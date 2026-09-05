import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import 'interview.dart';
import 'join_window.dart';
import 'interview_provider.dart';

/// A month of interviews, with the selected day's schedule beside it.
///
/// A recruiter's question about their diary is nearly always "what is coming
/// up" rather than "what happened in March", so the month grid marks the days
/// that have something on it and the panel answers the question in full for
/// one day at a time.
class InterviewCalendar extends StatefulWidget {
  const InterviewCalendar({super.key, this.compact = false});

  /// Narrow layout: month grid above the day panel rather than beside it.
  final bool compact;

  @override
  State<InterviewCalendar> createState() => _InterviewCalendarState();
}

class _InterviewCalendarState extends State<InterviewCalendar> {
  late DateTime _month = _startOfMonth(DateTime.now());
  late DateTime _selected = _today;

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month);

  void _step(int months) {
    setState(() => _month = DateTime(_month.year, _month.month + months));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();
    final byDay = provider.byDay;

    final grid = _MonthGrid(
      month: _month,
      selected: _selected,
      byDay: byDay,
      onPrevious: () => _step(-1),
      onNext: () => _step(1),
      onToday: () => setState(() {
        _month = _startOfMonth(DateTime.now());
        _selected = _today;
      }),
      onSelect: (day) => setState(() => _selected = day),
    );

    final panel = _DayPanel(
      day: _selected,
      interviews: byDay[_selected] ?? const [],
      loading: provider.loading,
      upcoming: provider.upcoming,
    );

    if (widget.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [grid, const SizedBox(height: 16), panel],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 380, child: grid),
        const SizedBox(width: 20),
        Expanded(child: panel),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MONTH GRID
// ═══════════════════════════════════════════════════════════════════════════

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.byDay,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final Map<DateTime, List<Interview>> byDay;
  final VoidCallback onPrevious, onNext, onToday;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstOfMonth = DateTime(month.year, month.month);
    // Monday-first grid: `weekday` is 1 for Monday, so the offset is one less.
    final leading = firstOfMonth.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = ((leading + daysInMonth) / 7).ceil() * 7;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
              ),
              _RoundButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
              const SizedBox(width: 4),
              _RoundButton(icon: Icons.chevron_right_rounded, onTap: onNext),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onToday,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Today', style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textFaint),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: cells,
            itemBuilder: (context, i) {
              final dayNumber = i - leading + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final day = DateTime(month.year, month.month, dayNumber);
              final entries = byDay[day] ?? const <Interview>[];
              return _DayCell(
                day: day,
                count: entries.length,
                needsLink: entries.any((e) => !e.hasLink &&
                    e.status == InterviewStatus.requested),
                isToday: day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day,
                isSelected: day == selected,
                onTap: () => onSelect(day),
              );
            },
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _Legend(color: AppColors.primary, label: 'Scheduled'),
              SizedBox(width: 14),
              _Legend(color: AppColors.warning, label: 'Awaiting link'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.count,
    required this.needsLink,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final int count;
  final bool needsLink, isToday, isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final dot = needsLink ? AppColors.warning : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : isToday
                    ? AppColors.primarySoft
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isToday && !isSelected
                ? Border.all(color: AppColors.primary, width: 1.2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : weekend
                          ? AppColors.textFaint
                          : AppColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              // A fixed-height strip whether or not there are dots, so the
              // numbers stay on one baseline across the whole grid.
              SizedBox(
                height: 5,
                child: count == 0
                    ? null
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < (count > 3 ? 3 : count); i++)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : dot,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  DAY PANEL
// ═══════════════════════════════════════════════════════════════════════════

class _DayPanel extends StatelessWidget {
  const _DayPanel({
    required this.day,
    required this.interviews,
    required this.loading,
    required this.upcoming,
  });

  final DateTime day;
  final List<Interview> interviews;
  final bool loading;
  final List<Interview> upcoming;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, d MMMM').format(day),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
              ),
              if (interviews.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${interviews.length} interview'
                    '${interviews.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (interviews.isEmpty)
            _NothingOn(upcoming: upcoming)
          else
            for (final i in interviews)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InterviewTile(interview: i),
              ),
        ],
      ),
    );
  }
}

/// An empty day is still worth something: it points at the next one that is not.
class _NothingOn extends StatelessWidget {
  const _NothingOn({required this.upcoming});

  final List<Interview> upcoming;

  @override
  Widget build(BuildContext context) {
    final next = upcoming.isEmpty ? null : upcoming.first;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Column(
        children: [
          const Icon(Icons.event_available_outlined,
              size: 32, color: AppColors.textFaint),
          const SizedBox(height: 12),
          const Text('Nothing scheduled',
              style: TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
          if (next != null) ...[
            const SizedBox(height: 6),
            Text(
              'Next: ${next.candidateName} on '
              '${DateFormat('EEE d MMM, HH:mm').format(next.scheduledAt)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textFaint),
            ),
          ],
        ],
      ),
    );
  }
}

/// One interview, as both the calendar and the admin's card show it.
class InterviewTile extends StatelessWidget {
  const InterviewTile({super.key, required this.interview, this.trailing});

  final Interview interview;

  /// Replaces the joining button. Left null, the tile offers its own once the
  /// window opens — the calendar is where a recruiter is sitting when it does.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final (tone, label) = switch (interview.status) {
      InterviewStatus.requested => (AppColors.warning, 'Awaiting link'),
      InterviewStatus.scheduled => (AppColors.primary, 'Scheduled'),
      InterviewStatus.completed => (AppColors.success, 'Completed'),
      InterviewStatus.cancelled => (AppColors.textFaint, 'Cancelled'),
    };

    // Zoom's word beats the clock's: isInProgress only means the start time
    // has passed, while isLive means the meeting was actually opened.
    final live = interview.isLive;
    final running = live || interview.isInProgress;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: running ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: running ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 46,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('HH:mm').format(interview.scheduledAt),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink),
                    ),
                    Text(
                      ' – ${DateFormat('HH:mm').format(interview.endsAt)}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 10),
                    _Tag(text: label, color: tone),
                    if (running) ...[
                      const SizedBox(width: 6),
                      _Tag(
                        text: live ? 'Live' : 'Now',
                        color: AppColors.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  interview.candidateName.isEmpty
                      ? 'Candidate'
                      : interview.candidateName,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    interview.mode.label,
                    '${interview.durationMinutes} min',
                    if (interview.jobTitle.isNotEmpty) interview.jobTitle,
                  ].join('  ·  '),
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
                if (interview.notes.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    interview.notes,
                    style: const TextStyle(
                        fontSize: 12, height: 1.4, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            ...[const SizedBox(width: 10), trailing!]
          else if (interview.hasLink) ...[
            const SizedBox(width: 10),
            _JoinTrailing(interview: interview),
          ],
        ],
      ),
    );
  }
}

/// The joining button on a tile, and what stands there before it is usable.
///
/// A disabled button with no explanation is the thing people email about, so
/// this says when it will work instead of just refusing.
class _JoinTrailing extends StatelessWidget {
  const _JoinTrailing({required this.interview});

  final Interview interview;

  @override
  Widget build(BuildContext context) => JoinWindow(
        interview: interview,
        builder: (context, open) {
          if (!open) {
            return Text(
              'Opens\n${joinOpensIn(interview)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            );
          }
          return FilledButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (!await openMeetingLink(interview.meetingLink)) {
                messenger.showSnackBar(const SnackBar(
                  content: Text('Could not open the joining link.'),
                ));
              }
            },
            icon: const Icon(Icons.videocam_rounded, size: 16),
            label: const Text('Join'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 34),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: color),
        ),
      );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      );
}
