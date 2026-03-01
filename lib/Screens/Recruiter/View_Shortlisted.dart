import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../widgets/view_js_profile.dart';
import 'LIst_of_Applicants_provider.dart';
import 'filter.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
class _T {
  static const primary   = Color(0xFF6366F1);
  static const purple    = Color(0xFF8B5CF6);
  static const textPri   = Color(0xFF0F172A);
  static const textSec   = Color(0xFF64748B);
  static const textTert  = Color(0xFF94A3B8);
  static const bg        = Color(0xFFF8FAFC);
  static const white     = Color(0xFFFFFFFF);
  static const border    = Color(0xFFE2E8F0);
  static const success   = Color(0xFF10B981);
  static const accent    = Color(0xFFEC4899);

  static const _avatarColors = [
    Color(0xFF3B82F6), Color(0xFF8B5CF6),
    Color(0xFFEC4899), Color(0xFF06B6D4),
  ];
  static Color avatar(int i) => _avatarColors[i % _avatarColors.length];

  static TextStyle label({double fs = 11, Color? c, FontWeight fw = FontWeight.w500}) =>
      GoogleFonts.ibmPlexSans(fontSize: fs, fontWeight: fw, color: c ?? textSec);
  static TextStyle head({double fs = 14, Color? c}) =>
      GoogleFonts.ibmPlexSans(fontSize: fs, fontWeight: FontWeight.w700, color: c ?? textPri);
  static TextStyle body({double fs = 13, Color? c}) =>
      GoogleFonts.ibmPlexSans(fontSize: fs, color: c ?? textPri, height: 1.5);
  static TextStyle mono({double fs = 14, Color? c, FontWeight fw = FontWeight.w700}) =>
      GoogleFonts.ibmPlexMono(fontSize: fs, fontWeight: fw, color: c ?? textPri);
}

