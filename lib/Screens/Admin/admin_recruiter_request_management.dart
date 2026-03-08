import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_recruiter_request_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Breakpoints
// ─────────────────────────────────────────────────────────────────────────────
class _BP {
  static const double mobile  = 600;
  static const double tablet  = 900;
  static const double desktop = 1200;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Palette
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFF4F6FB);
  static const surface    = Color(0xFFFFFFFF);
  static const border     = Color(0xFFE8EDF5);
  static const divider    = Color(0xFFF0F3F9);
  static const primary    = Color(0xFF4F46E5);
  static const primaryLt  = Color(0xFFEEF2FF);
  static const success    = Color(0xFF059669);
  static const successLt  = Color(0xFFECFDF5);
  static const warning    = Color(0xFFD97706);
  static const warningLt  = Color(0xFFFFFBEB);
  static const danger     = Color(0xFFDC2626);
  static const dangerLt   = Color(0xFFFEF2F2);
  static const txt1       = Color(0xFF0F172A);
  static const txt2       = Color(0xFF475569);
  static const txt3       = Color(0xFF94A3B8);
  static const txt4       = Color(0xFFCBD5E1);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Root Screen
// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboardScreen2 extends StatefulWidget {
  const AdminDashboardScreen2({super.key});

  @override
  State<AdminDashboardScreen2> createState() => _AdminDashboardScreen2State();
}

