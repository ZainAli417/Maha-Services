import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import 'assessment_models.dart';
import 'assessment_widgets.dart';
import 'question_bank_provider.dart';

/// Question papers, by job.
///
/// This screen is authoring, not hiring. It writes and approves the paper for a
/// job and nothing else — no candidates, no invitations, no scores. Those all
/// live on the recruiter request the candidates arrived in, which is the one
/// place the admin works from. Splitting them was the fix for a console that
/// showed the same batch twice with different powers over it.
class QuestionBankSection extends StatelessWidget {
  const QuestionBankSection({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => QuestionBankProvider()..watchJobs(),
        child: const _Console(),
      );
}

class _Console extends StatelessWidget {
  const _Console();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<QuestionBankProvider>();

    return ColoredBox(
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final picker = _JobPicker(provider: p);
          final detail = p.jobId.isEmpty
              ? const _Welcome()
              : _BankDetail(provider: p);

          if (!wide) {
            return Column(
              children: [
                SizedBox(height: 210, child: picker),
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
      ),
    );
  }
}

/// What this screen is for, before a job is picked.
///
/// Says what it does *not* do as well: the split between authoring a paper and
/// working a batch of candidates is the whole reason this screen exists, and an
/// admin who does not know it will go looking for candidates here.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.quiz_rounded,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Question papers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pick a job on the left to write, read or approve its paper. '
                  'One paper per job, reused by every batch shortlisted against '
                  'it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 17,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Candidates, invitations and scores are not here — '
                          'they are on Recruiter Requests, on the batch the '
                          'candidates arrived in.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
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

// ═══════════════════════════════════════════════════════════════════════════
//  LEFT — jobs that have somebody shortlisted against them
// ═══════════════════════════════════════════════════════════════════════════

class _JobPicker extends StatelessWidget {
  const _JobPicker({required this.provider});

  final QuestionBankProvider provider;

