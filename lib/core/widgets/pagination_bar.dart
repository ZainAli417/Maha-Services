import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Simple prev/next pagination control with an optional range label.
///
/// Works for both client-side page indexes and Firestore cursor paging: the
/// caller decides what `onPrev`/`onNext` do and whether they are enabled.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.onPrev,
    required this.onNext,
    this.label,
    this.canPrev = true,
    this.canNext = true,
  });

  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final String? label;
  final bool canPrev;
  final bool canNext;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (label != null) ...[
            Text(label!,
                style: AppText.body(fs: 12, color: AppColors.textMuted)),
            const SizedBox(width: 12),
          ],
          IconButton(
            onPressed: canPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Previous',
          ),
          IconButton(
            onPressed: canNext ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Next',
          ),
        ],
      );
}