class _AdminDashboardScreen2State extends State<AdminDashboardScreen2> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().fetchAllRequests(realtime: true);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: _C.bg,
    body: AdminDashboardBody(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Dashboard Body
// ─────────────────────────────────────────────────────────────────────────────
class AdminDashboardBody extends StatefulWidget {
  const AdminDashboardBody({super.key});

  @override
  State<AdminDashboardBody> createState() => _AdminDashboardBodyState();
}

class _AdminDashboardBodyState extends State<AdminDashboardBody> {
  bool _loadingDetails = false;
  final _listCtrl   = ScrollController();
  final _detailCtrl = ScrollController();

  @override
  void dispose() {
    _listCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _norm(dynamic m) => AdminProvider.normalizeMapStatic(m);

  /// FIX: safely extract string URLs from a list that may contain
  /// either String elements or Map<String,dynamic> elements.
  List<String> _safeDocList(dynamic field) {
    if (field == null) return [];
    if (field is! List) return [];
    final result = <String>[];
    for (final e in field) {
      if (e == null) continue;
      if (e is String && e.isNotEmpty) {
        result.add(e);
      } else if (e is Map) {
        // Try common URL keys in order of likelihood
        final url = e['url']?.toString().trim() ??
            e['uri']?.toString().trim() ??
            e['link']?.toString().trim() ??
            e['path']?.toString().trim() ??
            e['downloadUrl']?.toString().trim() ??
            e['fileUrl']?.toString().trim() ??
            '';
        // Fallback: first value that looks like a URL
        if (url.isNotEmpty) {
          result.add(url);
        } else {
          final fallback = e.values
              .whereType<String>()
              .firstWhere((v) => v.startsWith('http'), orElse: () => '');
          if (fallback.isNotEmpty) result.add(fallback);
        }
      } else {
        final s = e.toString().trim();
        if (s.isNotEmpty) result.add(s);
      }
    }
    return result;
  }

  List<String> _safeStringList(dynamic field) {
    if (field == null) return [];
    if (field is List) {
      return field
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  Color _statusColor(dynamic status) {
    final s = status?.toString().toLowerCase() ?? '';
    if (s == 'active' || s == 'approved') return _C.success;
    if (s == 'pending')                    return _C.warning;
    if (s == 'rejected' || s == 'closed') return _C.danger;
    return _C.primary;
  }

  Future<void> _openDetails(BuildContext ctx, String requestId) async {
    final prov = Provider.of<AdminProvider>(ctx, listen: false);
    if (prov.selectedRequestId == requestId) return;
    setState(() => _loadingDetails = true);
    await prov.selectRequest(requestId);
    if (mounted) setState(() => _loadingDetails = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AdminProvider>(context);
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final isDesktop = w >= _BP.tablet;

        return Scaffold(
          backgroundColor: _C.bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: isDesktop
                      ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: w < _BP.desktop ? 340 : 400,
                        child: _buildList(ctx, prov, isDesktop: true),
                      ),
                      const VerticalDivider(width: 1, color: _C.border),
                      Expanded(child: _buildDetails(ctx, prov)),
                    ],
                  )
                      : _buildList(ctx, prov, isDesktop: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Request List ──────────────────────────────────────────────────────────

  Widget _buildList(BuildContext ctx, AdminProvider prov,
      {required bool isDesktop}) {
    return Container(
      color: _C.bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(children: [
              Text('REQUESTS',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _C.txt3,
                      letterSpacing: 1.5)),
              const Spacer(),
              _LiveBadge(),
            ]),
          ),
          Expanded(
            child: prov.requests.isEmpty
                ? _EmptyList(loading: prov.loading)
                : Scrollbar(
              controller: _listCtrl,
              thumbVisibility: isDesktop,
              child: ListView.separated(
                controller: _listCtrl,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                itemCount: prov.requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final r     = _norm(prov.requests[i]);
                  final id    = r['id']?.toString() ?? '';
                  final email = r['recruiter_email']?.toString() ?? '';
                  final total = r['total_candidates'] ?? 0;
                  final stat  = r['status']?.toString() ?? 'unknown';
                  final ca    = r['created_at'];
                  final date  = ca is Timestamp
                      ? DateFormat('MMM d, yyyy').format(ca.toDate())
                      : (ca?.toString() ?? '-');

                  return _RequestTile(
                    id: id,
                    email: email,
                    total: total,
                    status: stat,
                    date: date,
                    selected: id == prov.selectedRequestId,
                    onTap: () => isDesktop
                        ? _openDetails(ctx, id)
                        : _showModal(ctx, prov, id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Details Panel (desktop) ───────────────────────────────────────────────

  Widget _buildDetails(BuildContext ctx, AdminProvider prov) {
    if (_loadingDetails) {
      return const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary));
    }
    if (prov.selectedRequestId == null) {
      return const _Placeholder();
    }
    if (prov.selectedRequestDetails == null) {
      return Center(
          child: Text('No details loaded',
              style: GoogleFonts.inter(color: _C.txt3)));
    }
    return Container(
      color: _C.bg,
      child: Scrollbar(
        controller: _detailCtrl,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _detailCtrl,
          padding: const EdgeInsets.all(28),
          child: _buildDetailContent(ctx, prov, prov.selectedRequestDetails!),
        ),
      ),
    );
  }

  // ── Detail Content ────────────────────────────────────────────────────────

  Widget _buildDetailContent(BuildContext ctx, AdminProvider prov,
      Map<String, dynamic> details) {
    final reqDoc    = _norm(details['request_doc']);
    final recruiter = _norm(details['recruiter']);
    final rawCands  =
        (details['candidates'] as List<dynamic>?)?.cast<dynamic>() ?? [];

    final reqData   = _norm(reqDoc['data']);
    final reqId     = reqDoc['id']?.toString() ?? '-';
    final status    = reqData['status']?.toString() ?? 'pending';
    final notes     = reqData['notes']?.toString() ?? '';
    final ca        = reqData['created_at'];
    final dateStr   = ca is Timestamp
        ? DateFormat('MMM d, yyyy · h:mm a').format(ca.toDate())
        : (ca?.toString() ?? '-');

    final rData    = _norm(recruiter['data']);
    final rName    = rData['name']?.toString() ?? recruiter['id']?.toString() ?? '-';
    final rEmail   = rData['email']?.toString() ?? '-';
    final rCompany = rData['company']?.toString() ?? '';

    // Dedup candidates
    final seen = <String, Map<String, dynamic>>{};
    for (final c in rawCands) {
      final cd = _norm(c);
      String uid = '';
      for (final k in [
        'uid','user_id','userId','id','jobSeekerId',
        'job_seeker_id','seekerUid','seeker_uid',
        'candidate_uid','candidateUid','user_uid',
      ]) {
        final v = cd[k]?.toString().trim() ?? '';
        if (v.isNotEmpty && v.toLowerCase() != 'null') { uid = v; break; }
      }
      if (uid.isEmpty) uid = cd['email']?.toString().trim() ?? '';
      if (uid.isEmpty) uid = '__c_${seen.length}';
      seen.putIfAbsent(uid.toLowerCase(), () => cd);
    }
    final cands = seen.values.toList();

    final rawStatuses = _norm(reqData['candidate_statuses']);
    final statusMap = <String, String>{};
    rawStatuses.forEach((k, v) {
      if (k.toString().isNotEmpty) statusMap[k.toString().toLowerCase()] = v?.toString() ?? '';
    });

    return LayoutBuilder(builder: (ctx, constraints) {
      final isNarrow = constraints.maxWidth < 520;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top bar ──
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Request #$reqId',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _C.txt1)),
                const SizedBox(height: 4),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.schedule_rounded, size: 13, color: _C.txt3),
                  const SizedBox(width: 5),
                  Text(dateStr,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: _C.txt3)),
                ]),
              ]),
              _StatusDropdown(
                  current: status,
                  onChanged: (ns) async {
                    final ok = await prov.updateRequestStatus(
                        requestId: reqId,
                        newStatus: ns,
                        performedBy: 'admin_dashboard');
                    if (!mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(ok ? 'Status → $ns' : 'Update failed'),
                        backgroundColor: ok ? _C.success : _C.danger,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))));
                  }),
            ],
          ),

          const SizedBox(height: 24),

          // ── Recruiter card ──
          _RecruiterCard(
              name: rName,
              email: rEmail,
              company: rCompany,
              notes: notes),

          const SizedBox(height: 28),

          // ── Candidates header ──
          Row(children: [
            Text('CANDIDATES',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _C.txt3,
                    letterSpacing: 1.5)),
            const SizedBox(width: 10),
            _CountBadge(count: cands.length),
          ]),
          const SizedBox(height: 16),

          if (cands.isEmpty)
            _EmptyCandidates()
          else
            _CandidateGrid(
              candidates: cands,
              statusMap: statusMap,
              isNarrow: isNarrow,
              reqId: reqId,
              prov: prov,
              norm: _norm,
              safeDocList: _safeDocList,
              showCV: (c) => _showCV(ctx, c),
              mountedCheck: () => mounted,
            ),

          const SizedBox(height: 48),
        ],
      );
    });
  }

  // ── Mobile Modal ─────────────────────────────────────────────────────────

  void _showModal(BuildContext ctx, AdminProvider prov, String requestId) {
    // Capture future BEFORE opening sheet — prevents FutureBuilder reset bug
    final future = prov.fetchRequestDetails(requestId: requestId);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FutureBuilder<Map<String, dynamic>?>(
        future: future,
        builder: (ctx2, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _ModalShell(
                height: 220,
                child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _C.primary)));
          }
          if (snap.hasError || snap.data == null) {
            return _ModalShell(
                height: 180,
                child: Center(
                    child: Text(
                        snap.hasError
                            ? 'Error: ${snap.error}'
                            : 'Failed to load',
                        style: GoogleFonts.inter(color: _C.txt3),
                        textAlign: TextAlign.center)));
          }
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.97,
            builder: (_, sc) => Container(
              decoration: const BoxDecoration(
                  color: _C.bg,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20))),
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                child: CustomScrollView(
                  controller: sc,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                                color: _C.border,
                                borderRadius: BorderRadius.circular(2))),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: _buildDetailContent(ctx2, prov, snap.data!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── CV Dialog ────────────────────────────────────────────────────────────

  void _showCV(BuildContext ctx, Map<String, dynamic> candidate) {
    final raw     = _norm(candidate['user_data'] ?? candidate);
    final persPro = _norm(raw['personalProfile'] ?? raw);
    final profPro = _norm(raw['professionalProfile'] ?? raw);

    String gVal(String flat, List<String> path, String fb) {
      if (raw.containsKey(flat) && raw[flat] != null) return raw[flat].toString();
      dynamic cur = raw;
      for (final p in path) {
        if (cur is Map && cur.containsKey(p)) cur = cur[p]; else return fb;
      }
      return cur?.toString() ?? fb;
    }

    final name     = gVal('name', ['personalProfile','name'],
        candidate['name']?.toString() ?? 'Unknown');
    final email    = gVal('email', ['personalProfile','email'],
        candidate['email']?.toString() ?? '');
    final phone    = gVal('phone', ['personalProfile','phone'],
        candidate['phone']?.toString() ?? '');
    final nation   = gVal('nationality', ['personalProfile','nationality'], '-');
    final dob      = gVal('dob', ['personalProfile','dob'], '-');
    final secEmail = gVal('secondary_email', ['personalProfile','secondary_email'], '');
    final summary  = gVal('summary', ['personalProfile','summary'], '');
    final goals    = gVal('objectives', ['personalProfile','objectives'], '');

    final eduList     = (raw['educationalProfile']     ?? raw['educational_profile'] ?? []) as List;
    final expList     = (raw['professionalExperience'] ?? raw['professional_experience'] ?? []) as List;
    final certList    = (raw['certifications'] ?? []) as List;
    final skills      = _safeStringList(raw['skills'] ?? persPro['skills']);
    final socialLinks = _safeStringList(raw['social_links'] ?? raw['socialLinks'] ?? persPro['socialLinks']);
    // ── BUG FIX: use _safeDocList instead of .cast<String>() ──────────────
    final expDocs     = _safeDocList(raw['experienceDocuments'] ?? raw['experience_documents']);
    final pubs        = _safeStringList(raw['publications']);
    final awards      = _safeStringList(raw['awards']);

    showDialog(
      context: ctx,
      builder: (_) => _CVDialog(
        name: name, email: email, phone: phone,
        nationality: nation, dob: dob, secondaryEmail: secEmail,
        summary: summary, objectives: goals,
        skills: skills, socialLinks: socialLinks,
        expDocs: expDocs, publications: pubs, awards: awards,
        professionalProfile: profPro,
        experienceList: expList.map((e) => _norm(e)).toList(),
        educationList: eduList.map((e) => _norm(e)).toList(),
        certifications: certList.map((e) => _norm(e)).toList(),
        avatarUrl: persPro['profilePicUrl']?.toString() ?? '',
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  COMPONENTS
// ═════════════════════════════════════════════════════════════════════════════

// ── Header ────────────────────────────────────────────────────────────────────
// class _Header extends StatelessWidget {
//   final bool isDesktop;
//   const _Header({required this.isDesktop});
//
//   @override
//   Widget build(BuildContext ctx) {
//     return Container(
//       height: 64,
//       color: _C.surface,
//       padding: EdgeInsets.symmetric(
//           horizontal: isDesktop ? 28 : 16),
//       child: Row(children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//               color: _C.primaryLt,
//               borderRadius: BorderRadius.circular(8)),
//           child: const Icon(Icons.admin_panel_settings_rounded,
//               color: _C.primary, size: 20),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Request Management',
//                     style: GoogleFonts.inter(
//                         fontSize: isDesktop ? 16 : 14,
//                         fontWeight: FontWeight.w700,
//                         color: _C.txt1)),
//                 Text('Real-time recruiter monitoring',
//                     style: GoogleFonts.inter(
//                         fontSize: 11,
//                         color: _C.txt3)),
//               ]),
//         ),
//       ]),
//     );
//   }
// }

// ── Live Badge ────────────────────────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: _C.successLt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.success.withOpacity(.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
              color: _C.success, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text('LIVE',
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _C.success)),
    ]),
  );
}

