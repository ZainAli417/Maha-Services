import 'package:flutter/material.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';

/// Two taps to a `MM/YYYY` value: pick the year, pick the month, done.
///
/// Every date in this flow — licence expiry, a course, an employment range —
/// is a month and a year, never a day. Asking for one through a keyboard means
/// the candidate types, we validate, and they retype when the format is wrong.
/// A grid removes all of that: nothing invalid is reachable, and the answer
/// commits on the month tap rather than making them confirm a choice they can
/// already see.
class MonthYearPicker {
  const MonthYearPicker._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Long month names, for read-back in summaries.
  static const _monthsLong = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Renders `03/2021` as `Mar 2021`. Anything unparseable is passed through
  /// untouched rather than blanked — a legacy value the candidate can still
  /// read beats an empty field.
  static String format(String? value, {bool long = false}) {
    final raw = (value ?? '').trim();
    final m = RegExp(r'^(\d{1,2})/(\d{4})$').firstMatch(raw);
    if (m == null) return raw;
    final month = int.parse(m.group(1)!);
    if (month < 1 || month > 12) return raw;
    final name = long ? _monthsLong[month - 1] : _months[month - 1];
    return '$name ${m.group(2)}';
  }

  /// Returns `MM/YYYY`, an empty string when cleared, or null when dismissed —
  /// three outcomes the caller must keep distinct, since "cleared" is a real
  /// edit and "dismissed" must leave the existing value alone.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? initial,
    int yearsAhead = 12,
    int yearsBack = 60,
  }) {
    final now = DateTime.now();
    int? month;
    int year = now.year;

    final parsed = RegExp(r'^(\d{1,2})/(\d{4})$').firstMatch((initial ?? '').trim());
    if (parsed != null) {
      final m = int.parse(parsed.group(1)!);
      if (m >= 1 && m <= 12) month = m;
      year = int.tryParse(parsed.group(2)!) ?? year;
    }

    final years = [for (var y = now.year + yearsAhead; y >= now.year - yearsBack; y--) y];

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final isMobile = ctx.isMobile;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: AppColors.surface,
            titlePadding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.heading(fs: 15.5, fw: FontWeight.w700)),
                const SizedBox(height: 2),
                Builder(builder: (_) {
                  final m = month;
                  return Text(
                    m == null
                        ? 'Pick a year, then a month.'
                        : '${_monthsLong[m - 1]} $year',
                    style: AppText.body(fs: 12, color: AppColors.textMuted),
                  );
                }),
              ],
            ),
            content: SizedBox(
              width: isMobile ? double.maxFinite : 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('YEAR'),
                  const SizedBox(height: AppSpacing.sm),
                  // Bounded and scrollable: the list spans seven decades, and a
                  // Wrap of that would push the month grid off-screen.
                  SizedBox(
                    height: 132,
                    child: _YearGrid(
                      years: years,
                      selected: year,
                      onSelected: (y) {
                        Haptics.selection();
                        setState(() => year = y);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel('MONTH'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < 12; i++)
                        _GridChip(
                          label: _months[i],
                          selected: month == i + 1,
                          width: 72,
                          // Committing here is the point: the year is already
                          // visible above, so a confirm step would only be an
                          // extra tap on a choice they can see.
                          onTap: () {
                            Haptics.light();
                            Navigator.of(ctx)
                                .pop('${(i + 1).toString().padLeft(2, '0')}/$year');
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(''),
                child: Text('Clear',
                    style: AppText.label(fs: 12.5, color: AppColors.textMuted)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _sectionLabel(String text) => Text(
        text,
        style: AppText.label(
            fs: 10, color: AppColors.textFaint, letterSpacing: 0.8, fw: FontWeight.w700),
      );
}

/// Scrollable year grid that opens already showing the selected year.
class _YearGrid extends StatefulWidget {
  const _YearGrid({
    required this.years,
    required this.selected,
    required this.onSelected,
  });

  final List<int> years;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  State<_YearGrid> createState() => _YearGridState();
}

class _YearGridState extends State<_YearGrid> {
  late final ScrollController _controller;

  static const _perRow = 4;
  static const _rowHeight = 42.0;

  @override
  void initState() {
    super.initState();
    // Scroll so the current value is visible rather than making the candidate
    // hunt for it — the list runs from a decade ahead back to 1960-ish.
    final index = widget.years.indexOf(widget.selected);
    final row = index < 0 ? 0 : index ~/ _perRow;
    _controller = ScrollController(
      initialScrollOffset: (row * _rowHeight - _rowHeight).clamp(0.0, double.infinity),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      child: GridView.builder(
        controller: _controller,
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _perRow,
          mainAxisExtent: 34,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: widget.years.length,
        itemBuilder: (context, i) {
          final y = widget.years[i];
          return _GridChip(
            label: '$y',
            selected: y == widget.selected,
            onTap: () => widget.onSelected(y),
          );
        },
      ),
    );
  }
}

/// A tappable cell used for both years and months, so the two grids read as
/// one control instead of two different-looking ones.
class _GridChip extends StatelessWidget {
  const _GridChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.width,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surfaceAlt,
        borderRadius: AppRadius.smRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smRadius,
          child: Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.smRadius,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: AppText.label(
                fs: 12,
                fw: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
