import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'LIst_of_Applicants_provider.dart';
import 'R_Top_Bar.dart';

// ─── Design tokens (single source of truth) ───────────────────────────────────
class _T {
  static const primary = Color(0xFF4F46E5);
  static const blue = Color(0xFF1E40AF);
  static const textPri = Color(0xFF0D1117);
  static const textSec = Color(0xFF57606A);
  static const textTert = Color(0xFF8B949E);
  static const bg = Color(0xFFF6F8FA);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFD0D7DE);
  static const success = Color(0xFF1A7F37);
  static const warning = Color(0xFFBF8700);
  static const red = Color(0xFFCF222E);

  static TextStyle label({
    double fs = 11,
    Color? c,
    FontWeight fw = FontWeight.w500,
  }) => GoogleFonts.poppins
(
    fontSize: fs,
    fontWeight: fw,
    color: c ?? textSec,
  );

  static TextStyle head({double fs = 14, Color? c}) => GoogleFonts.poppins
(
    fontSize: fs,
    fontWeight: FontWeight.w700,
    color: c ?? textPri,
  );

  static TextStyle body({double fs = 13, Color? c}) =>
      GoogleFonts.poppins
(fontSize: fs, color: c ?? textPri, height: 1.55);
}

// ─── Layout breakpoint InheritedWidget (computed ONCE at root) ────────────────
class _LD extends InheritedWidget {
  final bool isMobile;
  const _LD({required this.isMobile, required super.child});