// ── Count Badge ───────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext ctx) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
        color: _C.primaryLt,
        borderRadius: BorderRadius.circular(12)),
    child: Text('$count',
        style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _C.primary)),
  );
}

// ── Empty List ────────────────────────────────────────────────────────────────
class _EmptyList extends StatelessWidget {
  final bool loading;
  const _EmptyList({required this.loading});

  @override
  Widget build(BuildContext ctx) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: _C.primary));
    }
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: _C.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _C.border)),
          child: const Icon(Icons.inbox_outlined, size: 32, color: _C.txt4),
        ),
        const SizedBox(height: 16),
        Text('No Requests',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600, color: _C.txt2)),
        const SizedBox(height: 4),
        Text('New items appear here automatically',
            style: GoogleFonts.inter(
                fontSize: 12, color: _C.txt3)),
      ]),
    );
  }
}

// ── Placeholder ───────────────────────────────────────────────────────────────
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext ctx) {
    return Container(
      color: _C.bg,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: _C.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _C.border)),
            child: const Icon(Icons.touch_app_outlined,
                size: 28, color: _C.txt4),
          ),
          const SizedBox(height: 20),
          Text('Select a request',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _C.txt2)),
          const SizedBox(height: 4),
          Text('View details and manage candidates',
              style: GoogleFonts.inter(fontSize: 13, color: _C.txt3)),
        ]),
      ),
    );
  }
}

