/// Input widget a question renders as. Kept as string-backed values so the
/// admin-managed Firestore config and older documents stay forward-compatible.
enum QuestionType {
  text,
  longText,
  number,
  singleSelect,
  multiSelect,
  boolean,
  date;

  String toJson() => name;

  static QuestionType fromJson(String? v) {
    return QuestionType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => QuestionType.text,
    );
  }
}

/// A single onboarding question. Configuration-driven so the questionnaire
/// engine can render any role's flow without hardcoded screens.
class OnboardingQuestion {
  const OnboardingQuestion({
    required this.id,
    required this.label,
    required this.type,
    this.helpText,
    this.options = const [],
    this.required = false,
    this.min,
    this.max,
    this.unit,
    this.group,
    this.dependsOnId,
    this.dependsOnValue,
  });

  /// Stable key used as the answer map key. Must be unique within a role.
  final String id;
  final String label;
  final QuestionType type;
  final String? helpText;

  /// Choices for singleSelect / multiSelect.
  final List<String> options;
  final bool required;

  /// Numeric bounds for [QuestionType.number].
  final num? min;
  final num? max;

  /// Optional unit suffix (e.g. "hours", "years").
  final String? unit;

  /// Optional section grouping label for display.
  final String? group;

  /// Conditional display: show this question only when the answer to
  /// [dependsOnId] equals [dependsOnValue].
  final String? dependsOnId;
  final String? dependsOnValue;

  bool get isSelect =>
      type == QuestionType.singleSelect || type == QuestionType.multiSelect;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.toJson(),
        if (helpText != null) 'helpText': helpText,
        if (options.isNotEmpty) 'options': options,
        'required': required,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        if (unit != null) 'unit': unit,
        if (group != null) 'group': group,
        if (dependsOnId != null) 'dependsOnId': dependsOnId,
        if (dependsOnValue != null) 'dependsOnValue': dependsOnValue,
      };

  factory OnboardingQuestion.fromJson(Map<String, dynamic> j) {
    return OnboardingQuestion(
      id: (j['id'] ?? '').toString(),
      label: (j['label'] ?? '').toString(),
      type: QuestionType.fromJson(j['type']?.toString()),
      helpText: j['helpText']?.toString(),
      options: (j['options'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      required: j['required'] == true,
      min: j['min'] is num ? j['min'] as num : null,
      max: j['max'] is num ? j['max'] as num : null,
      unit: j['unit']?.toString(),
      group: j['group']?.toString(),
      dependsOnId: j['dependsOnId']?.toString(),
      dependsOnValue: j['dependsOnValue']?.toString(),
    );
  }

  OnboardingQuestion copyWith({
    String? id,
    String? label,
    QuestionType? type,
    String? helpText,
    List<String>? options,
    bool? required,
    num? min,
    num? max,
    String? unit,
    String? group,
    String? dependsOnId,
    String? dependsOnValue,
  }) {
    return OnboardingQuestion(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      helpText: helpText ?? this.helpText,
      options: options ?? this.options,
      required: required ?? this.required,
      min: min ?? this.min,
      max: max ?? this.max,
      unit: unit ?? this.unit,
      group: group ?? this.group,
      dependsOnId: dependsOnId ?? this.dependsOnId,
      dependsOnValue: dependsOnValue ?? this.dependsOnValue,
    );
  }
}
