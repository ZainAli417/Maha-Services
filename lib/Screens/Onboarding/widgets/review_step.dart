import 'package:flutter/material.dart';

import '../../../core/onboarding/models/question.dart';
import '../../../core/onboarding/onboarding_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'history_editors.dart';

/// Final page — a section-by-section read-back with jump-to-fix links for
/// anything still missing.
class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key, required this.provider});

  final OnboardingProvider provider;

  @override
  Widget build(BuildContext context) {
    final missing = provider.allMissing;
    final template = provider.template;
    if (template == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (missing.isEmpty)
          _Banner(
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            background: AppColors.successSoft,
            title: 'Everything required is filled in',
            body:
                'Submit to publish your ${template.title} profile. You can keep '
                'editing it afterwards from your profile page.',
          )
        else
          _MissingBanner(provider: provider, missing: missing),
        const SizedBox(height: AppSpacing.xl),
        for (var i = 0; i < provider.sections.length; i++) ...[
          if (provider.sections[i].kind != SectionKind.review)
            _SectionSummary(
              provider: provider,
              index: i,
            ),
        ],
      ],
    );
  }
}

class _MissingBanner extends StatelessWidget {
  const _MissingBanner({required this.provider, required this.missing});

  final OnboardingProvider provider;
  final List<OnboardingQuestion> missing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${missing.length} required '
                  '${missing.length == 1 ? 'field is' : 'fields are'} still empty',
                  style: AppText.heading(fs: 14, fw: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final q in missing.take(12))
                ActionChip(
                  label: Text(q.label, style: AppText.label(fs: 11.5)),
                  avatar: const Icon(Icons.north_east_rounded, size: 13),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () => _jumpTo(provider, q),
                ),
              if (missing.length > 12)
                Text('+${missing.length - 12} more',
                    style: AppText.label(fs: 11.5, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  static void _jumpTo(OnboardingProvider provider, OnboardingQuestion q) {
    final index = provider.sections.indexWhere(
        (s) => s.questions.any((candidate) => candidate.id == q.id));
    if (index >= 0) provider.goToSection(index);
  }
}

class _SectionSummary extends StatelessWidget {
  const _SectionSummary({required this.provider, required this.index});

  final OnboardingProvider provider;
  final int index;

  @override
  Widget build(BuildContext context) {
    final section = provider.sections[index];
    final rows = _rowsFor(section);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(section.title,
                        style:
                            AppText.heading(fs: 14, fw: FontWeight.w700)),
                  ),
                  TextButton.icon(
                    onPressed: () => provider.goToSection(index),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: rows.isEmpty
                  ? Text('Nothing added.',
                      style:
                          AppText.body(fs: 12.5, color: AppColors.textFaint))
                  : Column(
                      children: [
                        for (final row in rows)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _SummaryRow(
                                label: row.$1, value: row.$2),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<(String, String)> _rowsFor(FormSection section) {
    switch (section.kind) {
      case SectionKind.questions:
        return [
          for (final q in provider.visibleQuestions(section))
            if (provider.answers[q.id] != null)
              (q.label, _display(provider.answers[q.id], q)),
        ];
      case SectionKind.experience:
        return [
          for (final e in provider.experience)
            (
              e.title.isEmpty ? 'Role' : e.title,
              [
                e.company,
                formatEntryRange(e.startDate, e.endDate, e.isCurrent),
              ].where((s) => s.isNotEmpty).join(' · '),
            ),
        ];
      case SectionKind.education:
        return [
          for (final e in provider.education)
            (
              e.institution.isEmpty ? 'Education' : e.institution,
              [e.degree, e.fieldOfStudy, e.graduationYear?.toString() ?? '']
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
            ),
        ];
      case SectionKind.certifications:
        return [
          for (final c in provider.certifications)
            (
              c.name.isEmpty ? 'Certification' : c.name,
              [c.issuer, c.issueDate].where((s) => s.isNotEmpty).join(' · '),
            ),
        ];
      case SectionKind.review:
        return const [];
    }
  }

  static String _display(dynamic value, OnboardingQuestion q) {
    if (value is List) return value.join(', ');
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is Map) {
      if (value.containsKey('value')) {
        final yes = value['value'] == true;
        final details = value['details']?.toString().trim() ?? '';
        if (!yes) return 'No';
        return details.isEmpty ? 'Yes' : 'Yes — $details';
      }
      if (value.containsKey('name')) return value['name'].toString();
    }
    final unit = q.unit;
    return unit == null ? value.toString() : '$value $unit';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < 460;
        final labelWidget = Text(label,
            style: AppText.label(fs: 11.5, color: AppColors.textMuted));
        final valueWidget = Text(
          value.isEmpty ? '—' : value,
          style: AppText.body(fs: 12.5, color: AppColors.ink, fw: FontWeight.w500),
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [labelWidget, const SizedBox(height: 2), valueWidget],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 200, child: labelWidget),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: valueWidget),
          ],
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.heading(fs: 14, fw: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(body,
                    style: AppText.body(
                        fs: 12.5, color: AppColors.textSecondary, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