// ── Modal Shell ───────────────────────────────────────────────────────────────
class _ModalShell extends StatelessWidget {
  final Widget child;
  final double height;
  const _ModalShell({required this.child, required this.height});

  @override
  Widget build(BuildContext ctx) => Container(
    height: height,
    decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20))),
    child: child,
  );
}

// ── Empty Candidates ─────────────────────────────────────────────────────────
class _EmptyCandidates extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border)),
    child: Center(
      child: Column(children: [
        const Icon(Icons.people_outline,
            size: 32, color: _C.txt4),
        const SizedBox(height: 12),
        Text('No candidates attached',
            style: GoogleFonts.inter(
                color: _C.txt3, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

// ── Candidate Grid ────────────────────────────────────────────────────────────
class _CandidateGrid extends StatelessWidget {
  final List<Map<String, dynamic>> candidates;
  final Map<String, String> statusMap;
  final bool isNarrow;
  final String reqId;
  final AdminProvider prov;
  final Map<String, dynamic> Function(dynamic) norm;
  final List<String> Function(dynamic) safeDocList;
  final void Function(Map<String, dynamic>) showCV;
  final bool Function() mountedCheck;

  const _CandidateGrid({
    required this.candidates,
    required this.statusMap,
    required this.isNarrow,
    required this.reqId,
    required this.prov,
    required this.norm,
    required this.safeDocList,
    required this.showCV,
    required this.mountedCheck,
  });

  @override
  Widget build(BuildContext ctx) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isNarrow ? double.infinity : 440,
        mainAxisExtent: 188,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: candidates.length,
      itemBuilder: (ctx2, i) {
        final c      = candidates[i];
        final cUid   = c['uid']?.toString() ?? '';
        final canon  = cUid.toLowerCase();
        final cName  = c['name']?.toString() ?? cUid;
        final cEmail = c['email']?.toString() ?? '';
        final cStat  = statusMap[canon] ?? 'unknown';

        final rd = norm(c['user_data'] ?? c);
        String pick(String k1, String k2) {
          if (rd.containsKey(k1) && rd[k1] != null) return rd[k1].toString();
          if (rd.containsKey(k2) && rd[k2] is Map) {
            return (rd[k2] as Map)[k1]?.toString() ?? '';
          }
          return '';
        }
        final cPhone = pick('phone', 'personalProfile');
        final cTitle = pick('title', 'professionalProfile');

        return _CandidateCard(
          name: cName, email: cEmail, phone: cPhone,
          title: cTitle, status: cStat,
          onTap: () => showCV(c),
          onMenuAction: (action) async {
            if (action == 'open_cv') {
              // BUG FIX: use safeDocList instead of .cast<String>()
              final docs = safeDocList(rd['experienceDocuments']);
              final url  = docs.isNotEmpty ? docs.first : '';
              ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(
                  content: Text(
                      url.isNotEmpty ? 'CV: $url' : 'No CV on file'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))));
              return;
            }
            await Future.delayed(const Duration(milliseconds: 100));
            final ok = await prov.updateCandidateStatus(
                requestId: reqId,
                candidateUid: cUid,
                status: action,
                performedBy: 'admin_dashboard');
            if (!mountedCheck()) return;
            ScaffoldMessenger.of(ctx2).showSnackBar(SnackBar(
                content: Text(ok ? 'Status → $action' : 'Update failed'),
                backgroundColor: ok ? _C.success : _C.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))));
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REQUEST TILE
// ─────────────────────────────────────────────────────────────────────────────
class _RequestTile extends StatelessWidget {
  final String id, email, status, date;
  final int total;
  final bool selected;
  final VoidCallback onTap;

  const _RequestTile({
    required this.id, required this.email,
    required this.total, required this.status,
    required this.date, required this.selected,
    required this.onTap,
  });

  Color _color() {
    final s = status.toLowerCase();
    if (s == 'active' || s == 'approved') return _C.success;
    if (s == 'pending')  return _C.warning;
    if (s == 'rejected' || s == 'closed') return _C.danger;
    return _C.primary;
  }

  @override
  Widget build(BuildContext ctx) {
    final c = _color();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? _C.primaryLt : _C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? _C.primary : _C.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('REQ #$id',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? _C.primary : _C.txt1)),
              Text(date,
                  style: GoogleFonts.inter(fontSize: 10, color: _C.txt3)),
            ]),
            const SizedBox(height: 6),
            Text(email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 13, color: _C.txt2, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: c.withOpacity(.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(status.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700, color: c)),
              ),
              const Spacer(),
              Icon(Icons.people_outline,
                  size: 13, color: selected ? _C.primary : _C.txt3),
              const SizedBox(width: 4),
              Text('$total',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? _C.primary : _C.txt2)),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RECRUITER CARD
// ─────────────────────────────────────────────────────────────────────────────
class _RecruiterCard extends StatelessWidget {
  final String name, email, company, notes;
  const _RecruiterCard({
    required this.name, required this.email,
    required this.company, required this.notes,
  });

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('RECRUITER',
          style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _C.txt3,
              letterSpacing: 1.4)),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Avatar(name: name, size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            SelectableText(name,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _C.txt1)),
            const SizedBox(height: 3),
            SelectableText(email,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _C.primary,
                    fontWeight: FontWeight.w500)),
            if (company.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.business_outlined,
                    size: 13, color: _C.txt3),
                const SizedBox(width: 5),
                Flexible(
                    child: Text(company,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: _C.txt2))),
              ]),
            ],
          ]),
        ),
      ]),
      if (notes.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Divider(height: 1, color: _C.divider),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.notes_rounded, size: 15, color: _C.txt3),
          const SizedBox(width: 8),
          Expanded(
              child: Text(notes,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _C.txt2,
                      height: 1.6,
                      fontStyle: FontStyle.italic))),
        ]),
      ],
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  AVATAR
// ─────────────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;
  const _Avatar({required this.name, required this.size, this.imageUrl});

  @override
  Widget build(BuildContext ctx) {
    final url = imageUrl ?? '';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: url.isEmpty
              ? const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)])
              : null,
          image: url.isNotEmpty
              ? DecorationImage(
              image: NetworkImage(url), fit: BoxFit.cover)
              : null),
      child: url.isEmpty
          ? Center(
          child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: size * .38,
                  fontWeight: FontWeight.w700)))
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STATUS DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────
class _StatusDropdown extends StatelessWidget {
  final String current;
  final void Function(String) onChanged;
  const _StatusDropdown({required this.current, required this.onChanged});

