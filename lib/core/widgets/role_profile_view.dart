import 'package:flutter/material.dart';

import '../onboarding/role_profile_snapshot.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Renders a [RoleProfileSnapshot] the same way everywhere it is read — the
/// recruiter applicant panel and the admin candidate sheet — so a candidate
/// never looks different depending on who opened them.
class RoleProfileView extends StatelessWidget {
  const RoleProfileView({
    super.key,
    required this.snapshot,
    this.dense = false,
    this.canViewContactInfo = false,
  });

  final RoleProfileSnapshot snapshot;

  /// Tighter spacing for embedding inside an existing scroll view.
  final bool dense;

  /// Whether the viewer may see the candidate's direct contact details.
  /// Defaults to false so a new call site fails closed rather than leaking.
  final bool canViewContactInfo;

  @override
  Widget build(BuildContext context) {
    if (snapshot.isEmpty) return const _NoRoleProfile();

    final gap = dense ? AppSpacing.md : AppSpacing.lg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (snapshot.roleTitle.isNotEmpty) ...[
          _RoleHeader(snapshot: snapshot),
          SizedBox(height: gap),
        ],
        if (snapshot.metrics.isNotEmpty) ...[
          _MetricGrid(metrics: snapshot.metrics),
          SizedBox(height: gap),
        ],
        if (snapshot.licences.isNotEmpty) ...[
          _LicenceList(snapshot: snapshot),
          SizedBox(height: gap),
        ],
        if (snapshot.aircraftTypes.isNotEmpty)
          _ChipBlock(
            title: 'Aircraft & type ratings',
            values: snapshot.aircraftTypes,
            color: AppColors.primary,
          ),
        if (snapshot.competencies.isNotEmpty)
          _ChipBlock(
            title: 'Technical competencies',
            values: snapshot.competencies,
            color: AppColors.accent,
          ),
        if (snapshot.tools.isNotEmpty)
          _ChipBlock(
            title: 'Tools & systems',
            values: snapshot.tools,
            color: AppColors.info,
          ),
        for (final section in snapshot.sections)
          _SectionBlock(
            section: section,
            dense: dense,
            canViewContactInfo: canViewContactInfo,
          ),
      ],
    );
  }
}

class _RoleHeader extends StatelessWidget {
  const _RoleHeader({required this.snapshot});
  final RoleProfileSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final sub = [snapshot.industry, snapshot.category]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(snapshot.roleTitle,
                    style: AppText.heading(fs: 14, fw: FontWeight.w800)),
                if (sub.isNotEmpty)
                  Text(sub,
                      style:
                          AppText.label(fs: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final Map<String, num> metrics;

  @override
  Widget build(BuildContext context) {
    final keys = [
      ...MetricLabels.priority.where(metrics.containsKey),
      ...metrics.keys.where((k) => !MetricLabels.priority.contains(k)),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final k in keys)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(MetricLabels.format(metrics[k]!),
                    style: AppText.heading(
                        fs: 15, fw: FontWeight.w800, color: AppColors.primary)),
                Text(MetricLabels.of(k),
                    style:
                        AppText.label(fs: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
      ],
    );
  }
}

class _LicenceList extends StatelessWidget {
  const _LicenceList({required this.snapshot});
  final RoleProfileSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LICENCES & RATINGS',
            style: AppText.label(
                fs: 10, letterSpacing: 0.8, fw: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        for (final l in snapshot.licences)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_rounded,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: l.title,
                      style: AppText.body(
                          fs: 12.5,
                          fw: FontWeight.w600,
                          color: AppColors.ink),
                      children: [
                        if (l.issuingAuthority.isNotEmpty)
                          TextSpan(
                            text: '  ${l.issuingAuthority}',
                            style: AppText.label(
                                fs: 11, color: AppColors.textMuted),
                          ),
                        if (l.expiryDate != null && l.expiryDate!.isNotEmpty)
                          TextSpan(
                            text: '  · valid to ${l.expiryDate}',
                            style: AppText.label(
                                fs: 11, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChipBlock extends StatelessWidget {
  const _ChipBlock({
    required this.title,
    required this.values,
    required this.color,
  });

  final String title;
  final List<String> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: AppText.label(
                  fs: 10, letterSpacing: 0.8, fw: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in values)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border:
                        Border.all(color: color.withValues(alpha: 0.28)),
                  ),
                  child: Text(v,
                      style: AppText.label(
                          fs: 10.5, color: color, fw: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.section,
    required this.dense,
    required this.canViewContactInfo,
  });
  final RoleProfileSection section;
  final bool dense;
  final bool canViewContactInfo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? AppSpacing.md : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title.toUpperCase(),
              style: AppText.label(
                  fs: 10, letterSpacing: 0.8, fw: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: LayoutBuilder(
                builder: (context, c) {
                  final withheld = item.sensitive && !canViewContactInfo;
                  final label = Text(item.label,
                      style: AppText.label(
                          fs: 11, color: AppColors.textMuted));
                  final value = Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (withheld) ...[
                        const Icon(Icons.lock_outline_rounded,
                            size: 13, color: AppColors.textFaint),
                        const SizedBox(width: 4),
                      ] else if (item.highlight) ...[
                        const Icon(Icons.flag_rounded,
                            size: 13, color: AppColors.warning),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          withheld ? 'Shared after admin approval' : item.value,
                          style: AppText.body(
                            fs: 12.5,
                            fw: withheld ? FontWeight.w400 : FontWeight.w500,
                            color: withheld
                                ? AppColors.textFaint
                                : (item.highlight
                                    ? AppColors.warning
                                    : AppColors.ink),
                          ),
                        ),
                      ),
                    ],
                  );
                  if (c.maxWidth < 460) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [label, const SizedBox(height: 2), value],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 210, child: label),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: value),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NoRoleProfile extends StatelessWidget {
  const _NoRoleProfile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.textFaint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'This candidate applied before role templates were introduced, '
              'so no role-specific profile was captured.',
              style: AppText.body(fs: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
