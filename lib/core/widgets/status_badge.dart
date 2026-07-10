import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A pill badge tinted by semantic status. Use the named factories for the
/// common statuses used across the app so colors stay consistent.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  /// Maps a free-text status string to a themed badge.
  ///
  /// Recognizes the account/application/request statuses used across the app
  /// (active/pending/suspended/deleted/approved/rejected/…); unknown values
  /// fall back to a neutral slate badge.
  factory StatusBadge.forStatus(String? status) {
    final s = (status ?? '').toLowerCase().trim();
    switch (s) {
      case 'active':
      case 'approved':
      case 'open':
      case 'hired':
      case 'complete':
      case 'completed':
        return StatusBadge(
          label: _titleCase(s),
          color: AppColors.success,
          background: AppColors.successSoft,
        );
      case 'pending':
      case 'in_progress':
      case 'in progress':
      case 'review':
      case 'shortlist':
      case 'shortlisted':
        return StatusBadge(
          label: _titleCase(s),
          color: AppColors.warning,
          background: AppColors.warningSoft,
        );
      case 'suspended':
      case 'rejected':
      case 'deleted':
      case 'closed':
      case 'archived':
        return StatusBadge(
          label: _titleCase(s),
          color: AppColors.danger,
          background: AppColors.dangerSoft,
        );
      default:
        return StatusBadge(
          label: status == null || status.isEmpty ? 'Unknown' : status,
          color: AppColors.textMuted,
          background: AppColors.surfaceAlt,
        );
    }
  }

  static String _titleCase(String s) => s.isEmpty
      ? s
      : s
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: AppText.label(fs: 11, color: color, fw: FontWeight.w600)),
          ],
        ),
      );
}