  Color _c(String s) {
    final st = s.toLowerCase();
    if (st == 'active')   return _C.success;
    if (st == 'pending')  return _C.warning;
    if (st == 'rejected' || st == 'closed') return _C.danger;
    return _C.primary;
  }

  @override
  Widget build(BuildContext ctx) {
    final col = _c(current);
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      itemBuilder: (_) =>
          ['Pending', 'Active', 'Rejected', 'Closed'].map((s) =>
              PopupMenuItem(
                value: s.toLowerCase(),
                height: 40,
                child: Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: _c(s), shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(s, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                ]),
              )).toList(),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: col.withOpacity(.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: col.withOpacity(.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8,
              decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(current.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: col)),
          const SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: col),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CANDIDATE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CandidateCard extends StatelessWidget {
  final String name, email, phone, title, status;
  final void Function(String) onMenuAction;
  final VoidCallback onTap;

  const _CandidateCard({
    super.key,
    required this.name, required this.email, required this.phone,
    required this.title, required this.status,
    required this.onMenuAction, required this.onTap,
  });

  Color _color() {
    final s = status.toLowerCase();
    if (s.contains('shortlist'))  return _C.primary;
    if (s.contains('screening'))  return const Color(0xFF3B82F6);
    if (s.contains('interview'))  return const Color(0xFF8B5CF6);
    if (s.contains('hired') || s.contains('handover')) return _C.success;
    if (s.contains('rejected'))   return _C.danger;
    return _C.txt3;
  }

  @override
  Widget build(BuildContext ctx) {
    const stages = ['Shortlist','Screening','Interview','Technical','Offer','Hired'];
    final disp = status.toLowerCase() == 'shortlisted' ? 'shortlist' : status.toLowerCase();
    final idx  = stages.map((e) => e.toLowerCase()).toList().indexOf(disp);
    final col  = _color();

    return Container(
      decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: col.withOpacity(.08),
            child: Column(children: [
              // Status header
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                    color: _C.bg,
                    border: Border(
                        bottom: BorderSide(color: _C.divider))),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: col.withOpacity(.1),
                        borderRadius: BorderRadius.circular(5),
                        border:
                        Border.all(color: col.withOpacity(.2))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 5, height: 5,
                          decoration: BoxDecoration(
                              color: col, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(status.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: col,
                              letterSpacing: .5)),
                    ]),
                  ),
                ]),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _CandAvatar(name: name, color: col),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: _C.txt1)),
                                        if (title.isNotEmpty)
                                          Text(title, maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: col,
                                                  fontWeight: FontWeight.w600)),
                                      ])),
                                  _CandAction(
                                      stages: stages,
                                      idx: idx,
                                      color: col,
                                      onMenuAction: onMenuAction),
                                ]),
                            const SizedBox(height: 5),
                            _IconRow(
                                icon: Icons.email_outlined,
                                text: email),
                            if (phone.isNotEmpty)
                              _IconRow(
                                  icon: Icons.phone_android_outlined,
                                  text: phone),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  _Pipeline(idx: idx, total: stages.length, color: col),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CandAvatar extends StatelessWidget {
  final String name;
  final Color color;
  const _CandAvatar({required this.name, required this.color});

  @override
  Widget build(BuildContext ctx) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(.7), color]),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(.25),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ]),
    child: Center(
        child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'C',
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16))),
  );
}

