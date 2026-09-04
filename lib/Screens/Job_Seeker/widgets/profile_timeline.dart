import 'package:flutter/material.dart';

import '../../../core/onboarding/models/candidate_profile.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// What a timeline node represents. Each kind gets its own icon and accent so
/// a career at a glance is readable without reading every label.
enum MilestoneKind { experience, education, certification, licence }

/// A single dated point in the candidate's career.
class Milestone {
  const Milestone({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.sortKey,
    this.rangeLabel = '',
    this.details = const [],
    this.isCurrent = false,
    this.expiry,
  });

  final MilestoneKind kind;
  final String title;
  final String subtitle;

  /// Comparable `YYYYMM` value used to order the timeline, newest first.
  final int sortKey;
  final String rangeLabel;
  final List<String> details;
  final bool isCurrent;

  /// Parsed expiry for licences and certifications, if any.
  final DateTime? expiry;

  bool get isExpired =>
      expiry != null && expiry!.isBefore(DateTime.now());

  bool get isExpiringSoon {
    final e = expiry;
    if (e == null || isExpired) return false;
    return e.difference(DateTime.now()).inDays <= 90;
  }
}

/// Career progression, education and credential validity for a candidate,
/// built from the role-template profile written at onboarding.
class ProfileTimeline extends StatelessWidget {
  const ProfileTimeline({
    super.key,
    required this.profile,
    this.maxItems,
    this.onViewAll,
  });

  final CandidateProfile? profile;

  /// Caps the rendered nodes — the dashboard shows a slice, the profile page
  /// shows everything.
  final int? maxItems;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null) return const _TimelineEmpty();

    final all = buildMilestones(p);
    if (all.isEmpty) return const _TimelineEmpty();

    final shown =
        maxItems == null ? all : all.take(maxItems!).toList();
    final hidden = all.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricStrip(profile: p),
        if (p.roleSpecificData.experienceMetrics.isNotEmpty)
          const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < shown.length; i++)
          _TimelineRow(
            milestone: shown[i],
            isLast: i == shown.length - 1 && hidden == 0,
          ),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(left: 34, top: AppSpacing.sm),
            child: TextButton(
              onPressed: onViewAll,
              child: Text('Show $hidden more'),
            ),
          ),
      ],
    );
  }

  /// Flattens a profile into a single date-ordered milestone list.
  ///
  /// Exposed so the dashboard, the profile page and tests all derive the same
  /// ordering from the same rules.
  static List<Milestone> buildMilestones(CandidateProfile p) {
    final out = <Milestone>[];

    for (final e in p.experience) {
      out.add(Milestone(
        kind: MilestoneKind.experience,
        title: e.title.isEmpty ? 'Role' : e.title,
        subtitle: [e.company, e.location]
            .where((s) => s.isNotEmpty)
            .join(' · '),
        rangeLabel: _range(e.startDate, e.endDate, e.isCurrent),
        details: e.responsibilities.take(2).toList(),
        isCurrent: e.isCurrent,
        // A current role sorts above every dated one.
        sortKey: e.isCurrent ? 999999 : _key(e.endDate ?? e.startDate),
      ));
    }

    for (final e in p.education) {
      out.add(Milestone(
        kind: MilestoneKind.education,
        title: e.degree.isEmpty
            ? (e.fieldOfStudy.isEmpty ? 'Education' : e.fieldOfStudy)
            : e.degree,
        subtitle: e.institution,
        rangeLabel: e.graduationYear?.toString() ?? '',
        details: e.fieldOfStudy.isEmpty || e.degree.isEmpty
            ? const []
            : [e.fieldOfStudy],
        sortKey: (e.graduationYear ?? 0) * 100,
      ));
    }

    for (final c in p.certifications) {
      out.add(Milestone(
        kind: MilestoneKind.certification,
        title: c.name,
        subtitle: c.issuer,
        rangeLabel: c.issueDate,
        expiry: _date(c.expiryDate),
        sortKey: _key(c.issueDate),
      ));
    }

    for (final l in p.roleSpecificData.licensesAndRatings) {
      out.add(Milestone(
        kind: MilestoneKind.licence,
        title: l.title,
        subtitle: l.issuingAuthority,
        rangeLabel: l.expiryDate == null || l.expiryDate!.isEmpty
            ? ''
            : 'Valid to ${_short(l.expiryDate!)}',
        expiry: _date(l.expiryDate),
        // Licences carry no issue date, so they sit below dated history rather
        // than floating to the top on a zero key.
        sortKey: -1,
      ));
    }

    out.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return out;
  }

  /// `MM/YYYY`, `YYYY` and ISO-8601 all collapse to a comparable `YYYYMM`.
  static int _key(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return 0;
    final slash = RegExp(r'^(\d{1,2})[/\-](\d{4})$').firstMatch(s);
    if (slash != null) {
      return int.parse(slash.group(2)!) * 100 + int.parse(slash.group(1)!);
    }
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso.year * 100 + iso.month;
    final year = RegExp(r'(19|20)\d{2}').firstMatch(s);
    if (year != null) return int.parse(year.group(0)!) * 100;
    return 0;
  }

  static DateTime? _date(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    final slash = RegExp(r'^(\d{1,2})[/\-](\d{4})$').firstMatch(s);
    if (slash != null) {
      // Valid through the end of the stated month, and "the end" means the end
      // of that day. Day 0 of the following month lands on the last day at
      // 00:00, which made a licence read as expired for the whole of its final
      // day — the one day a pilot most needs it to still count.
      return DateTime(int.parse(slash.group(2)!),
          int.parse(slash.group(1)!) + 1, 0, 23, 59, 59);
    }
    return null;
  }

  static String _short(String raw) {
    final d = _date(raw);
    if (d == null) return raw;
    return '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _range(String start, String? end, bool isCurrent) {
    final e = isCurrent ? 'Present' : (end ?? '');
    if (start.isEmpty && e.isEmpty) return '';
    if (start.isEmpty) return e;
    if (e.isEmpty) return start;
    return '$start — $e';
  }
}

