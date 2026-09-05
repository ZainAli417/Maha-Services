import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'interview.dart';

/// Rebuilds its child when an interview's joining window opens or closes.
///
/// Without this the button is only ever right at the moment the page was
/// built: someone who opens the app twenty minutes early would sit looking at
/// a dead button through the whole window, and someone who left the tab open
/// would keep a live one long after the interview ended.
///
/// The timer is cheap and only runs while a window is actually approaching, so
/// a page full of past interviews ticks nothing.
class JoinWindow extends StatefulWidget {
  const JoinWindow({
    super.key,
    required this.interview,
    required this.builder,
  });

  final Interview interview;

  /// Called with whether the link may be used right now.
  final Widget Function(BuildContext context, bool open) builder;

  @override
  State<JoinWindow> createState() => _JoinWindowState();
}

class _JoinWindowState extends State<JoinWindow> {
  Timer? _tick;
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.interview.canJoinAt(DateTime.now());
    _schedule();
  }

  @override
  void didUpdateWidget(JoinWindow old) {
    super.didUpdateWidget(old);
    if (old.interview.scheduledAt != widget.interview.scheduledAt ||
        old.interview.meetingLink != widget.interview.meetingLink) {
      _open = widget.interview.canJoinAt(DateTime.now());
      _schedule();
    }
  }

  /// Ticks only while the window is open or still to come. Half a minute is
  /// fine granularity for a thing measured in fifteen-minute steps.
  void _schedule() {
    _tick?.cancel();
    final closed = InterviewJoin.closesAt(
      widget.interview.scheduledAt,
      widget.interview.durationMinutes,
    );
    if (DateTime.now().isAfter(closed)) return;

    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      final open = widget.interview.canJoinAt(DateTime.now());
      if (open != _open && mounted) setState(() => _open = open);
      if (DateTime.now().isAfter(closed)) _tick?.cancel();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _open);
}

/// Opens a joining link in a new tab or the Zoom app.
///
/// Returns false when the platform refused it, so a caller can say something
/// rather than leaving a button that appears to do nothing.
Future<bool> openMeetingLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || url.trim().isEmpty) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// "in 3 days", "in 2 hours", "in 12 minutes", "now".
///
/// Counts down to when the *link opens*, not to the interview itself: that is
/// the moment the button starts working, and it is the only question someone
/// looking at a disabled button is asking.
///
/// Coarse on purpose. A second-by-second countdown on a thing that is hours
/// away invites watching, and the exact minute is on the card already.
String opensInLabel(DateTime opensAt, [DateTime? now]) {
  final left = opensAt.difference(now ?? DateTime.now());
  if (left.isNegative) return 'now';
  if (left.inDays >= 1) {
    return 'in ${left.inDays} day${left.inDays == 1 ? '' : 's'}';
  }
  if (left.inHours >= 1) {
    return 'in ${left.inHours} hour${left.inHours == 1 ? '' : 's'}';
  }
  // Part-minutes round up, so the last stretch reads "in 1 minute" rather
  // than "in 0 minutes" — but a whole twelve minutes still says twelve.
  final mins = (left.inSeconds / 60).ceil();
  return 'in $mins minute${mins == 1 ? '' : 's'}';
}

/// [opensInLabel] for a booked interview.
String joinOpensIn(Interview interview, [DateTime? now]) =>
    opensInLabel(interview.joinOpensAt, now);

/// The invitation text an admin pastes into a message.
///
/// A bare URL leaves the recipient to work out when it is for, which is how
/// people end up joining an hour early or a day late. This is the same
/// information the email carries, in one block that survives being pasted into
/// WhatsApp.
String interviewInviteText(Interview interview) {
  final start = interview.scheduledAt;
  final tz = start.timeZoneName;
  final date = '${_weekday(start)} ${start.day} ${_month(start)} ${start.year}';
  final time = '${_two(start.hour)}:${_two(start.minute)}';

  return [
    'Interview — ${interview.jobTitle.isEmpty ? 'Maha Services' : interview.jobTitle}',
    '$date at $time $tz (${interview.durationMinutes} minutes)',
    '',
    'Join: ${interview.meetingLink}',
    if (interview.zoomPasscode.trim().isNotEmpty)
      'Passcode: ${interview.zoomPasscode}',
    '',
    'The link opens ${InterviewJoin.lead.inMinutes} minutes before the start '
        'time. You will wait in the waiting room until you are admitted.',
  ].join('\n');
}

String _two(int n) => n.toString().padLeft(2, '0');

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _weekday(DateTime d) => _weekdays[d.weekday - 1];
String _month(DateTime d) => _months[d.month - 1];
