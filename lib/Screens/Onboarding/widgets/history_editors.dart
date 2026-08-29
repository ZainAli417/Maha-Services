import 'package:flutter/material.dart';

import '../../../core/onboarding/models/candidate_profile.dart';
import '../../../core/onboarding/onboarding_provider.dart';
import '../../../core/onboarding/option_catalog.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import 'month_year_picker.dart';
import 'option_picker.dart';

/// Repeatable work-history editor. Structured entries rather than one free-text
/// blob, so the dashboard timeline and recruiter search can read them.
class ExperienceEditor extends StatelessWidget {
  const ExperienceEditor({super.key, required this.provider});

  final OnboardingProvider provider;

  @override
  Widget build(BuildContext context) {
    return _RepeatableSection(
      emptyIcon: Icons.work_outline_rounded,
      emptyTitle: 'No roles added yet',
      emptyBody:
          'Add each position you have held. Most recent first is easiest to read.',
      addLabel: 'Add a role',
      onAdd: provider.addExperience,
      children: [
        for (var i = 0; i < provider.experience.length; i++)
          _ExperienceCard(
            key: ValueKey(provider.experience[i].id),
            entry: provider.experience[i],
            index: i,
            onChanged: (e) => provider.updateExperience(i, e),
            onRemove: () => provider.removeExperience(i),
          ),
      ],
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    super.key,
    required this.entry,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final ExperienceEntry entry;
  final int index;
  final ValueChanged<ExperienceEntry> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EntryCard(
      title: entry.title.isEmpty ? 'Role ${index + 1}' : entry.title,
      subtitle: entry.company,
      onRemove: onRemove,
      children: [
        _FieldGrid(
          children: [
            _LabeledField(
              label: 'Job title',
              required: true,
              child: _Input(
                value: entry.title,
                hint: 'e.g. First Officer',
                onChanged: (v) => onChanged(entry.copyWith(title: v)),
              ),
            ),
            _LabeledField(
              label: 'Company / organization',
              required: true,
              child: _Input(
                value: entry.company,
                hint: 'e.g. Emirates',
                onChanged: (v) => onChanged(entry.copyWith(company: v)),
              ),
            ),
            _LabeledField(
              label: 'Location',
              child: _Input(
                value: entry.location,
                hint: 'City, Country',
                onChanged: (v) => onChanged(entry.copyWith(location: v)),
              ),
            ),
            _LabeledField(
              label: 'Start date',
              child: _MonthYearField(
                value: entry.startDate,
                hint: 'Start date',
                onChanged: (v) => onChanged(entry.copyWith(startDate: v ?? '')),
              ),
            ),
            _LabeledField(
              label: 'End date',
              child: entry.isCurrent
                  ? const _StaticField(text: 'Present')
                  : _MonthYearField(
                      value: entry.endDate ?? '',
                      hint: 'End date',
                      onChanged: (v) => onChanged(entry.copyWith(endDate: v)),
                    ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Checkbox(
              value: entry.isCurrent,
              visualDensity: VisualDensity.compact,
              onChanged: (v) {
                Haptics.selection();
                onChanged(entry.copyWith(
                  isCurrent: v ?? false,
                  endDate: (v ?? false) ? null : entry.endDate,
                ));
              },
            ),
            Text('I currently work here',
                style: AppText.body(fs: 12.5, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _LabeledField(
          label: 'Key responsibilities',
          hint: 'One per line — these become the bullets on your profile.',
          child: _Input(
            value: entry.responsibilities.join('\n'),
            hint: 'Commanded line operations across the A320 fleet…',
            maxLines: 4,
            onChanged: (v) => onChanged(entry.copyWith(
              responsibilities: v
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList(),
            )),
          ),
        ),
      ],
    );
  }
}

/// Repeatable education editor.
class EducationEditor extends StatelessWidget {
  const EducationEditor({super.key, required this.provider});

  final OnboardingProvider provider;

  @override
  Widget build(BuildContext context) {
    return _RepeatableSection(
      emptyIcon: Icons.school_outlined,
      emptyTitle: 'No education added yet',
      emptyBody:
          'Add degrees, diplomas and academy training relevant to the role.',
      addLabel: 'Add education',
      onAdd: provider.addEducation,
      children: [
        for (var i = 0; i < provider.education.length; i++)
          _EducationCard(
            key: ValueKey(provider.education[i].id),
            entry: provider.education[i],
            index: i,
            onChanged: (e) => provider.updateEducation(i, e),
            onRemove: () => provider.removeEducation(i),
          ),
      ],
    );
  }
}

class _EducationCard extends StatelessWidget {
  const _EducationCard({
    super.key,
    required this.entry,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final EducationEntry entry;
  final int index;
  final ValueChanged<EducationEntry> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final years = [
      for (var y = DateTime.now().year + 8; y >= 1960; y--) y.toString(),
    ];
    return _EntryCard(
      title: entry.institution.isEmpty
          ? 'Education ${index + 1}'
          : entry.institution,
      subtitle: entry.degree,
      onRemove: onRemove,
      children: [
        _FieldGrid(
          children: [
            _LabeledField(
              label: 'Institution',
              required: true,
              child: _Input(
                value: entry.institution,
                hint: 'University or academy',
                onChanged: (v) => onChanged(entry.copyWith(institution: v)),
              ),
            ),
            _LabeledField(
              label: 'Qualification',
              child: _PickerField(
                value: entry.degree,
                hint: 'Select qualification',
                options: OptionCatalog.educationLevels,
                allowCustom: true,
                onChanged: (v) => onChanged(entry.copyWith(degree: v ?? '')),
              ),
            ),
            _LabeledField(
              label: 'Field of study',
              child: _PickerField(
                value: entry.fieldOfStudy,
                hint: 'Select field of study',
                options: OptionCatalog.fieldsOfStudy,
                allowCustom: true,
                onChanged: (v) =>
                    onChanged(entry.copyWith(fieldOfStudy: v ?? '')),
              ),
            ),
            _LabeledField(
              label: 'Graduation year',
              child: _PickerField(
                value: entry.graduationYear?.toString() ?? '',
                hint: 'Select year',
                options: years,
                onChanged: (v) => onChanged(
                    entry.copyWith(graduationYear: int.tryParse(v ?? ''))),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Repeatable certification editor.
class CertificationEditor extends StatelessWidget {
  const CertificationEditor({super.key, required this.provider});

  final OnboardingProvider provider;

  @override
  Widget build(BuildContext context) {
    return _RepeatableSection(
      emptyIcon: Icons.verified_outlined,
      emptyTitle: 'No certifications added yet',
      emptyBody:
          'Courses, ratings and qualifications beyond the licences you already '
          'listed.',
      addLabel: 'Add certification',
      onAdd: provider.addCertification,
      children: [
        for (var i = 0; i < provider.certifications.length; i++)
          _CertificationCard(
            key: ValueKey(provider.certifications[i].id),
            entry: provider.certifications[i],
            index: i,
            onChanged: (e) => provider.updateCertification(i, e),
            onRemove: () => provider.removeCertification(i),
          ),
      ],
    );
  }
}

class _CertificationCard extends StatelessWidget {
  const _CertificationCard({
    super.key,
    required this.entry,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final CertificationEntry entry;
  final int index;
  final ValueChanged<CertificationEntry> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EntryCard(
      title:
          entry.name.isEmpty ? 'Certification ${index + 1}' : entry.name,
      subtitle: entry.issuer,
      onRemove: onRemove,
      children: [
        _FieldGrid(
          children: [
            _LabeledField(
              label: 'Certification name',
              required: true,
              child: _Input(
                value: entry.name,
                hint: 'e.g. NEBOSH IGC',
                onChanged: (v) => onChanged(entry.copyWith(name: v)),
              ),
            ),
            _LabeledField(
              label: 'Issuing organization',
              child: _PickerField(
                value: entry.issuer,
                hint: 'Select issuer',
                options: OptionCatalog.certificationIssuers,
                allowCustom: true,
                onChanged: (v) => onChanged(entry.copyWith(issuer: v ?? '')),
              ),
            ),
            _LabeledField(
              label: 'Issued',
              child: _MonthYearField(
                value: entry.issueDate,
                hint: 'Issue date',
                onChanged: (v) => onChanged(entry.copyWith(issueDate: v ?? '')),
              ),
            ),
            _LabeledField(
              label: 'Expires',
              hint: 'Leave blank if it does not expire',
              child: _MonthYearField(
                value: entry.expiryDate ?? '',
                hint: 'Expiry date',
                onChanged: (v) => onChanged(entry.copyWith(expiryDate: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Shared building blocks ──────────────────────────────────────────────────

class _RepeatableSection extends StatelessWidget {
  const _RepeatableSection({
    required this.children,
    required this.onAdd,
    required this.addLabel,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyBody,
  });

  final List<Widget> children;
  final VoidCallback onAdd;
  final String addLabel;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyBody;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (children.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(emptyIcon, size: 30, color: AppColors.textFaint),
                const SizedBox(height: AppSpacing.md),
                Text(emptyTitle,
                    style: AppText.heading(fs: 14, fw: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(emptyBody,
                    textAlign: TextAlign.center,
                    style:
                        AppText.body(fs: 12.5, color: AppColors.textMuted)),
              ],
            ),
          )
        else
          for (final c in children) ...[
            c,
            const SizedBox(height: AppSpacing.md),
          ],
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () {
            Haptics.light();
            onAdd();
          },
          icon: const Icon(Icons.add_rounded, size: 17),
          label: Text(addLabel),
        ),
      ],
    );
  }
}

class _EntryCard extends StatefulWidget {
  const _EntryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onRemove,
    required this.children,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRemove;
  final List<Widget> children;

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Haptics.selection();
              setState(() => _expanded = !_expanded);
            },
            borderRadius: AppRadius.cardRadius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.heading(
                                fs: 13.5, fw: FontWeight.w700)),
                        if (widget.subtitle.isNotEmpty)
                          Text(widget.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(
                                  fs: 11.5, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.danger),
                    onPressed: () {
                      Haptics.medium();
                      widget.onRemove();
                    },
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

/// Two-column on wide screens, single column on phones.
class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 560 ? 2 : 1;
        const gap = AppSpacing.md;
        final width = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
    this.hint,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: AppText.label(fs: 11.5, fw: FontWeight.w600),
            children: [
              if (required)
                const TextSpan(
                    text: ' *', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(hint!,
                style: AppText.label(fs: 10.5, color: AppColors.textFaint)),
          ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _Input extends StatefulWidget {
  const _Input({
    required this.value,
    required this.onChanged,
    this.hint = '',
    this.maxLines = 1,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final int maxLines;

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void didUpdateWidget(covariant _Input old) {
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
      decoration: InputDecoration(hintText: widget.hint, isDense: true),
    );
  }
}

class _StaticField extends StatelessWidget {
  const _StaticField({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text,
          style: AppText.body(fs: 13, color: AppColors.textMuted)),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint = 'Select…',
    this.allowCustom = false,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String hint;
  final bool allowCustom;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    return InkWell(
      borderRadius: AppRadius.smRadius,
      onTap: () async {
        final picked = await OptionPicker.single(
          context,
          title: hint,
          options: options,
          selected: empty ? null : value,
          allowCustom: allowCustom,
        );
        if (picked == null) return;
        Haptics.light();
        onChanged(picked.isEmpty ? null : picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: AppRadius.smRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                empty ? hint : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                    fs: 13,
                    color: empty ? AppColors.textFaint : AppColors.ink),
              ),
            ),
            const Icon(Icons.expand_more_rounded,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// `MM/YYYY` value for the history rows, picked rather than typed.
///
/// This used to be a TextField with a slash-inserting formatter, which still
/// left the candidate typing four digits per date and let `13/2029` through.
/// The grid picker cannot produce an invalid month, needs two taps, and shows
/// the value back as "Mar 2021" instead of the storage format.
class _MonthYearField extends StatelessWidget {
  const _MonthYearField({
    required this.value,
    required this.onChanged,
    this.hint = 'Select month & year',
  });

  final String value;
  final ValueChanged<String?> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    return InkWell(
      borderRadius: AppRadius.smRadius,
      onTap: () async {
        final picked = await MonthYearPicker.show(
          context,
          title: hint,
          initial: value,
        );
        if (picked == null) return;
        onChanged(picked.isEmpty ? null : picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: AppRadius.smRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                empty ? hint : MonthYearPicker.format(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                    fs: 13,
                    color: empty ? AppColors.textFaint : AppColors.ink),
              ),
            ),
            const Icon(Icons.event_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Convenience used by the review step and the profile screen.
String formatEntryRange(String start, String? end, bool isCurrent) {
  final e = isCurrent ? 'Present' : (end ?? '');
  if (start.isEmpty && e.isEmpty) return '';
  if (start.isEmpty) return e;
  if (e.isEmpty) return start;
  return '$start — $e';
}

/// Kept for callers that need the breakpoint without importing the theme.
bool isCompactWidth(BuildContext context) => context.isMobile;
