import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/onboarding/models/question.dart';
import '../../../core/onboarding/phone_codes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import 'month_year_picker.dart';
import 'option_picker.dart';

/// Renders one [OnboardingQuestion] as the densest structured control its type
/// allows. Raw text boxes appear only for the types that genuinely need one.
class QuestionField extends StatelessWidget {
  const QuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    this.prefilled = false,
    this.showError = false,
    this.uploading = false,
    this.onPickFile,
    this.onRemoveFile,
  });

  final OnboardingQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  /// The value came from the CV extractor and has not been touched yet.
  final bool prefilled;

  /// The section has been validated and this required field is still empty.
  final bool showError;

  final bool uploading;
  final VoidCallback? onPickFile;
  final VoidCallback? onRemoveFile;

  bool get _hasError => showError && question.required && !question.isAnswered(value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: question.label,
                  style: AppText.heading(fs: 13.5, fw: FontWeight.w600),
                  children: [
                    if (question.required)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.danger),
                      ),
                  ],
                ),
              ),
            ),
            if (prefilled) const _PrefilledBadge(),
          ],
        ),
        if (question.helpText != null) ...[
          const SizedBox(height: 3),
          Text(question.helpText!,
              style: AppText.body(fs: 11.5, color: AppColors.textMuted)),
        ],
        const SizedBox(height: AppSpacing.sm),
        _input(context),
        if (_hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 13, color: AppColors.danger),
              const SizedBox(width: 4),
              Text('This field is required',
                  style: AppText.label(fs: 11, color: AppColors.danger)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _input(BuildContext context) {
    switch (question.type) {
      case QuestionType.text:
        return _TextInput(
          key: ValueKey('${question.id}_text'),
          value: value?.toString() ?? '',
          hint: question.placeholder ?? 'Type your answer',
          hasError: _hasError,
          onChanged: onChanged,
        );
      case QuestionType.longText:
        return _TextInput(
          key: ValueKey('${question.id}_long'),
          value: value?.toString() ?? '',
          hint: question.placeholder ?? 'Type your answer',
          maxLines: 4,
          hasError: _hasError,
          onChanged: onChanged,
        );
      case QuestionType.number:
        return _NumberStepper(
          key: ValueKey('${question.id}_num'),
          value: value is num ? value as num : num.tryParse(value?.toString() ?? ''),
          unit: question.unit,
          min: question.min,
          max: question.max,
          hasError: _hasError,
          onChanged: onChanged,
        );
      case QuestionType.singleSelect:
        return question.options.length > 8
            ? _searchSingle(context)
            : _chipsSingle();
      case QuestionType.searchSelect:
        return _searchSingle(context);
      case QuestionType.multiSelect:
        return question.options.length > 12
            ? _searchMulti(context)
            : _chipsMulti();
      case QuestionType.searchMultiSelect:
        return _searchMulti(context);
      case QuestionType.tags:
        return _TagInput(
          key: ValueKey('${question.id}_tags'),
          values: _asList(value),
          hint: question.placeholder ?? 'Type and press enter',
          onChanged: onChanged,
        );
      case QuestionType.boolean:
        return _YesNoToggle(
          value: value == true,
          onChanged: onChanged,
        );
      case QuestionType.yesNoDetail:
        return _YesNoDetail(
          key: ValueKey('${question.id}_yesno'),
          value: value is Map ? Map<String, dynamic>.from(value as Map) : null,
          hasError: _hasError,
          onChanged: onChanged,
        );
      case QuestionType.date:
        return _DateButton(
          value: value?.toString(),
          label: question.label,
          hasError: _hasError,
          onChanged: onChanged,
        );
      case QuestionType.monthYear:
        return _MonthYearButton(
          value: value?.toString(),
          label: question.label,
          hasError: _hasError,
          onChanged: onChanged,
        );
      case QuestionType.phone:
        return _PhoneInput(
          key: ValueKey('${question.id}_phone'),
          value: value?.toString() ?? '',
          hasError: _hasError,
          onChanged: onChanged,
        );
      case QuestionType.file:
        return _FileSlot(
          document: value is Map ? Map<String, dynamic>.from(value as Map) : null,
          uploading: uploading,
          hasError: _hasError,
          onPick: onPickFile,
          onRemove: onRemoveFile,
        );
    }
  }

  // ── Selection variants ────────────────────────────────────────────────────

  Widget _chipsSingle() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final opt in question.options)
          ChoiceChip(
            label: Text(opt, style: AppText.label(fs: 12)),
            selected: value == opt,
            showCheckmark: false,
            selectedColor: AppColors.primarySoft,
            side: BorderSide(
              color: value == opt ? AppColors.primary : AppColors.border,
            ),
            onSelected: (_) {
              Haptics.selection();
              onChanged(value == opt ? null : opt);
            },
          ),
      ],
    );
  }

  Widget _chipsMulti() {
    final selected = _asList(value);
    final atLimit =
        question.maxSelect != null && selected.length >= question.maxSelect!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final opt in question.options)
          FilterChip(
            label: Text(opt, style: AppText.label(fs: 12)),
            selected: selected.contains(opt),
            selectedColor: AppColors.primarySoft,
            checkmarkColor: AppColors.primary,
            side: BorderSide(
              color:
                  selected.contains(opt) ? AppColors.primary : AppColors.border,
            ),
            onSelected: (on) {
              // A blocked tap at the cap gets the heavier tick — silence would
              // read as the control being broken.
              if (on && atLimit) {
                Haptics.medium();
                return;
              }
              Haptics.selection();
              final next = List<String>.from(selected);
              if (on) {
                next.add(opt);
              } else {
                next.remove(opt);
              }
              onChanged(next.isEmpty ? null : next);
            },
          ),
      ],
    );
  }

  Widget _searchSingle(BuildContext context) {
    final current = value?.toString();
    return _PickerButton(
      label: current?.isNotEmpty == true ? current! : (question.placeholder ?? 'Select…'),
      isEmpty: current == null || current.isEmpty,
      hasError: _hasError,
      onClear: current == null || current.isEmpty ? null : () => onChanged(null),
      onTap: () async {
        final picked = await OptionPicker.single(
          context,
          title: question.label,
          options: question.options,
          selected: current,
          allowCustom: question.allowCustom,
        );
        if (picked == null) return;
        Haptics.light();
        onChanged(picked.isEmpty ? null : picked);
      },
    );
  }

  Widget _searchMulti(BuildContext context) {
    final selected = _asList(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final s in selected)
                  InputChip(
                    label: Text(s, style: AppText.label(fs: 11.5)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primarySoft,
                    side: const BorderSide(color: AppColors.border),
                    onDeleted: () {
                      final next = List<String>.from(selected)..remove(s);
                      onChanged(next.isEmpty ? null : next);
                    },
                  ),
              ],
            ),
          ),
        _PickerButton(
          label: selected.isEmpty
              ? (question.placeholder ?? 'Search and select…')
              : 'Add or edit selection (${selected.length})',
          isEmpty: selected.isEmpty,
          hasError: _hasError,
          icon: Icons.search_rounded,
          onTap: () async {
            final picked = await OptionPicker.multi(
              context,
              title: question.label,
              options: question.options,
              selected: selected,
              allowCustom: question.allowCustom,
              maxSelect: question.maxSelect,
            );
            if (picked == null) return;
            Haptics.light();
            onChanged(picked.isEmpty ? null : picked);
          },
        ),
      ],
    );
  }

  static List<String> _asList(dynamic v) => v is List
      ? v.map((e) => e.toString()).toList()
      : (v == null ? <String>[] : [v.toString()]);
}

