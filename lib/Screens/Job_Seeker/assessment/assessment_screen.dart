import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import 'assessment_platform.dart';
import 'assessment_provider.dart';
import 'my_sittings_provider.dart';

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
  bool _recordRefreshed = false;

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

  /// Once a sitting is done it is no longer something to do, and the sidebar
  /// badge is counting exactly that. Refreshed after the frame, because this
  /// runs during build and a notify from inside build is an error.
  void _clearBadge(AssessmentProvider p) {
    if (p.phase != AssessmentPhase.finished || _recordRefreshed) return;
    _recordRefreshed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MySittingsProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    _syncExitGuard(provider.isRunning);
    _clearBadge(provider);

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
    final narrow = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(narrow ? 14 : 24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(narrow ? 20 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Badge(text: 'Online assessment'),
              const SizedBox(height: 16),
              Text(
                provider.jobTitle.isEmpty ? 'Your application' : provider.jobTitle,
                style: TextStyle(
                  fontSize: narrow ? 21 : 26,
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

              // Three tiles across where they fit, two-up on a phone, rather
              // than a Row that squeezes the last one off the screen.
              LayoutBuilder(
                builder: (context, c) {
                  const gap = 10.0;
                  final columns = c.maxWidth < 340 ? 2 : 3;
                  final width = (c.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final (label, value, icon) in [
                        ('Questions', '${provider.questionCount}',
                            Icons.list_alt_rounded),
                        ('Per question', '${provider.questionSeconds}s',
                            Icons.timer_outlined),
                        ('One sitting', '${provider.sittingMinutes} min',
                            Icons.event_available_rounded),
                      ])
                        SizedBox(
                          width: width,
                          child: _Stat(label: label, value: value, icon: icon),
                        ),
                    ],
                  );
                },
              ),
              SizedBox(height: narrow ? 20 : 24),

              const Text('Before you begin',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 10),
              ...[
                ...provider.rules,
                // The server's rule list predates the skip control, so this one
                // is added here rather than left for the candidate to find out
                // by pressing it.
                'You may skip a question, but it counts as unanswered and you '
                    'cannot return to it.',
              ].map((r) => Padding(
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
    } else if (p.skipped || p.timedOut) {
      // A skip is a decision, not a mistake. One short tick, no shake.
      vibrate(25);
    } else {
      vibrate(180);
      _shake.forward(from: 0);
    }
  }

  /// Confirms a skip before spending the question.
  ///
  /// Skipping is irreversible and costs a mark, so it asks once — but plainly,
  /// and without trying to talk the candidate out of it.
  Future<void> _confirmSkip(AssessmentProvider p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.redo_rounded,
                  size: 18, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            const Text(
              'Skip this question?',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        content: const Text(
          'You cannot come back to it. It will be marked as skipped and '
          'scored as a wrong answer.',
          style: TextStyle(
              fontSize: 13.5, height: 1.5, color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: const Text('Keep trying'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            child: const Text('Skip and move on'),
          ),
        ],
      ),
    );
    if (ok == true) p.skipQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final q = p.question;
    if (q == null) return const Center(child: CircularProgressIndicator());

    _feedbackEffects(p);
    final showing = p.phase == AssessmentPhase.feedback;
    final locked = p.selectedIndex != -1 || p.busy || showing;
    final narrow = MediaQuery.of(context).size.width < 600;

    return Center(
      // A question is a column of text. Letting it run the width of a desktop
      // monitor makes it harder to read, not easier.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: narrow ? 14 : 24, vertical: narrow ? 12 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProgressHeader(provider: p, question: q, narrow: narrow),
              SizedBox(height: narrow ? 14 : 18),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selection is off across the question and the options:
                      // it is the first step of copying a question out to look
                      // something up.
                      SelectionContainer.disabled(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(narrow ? 16 : 20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (q.topic.isNotEmpty) ...[
                                    _Badge(text: q.topic),
                                    const SizedBox(height: 12),
                                  ],
                                  Text(
                                    q.text,
                                    style: TextStyle(
                                      fontSize: narrow ? 17 : 19,
                                      height: 1.45,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: narrow ? 14 : 18),
                            AnimatedBuilder(
                              animation: _shake,
                              builder: (context, child) {
                                // A short damped wobble, only on a wrong answer.
                                final t = _shake.value;
                                final dx = t == 0
                                    ? 0.0
                                    : 9 * (1 - t) * (t * 22 % 2 < 1 ? 1 : -1);
                                return Transform.translate(
                                    offset: Offset(dx, 0), child: child);
                              },
                              child: Column(
                                children: [
                                  for (var i = 0; i < q.options.length; i++)
                                    Padding(
                                      padding: EdgeInsets.only(
                                          bottom: narrow ? 9 : 11),
                                      child: _OptionTile(
                                        label: String.fromCharCode(65 + i),
                                        text: q.options[i],
                                        state: _stateFor(p, i, showing, locked),
                                        narrow: narrow,
                                        onTap: locked ? null : () => p.answer(i),
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

              _BottomBar(
                provider: p,
                narrow: narrow,
                onSkip: locked ? null : () => _confirmSkip(p),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// What each option looks like right now.
  ///
  /// The moment one is chosen the rest go dead — greyed, unbordered and
  /// untappable — and the chosen one shows a padlock. The answer has gone to
  /// the server by then and cannot be changed, so leaving the others looking
  /// live would be a lie the candidate discovers by tapping one.
  _OptionState _stateFor(
      AssessmentProvider p, int i, bool showing, bool locked) {
    if (showing) {
      if (p.selectedIndex != i) return _OptionState.dead;
      if (p.skipped || p.timedOut) return _OptionState.dead;
      return p.wasCorrect == true ? _OptionState.correct : _OptionState.wrong;
    }
    if (p.selectedIndex == i) return _OptionState.locked;
    return locked ? _OptionState.dead : _OptionState.idle;
  }
}

enum _OptionState { idle, locked, correct, wrong, dead }

class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.label,
    required this.text,
    required this.state,
    required this.narrow,
    this.onTap,
  });

  final String label;
  final String text;
  final _OptionState state;
  final bool narrow;
  final VoidCallback? onTap;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dead = widget.state == _OptionState.dead;

    final (bg, border, fg, width) = switch (widget.state) {
      _OptionState.correct => (
          AppColors.successSoft, AppColors.success, AppColors.ink, 1.8),
      _OptionState.wrong => (
          AppColors.dangerSoft, AppColors.danger, AppColors.ink, 1.8),
      _OptionState.locked => (
          AppColors.primarySoft, AppColors.primary, AppColors.ink, 1.8),
      _OptionState.dead => (
          AppColors.surfaceAlt, AppColors.border, AppColors.textFaint, 1.0),
      _OptionState.idle => (
          _hovered ? AppColors.primarySoft : AppColors.surface,
          _hovered ? AppColors.primaryLight : AppColors.border,
          AppColors.ink,
          _hovered ? 1.6 : 1.2,
        ),
    };

    final badge = switch (widget.state) {
      _OptionState.correct => AppColors.success,
      _OptionState.wrong => AppColors.danger,
      _OptionState.locked => AppColors.primary,
      _OptionState.dead => AppColors.textFaint,
      _OptionState.idle => _hovered ? AppColors.primary : AppColors.textMuted,
    };

    final trailing = switch (widget.state) {
      _OptionState.correct =>
        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 21),
      _OptionState.wrong =>
        const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 21),
      // The padlock is the whole point: the choice is in, and it is closed.
      _OptionState.locked =>
        const Icon(Icons.lock_rounded, color: AppColors.primary, size: 19),
      _ => null,
    };

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(
          horizontal: widget.narrow ? 13 : 16, vertical: widget.narrow ? 13 : 15),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border, width: width),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badge.withValues(alpha: dead ? 0.09 : 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 12.5, color: badge),
            ),
          ),
          SizedBox(width: widget.narrow ? 11 : 13),
          Expanded(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.narrow ? 14 : 14.8,
                height: 1.4,
                fontWeight: dead ? FontWeight.w400 : FontWeight.w500,
                color: fg,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );

    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        // Dead options fade rather than vanish, so the candidate can still
        // read what they did not pick while the answer is being graded.
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: dead ? 0.55 : 1,
          child: tile,
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.provider,
    required this.question,
    required this.narrow,
  });

  final AssessmentProvider provider;
  final AssessmentQuestion question;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final seconds = (provider.msRemaining / 1000).ceil();
    final urgent = seconds <= 10;
    final tone = urgent ? AppColors.danger : AppColors.primary;
    final size = narrow ? 46.0 : 54.0;

    return Container(
      padding: EdgeInsets.all(narrow ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent ? AppColors.danger.withValues(alpha: 0.45) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The ring is the honest part of the countdown: it moves with
                // the number the server sent, so a candidate can always see
                // how long they actually have rather than trusting a digit.
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: provider.timeFraction,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation(tone),
                  ),
                ),
                Text(
                  '$seconds',
                  style: TextStyle(
                    fontSize: narrow ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    color: urgent ? AppColors.danger : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: narrow ? 12 : 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Question ${question.index + 1}',
                      style: TextStyle(
                        fontSize: narrow ? 14 : 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      ' of ${question.total}',
                      style: TextStyle(
                        fontSize: narrow ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    if (provider.tabSwitches > 0)
                      Tooltip(
                        message: 'Leaving this page is recorded and shown to '
                            'the reviewer. It does not end your test.',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_off_outlined,
                                  size: 12, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                '${provider.tabSwitches}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.warning),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:
                        question.total == 0 ? 0 : question.index / question.total,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceAlt,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The strip under the options: the skip control, or the verdict once graded.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.provider,
    required this.narrow,
    required this.onSkip,
  });

  final AssessmentProvider provider;
  final bool narrow;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    if (provider.phase == AssessmentPhase.feedback) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _Verdict(provider: provider),
      );
    }

    final waiting = onSkip == null;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              waiting
                  ? 'Answer recorded…'
                  : 'Pick an answer, or skip. Either way this question does '
                      'not come back.',
              style: const TextStyle(
                  fontSize: 12, height: 1.4, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onSkip,
            icon: const Icon(Icons.redo_rounded, size: 16),
            label: Text(narrow ? 'Skip' : 'Skip question'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(0, 40),
              visualDensity: VisualDensity.compact,
              textStyle:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Right, wrong, skipped or out of time — said once, in one place.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.provider});

  final AssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    final (color, soft, icon, label) = switch ((
      provider.timedOut,
      provider.skipped,
      provider.wasCorrect == true
    )) {
      (true, _, _) => (AppColors.warning, AppColors.warningSoft,
          Icons.timer_off_rounded, 'Time up — marked as skipped'),
      (_, true, _) => (AppColors.textMuted, AppColors.surfaceAlt,
          Icons.redo_rounded, 'Skipped'),
      (_, _, true) => (AppColors.success, AppColors.successSoft,
          Icons.check_circle_rounded, 'Correct'),
      _ => (AppColors.danger, AppColors.dangerSoft, Icons.cancel_rounded,
          'Incorrect'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Text(
            label,
            style: TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w800, color: color),
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
    final narrow = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(narrow ? 14 : 24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(narrow ? 22 : 32),
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
                        'answered correctly  ·  ${r.percentage}%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                if (r.skipped > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    // "Ran out of time" was true when that was the only way to
                    // leave one blank. Skipping is a choice now, and the count
                    // covers both.
                    '${r.skipped} question${r.skipped == 1 ? '' : 's'} left '
                    'unanswered — skipped or out of time.',
                    textAlign: TextAlign.center,
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
