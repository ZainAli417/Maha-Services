import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../Web_routes.dart' show AuthNotifier;
import '../../core/onboarding/models/aviation_role.dart';
import '../../core/onboarding/onboarding_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import 'widgets/question_field.dart';
import 'widgets/role_picker.dart';

/// Post-signup dynamic onboarding wizard. Chooses an aviation role, then walks
/// the candidate through role-specific question pages with progress,
/// skip/previous/save, and auto-save + resume.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnboardingProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = OnboardingProvider();
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

  Future<void> _finish() async {
    final ok = await _provider.complete();
    if (!mounted) return;
    if (ok) {
      // Continue to the existing profile builder (CV upload / manual).
      context.go('/profile-builder');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  void _skipAll() {
    // Skipping onboarding still lands the user in the profile builder; their
    // partial answers are already auto-saved.
    context.go('/profile-builder');
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
              if (p.loading) {
                return const LoadingView(message: 'Preparing your onboarding…');
              }
              if (p.error != null && p.roles.isEmpty) {
                return ErrorView(
                  message: p.error!,
                  onRetry: () {
                    final uid = context.read<AuthNotifier>().user?.uid;
                    if (uid != null) p.init(uid);
                  },
                );
              }
              if (p.role == null) {
                return RolePicker(
                  roles: p.roles,
                  onSelected: p.selectRole,
                  onSkip: _skipAll,
                );
              }
              return _WizardBody(onFinish: _finish, onSkipAll: _skipAll);
            },
          ),
        ),
      ),
    );
  }
}

class _WizardBody extends StatelessWidget {
  const _WizardBody({required this.onFinish, required this.onSkipAll});

  final Future<void> Function() onFinish;
  final VoidCallback onSkipAll;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    final role = p.role!;
    final questions = p.questionsForCurrentPage();
    final pageTitle = p.pages.isEmpty ? '' : p.pages[p.step];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            _Header(role: role, onSkipAll: onSkipAll),
            _ProgressBar(value: p.progress, step: p.step + 1, total: p.pages.length),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pageTitle,
                        style: AppText.heading(fs: 22, fw: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      'Step ${p.step + 1} of ${p.pages.length} · ${role.title}',
                      style: AppText.body(fs: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (questions.isEmpty)
                      Text('Nothing to fill on this step.',
                          style: AppText.body(color: AppColors.textMuted))
                    else
                      for (final q in questions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: QuestionField(
                            question: q,
                            value: p.answer(q.id),
                            onChanged: (v) => p.setAnswer(q.id, v),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            _Footer(onFinish: onFinish),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.role, required this.onSkipAll});
  final AviationRole role;
  final VoidCallback onSkipAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
      child: Row(
        children: [
          const Icon(Icons.flight_takeoff_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Aviation Onboarding',
                style: AppText.heading(fs: 16, fw: FontWeight.w700)),
          ),
          TextButton(onPressed: onSkipAll, child: const Text('Skip for now')),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar(
      {required this.value, required this.step, required this.total});
  final double value;
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: 8,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onFinish});
  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: p.isFirst ? null : () => p.previous(),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Previous'),
          ),
          const Spacer(),
          TextButton(
            onPressed: p.isLast ? null : () => p.skip(),
            child: const Text('Skip'),
          ),
          const SizedBox(width: 8),
          if (p.saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (p.isLast)
            ElevatedButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Finish'),
            )
          else
            ElevatedButton.icon(
              onPressed: () => p.next(),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Save & Continue'),
            ),
        ],
      ),
    );
  }
}
