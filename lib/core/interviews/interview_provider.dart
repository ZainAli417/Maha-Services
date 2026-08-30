import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'interview.dart';

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
        final ref = existing == null
            ? _db.collection('interviews').doc()
            : _db.collection('interviews').doc(existing.id);

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
          // Rebooking an interview that already had a link invalidates that
          // link: it was issued for a different time. Back to awaiting one.
          status: InterviewStatus.requested,
          round: round,
          notes: notes,
        );

        batch.set(ref, {
          ...interview.toJson(),
          'meetingLink': '',
          'meetingProvider': '',
          'linkGeneratedAt': null,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': recruiter,
        }, SetOptions(merge: true));

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

  /// Attaches a joining link and marks the interview scheduled. Admin side.
  ///
  /// The link is passed in rather than built here: creating a real meeting is
  /// the provider's job, and this stores whatever that returns.
  Future<bool> attachLink({
    required String interviewId,
    required String link,
    String provider = 'zoom',
  }) async {
    _busy = true;
    notifyListeners();
    try {
      await _db.collection('interviews').doc(interviewId).update({
        'meetingLink': link,
        'meetingProvider': provider,
        'status': InterviewStatus.scheduled.id,
        'linkGeneratedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = 'Could not attach the link: $e';
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
