import 'models/aviation_role.dart';
import 'models/candidate_profile.dart';
import 'models/question.dart';

/// One label/value pair as a recruiter sees it.
class RoleProfileItem {
  const RoleProfileItem({
    required this.label,
    required this.value,
    this.highlight = false,
    this.sensitive = false,
  });

  final String label;
  final String value;

  /// Compliance declarations answered "Yes" — surfaced first in the UI.
  final bool highlight;

  /// Personal contact detail. Recruiters see these withheld; only an admin,
  /// who handles the candidate's paperwork, sees the real value.
  final bool sensitive;

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        if (highlight) 'highlight': true,
        if (sensitive) 'sensitive': true,
      };

  factory RoleProfileItem.fromJson(Map<String, dynamic> j) => RoleProfileItem(
        label: (j['label'] ?? '').toString(),
        value: (j['value'] ?? '').toString(),
        highlight: j['highlight'] == true,
        sensitive: j['sensitive'] == true,
      );
}

class RoleProfileSection {
  const RoleProfileSection({required this.title, required this.items});

  final String title;
  final List<RoleProfileItem> items;

  Map<String, dynamic> toJson() => {
        'title': title,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory RoleProfileSection.fromJson(Map<String, dynamic> j) =>
      RoleProfileSection(
        title: (j['title'] ?? '').toString(),
        items: (j['items'] as List?)
                ?.whereType<Map>()
                .map((m) => RoleProfileItem.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            const [],
      );
}

/// A self-contained, display-ready copy of a candidate's role profile.
///
/// Written into the application document at apply time and carried onward into
/// the admin request payload. Denormalized on purpose: the recruiter and admin
/// screens must render a candidate without loading the role template (which an
/// admin may edit later), and the snapshot has to stay true to what the
/// candidate actually submitted on the day they applied.
class RoleProfileSnapshot {
  const RoleProfileSnapshot({
    this.roleTitle = '',
    this.industry = '',
    this.category = '',
    this.sections = const [],
    this.metrics = const {},
    this.licences = const [],
    this.aircraftTypes = const [],
    this.competencies = const [],
    this.tools = const [],
    this.capturedAt,
  });

  final String roleTitle;
  final String industry;
  final String category;
  final List<RoleProfileSection> sections;

  /// Headline numbers (flight hours, years in trade) keyed by metric id.
  final Map<String, num> metrics;
  final List<LicenseEntry> licences;
  final List<String> aircraftTypes;
  final List<String> competencies;
  final List<String> tools;
  final String? capturedAt;

  bool get isEmpty => sections.isEmpty && metrics.isEmpty && licences.isEmpty;

  Map<String, dynamic> toJson() => {
        'roleTitle': roleTitle,
        'industry': industry,
        'category': category,
        'sections': sections.map((s) => s.toJson()).toList(),
        'metrics': metrics,
        'licences': licences.map((l) => l.toJson()).toList(),
        'aircraftTypes': aircraftTypes,
        'competencies': competencies,
        'tools': tools,
        'capturedAt': capturedAt,
      };

  factory RoleProfileSnapshot.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const RoleProfileSnapshot();
    return RoleProfileSnapshot(
      roleTitle: (j['roleTitle'] ?? '').toString(),
      industry: (j['industry'] ?? '').toString(),
      category: (j['category'] ?? '').toString(),
      sections: (j['sections'] as List?)
              ?.whereType<Map>()
              .map((m) =>
                  RoleProfileSection.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      metrics: _numMap(j['metrics']),
      licences: (j['licences'] as List?)
              ?.whereType<Map>()
              .map((m) => LicenseEntry.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      aircraftTypes: _strList(j['aircraftTypes']),
      competencies: _strList(j['competencies']),
      tools: _strList(j['tools']),
      capturedAt: j['capturedAt']?.toString(),
    );
  }

  /// Flattens [profile] against [template] into a display-ready snapshot.
  ///
  /// File answers are reduced to the attachment's filename — recruiters get
  /// the documents through the existing document lists, and a signed URL in a
  /// long-lived request document would be a leak waiting to happen.
  static RoleProfileSnapshot build(
    CandidateProfile profile,
    RoleTemplate template, {
    DateTime? capturedAt,
  }) {
    final answers = profile.answers;
    final sections = <RoleProfileSection>[];

    for (final title in template.sections) {
      final items = <RoleProfileItem>[];
      for (final q in template.questionsIn(title)) {
        if (!_isVisible(q, answers)) continue;
        // Contact details are deliberately not copied here. They already live
        // on the application's personal section, and duplicating them into a
        // second long-lived document is how they end up somewhere nobody
        // remembers to redact.
        if (contactPaths.contains(q.mapsTo)) continue;
        final raw = answers[q.id];
        if (raw == null) continue;
        final value = formatValue(raw, q);
        if (value.isEmpty) continue;
        items.add(RoleProfileItem(
          label: q.label,
          value: value,
          highlight: _isPositiveDeclaration(raw),
        ));
      }
      if (items.isNotEmpty) {
        sections.add(RoleProfileSection(title: title, items: items));
      }
    }

    final role = profile.roleSpecificData;
    return RoleProfileSnapshot(
      roleTitle: profile.targetRole.roleTitle.isEmpty
          ? template.title
          : profile.targetRole.roleTitle,
      industry: profile.targetRole.industry.isEmpty
          ? template.industry
          : profile.targetRole.industry,
      category: template.category,
      sections: sections,
      metrics: role.experienceMetrics,
      licences: role.licensesAndRatings,
      aircraftTypes: role.aircraftTypes,
      competencies: role.technicalCompetencies,
      tools: role.toolsAndSystems,
      capturedAt: (capturedAt ?? DateTime.now()).toIso8601String(),
    );
  }

  /// Renders a stored answer the way every screen should show it.
  static String formatValue(dynamic value, OnboardingQuestion q) {
    if (value == null) return '';
    if (value is List) return value.join(', ');
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is Map) {
      if (value.containsKey('value')) {
        final yes = value['value'] == true;
        final details = value['details']?.toString().trim() ?? '';
        if (!yes) return 'No';
        return details.isEmpty ? 'Yes' : 'Yes — $details';
      }
      // A file answer: show the filename, never the download URL.
      if (value.containsKey('name')) return value['name'].toString();
      return '';
    }
    final s = value.toString().trim();
    if (s.isEmpty) return '';
    return q.unit == null ? s : '$s ${q.unit}';
  }

  /// Fields that identify or directly contact the candidate. Name, city,
  /// country and summary stay visible — a recruiter has to know who and where
  /// someone is to shortlist them — but the means of contacting them directly
  /// does not travel with the shortlist.
  static const contactPaths = {
    'personalInfo.email',
    'personalInfo.secondaryEmail',
    'personalInfo.phone',
    'personalInfo.dateOfBirth',
    'personalInfo.socialLinks',
  };

  /// A declaration answered "Yes" (violation, incident, enforcement) — the
  /// rows a recruiter must not miss.
  static bool _isPositiveDeclaration(dynamic value) =>
      value is Map && value['value'] == true;

  static bool _isVisible(OnboardingQuestion q, Map<String, dynamic> answers) {
    final depId = q.dependsOnId;
    if (depId == null) return true;
    final dep = answers[depId];
    if (dep == null) return false;
    final accepted = q.dependsOnValues.isNotEmpty
        ? q.dependsOnValues
        : (q.dependsOnValue == null
            ? const <String>[]
            : <String>[q.dependsOnValue!]);
    if (accepted.isEmpty) return true;
    if (dep is List) {
      return dep.any((v) => accepted.contains(v.toString()));
    }
    return accepted.contains(dep.toString());
  }

  static Map<String, num> _numMap(dynamic v) {
    if (v is! Map) return const {};
    final out = <String, num>{};
    v.forEach((k, value) {
      final n = value is num ? value : num.tryParse(value?.toString() ?? '');
      if (n != null) out[k.toString()] = n;
    });
    return out;
  }

  static List<String> _strList(dynamic v) => v is List
      ? v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
      : const [];
}

/// Human labels for the metric keys the templates emit.
abstract final class MetricLabels {
  static const _labels = {
    'totalTime': 'Total flight hours',
    'pic': 'PIC hours',
    'sic': 'SIC hours',
    'fixedWing': 'Fixed-wing hours',
    'rotaryWing': 'Rotary-wing hours',
    'multiEngine': 'Multi-engine hours',
    'turbine': 'Turbine / jet hours',
    'instrument': 'Instrument hours',
    'night': 'Night hours',
    'nvg': 'NVG hours',
    'dayLandings90': 'Day landings (90d)',
    'nightLandings90': 'Night landings (90d)',
    'totalYears': 'Years of experience',
    'tradeYears': 'Years in trade',
    'safetyYears': 'Years in safety',
    'cabinYears': 'Years in cabin',
    'operational': 'Operational experience',
    'teamSize': 'Largest team led',
  };

  static String of(String key) {
    final known = _labels[key];
    if (known != null) return known;
    final spaced = key.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced.isEmpty
        ? key
        : spaced[0].toUpperCase() + spaced.substring(1);
  }

  /// Metric ids measured in flight hours.
  ///
  /// Kept apart from the year metrics because they are not comparable: a
  /// filter for "at least 500" means 500 hours for a pilot and 500 years for
  /// an engineer if the two are pooled, which is how a single "top metric"
  /// number quietly produces nonsense.
  static const hourKeys = {
    'totalTime',
    'pic',
    'sic',
    'fixedWing',
    'rotaryWing',
    'multiEngine',
    'turbine',
    'instrument',
    'night',
    'nvg',
  };

  /// Metric ids measured in years of service or trade.
  static const yearKeys = {
    'totalYears',
    'tradeYears',
    'safetyYears',
    'cabinYears',
  };

  /// Total flight hours for a set of metrics, or null when the candidate has
  /// none — a ground role legitimately has no hours, and zero would read as
  /// "flew nothing" rather than "does not fly".
  static num? flightHours(Map<String, num> metrics) {
    final total = metrics['totalTime'];
    if (total != null) return total;
    final hours = [
      for (final e in metrics.entries)
        if (hourKeys.contains(e.key)) e.value,
    ];
    return hours.isEmpty ? null : hours.reduce((a, b) => a > b ? a : b);
  }

  /// Years of experience for a set of metrics, or null when none was captured.
  static num? years(Map<String, num> metrics) {
    final values = [
      for (final e in metrics.entries)
        if (yearKeys.contains(e.key)) e.value,
    ];
    return values.isEmpty ? null : values.reduce((a, b) => a > b ? a : b);
  }

  /// Metrics worth a headline tile, most important first.
  static const priority = [
    'totalTime',
    'pic',
    'turbine',
    'multiEngine',
    'instrument',
    'totalYears',
    'tradeYears',
    'safetyYears',
    'cabinYears',
    'teamSize',
  ];

  static String format(num v) {
    if (v >= 1000) {
      final k = v / 1000;
      final text = k >= 10 ? k.round().toString() : k.toStringAsFixed(1);
      return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}k';
    }
    return v == v.roundToDouble() ? v.round().toString() : v.toString();
  }
}
