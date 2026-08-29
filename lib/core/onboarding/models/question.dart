/// Input widget a question renders as. Kept as string-backed values so the
/// admin-managed Firestore config and older documents stay forward-compatible.
///
/// The first seven values are the original set and must keep their names —
/// existing `questionnaire_config` documents serialize by [name]. Everything
/// after them was added for the role-template engine and degrades gracefully:
/// an old client that cannot parse a new name falls back to [text].
enum QuestionType {
  text,
  longText,
  number,
  singleSelect,
  multiSelect,
  boolean,
  date,

  // ── Role-template additions ────────────────────────────────────────────
  /// Single choice from a long list — renders a searchable dropdown/sheet
  /// instead of a chip row.
  searchSelect,

  /// Many choices from a long list — searchable picker that renders the
  /// selection back as removable pills.
  searchMultiSelect,

  /// Free-form pill input for values that cannot be enumerated (variants,
  /// squadron names, tool names). Still structured: stored as a string list.
  tags,

  /// Month + year only (checkride dates, licence expiry).
  monthYear,

  /// Yes/No radio pair that reveals a mandatory narrative box when "Yes".
  /// Stored as `{'value': bool, 'details': String}`.
  yesNoDetail,

  /// Document upload. Stored as `{'name', 'url', 'size', 'contentType'}`.
  file,

  /// Dial code picked from a flagged country list, plus the national number.
  ///
  /// Stored as a single string (`"+971 50 123 4567"`) rather than a map, so
  /// every existing reader of `personalInfo.phone` — the admin contact fetch,
  /// the CV generator, the profile screen — keeps working without a migration.
  /// Only the input control is split in two.
  phone;

  String toJson() => name;

  static QuestionType fromJson(String? v) {
    return QuestionType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => QuestionType.text,
    );
  }

  /// True for the types whose answer is a `List`.
  bool get isMulti =>
      this == QuestionType.multiSelect ||
      this == QuestionType.searchMultiSelect ||
      this == QuestionType.tags;

  /// True for the types backed by an option list.
  bool get isSelect =>
      this == QuestionType.singleSelect ||
      this == QuestionType.multiSelect ||
      this == QuestionType.searchSelect ||
      this == QuestionType.searchMultiSelect;

  /// True for the types that render a search-driven picker.
  bool get isSearchable =>
      this == QuestionType.searchSelect ||
      this == QuestionType.searchMultiSelect;
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
    this.dependsOnValues = const [],
    this.mapsTo,
    this.placeholder,
    this.maxSelect,
    this.allowCustom = false,
    this.span = 1,
    this.cvExtractable = true,
  });

  /// Stable key used as the answer map key. Must be unique within a role.
  final String id;
  final String label;
  final QuestionType type;
  final String? helpText;

  /// Choices for the select/search types.
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

  /// Conditional display against a set — the question shows when the
  /// dependency's answer is (or contains) any of these. Takes precedence over
  /// [dependsOnValue] when non-empty.
  final List<String> dependsOnValues;

  /// Dot-path into [CandidateProfile] this answer projects onto, e.g.
  /// `roleSpecificData.flightHoursOrExperienceMetrics.totalTime`. Null means
  /// the answer only lives in the raw answer map.
  final String? mapsTo;

  /// Placeholder/hint shown inside the control.
  final String? placeholder;

  /// Upper bound on selections for the multi types (null = unlimited).
  final int? maxSelect;

  /// Whether a searchable picker may accept a value outside [options].
  final bool allowCustom;

  /// Desktop grid span (1 = half width, 2 = full width).
  final int span;

  /// Whether this field is worth asking the CV extractor to fill.
  ///
  /// False for anything a CV cannot honestly answer — availability and
  /// relocation preferences, notice periods, tooling status — and, critically,
  /// for every legal declaration (violations, incidents, enforcement history).
  /// Those must come from the candidate: a model inferring "no prior
  /// violations" from silence would be putting words in their mouth on a
  /// question with legal weight.
  ///
  /// Excluded fields never reach the prompt, which keeps it short enough to
  /// stay accurate and removes the opportunity to hallucinate them.
  final bool cvExtractable;

  bool get isSelect => type.isSelect;

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
        if (dependsOnValues.isNotEmpty) 'dependsOnValues': dependsOnValues,
        if (mapsTo != null) 'mapsTo': mapsTo,
        if (placeholder != null) 'placeholder': placeholder,
        if (maxSelect != null) 'maxSelect': maxSelect,
        if (allowCustom) 'allowCustom': true,
        if (span != 1) 'span': span,
        if (!cvExtractable) 'cvExtractable': false,
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
      dependsOnValues:
          (j['dependsOnValues'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      mapsTo: j['mapsTo']?.toString(),
      placeholder: j['placeholder']?.toString(),
      maxSelect: j['maxSelect'] is int ? j['maxSelect'] as int : null,
      allowCustom: j['allowCustom'] == true,
      span: j['span'] is int ? j['span'] as int : 1,
      cvExtractable: j['cvExtractable'] != false,
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
    List<String>? dependsOnValues,
    String? mapsTo,
    String? placeholder,
    int? maxSelect,
    bool? allowCustom,
    int? span,
    bool? cvExtractable,
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
      dependsOnValues: dependsOnValues ?? this.dependsOnValues,
      mapsTo: mapsTo ?? this.mapsTo,
      placeholder: placeholder ?? this.placeholder,
      maxSelect: maxSelect ?? this.maxSelect,
      allowCustom: allowCustom ?? this.allowCustom,
      span: span ?? this.span,
      cvExtractable: cvExtractable ?? this.cvExtractable,
    );
  }

  /// Whether [value] satisfies this question when it is [required].
  bool isAnswered(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) {
      if (type == QuestionType.yesNoDetail) {
        final v = value['value'];
        if (v is! bool) return false;
        // "Yes" demands the narrative box.
        return v == false ||
            (value['details']?.toString().trim().isNotEmpty ?? false);
      }
      return value.isNotEmpty;
    }
    return true;
  }
}
