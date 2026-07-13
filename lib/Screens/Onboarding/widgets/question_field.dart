import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/onboarding/models/question.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Renders one [OnboardingQuestion] as the appropriate input. Structured inputs
/// (chips, radios, dropdowns, number/date pickers) are preferred to minimize
/// typing.
class QuestionField extends StatelessWidget {
  const QuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final OnboardingQuestion question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: question.label,
                  style: AppText.heading(fs: 14, fw: FontWeight.w600),
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
          ],
        ),
        if (question.helpText != null) ...[
          const SizedBox(height: 2),
          Text(question.helpText!,
              style: AppText.body(fs: 12, color: AppColors.textMuted)),
        ],
        const SizedBox(height: AppSpacing.sm),
        _input(context),
      ],
    );
  }

  Widget _input(BuildContext context) {
    switch (question.type) {
      case QuestionType.text:
        return _text(hint: 'Type your answer');
      case QuestionType.longText:
        return _text(hint: 'Type your answer', maxLines: 4);
      case QuestionType.number:
        return _number();
      case QuestionType.singleSelect:
        return _singleSelect();
      case QuestionType.multiSelect:
        return _multiSelect();
      case QuestionType.boolean:
        return _boolean();
      case QuestionType.date:
        return _date(context);
    }
  }

  Widget _text({required String hint, int maxLines = 1}) {
    return TextFormField(
      initialValue: value?.toString(),
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hint),
      onChanged: onChanged,
    );
  }

  Widget _number() {
    return TextFormField(
      initialValue: value?.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        hintText: 'Enter a number',
        suffixText: question.unit,
      ),
      onChanged: (v) => onChanged(v.isEmpty ? null : num.tryParse(v)),
    );
  }

  Widget _singleSelect() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final opt in question.options)
          ChoiceChip(
            label: Text(opt),
            selected: value == opt,
            onSelected: (_) => onChanged(value == opt ? null : opt),
          ),
      ],
    );
  }

  Widget _multiSelect() {
    final selected = (value is List)
        ? List<String>.from(value.map((e) => e.toString()))
        : <String>[];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final opt in question.options)
          FilterChip(
            label: Text(opt),
            selected: selected.contains(opt),
            onSelected: (on) {
              final next = List<String>.from(selected);
              on ? next.add(opt) : next.remove(opt);
              onChanged(next.isEmpty ? null : next);
            },
          ),
      ],
    );
  }

  Widget _boolean() {
    final v = value == true;
    return Row(
      children: [
        Switch(value: v, onChanged: onChanged),
        const SizedBox(width: 8),
        Text(v ? 'Yes' : 'No',
            style: AppText.body(fs: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _date(BuildContext context) {
    DateTime? current;
    if (value is String && (value as String).isNotEmpty) {
      current = DateTime.tryParse(value);
    }
    final label =
        current == null ? 'Select date' : DateFormat.yMMMd().format(current);
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today_rounded, size: 16),
      label: Text(label),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: current ?? DateTime(2015),
          firstDate: DateTime(1940),
          lastDate: DateTime(2100),
          helpText: question.label,
        );
        if (picked != null) onChanged(picked.toIso8601String());
      },
    );
  }
}