class _CandAction extends StatelessWidget {
  final List<String> stages;
  final int idx;
  final Color color;
  final void Function(String) onMenuAction;
  const _CandAction({
    required this.stages, required this.idx,
    required this.color, required this.onMenuAction,
  });

  @override
  Widget build(BuildContext ctx) {


    return GestureDetector(
      onTap: () => onMenuAction(stages[idx + 1].toLowerCase()),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: color.withOpacity(.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('NEXT',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(width: 3),
          Icon(Icons.arrow_forward_rounded, size: 12, color: color),
        ]),
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: _C.txt3),
      const SizedBox(width: 5),
      Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _C.txt2,
                  fontWeight: FontWeight.w500))),
    ]),
  );
}

class _Pipeline extends StatelessWidget {
  final int idx, total;
  final Color color;
  const _Pipeline({required this.idx, required this.total, required this.color});

  @override
  Widget build(BuildContext ctx) => SizedBox(
    height: 4,
    child: Row(
      children: List.generate(total, (i) {
        final active = i <= idx;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 3),
            decoration: BoxDecoration(
                color: active ? color : _C.border,
                borderRadius: BorderRadius.circular(2)),
          ),
        );
      }),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  CV DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _CVDialog extends StatelessWidget {
  final String name, email, phone, nationality, dob;
  final String secondaryEmail, summary, objectives, avatarUrl;
  final List<String> skills, socialLinks, expDocs, publications, awards;
  final Map<String, dynamic> professionalProfile;
  final List<Map<String, dynamic>> experienceList, educationList, certifications;

  const _CVDialog({
    required this.name, required this.email, required this.phone,
    required this.nationality, required this.dob,
    required this.secondaryEmail, required this.summary,
    required this.objectives, required this.avatarUrl,
    required this.skills, required this.socialLinks,
    required this.expDocs, required this.publications,
    required this.awards, required this.professionalProfile,
    required this.experienceList, required this.educationList,
    required this.certifications,
  });

  @override
  Widget build(BuildContext ctx) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: 860,
            maxHeight: MediaQuery.of(ctx).size.height * .92),
        child: Column(children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Avatar(name: name, size: 72, imageUrl: avatarUrl),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SelectableText(name.toUpperCase(),
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .4)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 18, runSpacing: 8, children: [
                    if (email.isNotEmpty) _HdrItem(Icons.email_outlined, email),
                    if (phone.isNotEmpty)
                      _HdrItem(Icons.phone_android_outlined, phone),
                  ]),
                ]),
              ),
              IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70)),
            ]),
          ),
          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                _CVSection('PERSONAL', Icons.person_outline, _C.primary, [
                  _CVRow('Nationality', nationality),
                  _CVRow('Date of Birth', dob),
                  if (secondaryEmail.isNotEmpty)
                    _CVRow('Alt Email', secondaryEmail),
                  if (summary.isNotEmpty)
                    _CVRow('Summary', summary, multiline: true),
                  if (objectives.isNotEmpty)
                    _CVRow('Objectives', objectives, multiline: true),
                ]),
                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _CVSection('SKILLS', Icons.auto_awesome_outlined,
                      _C.success, [
                        Wrap(spacing: 8, runSpacing: 8,
                            children: skills
                                .map((s) => _Badge(s, _C.success))
                                .toList()),
                      ]),
                ],
                if (socialLinks.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _CVSection('LINKS', Icons.link_rounded,
                      const Color(0xFF06B6D4), [
                        Wrap(spacing: 10, runSpacing: 8,
                            children: socialLinks
                                .map((l) => _LinkChip(l, const Color(0xFF06B6D4)))
                                .toList()),
                      ]),
                ],
                if (professionalProfile.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _CVSection('PROFESSIONAL', Icons.work_history_outlined,
                      const Color(0xFF8B5CF6), [
                        if ((professionalProfile['status']?.toString() ?? '').isNotEmpty)
                          _CVRow('Status', professionalProfile['status'].toString()),
                        if ((professionalProfile['summary']?.toString() ?? '').isNotEmpty)
                          _CVRow('Summary',
                              professionalProfile['summary'].toString(),
                              multiline: true),
                      ]),
                ],
                if (experienceList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _CVSection('EXPERIENCE', Icons.business_center_outlined,
                      const Color(0xFF3B82F6),
                      experienceList.map(_ExpCard.new).toList()),
                ],
                if (educationList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _CVSection('EDUCATION', Icons.school_outlined,
                      _C.warning,
                      educationList.map(_EduCard.new).toList()),
                ],
                if (certifications.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _CVSection('CERTIFICATIONS', Icons.verified_outlined,
                      const Color(0xFFEC4899),
                      certifications
                          .map((c) => _CertCard(
                        title: c['name']?.toString() ??
                            c['certificationName']?.toString() ??
                            'Certification',
                        subtitle: c['organization']?.toString() ??
                            c['issuingAuthority']?.toString(),
                      ))
                          .toList()),
                ],
                if (expDocs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _CVSection('DOCUMENTS', Icons.attach_file_rounded,
                      const Color(0xFF059669), [
                        Wrap(spacing: 10, runSpacing: 8,
                            children: expDocs
                                .map((d) => _LinkChip(d, const Color(0xFF059669),
                                isDoc: true))
                                .toList()),
                      ]),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _HdrItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HdrItem(this.icon, this.text);

  @override
  Widget build(BuildContext ctx) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white60, size: 13),
        const SizedBox(width: 6),
        Flexible(
            child: SelectableText(text,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 13))),
      ]);
}

