import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/interviews/arrange_interview_dialog.dart';
import '../../core/interviews/interview_provider.dart';

import '../../core/widgets/view_js_profile.dart';
import 'LIst_of_Applicants_provider.dart';
import 'active_filters_bar.dart';
import 'filter.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
class _T {
  static const primary = Color(0xFF14507F);
  static const purple = Color(0xFF15A99C);
  static const textPri = Color(0xFF0B2239);
  static const textSec = Color(0xFF5E7A8E);
  static const textTert = Color(0xFF8AA5B5);
  static const bg = Color(0xFFF4F9FB);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCE7EF);
  static const success = Color(0xFF10B981);
  static const accent = Color(0xFFEC4899);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  static const _avatarColors = [
    Color(0xFF3B82F6),
    Color(0xFF15A99C),
    Color(0xFFEC4899),
    Color(0xFF2178B5),
  ];
  static Color avatar(int i) => _avatarColors[i % _avatarColors.length];

  static TextStyle label({
    double fs = 11,
    Color? c,
    FontWeight fw = FontWeight.w500,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: fs,
    fontWeight: fw,
    color: c ?? textSec,
  );
  static TextStyle head({double fs = 14, Color? c}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fs,
        fontWeight: FontWeight.w700,
        color: c ?? textPri,
      );
  static TextStyle body({double fs = 13, Color? c}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fs,
        color: c ?? textPri,
        height: 1.5,
      );
  static TextStyle mono({
    double fs = 14,
    Color? c,
    FontWeight fw = FontWeight.w700,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: fs,
    fontWeight: fw,
    color: c ?? textPri,
  );
}

// ─── Layout InheritedWidget ────────────────────────────────────────────────
class _LD extends InheritedWidget {
  final bool isMobile;
  const _LD({required this.isMobile, required super.child});

  static bool mobile(BuildContext ctx) {
    final inherited = ctx.dependOnInheritedWidgetOfExactType<_LD>();
    if (inherited != null) return inherited.isMobile;
    // fallback when no _LD ancestor exists (safe default)
    final mq = MediaQuery.maybeOf(ctx);
    if (mq != null) return mq.size.width < 768;
    // last resort: assume desktop
    return false;
  }

  @override
  bool updateShouldNotify(_LD old) => old.isMobile != isMobile;
}

// ─── Row helpers (pure fns) ────────────────────────────────────────────────
//
// Contact details never reach this screen — the application snapshot is
// written without them. So the line under a candidate's name is the role they
// applied as, which is the thing a recruiter is actually sorting on when
// fifteen different trades apply to one posting.
String _subtitle(ApplicantRecord a) {
  final role = a.targetRole.trim();
  if (role.isNotEmpty) return role;
  return a.location.trim().isNotEmpty ? a.location.trim() : 'Candidate';
}

/// What to show in the EXPERIENCE column, with its unit spelled out.
///
/// Three different things used to share this slot under one word. They are not
/// the same measure and a recruiter should never have to guess which one they
/// are looking at:
///
///   * flight hours — logged flying time, aircrew only
///   * years — time in service or trade, for roles that do not fly
///   * roles listed — a count of previous jobs, which is not a duration at all
///
/// The old label read "2y exp" off the job count, so two jobs looked like two
/// years of experience. Whatever this returns now names its own unit.
String _experienceOf(ApplicantRecord a) => switch (a.experienceBasis) {
  ExperienceBasis.flightHours => '${_n(a.flightHours!)} flight hours',
  ExperienceBasis.declaredYears => '${_n(a.declaredYears!)} years experience',
  // Named for where it came from. A recruiter reading "8 years of service"
  // should be able to check it against the dates on the roles below and see
  // that it is derived from them, not declared by the candidate.
  ExperienceBasis.serviceHistory => '${_n(a.serviceYears!)} years of service',
  ExperienceBasis.roleCount => a.roleCount == 0
      ? 'No history on file'
      : '${a.roleCount} role${a.roleCount == 1 ? '' : 's'} listed',
};

/// Thousands separator, because 2680 and 26800 are hard to tell apart at a
/// glance in a list.
String _n(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// Licences and aircraft, the fastest way to tell a fighter pilot from a fire
/// fighter without opening the profile.
List<String> _credentials(ApplicantRecord a, {int max = 3}) {
  final out = <String>[
    ...a.roleProfile.licences.map((l) => l.title).where((t) => t.isNotEmpty),
    ...a.roleProfile.aircraftTypes,
  ];
  final seen = <String>{};
  return [for (final v in out) if (seen.add(v)) v].take(max).toList();
}

// ─── Score helpers (pure fns) ──────────────────────────────────────────────
Color _scoreColor(int s) {
  if (s >= 85) return _T.success;
  if (s >= 70) return const Color(0xFF3B82F6);
  if (s >= 50) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

String _scoreLabel(int s) {
  if (s >= 85) return 'Excellent';
  if (s >= 70) return 'Good';
  if (s >= 50) return 'Medium';
  return 'Low';
}

// ═════════════════════════════════════════════════════════════════════════════
// ROOT WIDGET
// ═════════════════════════════════════════════════════════════════════════════
class view_shortlisted extends StatefulWidget {
  const view_shortlisted({super.key, this.jobId});
  final String? jobId;

  @override
  State<view_shortlisted> createState() => _ViewShortlistedState();
}

class _ViewShortlistedState extends State<view_shortlisted>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late final AnimationController _islandCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _islandAnim = CurvedAnimation(
    parent: _islandCtrl,
    curve: Curves.elasticOut,
  );

  late ApplicantsProvider _provider;

  /// How the table is ordered, or null for the order the list arrived in.
  ///
  /// The "Rank by Match Score" button and the AI-score column header write to
  /// this same field on purpose. Two pieces of state for one ordering is how a
  /// pressed button ends up disagreeing with the arrow above the column.
  ShortlistSort? _sort;

  bool get _rankByScore => _sort?.column == ShortlistSortColumn.aiScore;

  // ─── Lifecycle ─────────────────────────────────────────────────────────
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<ApplicantsProvider>();
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider = context.read<ApplicantsProvider>();
      _provider.addListener(_onSelectionChanged);
      _provider.refresh(jobId: widget.jobId);
    });
  }

  @override
  void didUpdateWidget(view_shortlisted old) {
    super.didUpdateWidget(old);
    if (old.jobId == widget.jobId) return;
    _sort = null;
    _searchCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider.clearSelection();
      _provider.refresh(jobId: widget.jobId);
    });
  }

  @override
  void dispose() {
    _provider.removeListener(_onSelectionChanged);
    Future.microtask(_provider.clearSelection);
    _searchCtrl
      ..removeListener(_onSearch)
      ..dispose();
    _islandCtrl.dispose();
    super.dispose();
  }

  // ─── Listeners ─────────────────────────────────────────────────────────
  void _onSearch() {
    if (mounted) setState(() {});
  }

  void _onSelectionChanged() {
    if (!mounted) return;
    final has = _provider.selectedApplicantIds.isNotEmpty;
    if (has && !_islandCtrl.isCompleted) {
      _islandCtrl.forward();
    } else if (!has && !_islandCtrl.isDismissed) {
      _islandCtrl.reverse();
    }
  }

  // ─── Data helpers ───────────────────────────────────────────────────────
  /// The people shortlisted for this job, before this screen's own controls.
  ///
  /// Everything on this screen -- the filter sheet, its live count, the chip
  /// strip -- is scoped to this list. Filtering used to run against the whole
  /// applicant pool, so narrowing a 17-person shortlist could hand back all
  /// 20 applicants.
  List<ApplicantRecord> _scope(ApplicantsProvider p) =>
      p.getShortlistForJob(widget.jobId);

  List<ApplicantRecord> _filtered(ApplicantsProvider p) {
    var list = p.applyFiltersTo(_scope(p));
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      // searchIndex already carries the name, location, role title, aircraft
      // types, licences and competencies. Matching on it means "A320" and
      // "ATPL" find people, which matching on email never could — the snapshot
      // has no email in it.
      list = list
          .where(
            (a) =>
                a.searchIndex.contains(q) ||
                (a.jobData?.title ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    final sort = _sort;
    if (sort != null) {
      list = ShortlistOrder.by(
        list,
        value: (a) => _sortKey(p, a, sort.column),
        ascending: sort.ascending,
      );
    }
    return list;
  }

  /// The number a column sorts on, or null when this candidate has none.
  ///
  /// Null rather than zero, so [ShortlistOrder] can keep "not analyzed" and
  /// "not invited" out of the ranking instead of ranking them bottom.
  num? _sortKey(
    ApplicantsProvider p,
    ApplicantRecord a,
    ShortlistSortColumn column,
  ) =>
      switch (column) {
        ShortlistSortColumn.aiScore => a.aiScore,
        // Only a released score. One the admin has not sent yet is not the
        // recruiter's to order people by, and is not on screen either.
        ShortlistSortColumn.testScore =>
          a.assessment.hasScore ? a.assessment.percentage : null,
      };

  void _sortBy(ShortlistSortColumn column) {
    setState(() => _sort = ShortlistOrder.cycle(_sort, column));
  }

  void _toggleSelectAll(ApplicantsProvider p) {
    // Only the ones that can actually be sent. Selecting a locked candidate
    // would put a tick beside a name the send then quietly drops, and the
    // recruiter would believe they had sent someone they had not.
    final list = _filtered(p).where(p.isSelectable).toList();
    if (list.isEmpty) return;
    final all = list.every((a) => p.isSelected(a.userId));
    all ? p.clearSelection() : p.selectAll(list);
  }

  void _toggleRank(ApplicantsProvider p) {
    setState(() => _sort = _rankByScore
        ? null
        : (column: ShortlistSortColumn.aiScore, ascending: false));
    _showToast(
      _rankByScore
          ? 'Candidates ranked by AI score'
          : 'Default sorting restored',
      icon: Icons.check_circle_outline,
    );
  }

  // ─── Toast ──────────────────────────────────────────────────────────────
  void _showToast(String msg, {required IconData icon}) {
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 30,
        left: 20,
        right: 20,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: _T.textPri,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: _T.success, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(msg, style: _T.label(fs: 13, c: _T.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 3), entry.remove);
  }

  // ─── Arrange interview ──────────────────────────────────────────────────
  Future<void> _arrangeInterview(
    ApplicantsProvider p, [
    ApplicantRecord? single,
  ]) async {
    final chosen = single != null ? [single] : p.selectedForInterview;
    if (chosen.isEmpty) return;

    // The interview hangs off the request that advanced them, so the admin
    // sees it on the batch they are actually working.
    final request = p.interviewRequestFor(chosen.first.userId);
    final messenger = ScaffoldMessenger.of(context);

    final booked = await showDialog<int>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<InterviewProvider>(),
        child: ArrangeInterviewDialog(
          candidates: [
            for (final a in chosen) (uid: a.userId, name: a.name),
          ],
          jobId: chosen.first.jobId,
          jobTitle: chosen.first.jobData?.title ?? '',
          requestId: (request?['request_id'] ?? '').toString(),
          round: (request?['round'] as num?)?.toInt() ?? 2,
        ),
      ),
    );

    if (!mounted || booked == null) return;

    // Booking the slot is the recruiter putting them forward, so it is written
    // as exactly that on the request the shortlist lives on. Otherwise the
    // admin's Interview Schedule holds a booking with no batch to show it in.
    final reqId = (request?['request_id'] ?? '').toString();
    await p.markAdvanced(
      requestId: reqId,
      candidateUids: [for (final a in chosen) a.userId],
    );

    if (!mounted) return;
    if (single == null) p.clearSelection();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$booked interview${booked == 1 ? '' : 's'} sent to the admin. '
          'They generate the joining link.',
        ),
      ),
    );
  }

  // ─── Send to Admin ──────────────────────────────────────────────────────
  Future<void> _sendToAdmin(ApplicantsProvider p) async {
    final notesCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, _) => Transform.scale(
        scale: anim.value,
        child: Opacity(
          opacity: anim.value,
          child: _SendToAdminDialog(
            selectedCount: p.selectedApplicantIds.length,
            round: p.pendingRound,
            notesController: notesCtrl,
            onSubmit: () => p.sendSelectedCandidatesToAdmin(
              notes: notesCtrl.text.trim().isEmpty
                  ? 'No notes provided'
                  : notesCtrl.text.trim(),
            ).then((id) => id != null),
          ),
        ),
      ),
    );

    notesCtrl.dispose();
    if (!mounted) return;

    if (ok == true) {
      messenger.showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _T.textPri,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: _T.success,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sent to admin',
                        style: _T.head(fs: 13, c: _T.white),
                      ),
                      // What actually happened, not a fixed line. A send can be
                      // a new shortlist, an answer to one already assessed, or
                      // both at once — "Pending admin review" was only ever
                      // true for the first.
                      Text(
                        p.lastSendSummary.isEmpty
                            ? 'Pending admin review.'
                            : p.lastSendSummary,
                        style: _T.label(fs: 11, c: _T.textTert),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: messenger.hideCurrentSnackBar,
                  child: Text(
                    'OK',
                    style: _T.label(fs: 12, c: _T.primary, fw: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, bc) {
        final isMobile = bc.maxWidth < 768;
        return _LD(
          isMobile: isMobile,
          child: Scaffold(
            backgroundColor: _T.bg,
            body: Consumer<ApplicantsProvider>(
              builder: (_, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _T.primary,
                      strokeWidth: 2,
                    ),
                  );
                }
                if (provider.error != null) {
                  return _ErrorPanel(
                    error: provider.error!,
                    onRetry: () => provider.refresh(jobId: widget.jobId),
                  );
                }
                final applicants = _filtered(provider);
                return Stack(
                  children: [
                    Column(
                      children: [
                        // ── Controls bar
                        RepaintBoundary(
                          child: _ControlsBar(
                            searchCtrl: _searchCtrl,
                            rankByScore: _rankByScore,
                            onToggleRank: () => _toggleRank(provider),
                            scope: _scope(provider),
                          ),
                        ),
                        ActiveFiltersBar(
                          provider: provider,
                          shown: applicants.length,
                          total: _scope(provider).length,
                          horizontalPadding: isMobile ? 12 : 20,
                        ),
                        // What the admin said when they sent the scores. This
                        // is the half of the release that a percentage cannot
                        // carry, and it belongs where the decision is made.
                        for (final n in provider.assessmentNotes)
                          _AdminNoteBanner(
                            note: n.note,
                            at: n.at,
                            scored: n.scored,
                            horizontalPadding: isMobile ? 12 : 20,
                          ),
                        // ── Content: card list on mobile, table on desktop
                        Expanded(
                          child: isMobile
                              ? _MobileCardList(
                                  applicants: applicants,
                                  provider: provider,
                                  jobId: widget.jobId,
                                  onToggleSelectAll: () =>
                                      _toggleSelectAll(provider),
                                  onViewProfile: _showProfile,
                                )
                              : _DesktopTable(
                                  applicants: applicants,
                                  provider: provider,
                                  jobId: widget.jobId,
                                  onToggleSelectAll: () =>
                                      _toggleSelectAll(provider),
                                  onViewProfile: _showProfile,
                                  onArrange: (a) => _arrangeInterview(provider, a),
                                  sort: _sort,
                                  onSort: _sortBy,
                                ),
                        ),
                      ],
                    ),
                    // ── Selection island
                    Positioned(
                      top: 10,
                      left: 8,
                      right: 8,
                      child: _SelectionIsland(
                        animation: _islandAnim,
                        provider: provider,
                        isMobile: isMobile,
                        onSend: () => _sendToAdmin(provider),
                        onArrangeInterview: () =>
                            _arrangeInterview(provider),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showProfile(ApplicantRecord a) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ViewApplicantDetails(applicant: a),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => ViewApplicantDetails(applicant: a),
      );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CONTROLS BAR
// ═════════════════════════════════════════════════════════════════════════════
class _ControlsBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final bool rankByScore;
  final VoidCallback onToggleRank;

  /// The shortlisted candidates on screen, passed through to the filter sheet
  /// so it narrows this list rather than the whole applicant pool.
  final List<ApplicantRecord> scope;

  const _ControlsBar({
    required this.searchCtrl,
    required this.rankByScore,
    required this.onToggleRank,
    required this.scope,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _LD.mobile(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _T.border)),
      ),
      child: isMobile
          ? Column(
              children: [
                _SearchField(ctrl: searchCtrl),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _RankButton(
                        active: rankByScore,
                        onTap: onToggleRank,
                        small: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterBtn(scope: scope, small: true),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: _SearchField(ctrl: searchCtrl)),
                const SizedBox(width: 10),
                _FilterBtn(scope: scope),
                const SizedBox(width: 10),
                _RankButton(active: rankByScore, onTap: onToggleRank),
              ],
            ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController ctrl;
  const _SearchField({required this.ctrl});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    style: _T.body(fs: 13),
    decoration: InputDecoration(
      hintText: 'Search candidates…',
      hintStyle: _T.label(fs: 13, c: _T.textTert),
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: _T.textTert,
        size: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _T.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _T.purple, width: 1.5),
      ),
      filled: true,
      fillColor: _T.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      isDense: true,
    ),
  );
}

class _RankButton extends StatelessWidget {
  final bool active, small;
  final VoidCallback onTap;
  const _RankButton({
    required this.active,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(
      active ? Icons.filter_list : Icons.sort_rounded,
      size: small ? 16 : 17,
    ),
    label: Text(
      active ? 'Ranked' : 'Rank by Match Score',
      style: _T.label(
        fs: small ? 12 : 13,
        c: active ? _T.purple : _T.textSec,
        fw: FontWeight.w600,
      ),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: active ? _T.purple : _T.textSec,
      backgroundColor: active ? _T.purple.withValues(alpha: 0.08) : _T.white,
      side: BorderSide(color: active ? _T.purple : _T.border),
      padding: EdgeInsets.symmetric(
        horizontal: small ? 12 : 16,
        vertical: small ? 10 : 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class _FilterBtn extends StatelessWidget {
  const _FilterBtn({required this.scope, this.small = false});

  final bool small;

  /// The shortlisted candidates this screen is showing. The sheet counts and
  /// filters against these, not against every applicant to the job.
  final List<ApplicantRecord> scope;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ApplicantsProvider>();
    final count = provider.activeFilterChips.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.filter_list_rounded,
            size: small ? 20 : 22,
            color: count > 0 ? _T.purple : _T.textSec,
          ),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: ApplicantFilterWidget(scope: scope),
            ),
          ),
          tooltip: 'Filter',
          padding: EdgeInsets.all(small ? 6 : 8),
          constraints: const BoxConstraints(),
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: _T.purple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: _T.label(fs: 9, c: Colors.white, fw: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MOBILE — CARD LIST
// ═════════════════════════════════════════════════════════════════════════════
class _MobileCardList extends StatelessWidget {
  final List<ApplicantRecord> applicants;
  final ApplicantsProvider provider;
  final String? jobId;
  final VoidCallback onToggleSelectAll;
  final ValueChanged<ApplicantRecord> onViewProfile;

  const _MobileCardList({
    required this.applicants,
    required this.provider,
    required this.jobId,
    required this.onToggleSelectAll,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (applicants.isEmpty) return _EmptyState(jobId: jobId);

    final allSelected = applicants.every((a) => provider.isSelected(a.userId));

    return Column(
      children: [
        // Select-all row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: _T.bg,
          child: Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Checkbox(
                  value: allSelected,
                  onChanged: (_) => onToggleSelectAll(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: _T.purple,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Select All (${applicants.length})',
                style: _T.label(fs: 12, fw: FontWeight.w600),
              ),
            ],
          ),
        ),
        // Cards
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
            itemCount: applicants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ApplicantCard(
              applicant: applicants[i],
              index: i,
              isSelected: provider.isSelected(applicants[i].userId),
              provider: provider,
              onViewProfile: onViewProfile,
            ),
          ),
        ),
      ],
    );
  }
}

/// The admin's note that came with a batch of scores.
class _AdminNoteBanner extends StatelessWidget {
  const _AdminNoteBanner({
    required this.note,
    required this.at,
    required this.scored,
    required this.horizontalPadding,
  });

  final String note;
  final DateTime? at;
  final int scored;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _T.purple.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _T.purple.withValues(alpha: 0.28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 17, color: _T.purple),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin sent $scored assessment '
                    '${scored == 1 ? 'score' : 'scores'}'
                    '${at == null ? '' : ' · ${DateFormat('d MMM, HH:mm').format(at!)}'}',
                    style: _T.label(
                      fs: 11,
                      c: _T.purple,
                      fw: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: _T.label(fs: 12.5, c: _T.textSec),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ApplicantCard extends StatelessWidget {
  final ApplicantRecord applicant;
  final int index;
  final bool isSelected;
  final ApplicantsProvider provider;
  final ValueChanged<ApplicantRecord> onViewProfile;

  const _ApplicantCard({
    required this.applicant,
    required this.index,
    required this.isSelected,
    required this.provider,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final aColor = _T.avatar(index);
    final scoreMap = applicant.profileSnapshot['match_score'];
    final hasScore = scoreMap is Map;
    final score = hasScore ? (scoreMap['overallScore'] as int? ?? 0) : 0;
    final sColor = _scoreColor(score);

    return GestureDetector(
      onLongPress: applicant.sentToAdmin
          ? null
          : () => provider.toggleSelection(applicant.userId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: isSelected ? _T.purple.withValues(alpha: 0.05) : _T.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSelected ? _T.purple : _T.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Top row: checkbox + avatar + name + action
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 11, 10, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Checkbox(
                      // Sending locks a candidate, but scores coming back
                      // unlocks them again: the recruiter now knows something
                      // they did not know when they chose.
                      value: provider.isSelectable(applicant)
                          ? isSelected
                          : true,
                      onChanged: provider.isSelectable(applicant)
                          ? (_) => provider.toggleSelection(applicant.userId)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: provider.isSelectable(applicant)
                          ? _T.purple
                          : Colors.grey,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: aColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        applicant.name.isNotEmpty
                            ? applicant.name.substring(0, 2).toUpperCase()
                            : 'NA',
                        style: _T.mono(fs: 13, c: aColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name + email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicant.name,
                          style: _T.head(fs: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _subtitle(applicant),
                          style: _T.label(fs: 10, c: _T.purple,
                              fw: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // View profile button
                  GestureDetector(
                    onTap: () => onViewProfile(applicant),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _T.bg,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _T.border),
                      ),
                      child: const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: _T.textSec,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: _T.border),

            // ── Bottom row: meta chips
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
              child: Row(
                children: [
                  Flexible(
                    child: _MetaChip(
                      icon: Icons.insights_outlined,
                      label: _experienceOf(applicant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Applied
                  _MetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('MMM d').format(applicant.appliedAt),
                  ),
                  const Spacer(),
                  // Standing first, then the AI score if there is one. The
                  // standing is what the recruiter acts on; the score is what
                  // they act with.
                  _StatusBadge(standing: _Standing.of(applicant, provider)),
                  if (hasScore) ...[
                    const SizedBox(width: 6),
                    _ScoreChip(score: score, color: sColor),
                  ],
                ],
              ),
            ),

            // Licences and aircraft — what a recruiter screens on.
            if (_credentials(applicant).isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in _credentials(applicant))
                      _CredPill(label: c),
                  ],
                ),
              ),

            // AI score bar (if available)
            if (hasScore)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: _T.border,
                          valueColor: AlwaysStoppedAnimation(sColor),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _scoreLabel(score),
                      style: _T.label(fs: 10, c: sColor, fw: FontWeight.w700),
                    ),
                  ],
                ),
              ),

            // The assessment. On a phone the table's columns collapse, so this
            // gets its own strip rather than a cell — a recruiter deciding on
            // the move needs the test result as much as the AI score.
            if (applicant.assessment.invited)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _T.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _T.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.quiz_outlined, size: 14, color: _T.textSec),
                      const SizedBox(width: 8),
                      Text('Assessment',
                          style: _T.label(fs: 11, fw: FontWeight.w600)),
                      const Spacer(),
                      Flexible(
                        child: _TestScoreCell(summary: applicant.assessment),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Books this one candidate's interview.
///
/// Shows the booked time once there is one, so the recruiter can see at a
/// glance which of the advanced candidates still need a slot without opening
/// the calendar.
class _InterviewAction extends StatelessWidget {
  const _InterviewAction({required this.applicant, required this.onTap});

  final ApplicantRecord applicant;
  final ValueChanged<ApplicantRecord> onTap;

  @override
  Widget build(BuildContext context) {
    final booked =
        context.watch<InterviewProvider>().forCandidate(applicant.userId);
    final tone = booked == null ? _T.purple : _T.success;

    return IconButton(
      icon: Icon(
        booked == null ? Icons.event_available_outlined : Icons.event_rounded,
        size: 17,
      ),
      onPressed: () => onTap(applicant),
      color: tone,
      tooltip: booked == null
          ? 'Arrange interview'
          : 'Interview ${DateFormat('d MMM, HH:mm').format(booked.scheduledAt)}'
              '${booked.hasLink ? '' : ' — awaiting link'}',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

/// A licence or aircraft type, rendered small enough that three fit a row.
class _CredPill extends StatelessWidget {
  const _CredPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _T.purple.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _T.purple.withValues(alpha: 0.18)),
        ),
        child: Text(
          label,
          style: _T.label(fs: 10, c: _T.purple, fw: FontWeight.w600),
        ),
      );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: _T.textSec),
      const SizedBox(width: 4),
      // Flexible because the headline metric can run long — "Total flight
      // hours 2680" has to ellipsize on a narrow card, not overflow it.
      Flexible(
        child: Text(
          label,
          style: _T.label(fs: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _ScoreChip extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreChip({required this.score, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Text(
      '$score%',
      style: _T.mono(fs: 11, c: color, fw: FontWeight.w800),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// DESKTOP — TABLE
// ═════════════════════════════════════════════════════════════════════════════
class _DesktopTable extends StatelessWidget {
  final List<ApplicantRecord> applicants;
  final ApplicantsProvider provider;
  final String? jobId;
  final VoidCallback onToggleSelectAll;
  final ValueChanged<ApplicantRecord> onViewProfile;
  final ValueChanged<ApplicantRecord> onArrange;

  const _DesktopTable({
    required this.applicants,
    required this.provider,
    required this.jobId,
    required this.onToggleSelectAll,
    required this.onViewProfile,
    required this.onArrange,
    required this.sort,
    required this.onSort,
  });

  /// The column in use, or null for the order the list arrived in.
  final ShortlistSort? sort;
  final ValueChanged<ShortlistSortColumn> onSort;

  @override
  Widget build(BuildContext context) {
    if (applicants.isEmpty) return _EmptyState(jobId: jobId);

    final allSelected = applicants.every((a) => provider.isSelected(a.userId));

    return Column(
      children: [
        // ── Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          decoration: const BoxDecoration(
            color: _T.bg,
            border: Border(bottom: BorderSide(color: _T.border)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: Checkbox(
                  value: allSelected,
                  onChanged: (_) => onToggleSelectAll(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: _T.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: _Hdr('CANDIDATE')),
              Expanded(flex: 3, child: _Hdr('EXPERIENCE')),
              Expanded(flex: 2, child: _Hdr('APPLIED ON')),
              Expanded(
                flex: 2,
                child: _Hdr(
                  'AI SCORE',
                  ascending: sort?.column == ShortlistSortColumn.aiScore
                      ? sort!.ascending
                      : null,
                  onTap: () => onSort(ShortlistSortColumn.aiScore),
                ),
              ),
              Expanded(
                flex: 2,
                child: _Hdr(
                  'TEST SCORE',
                  ascending: sort?.column == ShortlistSortColumn.testScore
                      ? sort!.ascending
                      : null,
                  onTap: () => onSort(ShortlistSortColumn.testScore),
                ),
              ),
              Expanded(flex: 2, child: _Hdr('STATUS')),
              const SizedBox(width: 76),
            ],
          ),
        ),
        // ── Rows
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: applicants.length,
            itemBuilder: (_, i) => _TableRow(
              applicant: applicants[i],
              index: i,
              isSelected: provider.isSelected(applicants[i].userId),
              provider: provider,
              onViewProfile: onViewProfile,
              onArrange: onArrange,
            ),
          ),
        ),
      ],
    );
  }
}

/// A column heading, optionally one the recruiter can order by.
///
/// A sortable heading always shows an arrow, faint when the column is not the
/// one in use. A control that only appears once you have already found it is a
/// control most people never find.
class _Hdr extends StatelessWidget {
  const _Hdr(this.text, {this.ascending, this.onTap});

  final String text;

  /// Direction when this is the column in use; null when it is not.
  final bool? ascending;

  /// Non-null makes the heading clickable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _T.label(
        fs: 11,
        fw: FontWeight.w700,
        c: ascending == null ? _T.textSec : _T.purple,
      ).copyWith(letterSpacing: 0.4),
    );

    if (onTap == null) return label;

    final asc = ascending;
    return Tooltip(
      message: switch (asc) {
        null => 'Sort by $text — highest first',
        false => 'Highest first. Click for lowest first.',
        true => 'Lowest first. Click to clear the sort.',
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 3, 4, 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: label),
              const SizedBox(width: 3),
              Icon(
                switch (asc) {
                  null => Icons.unfold_more_rounded,
                  false => Icons.arrow_downward_rounded,
                  true => Icons.arrow_upward_rounded,
                },
                size: 12,
                color: asc == null
                    ? _T.textTert
                    : _T.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final ApplicantRecord applicant;
  final int index;
  final bool isSelected;
  final ApplicantsProvider provider;
  final ValueChanged<ApplicantRecord> onViewProfile;
  final ValueChanged<ApplicantRecord> onArrange;

  const _TableRow({
    required this.applicant,
    required this.index,
    required this.isSelected,
    required this.provider,
    required this.onViewProfile,
    required this.onArrange,
  });

  @override
  Widget build(BuildContext context) {
    final aColor = _T.avatar(index);
    final scoreMap = applicant.profileSnapshot['match_score'];
    final hasScore = scoreMap is Map;
    final score = hasScore ? (scoreMap['overallScore'] as int? ?? 0) : 0;
    final sColor = _scoreColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? _T.purple.withValues(alpha: 0.04) : _T.white,
        border: const Border(bottom: BorderSide(color: _T.border)),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 38,
            child: Checkbox(
              value: provider.isSelectable(applicant) ? isSelected : true,
              onChanged: provider.isSelectable(applicant)
                  ? (_) => provider.toggleSelection(applicant.userId)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              activeColor:
                  provider.isSelectable(applicant) ? _T.purple : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),

          // Candidate
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: aColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      applicant.name.isNotEmpty
                          ? applicant.name.substring(0, 2).toUpperCase()
                          : 'NA',
                      style: _T.mono(fs: 13, c: aColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        style: _T.head(fs: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _subtitle(applicant),
                        style: _T.label(fs: 11, c: _T.purple,
                            fw: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Experience — the headline metric, plus licences and aircraft so
          // the row says what the candidate is qualified to fly or fix.
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _experienceOf(applicant),
                  style: _T.body(fs: 12, c: _T.textPri),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_credentials(applicant, max: 2).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _credentials(applicant, max: 2).join('  •  '),
                    style: _T.label(fs: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (applicant.professionalStatus.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    applicant.professionalStatus,
                    style: _T.label(fs: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Applied on
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM dd, yyyy').format(applicant.appliedAt),
              style: _T.body(fs: 12, c: _T.textSec),
            ),
          ),

          // AI Score
          Expanded(
            flex: 2,
            child: hasScore
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('$score%', style: _T.mono(fs: 13, c: sColor)),
                          const SizedBox(width: 7),
                          Text(
                            _scoreLabel(score),
                            style: _T.label(
                              fs: 11,
                              c: sColor,
                              fw: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: _T.border,
                          valueColor: AlwaysStoppedAnimation(sColor),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  )
                : Text('Not analyzed', style: _T.label(fs: 11, c: _T.textTert)),
          ),

          // Test score — the assessment result, kept beside the AI score so
          // the two are read together. They measure different things: one is
          // a machine's opinion of a CV, the other is what the candidate
          // actually answered.
          Expanded(
            flex: 2,
            child: _TestScoreCell(summary: applicant.assessment),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(standing: _Standing.of(applicant, provider)),
            ),
          ),

          // View, and — once they have been advanced — book their interview
          // without having to tick a box first. One candidate at a time is the
          // common case; the island handles the batch.
          SizedBox(
            width: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (provider.canArrangeInterview(applicant))
                  _InterviewAction(applicant: applicant, onTap: onArrange),
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  onPressed: () => onViewProfile(applicant),
                  color: _T.textSec,
                  tooltip: 'View Profile',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The assessment column.
///
/// Shows a number only once an admin has released the batch. Before that it
/// reports where the candidate has got to — invited, sitting it, finished and
/// waiting — because a partial score is not a score, and showing one would
/// invite a decision made on half the evidence.
class _TestScoreCell extends StatelessWidget {
  final AssessmentSummary summary;
  const _TestScoreCell({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (!summary.hasScore) {
      final (color, icon) = switch (summary.status) {
        '' => (_T.textTert, Icons.remove_circle_outline),
        'invited' => (_T.textSec, Icons.mail_outline_rounded),
        'accepted' || 'in_progress' => (_T.primary, Icons.pending_outlined),
        'submitted' => (_T.warning, Icons.lock_clock_rounded),
        'expired' => (_T.danger, Icons.hourglass_disabled_rounded),
        _ => (_T.textTert, Icons.help_outline),
      };
      return Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              summary.label,
              style: _T.label(fs: 11, c: color, fw: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final passed = summary.verdict == 'pass';
    final color = passed ? _T.success : _T.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Text('${summary.correct}/${summary.total}',
                style: _T.mono(fs: 13, c: _T.textPri)),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                passed ? 'PASS' : 'FAIL',
                style: _T.label(fs: 9, c: color, fw: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          [
            '${summary.percentage}%',
            // A rank turns a bare number into a decision: "14/20" says little,
            // "3rd of 17" says who to call first.
            if (summary.rank != null && summary.rankOf > 1)
              '${_ordinal(summary.rank!)} of ${summary.rankOf}',
            if (summary.tabSwitches > 0) '${summary.tabSwitches} tab switches',
          ].join('  ·  '),
          style: _T.label(fs: 10, c: _T.textTert),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  static String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    return switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' };
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SELECTION ISLAND
// ═════════════════════════════════════════════════════════════════════════════
class _SelectionIsland extends StatelessWidget {
  final Animation<double> animation;
  final ApplicantsProvider provider;
  final bool isMobile;
  final VoidCallback onSend;
  final VoidCallback onArrangeInterview;

  const _SelectionIsland({
    required this.animation,
    required this.provider,
    required this.isMobile,
    required this.onSend,
    required this.onArrangeInterview,
  });

  @override
  Widget build(BuildContext context) {
    final count = provider.selectedApplicantIds.length;
    if (count == 0) return const SizedBox.shrink();

    final interviewCount = provider.selectedForInterview.length;
    final sendable = count - interviewCount;

    return Center(
      child: ScaleTransition(
        scale: animation,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: _T.textPri,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: _T.textPri.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _T.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: _T.accent,
                    ),
                    const SizedBox(width: 5),
                    Text('$count', style: _T.mono(fs: 13, c: _T.white)),
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                Text('Selected', style: _T.label(fs: 13, c: Colors.white70)),
              ],
              const SizedBox(width: 6),
              IconButton(
                onPressed: provider.clearSelection,
                icon: const Icon(Icons.close_rounded, size: 16),
                color: Colors.white70,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Clear',
              ),
              const SizedBox(width: 10),
              // Once a candidate has been advanced past the assessment, the
              // useful action is no longer "send" — the admin already has
              // them — it is booking the interview.
              if (interviewCount > 0)
                ElevatedButton.icon(
                  onPressed: onArrangeInterview,
                  icon: const Icon(Icons.videocam_rounded, size: 15),
                  label: Text(
                    isMobile
                        ? 'Interview'
                        : 'Arrange interview'
                            '${interviewCount == count ? '' : ' ($interviewCount)'}',
                    style: _T.label(fs: 13, c: _T.white, fw: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.accent,
                    foregroundColor: _T.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              if (interviewCount > 0 && sendable > 0) const SizedBox(width: 8),
              if (sendable > 0)
                ElevatedButton.icon(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded, size: 15),
                  label: Text(
                    isMobile ? 'Send' : 'Send to Admin',
                    style: _T.label(fs: 13, c: _T.white, fw: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.primary,
                    foregroundColor: _T.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED MICRO WIDGETS
// ═════════════════════════════════════════════════════════════════════════════
/// Where a candidate stands with the recruiter, in one word.
///
/// Four states, one widget. They used to be three separate badges with three
/// different paddings and three different text sizes, which is why the column
/// looked assembled rather than designed — and why the widest of them
/// overflowed a column sized for the narrowest.
enum _Standing {
  /// On the shortlist, not sent anywhere yet.
  shortlisted('Shortlisted', Icons.check_circle_outline_rounded, _T.success),

  /// Sent to the admin and waiting on them. Nothing for the recruiter to do.
  withAdmin('With admin', Icons.lock_outline_rounded, _T.primary),

  /// Passed the assessment. The recruiter's move — book the interview.
  passed('Passed', Icons.how_to_reg_outlined, _T.success),

  /// Sat the assessment and came in under the pass mark.
  ///
  /// Nothing is possible from here. The test made this decision, not the
  /// recruiter, so no control on the row is live.
  didNotPass('Did not pass', Icons.block_rounded, _T.danger),

  /// Interview arranged. Already forward.
  advanced('Interview set', Icons.event_available_rounded, _T.purple),

  /// Considered in a batch that has since been narrowed, and not kept.
  notKept('Not kept', Icons.remove_circle_outline_rounded, _T.textTert);

  const _Standing(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  /// Reads a candidate's standing from what is actually known about them.
  ///
  /// Order matters: being advanced outranks having a result, which outranks
  /// having been sent. Each state is the latest thing that happened.
  static _Standing of(ApplicantRecord a, ApplicantsProvider p) {
    if (p.isAdvanced(a)) return _Standing.advanced;
    if (p.hasFailedAssessment(a)) return _Standing.didNotPass;
    if (p.canArrangeInterview(a)) return _Standing.passed;
    if (p.isSuperseded(a)) return _Standing.notKept;
    if (a.sentToAdmin) return _Standing.withAdmin;
    return _Standing.shortlisted;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.standing, this.compact = false});

  final _Standing standing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: switch (standing) {
        _Standing.shortlisted => 'On your shortlist. Select and send to the admin.',
        _Standing.withAdmin =>
          'With the admin. Locked until their assessment result comes back.',
        _Standing.passed =>
          'Passed the assessment. Arrange their interview from this row.',
        _Standing.didNotPass =>
          'Sat the assessment and came in under the pass mark. Nothing further '
              'can be done with them on this job.',
        _Standing.advanced =>
          'Interview arranged. The admin issues the joining link.',
        _Standing.notKept =>
          'You narrowed this batch and did not keep them.',
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: standing.color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: standing.color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(standing.icon, size: 11, color: standing.color),
            if (!compact) ...[
              const SizedBox(width: 5),
              // Flexible so a narrow column shortens the label instead of
              // painting the overflow stripes over the next cell.
              Flexible(
                child: Text(
                  standing.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _T.label(
                    fs: 10,
                    c: standing.color,
                    fw: FontWeight.w700,
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


class _EmptyState extends StatelessWidget {
  final String? jobId;
  const _EmptyState({this.jobId});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.person_search_sharp, size: 56, color: _T.textTert),
        const SizedBox(height: 14),
        Text(
          'No candidates in shortlist',
          style: _T.head(fs: 17, c: _T.textSec),
        ),
        const SizedBox(height: 6),
        Text(
          jobId != null
              ? 'No candidates shortlisted for this position yet'
              : 'Select a job to view shortlisted candidates',
          style: _T.label(fs: 12),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorPanel({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
        const SizedBox(height: 14),
        Text('Error: $error', style: _T.label(fs: 13, c: Colors.red.shade700)),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 17),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _T.primary,
            foregroundColor: _T.white,
          ),
        ),
      ],
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// SEND TO ADMIN DIALOG
// ═════════════════════════════════════════════════════════════════════════════
class _SendToAdminDialog extends StatefulWidget {
  final int selectedCount;
  final int round;
  final TextEditingController notesController;
  final Future<dynamic> Function() onSubmit;

  const _SendToAdminDialog({
    required this.selectedCount,
    required this.round,
    required this.notesController,
    required this.onSubmit,
  });

  @override
  State<_SendToAdminDialog> createState() => _SendToAdminDialogState();
}

class _SendToAdminDialogState extends State<_SendToAdminDialog> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _T.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(22),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _T.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.outbox_rounded,
                  color: _T.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                widget.round > 1
                    ? 'Confirm your picks after the assessment'
                    : 'Send to Admin',
                style: _T.head(fs: 17),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.round > 1
                ? 'Keeping ${widget.selectedCount} candidate(s) from this batch '
                    'for interview. Your original shortlist stays on the same '
                    'request exactly as you sent it — the people you did not '
                    'keep are dimmed, not removed, so the reason for the change '
                    'is still readable next to it.'
                : 'Submitting ${widget.selectedCount} candidate(s) to super admin '
                    'for final approval.',
            style: _T.body(fs: 13, c: _T.textSec),
          ),
          const SizedBox(height: 20),
          // Notes field
          TextField(
            controller: widget.notesController,
            maxLines: 3,
            style: _T.body(fs: 13),
            decoration: InputDecoration(
              labelText: 'Administrative Notes',
              labelStyle: _T.label(fs: 11, c: _T.primary, fw: FontWeight.w700),
              hintText: 'e.g. High priority — check English proficiency…',
              hintStyle: _T.label(fs: 12, c: _T.textTert),
              alignLabelWithHint: true,
              filled: true,
              fillColor: _T.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _T.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Discard', style: _T.label(fs: 13)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.primary,
                  foregroundColor: _T.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _T.white,
                        ),
                      )
                    : Text(
                        'Confirm & Submit',
                        style: _T.label(
                          fs: 13,
                          c: _T.white,
                          fw: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final result = await widget.onSubmit();
    if (mounted) Navigator.pop(context, result != null);
  }
}
