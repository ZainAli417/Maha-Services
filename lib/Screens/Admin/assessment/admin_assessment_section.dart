import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import 'admin_assessment_provider.dart';

/// The admin's assessment console.
///
/// One screen for the whole loop: pick the recruiter's batch, build the paper,
/// read it before anyone else does, invite, watch it happen, send the scores
/// back. Split across screens it would be four places to look for one answer.
class AdminAssessmentSection extends StatelessWidget {
  const AdminAssessmentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminAssessmentProvider(),
      child: const _Console(),
    );
  }
}

class _Console extends StatelessWidget {
  const _Console();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminAssessmentProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final picker = _RequestPicker(selected: p.requestId);
        final detail = p.requestId == null
            ? const _Placeholder()
            : _RequestDetail(provider: p);

        if (!wide) {
          return Column(
            children: [
              SizedBox(height: 190, child: picker),
              const Divider(height: 1, color: AppColors.border),
              Expanded(child: detail),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 320, child: picker),
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(child: detail),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LEFT — the recruiter's batches
// ═══════════════════════════════════════════════════════════════════════════

class _RequestPicker extends StatelessWidget {
  const _RequestPicker({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Text(
              'Shortlist batches',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('recruiter_requests')
                  .orderBy('created_at', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _Message(
                      icon: Icons.error_outline,
                      text: 'Could not load requests.\n${snap.error}');
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const _Message(
                      icon: Icons.inbox_outlined,
                      text: 'No recruiter has sent a shortlist yet.');
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    final id = docs[i].id;
                    final created = (d['created_at'] as Timestamp?)?.toDate();
                    return _RequestTile(
                      title: (d['recruiter_email'] ?? 'Recruiter').toString(),
                      count: (d['total_candidates'] as num?)?.toInt() ?? 0,
                      released: d['assessment_released_at'] != null,
                      round: (d['round'] as num?)?.toInt() ?? 1,
                      date: created,
                      isSelected: id == selected,
                      onTap: () =>
                          context.read<AdminAssessmentProvider>().openRequest(id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.title,
    required this.count,
    required this.released,
    required this.round,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool released;
  final int round;
  final DateTime? date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primary : AppColors.ink,
                        ),
                      ),
                    ),
                    if (released)
                      const Icon(Icons.send_rounded,
                          size: 13, color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 5),
                // Without this, one recruiter's two batches look like the same
                // thing sent twice. They are one shortlist and the revision of
                // it, and which is which decides what this screen can do.
                Row(
                  children: [
                    _Pill(
                      text: round >= 2 ? 'Round $round · revised' : 'Round 1',
                      color: round >= 2 ? AppColors.accent : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        [
                          '$count candidate${count == 1 ? '' : 's'}',
                          if (date != null) DateFormat('d MMM').format(date!),
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
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
//  RIGHT — the batch itself
// ═══════════════════════════════════════════════════════════════════════════

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({required this.provider});

  final AdminAssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (provider.error.isNotEmpty)
          _Banner(
            tone: AppColors.danger,
            soft: AppColors.dangerSoft,
            icon: Icons.error_outline_rounded,
            text: provider.error,
            onDismiss: provider.clearMessages,
          ),
        if (provider.notice.isNotEmpty)
          _Banner(
            tone: AppColors.success,
            soft: AppColors.successSoft,
            icon: Icons.check_circle_outline_rounded,
            text: provider.notice,
            onDismiss: provider.clearMessages,
          ),

        // A revised batch is past the assessment. Offering to build a paper
        // and invite these people again would be offering to redo the step
        // that selected them, which is how an admin ends up re-testing a
        // candidate who already passed.
        if (provider.isRevisedBatch) ...[
          _RevisedBanner(provider: provider),
          const SizedBox(height: 16),
          _StepCard(
            step: 1,
            title: 'Results this shortlist was made on',
            subtitle: 'Carried from the round it revises — not re-run',
            child: _CarriedScoresPanel(provider: provider),
          ),
          const SizedBox(height: 16),
          _StepCard(
            step: 2,
            title: 'Interviews',
            subtitle: 'Booked by the recruiter · you issue the joining links',
            child: const _RevisedInterviewHint(),
          ),
        ] else ...[
          _StepCard(
            step: 1,
            title: 'Question paper',
            subtitle: provider.jobTitle.isEmpty
                ? 'One paper per job, shared by everyone in this batch'
                : provider.jobTitle,
            child: _BankPanel(provider: provider),
          ),
          const SizedBox(height: 16),

          _StepCard(
            step: 2,
            title: 'Invite candidates',
            subtitle: 'Each gets their own link, valid for 24 hours',
            child: _InvitePanel(provider: provider),
          ),
          const SizedBox(height: 16),

          _StepCard(
            step: 3,
            title: 'Live board',
            subtitle:
                '${provider.submittedCount} of ${provider.rows.length} finished',
            child: _BoardPanel(provider: provider),
          ),
          const SizedBox(height: 16),

          _StepCard(
            step: 4,
            title: 'Send scores to the recruiter',
            subtitle: 'They re-shortlist from the results',
            child: _ReleasePanel(provider: provider),
          ),
        ],
      ],
    );
  }
}

// ── A revised batch ─────────────────────────────────────────────────────────

/// Says plainly what a second batch from the same recruiter is.
///
/// Two entries from one recruiter otherwise read as the same shortlist sent
/// twice, which is the wrong conclusion to draw before deciding what to do
/// with either of them.
class _RevisedBanner extends StatelessWidget {
  const _RevisedBanner({required this.provider});

  final AdminAssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.replay_rounded, size: 19, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round ${provider.round} — revised after the assessment',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 5),
                Text(
                  'The recruiter picked these ${provider.candidates.length} '
                  'from the earlier batch after seeing their scores. There is '
                  'nothing to test here — the assessment already happened. '
                  'What is left is the interviews.',
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The scores this shortlist was decided on, read from the batch that produced
/// them rather than copied forward.
class _CarriedScoresPanel extends StatelessWidget {
  const _CarriedScoresPanel({required this.provider});

  final AdminAssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    final scores = provider.carriedScores;
    if (scores.isEmpty) {
      return const _Hint(
        icon: Icons.help_outline_rounded,
        text: 'No assessment results are attached to the batch this one '
            'revises. The recruiter chose these candidates on something else.',
      );
    }

    final rows = provider.candidates.map((c) {
      final uid = (c['uid'] ?? '').toString();
      final raw = scores[uid];
      final s = raw is Map ? Map<String, dynamic>.from(raw) : null;
      return (
        name: (c['name'] ?? uid).toString(),
        percentage: (s?['percentage'] as num?)?.toInt(),
        correct: (s?['correct'] as num?)?.toInt(),
        total: (s?['total'] as num?)?.toInt() ?? 20,
        verdict: (s?['verdict'] ?? '').toString(),
      );
    }).toList()
      ..sort((a, b) => (b.percentage ?? -1).compareTo(a.percentage ?? -1));

    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(r.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink)),
                ),
                if (r.percentage == null)
                  const Text('No score on file',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textFaint))
                else ...[
                  Text('${r.correct}/${r.total}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const SizedBox(width: 8),
                  _Pill(
                    text: '${r.percentage}% ${r.verdict}',
                    color: r.verdict == 'pass'
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Points at where the interview work actually happens.
class _RevisedInterviewHint extends StatelessWidget {
  const _RevisedInterviewHint();

  @override
  Widget build(BuildContext context) => const _Hint(
        icon: Icons.event_available_outlined,
        text: 'The recruiter books the slots. Each booking appears on that '
            'candidate\'s card under Recruiter Requests, where you generate '
            'the joining link.',
      );
}

// ── Step 1: the paper ───────────────────────────────────────────────────────

class _BankPanel extends StatelessWidget {
  const _BankPanel({required this.provider});

  final AdminAssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    final bank = provider.bank;

    if (bank == null && !provider.backendReachable) {
      return const _Hint(
        icon: Icons.cloud_off_rounded,
        text: 'Cannot reach the assessment backend, so the paper for this job '
            'could not be loaded. There may well be one — this is not the same '
            'as there being none. Check the service is running, then reopen '
            'this batch.',
      );
    }

    if (bank == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No paper has been generated for this job yet. Generating costs one '
            'AI call for the whole batch — every candidate is then sampled from '
            'the same set, which is what makes their scores comparable.',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: provider.busy ? null : () => provider.generateBank(),
            icon: provider.busy
                ? const SizedBox(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome_rounded, size: 17),
            label: const Text('Generate question paper'),
          ),
        ],
      );
    }

    final tiers = bank.tierCounts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Pill(
              text: bank.isApproved ? 'Approved' : 'Draft — not yet approved',
              color: bank.isApproved ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(
              '${bank.questions.length} questions  ·  '
              '${tiers['easy']} easy / ${tiers['medium']} medium / ${tiers['hard']} hard',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!bank.isApproved)
          const Text(
            'Read the questions before approving. A wrong answer key scores '
            'every candidate against it, and that is not something you can take '
            'back once the batch has sat the test.',
            style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => _openReview(context, provider),
              icon: const Icon(Icons.fact_check_outlined, size: 17),
              label: Text(bank.isApproved ? 'Review paper' : 'Review and approve'),
            ),
            OutlinedButton.icon(
              onPressed: provider.busy
                  ? null
                  : () => _confirmRegenerate(context, provider),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Regenerate'),
            ),
          ],
        ),
      ],
    );
  }

  static void _openReview(BuildContext context, AdminAssessmentProvider p) {
    showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: p,
        child: _BankReviewDialog(bank: p.bank!),
      ),
    );
  }

  static Future<void> _confirmRegenerate(
      BuildContext context, AdminAssessmentProvider p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate the paper?'),
        content: const Text(
          'This replaces every question and costs another AI call. Candidates '
          'who have already sat the test keep the score they earned on the old '
          'paper, which will no longer be comparable with the new one.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Regenerate')),
        ],
      ),
    );
    if (ok == true) await p.generateBank(force: true);
  }
}

