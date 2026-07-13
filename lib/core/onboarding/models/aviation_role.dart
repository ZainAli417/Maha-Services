import 'question.dart';

/// A single aviation career/profession with its own tailored onboarding flow.
class AviationRole {
  const AviationRole({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    this.questions = const [],
  });

  /// Stable slug (e.g. 'airline_pilot'). Used as the Firestore doc id.
  final String id;
  final String title;

  /// High-level grouping (e.g. 'Flight Crew', 'Engineering & Maintenance').
  final String category;
  final String? description;
  final List<OnboardingQuestion> questions;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        if (description != null) 'description': description,
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory AviationRole.fromJson(Map<String, dynamic> j) {
    return AviationRole(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      category: (j['category'] ?? 'General').toString(),
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
    String? description,
    List<OnboardingQuestion>? questions,
  }) {
    return AviationRole(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      questions: questions ?? this.questions,
    );
  }
}