/// Headline numbers from the role template's experience metrics — flight
/// hours for aircrew, years in trade for engineers, and so on.
class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.profile});
  final CandidateProfile profile;

  static const _labels = {
    'totalTime': 'Total hours',
    'pic': 'PIC hours',
    'sic': 'SIC hours',
    'turbine': 'Turbine hours',
    'multiEngine': 'Multi-engine',
    'instrument': 'Instrument',
    'night': 'Night hours',
    'nvg': 'NVG hours',
    'fixedWing': 'Fixed-wing',
    'rotaryWing': 'Rotary-wing',
    'totalYears': 'Years experience',
    'tradeYears': 'Years in trade',
    'safetyYears': 'Years in safety',
    'cabinYears': 'Years in cabin',
    'operational': 'Operational',
    'teamSize': 'Team led',
  };

  /// The metrics worth a headline tile, in priority order.
  static const _priority = [
    'totalTime',
    'pic',
    'turbine',
    'totalYears',
    'tradeYears',
    'safetyYears',
    'cabinYears',
    'multiEngine',
    'instrument',
    'teamSize',
  ];

  @override
  Widget build(BuildContext context) {
    final metrics = profile.roleSpecificData.experienceMetrics;
    if (metrics.isEmpty) return const SizedBox.shrink();

    final keys = [
      ..._priority.where(metrics.containsKey),
      ...metrics.keys.where((k) => !_priority.contains(k)),
    ].take(context.isMobile ? 3 : 4).toList();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final k in keys)
          _MetricTile(
            label: _labels[k] ?? _humanize(k),
            value: _format(metrics[k]!),
          ),
      ],
    );
  }

  static String _humanize(String key) {
    final spaced = key.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  static String _format(num v) {
    if (v >= 1000) {
      final thousands = v / 1000;
      final text = thousands >= 10
          ? thousands.round().toString()
          : thousands.toStringAsFixed(1);
      return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}k';
    }
    return v == v.roundToDouble() ? v.round().toString() : v.toString();
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: AppText.heading(
                  fs: 16, fw: FontWeight.w800, color: AppColors.primary)),
          Text(label,
              style: AppText.label(fs: 10.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.milestone, required this.isLast});

  final Milestone milestone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style(milestone.kind);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          milestone.title,
                          style: AppText.heading(
                              fs: 13.5, fw: FontWeight.w700),
                        ),
                      ),
                      if (milestone.isCurrent)
                        const _Pill(
                            text: 'Current', color: AppColors.success),
                      if (milestone.isExpired)
                        const _Pill(
                            text: 'Expired', color: AppColors.danger),
                      if (milestone.isExpiringSoon)
                        const _Pill(
                            text: 'Expiring', color: AppColors.warning),
                    ],
                  ),
                  if (milestone.subtitle.isNotEmpty)
                    Text(milestone.subtitle,
                        style: AppText.body(
                            fs: 12, color: AppColors.textSecondary)),
                  if (milestone.rangeLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(milestone.rangeLabel,
                          style: AppText.label(
                              fs: 11, color: AppColors.textMuted)),
                    ),
                  for (final d in milestone.details)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• $d',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                              fs: 11.5, color: AppColors.textMuted)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static (IconData, Color) _style(MilestoneKind kind) {
    switch (kind) {
      case MilestoneKind.experience:
        return (Icons.work_rounded, AppColors.primary);
      case MilestoneKind.education:
        return (Icons.school_rounded, AppColors.accent);
      case MilestoneKind.certification:
        return (Icons.workspace_premium_rounded, AppColors.info);
      case MilestoneKind.licence:
        return (Icons.verified_rounded, AppColors.success);
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(text,
          style:
              AppText.label(fs: 9.5, color: color, fw: FontWeight.w700)),
    );
  }
}

class _TimelineEmpty extends StatelessWidget {
  const _TimelineEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.timeline_rounded,
              size: 28, color: AppColors.textFaint),
          const SizedBox(height: AppSpacing.sm),
          Text('Your career timeline is empty',
              style: AppText.heading(fs: 13.5, fw: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(
            'Add roles, education and certifications to your profile and they '
            'will appear here in order.',
            textAlign: TextAlign.center,
            style: AppText.body(fs: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