class _BankReviewDialog extends StatefulWidget {
  const _BankReviewDialog({required this.bank});

  final QuestionBank bank;

  @override
  State<_BankReviewDialog> createState() => _BankReviewDialogState();
}

class _BankReviewDialogState extends State<_BankReviewDialog> {
  late final List<BankQuestion> _questions = widget.bank.questions;
  final Set<String> _removed = {};

  List<BankQuestion> get _kept =>
      _questions.where((q) => !_removed.contains(q.id)).toList();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminAssessmentProvider>();
    final tooFew = _kept.length < 20;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Question paper',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _questions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, i) => _QuestionReviewTile(
                  index: i,
                  question: _questions[i],
                  removed: _removed.contains(_questions[i].id),
                  onToggleRemoved: () => setState(() {
                    final id = _questions[i].id;
                    _removed.contains(id) ? _removed.remove(id) : _removed.add(id);
                  }),
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
                      tooFew
                          ? '${_kept.length} questions kept — at least 20 are '
                              'needed to build a paper.'
                          : '${_kept.length} questions kept'
                              '${_removed.isEmpty ? '' : ', ${_removed.length} dropped'}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tooFew ? AppColors.danger : AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (_removed.isNotEmpty) ...[
                    OutlinedButton(
                      onPressed: p.busy || tooFew
                          ? null
                          : () async {
                              await p.saveBank(_kept);
                              if (context.mounted) Navigator.pop(context);
                            },
                      child: const Text('Save changes'),
                    ),
                    const SizedBox(width: 10),
                  ],
                  FilledButton.icon(
                    onPressed: p.busy || tooFew
                        ? null
                        : () async {
                            if (_removed.isEmpty) {
                              await p.approveBank();
                            } else {
                              await p.saveBank(_kept, approve: true);
                            }
                            if (context.mounted) Navigator.pop(context);
                          },
                    icon: const Icon(Icons.verified_rounded, size: 17),
                    label: Text(
                        widget.bank.isApproved ? 'Re-approve' : 'Approve this paper'),
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

class _QuestionReviewTile extends StatelessWidget {
  const _QuestionReviewTile({
    required this.index,
    required this.question,
    required this.removed,
    required this.onToggleRemoved,
  });

  final int index;
  final BankQuestion question;
  final bool removed;
  final VoidCallback onToggleRemoved;

  @override
  Widget build(BuildContext context) {
    final tierColor = switch (question.difficulty) {
      'easy' => AppColors.success,
      'hard' => AppColors.danger,
      _ => AppColors.warning,
    };

    return Opacity(
      opacity: removed ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: removed ? AppColors.danger : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${index + 1}.',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                const SizedBox(width: 8),
                _Pill(text: question.difficulty, color: tierColor),
                const SizedBox(width: 6),
                if (question.topic.isNotEmpty)
                  _Pill(text: question.topic, color: AppColors.primaryLight),
                const Spacer(),
                IconButton(
                  tooltip: removed ? 'Put back in the paper' : 'Drop this question',
                  onPressed: onToggleRemoved,
                  icon: Icon(
                    removed ? Icons.undo_rounded : Icons.delete_outline_rounded,
                    size: 18,
                    color: removed ? AppColors.primary : AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(question.text,
                style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
            const SizedBox(height: 10),
            for (var i = 0; i < question.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      i == question.correctIndex
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 15,
                      color: i == question.correctIndex
                          ? AppColors.success
                          : AppColors.textFaint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.options[i],
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: i == question.correctIndex
                              ? AppColors.ink
                              : AppColors.textSecondary,
                          fontWeight: i == question.correctIndex
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (question.explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                // Kept for the day a candidate disputes their score. It is
                // never sent to the candidate, during the test or after it.
                child: Text(
                  question.explanation,
                  style: const TextStyle(
                      fontSize: 12, height: 1.45, color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Step 2: invitations ─────────────────────────────────────────────────────

class _InvitePanel extends StatelessWidget {
  const _InvitePanel({required this.provider});

  final AdminAssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    final bank = provider.bank;
    if (bank == null && !provider.backendReachable) {
      return const _Hint(
        icon: Icons.cloud_off_rounded,
        text: 'Waiting on the assessment backend before invitations can be sent.',
      );
    }
    if (bank == null || !bank.isApproved) {
      return const _Hint(
        icon: Icons.lock_outline_rounded,
        text: 'Approve the question paper first. Invitations cannot go out on a '
            'paper nobody has read.',
      );
    }

    final invitedUids = {for (final r in provider.rows) r.candidateUid: r};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Pass mark',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            Expanded(
              child: Slider(
                value: provider.passMark.toDouble(),
                max: 100,
                divisions: 20,
                label: '${provider.passMark}%',
                onChanged: (v) => provider.setPassMark(v.round()),
              ),
            ),
            Text('${provider.passMark}%',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ],
        ),
        const Text(
          'Sets the pass/fail label the recruiter sees. It does not decide '
          'anything on its own — the raw score travels with it.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),

        ...provider.candidates.map((c) {
          final uid = (c['uid'] ?? '').toString();
          final existing = invitedUids[uid];
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: existing != null || provider.selected.contains(uid),
            onChanged: existing != null ? null : (_) => provider.toggle(uid),
            title: Text((c['name'] ?? 'Unknown').toString(),
                style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
            subtitle: Text(
              existing != null
                  ? 'Already invited — ${existing.status}'
                  : (c['target_role'] ?? '').toString(),
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          );
        }),

        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: provider.selectAllUninvited,
              child: const Text('Select everyone not yet invited'),
            ),
            FilledButton.icon(
              onPressed: provider.busy || provider.selected.isEmpty
                  ? null
                  : provider.invite,
              icon: const Icon(Icons.send_rounded, size: 17),
              label: Text(provider.selected.isEmpty
                  ? 'Send invitations'
                  : 'Send ${provider.selected.length} invitation'
                      '${provider.selected.length == 1 ? '' : 's'}'),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Step 3: the live board ──────────────────────────────────────────────────

class _BoardPanel extends StatelessWidget {
  const _BoardPanel({required this.provider});

  final AdminAssessmentProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.rows.isEmpty) {
      return const _Hint(
        icon: Icons.people_outline_rounded,
        text: 'Nobody has been invited yet. This board updates live as '
            'candidates accept, sit and submit.',
      );
    }

    return Column(
      children: [
        for (final r in provider.rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BoardRow(row: r),
          ),
      ],
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({required this.row});

  final AssessmentRow row;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (row.status) {
      'invited' => (AppColors.textMuted, 'Invited'),
      'accepted' => (AppColors.info, 'Accepted'),
      'in_progress' => (AppColors.primary, 'Sitting now'),
      'submitted' => (AppColors.success, 'Submitted'),
      'expired' => (AppColors.danger, 'Expired'),
      _ => (AppColors.textFaint, row.status),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.candidateName.isEmpty ? row.candidateUid : row.candidateName,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _Pill(text: label, color: color),
                    if (row.tabSwitches > 0) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Left the test page ${row.tabSwitches} time(s). '
                            'Recorded for context, not treated as proof of anything.',
                        child: _Pill(
                            text: '${row.tabSwitches} switches',
                            color: AppColors.warning),
                      ),
                    ],
                    if (row.resumes > 0) ...[
                      const SizedBox(width: 6),
                      _Pill(text: '${row.resumes} resumes', color: AppColors.textMuted),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: row.isDone
                ? Text(
                    '${row.correct}/${row.questionCount}  ·  ${row.percentage}%',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${row.answeredCount} / ${row.questionCount}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: row.progress,
                          minHeight: 5,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(
            width: 96,
            child: Text(
              row.submittedAt != null
                  ? DateFormat('d MMM, HH:mm').format(row.submittedAt!)
                  : row.expiresAt != null
                      ? 'by ${DateFormat('d MMM, HH:mm').format(row.expiresAt!)}'
                      : '',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 4: release ─────────────────────────────────────────────────────────

class _ReleasePanel extends StatefulWidget {
  const _ReleasePanel({required this.provider});

  final AdminAssessmentProvider provider;

  @override
  State<_ReleasePanel> createState() => _ReleasePanelState();
}

class _ReleasePanelState extends State<_ReleasePanel> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final pending = p.rows.where((r) => !r.isDone && r.status != 'expired').length;

    if (p.rows.isEmpty) {
      return const _Hint(
        icon: Icons.hourglass_empty_rounded,
        text: 'Scores can be sent once candidates have sat the test.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pending > 0)
          _Banner(
            tone: AppColors.warning,
            soft: AppColors.warningSoft,
            icon: Icons.schedule_rounded,
            text: '$pending candidate${pending == 1 ? ' is' : 's are'} still '
                'within their window. Releasing now sends what you have — '
                'anyone unfinished goes across as "not taken".',
          ),
        TextField(
          controller: _note,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Note for the recruiter — anything the numbers do not say',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: p.busy ? null : () => p.release(_note.text),
          icon: const Icon(Icons.outbox_rounded, size: 17),
          label: Text(p.scoresReleased ? 'Send updated scores' : 'Send scores to recruiter'),
        ),
        const SizedBox(height: 8),
        const Text(
          'The recruiter sees each score beside their AI match score and can '
          're-shortlist from there.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SMALL PARTS
// ═══════════════════════════════════════════════════════════════════════════

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final int step;
  final String title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: Text('$step',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: color),
        ),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.tone,
    required this.soft,
    required this.icon,
    required this.text,
    this.onDismiss,
  });

  final Color tone, soft;
  final IconData icon;
  final String text;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(13),
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
              child: Text(text,
                  style: TextStyle(fontSize: 12.5, height: 1.45, color: tone)),
            ),
            if (onDismiss != null)
              InkWell(
                onTap: onDismiss,
                child: Icon(Icons.close_rounded, size: 16, color: tone),
              ),
          ],
        ),
      );
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.textFaint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, height: 1.5, color: AppColors.textMuted)),
          ),
        ],
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34, color: AppColors.textFaint),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ),
      );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) => const _Message(
        icon: Icons.quiz_outlined,
        text: 'Pick a shortlist batch to build its assessment.',
      );
}