class _CVSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  const _CVSection(this.title, this.icon, this.color, this.children);

  @override
  Widget build(BuildContext ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Text(title,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _C.txt1,
              letterSpacing: 1.4)),
      const SizedBox(width: 14),
      const Expanded(child: Divider(height: 1, color: _C.border)),
    ]),
    const SizedBox(height: 14),
    Padding(
        padding: const EdgeInsets.only(left: 28),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children)),
  ]);
}

class _CVRow extends StatelessWidget {
  final String label, value;
  final bool multiline;
  const _CVRow(this.label, this.value, {this.multiline = false});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: _C.txt3,
              letterSpacing: 1)),
      const SizedBox(height: 3),
      SelectableText(value,
          style: GoogleFonts.inter(
              fontSize: 13,
              color: _C.txt2,
              height: 1.5)),
    ]),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext ctx) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(.2))),
    child: Text(text,
        style: GoogleFonts.inter(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600)),
  );
}

class _LinkChip extends StatelessWidget {
  final String url;
  final Color color;
  final bool isDoc;
  const _LinkChip(this.url, this.color, {this.isDoc = false});

  @override
  Widget build(BuildContext ctx) => InkWell(
    onTap: () {},
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isDoc ? Icons.description_outlined : Icons.link_rounded,
            size: 13, color: color),
        const SizedBox(width: 6),
        Flexible(
            child: Text(
                url.length > 32 ? '${url.substring(0, 29)}…' : url,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: color,
                    decoration: TextDecoration.underline),
                overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );
}

