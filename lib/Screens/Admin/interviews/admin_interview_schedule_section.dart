import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/interviews/interview.dart';
import '../../../core/interviews/interview_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Interviews, by job.
///
/// Grouped the same way the Assessments screen is, because a paper belongs to a
/// job and so does an interview panel — and an admin working through a day's
/// interviews is working through one role, not one recruiter. Each job then
/// lists its batches, so the request a candidate arrived on is never lost:
/// seventeen were shortlisted, ten sat the test, six were kept, and all of that
/// stays attached to one request id.
///
/// The recruiter decides who and when. The admin issues the joining link. That
/// split is deliberate — the person arranging the meeting is not the person
/// deciding it should happen.
class AdminInterviewScheduleSection extends StatefulWidget {
  const AdminInterviewScheduleSection({super.key});

  @override
  State<AdminInterviewScheduleSection> createState() =>
      _AdminInterviewScheduleSectionState();
}

/// One job's interview work: its batches, and the totals across them.
class _JobGroup {
  _JobGroup({required this.jobId, required this.title});

  final String jobId;
  String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> batches = [];

  int kept = 0;
  int considered = 0;

  String get subtitle => '$kept of $considered kept  ·  '
      '${batches.length} batch${batches.length == 1 ? '' : 'es'}';
}

