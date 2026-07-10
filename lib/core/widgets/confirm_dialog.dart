import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A yes/no confirmation dialog. Returns `true` if confirmed, `false`/`null`
/// otherwise.
class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool danger = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final accent = danger ? AppColors.danger : AppColors.primary;
        return AlertDialog(
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: accent, size: 22),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(title,
                    style: AppText.heading(fs: 17, fw: FontWeight.w700)),
              ),
            ],
          ),
          content: Text(message,
              style: AppText.body(fs: 14, color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(cancelLabel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