// ─── Layout InheritedWidget ────────────────────────────────────────────────
class _LD extends InheritedWidget {
  final bool isMobile;
  const _LD({required this.isMobile, required super.child});
  static bool mobile(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<_LD>()!.isMobile;
  @override
  bool updateShouldNotify(_LD old) => old.isMobile != isMobile;
}

// ─── Email masker (pure fn) ────────────────────────────────────────────────
String _maskEmail(String email) {
  final p = email.split('@');
  if (p.length != 2) return '****@****.com';
  final u = p[0];
  return '${u.length > 2 ? u.substring(0, 2) : '**'}****@${p[1]}';
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
    vsync: this, duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _islandAnim = CurvedAnimation(
    parent: _islandCtrl, curve: Curves.elasticOut,
  );

  late ApplicantsProvider _provider;
  bool _rankByScore = false;

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
    _rankByScore = false;
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
  void _onSearch() { if (mounted) setState(() {}); }

  void _onSelectionChanged() {
    if (!mounted) return;
    final has = _provider.selectedApplicantIds.isNotEmpty;
    if (has && !_islandCtrl.isCompleted)      _islandCtrl.forward();
    else if (!has && !_islandCtrl.isDismissed) _islandCtrl.reverse();
  }

  // ─── Data helpers ───────────────────────────────────────────────────────
  List<ApplicantRecord> _filtered(ApplicantsProvider p) {
    var list = p.getShortlistForJob(widget.jobId);
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((a) =>
      a.name.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q) ||
          (a.jobData?.title ?? '').toLowerCase().contains(q)).toList();
    }
    if (_rankByScore) {
      list = List.from(list)
        ..sort((a, b) => _score(b).compareTo(_score(a)));
    }
    return list;
  }

  int _score(ApplicantRecord a) {
    final d = a.profileSnapshot['match_score'];
    return (d is Map) ? (d['overallScore'] as int? ?? 0) : 0;
  }

  void _toggleSelectAll(ApplicantsProvider p) {
    final list = _filtered(p);
    final all  = list.every((a) => p.isSelected(a.userId));
    all ? p.clearSelection() : p.selectAll(list);
  }

  void _toggleRank(ApplicantsProvider p) {
    setState(() => _rankByScore = !_rankByScore);
    _showToast(
      _rankByScore ? 'Candidates ranked by AI score' : 'Default sorting restored',
      icon: Icons.check_circle_outline,
    );
  }

  // ─── Toast ──────────────────────────────────────────────────────────────
  void _showToast(String msg, {required IconData icon}) {
    final entry = OverlayEntry(builder: (_) => Positioned(
      top: 30, left: 20, right: 20,
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: _T.textPri,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(
                  color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(children: [
              Icon(icon, color: _T.success, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(msg, style: _T.label(fs: 13, c: _T.white))),
            ]),
          ),
        ),
      )),
    ));
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 3), entry.remove);
  }

  // ─── Send to Admin ──────────────────────────────────────────────────────
  Future<void> _sendToAdmin(ApplicantsProvider p) async {
    final notesCtrl  = TextEditingController();
    final messenger  = ScaffoldMessenger.of(context);

    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) => Transform.scale(
        scale: anim.value,
        child: Opacity(
          opacity: anim.value,
          child: _SendToAdminDialog(
            selectedCount: p.selectedApplicantIds.length,
            notesController: notesCtrl,
            onSubmit: () => p.sendSelectedCandidatesToAdmin(
              notes: notesCtrl.text.trim().isEmpty
                  ? 'No notes provided'
                  : notesCtrl.text.trim(),
            ),
          ),
        ),
      ),
    );

    notesCtrl.dispose();
    if (!mounted) return;

    if (ok == true) {
      messenger.showSnackBar(SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _T.textPri,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(children: [
            const Icon(Icons.check_circle_rounded, color: _T.success, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Submission Successful',
                    style: _T.head(fs: 13, c: _T.white)),
                Text('Pending admin review.',
                    style: _T.label(fs: 11, c: _T.textTert)),
              ],
            )),
            TextButton(
              onPressed: messenger.hideCurrentSnackBar,
              child: Text('OK', style: _T.label(
                  fs: 12, c: _T.primary, fw: FontWeight.w700)),
            ),
          ]),
        ),
      ));
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, bc) {
      final isMobile = bc.maxWidth < 768;
      return _LD(
        isMobile: isMobile,
        child: Scaffold(
          backgroundColor: _T.white,
          body: Consumer<ApplicantsProvider>(
            builder: (_, provider, __) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator(
                    color: _T.primary, strokeWidth: 2));
              }
              if (provider.error != null) {
                return _ErrorPanel(
                  error: provider.error!,
                  onRetry: () => provider.refresh(jobId: widget.jobId),
                );
              }
              final applicants = _filtered(provider);
              return Stack(children: [
                Column(children: [
                  // ── Controls bar
                  RepaintBoundary(
                    child: _ControlsBar(
                      searchCtrl: _searchCtrl,
                      rankByScore: _rankByScore,
                      onToggleRank: () => _toggleRank(provider),
                    ),
                  ),
                  // ── Content: card list on mobile, table on desktop
                  Expanded(
                    child: isMobile
                        ? _MobileCardList(
                      applicants: applicants,
                      provider: provider,
                      jobId: widget.jobId,
                      onToggleSelectAll: () => _toggleSelectAll(provider),
                      onViewProfile: _showProfile,
                    )
                        : _DesktopTable(
                      applicants: applicants,
                      provider: provider,
                      jobId: widget.jobId,
                      onToggleSelectAll: () => _toggleSelectAll(provider),
                      onViewProfile: _showProfile,
                    ),
                  ),
                ]),
                // ── Selection island
                Positioned(
                  top: 10, left: 8, right: 8,
                  child: _SelectionIsland(
                    animation: _islandAnim,
                    provider: provider,
                    isMobile: isMobile,
                    onSend: () => _sendToAdmin(provider),
                  ),
                ),
              ]);
            },
          ),
        ),
      );
    });
  }

  void _showProfile(ApplicantRecord a) {
    if (_LD.mobile(context)) {
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
  const _ControlsBar({
    required this.searchCtrl,
    required this.rankByScore,
    required this.onToggleRank,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _LD.mobile(context);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _T.border))),
      child: isMobile
          ? Column(children: [
        _SearchField(ctrl: searchCtrl),
        const SizedBox(height: 9),
        Row(children: [
          Expanded(child: _RankButton(
              active: rankByScore, onTap: onToggleRank, small: true)),
          const SizedBox(width: 8),
          _FilterBtn(small: true),
        ]),
      ])
          : Row(children: [
        Expanded(child: _SearchField(ctrl: searchCtrl)),
        const SizedBox(width: 10),
        _FilterBtn(),
        const SizedBox(width: 10),
        _RankButton(active: rankByScore, onTap: onToggleRank),
      ]),
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
      prefixIcon: const Icon(Icons.search_rounded,
          color: _T.textTert, size: 18),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: _T.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: _T.purple, width: 1.5)),
      filled: true, fillColor: _T.bg,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      isDense: true,
    ),
  );
}