class _AdminInterviewScheduleSectionState
    extends State<AdminInterviewScheduleSection> {
  String? _jobId;
  String? _requestId;

  /// Groups the batches by the job their candidates applied to.
  ///
  /// The job id is read off the candidates rather than stored on the request,
  /// so there is one copy of it and nothing to drift.
  List<_JobGroup> _group(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final byJob = <String, _JobGroup>{};
    for (final doc in docs) {
      final data = doc.data();
      final kept = (data['final_selection'] as List? ?? const []).length;
      if (kept == 0) continue;

      final candidates =
          (data['candidates'] as List? ?? const []).whereType<Map>();
      final first = candidates.isEmpty ? const {} : candidates.first;
      final jobId = (first['job_id'] ?? 'unknown').toString();

      final group = byJob.putIfAbsent(
        jobId,
        () => _JobGroup(
          jobId: jobId,
          title: (first['job_title'] ?? '').toString().isEmpty
              ? 'Untitled role'
              : first['job_title'].toString(),
        ),
      );
      group.batches.add(doc);
      group.kept += kept;
      group.considered += (data['candidate_ids'] as List? ?? const []).length;
    }

    final groups = byJob.values.toList()
      ..sort((a, b) => b.kept.compareTo(a.kept));
    for (final g in groups) {
      g.batches.sort((a, b) {
        final at = a.data()['final_selection_at'];
        final bt = b.data()['final_selection_at'];
        if (at is Timestamp && bt is Timestamp) return bt.compareTo(at);
        return 0;
      });
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('recruiter_requests')
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            );
          }

          final groups = _group(snap.data!.docs);
          if (groups.isEmpty) {
            return const _Message(
              icon: Icons.event_available_outlined,
              title: 'Nothing to schedule yet',
              body: 'A job appears here as soon as a recruiter books an '
                  'interview for someone who passed their assessment. Until '
                  'then the choice is theirs to make, not yours to prompt.',
            );
          }

          final job = groups.firstWhere(
            (g) => g.jobId == _jobId,
            orElse: () => groups.first,
          );
          final batch = job.batches.firstWhere(
            (b) => b.id == _requestId,
            orElse: () => job.batches.first,
          );

          return LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 1000;
              final picker = _JobPicker(
                groups: groups,
                selectedJob: job.jobId,
                selectedBatch: batch.id,
                onSelectJob: (id) => setState(() {
                  _jobId = id;
                  _requestId = null;
                }),
                onSelectBatch: (id) => setState(() => _requestId = id),
              );
              final detail = _BatchDetail(
                key: ValueKey(batch.id),
                requestId: batch.id,
                jobTitle: job.title,
                data: batch.data(),
              );

              if (!wide) {
                return Column(
                  children: [
                    SizedBox(height: 216, child: picker),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(child: detail),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 344, child: picker),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(child: detail),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LEFT — jobs, each with its batches
// ═══════════════════════════════════════════════════════════════════════════

class _JobPicker extends StatelessWidget {
  const _JobPicker({
    required this.groups,
    required this.selectedJob,
    required this.selectedBatch,
    required this.onSelectJob,
    required this.onSelectBatch,
  });

  final List<_JobGroup> groups;
  final String selectedJob, selectedBatch;
  final ValueChanged<String> onSelectJob;
  final ValueChanged<String> onSelectBatch;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PanelHeading(
              icon: Icons.event_note_rounded,
              title: 'Interviews by job',
              subtitle: 'Only candidates a recruiter kept after the assessment.',
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final g = groups[i];
                  final open = g.jobId == selectedJob;
                  return _JobCard(
                    group: g,
                    open: open,
                    selectedBatch: selectedBatch,
                    onTap: () => onSelectJob(g.jobId),
                    onSelectBatch: onSelectBatch,
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.group,
    required this.open,
    required this.selectedBatch,
    required this.onTap,
    required this.onSelectBatch,
  });

  final _JobGroup group;
  final bool open;
  final String selectedBatch;
  final VoidCallback onTap;
  final ValueChanged<String> onSelectBatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: open ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: open ? AppColors.primary : AppColors.border,
          width: open ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: open
                            ? AppColors.primary
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.work_outline_rounded,
                        size: 17,
                        color: open ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            group.subtitle,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: open ? AppColors.primary : AppColors.textFaint,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Batches only when the job is open. Every request stays addressable
          // by its own id — that id is the thread the whole hire hangs on.
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
              child: Column(
                children: [
                  for (final b in group.batches)
                    _BatchRow(
                      doc: b,
                      selected: b.id == selectedBatch,
                      onTap: () => onSelectBatch(b.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({
    required this.doc,
    required this.selected,
    required this.onTap,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final kept = (d['final_selection'] as List? ?? const []).length;
    final total = (d['candidate_ids'] as List? ?? const []).length;
    final when = d['final_selection_at'];

    return Padding
      (padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : AppColors.textFaint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$kept for interview  ·  from $total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.ink
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'REQ ${doc.id.length > 12 ? doc.id.substring(0, 12) : doc.id}'
                        '${when is Timestamp ? '  ·  ${DateFormat('d MMM').format(when.toDate())}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.2,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
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

// ═══════════════════════════════════════════════════════════════════════════
//  RIGHT — the kept candidates and their slots
// ═══════════════════════════════════════════════════════════════════════════

class _BatchDetail extends StatelessWidget {
  const _BatchDetail({
    super.key,
    required this.requestId,
    required this.jobTitle,
    required this.data,
  });

  final String requestId, jobTitle;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final keptIds = {
      for (final id in (data['final_selection'] as List? ?? const []))
        id.toString(),
    };
    final candidates = [
      for (final raw in (data['candidates'] as List? ?? const []))
        if (raw is Map) Map<String, dynamic>.from(raw),
    ].where((c) => keptIds.contains((c['uid'] ?? '').toString())).toList();

    final summary = data['assessment_summary'] is Map
        ? Map<String, dynamic>.from(data['assessment_summary'] as Map)
        : const <String, dynamic>{};
    final note = (data['final_selection_note'] ?? '').toString().trim();

    // Highest scorer first. An interview list is worked top down, and the order
    // the recruiter happened to tick people in carries no information.
    candidates.sort((a, b) {
      int pct(Map<String, dynamic> c) {
        final e = summary[(c['uid'] ?? '').toString()];
        return e is Map ? ((e['percentage'] as num?)?.toInt() ?? -1) : -1;
      }

      return pct(b).compareTo(pct(a));
    });

    return ChangeNotifierProvider(
      create: (_) => InterviewProvider()..watchForRequest(requestId),
      child: Consumer<InterviewProvider>(
        builder: (context, interviews, _) {
          final booked = {
            for (final i in interviews.interviews)
              if (i.status != InterviewStatus.cancelled) i.candidateUid: i,
          };
          final awaitingLink = booked.values.where((i) => !i.hasLink).length;
          final unbooked =
              candidates.where((c) => !booked.containsKey(c['uid'])).length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _DetailHeader(
                jobTitle: jobTitle,
                requestId: requestId,
                recruiter: (data['recruiter_email'] ?? '').toString(),
                kept: candidates.length,
                considered:
                    (data['candidate_ids'] as List? ?? const []).length,
                booked: booked.length,
                awaitingLink: awaitingLink,
              ),
              const SizedBox(height: 16),
              if (note.isNotEmpty) _RecruiterNote(text: note),
              if (unbooked > 0)
                _Callout(
                  icon: Icons.hourglass_empty_rounded,
                  tone: AppColors.warning,
                  text: '$unbooked of these ${candidates.length} have no slot '
                      'yet. The recruiter books the date and time; it appears '
                      'here the moment they do.',
                ),
              const SizedBox(height: 4),
              for (final c in candidates)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InterviewRow(
                    name: (c['name'] ?? c['uid'] ?? '—').toString(),
                    role: (c['job_title'] ?? c['target_role'] ?? '').toString(),
                    score: summary[(c['uid'] ?? '').toString()] is Map
                        ? Map<String, dynamic>.from(
                            summary[(c['uid'] ?? '').toString()] as Map)
                        : const {},
                    interview: booked[(c['uid'] ?? '').toString()],
                  ),
                ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.jobTitle,
    required this.requestId,
    required this.recruiter,
    required this.kept,
    required this.considered,
    required this.booked,
    required this.awaitingLink,
  });

  final String jobTitle, requestId, recruiter;
  final int kept, considered, booked, awaitingLink;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jobTitle,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _Meta(icon: Icons.tag_rounded, text: 'REQ $requestId'),
                if (recruiter.isNotEmpty)
                  _Meta(
                    icon: Icons.person_outline_rounded,
                    text: recruiter,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Stat(
                  label: '$kept kept',
                  sub: 'of $considered considered',
                  color: AppColors.primary,
                ),
                _Stat(
                  label: '$booked booked',
                  sub: 'slot confirmed',
                  color: AppColors.accent,
                ),
                _Stat(
                  label: '$awaitingLink awaiting link',
                  sub: 'yours to issue',
                  color: awaitingLink > 0
                      ? AppColors.warning
                      : AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.sub, required this.color});

  final String label, sub;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
}

class _RecruiterNote extends StatelessWidget {
  const _RecruiterNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notes_rounded, size: 17, color: AppColors.primary),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECRUITER\'S NOTE WITH THIS SELECTION',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// One kept candidate: what they scored, when they are being seen, and the link.
class _InterviewRow extends StatelessWidget {
  const _InterviewRow({
    required this.name,
    required this.role,
    required this.score,
    required this.interview,
  });

  final String name, role;
  final Map<String, dynamic> score;
  final Interview? interview;

  Future<void> _generate(BuildContext context) async {
    final provider = context.read<InterviewProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final id = interview!.id;

    // Placeholder until the Zoom integration lands. Deliberately obvious: a
    // link that looked real but was not would be handed to a candidate.
    final ok = await provider.attachLink(
      interviewId: id,
      link: 'https://zoom.us/j/PENDING-${id.substring(0, 8)}',
      provider: 'zoom_placeholder',
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Placeholder link attached. Zoom is not connected yet — replace '
                'it before sending anything to the candidate.'
            : 'Could not attach the link.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iv = interview;
    final pct = (score['percentage'] as num?)?.toInt();
    final rank = (score['rank'] as num?)?.toInt();
    final rankOf = (score['rankOf'] as num?)?.toInt();
    final verdict = (score['verdict'] ?? '').toString();
    final pass = verdict == 'pass';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    name.trim().isEmpty
                        ? '?'
                        : name
                            .trim()
                            .split(' ')
                            .map((w) => w.isEmpty ? '' : w[0])
                            .take(2)
                            .join()
                            .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      if (role.isNotEmpty)
                        Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (pct != null)
                  _Tag(
                    text: rank == null || rankOf == null
                        ? 'TEST $pct%'
                        : 'TEST $pct%  ·  $rank/$rankOf',
                    color: pass ? AppColors.success : AppColors.warning,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(13),
            child: iv == null
                ? const _Callout(
                    icon: Icons.event_busy_outlined,
                    tone: AppColors.textMuted,
                    text: 'No slot booked yet — the recruiter arranges the time.',
                    flat: true,
                  )
                : _Slot(interview: iv, onGenerate: () => _generate(context)),
          ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.interview, required this.onGenerate});

  final Interview interview;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final waiting = !interview.hasLink;
    final tone = waiting ? AppColors.warning : AppColors.accent;

    return LayoutBuilder(
      builder: (context, c) {
        final tight = c.maxWidth < 420;
        final info = Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                waiting ? Icons.event_rounded : Icons.videocam_rounded,
                size: 16,
                color: tone,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE d MMM y, HH:mm')
                        .format(interview.scheduledAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${interview.mode.label} · ${interview.durationMinutes} min'
                    '${waiting ? '' : ' · link issued'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final action = waiting
            ? FilledButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.add_link_rounded, size: 15),
                label: const Text('Generate link'),
                style: FilledButton.styleFrom(
                  backgroundColor: tone,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: interview.meetingLink),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joining link copied')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: const Text('Copy link'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tone,
                  side: BorderSide(color: tone.withValues(alpha: 0.5)),
                  minimumSize: const Size(0, 36),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );

        return Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: tone.withValues(alpha: 0.22)),
          ),
          // The button drops below the time on a narrow card rather than
          // squeezing the date into an ellipsis.
          child: tight
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [info, const SizedBox(height: 10), action],
                )
              : Row(children: [Expanded(child: info), action]),
        );
      },
    );
  }
}

// ── small pieces ───────────────────────────────────────────────────────────

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: color,
          ),
        ),
      );
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.icon,
    required this.tone,
    required this.text,
    this.flat = false,
  });

  final IconData icon;
  final Color tone;
  final String text;

  /// Flat drops the fill and border, for a callout already inside a panel.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: tone),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: flat ? AppColors.textMuted : tone,
            ),
          ),
        ),
      ],
    );
    if (flat) return row;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: row,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 27, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
