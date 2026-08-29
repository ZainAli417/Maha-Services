import 'package:flutter/material.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';

/// Searchable option picker for lists too long to render as chips.
///
/// Presents as a bottom sheet on phones and a centered dialog on wider
/// screens, matching the responsive rules for the onboarding form.
class OptionPicker {
  const OptionPicker._();

  /// Single selection. Returns the chosen value, `''` to clear, or null when
  /// dismissed.
  static Future<String?> single(
    BuildContext context, {
    required String title,
    required List<String> options,
    String? selected,
    bool allowCustom = false,
    String searchHint = 'Search…',
  }) {
    return _show<String>(
      context,
      builder: (ctx, close) => _PickerBody(
        title: title,
        options: options,
        selected: selected == null ? const [] : [selected],
        multi: false,
        allowCustom: allowCustom,
        searchHint: searchHint,
        onDone: (values) => close(values.isEmpty ? '' : values.first),
      ),
    );
  }

  /// Multiple selection. Returns the full selection, or null when dismissed.
  static Future<List<String>?> multi(
    BuildContext context, {
    required String title,
    required List<String> options,
    List<String> selected = const [],
    bool allowCustom = false,
    int? maxSelect,
    String searchHint = 'Search…',
  }) {
    return _show<List<String>>(
      context,
      builder: (ctx, close) => _PickerBody(
        title: title,
        options: options,
        selected: selected,
        multi: true,
        allowCustom: allowCustom,
        maxSelect: maxSelect,
        searchHint: searchHint,
        onDone: close,
      ),
    );
  }

  static Future<T?> _show<T>(
    BuildContext context, {
    required Widget Function(BuildContext, void Function(T)) builder,
  }) {
    final isMobile = context.isMobile;
    if (isMobile) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.82,
            child: builder(ctx, (v) => Navigator.of(ctx).pop(v)),
          ),
        ),
      );
    }
    return showDialog<T>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: builder(ctx, (v) => Navigator.of(ctx).pop(v)),
        ),
      ),
    );
  }
}

class _PickerBody extends StatefulWidget {
  const _PickerBody({
    required this.title,
    required this.options,
    required this.selected,
    required this.multi,
    required this.allowCustom,
    required this.searchHint,
    required this.onDone,
    this.maxSelect,
  });

  final String title;
  final List<String> options;
  final List<String> selected;
  final bool multi;
  final bool allowCustom;
  final int? maxSelect;
  final String searchHint;
  final ValueChanged<List<String>> onDone;

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> {
  late final List<String> _selected = List.of(widget.selected);
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final q = _query.trim().toLowerCase();
    // Custom values the candidate added earlier are not in [options]; surface
    // them alongside so they can be toggled off again.
    final pool = <String>[
      ...widget.options,
      ..._selected.where((s) => !widget.options.contains(s)),
    ];
    if (q.isEmpty) return pool;
    final starts = <String>[];
    final contains = <String>[];
    for (final o in pool) {
      final lower = o.toLowerCase();
      if (lower.startsWith(q)) {
        starts.add(o);
      } else if (lower.contains(q)) {
        contains.add(o);
      }
    }
    return [...starts, ...contains];
  }

  bool get _canAddCustom {
    if (!widget.allowCustom) return false;
    final q = _query.trim();
    if (q.isEmpty) return false;
    return !widget.options.any((o) => o.toLowerCase() == q.toLowerCase()) &&
        !_selected.any((s) => s.toLowerCase() == q.toLowerCase());
  }

  bool get _atLimit =>
      widget.maxSelect != null && _selected.length >= widget.maxSelect!;

  void _toggle(String value) {
    if (!widget.multi) {
      Haptics.selection();
      widget.onDone([value]);
      return;
    }
    // A tap that the cap swallows still deserves a response — the heavier tick
    // says "heard you, but no" rather than leaving the row looking dead.
    if (!_selected.contains(value) && _atLimit) {
      Haptics.medium();
      return;
    }
    Haptics.selection();
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  void _addCustom() {
    final value = _query.trim();
    if (value.isEmpty) return;
    Haptics.selection();
    if (!widget.multi) {
      widget.onDone([value]);
      return;
    }
    setState(() {
      if (!_atLimit) _selected.add(value);
      _searchCtrl.clear();
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.md, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.title,
                    style: AppText.heading(fs: 16, fw: FontWeight.w700)),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
          child: TextField(
            controller: _searchCtrl,
            autofocus: !context.isMobile,
            textInputAction: TextInputAction.done,
            onChanged: (v) => setState(() => _query = v),
            onSubmitted: (_) => _canAddCustom ? _addCustom() : null,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.textFaint),
              isDense: true,
            ),
          ),
        ),
        if (widget.multi && _selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final s in _selected)
                    InputChip(
                      label: Text(s, style: AppText.label(fs: 11)),
                      onDeleted: () => setState(() => _selected.remove(s)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.primarySoft,
                      side: const BorderSide(color: AppColors.border),
                    ),
                ],
              ),
            ),
          ),
        if (_atLimit)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Maximum ${widget.maxSelect} selected',
                  style: AppText.label(fs: 11, color: AppColors.warning)),
            ),
          ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: results.isEmpty && !_canAddCustom
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'No matches for "$_query".',
                      style: AppText.body(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  itemCount: results.length + (_canAddCustom ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_canAddCustom && i == 0) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.add_rounded,
                            size: 18, color: AppColors.primary),
                        title: Text('Add "${_query.trim()}"',
                            style: AppText.body(
                                fs: 13,
                                fw: FontWeight.w600,
                                color: AppColors.primary)),
                        onTap: _addCustom,
                      );
                    }
                    final option = results[i - (_canAddCustom ? 1 : 0)];
                    final isSelected = _selected.contains(option);
                    return ListTile(
                      dense: true,
                      title: Text(option, style: AppText.body(fs: 13)),
                      leading: widget.multi
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggle(option),
                              visualDensity: VisualDensity.compact,
                            )
                          : Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textFaint,
                            ),
                      onTap: () => _toggle(option),
                    );
                  },
                ),
        ),
        if (widget.multi) ...[
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  '${_selected.length} selected',
                  style: AppText.label(fs: 12, color: AppColors.textMuted),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => setState(_selected.clear),
                  child: const Text('Clear'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () => widget.onDone(_selected),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