class _PrefilledBadge extends StatelessWidget {
  const _PrefilledBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 11, color: AppColors.info),
          const SizedBox(width: 3),
          Text('From CV',
              style: AppText.label(
                  fs: 9.5, color: AppColors.info, fw: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Text input that stays in sync when the value is replaced from outside
/// (CV prefill, resumed draft) without stealing the caret while typing.
class _TextInput extends StatefulWidget {
  const _TextInput({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
    this.maxLines = 1,
    this.hasError = false,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final bool hasError;

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void didUpdateWidget(covariant _TextInput old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text && !_focus.hasFocus) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      style: AppText.body(fs: 13, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: widget.hint,
        isDense: true,
        enabledBorder: widget.hasError ? _errorBorder : null,
      ),
    );
  }
}

final OutlineInputBorder _errorBorder = OutlineInputBorder(
  borderRadius: AppRadius.smRadius,
  borderSide: const BorderSide(color: AppColors.danger),
);

/// Numeric entry with tap-to-step controls — faster than typing on mobile and
/// it keeps the value inside the field's bounds.
class _NumberStepper extends StatefulWidget {
  const _NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.unit,
    this.min,
    this.max,
    this.hasError = false,
  });

  final num? value;
  final ValueChanged<num?> onChanged;
  final String? unit;
  final num? min;
  final num? max;
  final bool hasError;

  @override
  State<_NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<_NumberStepper> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value?.toString() ?? '');
  final _focus = FocusNode();

  @override
  void didUpdateWidget(covariant _NumberStepper old) {
    super.didUpdateWidget(old);
    final text = widget.value?.toString() ?? '';
    if (text != _controller.text && !_focus.hasFocus) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Step size scales with magnitude: single hours at the low end, hundreds
  /// once a pilot is logging thousands.
  num get _step {
    final v = widget.value ?? 0;
    if (v >= 1000) return 100;
    if (v >= 100) return 10;
    return 1;
  }

  void _bump(num delta) {
    var next = (widget.value ?? 0) + delta;
    if (widget.min != null && next < widget.min!) next = widget.min!;
    if (widget.max != null && next > widget.max!) next = widget.max!;
    Haptics.selection();
    _controller.text = next.toString();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          onTap: (widget.value ?? 0) <= (widget.min ?? 0)
              ? null
              : () => _bump(-_step),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: AppText.heading(fs: 14, fw: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0',
              isDense: true,
              suffixText: widget.unit,
              suffixStyle: AppText.label(fs: 11, color: AppColors.textMuted),
              enabledBorder: widget.hasError ? _errorBorder : null,
            ),
            onChanged: (v) {
              if (v.isEmpty) return widget.onChanged(null);
              final parsed = num.tryParse(v);
              if (parsed == null) return;
              if (widget.max != null && parsed > widget.max!) return;
              widget.onChanged(parsed);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _StepButton(
          icon: Icons.add_rounded,
          onTap: widget.max != null && (widget.value ?? 0) >= widget.max!
              ? null
              : () => _bump(_step),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smRadius,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceAlt : AppColors.background,
          borderRadius: AppRadius.smRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? AppColors.textSecondary : AppColors.textFaint),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.isEmpty,
    required this.onTap,
    this.hasError = false,
    this.icon = Icons.expand_more_rounded,
    this.onClear,
  });

  final String label;
  final bool isEmpty;
  final VoidCallback onTap;
  final bool hasError;
  final IconData icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: AppRadius.smRadius,
          border: Border.all(
              color: hasError ? AppColors.danger : AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  fs: 13,
                  color: isEmpty ? AppColors.textFaint : AppColors.ink,
                  fw: isEmpty ? FontWeight.w400 : FontWeight.w500,
                ),
              ),
            ),
            if (onClear != null)
              InkWell(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textFaint),
                ),
              ),
            Icon(icon, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Free-form pill entry for values no list can enumerate.
class _TagInput extends StatefulWidget {
  const _TagInput({
    super.key,
    required this.values,
    required this.hint,
    required this.onChanged,
  });

  final List<String> values;
  final String hint;
  final ValueChanged<List<String>?> onChanged;

  @override
  State<_TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<_TagInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final value = raw.trim();
    if (value.isEmpty || widget.values.contains(value)) {
      _controller.clear();
      return;
    }
    Haptics.selection();
    widget.onChanged([...widget.values, value]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.values.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final v in widget.values)
                  InputChip(
                    label: Text(v, style: AppText.label(fs: 11.5)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.surfaceAlt,
                    side: const BorderSide(color: AppColors.border),
                    onDeleted: () {
                      Haptics.selection();
                      final next = List<String>.from(widget.values)..remove(v);
                      widget.onChanged(next.isEmpty ? null : next);
                    },
                  ),
              ],
            ),
          ),
        TextField(
          controller: _controller,
          onSubmitted: _add,
          style: AppText.body(fs: 13, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: widget.hint,
            isDense: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded, size: 18),
              onPressed: () => _add(_controller.text),
              tooltip: 'Add',
            ),
          ),
        ),
      ],
    );
  }
}