class _RankButton extends StatelessWidget {
  final bool active, small;
  final VoidCallback onTap;
  const _RankButton({required this.active, required this.onTap,
    this.small = false});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(active ? Icons.filter_list : Icons.sort_rounded,
        size: small ? 16 : 17),
    label: Text(active ? 'Ranked' : 'Rank by Match Score',
        style: _T.label(
            fs: small ? 12 : 13,
            c: active ? _T.purple : _T.textSec,
            fw: FontWeight.w600)),
    style: OutlinedButton.styleFrom(
      foregroundColor: active ? _T.purple : _T.textSec,
      backgroundColor: active ? _T.purple.withOpacity(0.08) : _T.white,
      side: BorderSide(color: active ? _T.purple : _T.border),
      padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 16, vertical: small ? 10 : 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class _FilterBtn extends StatelessWidget {
  final bool small;
  const _FilterBtn({this.small = false});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(Icons.filter_list_rounded,
        size: small ? 20 : 22, color: _T.textSec),
    onPressed: () => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ApplicantFilterWidget(),
    ),
    tooltip: 'Filter',
    padding: EdgeInsets.all(small ? 6 : 8),
    constraints: const BoxConstraints(),
  );
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

    return Column(children: [
      // Select-all row
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: _T.bg,
        child: Row(children: [
          SizedBox(
            width: 36, height: 36,
            child: Checkbox(
              value: allSelected,
              onChanged: (_) => onToggleSelectAll(),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              activeColor: _T.purple,
            ),
          ),
          const SizedBox(width: 8),
          Text('Select All (${applicants.length})',
              style: _T.label(fs: 12, fw: FontWeight.w600)),
        ]),
      ),
      // Cards
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
          itemCount: applicants.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ApplicantCard(
            applicant: applicants[i],
            index: i,
            isSelected: provider.isSelected(applicants[i].userId),
            provider: provider,
            onViewProfile: onViewProfile,
          ),
        ),
      ),
    ]);
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicantRecord applicant;
  final int index;
  final bool isSelected;
  final ApplicantsProvider provider;
  final ValueChanged<ApplicantRecord> onViewProfile;

  const _ApplicantCard({
    required this.applicant, required this.index, required this.isSelected,
    required this.provider, required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final aColor   = _T.avatar(index);
    final scoreMap = applicant.profileSnapshot['match_score'];
    final hasScore = scoreMap is Map;
    final score    = hasScore ? (scoreMap['overallScore'] as int? ?? 0) : 0;
    final sColor   = _scoreColor(score);

    return GestureDetector(
      onLongPress: applicant.sentToAdmin
          ? null
          : () => provider.toggleSelection(applicant.userId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: isSelected ? _T.purple.withOpacity(0.05) : _T.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSelected ? _T.purple : _T.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: const [BoxShadow(
              color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(children: [
          // ── Top row: checkbox + avatar + name + action
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 11, 10, 8),
            child: Row(children: [
              SizedBox(
                width: 30, height: 30,
                child: Checkbox(
                  value: applicant.sentToAdmin ? true : isSelected,
                  onChanged: applicant.sentToAdmin
                      ? null
                      : (_) => provider.toggleSelection(applicant.userId),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  activeColor: applicant.sentToAdmin ? Colors.grey : _T.purple,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              // Avatar
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: aColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(
                  applicant.name.isNotEmpty
                      ? applicant.name.substring(0, 2).toUpperCase()
                      : 'NA',
                  style: _T.mono(fs: 13, c: aColor),
                )),
              ),
              const SizedBox(width: 10),
              // Name + email
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(applicant.name, style: _T.head(fs: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_maskEmail(applicant.email),
                      style: _T.label(fs: 10),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
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
                  child: const Icon(Icons.visibility_outlined,
                      size: 16, color: _T.textSec),
                ),
              ),
            ]),
          ),

          const Divider(height: 1, color: _T.border),

          // ── Bottom row: meta chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
            child: Row(children: [
              // Exp
              _MetaChip(
                icon: Icons.work_outline_rounded,
                label: '${applicant.experienceYears}y exp',
              ),
              const SizedBox(width: 8),
              // Applied
              _MetaChip(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('MMM d').format(applicant.appliedAt),
              ),
              const Spacer(),
              // Score or status
              if (hasScore)
                _ScoreChip(score: score, color: sColor)
              else if (applicant.sentToAdmin)
                _SentBadge()
              else
                _ShortlistBadge(),
            ]),
          ),

          // AI score bar (if available)
          if (hasScore)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
              child: Row(children: [
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
                Text(_scoreLabel(score),
                    style: _T.label(fs: 10, c: sColor, fw: FontWeight.w700)),
              ]),
            ),
        ]),
      ),
    );
  }
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
      Text(label, style: _T.label(fs: 11)),
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
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text('$score%',
        style: _T.mono(fs: 11, c: color, fw: FontWeight.w800)),
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

  const _DesktopTable({
    required this.applicants,
    required this.provider,
    required this.jobId,
    required this.onToggleSelectAll,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (applicants.isEmpty) return _EmptyState(jobId: jobId);

    final allSelected =
    applicants.every((a) => provider.isSelected(a.userId));

    return Column(children: [
      // ── Table header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: const BoxDecoration(
          color: _T.bg,
          border: Border(bottom: BorderSide(color: _T.border)),
        ),
        child: Row(children: [
          SizedBox(
            width: 38,
            child: Checkbox(
              value: allSelected,
              onChanged: (_) => onToggleSelectAll(),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              activeColor: _T.purple,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: _Hdr('CANDIDATE')),
          Expanded(flex: 3, child: _Hdr('EXPERIENCE')),
          Expanded(flex: 2, child: _Hdr('APPLIED ON')),
          Expanded(flex: 2, child: _Hdr('AI SCORE')),
          Expanded(flex: 1, child: _Hdr('STATUS')),
          const SizedBox(width: 64),
        ]),
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
          ),
        ),
      ),
    ]);
  }
}