class _ExpCard extends StatelessWidget {
  final Map<String, dynamic> exp;
  const _ExpCard(this.exp);

  @override
  Widget build(BuildContext ctx) {
    final role = exp['role']?.toString() ??
        exp['jobTitle']?.toString() ??
        exp['position']?.toString() ?? 'Role';
    final org = exp['organization']?.toString() ??
        exp['companyName']?.toString() ??
        exp['company']?.toString() ?? '';
    final dur = exp['duration']?.toString() ??
        '${exp['startDate'] ?? ''} – ${exp['endDate'] ?? 'Present'}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(role,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _C.txt1)),
        if (org.isNotEmpty)
          Text(org,
              style: GoogleFonts.inter(
                  color: const Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        const SizedBox(height: 3),
        Text(dur,
            style: GoogleFonts.inter(
                fontSize: 11, color: _C.txt3)),
      ]),
    );
  }
}

class _EduCard extends StatelessWidget {
  final Map<String, dynamic> edu;
  const _EduCard(this.edu);

  @override
  Widget build(BuildContext ctx) {
    final deg  = edu['degree']?.toString() ??
        edu['majorSubjects']?.toString() ?? 'Degree';
    final inst = edu['institution']?.toString() ??
        edu['institutionName']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _C.warningLt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.warning.withOpacity(.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(inst,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _C.txt1)),
        Text(deg,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: _C.warning,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _CertCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _CertCard({required this.title, this.subtitle});

  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: const Color(0xFFFDF4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFEC4899).withOpacity(.2))),
    child: Row(children: [
      const Icon(Icons.verified_rounded,
          color: Color(0xFFEC4899), size: 15),
      const SizedBox(width: 10),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _C.txt1)),
            if (subtitle != null)
              Text(subtitle!,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: _C.txt2)),
          ])),
    ]),
  );
}