class _YesNoToggle extends StatelessWidget {
  const _YesNoToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('Yes')),
        ButtonSegment(value: false, label: Text('No')),
      ],
      selected: {value},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(AppText.label(fs: 12.5)),
      ),
      onSelectionChanged: (s) {
        Haptics.selection();
        onChanged(s.first);
      },
    );
  }
}

/// Yes/No where "Yes" demands a narrative — the declaration pattern the
/// compliance sections use for violations, incidents and sanctions.
class _YesNoDetail extends StatefulWidget {
  const _YesNoDetail({
    super.key,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final Map<String, dynamic>? value;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final bool hasError;

  @override
  State<_YesNoDetail> createState() => _YesNoDetailState();
}

class _YesNoDetailState extends State<_YesNoDetail> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value?['details']?.toString() ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool? get _flag => widget.value?['value'] is bool
      ? widget.value!['value'] as bool
      : null;

  @override
  Widget build(BuildContext context) {
    final flag = _flag;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final option in const [true, false])
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(option ? 'Yes' : 'No',
                      style: AppText.label(fs: 12.5)),
                  selected: flag == option,
                  showCheckmark: false,
                  selectedColor: option ? AppColors.warningSoft : AppColors.primarySoft,
                  side: BorderSide(
                    color: flag == option
                        ? (option ? AppColors.warning : AppColors.primary)
                        : AppColors.border,
                  ),
                  onSelected: (_) {
                    Haptics.selection();
                    widget.onChanged({
                      'value': option,
                      'details': option ? _controller.text.trim() : '',
                    });
                  },
                ),
              ),
          ],
        ),
        if (flag == true) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            maxLines: 3,
            style: AppText.body(fs: 13, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Provide the details — dates, authority, outcome',
              isDense: true,
              enabledBorder: widget.hasError ? _errorBorder : null,
            ),
            onChanged: (v) =>
                widget.onChanged({'value': true, 'details': v.trim()}),
          ),
        ],
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.value,
    required this.label,
    required this.onChanged,
    this.hasError = false,
  });

  final String? value;
  final String label;
  final ValueChanged<String?> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final current =
        value == null || value!.isEmpty ? null : DateTime.tryParse(value!);
    return _PickerButton(
      label: current == null ? 'Select date' : DateFormat.yMMMd().format(current),
      isEmpty: current == null,
      hasError: hasError,
      icon: Icons.calendar_today_rounded,
      onClear: current == null ? null : () => onChanged(null),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: current ?? DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime(DateTime.now().year + 20),
          helpText: label,
        );
        if (picked != null) onChanged(picked.toIso8601String());
      },
    );
  }
}