class _Hdr extends StatelessWidget {
  final String text;
  const _Hdr(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: _T.label(fs: 11, fw: FontWeight.w700)
          .copyWith(letterSpacing: 0.4));
}

class _TableRow extends StatelessWidget {
  final ApplicantRecord applicant;
  final int index;
  final bool isSelected;
  final ApplicantsProvider provider;
  final ValueChanged<ApplicantRecord> onViewProfile;

  const _TableRow({
    required this.applicant, required this.index, required this.isSelected,
    required this.provider, required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final aColor   = _T.avatar(index);
    final scoreMap = applicant.profileSnapshot['match_score'];
    final hasScore = scoreMap is Map;
    final score    = hasScore ? (scoreMap['overallScore'] as int? ?? 0) : 0;
    final sColor   = _scoreColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? _T.purple.withOpacity(0.04) : _T.white,
        border: const Border(bottom: BorderSide(color: _T.border)),
      ),
      child: Row(children: [
        // Checkbox
        SizedBox(
          width: 38,
          child: Checkbox(
            value: applicant.sentToAdmin ? true : isSelected,
            onChanged: applicant.sentToAdmin
                ? null
                : (_) => provider.toggleSelection(applicant.userId),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
            activeColor: applicant.sentToAdmin ? Colors.grey : _T.purple,
          ),
        ),
        const SizedBox(width: 8),

        // Candidate
        Expanded(flex: 3, child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: aColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(
              applicant.name.isNotEmpty
                  ? applicant.name.substring(0, 2).toUpperCase()
                  : 'NA',
              style: _T.mono(fs: 13, c: aColor),
            )),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(applicant.name, style: _T.head(fs: 13),
                  overflow: TextOverflow.ellipsis),
              Text(_maskEmail(applicant.email),
                  style: _T.label(fs: 11),
                  overflow: TextOverflow.ellipsis),
            ],
          )),
        ])),

        // Experience
        Expanded(flex: 3, child: Text(
          '${applicant.experienceYears}y  •  ${applicant.professionalStatus}',
          style: _T.body(fs: 12, c: _T.textSec),
        )),

        // Applied on
        Expanded(flex: 2, child: Text(
          DateFormat('MMM dd, yyyy').format(applicant.appliedAt),
          style: _T.body(fs: 12, c: _T.textSec),
        )),

        // AI Score
        Expanded(flex: 2, child: hasScore
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('$score%', style: _T.mono(fs: 13, c: sColor)),
            const SizedBox(width: 7),
            Text(_scoreLabel(score),
                style: _T.label(fs: 11, c: sColor, fw: FontWeight.w600)),
          ]),
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
        ])
            : Text('Not analyzed',
            style: _T.label(fs: 11, c: _T.textTert))),

        // Status
        Expanded(flex: 1, child: applicant.sentToAdmin
            ? _SentBadge()
            : _ShortlistBadge()),

        // View
        SizedBox(
          width: 56,
          child: IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 17),
            onPressed: () => onViewProfile(applicant),
            color: _T.textSec,
            tooltip: 'View Profile',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ]),
    );
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

  const _SelectionIsland({
    required this.animation, required this.provider,
    required this.isMobile, required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final count = provider.selectedApplicantIds.length;
    if (count == 0) return const SizedBox.shrink();

    return Center(
      child: ScaleTransition(
        scale: animation,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 18, vertical: 10),
          decoration: BoxDecoration(
            color: _T.textPri,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [BoxShadow(
                color: _T.textPri.withOpacity(0.35),
                blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _T.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Icon(Icons.check_circle_rounded, size: 14, color: _T.accent),
                const SizedBox(width: 5),
                Text('$count',
                    style: _T.mono(fs: 13, c: _T.white)),
              ]),
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
            ElevatedButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded, size: 15),
              label: Text(isMobile ? 'Send' : 'Send to Admin',
                  style: _T.label(
                      fs: 13, c: _T.white, fw: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.primary,
                foregroundColor: _T.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED MICRO WIDGETS
// ═════════════════════════════════════════════════════════════════════════════
class _SentBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: Colors.blue.withOpacity(0.3)),
    ),
    child: Text('SENT',
        style: _T.label(
            fs: 9, c: Colors.blue.shade700, fw: FontWeight.w800)),
  );
}

class _ShortlistBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: _T.success.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text('Shortlist',
        style: _T.label(fs: 10, c: _T.success, fw: FontWeight.w600)),
  );
}

