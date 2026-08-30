import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import 'assessment_platform.dart';
import 'assessment_provider.dart';

/// The candidate's assessment, start to finish.
///
/// Deliberately not inside the app shell: no navigation rail, no top bar, no
/// route out. A timed test that shares a frame with the rest of the product
/// invites a candidate to wander off mid-question and then dispute the clock.
class AssessmentScreen extends StatelessWidget {
  const AssessmentScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Keyed by token so a different link never reuses a live sitting's state.
      key: ValueKey(token),
      create: (_) => AssessmentProvider(token)..load(),
      child: const _AssessmentView(),
    );
  }
}

class _AssessmentView extends StatefulWidget {
  const _AssessmentView();

  @override
  State<_AssessmentView> createState() => _AssessmentViewState();
}

class _AssessmentViewState extends State<_AssessmentView> with WidgetsBindingObserver {
  bool _guardArmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    setExitGuard(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Leaving the tab or backgrounding the app is what a tab-switch looks like
  /// from inside Flutter — the same signal on web and on Android, with no
  /// platform code and no JavaScript listener to keep in sync.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      final provider = context.read<AssessmentProvider>();
      if (provider.isRunning) provider.reportEvent('blur');
    }
  }

  void _syncExitGuard(bool running) {
    if (running == _guardArmed) return;
    _guardArmed = running;
    setExitGuard(running);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    _syncExitGuard(provider.isRunning);

    return PopScope(
      // The one hard rule of the whole test: there is no way back. Enforced on
      // the server too — the cursor only ever moves forward — so this is the
      // courtesy half of it, not the control.
      canPop: !provider.isRunning,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _body(context, provider),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AssessmentProvider p) {
    switch (p.phase) {
      case AssessmentPhase.loading:
        return const Center(key: ValueKey('loading'), child: CircularProgressIndicator());
      case AssessmentPhase.invitation:
      case AssessmentPhase.ready:
        return _Briefing(key: const ValueKey('brief'), provider: p);
      case AssessmentPhase.question:
      case AssessmentPhase.feedback:
        return _Sitting(key: const ValueKey('sitting'), provider: p);
      case AssessmentPhase.finished:
        return _Finished(key: const ValueKey('done'), provider: p);
      case AssessmentPhase.expired:
        return const _Closed(
          key: ValueKey('expired'),
          icon: Icons.hourglass_disabled_rounded,
          title: 'This invitation has expired',
          body: 'The 24-hour window has passed. Contact the recruitment team if '
              'you would still like to be considered.',
        );
      case AssessmentPhase.error:
        return _Closed(
          key: const ValueKey('error'),
          icon: Icons.error_outline_rounded,
          title: 'Something went wrong',
          body: p.error,
          onRetry: p.load,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BRIEFING
// ═══════════════════════════════════════════════════════════════════════════

class _Briefing extends StatelessWidget {
  const _Briefing({super.key, required this.provider});

  final AssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    final accepted = provider.phase == AssessmentPhase.ready;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Badge(text: 'Online assessment'),
              const SizedBox(height: 16),
              Text(
                provider.jobTitle.isEmpty ? 'Your application' : provider.jobTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.2,
                ),
              ),
              if (provider.company.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(provider.company,
                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 24),

              Row(
                children: [
                  _Stat(
                    label: 'Questions',
                    value: '${provider.questionCount}',
                    icon: Icons.list_alt_rounded,
                  ),
                  const SizedBox(width: 12),
                  _Stat(
                    label: 'Per question',
                    value: '${provider.questionSeconds}s',
                    icon: Icons.timer_outlined,
                  ),
                  const SizedBox(width: 12),
                  _Stat(
                    label: 'One sitting',
                    value: '${provider.sittingMinutes} min',
                    icon: Icons.event_available_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Before you begin',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 10),
              ...provider.rules.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(Icons.check_circle_outline_rounded,
                              size: 17, color: AppColors.primaryLight),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r,
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  )),

              if (provider.expiresAt != null && !accepted) ...[
                const SizedBox(height: 8),
                _Notice(
                  icon: Icons.schedule_rounded,
                  tone: AppColors.warning,
                  soft: AppColors.warningSoft,
                  text: 'You have until ${_formatDeadline(provider.expiresAt!)} to start.',
                ),
              ],

              if (accepted) ...[
                const SizedBox(height: 8),
                const _Notice(
                  icon: Icons.lock_clock_rounded,
                  tone: AppColors.danger,
                  soft: AppColors.dangerSoft,
                  text: 'Once you press Start, the clock runs until the test is '
                      'finished — closing this page will not pause it.',
                ),
              ],

              if (provider.error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(provider.error,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: provider.busy
                      ? null
                      : () => accepted ? provider.start() : provider.accept(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: accepted ? AppColors.success : AppColors.primary,
                  ),
                  child: provider.busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          accepted ? 'Start the assessment' : 'Accept the invitation',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              if (!accepted) ...[
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Accepting does not start the clock. You choose when to begin.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDeadline(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]}, $hh:$mm';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  THE SITTING
// ═══════════════════════════════════════════════════════════════════════════

class _Sitting extends StatefulWidget {
  const _Sitting({super.key, required this.provider});

  final AssessmentProvider provider;

  @override
  State<_Sitting> createState() => _SittingState();
}

class _SittingState extends State<_Sitting> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  int? _buzzedFor;

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// Fires the haptic and the shake once per graded answer.
  ///
  /// Guarded by the question index because the provider notifies several times
  /// while the feedback is on screen, and a buzz per rebuild would be a
  /// vibrating phone rather than a signal.
  void _feedbackEffects(AssessmentProvider p) {
    if (p.phase != AssessmentPhase.feedback) return;
    final index = p.question?.index;
    if (index == null || _buzzedFor == index) return;
    _buzzedFor = index;

    if (p.wasCorrect == true) {
      vibrate(40);
    } else {
      vibrate(180);
      _shake.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final q = p.question;
    if (q == null) return const Center(child: CircularProgressIndicator());

    _feedbackEffects(p);
    final showing = p.phase == AssessmentPhase.feedback;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressHeader(provider: p, question: q),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (q.topic.isNotEmpty) ...[
                    _Badge(text: q.topic),
                    const SizedBox(height: 12),
                  ],
                  // Selection is off across the question and the options: it
                  // is the first step of copying a question out to look up.
                  SelectionContainer.disabled(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.text,
                          style: const TextStyle(
                            fontSize: 20,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 22),
                        AnimatedBuilder(
                          animation: _shake,
                          builder: (context, child) {
                            // A short damped wobble, only on a wrong answer.
                            final t = _shake.value;
                            final dx = t == 0
                                ? 0.0
                                : 9 * (1 - t) *
                                    (t * 22 % 2 < 1 ? 1 : -1);
                            return Transform.translate(
                                offset: Offset(dx, 0), child: child);
                          },
                          child: Column(
                            children: [
                              for (var i = 0; i < q.options.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _OptionTile(
                                    label: String.fromCharCode(65 + i),
                                    text: q.options[i],
                                    state: _stateFor(p, i, showing),
                                    onTap: (showing || p.busy)
                                        ? null
                                        : () => p.answer(i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _FeedbackBar(provider: p),
        ],
      ),
    );
  }

  _OptionState _stateFor(AssessmentProvider p, int i, bool showing) {
    if (!showing) return p.selectedIndex == i ? _OptionState.picked : _OptionState.idle;
    if (p.selectedIndex != i) return _OptionState.dimmed;
    return p.wasCorrect == true ? _OptionState.correct : _OptionState.wrong;
  }
}

enum _OptionState { idle, picked, correct, wrong, dimmed }

class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.label,
    required this.text,
    required this.state,
    this.onTap,
  });

  final String label;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (widget.state) {
      _OptionState.correct => (AppColors.successSoft, AppColors.success, AppColors.ink),
      _OptionState.wrong => (AppColors.dangerSoft, AppColors.danger, AppColors.ink),
      _OptionState.picked => (AppColors.primarySoft, AppColors.primary, AppColors.ink),
      _OptionState.dimmed => (AppColors.surface, AppColors.border, AppColors.textFaint),
      _OptionState.idle => (
          _hovered ? AppColors.primarySoft : AppColors.surface,
          _hovered ? AppColors.primaryLight : AppColors.border,
          AppColors.ink,
        ),
    };

    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1.6),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: border.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13, color: border),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(fontSize: 15, height: 1.4, color: fg),
                ),
              ),
              if (widget.state == _OptionState.correct)
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
              if (widget.state == _OptionState.wrong)
                const Icon(Icons.cancel_rounded, color: AppColors.danger),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.provider, required this.question});

  final AssessmentProvider provider;
  final AssessmentQuestion question;

  @override
  Widget build(BuildContext context) {
    final seconds = (provider.msRemaining / 1000).ceil();
    final urgent = seconds <= 10;

    return Row(
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The ring is the honest part of the countdown: it moves with
              // the number the server sent, so a candidate can always see how
              // long they actually have rather than trusting a digit.
              CircularProgressIndicator(
                value: provider.timeFraction,
                strokeWidth: 4,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                    urgent ? AppColors.danger : AppColors.primaryLight),
              ),
              Text(
                '$seconds',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: urgent ? AppColors.danger : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Question ${question.index + 1} of ${question.total}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  const Spacer(),
                  if (provider.tabSwitches > 0)
                    Tooltip(
                      message: 'Leaving this page is recorded and shown to the '
                          'reviewer. It does not end your test.',
                      child: Row(
                        children: [
                          const Icon(Icons.visibility_off_outlined,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${provider.tabSwitches}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: question.total == 0 ? 0 : question.index / question.total,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  const _FeedbackBar({required this.provider});

  final AssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    final showing = provider.phase == AssessmentPhase.feedback;

    if (!showing) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(
          'Choose an answer. You cannot return to this question.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
      );
    }

    final (color, soft, icon, label) = provider.timedOut
        ? (AppColors.warning, AppColors.warningSoft, Icons.timer_off_rounded,
            'Time up — marked as skipped')
        : provider.wasCorrect == true
            ? (AppColors.success, AppColors.successSoft,
                Icons.check_circle_rounded, 'Correct')
            : (AppColors.danger, AppColors.dangerSoft, Icons.cancel_rounded,
                'Incorrect');

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CLOSING SCREENS
// ═══════════════════════════════════════════════════════════════════════════

class _Finished extends StatelessWidget {
  const _Finished({super.key, required this.provider});

  final AssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    final r = provider.result;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.task_alt_rounded, size: 56, color: AppColors.success),
              const SizedBox(height: 16),
              const Text(
                'Assessment complete',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your answers have been submitted and cannot be changed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              if (r != null) ...[
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 28),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${r.correct} / ${r.total}',
                        style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            height: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'answered correctly',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                if (r.skipped > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${r.skipped} question${r.skipped == 1 ? '' : 's'} ran out of time.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ],

              const SizedBox(height: 24),
              // No verdict here on purpose. Whether this score is enough is the
              // recruiter's call and theirs to communicate; a machine telling
              // someone they failed has rejected them on nobody's authority.
              const Text(
                'The recruitment team will review your result and be in touch '
                'about the next step.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/dashboard'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text('Back to dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Closed extends StatelessWidget {
  const _Closed({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onRetry != null) ...[
                    FilledButton(onPressed: onRetry, child: const Text('Try again')),
                    const SizedBox(width: 12),
                  ],
                  OutlinedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Back to dashboard'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SMALL PARTS
// ═══════════════════════════════════════════════════════════════════════════

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});

  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.tone,
    required this.soft,
    required this.text,
  });

  final IconData icon;
  final Color tone, soft;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.45, color: tone),
            ),
          ),
        ],
      ),
    );
  }
}
