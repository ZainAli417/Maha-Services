import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../Constant/js_header.dart';
import '../../../core/assessments/candidate_sitting.dart';
import '../../../core/theme/app_colors.dart';
import '../JS_Top_Bar.dart';
import 'my_sittings_provider.dart';

/// The candidate's assessments, grouped by the job they were for.
///
/// Two jobs at once: the tests still to sit, and a record of the ones already
/// taken with the score on each. Grouped by role because that is how a
/// candidate remembers them — "the one for the avionics job", not "the one on
/// the 3rd".
class MySittingsScreen extends StatefulWidget {
  const MySittingsScreen({super.key});

  @override
  State<MySittingsScreen> createState() => _MySittingsScreenState();
}

class _MySittingsScreenState extends State<MySittingsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Always a fresh read. This is the screen someone opens right after
    // sitting a test, and a cached list would show it as still to do.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<MySittingsProvider>().refresh());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final p = context.watch<MySittingsProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: isMobile
          ? const Drawer(child: JobSeekerSidebar(activeIndex: 6, isDrawer: true))
          : null,
      body: Row(
        children: [
          if (!isMobile) const JobSeekerSidebar(activeIndex: 6),
          Expanded(
            child: Column(
              children: [
                JobSeekerHeader(
                  icon: Icons.fact_check_rounded,
                  eyebrow: 'ASSESSMENTS',
                  title: 'My Assessments',
                  subtitle: 'Tests to sit, and your scores on the ones you have',
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  trailing: IconButton(
                    tooltip: 'Refresh',
                    onPressed: p.loading ? null : p.refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    color: Colors.white,
                  ),
                ),
                Expanded(child: _Body(provider: p, search: _search)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider, required this.search});

  final MySittingsProvider provider;
  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    if (provider.loading && provider.all.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error.isNotEmpty && provider.all.isEmpty) {
      return _Empty(
        icon: Icons.cloud_off_rounded,
        tone: AppColors.danger,
        title: 'Could not load your assessments',
        line: provider.error,
        action: ('Try again', provider.refresh),
      );
    }
    if (provider.all.isEmpty) {
      return const _Empty(
        icon: Icons.fact_check_outlined,
        tone: AppColors.textMuted,
        title: 'No assessments yet',
        line: 'When a recruiter shortlists you for a role that needs a test, '
            'the invitation appears here and in your email.',
      );
    }

    final wide = MediaQuery.of(context).size.width >= 900;
    final groups = provider.groups;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 14, vertical: 16),
        children: [
          _RecordStrip(provider: provider, wide: wide),
          const SizedBox(height: 14),
          _Controls(provider: provider, search: search, wide: wide),
          const SizedBox(height: 14),
          if (groups.isEmpty)
            _Empty(
              icon: Icons.search_off_rounded,
              tone: AppColors.textMuted,
              title: 'Nothing matches',
              line: provider.query.isEmpty
                  ? 'No assessments in this category.'
                  : 'No assessment matches "${provider.query}".',
              action: ('Clear', () {
                search.clear();
                provider.setQuery('');
                provider.setFilter(SittingFilter.all);
              }),
            )
          else
            for (final g in groups)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _JobCard(group: g, wide: wide),
              ),
        ],
      ),
    );
  }
}

// ── the record, three numbers ───────────────────────────────────────────────

class _RecordStrip extends StatelessWidget {
  const _RecordStrip({required this.provider, required this.wide});

  final MySittingsProvider provider;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final r = provider.record;
    final cards = [
      (
        'To do',
        '${provider.toDoCount}',
        Icons.pending_actions_rounded,
        provider.toDoCount > 0 ? AppColors.warning : AppColors.textMuted,
      ),
      ('Completed', '${r.taken}', Icons.task_alt_rounded, AppColors.primary),
      // Null, not zero: "no tests marked" and "averaged nought" are not the
      // same thing to read about yourself.
      (
        'Average score',
        r.average == null ? '—' : '${r.average}%',
        Icons.insights_rounded,
        AppColors.accent,
      ),
      (
        'Best score',
        r.best == null ? '—' : '${r.best}%',
        Icons.military_tech_rounded,
        AppColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth < 420 ? 2 : (wide ? 4 : 2);
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: c.maxWidth / columns / 74,
          children: [
            for (final (label, value, icon, tone) in cards)
              _Stat(label: label, value: value, icon: icon, tone: tone),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label, value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: tone),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── search and filters ─────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  const _Controls({
    required this.provider,
    required this.search,
    required this.wide,
  });

  final MySittingsProvider provider;
  final TextEditingController search;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: search,
      onChanged: provider.setQuery,
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search by role or company',
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textFaint),
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
        suffixIcon: provider.query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: () {
                  search.clear();
                  provider.setQuery('');
                },
              ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );

