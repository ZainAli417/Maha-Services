import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../services/backend_api.dart';
import 'interview.dart';

/// What came back from asking the backend to make a meeting.
///
/// A booking can succeed and still be worth saying something about — a free
/// Zoom plan will cut a 45-minute interview off at 40, and finding that out
/// mid-interview is the wrong time.
class MeetingOutcome {
  const MeetingOutcome({
    required this.ok,
    this.rescheduled = false,
    this.emailed = 0,
    this.warning = '',
    this.message = '',
  });

  final bool ok;
  final bool rescheduled;
  final int emailed;
  final String warning;
  final String message;
}

/// Scheduling, for whichever side is looking.
///
/// The recruiter books; the admin turns a booking into a joining link. Both
/// read the same `interviews` documents, so neither has to be told what the
/// other did — the card and the calendar move together because they are the
/// same record.
class InterviewProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Interview> _interviews = const [];
  List<Interview> get interviews => _interviews;

  bool _loading = true;
  bool get loading => _loading;

  String _error = '';
  String get error => _error;

  bool _busy = false;
  bool get busy => _busy;

  StreamSubscription? _sub;
  String? _watchKey;

  List<Interview> get upcoming => InterviewSchedule.upcoming(_interviews);
  Map<DateTime, List<Interview>> get byDay =>
      InterviewSchedule.byDay(_interviews);

  Interview? forCandidate(String uid) {
    for (final i in _interviews) {
      if (i.candidateUid == uid && i.status != InterviewStatus.cancelled) {
        return i;
      }
    }
    return null;
  }

  Set<String> get bookedCandidateIds => {
        for (final i in _interviews)
          if (i.status != InterviewStatus.cancelled) i.candidateUid,
      };

  /// Everything this recruiter has booked.
  void watchForRecruiter([String? uid]) {
    final recruiter = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (recruiter == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    _watch('recruiter:$recruiter',
        _db.collection('interviews').where('recruiterUid', isEqualTo: recruiter));
  }

  /// Everything booked out of one shortlist batch.
  void watchForRequest(String requestId) {
    _watch('request:$requestId',
        _db.collection('interviews').where('requestId', isEqualTo: requestId));
  }

  void _watch(String key, Query<Map<String, dynamic>> query) {
    if (_watchKey == key) return;
    _watchKey = key;
    _sub?.cancel();
    _loading = true;
    notifyListeners();

    // Ordering is done in memory rather than in the query: an orderBy
    // alongside the equality filter would need a composite index, and these
    // lists are small enough that sorting here costs nothing.
    _sub = query.snapshots().listen(
      (snap) {
        _interviews = snap.docs.map(Interview.fromDoc).toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        _loading = false;
        _error = '';
        notifyListeners();
      },
      onError: (e) {
        _error = 'Could not load interviews: $e';
        _loading = false;
        notifyListeners();
      },
    );
  }

  /// Books one slot per candidate, back to back from [start].
  ///
  /// Booking several people at one time would be a diary clash by
  /// construction, so each candidate is offset by the interview length plus a
  /// short gap — the recruiter picks the first slot and the rest follow.
  Future<int> schedule({
    required List<({String uid, String name})> candidates,
    required String jobId,
    required String jobTitle,
    required String requestId,
    required DateTime start,
    required int durationMinutes,
    required InterviewMode mode,
    required int round,
    String notes = '',
    int gapMinutes = 15,
  }) async {
    final recruiter = FirebaseAuth.instance.currentUser?.uid;
    if (recruiter == null || candidates.isEmpty) return 0;

    _busy = true;
    _error = '';
    notifyListeners();

    try {
      final batch = _db.batch();
      var slot = start;

      for (final c in candidates) {
        final existing = forCandidate(c.uid);

        if (existing == null) {
          final ref = _db.collection('interviews').doc();
          final interview = Interview(
            id: ref.id,
            candidateUid: c.uid,
            candidateName: c.name,
            jobId: jobId,
            jobTitle: jobTitle,
            requestId: requestId,
            recruiterUid: recruiter,
            scheduledAt: slot,
            durationMinutes: durationMinutes,
            mode: mode,
            status: InterviewStatus.requested,
            round: round,
            notes: notes,
          );

          // The meeting fields are left off entirely rather than written
          // empty. They belong to the backend, and a recruiter is not allowed
          // to set them at all — including to a blank.
          final data = interview.toJson()
            ..remove('meetingLink')
            ..remove('meetingProvider');

          batch.set(ref, {
            ...data,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': recruiter,
          });
        } else {
          // Moving an existing booking touches the timing only.
          //
          // The link deliberately survives: the admin re-issues the meeting
          // for the new time and Zoom keeps the same joining URL, so a link
          // already sitting in the candidate's inbox goes on working.
          // `rescheduledAt` is what tells the admin the meeting is now behind
          // the booking.
          batch.update(_db.collection('interviews').doc(existing.id), {
            'scheduledAt': Timestamp.fromDate(slot),
            'durationMinutes': durationMinutes,
            'mode': mode.id,
            'round': round,
            'notes': notes,
            'jobId': jobId,
            'jobTitle': jobTitle,
            'requestId': requestId,
            'rescheduledAt': FieldValue.serverTimestamp(),
          });
        }

        slot = slot.add(Duration(minutes: durationMinutes + gapMinutes));
      }

      await batch.commit();
      return candidates.length;
    } catch (e) {
      _error = 'Could not save the schedule: $e';
      return 0;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Creates the real Zoom meeting for a booking. Admin side.
  ///
  /// The link is never built here. Zoom is spoken to only by the backend —
  /// the Server-to-Server secret would be readable by anyone who opened the
  /// network tab of a web build, and it grants meeting control over the whole
  /// Zoom account. This asks; the backend does it and writes the result, which
  /// arrives back through the snapshot listener like any other change.
  ///
  /// Running it again after a reschedule moves the same Zoom meeting rather
  /// than making a second one, so a link already in a candidate's inbox keeps
  /// working.
  Future<MeetingOutcome> generateMeeting(String interviewId) async {
    _busy = true;
    _error = '';
    notifyListeners();
    try {
      final res = await BackendApi.post('/interviews/$interviewId/meeting', const {});
      return MeetingOutcome(
        ok: true,
        rescheduled: res['rescheduled'] == true,
        emailed: (res['emailed'] as num?)?.toInt() ?? 0,
        warning: (res['warning'] ?? '').toString(),
      );
    } on BackendException catch (e) {
      _error = e.message;
      return MeetingOutcome(ok: false, message: e.message);
    } catch (e) {
      _error = 'Could not create the meeting: $e';
      return MeetingOutcome(ok: false, message: _error);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// A fresh host link for the admin to open, valid now.
  ///
  /// Never stored: Zoom's start URL is a host credential and it dies two hours
  /// after it is issued, so a copy kept in the record would be both a leak and,
  /// by the day of the interview, a dead link. It is fetched at the moment it
  /// is needed and handed straight to the browser.
  Future<String> hostStartUrl(String interviewId) async {
    _busy = true;
    _error = '';
    notifyListeners();
    try {
      final res = await BackendApi.post('/interviews/$interviewId/start', const {});
      return (res['startUrl'] ?? '').toString();
    } on BackendException catch (e) {
      _error = e.message;
      return '';
    } catch (e) {
      _error = 'Could not start the meeting: $e';
      return '';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Cancels the Zoom meeting behind a booking and clears the link.
  ///
  /// With [cancel] the interview itself is called off; without it the slot
  /// stays and goes back to awaiting a link.
  Future<bool> removeMeeting(String interviewId, {bool cancel = false}) async {
    _busy = true;
    _error = '';
    notifyListeners();
    try {
      await BackendApi.delete('/interviews/$interviewId/meeting',
          body: {'cancel': cancel});
      return true;
    } on BackendException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Could not remove the meeting: $e';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> setStatus(String interviewId, InterviewStatus status) async {
    try {
      await _db
          .collection('interviews')
          .doc(interviewId)
          .update({'status': status.id});
      return true;
    } catch (e) {
      _error = 'Could not update the interview: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
