import 'package:flutter/material.dart';

import '../../../core/onboarding/models/aviation_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/search_field.dart';

/// Step 0 of onboarding: choose the aviation role that drives the questionnaire.
/// Roles are grouped by category and filterable by a search box.
class RolePicker extends StatefulWidget {
  const RolePicker({
    super.key,
    required this.roles,
    required this.onSelected,
    required this.onSkip,
  });

  final List<AviationRole> roles;
  final ValueChanged<AviationRole> onSelected;
  final VoidCallback onSkip;

  @override
  State<RolePicker> createState() => _RolePickerState();
}

class _RolePickerState extends State<RolePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.roles
        : widget.roles
            .where((r) =>
                r.title.toLowerCase().contains(_query.toLowerCase()) ||
                r.category.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    // Group by category, preserving first-seen order.
    final byCategory = <String, List<AviationRole>>{};
    for (final r in filtered) {
      byCategory.putIfAbsent(r.category, () => []).add(r);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What is your aviation role?',
                            style:
                                AppText.heading(fs: 24, fw: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          'We tailor your onboarding questions to your profession.',
                          style: AppText.body(
                              fs: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                      onPressed: widget.onSkip,
                      child: const Text('Skip for now')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: SearchField(
                hint: 'Search roles (e.g. pilot, avionics, ATC)…',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  for (final entry in byCategory.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          top: AppSpacing.sm, bottom: AppSpacing.md),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: AppText.label(
                            fs: 12,
                            color: AppColors.textMuted,
                            letterSpacing: 0.6),
                      ),
                    ),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final r in entry.value)
                          _RoleCard(
                              role: r,
                              onTap: () => widget.onSelected(r)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (byCategory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Center(
                        child: Text('No roles match "$_query".',
                            style: AppText.body(color: AppColors.textMuted)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.onTap});
  final AviationRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.work_outline_rounded,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  role.title,
                  style: AppText.heading(fs: 13, fw: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
