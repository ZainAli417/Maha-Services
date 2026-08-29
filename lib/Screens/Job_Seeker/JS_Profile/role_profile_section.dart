import 'package:flutter/material.dart';

import '../../../core/onboarding/models/question.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../Onboarding/widgets/question_field.dart';
import 'JS_Profile_Provider.dart';

/// Renders the candidate's role-specific profile as one card per template
/// section, generated from the active role template rather than hardcoded.
///
/// Each card opens an edit sheet built from the same [QuestionField] controls
/// the onboarding form uses, so a template change reaches the profile editor
/// without a code change here.
class RoleProfileSections extends StatelessWidget {
  const RoleProfileSections({
    super.key,
    required this.provider,
    this.only,
    this.showHeader = true,
  });

  final ProfileProvider_NEW provider;

  /// Render just this template section. The profile screen promotes each
  /// section to its own tab, so it asks for one at a time; passing null keeps
  /// the original stacked-cards rendering for any caller that still wants the
  /// whole role in one scroll.
  final String? only;

  /// The role banner is drawn once per screen, not once per section.
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final template = provider.roleTemplate;
    final profile = provider.candidateProfile;

    if (template == null || profile == null) {
      return const _LegacyNotice();
    }

    final sections =
        only == null ? provider.roleSections : <String>[only!];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          _RoleHeader(
            roleTitle: profile.targetRole.roleTitle.isEmpty
                ? template.title
                : profile.targetRole.roleTitle,
            industry: profile.targetRole.industry,
            category: template.category,
            lastUpdated: profile.lastUpdated,
            isComplete: profile.isComplete,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        for (final section in sections)
          _SectionCard(
            provider: provider,
            section: section,
          ),
      ],
    );
  }
}

class _RoleHeader extends StatelessWidget {
  const _RoleHeader({
    required this.roleTitle,
    required this.industry,
    required this.category,
    required this.lastUpdated,
    required this.isComplete,
  });

  final String roleTitle;
  final String industry;
  final String category;
  final DateTime? lastUpdated;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.badge_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roleTitle,
                    style: AppText.heading(
                        fs: 16, fw: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  [industry, category].where((s) => s.isNotEmpty).join(' · '),
                  style: AppText.body(
                      fs: 12,
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          if (!context.isMobile)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                isComplete ? 'Complete' : 'Draft',
                style: AppText.label(
                    fs: 10.5, color: Colors.white, fw: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.provider, required this.section});

  final ProfileProvider_NEW provider;
  final String section;

  @override
  Widget build(BuildContext context) {
    final questions = provider.visibleQuestionsIn(section);
    if (questions.isEmpty) return const SizedBox.shrink();

    final answers = provider.candidateProfile?.answers ?? const {};
    final answered =
        questions.where((q) => q.isAnswered(answers[q.id])).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section,
                            style: AppText.heading(
                                fs: 14.5, fw: FontWeight.w700)),
                        Text('$answered of ${questions.length} filled',
                            style: AppText.label(
                                fs: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  for (final q in questions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _AnswerRow(
                        label: q.label,
                        value: formatAnswer(answers[q.id], q),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final questions = provider.visibleQuestionsIn(section);
    final current = Map<String, dynamic>.from(
        provider.candidateProfile?.answers ?? const {});

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _SectionEditDialog(
        title: section,
        questions: questions,
        initial: current,
      ),
    );
    if (result == null) return;

    final ok = await provider.saveRoleAnswers(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '$section updated' : 'Could not save $section'),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SectionEditDialog extends StatefulWidget {
  const _SectionEditDialog({
    required this.title,
    required this.questions,
    required this.initial,
  });

  final String title;
  final List<OnboardingQuestion> questions;
  final Map<String, dynamic> initial;

  @override
  State<_SectionEditDialog> createState() => _SectionEditDialogState();
}

class _SectionEditDialogState extends State<_SectionEditDialog> {
  late final Map<String, dynamic> _draft =
      Map<String, dynamic>.from(widget.initial);
  bool _showErrors = false;

  List<OnboardingQuestion> get _missing => widget.questions
      .where((q) => q.required && !q.isAnswered(_draft[q.id]))
      .toList();

  void _set(String id, dynamic value) {
    setState(() {
      final blank = value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty);
      if (blank) {
        _draft[id] = null;
      } else {
        _draft[id] = value;
      }
    });
  }

  void _submit() {
    if (_missing.isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    // Only the ids this dialog owns travel back, so a section edit can never
    // clobber an answer from another section.
    Navigator.of(context).pop({
      for (final q in widget.questions) q.id: _draft[q.id],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style:
                            AppText.heading(fs: 16, fw: FontWeight.w800)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final q in widget.questions)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.xl),
                        child: QuestionField(
                          question: q,
                          value: _draft[q.id],
                          showError: _showErrors,
                          onChanged: (v) => _set(q.id, v),
                          // Attachments are managed during onboarding; the
                          // profile editor shows them read-only.
                          onPickFile: null,
                          onRemoveFile: null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (_showErrors && _missing.isNotEmpty)
                    Expanded(
                      child: Text(
                        '${_missing.length} required '
                        '${_missing.length == 1 ? 'field' : 'fields'} left',
                        style:
                            AppText.label(fs: 11.5, color: AppColors.danger),
                      ),
                    )
                  else
                    const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Save changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final label0 = Text(this.label,
            style: AppText.label(fs: 11.5, color: AppColors.textMuted));
        final value0 = Text(
          value.isEmpty ? 'Not provided' : value,
          style: AppText.body(
            fs: 12.5,
            fw: FontWeight.w500,
            color: value.isEmpty ? AppColors.textFaint : AppColors.ink,
          ),
        );
        if (c.maxWidth < 460) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [label0, const SizedBox(height: 2), value0],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 230, child: label0),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: value0),
          ],
        );
      },
    );
  }
}

class _LegacyNotice extends StatelessWidget {
  const _LegacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.badge_outlined, size: 30, color: AppColors.textFaint),
          const SizedBox(height: AppSpacing.md),
          Text('No role profile yet',
              style: AppText.heading(fs: 14.5, fw: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'This account was created before role templates existed. Your '
            'other profile sections are unaffected — the answers below are '
            'what was captured at the time.',
            textAlign: TextAlign.center,
            style: AppText.body(fs: 12.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Renders a stored answer for display. Shared with the review step and the
/// dashboard so one answer never reads two different ways.
String formatAnswer(dynamic value, OnboardingQuestion q) {
  if (value == null) return '';
  if (value is List) return value.join(', ');
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is Map) {
    if (value.containsKey('value')) {
      final yes = value['value'] == true;
      final details = value['details']?.toString().trim() ?? '';
      if (!yes) return 'No';
      return details.isEmpty ? 'Yes' : 'Yes — $details';
    }
    if (value.containsKey('name')) return value['name'].toString();
  }
  final s = value.toString().trim();
  if (s.isEmpty) return '';
  return q.unit == null ? s : '$s ${q.unit}';
}
