import 'package:cloud_firestore/cloud_firestore.dart';

/// How the interview is held.
enum InterviewMode {
  video('video', 'Video call'),
  inPerson('in_person', 'In person'),
  phone('phone', 'Phone');

  const InterviewMode(this.id, this.label);

  final String id;
  final String label;

  static InterviewMode fromId(String? id) => values.firstWhere(
        (m) => m.id == id,
        orElse: () => InterviewMode.video,
      );
}

/// Where an interview has got to.
enum InterviewStatus {
  /// The recruiter has proposed a time; the admin has not set anything up yet.
  requested('requested', 'Awaiting link'),

  /// A joining link exists and the candidate can be told.
  scheduled('scheduled', 'Scheduled'),

  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const InterviewStatus(this.id, this.label);

  final String id;
  final String label;

  static InterviewStatus fromId(String? id) => values.firstWhere(
        (s) => s.id == id,
        orElse: () => InterviewStatus.requested,
      );
}

/// One scheduled interview.
///
/// Held in a top-level `interviews` collection and streamed by both sides:
/// the recruiter reads it by `recruiterUid` for their calendar, the admin by
/// `requestId` for the batch they are working. One document, two readers — no
/// mirrored copy on the application to fall out of step with it.
class Interview {
  const Interview({
    required this.id,
    required this.candidateUid,
    required this.candidateName,
    required this.jobId,
    required this.jobTitle,
    required this.requestId,
    required this.recruiterUid,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.mode,
    required this.status,
    this.round = 2,
    this.meetingLink = '',
    this.meetingProvider = '',
    this.notes = '',
    this.createdAt,
    this.linkGeneratedAt,
  });

  final String id;
  final String candidateUid;
  final String candidateName;
  final String jobId;
  final String jobTitle;
  final String requestId;
  final String recruiterUid;

  final DateTime scheduledAt;
  final int durationMinutes;
  final InterviewMode mode;
  final InterviewStatus status;
  final int round;

  final String meetingLink;
  final String meetingProvider;
  final String notes;
  final DateTime? createdAt;
  final DateTime? linkGeneratedAt;

  DateTime get endsAt => scheduledAt.add(Duration(minutes: durationMinutes));

  bool get hasLink => meetingLink.trim().isNotEmpty;

  bool get isPast => endsAt.isBefore(DateTime.now());

  /// Live right now, so the calendar can mark it and neither side has to work
  /// it out from two timestamps.
  bool get isInProgress {
    final now = DateTime.now();
    return !now.isBefore(scheduledAt) && now.isBefore(endsAt);
  }

  /// The calendar groups by day, so the key is the day alone.
  DateTime get day =>
      DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);

  Map<String, dynamic> toJson() => {
        'interviewId': id,
        'candidateUid': candidateUid,
        'candidateName': candidateName,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'requestId': requestId,
        'recruiterUid': recruiterUid,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'durationMinutes': durationMinutes,
        'mode': mode.id,
        'status': status.id,
        'round': round,
        'meetingLink': meetingLink,
        'meetingProvider': meetingProvider,
        'notes': notes,
      };

  factory Interview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Interview(
      id: doc.id,
      candidateUid: (d['candidateUid'] ?? '').toString(),
      candidateName: (d['candidateName'] ?? '').toString(),
      jobId: (d['jobId'] ?? '').toString(),
      jobTitle: (d['jobTitle'] ?? '').toString(),
      requestId: (d['requestId'] ?? '').toString(),
      recruiterUid: (d['recruiterUid'] ?? '').toString(),
      scheduledAt: (d['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime(1970),
      durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 45,
      mode: InterviewMode.fromId(d['mode']?.toString()),
      status: InterviewStatus.fromId(d['status']?.toString()),
      round: (d['round'] as num?)?.toInt() ?? 2,
      meetingLink: (d['meetingLink'] ?? '').toString(),
      meetingProvider: (d['meetingProvider'] ?? '').toString(),
      notes: (d['notes'] ?? '').toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      linkGeneratedAt: (d['linkGeneratedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Read-only helpers over a list of interviews.
///
/// Pure, so the grouping and clash rules can be tested without Firestore —
/// a double-booking is the kind of thing that is embarrassing in front of a
/// candidate and invisible in a unit-less list.
abstract final class InterviewSchedule {
  /// Interviews grouped by calendar day, each day sorted by start time.
  static Map<DateTime, List<Interview>> byDay(List<Interview> interviews) {
    final out = <DateTime, List<Interview>>{};
    for (final i in interviews) {
      if (i.status == InterviewStatus.cancelled) continue;
      out.putIfAbsent(i.day, () => []).add(i);
    }
    for (final list in out.values) {
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    }
    return out;
  }

  /// Interviews that have not finished yet, soonest first.
  static List<Interview> upcoming(List<Interview> interviews) {
    final out = interviews
        .where((i) => i.status != InterviewStatus.cancelled && !i.isPast)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return out;
  }

  /// Anything already booked that overlaps [start] for [minutes].
  ///
  /// Touching end-to-end is not a clash: an interview finishing at 14:00 and
  /// the next starting at 14:00 is a normal back-to-back booking.
  static List<Interview> clashes(
    List<Interview> interviews,
    DateTime start,
    int minutes, {
    String? ignoreId,
  }) {
    final end = start.add(Duration(minutes: minutes));
    return [
      for (final i in interviews)
        if (i.id != ignoreId &&
            i.status != InterviewStatus.cancelled &&
            start.isBefore(i.endsAt) &&
            i.scheduledAt.isBefore(end))
          i,
    ];
  }
}
