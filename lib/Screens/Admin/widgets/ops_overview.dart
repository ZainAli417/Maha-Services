import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/admin/assessment_ops.dart';
import '../../../core/theme/app_colors.dart';
import 'ops_provider.dart';

/// The admin's own work, on the dashboard.
///
/// Four parts, in the order an admin needs them: what is waiting on *them*,
/// where every candidate currently is, what the scores look like, and which
/// jobs are moving. Every figure comes from [AssessmentOps]; nothing on this
/// screen counts anything itself.
class OpsOverview extends StatelessWidget {
  const OpsOverview({
    super.key,
    required this.isMobile,
    this.padding = EdgeInsets.zero,
  });

  final bool isMobile;

  /// Left to the caller. The admin dashboard already pads its scroll view; the
  /// recruiter dashboard uses unpadded slivers and supplies its own.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminOpsProvider>();
    final ops = provider.ops;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(
            icon: Icons.rule_folder_rounded,
            title: 'Assessment operations',
            subtitle: 'Every batch a recruiter has sent, and what is waiting '
                'on you',
          ),
          const SizedBox(height: 14),
          if (provider.error.isNotEmpty)
            _Note(
              icon: Icons.error_outline_rounded,
              tone: AppColors.danger,
              text: provider.error,
            )
          else if (provider.loading)
            const _Loading()
          else if (ops.received == 0)
            const _Note(
              icon: Icons.inbox_outlined,
              tone: AppColors.textMuted,
              text: 'No recruiter has sent a shortlist yet. When one does, the '
                  'whole assessment pipeline appears here.',
            )
          else ...[
            _ActionQueue(actions: ops.actions, isMobile: isMobile),
            const SizedBox(height: 14),
            _FunnelGrid(ops: ops),
            const SizedBox(height: 14),
            if (isMobile) ...[
              _ScoreChart(ops: ops),
              const SizedBox(height: 14),
              _JobTable(rows: ops.jobRows, isMobile: true),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: _ScoreChart(ops: ops)),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 6,
                    child: _JobTable(rows: ops.jobRows, isMobile: false),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  1. WHAT IS WAITING ON YOU
// ═══════════════════════════════════════════════════════════════════════════

class _ActionQueue extends StatelessWidget {
  const _ActionQueue({required this.actions, required this.isMobile});

  final List<OpsAction> actions;
  final bool isMobile;

  static ({Color tone, IconData icon, String label}) _style(OpsUrgency u) =>
      switch (u) {
        OpsUrgency.blocking => (
            tone: AppColors.danger,
            icon: Icons.block_rounded,
            label: 'BLOCKED',
          ),
        OpsUrgency.waiting => (
            tone: AppColors.warning,
            icon: Icons.hourglass_top_rounded,
            label: 'WAITING ON YOU',
          ),
        OpsUrgency.soon => (
            tone: AppColors.primaryLight,
            icon: Icons.timer_outlined,
            label: 'CLOSING SOON',
          ),
        OpsUrgency.watch => (
            tone: AppColors.textMuted,
            icon: Icons.visibility_outlined,
            label: 'FOR INFORMATION',
          ),
      };

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 20, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nothing is waiting on you. Every paper is approved, every '
                'score has gone across, and every booked interview has a link.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 1080 ? 3 : (c.maxWidth >= 640 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 118,
          ),
          itemBuilder: (_, i) {
            final a = actions[i];
            final s = _style(a.urgency);
            return Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: s.tone.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(s.icon, size: 13, color: s.tone),
                      const SizedBox(width: 6),
                      Text(
                        s.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: s.tone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    a.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      // What happens if it is left, not what to click. An admin
                      // who knows the consequence can set the priority.
                      a.detail,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  2. WHERE EVERYBODY IS
// ═══════════════════════════════════════════════════════════════════════════

class _FunnelGrid extends StatelessWidget {
  const _FunnelGrid({required this.ops});

  final AssessmentOps ops;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _Cell(
        label: 'Received',
        value: '${ops.received}',
        hint: 'candidates across ${ops.batches} batch'
            '${ops.batches == 1 ? '' : 'es'}',
        icon: Icons.inbox_rounded,
        color: AppColors.primary,
      ),
      _Cell(
        label: 'Invited',
        value: '${ops.invited}',
        hint: '${ops.notInvited} never invited',
        icon: Icons.send_rounded,
        color: AppColors.primaryLight,
      ),
      _Cell(
        label: 'Mid-test',
        value: '${ops.inFlight}',
        hint: 'invited or sitting it now',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
      ),
      _Cell(
        label: 'Sat the test',
        value: '${ops.satTest}',
        hint: '${ops.expired} let it expire',
        icon: Icons.assignment_turned_in_rounded,
        color: AppColors.info,
      ),
      _Cell(
        label: 'Passed',
        value: '${ops.passed}',
        hint: '${ops.failed} under the mark',
        icon: Icons.verified_rounded,
        color: AppColors.success,
      ),
      _Cell(
        label: 'Scores sent',
        value: '${ops.releasedScores}',
        hint: ops.unsentScores == 0
            ? 'all released'
            : '${ops.unsentScores} still with you',
        icon: Icons.forward_to_inbox_rounded,
        color: AppColors.accent,
        emphasis: ops.unsentScores > 0,
      ),
      _Cell(
        label: 'Kept',
        value: '${ops.keptForInterview}',
        hint: 'chosen for interview',
        icon: Icons.push_pin_rounded,
        color: AppColors.primary,
      ),
      _Cell(
        label: 'Links needed',
        value: '${ops.interviewsWithoutLink}',
        hint: '${ops.interviewsBooked} booked in total',
        icon: Icons.add_link_rounded,
        color: AppColors.danger,
        emphasis: ops.interviewsAtRisk > 0,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 1120
            ? 8
            : c.maxWidth >= 860
                ? 4
                : c.maxWidth >= 560
                    ? 4
                    : 2;
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

class _Cell extends StatelessWidget {
  const _Cell({
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
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: '$label — $hint',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: emphasis ? color.withValues(alpha: 0.06) : AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: emphasis ? color.withValues(alpha: 0.5) : AppColors.border,
              width: emphasis ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
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
//  3. WHAT THE SCORES LOOK LIKE
// ═══════════════════════════════════════════════════════════════════════════

/// Score distribution in ten-point buckets.
///
/// The shape is the point, not the average. A batch clustered at 55–65 says the
/// pass mark is doing the deciding; a batch spread from 20 to 95 says the paper
/// is. An average of 67% hides both.
class _ScoreChart extends StatelessWidget {
  const _ScoreChart({required this.ops});

  final AssessmentOps ops;

  @override
  Widget build(BuildContext context) {
    final buckets = ops.scoreHistogram;
    final total = buckets.fold<int>(0, (a, b) => a + b);
    final peak = buckets.isEmpty ? 0 : buckets.reduce((a, b) => a > b ? a : b);

    return _Panel(
      title: 'Score distribution',
      subtitle: total == 0
          ? 'No score has come back yet'
          : '$total sitting${total == 1 ? '' : 's'} graded'
              '${ops.avgScore == null ? '' : ' · avg ${ops.avgScore!.round()}%'}'
              '${ops.passRate == null ? '' : ' · ${(ops.passRate! * 100).round()}% pass'}',
      footer: total == 0
          ? null
          : Row(
              children: [
                _Key(color: AppColors.danger.withValues(alpha: 0.75),
                    label: 'under 60%'),
                const SizedBox(width: 14),
                _Key(color: AppColors.success, label: '60% and over'),
              ],
            ),
      child: total == 0
          ? const SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  'The histogram fills in as candidates finish.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          : SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (peak + 1).toDouble(),
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                        '${group.x * 10}–${group.x * 10 + 9}%\n'
                        '${rod.toY.toInt()} candidate'
                        '${rod.toY.toInt() == 1 ? '' : 's'}',
                        GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: peak <= 5 ? 1 : (peak / 4).ceilToDouble(),
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            color: AppColors.textFaint,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          // Every other label, or ten of them collide.
                          if (i.isOdd) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              '${i * 10}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var i = 0; i < buckets.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: buckets[i].toDouble(),
                            width: 14,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                            // Coloured by which side of the 60% pass mark the
                            // bucket falls on, so the split is visible without
                            // a legend to read.
                            color: i < 6
                                ? AppColors.danger.withValues(alpha: 0.75)
                                : AppColors.success,
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

class _Key extends StatelessWidget {
  const _Key({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
}

// ═══════════════════════════════════════════════════════════════════════════
//  4. WHICH JOBS ARE MOVING
// ═══════════════════════════════════════════════════════════════════════════

class _JobTable extends StatelessWidget {
  const _JobTable({required this.rows, required this.isMobile});

  final List<OpsJobRow> rows;
  final bool isMobile;

  static ({Color tone, String label}) _paper(String status) => switch (status) {
        'approved' => (tone: AppColors.success, label: 'Approved'),
        'draft' => (tone: AppColors.warning, label: 'Draft'),
        _ => (tone: AppColors.danger, label: 'No paper'),
      };

  @override
  Widget build(BuildContext context) => _Panel(
        title: 'By job',
        subtitle: '${rows.length} job${rows.length == 1 ? '' : 's'} with '
            'candidates in the pipeline',
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 18, color: AppColors.border),
              _JobRowTile(row: rows[i], paper: _paper(rows[i].paperStatus)),
            ],
          ],
        ),
      );
}

class _JobRowTile extends StatelessWidget {
  const _JobRowTile({required this.row, required this.paper});

  final OpsJobRow row;
  final ({Color tone, String label}) paper;

  @override
  Widget build(BuildContext context) {
    // Progress against the shortlist, so a job with 3 of 20 tested reads
    // differently from one with 17 of 17.
    final progress =
        row.shortlisted == 0 ? 0.0 : row.satTest / row.shortlisted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                row.jobTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: paper.tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: paper.tone.withValues(alpha: 0.35)),
              ),
              child: Text(
                paper.label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: paper.tone,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 5,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
          ),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _Fact(label: 'shortlisted', value: '${row.shortlisted}'),
            _Fact(label: 'invited', value: '${row.invited}'),
            _Fact(label: 'sat', value: '${row.satTest}'),
            _Fact(
              label: 'pass rate',
              value: row.passRate == null
                  ? '—'
                  : '${(row.passRate! * 100).round()}%',
              tone: row.passRate == null ? null : AppColors.success,
            ),
            _Fact(
              label: 'avg',
              value: row.avgScore == null
                  ? '—'
                  : '${row.avgScore!.round()}%',
            ),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.tone});

  final String label, value;
  final Color? tone;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: tone ?? AppColors.ink,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
}

// ── shared shells ──────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    this.footer,
    required this.child,
  });

  final String title, subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            child,
            if (footer != null) ...[
              const SizedBox(height: 12),
              footer!,
            ],
          ],
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  subtitle,
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
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.tone, required this.text});

  final IconData icon;
  final Color tone;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: tone.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: tone),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
}
