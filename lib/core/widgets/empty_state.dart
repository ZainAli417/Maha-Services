import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Reusable empty-state placeholder: icon, title, optional subtitle and action.
///
/// Extracted from the near-duplicate empty views across dashboards
/// (Recruiter dashboard `_EmptyView`, saved jobs, job hub, applications).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 16 : 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.08),
                    AppColors.accent.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: compact ? 36 : 48, color: color),
            ),
            SizedBox(height: compact ? 12 : 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.heading(fs: compact ? 16 : 20, fw: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppText.body(fs: 13, color: AppColors.textMuted),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
