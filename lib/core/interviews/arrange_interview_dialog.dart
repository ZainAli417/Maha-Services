import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import 'interview.dart';
import 'interview_provider.dart';

/// Books interviews for one or more candidates.
///
/// The recruiter picks a single starting slot and everyone selected is booked
/// from it in turn. Booking several people at the same minute would be a diary
/// clash by construction, so the dialog shows the resulting run of times
/// rather than leaving the recruiter to discover the overlap later.
class ArrangeInterviewDialog extends StatefulWidget {
  const ArrangeInterviewDialog({
    super.key,
    required this.candidates,
    required this.jobId,
    required this.jobTitle,
    required this.requestId,
    required this.round,
  });

  final List<({String uid, String name})> candidates;
  final String jobId;
  final String jobTitle;
  final String requestId;
  final int round;

  @override
  State<ArrangeInterviewDialog> createState() => _ArrangeInterviewDialogState();
}

class _ArrangeInterviewDialogState extends State<ArrangeInterviewDialog> {
  late DateTime _date = _nextWorkingDay();
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  int _duration = 45;
  int _gap = 15;
  InterviewMode _mode = InterviewMode.video;
  final _notes = TextEditingController();

  static DateTime _nextWorkingDay() {
    var d = DateTime.now().add(const Duration(days: 1));
    while (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    return DateTime(d.year, d.month, d.day);
  }

  DateTime get _start =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  List<({String name, DateTime at})> get _slots {
    var at = _start;
    final out = <({String name, DateTime at})>[];
    for (final c in widget.candidates) {
      out.add((name: c.name, at: at));
      at = at.add(Duration(minutes: _duration + _gap));
    }
    return out;
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final provider = context.read<InterviewProvider>();
    final navigator = Navigator.of(context);
    final saved = await provider.schedule(
      candidates: widget.candidates,
      jobId: widget.jobId,
      jobTitle: widget.jobTitle,
      requestId: widget.requestId,
      start: _start,
      durationMinutes: _duration,
      mode: _mode,
      round: widget.round,
      notes: _notes.text.trim(),
      gapMinutes: _gap,
    );
    if (saved > 0) navigator.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();
    final ownIds = widget.candidates.map((c) => c.uid).toSet();

    // Clashes with anything already in the diary, excluding the bookings this
    // dialog is about to replace.
    final existing = provider.interviews
        .where((i) => !ownIds.contains(i.candidateUid))
        .toList();
    final span = _duration * widget.candidates.length +
        _gap * (widget.candidates.length - 1);
    final clashes = InterviewSchedule.clashes(existing, _start, span);

    final rebooking = widget.candidates
        .where((c) => provider.forCandidate(c.uid) != null)
        .length;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            label: 'Date',
                            icon: Icons.event_rounded,
                            value: DateFormat('EEE, d MMM yyyy').format(_date),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            label: 'Start time',
                            icon: Icons.schedule_rounded,
                            value: _time.format(context),
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    _Label('Length of each interview'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final m in [30, 45, 60, 90])
                          _Choice(
                            label: '$m min',
                            selected: _duration == m,
                            onTap: () => setState(() => _duration = m),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    _Label('Format'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final m in InterviewMode.values)
                          _Choice(
                            label: m.label,
                            selected: _mode == m,
                            onTap: () => setState(() => _mode = m),
                          ),
                      ],
                    ),

                    if (widget.candidates.length > 1) ...[
                      const SizedBox(height: 18),
                      _Label('Gap between interviews'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final g in [0, 10, 15, 30])
                            _Choice(
                              label: g == 0 ? 'Back to back' : '$g min',
                              selected: _gap == g,
                              onTap: () => setState(() => _gap = g),
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 18),
                    TextField(
                      controller: _notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Note for the admin — panel, focus areas, anything else',
                      ),
                    ),

                    const SizedBox(height: 20),
                    _slotList(),

                    if (clashes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _Warning(
                        blocking: true,
                        icon: Icons.event_busy_rounded,
                        text: 'This run overlaps ${clashes.length} interview'
                            '${clashes.length == 1 ? '' : 's'} already booked: '
                            '${clashes.map((c) => '${c.candidateName} at '
                                '${DateFormat('HH:mm').format(c.scheduledAt)}').take(3).join(', ')}'
                            '${clashes.length > 3 ? '…' : ''}. '
                            'Pick another time, or shorten the interviews.',
                      ),
                    ],
                    if (rebooking > 0) ...[
                      const SizedBox(height: 14),
                      _Warning(
                        icon: Icons.link_off_rounded,
                        text: '$rebooking of these already had a slot. '
                            'Rebooking clears the joining link — it was issued '
                            'for the old time — and the admin generates a new one.',
                      ),
                    ],
                    if (provider.error.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(provider.error,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _start.isBefore(DateTime.now())
                          ? 'That time has already passed.'
                          : clashes.isNotEmpty
                              ? 'Clashes with an interview already booked.'
                              : DateFormat('EEE d MMM, HH:mm').format(_start),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _start.isBefore(DateTime.now()) ||
                                clashes.isNotEmpty
                            ? AppColors.danger
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    // A clash is refused, not warned about. Two candidates
                    // sitting in the same slot is discovered by the second one
                    // waiting outside, which is not where it should be found.
                    onPressed: provider.busy ||
                            clashes.isNotEmpty ||
                            _start.isBefore(DateTime.now())
                        ? null
                        : _submit,
                    icon: const Icon(Icons.event_available_rounded, size: 17),
                    label: Text(widget.candidates.length == 1
                        ? 'Send to admin'
                        : 'Book ${widget.candidates.length} interviews'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 12, 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.videocam_rounded,
                  color: AppColors.primary, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Arrange interview',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  Text(
                    widget.candidates.length == 1
                        ? widget.candidates.first.name
                        : '${widget.candidates.length} candidates · ${widget.jobTitle}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Widget _slotList() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.candidates.length == 1 ? 'Slot' : 'Running order',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            for (final slot in _slots)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 108,
                      child: Text(
                        '${DateFormat('HH:mm').format(slot.at)}'
                        ' – ${DateFormat('HH:mm').format(slot.at.add(Duration(minutes: _duration)))}',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ),
                    Expanded(
                      child: Text(slot.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.ink)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

// ── small parts ─────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary),
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label, value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(label),
          const SizedBox(height: 7),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 17, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

class _Warning extends StatelessWidget {
  const _Warning({
    required this.icon,
    required this.text,
    this.blocking = false,
  });

  final IconData icon;
  final String text;

  /// Red rather than amber: this one stops the booking, and a note that reads
  /// like advice next to a disabled button is just confusing.
  final bool blocking;

  @override
  Widget build(BuildContext context) {
    final tone = blocking ? AppColors.danger : AppColors.warning;
    final soft = blocking ? AppColors.dangerSoft : AppColors.warningSoft;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12.5, height: 1.45, color: tone)),
          ),
        ],
      ),
    );
  }
}
