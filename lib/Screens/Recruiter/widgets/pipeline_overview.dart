import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/interviews/interview.dart';
import '../../../core/interviews/interview_provider.dart';
import '../../../core/recruiter/hiring_funnel.dart';
import '../../../core/theme/app_colors.dart';
import '../LIst_of_Applicants_provider.dart';

/// The recruiter's whole pipeline on one screen.
///
/// Reads every number from [HiringFunnel] rather than counting anything here.
/// A widget that does its own arithmetic is how a "15 passed" tile ends up
/// beside a "14 passed" chart with no way to tell which is wrong.
///
/// Laid out as a stage strip over a detail grid: the strip answers "where is
/// everybody", the grid answers "what do I do next". Both reflow rather than
/// scale down, so a phone gets the same information in one column.
class PipelineOverview extends StatefulWidget {
  const PipelineOverview({super.key, required this.isMobile});

  final bool isMobile;

  @override
  State<PipelineOverview> createState() => _PipelineOverviewState();
}

class _PipelineOverviewState extends State<PipelineOverview> {
  /// null means every job.
  String? _jobId;

  @override
  Widget build(BuildContext context) {
    final applicants = context.watch<ApplicantsProvider>();
    final interviews = context.watch<InterviewProvider>();

    final booked = {
      for (final i in interviews.interviews)
        if (i.status != InterviewStatus.cancelled) i.candidateUid,
    };
    final jobs = applicants.shortlistedJobs;

    // A job filter that no longer matches anything would silently show an empty
    // pipeline, so it falls back to "all jobs" rather than showing zeroes.
    final active = jobs.any((j) => j.id == _jobId) ? _jobId : null;
    final f = applicants.funnel(bookedUids: booked, jobId: active);

    final pad = widget.isMobile ? 16.0 : 28.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 18, pad, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            jobs: jobs,
            selected: active,
            onSelected: (id) => setState(() => _jobId = id),
            isMobile: widget.isMobile,
          ),
          const SizedBox(height: 14),
          if (f.shortlisted == 0)
            const _Empty()
          else ...[
            _StageStrip(funnel: f, isMobile: widget.isMobile),
            const SizedBox(height: 14),
            _DetailGrid(funnel: f, isMobile: widget.isMobile),
            const SizedBox(height: 14),
            _RatioRow(funnel: f, isMobile: widget.isMobile),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  HEADER — title and the job scope
// ═══════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.jobs,
    required this.selected,
    required this.onSelected,
    required this.isMobile,
  });

  final List<({String id, String title, int shortlisted})> jobs;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final title = Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.insights_rounded,
            size: 17,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your pipeline',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.2,
                ),
              ),
              Text(
                'Every shortlisted candidate, and where they are',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (jobs.length < 2) return title;

    final picker = _JobScope(
      jobs: jobs,
      selected: selected,
      onSelected: onSelected,
    );

    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 10), picker],
          )
        : Row(children: [Expanded(child: title), picker]);
  }
}

class _JobScope extends StatelessWidget {
  const _JobScope({
    required this.jobs,
    required this.selected,
    required this.onSelected,
  });

