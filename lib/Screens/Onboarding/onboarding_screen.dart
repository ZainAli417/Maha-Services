import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../Web_routes.dart' show AuthNotifier;
import '../../core/onboarding/models/question.dart';
import '../../core/onboarding/onboarding_provider.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import 'widgets/entry_mode_step.dart';
import 'widgets/history_editors.dart';
import 'widgets/question_field.dart';
import 'widgets/review_step.dart';
import 'widgets/role_picker.dart';

/// Post-signup onboarding: choose an industry and role, populate the role's
/// template from a CV or by hand, then submit a structured candidate profile.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnboardingProvider _provider = OnboardingProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthNotifier>().user?.uid;
      if (uid != null) _provider.init(uid);
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await _provider.submit();
    if (!mounted) return;
    // The end of a long form is the one moment worth a real thump, in both
    // directions — landed, or blocked.
    Haptics.medium();
    if (ok) {
      context.go('/dashboard');
    } else if (_provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_provider.error!)),
      );
    }
  }

  Future<void> _saveAndExit() async {
    await _provider.saveNow();
    if (!mounted) return;
    Haptics.light();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved — pick up where you left off.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Consumer<OnboardingProvider>(
            builder: (context, p, _) {
              switch (p.phase) {
                case OnboardingPhase.loading:
                  return const LoadingView(
                      message: 'Preparing your onboarding…');

                case OnboardingPhase.roleSelection:
                  if (p.error != null && p.templates.isEmpty) {
                    return ErrorView(
                      message: p.error!,
                      onRetry: () {
                        final uid = context.read<AuthNotifier>().user?.uid;
                        if (uid != null) p.init(uid);
                      },
                    );
                  }
                  return RolePicker(
                    templates: p.templates,
                    industries: p.industries,
                    industry: p.industry,
                    onIndustryChanged: p.selectIndustry,
                    onSelected: p.selectTemplate,
                  );

                case OnboardingPhase.entryMode:
                  return EntryModeStep(
                    template: p.template!,
                    onManual: p.chooseManual,
                    onCvPicked: p.uploadCv,
                    onChangeRole: p.changeRole,
                  );

                case OnboardingPhase.extracting:
                  return ExtractionProgress(
                      filename: p.cvFilename ?? 'your CV');

                case OnboardingPhase.form:
                case OnboardingPhase.submitted:
                  return _FormShell(
                    onSubmit: _submit,
                    onSaveAndExit: _saveAndExit,
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// FORM SHELL
// ══════════════════════════════════════════════════════════════════════════

class _FormShell extends StatelessWidget {
  const _FormShell({required this.onSubmit, required this.onSaveAndExit});

  final Future<void> Function() onSubmit;
  final Future<void> Function() onSaveAndExit;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    final wide = !context.isMobile && context.screenWidth >= AppBreakpoints.tablet;

    return Column(
      children: [
        _TopBar(onSaveAndExit: onSaveAndExit),
        if (!wide) _MobileProgress(provider: p),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide) _SectionRail(provider: p),
              Expanded(
                child: Stack(
                  children: [
                    _SectionBody(provider: p),
                    if (wide)
                      Positioned(
                        right: AppSpacing.xl,
                        bottom: AppSpacing.xl,
                        child: _SaveIndicator(state: p.saveState),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _ActionBar(onSubmit: onSubmit),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSaveAndExit});
  final Future<void> Function() onSaveAndExit;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    final template = p.template;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent]),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.badge_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template?.title ?? 'Your profile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.heading(fs: 14.5, fw: FontWeight.w800)),
                Text(
                  '${template?.industry ?? ''} · ${(p.completeness * 100).round()}% of required fields done',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(fs: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (!context.isMobile)
            TextButton.icon(
              onPressed: p.changeRole,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: const Text('Change role'),
            ),
          TextButton(
            onPressed: () => onSaveAndExit(),
            child: const Text('Save draft'),
          ),
        ],
      ),
    );
  }
}

/// Desktop: persistent section stepper with per-section completion state.
class _SectionRail extends StatelessWidget {
  const _SectionRail({required this.provider});
  final OnboardingProvider provider;

  @override
  Widget build(BuildContext context) {
    final sections = provider.sections;
    return Container(
      width: 268,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                AppSpacing.lg, AppSpacing.md),
            child: Row(
              children: [
                Text('YOUR PROGRESS',
                    style: AppText.label(
                        fs: 10.5,
                        color: AppColors.textFaint,
                        letterSpacing: 0.8,
                        fw: FontWeight.w700)),
                const Spacer(),
                Text('${provider.sectionIndex + 1}/${sections.length}',
                    style: AppText.label(
                        fs: 10.5,
                        color: AppColors.textFaint,
                        fw: FontWeight.w700)),
              ],
            ),
          ),
          for (var i = 0; i < sections.length; i++)
            _TimelineStop(
              index: i,
              title: sections[i].title,
              active: i == provider.sectionIndex,
              complete: provider.sectionIsComplete(i) &&
                  (provider.sectionWasVisited(i) || i < provider.sectionIndex),
              isFirst: i == 0,
              isLast: i == sections.length - 1,
              // The connector above a stop is "travelled" once the candidate
              // has reached it, which is what makes the rail read as a route
              // rather than a checklist.
              trackFilledAbove: i <= provider.sectionIndex,
              trackFilledBelow: i < provider.sectionIndex,
              onTap: () => provider.goToSection(i),
            ),
        ],
      ),
    );
  }
}

