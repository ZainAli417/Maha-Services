import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A KPI / metric card: label, big value, icon, accent color, optional sublabel
/// and delta. Extracted from the several near-duplicate stat cards across the
/// recruiter dashboard, job-seeker dashboard, admin analytics, and user mgmt.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.primary,
    this.sublabel,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? sublabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value,
              style: AppText.heading(fs: 24, fw: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: AppText.body(fs: 12, color: AppColors.textMuted)),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(sublabel!,
                style: AppText.label(fs: 11, color: AppColors.textFaint)),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: card,
    );
  }
}