  static bool mobile(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<_LD>()!.isMobile;

  @override
  bool updateShouldNotify(_LD old) => old.isMobile != isMobile;
}

// ─── Safe date parser (pure function — no alloc per build) ────────────────────
DateTime _parseDate(dynamic raw) {
  if (raw == null) return DateTime.now();
  if (raw is DateTime) return raw;
  try {
    return (raw as dynamic).toDate() as DateTime;
  } catch (_) {
    return DateTime.now();
  }
}

// ─── Email masker (pure function) ─────────────────────────────────────────────
String _maskEmail(String email) {
  if (email.isEmpty) return '';
  final parts = email.split('@');
  if (parts.length != 2) return '****';
  final u = parts[0];
  return '${u.length > 2 ? u.substring(0, 2) : '**'}****@${parts[1]}';
}

// ─── Status helpers (pure functions) ──────────────────────────────────────────
Color _requestStatusColor(String s) {
  switch (s) {
    case 'approved':
    case 'accepted':
      return _T.success;
    case 'pending':
      return _T.warning;
    case 'rejected':
      return _T.red;
    default:
      return _T.textSec;
  }
}

Color _candidateStatusColor(String s) {
  switch (s) {
    case 'shortlist':
      return const Color(0xFF4F46E5);
    case 'screening':
      return const Color(0xFF2563EB);
    case 'interview':
      return const Color(0xFF7C3AED);
    case 'technical':
      return const Color(0xFF0891B2);
    case 'offer':
      return const Color(0xFFB45309);
    case 'handover':
    case 'hired':
      return _T.success;
    case 'rejected':
      return _T.red;
    default:
      return _T.textSec;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ROOT SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class RequestBoxScreen extends StatefulWidget {
  const RequestBoxScreen({super.key});
  @override
  State<RequestBoxScreen> createState() => _RequestBoxScreenState();
}

class _RequestBoxScreenState extends State<RequestBoxScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Cached provider — safe to store after didChangeDependencies
  late ApplicantsProvider _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<ApplicantsProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _provider.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    // _LD wraps everything so children never read MediaQuery directly
    return _LD(
      isMobile: isMobile,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: isMobile
            ? Drawer(child: RecruiterSidebar(activeIndex: 4, isDrawer: true))
            : null,
        body: Row(
          children: [
            if (!isMobile) const RecruiterSidebar(activeIndex: 4),
            Expanded(
              child: Column(
                children: [
                  // ── Top bar
                  RepaintBoundary(
                    child: isMobile
                        ? _MobileTopBar(
                            onMenu: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                          )
                        : const _DesktopHeader(),
                  ),
                  // ── Content
                  Expanded(
                    child: Consumer<ApplicantsProvider>(
                      builder: (ctx, provider, _) {
                        final requests = provider.recruiterRequests;
                        if (requests.isEmpty) return const _EmptyState();

                        return RepaintBoundary(
                          child: ListView.builder(
                            padding: EdgeInsets.all(isMobile ? 12 : 24),
                            itemCount: requests.length,
                            itemBuilder: (_, i) => _RequestCard(
                              request: requests[i],
                              onStatusChanged: _onCandidateStatusChanged,
                            ),
                          ),
                        );
                      },
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

  // ─── Callback (stable reference — not recreated inside build) ─────────────
  Future<void> _onCandidateStatusChanged({
    required String requestId,
    required String candidateUid,
    required String status,
    required String currentStatus,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    if (currentStatus.toLowerCase() != 'handover') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Candidates can only be Hired or Rejected after Admin Handover',
          ),
          backgroundColor: Color(0xFFB45309),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Let PopupMenuRoute fully dismiss before async work
    await Future.delayed(const Duration(milliseconds: 150));

    final ok = await _provider.updateCandidateStatus(
      requestId: requestId,
      candidateUid: candidateUid,
      status: status,
    );
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Candidate marked as $status' : 'Failed to update status',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TOP BARS
// ═════════════════════════════════════════════════════════════════════════════
class _MobileTopBar extends StatelessWidget {
  final VoidCallback onMenu;
  const _MobileTopBar({required this.onMenu});

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: const BoxDecoration(color: _T.white),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu_rounded, size: 22),
          onPressed: onMenu,
          color: _T.textSec,
        ),
        const SizedBox(width: 4),
        const _HeaderIcon(),
        const SizedBox(width: 10),
        Text('Request Box', style: _T.head(fs: 15)),
      ],
    ),
  );
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    color: _T.white,
    child: Row(
      children: [
        const _HeaderIcon(size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Applicants Request Box', style: _T.head(fs: 17)),
              Text(
                'Manage & Onboard Applicants against Your Posted Jobs',
                style: _T.label(c: _T.textSec),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HeaderIcon extends StatelessWidget {
  final double size;
  const _HeaderIcon({this.size = 18});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: _T.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.all_inbox_outlined, size: size, color: _T.blue),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// REQUEST CARD  (stateless — stable identity across ListView rebuilds)
// ═════════════════════════════════════════════════════════════════════════════
class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final Future<void> Function({
    required String requestId,
    required String candidateUid,
    required String status,
    required String currentStatus,
  })
  onStatusChanged;

  const _RequestCard({required this.request, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final isMobile = _LD.mobile(context);
    final createdAt = _parseDate(request['created_at']);
    final status = ((request['status'] as String?) ?? 'pending').toLowerCase();
    final candidates = (request['candidates'] as List?) ?? const [];
    final notes = (request['notes'] as String?) ?? 'No notes provided';
    final requestId = (request['request_id'] as String?) ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _T.primary.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: _T.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Candidate Submission Request',
                        style: _T.head(fs: isMobile ? 14 : 15),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
                        style: _T.label(fs: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusBadge(status: status, colorFn: _requestStatusColor),
              ],
            ),
          ),

          const Divider(height: 1, color: _T.border),

          // ── Notes + candidates
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message / Notes',
                  style: _T
                      .label(fs: 10, fw: FontWeight.w700)
                      .copyWith(letterSpacing: 0.4),
                ),
                const SizedBox(height: 5),
                Text(notes, style: _T.body(fs: isMobile ? 13 : 14)),
                const SizedBox(height: 18),
                Text(
                  'Candidates Sent (${candidates.length})',
                  style: _T
                      .label(fs: 10, fw: FontWeight.w700)
                      .copyWith(letterSpacing: 0.4),
                ),
                const SizedBox(height: 10),
                _CandidatesWrap(
                  candidates: candidates,
                  requestId: requestId,
                  onStatusChanged: onStatusChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CANDIDATES WRAP
// ═════════════════════════════════════════════════════════════════════════════
class _CandidatesWrap extends StatelessWidget {
  final List candidates;
  final String requestId;
  final Future<void> Function({
    required String requestId,
    required String candidateUid,
    required String status,
    required String currentStatus,
  })
  onStatusChanged;

  const _CandidatesWrap({
    required this.candidates,
    required this.requestId,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in candidates)
          _CandidateMiniCard(
            candidate: c,
            requestId: requestId,
            onStatusChanged: onStatusChanged,
          ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CANDIDATE MINI CARD
// ═════════════════════════════════════════════════════════════════════════════
class _CandidateMiniCard extends StatelessWidget {
  final dynamic candidate;
  final String requestId;
  final Future<void> Function({
    required String requestId,
    required String candidateUid,
    required String status,
    required String currentStatus,
  })
  onStatusChanged;

  const _CandidateMiniCard({
    required this.candidate,
    required this.requestId,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _LD.mobile(context);
    final name = (candidate['name'] as String?) ?? 'Candidate';
    final email = (candidate['email'] as String?) ?? '';
    final jobTitle = (candidate['job_title'] as String?) ?? 'N/A';
    final uid = (candidate['uid'] as String?) ?? '';
    final status = ((candidate['status'] as String?) ?? 'pending')
        .toLowerCase();
    final isFinal = status == 'hired' || status == 'rejected';
    final statusC = _candidateStatusColor(status);

    // Width adapts: full-width on mobile, fixed on wider
    return LayoutBuilder(
      builder: (_, bc) {
        final w = bc.maxWidth < 600 ? bc.maxWidth : 310.0;
        return SizedBox(
          width: w,
          child: Container(
            padding: EdgeInsets.all(isMobile ? 11 : 13),
            decoration: BoxDecoration(
              color: _T.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _T.border),
            ),
            child: Column(
              children: [
                // ── Avatar + name + action
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: _T.primary.withOpacity(0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _T.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: _T.head(fs: isMobile ? 12 : 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _maskEmail(email),
                            style: _T.label(fs: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Final status icon or action menu
                    if (isFinal)
                      Icon(
                        status == 'hired'
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: statusC,
                        size: 18,
                      )
                    else
                      _CandidateActionMenu(
                        requestId: requestId,
                        candidateUid: uid,
                        currentStatus: status,
                        onStatusSelected: onStatusChanged,
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Job title + status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        jobTitle,
                        style: _T.label(
                          fs: 11,
                          c: _T.primary,
                          fw: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(
                      status: status,
                      colorFn: _candidateStatusColor,
                      small: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// POPUP MENU  (stable widget — no closure captures per build loop)
// ═════════════════════════════════════════════════════════════════════════════
class _CandidateActionMenu extends StatelessWidget {
  final String requestId, candidateUid, currentStatus;
  final Future<void> Function({
    required String requestId,
    required String candidateUid,
    required String status,
    required String currentStatus,
  })
  onStatusSelected;

  const _CandidateActionMenu({
    required this.requestId,
    required this.candidateUid,
    required this.currentStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded, size: 18, color: _T.textSec),
      splashRadius: 18,
      onSelected: (val) => onStatusSelected(
        requestId: requestId,
        candidateUid: candidateUid,
        status: val,
        currentStatus: currentStatus,
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'hired',
          child: _MenuRow(
            icon: Icons.check_circle_rounded,
            color: _T.success,
            label: 'Mark as Hired',
          ),
        ),
        PopupMenuItem(
          value: 'rejected',
          child: _MenuRow(
            icon: Icons.cancel_rounded,
            color: _T.red,
            label: 'Mark as Rejected',
          ),
        ),
      ],
    );
  }
}

/// Const-constructable menu row — avoids Row allocation per `itemBuilder` call
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _MenuRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 17),
      const SizedBox(width: 9),
      Text(label, style: _T.body(fs: 13)),
    ],
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED MICRO WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

/// Reusable status badge — works for both request-level and candidate-level
class _StatusBadge extends StatelessWidget {
  final String status;
  final Color Function(String) colorFn;
  final bool small;
  const _StatusBadge({
    required this.status,
    required this.colorFn,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = colorFn(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 11,
        vertical: small ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(small ? 4 : 20),
        border: Border.all(color: c.withOpacity(small ? 0.25 : 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: _T.label(fs: small ? 9 : 10, c: c, fw: FontWeight.w800),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inbox_outlined, size: 72, color: _T.border),
        const SizedBox(height: 18),
        Text('No requests yet', style: _T.head(fs: 17, c: _T.textSec)),
        const SizedBox(height: 6),
        Text(
          'Candidate submission requests will appear here',
          style: _T.label(fs: 13, c: _T.textTert),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