  @override
  Widget build(BuildContext context) {
    final jobs = provider.jobs;

    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.work_outline_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Jobs',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  'One paper per job. Every candidate shortlisted against it '
                  'sits 20 questions from that one paper — which is the only '
                  'reason two of their scores can be compared.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (provider.loadingJobs)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceAlt,
            )
          else if (jobs.isEmpty)
            const Expanded(
              child: AssessMessage(
                icon: Icons.work_off_outlined,
                text: 'No job has anybody shortlisted against it yet.',
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                itemCount: jobs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (context, i) => _JobTile(
                  job: jobs[i],
                  selected: jobs[i].jobId == provider.jobId,
                  onTap: () => provider.openJob(jobs[i].jobId),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({
    required this.job,
    required this.selected,
    required this.onTap,
  });

  final BankJob job;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color:
                        selected ? AppColors.primary : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 17,
                    color: selected ? Colors.white : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
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
                        '${job.candidateCount} shortlisted  ·  '
                        '${job.requestCount} batch'
                        '${job.requestCount == 1 ? '' : 'es'}',
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
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textFaint,
                ),
              ],
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  RIGHT — the paper
// ═══════════════════════════════════════════════════════════════════════════

class _BankDetail extends StatelessWidget {
  const _BankDetail({required this.provider});

  final QuestionBankProvider provider;

  @override
  Widget build(BuildContext context) {
    final job = provider.selectedJob;
    final bank = provider.bank;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
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
                      provider.jobTitle,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AssessPill(
                    text: switch (bank) {
                      null => 'No paper',
                      _ when bank.isApproved => 'Approved',
                      _ => 'Draft',
                    },
                    color: switch (bank) {
                      null => AppColors.textMuted,
                      _ when bank.isApproved => AppColors.success,
                      _ => AppColors.warning,
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _Meta(icon: Icons.tag_rounded, text: 'JOB ${provider.jobId}'),
                  if (job != null)
                    _Meta(
                      icon: Icons.people_outline_rounded,
                      text: '${job.candidateCount} shortlisted across '
                          '${job.requestCount} batch'
                          '${job.requestCount == 1 ? '' : 'es'}',
                    ),
                ],
              ),
              if (job != null && job.roleTitles.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                // Stated because it is the thing admins ask about the paper: it
                // is written from the job posting *and* the trades the
                // applicants actually hold, not from the job title alone.
                const Text(
                  'THE PAPER IS WRITTEN FROM',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This job posting — its title, department, experience '
                  'requirement, listed skills and full description — plus the '
                  'trades the shortlisted candidates actually hold, most '
                  'represented first:',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 9),
                // Ranked by how many candidates hold each trade, and the count
                // is shown. The prompt describes at most eight, so an admin can
                // see which eight those are rather than trusting that the right
                // ones were picked.
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final e
                        in job.roleCounts.entries.take(kPromptRoleLimit))
                      _RolePill(role: e.key, count: e.value),
                  ],
                ),
                if (job.roleOverflow > 0) ...[
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '${job.roleOverflow} less common trade'
                          '${job.roleOverflow == 1 ? '' : 's'} '
                          '${job.roleOverflow == 1 ? 'is' : 'are'} not '
                          'described to the model — the prompt covers the '
                          '$kPromptRoleLimit most represented.',
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (provider.error.isNotEmpty)
          AssessBanner(
            tone: AppColors.danger,
            soft: AppColors.dangerSoft,
            icon: Icons.error_outline_rounded,
            text: provider.error,
            onDismiss: provider.clearMessages,
          ),
        if (provider.notice.isNotEmpty)
          AssessBanner(
            tone: AppColors.success,
            soft: AppColors.successSoft,
            icon: Icons.check_circle_outline_rounded,
            text: provider.notice,
            onDismiss: provider.clearMessages,
          ),
        AssessStepCard(
          step: 1,
          title: 'Question paper',
          subtitle: '60 questions written once · candidates each sit 20 of them',
          child: _BankPanel(provider: provider),
        ),
        const SizedBox(height: 14),
        AssessStepCard(
          step: 2,
          title: 'Answer key',
          subtitle: 'Held on the server only · never sent to a candidate',
          child: _KeyPanel(provider: provider),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

/// One trade in the shortlist, with how many candidates hold it.
class _RolePill extends StatelessWidget {
  const _RolePill({required this.role, required this.count});

  final String role;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(9, 4, 5, 4),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              role,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
}

/// One count in the paper's composition, coloured by difficulty.
class _Tier extends StatelessWidget {
  const _Tier({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
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

class _BankPanel extends StatelessWidget {
  const _BankPanel({required this.provider});

  final QuestionBankProvider provider;

  @override
  Widget build(BuildContext context) {
    final bank = provider.bank;

    if (bank == null && !provider.backendReachable) {
      return const AssessHint(
        icon: Icons.cloud_off_rounded,
        text: 'Cannot reach the assessment backend, so this job\'s paper could '
            'not be loaded. There may well be one — that is not the same as '
            'there being none. Start the service, then reopen this job.',
      );
    }

    if (bank == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No paper has been written for this job yet. Generating costs one '
            'AI call, ever — every candidate shortlisted against this job is '
            'then sampled from the same set.',
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: provider.busy ? null : () => provider.generateBank(),
            icon: provider.busy
                ? const SizedBox(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AssessPill(
              text: bank.isApproved ? 'Approved' : 'Draft — not yet approved',
              color: bank.isApproved ? AppColors.success : AppColors.warning,
            ),
            _Tier(label: '${bank.questions.length} questions',
                color: AppColors.primary),
            _Tier(label: '${tiers['easy']} easy', color: AppColors.success),
            _Tier(label: '${tiers['medium']} medium', color: AppColors.warning),
            _Tier(label: '${tiers['hard']} hard', color: AppColors.danger),
            if (bank.generatedAt != null)
              Text(
                'written ${DateFormat('d MMM, HH:mm').format(bank.generatedAt!)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!bank.isApproved)
          const Text(
            'Read the questions before approving. A wrong answer key scores '
            'every candidate against it, and that is not something you can take '
            'back once a batch has sat the test.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => _openReview(context, provider),
              icon: const Icon(Icons.fact_check_outlined, size: 17),
              label: Text(
                bank.isApproved ? 'Review paper' : 'Review and approve',
              ),
            ),
            OutlinedButton.icon(
              onPressed:
                  provider.busy ? null : () => _confirmRegenerate(context, provider),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Regenerate'),
            ),
          ],
        ),
      ],
    );
  }

  static void _openReview(BuildContext context, QuestionBankProvider p) {
    showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: p,
        child: _BankReviewDialog(bank: p.bank!),
      ),
    );
  }

  static Future<void> _confirmRegenerate(
    BuildContext context,
    QuestionBankProvider p,
  ) async {
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
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
    if (ok == true) await p.generateBank(force: true);
  }
}

/// Where the answer key is, and where it is not.
///
/// Stated on the screen because it is the whole security argument for the
/// assessment, and an admin who does not know it might reasonably ask to have
/// the key emailed somewhere.
class _KeyPanel extends StatelessWidget {
  const _KeyPanel({required this.provider});

  final QuestionBankProvider provider;

  @override
  Widget build(BuildContext context) {
    final bank = provider.bank;
    if (bank == null) {
      return const AssessHint(
        icon: Icons.lock_outline_rounded,
        text: 'There is no key yet because there is no paper yet.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AssessHint(
          icon: Icons.shield_outlined,
          text: 'The correct answers are stored server-side and are never part '
              'of anything a candidate\'s browser receives. Grading happens on '
              'the server; the candidate\'s screen is told only whether the '
              'option they picked was right.',
        ),
        const SizedBox(height: 12),
        AssessHint(
          icon: Icons.visibility_outlined,
          text: 'You are the only role that can read the key, and only here — '
              'through "Review paper" above. ${bank.questions.length} answers '
              'are on file for this job.',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  REVIEW DIALOG — the one place the answer key is visible
// ═══════════════════════════════════════════════════════════════════════════

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
    final p = context.watch<QuestionBankProvider>();
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
                    child: Text(
                      'Question paper',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
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
                    _removed.contains(id)
                        ? _removed.remove(id)
                        : _removed.add(id);
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
                      widget.bank.isApproved
                          ? 'Re-approve'
                          : 'Approve this paper',
                    ),
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
            color: removed ? AppColors.danger : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${index + 1}.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                AssessPill(text: question.difficulty, color: tierColor),
                const SizedBox(width: 6),
                if (question.topic.isNotEmpty)
                  Flexible(
                    child: AssessPill(
                      text: question.topic,
                      color: AppColors.primary,
                    ),
                  ),
                const Spacer(),
                IconButton(
                  tooltip:
                      removed ? 'Put back in the paper' : 'Drop this question',
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
            Text(
              question.text,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
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
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
