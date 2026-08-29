import 'question.dart';

/// A single career/profession template with its own tailored onboarding flow.
///
/// Historically aviation-only (hence the class name, kept so the admin
/// questionnaire editor and every persisted `questionnaire_config` document
/// keep working); templates now carry an [industry] so the picker can present
/// a category hierarchy across verticals.
class AviationRole {
  const AviationRole({
    required this.id,
    required this.title,
    required this.category,
    this.industry = 'Aviation',
    this.description,
    this.questions = const [],
  });

  /// Stable slug (e.g. 'airline_pilot'). Used as the Firestore doc id.
  final String id;
  final String title;

  /// High-level grouping within an industry (e.g. 'Flight Crew').
  final String category;

  /// Top-level vertical (e.g. 'Aviation', 'Engineering & Technology').
  final String industry;
  final String? description;
  final List<OnboardingQuestion> questions;

  /// Ordered, de-duplicated section names derived from question groups.
  List<String> get sections {
    final seen = <String>[];
    for (final q in questions) {
      final g = q.group ?? 'General';
      if (!seen.contains(g)) seen.add(g);
    }
    return seen;
  }

  List<OnboardingQuestion> questionsIn(String section) =>
      questions.where((q) => (q.group ?? 'General') == section).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'industry': industry,
        if (description != null) 'description': description,
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory AviationRole.fromJson(Map<String, dynamic> j) {
    return AviationRole(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      category: (j['category'] ?? 'General').toString(),
      industry: (j['industry'] ?? 'Aviation').toString(),
      description: j['description']?.toString(),
      questions: (j['questions'] as List?)
              ?.whereType<Map>()
              .map((m) => OnboardingQuestion.fromJson(
                  Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
    );
  }

  AviationRole copyWith({
    String? title,
    String? category,
    String? industry,
    String? description,
    List<OnboardingQuestion>? questions,
  }) {
    return AviationRole(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      industry: industry ?? this.industry,
      description: description ?? this.description,
      questions: questions ?? this.questions,
    );
  }
}

/// Preferred name for new code — the model describes any role template, not
/// just aviation ones.
typedef RoleTemplate = AviationRole;