class _EmptyState extends StatelessWidget {
  final String? jobId;
  const _EmptyState({this.jobId});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.person_search_sharp, size: 56, color: _T.textTert),
      const SizedBox(height: 14),
      Text('No candidates in shortlist', style: _T.head(fs: 17, c: _T.textSec)),
      const SizedBox(height: 6),
      Text(
        jobId != null
            ? 'No candidates shortlisted for this position yet'
            : 'Select a job to view shortlisted candidates',
        style: _T.label(fs: 12),
        textAlign: TextAlign.center,
      ),
    ]),
  );
}

class _ErrorPanel extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorPanel({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
      const SizedBox(height: 14),
      Text('Error: $error',
          style: _T.label(fs: 13, c: Colors.red.shade700)),
      const SizedBox(height: 14),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 17),
        label: const Text('Retry'),
        style: ElevatedButton.styleFrom(
            backgroundColor: _T.primary, foregroundColor: _T.white),
      ),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// SEND TO ADMIN DIALOG
// ═════════════════════════════════════════════════════════════════════════════
class _SendToAdminDialog extends StatefulWidget {
  final int selectedCount;
  final TextEditingController notesController;
  final Future<dynamic> Function() onSubmit;

  const _SendToAdminDialog({
    required this.selectedCount,
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
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _T.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.outbox_rounded, color: _T.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Text('Send to Admin', style: _T.head(fs: 17)),
        ]),
        const SizedBox(height: 18),
        Text(
          'Submitting ${widget.selectedCount} candidate(s) to super admin for final approval.',
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
            filled: true, fillColor: _T.bg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _T.primary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
                  horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _submitting
                ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _T.white))
                : Text('Confirm & Submit',
                style: _T.label(
                    fs: 13, c: _T.white, fw: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final result = await widget.onSubmit();
    if (mounted) Navigator.pop(context, result != null);
  }
}