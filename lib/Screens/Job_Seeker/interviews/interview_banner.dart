import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/interviews/candidate_interview.dart';
import '../../../core/interviews/join_window.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/backend_api.dart';

/// The candidate's next interview, with the joining link when it is usable.
///
/// The link also goes out by email, but an email is easy to lose and a
/// candidate who opens the app on the morning of their interview should not
/// have to go looking for it. Renders nothing when there is no interview
/// booked, so it costs no space until it has something to say.
///
/// Polls rather than streams: the joining link is served by the backend only
/// inside the joining window, so there is nothing in Firestore for this to
/// listen to. [CandidateInterviews.refreshEvery] keeps the polling slow until
/// the window is close.
class InterviewBanner extends StatefulWidget {
  const InterviewBanner({super.key});

  @override
  State<InterviewBanner> createState() => _InterviewBannerState();
}

class _InterviewBannerState extends State<InterviewBanner> {
  CandidateInterview? _next;
  Timer? _poll;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await BackendApi.get('/interviews/mine');
      final list = (res['interviews'] as List? ?? const [])
          .map((e) => CandidateInterview.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _next = CandidateInterviews.next(list, DateTime.now());
        _loaded = true;
      });
    } catch (_) {
      // A dashboard is not the place to report that a background fetch failed;
      // the next poll will try again and the card simply stays absent.
      if (mounted) setState(() => _loaded = true);
    }
    _schedule();
  }

  void _schedule() {
    _poll?.cancel();
    final every = CandidateInterviews.refreshEvery(_next, DateTime.now());
    if (every == null) return;
    _poll = Timer(every, _load);
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _join(String link) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await openMeetingLink(link)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the joining link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iv = _next;
    if (!_loaded || iv == null) return const SizedBox.shrink();

    // The zone is spelled out because these candidates are not all in one
    // country — a time with no zone beside it is how someone joins at the
    // right hour in the wrong place.
    final when = '${DateFormat('EEEE d MMMM, HH:mm').format(iv.scheduledAt)} '
        '${iv.scheduledAt.timeZoneName}';
    final role = [
      if (iv.jobTitle.isNotEmpty) iv.jobTitle,
      if (iv.company.isNotEmpty) iv.company,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: iv.live ? AppColors.success : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final tight = c.maxWidth < 420;

            final text = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  iv.live
                      ? 'Your interview is running now'
                      : 'You have an interview booked',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  role.isEmpty ? when : '$role\n$when',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            );

            final action = _Action(
              interview: iv,
              onJoin: () => _join(iv.meetingLink),
            );

            return tight
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _Badge(live: iv.live),
                          const SizedBox(width: 14),
                          Expanded(child: text),
                        ],
                      ),
                      const SizedBox(height: 14),
                      action,
                    ],
                  )
                : Row(
                    children: [
                      _Badge(live: iv.live),
                      const SizedBox(width: 14),
                      Expanded(child: text),
                      const SizedBox(width: 12),
                      action,
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.live});
  final bool live;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          live ? Icons.sensors_rounded : Icons.videocam_rounded,
          color: Colors.white,
          size: 21,
        ),
      );
}

/// Join, or a plain sentence about why not yet.
///
/// A greyed-out button with no reason beside it is what makes people email to
/// ask whether their interview is still happening.
class _Action extends StatelessWidget {
  const _Action({required this.interview, required this.onJoin});

  final CandidateInterview interview;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    if (interview.canJoin) {
      return FilledButton.icon(
        onPressed: onJoin,
        icon: const Icon(Icons.videocam_rounded, size: 17),
        label: const Text('Join now'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor:
              interview.live ? AppColors.success : AppColors.primary,
          minimumSize: const Size(0, 40),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      );
    }

    final message = interview.hasLink
        ? 'Joining opens\n${opensInLabel(interview.joinOpensAt)}'
        : 'The joining link\nwill appear here';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