/// `MM/YYYY` picker — checkride and licence dates are recorded to the month.
/// Delegates to the shared [MonthYearPicker] so this control and the ones in
/// the experience/education/certification rows behave identically.
class _MonthYearButton extends StatelessWidget {
  const _MonthYearButton({
    required this.value,
    required this.label,
    required this.onChanged,
    this.hasError = false,
  });

  final String? value;
  final String label;
  final ValueChanged<String?> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final empty = value == null || value!.isEmpty;
    return _PickerButton(
      label: empty ? 'Select month & year' : MonthYearPicker.format(value),
      isEmpty: empty,
      hasError: hasError,
      icon: Icons.event_rounded,
      onClear: empty
          ? null
          : () {
              Haptics.selection();
              onChanged(null);
            },
      onTap: () async {
        final picked = await MonthYearPicker.show(
          context,
          title: label,
          initial: value,
        );
        if (picked != null) onChanged(picked.isEmpty ? null : picked);
      },
    );
  }
}

class _FileSlot extends StatelessWidget {
  const _FileSlot({
    required this.document,
    required this.uploading,
    required this.hasError,
    this.onPick,
    this.onRemove,
  });

  final Map<String, dynamic>? document;
  final bool uploading;
  final bool hasError;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    if (uploading) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: AppRadius.smRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('Uploading…',
                style: AppText.body(fs: 12.5, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    if (document != null) {
      final name = document!['name']?.toString() ?? 'Attached file';
      final size = document!['size'];
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.successSoft.withValues(alpha: 0.45),
          borderRadius: AppRadius.smRadius,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_rounded,
                size: 18, color: AppColors.success),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.heading(fs: 12.5, fw: FontWeight.w600)),
                  if (size is int && size > 0)
                    Text(_readable(size),
                        style:
                            AppText.label(fs: 10.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Replace',
              icon: const Icon(Icons.refresh_rounded, size: 17),
              onPressed: onPick,
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 17, color: AppColors.danger),
              onPressed: onRemove,
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onPick,
      borderRadius: AppRadius.smRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: AppRadius.smRadius,
          border: Border.all(
            color: hasError ? AppColors.danger : AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.upload_file_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text('Choose a file — PDF, DOCX or image, up to 10MB',
                  style: AppText.body(fs: 12.5, color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  static String _readable(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(0)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Dial code and national number as two separate controls.
///
/// A single free-text phone box asks the candidate to remember their own
/// country code, type a `+`, and get the spacing right — and it silently
/// accepts anything, so a number that cannot be dialled reaches the recruiter
/// looking valid. Splitting it means the country half cannot be wrong at all,
/// and the number half only has to hold digits.
///
/// The two halves are joined back into one string before storage, so nothing
/// downstream of the form knows this control exists.
class _PhoneInput extends StatefulWidget {
  const _PhoneInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  State<_PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<_PhoneInput> {
  late PhoneCountry _country;
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    final split = PhoneCodes.split(widget.value);
    _country = split.country;
    _controller = TextEditingController(text: split.number);
  }

  @override
  void didUpdateWidget(covariant _PhoneInput old) {
    super.didUpdateWidget(old);
    // Only re-seed from outside when the field is idle: a CV extraction landing
    // mid-edit must not yank the cursor out from under the candidate.
    if (widget.value != old.value && !_focus.hasFocus) {
      final split = PhoneCodes.split(widget.value);
      _country = split.country;
      if (_controller.text != split.number) _controller.text = split.number;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(PhoneCodes.join(_country, _controller.text));

  Future<void> _pickCountry() async {
    Haptics.selection();
    final labels = [for (final c in PhoneCodes.ordered) c.label];
    final picked = await OptionPicker.single(
      context,
      title: 'Country code',
      options: labels,
      selected: _country.label,
      searchHint: 'Search country or code…',
    );
    if (picked == null || !mounted) return;
    final match = PhoneCodes.ordered.firstWhere(
      (c) => c.label == picked,
      orElse: () => _country,
    );
    Haptics.light();
    setState(() => _country = match);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickCountry,
          borderRadius: AppRadius.smRadius,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: AppRadius.smRadius,
              border: Border.all(
                color: widget.hasError ? AppColors.danger : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_country.flag, style: const TextStyle(fontSize: 17)),
                const SizedBox(width: 6),
                Text(_country.dialCode,
                    style: AppText.body(fs: 13, color: AppColors.ink)),
                const SizedBox(width: 2),
                const Icon(Icons.expand_more_rounded,
                    size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            keyboardType: TextInputType.phone,
            // Digits and the separators people actually paste. The dial code
            // lives in the button, so a leading `+` here would duplicate it.
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 \-()]')),
              LengthLimitingTextInputFormatter(18),
            ],
            style: AppText.body(fs: 13, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: '50 123 4567',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 12),
              enabledBorder: widget.hasError ? _errorBorder : null,
            ),
            onChanged: (_) => _emit(),
          ),
        ),
      ],
    );
  }
}