/// One stop on the vertical timeline: a node, the line running through it, and
/// the section label.
///
/// The line is drawn per-row rather than as one background stripe so each
/// segment can carry its own state — the travelled part reads solid, the part
/// still ahead stays faint — and so a row can grow with a two-line title
/// without the track breaking.
class _TimelineStop extends StatefulWidget {
  const _TimelineStop({
    required this.index,
    required this.title,
    required this.active,
    required this.complete,
    required this.isFirst,
    required this.isLast,
    required this.trackFilledAbove,
    required this.trackFilledBelow,
    required this.onTap,
  });

  final int index;
  final String title;
  final bool active;
  final bool complete;
  final bool isFirst;
  final bool isLast;
  final bool trackFilledAbove;
  final bool trackFilledBelow;
  final VoidCallback onTap;

  @override
  State<_TimelineStop> createState() => _TimelineStopState();
}

class _TimelineStopState extends State<_TimelineStop> {
  bool _hover = false;

  static const _nodeSize = 26.0;
  static const _railWidth = 34.0;

  @override
  Widget build(BuildContext context) {
    final reached = widget.complete || widget.active || widget.trackFilledAbove;
    final nodeColor = widget.complete
        ? AppColors.success
        : (widget.active ? AppColors.primary : AppColors.surfaceAlt);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: widget.active
              ? AppColors.primarySoft
              : (_hover ? AppColors.surfaceAlt : null),
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _railWidth + AppSpacing.lg,
                  child: Column(
                    children: [
                      Expanded(
                        child: _Track(
                          filled: widget.trackFilledAbove,
                          hidden: widget.isFirst,
                        ),
                      ),
                      _Node(
                        size: _nodeSize,
                        color: nodeColor,
                        bordered: !widget.complete && !widget.active,
                        ringed: widget.active,
                        child: widget.complete
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white)
                            : Text('${widget.index + 1}',
                                style: AppText.label(
                                  fs: 11,
                                  fw: FontWeight.w700,
                                  color: widget.active
                                      ? Colors.white
                                      : AppColors.textMuted,
                                )),
                      ),
                      Expanded(
                        child: _Track(
                          filled: widget.trackFilledBelow,
                          hidden: widget.isLast,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 2,
                          style: AppText.body(
                            fs: 12.5,
                            fw: widget.active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: widget.active
                                ? AppColors.primary
                                : (reached
                                    ? AppColors.textSecondary
                                    : AppColors.textMuted),
                          ),
                        ),
                        if (widget.active) ...[
                          const SizedBox(height: 1),
                          Text('In progress',
                              style: AppText.label(
                                  fs: 10, color: AppColors.primary)),
                        ] else if (widget.complete) ...[
                          const SizedBox(height: 1),
                          Text('Complete',
                              style: AppText.label(
                                  fs: 10, color: AppColors.success)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A segment of the vertical line. Kept as its own widget so the first and last
/// stops can suppress theirs without the column collapsing — an invisible
/// segment still holds the node in the same horizontal position.
class _Track extends StatelessWidget {
  const _Track({required this.filled, required this.hidden});

  final bool filled;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: 2,
        color: hidden
            ? Colors.transparent
            : (filled ? AppColors.primary : AppColors.border),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.size,
    required this.color,
    required this.bordered,
    required this.ringed,
    required this.child,
  });

  final double size;
  final Color color;
  final bool bordered;

  /// The current stop gets a soft halo so it is findable at a glance without
  /// relying on the fill colour alone.
  final bool ringed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: bordered ? AppColors.border : Colors.transparent,
        ),
        boxShadow: ringed
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

class _MobileProgress extends StatelessWidget {
  const _MobileProgress({required this.provider});
  final OnboardingProvider provider;

  @override
  Widget build(BuildContext context) {
    final section = provider.currentSection;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section?.title ?? '',
                  style: AppText.heading(fs: 13.5, fw: FontWeight.w700),
                ),
              ),
              Text(
                'Step ${provider.sectionIndex + 1} of ${provider.sections.length}',
                style: AppText.label(fs: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: provider.progress.clamp(0, 1)),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: AppColors.surfaceAlt,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.provider});
  final OnboardingProvider provider;

  @override
  Widget build(BuildContext context) {
    final section = provider.currentSection;
    if (section == null) {
      return const Center(child: Text('Nothing to fill in.'));
    }

    return SingleChildScrollView(
      key: PageStorageKey('onboarding_${section.title}'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        context.isMobile ? AppSpacing.xl : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey(section.title),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!context.isMobile) ...[
                  Text(section.title,
                      style:
                          AppText.heading(fs: 21, fw: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    _sectionBlurb(section, provider),
                    style: AppText.body(fs: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (provider.error != null) ...[
                  _ErrorBanner(
                      message: provider.error!, onDismiss: provider.clearError),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (provider.extraction != null &&
                    provider.sectionIndex == 0 &&
                    provider.extraction!.filledCount > 0) ...[
                  _ExtractionBanner(provider: provider),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _content(context, section),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, FormSection section) {
    switch (section.kind) {
      case SectionKind.questions:
        return _QuestionGrid(provider: provider, section: section);
      case SectionKind.experience:
        return ExperienceEditor(provider: provider);
      case SectionKind.education:
        return EducationEditor(provider: provider);
      case SectionKind.certifications:
        return CertificationEditor(provider: provider);
      case SectionKind.review:
        return ReviewStep(provider: provider);
    }
  }

  static String _sectionBlurb(FormSection s, OnboardingProvider p) {
    switch (s.kind) {
      case SectionKind.questions:
        final visible = p.visibleQuestions(s).length;
        final required =
            p.visibleQuestions(s).where((q) => q.required).length;
        return '$visible ${visible == 1 ? 'field' : 'fields'}'
            '${required > 0 ? ' · $required required' : ''}';
      case SectionKind.experience:
        return 'Your work history, most recent first.';
      case SectionKind.education:
        return 'Degrees, diplomas and academy training.';
      case SectionKind.certifications:
        return 'Courses and qualifications beyond your licences.';
      case SectionKind.review:
        return 'Check everything before it goes to recruiters.';
    }
  }
}

/// Two-column grid on desktop, single column on phones. A question with
/// `span: 2` always takes the full width.
class _QuestionGrid extends StatelessWidget {
  const _QuestionGrid({required this.provider, required this.section});

  final OnboardingProvider provider;
  final FormSection section;

  @override
  Widget build(BuildContext context) {
    final questions = provider.visibleQuestions(section);
    if (questions.isEmpty) {
      return Text('Nothing to fill in on this step.',
          style: AppText.body(color: AppColors.textMuted));
    }

    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 640 ? 2 : 1;
        const gap = AppSpacing.xl;
        final unit = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final q in questions)
              SizedBox(
                width: (columns == 1 || q.span >= 2) ? c.maxWidth : unit,
                child: QuestionField(
                  key: ValueKey(q.id),
                  question: q,
                  value: provider.answer(q.id),
                  prefilled: provider.wasPrefilled(q.id),
                  showError: provider.showErrors,
                  uploading: provider.uploadingIds.contains(q.id),
                  onChanged: (v) => provider.setAnswer(q.id, v),
                  onPickFile: q.type == QuestionType.file
                      ? () => _pickFor(context, q.id)
                      : null,
                  onRemoveFile: q.type == QuestionType.file
                      ? () => provider.removeDocument(q.id)
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickFor(BuildContext context, String questionId) async {
    final picked = await pickDocument(
      extensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'zip'],
    );
    if (picked == null) return;
    await provider.attachDocument(
      questionId: questionId,
      filename: picked.name,
      bytes: picked.bytes,
      contentType: _contentType(picked.name),
    );
  }

  static String _contentType(String filename) {
    switch (filename.toLowerCase().split('.').last) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onSubmit});
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    final isMobile = context.isMobile;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!p.isFirstSection)
              TextButton.icon(
                onPressed: () => p.previous(),
                icon: const Icon(Icons.arrow_back_rounded, size: 17),
                label: Text(isMobile ? '' : 'Previous'),
              ),
            const Spacer(),
            if (isMobile) _SaveIndicator(state: p.saveState, compact: true),
            const SizedBox(width: AppSpacing.sm),
            if (p.submitting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (p.currentSection?.kind == SectionKind.review)
              ElevatedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Submit profile'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => p.next(),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Continue'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Non-intrusive background auto-save feedback.
class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.state, this.compact = false});

  final SaveState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (state) {
      SaveState.idle => (Icons.cloud_outlined, 'Draft', AppColors.textFaint),
      SaveState.saving => (Icons.sync_rounded, 'Saving…', AppColors.textMuted),
      SaveState.saved => (
          Icons.cloud_done_rounded,
          'Saved',
          AppColors.success
        ),
      SaveState.error => (
          Icons.cloud_off_rounded,
          'Not saved',
          AppColors.danger
        ),
    };

    return AnimatedOpacity(
      opacity: state == SaveState.idle ? 0 : 1,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
          boxShadow: compact
              ? null
              : [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            if (!compact) ...[
              const SizedBox(width: 6),
              Text(label, style: AppText.label(fs: 11, color: color)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExtractionBanner extends StatelessWidget {
  const _ExtractionBanner({required this.provider});
  final OnboardingProvider provider;

  @override
  Widget build(BuildContext context) {
    final result = provider.extraction!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.infoSoft.withValues(alpha: 0.55),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.info.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 18, color: AppColors.info),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We pre-filled ${result.filledCount} '
                  '${result.filledCount == 1 ? 'item' : 'items'} from '
                  '${provider.cvFilename ?? 'your CV'}',
                  style: AppText.heading(fs: 13.5, fw: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'Fields marked "From CV" have not been checked by you yet. '
                  'Review them as you go — editing one clears the badge.',
                  style: AppText.body(
                      fs: 12, color: AppColors.textSecondary, height: 1.45),
                ),
                if (result.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  for (final note in result.notes.take(3))
                    Text('• $note',
                        style: AppText.body(
                            fs: 11.5, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 17, color: AppColors.danger),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message,
                style: AppText.body(fs: 12.5, color: AppColors.danger)),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            onPressed: onDismiss,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