    final chips = Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final f in SittingFilter.values)
          _Chip(
            label: f.label,
            count: SittingLibrary.filter(provider.all, f).length,
            selected: provider.filter == f,
            onTap: () => provider.setFilter(f),
          ),
      ],
    );

    // Side by side where there is room; stacked where there is not, rather
    // than squeezing a search box down to nothing.
    return wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 320, child: field),
              const SizedBox(width: 12),
              Expanded(child: Align(alignment: Alignment.centerRight, child: chips)),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [field, const SizedBox(height: 10), chips],
          );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ── one job, with its sittings ──────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  const _JobCard({required this.group, required this.wide});

  final SittingJobGroup group;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final open = group.sittings.where((s) => s.isOpen).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: open > 0
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: open > 0
                  ? AppColors.warning.withValues(alpha: 0.06)
                  : AppColors.surfaceAlt.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.work_outline_rounded,
                      size: 17, color: AppColors.primary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.jobTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        [
                          if (group.company.isNotEmpty) group.company,
                          '${group.sittings.length} '
                              '${group.sittings.length == 1 ? 'test' : 'tests'}',
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (open > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      open == 1 ? 'Action needed' : '$open to sit',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < group.sittings.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _SittingRow(sitting: group.sittings[i], wide: wide),
          ],
        ],
      ),
    );
  }
}

class _SittingRow extends StatelessWidget {
  const _SittingRow({required this.sitting, required this.wide});

  final CandidateSitting sitting;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final s = sitting;

    final (tone, label) = switch (s.status) {
      'submitted' => (AppColors.success, 'Completed'),
      'in_progress' => (AppColors.primary, 'In progress'),
      'expired' => (AppColors.textFaint, 'Expired'),
      _ => (AppColors.warning, 'Invitation open'),
    };

    final meta = [
      DateFormat('d MMM y').format(s.invitedAt),
      if (s.isStarted) '${s.answeredCount} of ${s.questionCount} answered',
      if (s.isDone && s.correct != null)
        '${s.correct} of ${s.questionCount} correct',
      if (s.isDone && (s.skipped ?? 0) > 0) '${s.skipped} skipped',
    ].join('  ·  ');

    final status = Row(
      children: [
        Container(width: 7, height: 7,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: tone == AppColors.textFaint ? AppColors.textMuted : tone,
                ),
              ),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );

    final score = s.score == null
        ? const SizedBox.shrink()
        : _ScorePill(score: s.score!);

    final action = s.isExpired
        ? null
        : FilledButton(
            onPressed: () => context.go('/assessment/${s.id}'),
            style: FilledButton.styleFrom(
              backgroundColor: s.isDone ? AppColors.surfaceAlt : tone,
              foregroundColor: s.isDone ? AppColors.textSecondary : Colors.white,
              minimumSize: const Size(0, 34),
              visualDensity: VisualDensity.compact,
              elevation: 0,
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            child: Text(s.action),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: wide
          ? Row(
              children: [
                Expanded(child: status),
                score,
                if (action != null) ...[const SizedBox(width: 10), action],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [Expanded(child: status), score]),
                if (action != null) ...[
                  const SizedBox(height: 10),
                  action,
                ],
              ],
            ),
    );
  }
}

/// The score, and nothing about passing.
///
/// The server does not send the candidate a verdict — whether this was a pass
/// is the recruiter's to be told first — so this shows the mark and stops
/// there rather than inventing a threshold.
class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final tone = switch (score) {
      >= 80 => AppColors.success,
      >= 60 => AppColors.primary,
      >= 40 => AppColors.warning,
      _ => AppColors.danger,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: tone),
          ),
          Text(
            '%',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: tone),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.tone,
    required this.title,
    required this.line,
    this.action,
  });

  final IconData icon;
  final Color tone;
  final String title, line;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 26, color: tone),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  line,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: action!.$2,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text(action!.$1),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
