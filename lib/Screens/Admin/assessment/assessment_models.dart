import 'package:cloud_firestore/cloud_firestore.dart';

/// One question as the admin reviews it — with the answer, unlike every other
/// view of it in the product.
class BankQuestion {
  BankQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.topic,
    required this.explanation,
  });

  final String id;
  String text;
  List<String> options;
  int correctIndex;
  String difficulty;
  String topic;
  String explanation;

  factory BankQuestion.fromJson(Map<String, dynamic> j) => BankQuestion(
        id: (j['id'] ?? '').toString(),
        text: (j['text'] ?? '').toString(),
        options: (j['options'] as List?)?.map((o) => o.toString()).toList() ?? const [],
        correctIndex: (j['correctIndex'] as num?)?.toInt() ?? 0,
        difficulty: (j['difficulty'] ?? 'medium').toString(),
        topic: (j['topic'] ?? '').toString(),
        explanation: (j['explanation'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options,
        'correctIndex': correctIndex,
        'difficulty': difficulty,
        'topic': topic,
        'explanation': explanation,
      };
}

/// The question bank for one job.
class QuestionBank {
  const QuestionBank({
    required this.jobId,
    required this.jobTitle,
    required this.status,
    required this.questions,
    this.generatedAt,
  });

  final String jobId;
  final String jobTitle;

  /// draft until an admin has read it; approved once they have.
  final String status;
  final List<BankQuestion> questions;
  final DateTime? generatedAt;

  bool get isApproved => status == 'approved';

  Map<String, int> get tierCounts {
    final counts = {'easy': 0, 'medium': 0, 'hard': 0};
    for (final q in questions) {
      counts[q.difficulty] = (counts[q.difficulty] ?? 0) + 1;
    }
    return counts;
  }

  factory QuestionBank.fromJson(Map<String, dynamic> j) => QuestionBank(
        jobId: (j['jobId'] ?? '').toString(),
        jobTitle: (j['jobTitle'] ?? '').toString(),
        status: (j['status'] ?? 'draft').toString(),
        questions: (j['questions'] as List?)
                ?.whereType<Map>()
                .map((m) => BankQuestion.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            const [],
        generatedAt: _ts(j['generatedAt']),
      );

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return null;
  }
}

/// One candidate's sitting, as the admin board shows it.
class AssessmentRow {
  const AssessmentRow({
    required this.assessmentId,
    required this.candidateUid,
    required this.candidateName,
    required this.status,
    required this.answeredCount,
    required this.questionCount,
    this.percentage,
    this.correct,
    this.verdict,
    this.rank,
    this.tabSwitches = 0,
    this.resumes = 0,
    this.submittedAt,
    this.expiresAt,
    this.released = false,
  });

  final String assessmentId, candidateUid, candidateName, status;
  final int answeredCount, questionCount;
  final int? percentage, correct, rank;
  final String? verdict;
  final int tabSwitches, resumes;
  final DateTime? submittedAt, expiresAt;
  final bool released;

  bool get isDone => status == 'submitted';
  double get progress => questionCount == 0 ? 0 : answeredCount / questionCount;

  factory AssessmentRow.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final result = d['result'] is Map
        ? Map<String, dynamic>.from(d['result'] as Map)
        : const <String, dynamic>{};
    final integrity = d['integrity'] is Map
        ? Map<String, dynamic>.from(d['integrity'] as Map)
        : const <String, dynamic>{};

    return AssessmentRow(
      assessmentId: doc.id,
      candidateUid: (d['candidateUid'] ?? '').toString(),
      candidateName: (d['candidateName'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      answeredCount: (d['answeredCount'] as num?)?.toInt() ?? 0,
      questionCount: (d['questionCount'] as num?)?.toInt() ?? 20,
      percentage: (result['percentage'] as num?)?.toInt(),
      correct: (result['correct'] as num?)?.toInt(),
      verdict: result['verdict']?.toString(),
      tabSwitches: (integrity['tabSwitches'] as num?)?.toInt() ?? 0,
      resumes: (integrity['resumes'] as num?)?.toInt() ?? 0,
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
      released: d['releasedToRecruiterAt'] != null,
    );
  }
}