  final List<({String id, String title, int shortlisted})> jobs;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final current = jobs.where((j) => j.id == selected).firstOrNull;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: PopupMenuButton<String?>(
        tooltip: 'Scope the pipeline to one job',
        onSelected: onSelected,
        position: PopupMenuPosition.under,
        itemBuilder: (_) => [
          PopupMenuItem<String?>(
            value: null,
            child: Text(
              'All jobs',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: selected == null ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          const PopupMenuDivider(),
          for (final j in jobs)
            PopupMenuItem<String?>(
              value: j.id,
              child: Text(
                '${j.title}  ·  ${j.shortlisted}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight:
                      selected == j.id ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.work_outline_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                current?.title ?? 'All jobs',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STAGE STRIP — where everybody is
// ═══════════════════════════════════════════════════════════════════════════

/// One stage: how many reached it, and what share of the shortlist that is.
typedef _Stage = ({String label, int count, IconData icon, Color color});

class _StageStrip extends StatelessWidget {
  const _StageStrip({required this.funnel, required this.isMobile});

  final HiringFunnel funnel;
  final bool isMobile;

  List<_Stage> get _stages => [
        (
          label: 'Shortlisted',
          count: funnel.shortlisted,
          icon: Icons.bookmark_added_outlined,
          color: AppColors.primary,
        ),
        (
          label: 'With admin',
          count: funnel.sentToAdmin,
          icon: Icons.forward_to_inbox_outlined,
          color: AppColors.primaryLight,
        ),
        (
          label: 'Sat the test',
          count: funnel.satTest,
          icon: Icons.assignment_turned_in_outlined,
          color: AppColors.info,
        ),
        (
          label: 'Passed',
          count: funnel.passed,
          icon: Icons.verified_outlined,
          color: AppColors.success,
        ),
        (
          label: 'Interview set',
          count: funnel.interviewBooked,
          icon: Icons.event_available_outlined,
          color: AppColors.accent,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final stages = _stages;
    final total = funnel.shortlisted;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // The bars carry the proportion, so they reflow to one column on a
          // phone rather than shrinking into unreadable slivers.
          if (isMobile)
            Column(
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _StageBar(
                    stage: stages[i],
                    total: total,
                    previous: i == 0 ? null : stages[i - 1].count,
                  ),
                ],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 26),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textFaint,
                      ),
                    ),
                  Expanded(
                    child: _StageBar(
                      stage: stages[i],
                      total: total,
                      previous: i == 0 ? null : stages[i - 1].count,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _StageBar extends StatelessWidget {
  const _StageBar({
    required this.stage,
    required this.total,
    required this.previous,
  });

  final _Stage stage;
  final int total;

  /// The stage before this one, for the drop-off note. Null for the first.
  final int? previous;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : stage.count / total;
    final lost = previous == null ? 0 : previous! - stage.count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(stage.icon, size: 14, color: stage.color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                stage.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${stage.count}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              total == 0 ? '' : '${(share * 100).round()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: stage.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: share,
            minHeight: 5,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: AlwaysStoppedAnimation(stage.color),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          // Drop-off, named. A stage count on its own does not say whether the
          // people missing from it were rejected, are still moving, or were
          // never sent.
          lost <= 0 ? 'no drop-off' : '$lost did not reach here',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: lost <= 0 ? AppColors.textFaint : AppColors.warning,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DETAIL GRID — what to do next
// ═══════════════════════════════════════════════════════════════════════════

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.funnel, required this.isMobile});

  final HiringFunnel funnel;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    // Ordered by whose move it is: the recruiter's first, then waiting, then
    // closed. A dashboard that leads with what somebody else owes you is a
    // dashboard nobody acts on.
    final tiles = <Widget>[
      _Tile(
        label: 'Ready to interview',
        value: '${funnel.interviewReady}',
        hint: 'passed, no slot booked — your move',
        icon: Icons.event_available_rounded,
        color: AppColors.accent,
        emphasis: funnel.interviewReady > 0,
      ),
      _Tile(
        label: 'Not sent yet',
        value: '${funnel.notSentYet}',
        hint: 'shortlisted, still with you',
        icon: Icons.outbox_rounded,
        color: AppColors.primary,
        emphasis: funnel.notSentYet > 0,
      ),
      _Tile(
        label: 'Awaiting result',
        value: '${funnel.awaitingResult}',
        hint: 'invited, test not finished',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
      ),
      _Tile(
        label: 'Did not pass',
        value: '${funnel.failed}',
        hint: 'under the pass mark — closed',
        icon: Icons.block_rounded,
        color: AppColors.danger,
      ),
      _Tile(
        label: 'Expired',
        value: '${funnel.expired}',
        hint: 'never sat it in 24 hours',
        icon: Icons.timer_off_rounded,
        color: AppColors.textMuted,
      ),
      _Tile(
        label: 'Interviews set',
        value: '${funnel.interviewBooked}',
        hint: 'admin issues the joining link',
        icon: Icons.videocam_rounded,
        color: AppColors.primaryLight,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        // Reflow on measured width, not on a device guess: this sits inside a
        // sidebar layout, so the viewport is not what the grid actually gets.
        final columns = c.maxWidth >= 1120
            ? 6
            : c.maxWidth >= 700
                ? 3
                : 2;
        // A fixed height rather than an aspect ratio. Tying height to column
        // width is what made these tiles nearly square, with a number at the
        // top, a label at the bottom and a hole between them.
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 68,
          ),
          itemBuilder: (_, i) => tiles[i],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
    this.emphasis = false,
  });

  final String label, value, hint;
  final IconData icon;
  final Color color;

  /// Draws the border in the tile's own colour when there is something to act
  /// on, so the eye lands on the actionable tiles first.
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Tooltip(
        // The full sentence lives here rather than on the card. It is worth
        // reading once and worth no vertical space after that.
        message: '$label — $hint',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: emphasis ? color.withValues(alpha: 0.05) : AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color:
                  emphasis ? color.withValues(alpha: 0.5) : AppColors.border,
              width: emphasis ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.05,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: AppColors.textSecondary,
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

// ═══════════════════════════════════════════════════════════════════════════
//  RATIOS — the quality of the batch, not its size
// ═══════════════════════════════════════════════════════════════════════════

class _RatioRow extends StatelessWidget {
  const _RatioRow({required this.funnel, required this.isMobile});

  final HiringFunnel funnel;
  final bool isMobile;

  static String _pct(double? v) =>
      v == null ? '—' : '${(v * 100).round()}%';

  static String _score(double? v) =>
      v == null ? 'Not analysed' : '${v.round()}%';

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      _Ratio(
        label: 'Pass rate',
        value: _pct(funnel.passRate),
        sub: funnel.scored == 0
            ? 'no scores in yet'
            : '${funnel.passed} of ${funnel.scored} scored',
        icon: Icons.verified_rounded,
        color: AppColors.success,
      ),
      _Ratio(
        label: 'Avg test score',
        value: _score(funnel.avgTestScore),
        sub: funnel.scored == 0
            ? 'released scores only'
            : 'across ${funnel.scored}',
        icon: Icons.fact_check_rounded,
        color: AppColors.info,
      ),
      _Ratio(
        label: 'Avg AI score',
        value: _score(funnel.avgAiScore),
        sub: funnel.aiAnalysed == 0
            ? 'nobody analysed'
            : 'across ${funnel.aiAnalysed}',
        icon: Icons.bolt_rounded,
        color: AppColors.primaryLight,
      ),
      _Ratio(
        label: 'AI coverage',
        value: funnel.shortlisted == 0
            ? '—'
            : _pct(funnel.aiAnalysed / funnel.shortlisted),
        sub: '${funnel.aiNotAnalysed} not analysed',
        icon: Icons.donut_large_rounded,
        color: AppColors.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 780 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 68,
          ),
          itemBuilder: (_, i) => items[i],
        );
      },
    );
  }
}

class _Ratio extends StatelessWidget {
  const _Ratio({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  final String label, value, sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.26)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      height: 1.2,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Value and its denominator on one baseline. "Not analysed"
                  // is a legitimate value here, so the sub is what gives way
                  // when the row runs out of room, never the number.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 30,
              color: AppColors.textFaint,
            ),
            const SizedBox(height: 10),
            Text(
              'Nothing shortlisted yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Shortlist a candidate from an applicant list and the whole '
              'pipeline appears here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
}
