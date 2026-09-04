import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:job_portal/Constant/brand_snackbar.dart';

import 'admin_recruiter_request_provider.dart';
import '../../core/onboarding/models/candidate_profile.dart';
import '../../core/onboarding/role_profile_snapshot.dart';
import '../../core/widgets/role_profile_view.dart';
import '../../core/interviews/interview.dart';
import '../../core/interviews/interview_provider.dart';
import '../../core/rbac/hiring_pipeline.dart';
import '../../core/profile/service_years.dart';
import 'assessment/assessment_models.dart';
import 'assessment/request_assessment_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Breakpoints
// ─────────────────────────────────────────────────────────────────────────────
class _BP {
  static const double tablet = 900;
  static const double desktop = 1200;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Maha HR Services — Navy + Teal Brand Palette
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  // Backgrounds
  static const bg = Color(0xFFFFFFFF);
  static const bgLight = Color(0xFFF4F9FB); // bgSoft
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCE7EF);
  static const divider = Color(0xFFF4F9FB);

  // Primary - Navy (was indigo)
  static const primary = Color(0xFF14507F); // navy
  static const primaryLight = Color(0xFFE8F1F8); // navy tint
  static const primaryLt = Color(0xFFE8F1F8); // navy tint

  // Brand accents
  static const navy = Color(0xFF14507F);
  static const deepNavy = Color(0xFF0A2E4F);
  static const hero = Color(0xFF061C31);
  static const blue = Color(0xFF2178B5);
  static const teal = Color(0xFF2EC4B6);
  static const tealBright = Color(0xFF43E0D2);
  static const tealDeep = Color(0xFF15A99C);
  static const coral = Color(0xFFFF7A59);
  static const amber = Color(0xFFFFB020);
  static const tealTint = Color(0xFFE4F6F4);
  static const navyTint = Color(0xFFE8F1F8);

  // Semantic colors (status semantics preserved)
  static const success = Color(0xFF10B981); // approved / active
  static const successLight = Color(0xFFE7F7F0);
  static const successLt = Color(0xFFE7F7F0);
  static const warning = Color(0xFFF59E0B); // pending → amber
  static const warningLight = Color(0xFFFEF4E0);
  static const warningLt = Color(0xFFFEF4E0);
  static const danger = Color(0xFFEF4444); // rejected / closed
  static const dangerLight = Color(0xFFFEECEC);

  // Text hierarchy
  static const txt1 = Color(0xFF0B2239); // ink
  static const txt2 = Color(0xFF3E5C76); // slate
  static const txt3 = Color(0xFF5E7A8E); // muted
  static const txt4 = Color(0xFF8AA5B5); // faint

  // Accent colors (teal)
  static const accent = Color(0xFF2EC4B6);
  static const accentLight = Color(0xFFE4F6F4);
  static const info = Color(0xFF2178B5);
  static const infoLight = Color(0xFFE8F1F8);

  // Brand gradients
  static const gradPrimary = LinearGradient(
    colors: [teal, navy],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradHero = LinearGradient(
    colors: [hero, deepNavy],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  URL helpers
// ─────────────────────────────────────────────────────────────────────────────
class _U {
  static IconData icon(String url) {
    if (url.contains('linkedin')) return Icons.people_alt_outlined;
    if (url.contains('github')) return Icons.code_rounded;
    if (url.contains('drive.google')) return Icons.folder_outlined;
    if (url.contains('dropbox')) return Icons.cloud_outlined;
    if (url.contains('twitter') || url.contains('x.com')) {
      return Icons.tag_rounded;
    }
    return Icons.link_rounded;
  }

  static String hostLabel(String url) {
    if (url.isEmpty) return 'Link';
    if (url.contains('linkedin')) return 'LinkedIn';
    if (url.contains('github')) return 'GitHub';
    if (url.contains('drive.google')) return 'Google Drive';
    if (url.contains('dropbox')) return 'Dropbox';
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      final host = uri.host.replaceFirst('www.', '');
      return host.isNotEmpty ? host : url;
    } catch (_) {
      return url.length > 28 ? '${url.substring(0, 25)}…' : url;
    }
  }
}

/// Reads a numeric field that may arrive as a num, a numeric string, or absent.
///
/// Returns null rather than 0 for anything unreadable: "not recorded" and
/// "zero hours" are different facts about a pilot, and a screen that shows the
/// second when it means the first is lying about the candidate.
num? _numOrNull(dynamic v) {
  if (v is num) return v;
  final t = v?.toString().trim() ?? '';
  return t.isEmpty ? null : num.tryParse(t);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Root Screen
// ─────────────────────────────────────────────────────────────────────────────
class Admin_Recruiter_Request_screen extends StatefulWidget {
  const Admin_Recruiter_Request_screen({super.key});

  @override
  State<Admin_Recruiter_Request_screen> createState() =>
      _Admin_Recruiter_Request_screenState();
}

class _Admin_Recruiter_Request_screenState
    extends State<Admin_Recruiter_Request_screen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminProvider>().fetchAllRequests(realtime: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _C.bg,
    body: SafeArea(top: false, child: const _DashboardBody()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Dashboard Body — single widget, no nested Scaffold
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardBody extends StatefulWidget {
  const _DashboardBody();
  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  bool _loadingDetails = false;
  final _listCtrl = ScrollController();
  final _detailCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';

  /// Candidates ticked for a bulk action. Held on the screen, not the provider,
  /// because it is a gesture in progress rather than anything about the batch.
  final Set<String> _picked = {};

  @override
  void dispose() {
    _listCtrl.dispose();
    _detailCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data helpers ──────────────────────────────────────────────────────────

  Map<String, dynamic> _n(dynamic m) => AdminProvider.normalizeMapStatic(m);

  String _s(dynamic v, [String fb = '']) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? fb : s;
  }

  List<String> _sl(dynamic f) {
    if (f == null) return [];
    if (f is List) {
      return f
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'active' || s == 'approved') return _C.success;
    if (s == 'pending') return _C.warning;
    if (s == 'rejected' || s == 'closed') return _C.danger;
    return _C.primary;
  }

  List<Map<String, dynamic>> _filteredRequests(AdminProvider prov) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return prov.requests.map(_n).where((r) {
      final status = _s(r['status'], 'pending').toLowerCase().trim();
      final haystack = [
        r['id'],
        r['recruiter_email'],
        r['recruiter_id'],
        r['recruiterEmail'],
        r['status'],
        r['total_candidates'],
      ].map((e) => e?.toString().toLowerCase() ?? '').join(' ');
      final matchesSearch = q.isEmpty || haystack.contains(q);
      final matchesStatus = _statusFilter == 'all' || status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  int _countByStatus(AdminProvider prov, String status) {
    if (status == 'all') return prov.requests.length;
    return prov.requests.map(_n).where((r) {
      return _s(r['status'], 'pending').toLowerCase().trim() == status;
    }).length;
  }

  /// Extracts plain URL strings from any list.
  List<String> _urlList(dynamic field) {
    if (field == null) return [];
    if (field is! List) return [];
    final out = <String>[];
    for (final e in field) {
      if (e == null) continue;
      if (e is String && e.isNotEmpty) {
        out.add(e);
        continue;
      }
      if (e is Map) {
        final v =
            e['url']?.toString().trim() ??
            e['uri']?.toString().trim() ??
            e['link']?.toString().trim() ??
            '';
        if (v.isNotEmpty) {
          out.add(v);
          continue;
        }
        final fb = e.values.whereType<String>().firstWhere(
          (s) => s.startsWith('http'),
          orElse: () => '',
        );
        if (fb.isNotEmpty) out.add(fb);
      }
    }
    return out;
  }

  /// Extracts named links from [{"Label": "url"}, ...].
  /// Returns List of MapEntry(label, url).
  List<MapEntry<String, String>> _namedLinks(dynamic field) {
    if (field == null) return [];
    if (field is! List) return [];
    final out = <MapEntry<String, String>>[];
    for (final e in field) {
      if (e == null) continue;
      if (e is String && e.isNotEmpty) {
        out.add(MapEntry(_U.hostLabel(e), e));
      } else if (e is Map) {
        e.forEach((k, v) {
          final label = k?.toString().trim() ?? '';
          final url = v?.toString().trim() ?? '';
          if (label.isNotEmpty && url.isNotEmpty) {
            out.add(MapEntry(label, url));
          }
        });
      }
    }
    return out;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();
    return LayoutBuilder(
      builder: (ctx, cs) {
        final w = cs.maxWidth;
        final isDesktop = w >= _BP.tablet;
        final filtered = _filteredRequests(prov);

        return ColoredBox(
          color: _C.bgLight,
          child: Column(
            children: [
              _buildHeader(ctx, prov, isDesktop: isDesktop),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 20 : 12,
                    0,
                    isDesktop ? 20 : 12,
                    isDesktop ? 20 : 12,
                  ),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: w < _BP.desktop ? 360 : 430,
                              child: _buildList(
                                ctx,
                                prov,
                                requests: filtered,
                                isDesktop: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDetail(ctx, prov)),
                          ],
                        )
                      : _buildList(
                          ctx,
                          prov,
                          requests: filtered,
                          isDesktop: false,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext ctx,
    AdminProvider prov, {
    required bool isDesktop,
  }) {
    final pending = _countByStatus(prov, 'pending');
    final active = _countByStatus(prov, 'active');
    final rejected = _countByStatus(prov, 'rejected');
    final closed = _countByStatus(prov, 'closed');

    final stats = [
      _MetricCard(
        label: 'Total Requests',
        value: prov.requests.length.toString(),
        icon: Icons.inbox_outlined,
        color: _C.primary,
      ),
      _MetricCard(
        label: 'Pending Review',
        value: pending.toString(),
        icon: Icons.hourglass_top_rounded,
        color: _C.warning,
      ),
      _MetricCard(
        label: 'Active',
        value: active.toString(),
        icon: Icons.verified_outlined,
        color: _C.success,
      ),
      _MetricCard(
        label: 'Rejected / Closed',
        value: '${rejected + closed}',
        icon: Icons.block_outlined,
        color: _C.danger,
      ),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 14,
        isDesktop ? 22 : 14,
        isDesktop ? 24 : 14,
        14,
      ),
      color: _C.bgLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isDesktop ? 46 : 40,
                height: isDesktop ? 46 : 40,
                decoration: BoxDecoration(
                  gradient: _C.gradPrimary,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: _C.teal.withValues(alpha: .30),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECRUITER PIPELINE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _C.tealDeep,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Recruiter Requests',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isDesktop ? 22 : 18,
                        fontWeight: FontWeight.w800,
                        color: _C.txt1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review recruiter submissions, inspect candidate batches, and move requests through the pipeline.',
                      maxLines: isDesktop ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _C.txt2,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop) _LiveBadge(),
            ],
          ),
          const SizedBox(height: 16),
          isDesktop
              ? Row(
                  children: stats
                      .map(
                        (card) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: card,
                          ),
                        ),
                      )
                      .toList(),
                )
              : SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: stats.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) =>
                        SizedBox(width: 180, child: stats[i]),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Request List ──────────────────────────────────────────────────────────

  Widget _buildList(
    BuildContext ctx,
    AdminProvider prov, {
    List<Map<String, dynamic>>? requests,
    required bool isDesktop,
  }) {
    final visible = requests ?? _filteredRequests(prov);
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 18 : 14),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Review Queue',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _C.txt1,
                      ),
                    ),
                    const Spacer(),
                    _CountBadge(count: visible.length),
                    if (!isDesktop) ...[const SizedBox(width: 8), _LiveBadge()],
                  ],
                ),
                const SizedBox(height: 12),
                _SearchField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                _StatusFilterBar(
                  selected: _statusFilter,
                  countFor: (s) => _countByStatus(prov, s),
                  onSelected: (s) => setState(() => _statusFilter = s),
                  colorFor: _statusColor,
                ),
                if (prov.loading) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: const LinearProgressIndicator(
                      minHeight: 3,
                      color: _C.primary,
                      backgroundColor: _C.primaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: _C.border),
          Expanded(
            child: visible.isEmpty
                ? _EmptyList(loading: prov.loading)
                : Scrollbar(
                    controller: _listCtrl,
                    thumbVisibility: isDesktop,
                    child: ListView.separated(
                      controller: _listCtrl,
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final r = visible[i];
                        final id = _s(r['id']);
                        // The account, not the copy the request was written
                        // with. A denormalised address goes stale; the person
                        // it names does not.
                        final account = prov.recruiterFor(
                          _s(r['recruiter_id']),
                        );
                        final name = _s(account['name']);
                        final email = _s(
                          account['email'],
                          _s(r['recruiter_email']),
                        );
                        final total = r['total_candidates'] ?? 0;
                        // A request with no status is one nobody has
                        // acted on yet, which is what pending means. The old
                        // default said "unknown", which reads as a data fault
                        // rather than as a queue position.
                        final stat = _s(
                          r['status'],
                          'pending',
                        ).replaceAll('\n', '').trim();
                        final date = AdminProvider.formatDate(r['created_at']);
                        return _RequestTile(
                          id: id,
                          name: name,
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

  // ── Desktop detail ────────────────────────────────────────────────────────

  Widget _buildDetail(BuildContext ctx, AdminProvider prov) {
    if (_loadingDetails) {
      return Container(
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary),
        ),
      );
    }
    if (prov.selectedRequestId == null) return const _Placeholder();
    if (prov.selectedRequestDetails == null) {
      return Center(
        child: Text(
          'No details loaded',
          style: GoogleFonts.plusJakartaSans(color: _C.txt3),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Scrollbar(
        controller: _detailCtrl,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _detailCtrl,
          padding: const EdgeInsets.all(24),
          child: _buildDetailContent(ctx, prov, prov.selectedRequestDetails!),
        ),
      ),
    );
  }

  /// Invites one candidate from their own card.
  ///
  /// Same backend call as the bulk button, with a list of one. There is no
  /// second code path for the single case, so the two cannot disagree about
  /// what an invitation is.
  Future<void> _inviteOne(
    BuildContext ctx,
    RequestAssessmentProvider assess,
    String uid,
  ) async {
    final ok = await assess.invite([uid]);
    if (!mounted) return;
    _toast(ctx, ok ? assess.notice : assess.error, ok);
  }

  Future<void> _openDetails(BuildContext ctx, String id) async {
    final prov = Provider.of<AdminProvider>(ctx, listen: false);
    if (prov.selectedRequestId == id) return;
    setState(() => _loadingDetails = true);
    _picked.clear();
    await prov.selectRequest(id);
    if (mounted) setState(() => _loadingDetails = false);
  }

  // ── Detail content (used by desktop panel AND mobile sheet) ──────────────

  Widget _buildDetailContent(
    BuildContext ctx,
    AdminProvider prov,
    Map<String, dynamic> details,
  ) {
    final reqDoc = _n(details['request_doc']);
    final recruiter = _n(details['recruiter']);
    final rawCands =
        (details['candidates'] as List<dynamic>?)?.cast<dynamic>() ?? [];

    final reqData = _n(reqDoc['data']);
    final reqId = _s(reqDoc['id'], '-');
    final status = _s(reqData['status'], 'pending').replaceAll('\n', '').trim();
    final notes = _s(reqData['notes']);
    final dateStr = AdminProvider.formatDateTime(reqData['created_at']);


    // Dedup candidates by uid (uid is flat on each candidate object)
    final seen = <String, Map<String, dynamic>>{};
    for (final c in rawCands) {
      // This part of the code is not a Firestore snapshot listener.
      // The instruction to "Add a check for pending writes in the realtime listener"
      // implies a different context (e.g., a stream listener for Firestore documents).
      // Applying the provided snippet directly here would be syntactically incorrect
      // and semantically misplaced as 'snap.docChanges' and 'change.doc.metadata.hasPendingWrites'
      // are not available in this function's scope.
      //
      // Therefore, the original logic for deduping candidates is retained.
      final cd = _n(c);
      final uid = _s(
        cd['uid'],
        _s(cd['user_id'], _s(cd['email'], '__${seen.length}')),
      );
      seen.putIfAbsent(uid.toLowerCase(), () => cd);
    }
    final cands = seen.values.toList();
    final round = (reqData['round'] as num?)?.toInt() ?? 1;

    // candidate_statuses from the request doc overrides any embedded status
    final rawStat = _n(reqData['candidate_statuses']);
    final statusMap = <String, String>{};
    rawStat.forEach((k, v) {
      if (k.toString().isNotEmpty) {
        statusMap[k.toLowerCase()] = v?.toString() ?? '';
      }
    });

    // The recruiter's post-assessment answer, written onto this same request.
    // Empty until they have given one, which is the difference between "this
    // batch has not been narrowed" and "nobody was kept".
    final finalSelection = {
      for (final id in (reqData['final_selection'] as List? ?? const []))
        id.toString(),
    };

    // Every candidate in a batch applied to the same job, so the paper is the
    // job's. Read off the batch rather than stored twice and left to drift.
    final jobId = cands
        .map((c) => _s(c['job_id']))
        .firstWhere((id) => id.isNotEmpty, orElse: () => '');

    return LayoutBuilder(
      builder: (_, cs) {
        final isNarrow = cs.maxWidth < 520;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _C.bgLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.border),
              ),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.fact_check_outlined,
                          color: _statusColor(status),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request #$reqId',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _C.txt1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: _C.txt3,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                dateStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _C.txt2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.people_outline,
                                size: 14,
                                color: _C.txt3,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${cands.length} candidates',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _C.txt2,
                                ),
                              ),
                            ],
                          ),
                          // What the recruiter typed when they sent the batch.
                          // Kept as one line rather than dropped with the card
                          // it used to sit in: it is the only place the admin
                          // learns why this shortlist arrived.
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.notes_rounded,
                                  size: 14,
                                  color: _C.txt3,
                                ),
                                const SizedBox(width: 5),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 460,
                                  ),
                                  child: Text(
                                    notes,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                      color: _C.txt3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  _StatusDropdown(
                    current: status,
                    onChanged: (ns) async {
                      final ok = await prov.updateRequestStatus(
                        requestId: reqId,
                        newStatus: ns,
                        performedBy: 'admin_dashboard',
                      );
                      if (!mounted) return; // Check if still in tree
                      _toast(
                        ctx,
                        ok
                            ? 'Status updated to ${ns.toUpperCase()}'
                            : 'Update failed',
                        ok,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Candidates',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _C.txt1,
                  ),
                ),
                _CountBadge(count: cands.length),
                if (round >= 2) _RoundBadge(round: round),
              ],
            ),
            const SizedBox(height: 16),

            if (cands.isEmpty)
              _EmptyCandidates()
            else
              // Two streams, both scoped to this batch, both keyed on reqId so
              // switching batches rebuilds them. The app-level
              // InterviewProvider watches the signed-in recruiter's own
              // bookings, which is the wrong set entirely for an admin.
              MultiProvider(
                key: ValueKey('batch_$reqId'),
                providers: [
                  ChangeNotifierProvider(
                    create: (_) => InterviewProvider()..watchForRequest(reqId),
                  ),
                  ChangeNotifierProvider(
                    create: (_) => RequestAssessmentProvider()
                      ..open(requestId: reqId, jobId: jobId),
                  ),
                ],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TestConsole(
                      reqId: reqId,
                      candidates: cands,
                      picked: _picked,
                      onPickMany: (uids) => setState(() {
                        _picked
                          ..clear()
                          ..addAll(uids);
                      }),
                      onDone: (msg, ok) {
                        if (mounted) {
                          setState(_picked.clear);
                          _toast(ctx, msg, ok);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _CandidateGrid(
                      candidates: cands,
                      statusMap: statusMap,
                      finalSelection: finalSelection,
                      isNarrow: isNarrow,
                      reqId: reqId,
                      picked: _picked,
                      onPick: (uid, on) => setState(
                        () => on ? _picked.add(uid) : _picked.remove(uid),
                      ),
                      onTap: (c) => _showCV(ctx, c),
                      onInvite: (assess, uid) =>
                          _inviteOne(ctx, assess, uid),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 48),
          ],
        );
      },
    );
  }

  // ── Toast (branded snackbars) ───────────────────────────────────────────────

  void _toast(BuildContext ctx, String msg, bool ok) {
    if (!mounted) return;
    if (ok) {
      BrandSnack.success(ctx, msg);
    } else {
      BrandSnack.error(ctx, msg);
    }
  }

  // ── Mobile bottom-sheet for request detail ────────────────────────────────

  void _showModal(BuildContext ctx, AdminProvider prov, String requestId) {
    prov.selectRequest(requestId);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: prov,
        child: Consumer<AdminProvider>(
          builder: (ctx2, snap, _) {
            if (snap.loading && snap.selectedRequestDetails == null) {
              return _Shell(
                height: 220,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _C.primary,
                  ),
                ),
              );
            }
            final det = snap.selectedRequestDetails;
            if (det == null) {
              return _Shell(
                height: 180,
                child: Center(
                  child: Text(
                    'Failed to load',
                    style: GoogleFonts.plusJakartaSans(color: _C.txt3),
                  ),
                ),
              );
            }
            return DraggableScrollableSheet(
              initialChildSize: 0.92,
              minChildSize: 0.5,
              maxChildSize: 0.97,
              builder: (_, sc) => ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: ScaffoldMessenger(
                  child: Scaffold(
                    backgroundColor: _C.bg,
                    body: CustomScrollView(
                      controller: sc,
                      slivers: [
                        SliverToBoxAdapter(child: _dragHandle()),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          sliver: SliverToBoxAdapter(
                            child: Builder(
                              builder: (sheetCtx) =>
                                  _buildDetailContent(sheetCtx, snap, det),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _dragHandle() => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: _C.border,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  // ── CV Bottom Sheet ───────────────────────────────────────────────────────
  //
  // DATA PATH:
  //   /recruiter_requests/{reqId}/candidates[]  — each item is FLAT.
  //   ALL profile data lives directly on the candidate object.
  //   No personalProfile / professionalProfile nesting in this schema.
  //
  //   Key fields (from real JSON):
  //     name, email, phone, uid, picture_url
  //     nationality, dob, location, retirement_date, secondary_email
  //     summary, objectives
  //     company, job_title, current_role, professional_status, experience_years
  //     skills[], social_links[], awards[], publications[]
  //     professionalExperience[], educationalProfile[], certifications[]
  //     experienceDocuments: [{"Label": "url"}, ...]  → named link chips
  //     certificationDocuments: ["url", ...]          → link chips
  //     match_score: { overallScore, recommendation, strengths[], weaknesses[],
  //                   skillsMatch, educationMatch, experienceMatch, detailedAnalysis }
  //     status                                        → excluded (on card only)

  /// Projects `candidateProfile` onto the flat keys [_CVSheet] reads.
  ///
  /// The sheet predates the profile schema and reads one flat map; rather than
  /// rewrite every row, the profile is unpacked here once. Contact fields are
  /// included on purpose — this is the admin view, and admins are the ones who
  /// arrange interviews and travel.
  static Map<String, dynamic> _flattenProfile(Map<String, dynamic> raw) {
    if (raw.isEmpty) return const {};
    final profile = CandidateProfile.fromJson(
        raw['uid']?.toString() ?? '', raw);
    final personal = profile.personalInfo;
    final latest =
        profile.experience.isEmpty ? null : profile.experience.first;
    final firstEdu =
        profile.education.isEmpty ? null : profile.education.first;

    List<Map<String, dynamic>> docs(DocumentCategory category) => [
          for (final d in profile.documentsIn(category))
            {'name': d.name, 'url': d.url, 'type': d.contentType},
        ];

    return {
      'name': personal.fullName,
      'email': personal.email,
      'secondary_email': personal.secondaryEmail,
      'phone': personal.phone,
      'nationality': personal.nationality,
      'dob': personal.dateOfBirth,
      'location': personal.location.display,
      'picture_url': personal.profilePicUrl,
      'summary': personal.summary,
      'objectives': personal.objectives,
      'socialLinks': personal.socialLinks,
      'skills': <String>{
        ...personal.skills,
        ...profile.roleSpecificData.technicalCompetencies,
        ...profile.roleSpecificData.toolsAndSystems,
      }.toList(),
      'professional_status': profile.professionalStatus,
      'retirement_date': profile.expectedRetirementDate,
      'current_role': latest?.title ?? '',
      'company': latest?.company ?? '',
      // A count and a duration, under names that say which is which. The key
      // called `experience_years` used to hold this count, which is how a
      // two-posting candidate was rendered as "2 year(s)" on this very sheet.
      'roles_listed': profile.experience.length,
      'years_experience': ServiceYears.from([
        for (final x in profile.experience)
          {
            'startDate': x.startDate,
            'endDate': x.endDate,
            'isCurrent': x.isCurrent,
          },
      ]),
      'university': firstEdu?.institution ?? '',
      'education': firstEdu?.fieldOfStudy ?? '',
      'education_duration': firstEdu?.graduationYear?.toString() ?? '',
      'professionalExperience': [
        for (final x in profile.experience)
          {
            'organization': x.company,
            'role': x.title,
            'location': x.location,
            'startDate': x.startDate,
            'endDate': x.endDate ?? (x.isCurrent ? 'Present' : ''),
            'duties': x.responsibilities.join('\n'),
          },
      ],
      'educationalProfile': [
        for (final e in profile.education)
          {
            'institutionName': e.institution,
            'degree': e.degree,
            'majorSubjects': e.fieldOfStudy,
            'duration': e.graduationYear?.toString() ?? '',
            'marksOrCgpa': e.grade,
          },
      ],
      'certifications': [
        for (final c in profile.certifications)
          {'name': c.name, 'organization': c.issuer},
        for (final l in profile.roleSpecificData.licensesAndRatings)
          {'name': l.title, 'organization': l.issuingAuthority},
      ],
      'publications': profile.publications,
      'awards': profile.awards,
      'experienceDocuments': docs(DocumentCategory.experience),
      'certification_documents': docs(DocumentCategory.certification),
      'documents': docs(DocumentCategory.general),
    };
  }

  void _showCV(BuildContext ctx, Map<String, dynamic> candidate) {
    // The sheet renders a flat map. Flatten the candidate profile into the
    // keys it reads, then let anything the recruiter's request carried at the
    // top level win — that layer holds the match score and the request's own
    // view of the job title.
    final raw = _n(candidate);
    final cand = <String, dynamic>{
      ..._flattenProfile(_n(raw['candidate_profile'])),
      ...raw,
    };
    cand.remove('candidate_profile');

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📋 CV SHEET — keys: ${cand.keys.toList()}');
    debugPrint('📋 name=${cand['name']}, email=${cand['email']}');
    debugPrint('📋 nationality=${cand['nationality']}, dob=${cand['dob']}');
    debugPrint('📋 skills=${cand['skills']}');
    debugPrint('📋 eduProfile type=${cand['educationalProfile']?.runtimeType}');
    debugPrint(
      '📋 profExp type=${cand['professionalExperience']?.runtimeType}',
    );
    debugPrint('📋 certs type=${cand['certifications']?.runtimeType}');
    debugPrint('📋 match_score=${_n(cand['match_score']).keys.toList()}');
    debugPrint('📋 expDocs=${cand['experienceDocuments']}');
    debugPrint('═══════════════════════════════════════════════════════');

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _CVSheet(
        cand: cand,
        namedLinks: _namedLinks,
        urlList: _urlList,
        strList: _sl,
        str: _s,
        norm: _n,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SMALL SHARED COMPONENTS
// ═════════════════════════════════════════════════════════════════════════════

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .035),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _C.txt1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _C.txt2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: _C.txt1,
    ),
    decoration: InputDecoration(
      hintText: 'Search by request, email, recruiter...',
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _C.txt3,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Container(
          width: 30,
          decoration: BoxDecoration(
            color: _C.tealTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.search_rounded, size: 17, color: _C.tealDeep),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 40),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: _C.txt3),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
      isDense: true,
      filled: true,
      fillColor: _C.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _C.navy, width: 1.6),
      ),
    ),
  );
}

class _StatusFilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final int Function(String) countFor;
  final Color Function(String) colorFor;

  const _StatusFilterBar({
    required this.selected,
    required this.onSelected,
    required this.countFor,
    required this.colorFor,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = ['all', 'pending', 'active', 'rejected', 'closed'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final isSelected = status == selected;
          final color = status == 'all' ? _C.primary : colorFor(status);
          final label = status == 'all'
              ? 'All'
              : '${status[0].toUpperCase()}${status.substring(1)}';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              onSelected: (_) => onSelected(status),
              label: Text('$label ${countFor(status)}'),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? color : _C.txt2,
              ),
              avatar: status == 'all'
                  ? null
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
              selectedColor: color.withValues(alpha: .12),
              backgroundColor: _C.bgLight,
              side: BorderSide(
                color: isSelected ? color.withValues(alpha: .35) : _C.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _C.successLt,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.success.withValues(alpha: .2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: _C.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'LIVE',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _C.success,
          ),
        ),
      ],
    ),
  );
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: _C.primaryLt,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$count',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _C.primary,
      ),
    ),
  );
}

class _EmptyList extends StatelessWidget {
  final bool loading;
  const _EmptyList({required this.loading});
  @override
  Widget build(BuildContext ctx) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _C.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _C.border),
            ),
            child: const Icon(Icons.inbox_outlined, size: 32, color: _C.txt4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Requests',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: _C.txt2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'New items appear here automatically',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _C.txt3),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();
  @override
  Widget build(BuildContext ctx) => Container(
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _C.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _C.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app_outlined,
              size: 30,
              color: _C.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Select a request',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _C.txt1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose an item from the review queue to inspect recruiter details and manage candidates.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.txt2,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Shell extends StatelessWidget {
  final Widget child;
  final double height;
  const _Shell({required this.child, required this.height});
  @override
  Widget build(BuildContext ctx) => Container(
    height: height,
    decoration: const BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: child,
  );
}

class _EmptyCandidates extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.border),
    ),
    child: Center(
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 32, color: _C.txt4),
          const SizedBox(height: 12),
          Text(
            'No candidates attached',
            style: GoogleFonts.plusJakartaSans(
              color: _C.txt3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  CANDIDATE GRID
// ═════════════════════════════════════════════════════════════════════════════

class _CandidateGrid extends StatelessWidget {
  final List<Map<String, dynamic>> candidates;
  final Map<String, String> statusMap;
  final Set<String> finalSelection;
  final bool isNarrow;
  final String reqId;
  final Set<String> picked;
  final void Function(String uid, bool on) onPick;
  final void Function(Map<String, dynamic>) onTap;

  /// Takes the provider the grid is already watching rather than looking it up
  /// again: the caller lives above the [MultiProvider] that supplies it, so a
  /// lookup from there would find nothing.
  final void Function(RequestAssessmentProvider, String uid) onInvite;

  const _CandidateGrid({
    required this.candidates,
    required this.statusMap,
    required this.finalSelection,
    required this.isNarrow,
    required this.reqId,
    required this.picked,
    required this.onPick,
    required this.onTap,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext ctx) {
    // Both scoped to this batch. The recruiter books the slot and the candidate
    // sits the test; this is where the admin sees both happen — the same
    // documents, streamed by every side, so nothing has to be copied across and
    // nothing can fall out of step.
    final interviews = ctx.watch<InterviewProvider>();
    final assess = ctx.watch<RequestAssessmentProvider>();

    final booked = {
      for (final i in interviews.interviews)
        if (i.status != InterviewStatus.cancelled) i.candidateUid: i,
    };

    // The card grows a footer for each of the two strips it can carry; a fixed
    // extent sized for the shortest would clip the others.
    final extent = booked.isEmpty ? 212.0 : 262.0;
    final narrowed = finalSelection.isNotEmpty;
    final canInvite = assess.paperApproved == true;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isNarrow ? double.infinity : 440,
        mainAxisExtent: extent,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: candidates.length,
      itemBuilder: (ctx2, i) {
        final c = candidates[i];
        final uid = c['uid']?.toString() ?? '';
        final canon = uid.toLowerCase();

        // candidate_statuses on the request wins over the copy embedded in the
        // candidate map; the embedded one is a snapshot from when the recruiter
        // sent them. Neither being set means shortlist, which is what being in
        // this batch means — not "unknown".
        final embedded = c['status']?.toString().trim() ?? '';
        final cStat = statusMap[canon]?.isNotEmpty == true
            ? statusMap[canon]!
            : (embedded.isEmpty ? 'shortlist' : embedded);

        final row = assess.rowFor(uid);

        // Two ways a candidate stops being live in this batch, and both look
        // the same to a reader: the test decided it (a released fail), or the
        // recruiter did (narrowed the batch and did not keep them). Dimmed,
        // never removed — the record of them being considered has to survive.
        final failed = row?.released == true && row?.verdict == 'fail';
        final dead = failed || (narrowed && !finalSelection.contains(uid));

        return CandidateCard(
          key: ValueKey('${reqId}_$canon'),
          name: c['name']?.toString() ?? uid,
          email: c['email']?.toString() ?? '',
          phone: c['phone']?.toString() ?? '',
          title: c['job_title']?.toString() ??
              c['current_role']?.toString() ??
              '',
          company: c['company']?.toString() ?? '',
          score: (c['match_score'] as Map?)?['overallScore']?.toString() ?? '',
          status: cStat,
          assessment: row,
          interview: booked[uid],
          superseded: dead,
          finalPick: finalSelection.contains(uid),
          // Selectable for the two things the admin does in bulk: inviting
          // people who have not been invited, and sending back scores that
          // have arrived and not gone yet. A score already sent is not
          // something a tick can act on, so the box stays dead for it.
          selectable: row == null || (row.percentage != null && !row.released),
          selected: picked.contains(uid),
          onSelected: (on) => onPick(uid, on),
          onInvite: row == null && canInvite && uid.isNotEmpty
              ? () => onInvite(assess, uid)
              : null,
          onTap: () => onTap(c),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REQUEST TILE
// ─────────────────────────────────────────────────────────────────────────────
class _RequestTile extends StatefulWidget {
  final String id, name, email, status, date;
  final int total;
  final bool selected;
  final VoidCallback onTap;

  const _RequestTile({
    required this.id,
    required this.name,
    required this.email,
    required this.total,
    required this.status,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _hover = false;

  Color _col() {
    final s = widget.status.toLowerCase();
    if (s == 'active' || s == 'approved') return _C.success;
    if (s == 'pending') return _C.warning;
    if (s == 'rejected' || s == 'closed') return _C.danger;
    return _C.primary;
  }

  @override
  Widget build(BuildContext ctx) {
    final c = _col();
    final selected = widget.selected;
    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
            0,
            (_hover && !selected) ? -3 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: selected ? _C.primaryLight : _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _C.navy.withValues(alpha: .55)
                  : (_hover ? _C.teal.withValues(alpha: .5) : _C.border),
              width: selected ? 1.4 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _C.navy.withValues(alpha: .12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : (_hover
                      ? [
                          BoxShadow(
                            color: _C.teal.withValues(alpha: .18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                child: Stack(
                  children: [
                    if (selected)
                      Positioned(
                        left: 0,
                        top: 10,
                        bottom: 10,
                        child: Container(
                          width: 3.5,
                          decoration: BoxDecoration(
                            gradient: _C.gradPrimary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: c.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  color: c,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Who sent it, then how to reach them, then the
                              // reference. An admin scans this queue for a
                              // person, not for an id — the id used to be the
                              // headline and the person was not shown at all.
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.name.isEmpty
                                          ? (widget.email.isEmpty
                                              ? 'Unnamed recruiter'
                                              : widget.email)
                                          : widget.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: selected
                                            ? _C.primary
                                            : _C.txt1,
                                      ),
                                    ),
                                    if (widget.name.isNotEmpty &&
                                        widget.email.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: _C.txt2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 3),
                                    Text(
                                      'REQ #${widget.id}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                        color: _C.txt4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: selected ? _C.primary : _C.txt3,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: c.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: c.withValues(alpha: .18),
                                  ),
                                ),
                                child: Text(
                                  widget.status.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: c,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.people_outline,
                                size: 13,
                                color: selected ? _C.primary : _C.txt3,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.total}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? _C.primary : _C.txt2,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                widget.date,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _C.txt3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RECRUITER CARD
// ─────────────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;
  const _Avatar({required this.name, required this.size, this.imageUrl});

  @override
  Widget build(BuildContext ctx) {
    final url = imageUrl?.isNotEmpty == true ? imageUrl! : '';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: url.isEmpty
            ? const LinearGradient(
                colors: [_C.teal, _C.navy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        image: url.isNotEmpty
            ? DecorationImage(
                image: ResizeImage(
                  NetworkImage(url),
                  width: (size * 2).round(),
                  height: (size * 2).round(),
                ),
                fit: BoxFit.cover,
                onError: (_, _) {},
              )
            : null,
      ),
      child: url.isEmpty
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: size * .38,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
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
    final st = s.toLowerCase().trim();
    if (st == 'active') return _C.success;
    if (st == 'pending') return _C.warning;
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
      itemBuilder: (_) => ['Pending', 'Active', 'Rejected', 'Closed']
          .map(
            (s) => PopupMenuItem(
              value: s.toLowerCase(),
              height: 40,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _c(s),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    s,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: col.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: col.withValues(alpha: .25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: col, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              current.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: col,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: col),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CANDIDATE CARD  (grid tile)
// ─────────────────────────────────────────────────────────────────────────────

// ─── Design tokens - Navy + Teal brand ─────────────────────────────────────────
abstract final class _T {
  // Surface / background
  static const bg = Color(0xFFF4F9FB);
  static const bgLight = Color(0xFFF4F9FB);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCE7EF);
  static const divider = Color(0xFFF4F9FB);

  // Text hierarchy
  static const txt1 = Color(0xFF0B2239); // ink
  static const txt2 = Color(0xFF3E5C76); // slate
  static const txt3 = Color(0xFF5E7A8E); // muted

  // Semantic colors
  static const primary = Color(0xFF14507F); // navy
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // Accent palette (pipeline stage colours) - navy → blue → teal → coral → green
  static const blue = Color(0xFF2178B5);
  static const violet = Color(0xFF2EC4B6); // teal (was violet)
  static const pink = Color(0xFFFF7A59); // coral (was pink)
  static const emerald = Color(0xFF10B981);

  // Typography helpers
  static TextStyle label({
    double size = 11,
    FontWeight weight = FontWeight.w500,
    Color color = txt2,
    double spacing = 0,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: 1.2,
  );
}

// ─── Pipeline stage definitions ───────────────────────────────────────────────
/// The pipeline this screen paints, taken from the one definition of it.
///
/// It used to be a second copy of the same list. Two copies is how a button
/// ends up offering a stage the write path does not recognise.
const _kStages = HiringPipeline.stages;

const _kStageColors = <String, Color>{
  'shortlist': _T.primary,
  'shortlisted': _T.primary,
  'screening': _T.blue,
  'interview': _T.violet,
  'technical': _T.pink,
  'offer': _T.emerald,
  'handover': _T.success,
  'hired': _T.success,
  'rejected': _T.danger,
};

Color _stageColor(String status) =>
    _kStageColors[status.toLowerCase()] ?? _T.txt3;

Color _scoreColor(int v) {
  if (v >= 70) return _T.success;
  if (v >= 40) return _T.warning;
  return _T.danger;
}

int _stageIndex(String status) => HiringPipeline.indexOf(status);

// ══════════════════════════════════════════════════════════════════════════════
//  PUBLIC WIDGET
// ══════════════════════════════════════════════════════════════════════════════
/// One candidate, everything the admin does to them, on one card.
///
/// There is no stage menu on it any more. Every stage this screen can move a
/// candidate through is the consequence of a real action — inviting them to the
/// test, sending their score to the recruiter, the recruiter booking them an
/// interview — so a dropdown that set the stage directly could only ever
/// disagree with what had actually happened.
class CandidateCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String title;
  final String company;

  /// The AI match score from shortlisting. Not the test score.
  final String score;
  final String status;

  /// This candidate's sitting, or null if they have never been invited.
  final AssessmentRow? assessment;

  /// The slot the recruiter booked, if they have.
  final Interview? interview;

  /// True when the recruiter has narrowed the batch and did not keep this one.
  /// The card dims; it is never removed, because the record of them having been
  /// considered has to survive the narrowing.
  final bool superseded;

  /// True when the recruiter kept this candidate after seeing the scores.
  final bool finalPick;

  final bool selectable;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  /// Invites this one candidate to sit the test. Null when that is not
  /// currently possible — no approved paper, or they are already invited.
  final VoidCallback? onInvite;

  final VoidCallback onTap;

  const CandidateCard({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.title,
    required this.company,
    required this.score,
    required this.status,
    required this.onTap,
    this.assessment,
    this.interview,
    this.superseded = false,
    this.finalPick = false,
    this.selectable = false,
    this.selected = false,
    this.onSelected,
    this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final col = _stageColor(status);
    final idx = _stageIndex(status);

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: col.withValues(alpha: 0.06),
            highlightColor: col.withValues(alpha: 0.03),
            child: Column(
              mainAxisSize:
                  MainAxisSize.max, // Changed from min to allow Expanded
              children: [
                _CardHeader(
                  status: status,
                  score: score,
                  color: col,
                  finalPick: finalPick,
                  superseded: superseded,
                  selectable: selectable,
                  selected: selected,
                  onSelected: onSelected,
                ),
                Expanded(
                  child: _CardBody(
                    name: name,
                    title: title,
                    company: company,
                    email: email,
                    phone: phone,
                    stageColor: col,
                  ),
                ),
                _AssessmentStrip(row: assessment, onInvite: onInvite),
                if (interview != null) _InterviewStrip(interview: interview!),
                _PipelineBar(index: idx, total: _kStages.length, color: col),
              ],
            ),
          ),
        ),
      ),
    );

    // Dimmed, not hidden. A reader looking at this batch in three months needs
    // to see who was considered as well as who was kept.
    if (!superseded) return card;
    return Opacity(opacity: 0.45, child: card);
  }
}

// ─── Header: status badge + score ─────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final String status, score;
  final Color color;
  final bool finalPick, superseded, selectable, selected;
  final ValueChanged<bool>? onSelected;

  const _CardHeader({
    required this.status,
    required this.score,
    required this.color,
    this.finalPick = false,
    this.superseded = false,
    this.selectable = false,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scoreVal = int.tryParse(score) ?? 0;
    final sc = _scoreColor(scoreVal);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const BoxDecoration(
        color: _T.bg,
        border: Border(bottom: BorderSide(color: _T.divider, width: 1)),
      ),
      child: Row(
        children: [
          if (selectable)
            SizedBox(
              width: 26,
              height: 26,
              child: Checkbox(
                value: selected,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) => onSelected?.call(v ?? false),
              ),
            ),
          if (selectable) const SizedBox(width: 6),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  status.toUpperCase(),
                  style: _T.label(
                    size: 9,
                    weight: FontWeight.w700,
                    color: color,
                    spacing: 0.6,
                  ),
                ),
              ],
            ),
          ),

          if (finalPick) ...[
            const SizedBox(width: 5),
            _MiniTag(
              text: 'KEPT',
              icon: Icons.push_pin_rounded,
              color: _T.violet,
            ),
          ],
          if (superseded) ...[
            const SizedBox(width: 5),
            _MiniTag(
              text: 'CLOSED',
              icon: Icons.remove_circle_outline_rounded,
              color: _T.txt3,
            ),
          ],

          const Spacer(),

          // Score pill — the AI match score from shortlisting. Labelled, so it
          // is never read as the test score sitting two rows below it.
          if (score.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 11, color: sc),
                  const SizedBox(width: 3),
                  Text(
                    'AI $score%',
                    style: _T.label(
                      size: 10,
                      weight: FontWeight.w700,
                      color: sc,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A one-word marker on the card header.
/// The online test, for one recruiter request, in one strip.
///
/// Everything the admin does about the assessment happens here: invite the
/// batch, watch it come in, send the scores back with a note. It sits directly
/// above the candidates it acts on, because the alternative — a separate
/// assessment screen with its own copy of the candidate list — is what made two
/// screens disagree about which batch was which.
class _TestConsole extends StatelessWidget {
  const _TestConsole({
    required this.reqId,
    required this.candidates,
    required this.picked,
    required this.onPickMany,
    required this.onDone,
  });

  final String reqId;
  final List<Map<String, dynamic>> candidates;
  final Set<String> picked;
  final ValueChanged<Set<String>> onPickMany;
  final void Function(String message, bool ok) onDone;

  List<String> get _uids => [
        for (final c in candidates)
          if ((c['uid']?.toString() ?? '').isNotEmpty) c['uid'].toString(),
      ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RequestAssessmentProvider>();

    final uninvited = [for (final u in _uids) if (!p.isInvited(u)) u];
    final scored = [
      for (final u in _uids)
        if (p.hasScore(u) && !p.isReleased(u)) u,
    ];

    final pickedUninvited =
        picked.where((u) => uninvited.contains(u)).toList();
    final pickedScored = picked.where((u) => scored.contains(u)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz_outlined, size: 17, color: _C.tealDeep),
              const SizedBox(width: 8),
              Text(
                'Online test assessment',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _C.txt1,
                ),
              ),
              const Spacer(),
              if (p.busy)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _C.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _paperLine(p),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _stat('${p.invitedCount} invited', _C.primary),
              _stat('${p.submittedCount} sat the test', _C.blue),
              _stat('${p.scoredCount} scored', _C.success),
              _stat('${p.releasedCount} sent to recruiter', _C.teal),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _C.border),
          const SizedBox(height: 14),

          // ── Invite ────────────────────────────────────────────────────────
          if (uninvited.isNotEmpty)
            _actionRow(
              context,
              label: pickedUninvited.isEmpty
                  ? '${uninvited.length} not invited yet'
                  : '${pickedUninvited.length} selected to invite',
              selectAllLabel: 'Select all ${uninvited.length}',
              onSelectAll: () => onPickMany(uninvited.toSet()),
              button: FilledButton.icon(
                onPressed: p.busy ||
                        pickedUninvited.isEmpty ||
                        p.paperApproved != true
                    ? null
                    : () async {
                        final ok = await p.invite(pickedUninvited);
                        onDone(ok ? p.notice : p.error, ok);
                      },
                icon: const Icon(Icons.send_rounded, size: 15),
                label: Text('Invite ${pickedUninvited.length} for test'),
              ),
            ),

          // ── Release ───────────────────────────────────────────────────────
          if (scored.isNotEmpty) ...[
            if (uninvited.isNotEmpty) const SizedBox(height: 12),
            _actionRow(
              context,
              label: pickedScored.isEmpty
                  ? '${scored.length} score${scored.length == 1 ? '' : 's'} '
                      'not sent to the recruiter yet'
                  : '${pickedScored.length} selected to send',
              selectAllLabel: 'Select all ${scored.length}',
              onSelectAll: () => onPickMany(scored.toSet()),
              button: FilledButton.icon(
                onPressed: p.busy || pickedScored.isEmpty
                    ? null
                    : () => _release(context, p, pickedScored),
                icon: const Icon(Icons.forward_to_inbox_rounded, size: 15),
                label: Text('Send ${pickedScored.length} to recruiter'),
                style: FilledButton.styleFrom(backgroundColor: _C.tealDeep),
              ),
            ),
          ],

          if (uninvited.isEmpty && scored.isEmpty)
            Text(
              p.invitedCount == 0
                  ? 'Nobody in this batch has been invited yet.'
                  : 'Nothing to do here right now — every score that has come '
                      'back has been sent to the recruiter.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.45,
                color: _C.txt2,
              ),
            ),

          if (p.error.isNotEmpty) ...[
            const SizedBox(height: 12),
            _note(p.error, _C.danger, Icons.error_outline_rounded),
          ],
        ],
      ),
    );
  }

  Widget _paperLine(RequestAssessmentProvider p) => switch (p.paperApproved) {
        true => _note(
            'Question paper approved for this job. Every candidate sits 20 '
            'questions sampled from the same set.',
            _C.success,
            Icons.verified_rounded,
          ),
        false => _note(
            'No approved question paper for this job yet. Write and approve one '
            'on the Assessments screen, then come back and invite.',
            _C.warning,
            Icons.edit_note_rounded,
          ),
        // Unknown, not absent. Reporting an unreachable backend as "no paper"
        // is how an admin ends up regenerating a paper that already exists.
        null => _note(
            'Cannot reach the assessment backend, so the paper for this job '
            'could not be checked. There may well be an approved one.',
            _C.txt3,
            Icons.cloud_off_rounded,
          ),
      };

  Widget _note(String text, Color color, IconData icon) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      );

  Widget _stat(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );

  Widget _actionRow(
    BuildContext context, {
    required String label,
    required String selectAllLabel,
    required VoidCallback onSelectAll,
    required Widget button,
  }) =>
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.txt2,
            ),
          ),
          TextButton(
            onPressed: onSelectAll,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              visualDensity: VisualDensity.compact,
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(selectAllLabel),
          ),
          button,
        ],
      );

  /// Sends the picked scores to the recruiter, with the note the admin writes.
  ///
  /// The note is the point of the step. A number on its own does not tell the
  /// recruiter what the admin thought of it.
  Future<void> _release(
    BuildContext context,
    RequestAssessmentProvider p,
    List<String> uids,
  ) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Send ${uids.length} score${uids.length == 1 ? '' : 's'} to the recruiter',
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'They will see the score, the rank within the batch and the '
                'pass mark, and can then re-select from this same shortlist. '
                'Candidates you have not picked stay hidden from them.',
                style: TextStyle(fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Note for the recruiter',
                  hintText: 'e.g. Scores in — shortlist for interview from '
                      'these, technical section was strongest for the top three.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send scores'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null) return;

    final ok = await p.release(uids: uids, note: note);
    onDone(ok ? p.notice : p.error, ok);
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
            Text(
              text,
              style: _T.label(
                size: 8.5,
                weight: FontWeight.w800,
                color: color,
                spacing: 0.5,
              ),
            ),
          ],
        ),
      );
}

/// Where this candidate is in the online test, and the button that starts it.
///
/// The status is the same fact the candidate and the recruiter see, read from
/// the same assessment document. Nobody is looking at a copy.
class _AssessmentStrip extends StatelessWidget {
  const _AssessmentStrip({required this.row, required this.onInvite});

  final AssessmentRow? row;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final r = row;

    // Never invited. The only state with an action attached.
    if (r == null) {
      return _shell(
        icon: Icons.quiz_outlined,
        color: _T.txt3,
        label: 'Not invited to the test',
        trailing: onInvite == null
            ? null
            : TextButton.icon(
                onPressed: onInvite,
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text('Invite for test'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 30),
                  visualDensity: VisualDensity.compact,
                  textStyle: _T.label(size: 11, weight: FontWeight.w700),
                ),
              ),
      );
    }

    final (label, color) = switch (r.status) {
      'invited' => (
          r.expiresAt == null
              ? 'Invited · waiting for them to accept'
              : 'Invited · ${_countdown(r.expiresAt!)} to accept',
          _T.warning,
        ),
      'accepted' => ('Accepted · has not started yet', _T.blue),
      'in_progress' => (
          'In test assessment · ${r.answeredCount} of ${r.questionCount} answered',
          _T.blue,
        ),
      'submitted' => (
          r.percentage == null
              ? 'Submitted · awaiting score'
              : 'Scored ${r.correct}/${r.questionCount} · ${r.percentage}%'
                  '${r.verdict == null ? '' : ' · ${r.verdict!.toUpperCase()}'}',
          r.verdict == 'pass' ? _T.success : _T.danger,
        ),
      'expired' => ('Expired · did not sit the test', _T.danger),
      _ => (r.status.isEmpty ? 'Unknown state' : r.status, _T.txt3),
    };

    return _shell(
      icon: r.status == 'submitted'
          ? Icons.fact_check_rounded
          : Icons.timer_outlined,
      color: color,
      label: label,
      trailing: r.released
          ? _MiniTag(
              text: 'SENT',
              icon: Icons.forward_to_inbox_rounded,
              color: _T.success,
            )
          : null,
      // Two integrity signals worth an admin's attention, and worth naming
      // rather than acting on: a tab switch is not proof of anything.
      note: r.tabSwitches > 0 || r.resumes > 1
          ? '${r.tabSwitches} tab switch${r.tabSwitches == 1 ? '' : 'es'}'
              '${r.resumes > 1 ? ', resumed ${r.resumes}×' : ''}'
          : null,
    );
  }

  static String _countdown(DateTime deadline) {
    final left = deadline.difference(DateTime.now());
    if (left.isNegative) return 'expired';
    if (left.inHours >= 1) return '${left.inHours}h left';
    return '${left.inMinutes}m left';
  }

  Widget _shell({
    required IconData icon,
    required Color color,
    required String label,
    Widget? trailing,
    String? note,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          border: const Border(
            top: BorderSide(color: _T.divider, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _T.label(
                      size: 11,
                      weight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (note != null)
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _T.label(size: 9.5, color: _T.txt3),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      );
}

/// The interview the recruiter booked, and the one action the admin owns.
///
/// The recruiter chooses who and when; the admin turns that into a joining
/// link. Keeping the two apart is the point — the person arranging the meeting
/// is not the person deciding it should happen.
class _InterviewStrip extends StatelessWidget {
  const _InterviewStrip({required this.interview});

  final Interview interview;

  Future<void> _generate(BuildContext context) async {
    final provider = context.read<InterviewProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Placeholder until the Zoom integration lands. Deliberately obvious:
    // a link that looks real but is not would be handed to a candidate.
    final link = 'https://zoom.us/j/PENDING-${interview.id.substring(0, 8)}';
    final ok = await provider.attachLink(
      interviewId: interview.id,
      link: link,
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
    final waiting = !interview.hasLink;
    final tone = waiting ? _T.warning : _T.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.07),
        border: Border(top: BorderSide(color: _T.border)),
      ),
      child: Row(
        children: [
          Icon(
            waiting ? Icons.event_rounded : Icons.videocam_rounded,
            size: 15,
            color: tone,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('EEE d MMM, HH:mm')
                      .format(interview.scheduledAt),
                  style: _T.label(
                      size: 11.5, weight: FontWeight.w800, color: _T.txt1),
                ),
                Text(
                  '${interview.mode.label} · ${interview.durationMinutes} min'
                  '${waiting ? '' : ' · link sent'}',
                  style: _T.label(size: 10, color: _T.txt3),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (waiting)
            TextButton.icon(
              onPressed: () => _generate(context),
              icon: const Icon(Icons.add_link_rounded, size: 15),
              label: const Text('Generate link'),
              style: TextButton.styleFrom(
                foregroundColor: tone,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: _T.label(size: 11.5, weight: FontWeight.w800),
              ),
            )
          else
            IconButton(
              tooltip: 'Copy joining link',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: interview.meetingLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Joining link copied')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 15),
              color: tone,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

// ─── Main body ────────────────────────────────────────────────────────────────
class _CardBody extends StatelessWidget {
  final String name, title, company, email, phone;
  final Color stageColor;

  const _CardBody({
    required this.name,
    required this.title,
    required this.company,
    required this.email,
    required this.phone,
    required this.stageColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          second_Avatar(name: name, color: stageColor),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment
                  .center, // Vertically center in expanded area
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _T.label(
                              size: 14,
                              weight: FontWeight.w700,
                              color: _T.txt1,
                            ),
                          ),
                          if (title.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _T.label(
                                size: 12,
                                weight: FontWeight.w700,
                                color: stageColor,
                              ),
                            ),
                          ],
                          if (company.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _T.label(
                                size: 10,
                                weight: FontWeight.w500,
                                color: _T.txt3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _MetaRow(icon: Icons.alternate_email_rounded, text: email),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _MetaRow(icon: Icons.smartphone_rounded, text: phone),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Circular avatar ──────────────────────────────────────────────────────────
class second_Avatar extends StatelessWidget {
  final String name;
  final Color color;

  const second_Avatar({super.key, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : 'C';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.75), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: _T.label(
          size: initials.length > 1 ? 13 : 16,
          weight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Marks a shortlist that has already been round the loop once.
class _RoundBadge extends StatelessWidget {
  const _RoundBadge({required this.round});

  final int round;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: _T.violet.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay_rounded, size: 12, color: _T.violet),
            const SizedBox(width: 5),
            Text(
              'Round $round · post-assessment',
              style: _T.label(
                  size: 10.5, weight: FontWeight.w800, color: _T.violet),
            ),
          ],
        ),
      );
}

// ─── Email / phone row ────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: _T.txt3),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _T.label(size: 11, color: _T.txt2),
          ),
        ),
      ],
    );
  }
}

// ─── Segmented pipeline progress bar ─────────────────────────────────────────
class _PipelineBar extends StatelessWidget {
  final int index, total;
  final Color color;

  const _PipelineBar({
    required this.index,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: List.generate(total, (i) {
          final active = i <= index;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOut,
              height: 4,
              margin: EdgeInsets.only(right: i < total - 1 ? 3 : 0),
              decoration: BoxDecoration(
                color: active ? color : _T.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CVSheet extends StatelessWidget {
  final Map<String, dynamic> cand;
  final List<MapEntry<String, String>> Function(dynamic) namedLinks;
  final List<String> Function(dynamic) urlList;
  final List<String> Function(dynamic) strList;
  final String Function(dynamic, [String]) str;
  final Map<String, dynamic> Function(dynamic) norm;

  const _CVSheet({
    required this.cand,
    required this.namedLinks,
    required this.urlList,
    required this.strList,
    required this.str,
    required this.norm,
  });

  @override
  Widget build(BuildContext ctx) {
    debugPrint('🔍 _CVSheet.build — ${cand.keys.length} keys received');
    // ── Flat field extraction (matches the real DB schema) ─────────────────
    final name = str(cand['name'], 'Unknown');
    final email = str(cand['email']);
    final phone = str(cand['phone']);
    final picUrl = str(cand['picture_url']);
    final nationality = str(cand['nationality']);
    final dob = str(cand['dob']);
    final location = str(cand['location']);
    final secEmail = str(cand['secondary_email']);
    final retDate = str(cand['retirement_date']);
    final summary = str(cand['summary']);
    final objectives = str(cand['objectives']);
    final company = str(cand['company']);
    final jobTitle = str(cand['job_title']);
    final currentRole = str(cand['current_role']);
    final profStatus = str(cand['professional_status']);
    // Three separate measures, never merged. `years_experience` is a duration
    // the recruiter's request already computed; `roles_listed` is a count.
    final serviceYears = _numOrNull(cand['years_experience']);
    final rolesListed = _numOrNull(cand['roles_listed']);
    final flightHours = _numOrNull(cand['flight_hours']);
    final education = str(cand['education']);
    final university = str(cand['university']);
    final eduDur = str(cand['education_duration']);

    final skills = strList(cand['skills']);
    final socialLinks = urlList(cand['social_links'] ?? cand['socialLinks']);
    final awards = strList(cand['awards']);
    final publications = strList(cand['publications']);

    final eduList =
        (cand['educationalProfile'] is List
                ? (cand['educationalProfile'] as List)
                : [])
            .map((e) => norm(e))
            .toList();
    final expList =
        (cand['professionalExperience'] is List
                ? (cand['professionalExperience'] as List)
                : [])
            .map((e) => norm(e))
            .toList();
    final certList =
        (cand['certifications'] is List ? (cand['certifications'] as List) : [])
            .map((e) => norm(e))
            .toList();

    // experienceDocuments: [{"NOC": "url"}, {"Letter": "url"}]
    final expDocs = namedLinks(
      cand['experienceDocuments'] ?? cand['experience_documents'],
    );
    // certificationDocuments: ["url", ...] or [{"Label":"url"}]
    final certDocs = namedLinks(
      cand['certificationDocuments'] ?? cand['certification_documents'],
    );

    // Role-template answers, carried verbatim from the recruiter's payload so
    // the admin reviews the same fields the recruiter screened on.
    final roleProfile = RoleProfileSnapshot.fromJson(
      cand['role_profile'] is Map
          ? Map<String, dynamic>.from(cand['role_profile'] as Map)
          : null,
    );

    // match_score
    final ms = norm(cand['match_score']);
    final hasScore = ms.isNotEmpty && ms['overallScore'] != null;
    final overallSc = ms['overallScore'];
    final rec = str(ms['recommendation']);
    final strengths = strList(ms['strengths']);
    final weaknesses = strList(ms['weaknesses']);
    final analysis = str(ms['detailedAnalysis']);
    final skillMatch = ms['skillsMatch'];
    final eduMatch = ms['educationMatch'];
    final expMatch = ms['experienceMatch'];

    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            children: [
              // ── Header Area (Dark) ──
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    // drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 4),
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header Info
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 14, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Avatar(
                            name: name,
                            size: 68,
                            imageUrl: picUrl.isNotEmpty ? picUrl : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  name.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .4,
                                  ),
                                ),
                                if (jobTitle.isNotEmpty ||
                                    currentRole.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    jobTitle.isNotEmpty
                                        ? jobTitle
                                        : currentRole,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF43E0D2),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                if (company.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.business_outlined,
                                        color: Colors.white38,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        company,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 6,
                                  children: [
                                    if (email.isNotEmpty)
                                      _HdrItem(Icons.email_outlined, email),
                                    if (phone.isNotEmpty)
                                      _HdrItem(
                                        Icons.phone_android_outlined,
                                        phone,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white60,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ──
              Expanded(
                child: CustomScrollView(
                  controller: sc,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 60),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Personal ──
                            // Every row below is individually optional, so the
                            // header would otherwise stand alone over nothing
                            // for a candidate whose detail all lives in the
                            // role template.
                            if (nationality.isNotEmpty ||
                                dob.isNotEmpty ||
                                location.isNotEmpty ||
                                retDate.isNotEmpty ||
                                secEmail.isNotEmpty ||
                                summary.isNotEmpty ||
                                objectives.isNotEmpty)
                            _Sec('PERSONAL', Icons.person_outline, _C.primary, [
                              _Row2(
                                nationality.isNotEmpty
                                    ? _InfoTile('Nationality', nationality)
                                    : null,
                                dob.isNotEmpty
                                    ? _InfoTile('Date of Birth', dob)
                                    : null,
                              ),
                              _Row2(
                                location.isNotEmpty
                                    ? _InfoTile('Location', location)
                                    : null,
                                retDate.isNotEmpty
                                    ? _InfoTile('Retirement Date', retDate)
                                    : null,
                              ),
                              if (secEmail.isNotEmpty)
                                _CVRow('Alt Email', secEmail),
                              if (summary.isNotEmpty)
                                _CVRow('Summary', summary),
                              if (objectives.isNotEmpty)
                                _CVRow('Objectives', objectives),
                            ]),

                            // ── Professional Status ──
                            //
                            // Service length, roles listed and flight hours are
                            // three different measurements in three different
                            // units. They each get their own tile and their own
                            // label; the bug this replaces was one number shown
                            // under another one's name. CGPA is not here — it
                            // belongs to a specific degree and is rendered with
                            // that degree in the education list below.
                            if (serviceYears != null ||
                                rolesListed != null ||
                                flightHours != null ||
                                profStatus.isNotEmpty ||
                                currentRole.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'PROFESSIONAL STATUS',
                                Icons.work_outline,
                                const Color(0xFF2EC4B6),
                                [
                                  _Row2(
                                    currentRole.isNotEmpty
                                        ? _InfoTile('Current Role', currentRole)
                                        : null,
                                    profStatus.isNotEmpty
                                        ? _InfoTile('Status', profStatus)
                                        : null,
                                  ),
                                  _Row2(
                                    serviceYears != null
                                        ? _InfoTile(
                                            'Service Length',
                                            ServiceYears.label(serviceYears),
                                          )
                                        : (rolesListed != null
                                            ? _InfoTile(
                                                'Service Length',
                                                'No dated roles on file',
                                              )
                                            : null),
                                    rolesListed != null
                                        ? _InfoTile(
                                            'Roles Listed',
                                            '${rolesListed.toInt()}',
                                          )
                                        : null,
                                  ),
                                  _Row2(
                                    flightHours != null
                                        ? _InfoTile(
                                            'Flight Hours',
                                            '${flightHours.toInt()}',
                                          )
                                        : null,
                                    null,
                                  ),
                                ],
                              ),
                            ],

                            // ── Match Score ──
                            if (hasScore) ...[
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics_outlined,
                                    color: const Color(0xFF2178B5),
                                    size: 17,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'MATCH SCORE',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _C.txt1,
                                      letterSpacing: 1.4,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Divider(height: 1, color: _C.border),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _MatchScoreCard(
                                overall: overallSc,
                                recommendation: rec,
                                skillMatch: skillMatch,
                                eduMatch: eduMatch,
                                expMatch: expMatch,
                                strengths: strengths,
                                weaknesses: weaknesses,
                                analysis: analysis,
                              ),
                            ],

                            // ── Role Profile ──
                            if (!roleProfile.isEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'ROLE PROFILE',
                                Icons.badge_outlined,
                                _C.primary,
                                [
                                  // Admins run the candidate's paperwork and
                                  // travel, so they see everything.
                                  RoleProfileView(
                                    snapshot: roleProfile,
                                    dense: true,
                                    canViewContactInfo: true,
                                  ),
                                ],
                              ),
                            ],

                            // ── Skills ──
                            if (skills.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'SKILLS',
                                Icons.auto_awesome_outlined,
                                _C.success,
                                [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: skills
                                        .map(
                                          (s) => _TextChip(
                                            text: s,
                                            color: _C.success,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ],

                            // ── Social Links ──
                            if (socialLinks.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'SOCIAL LINKS',
                                Icons.link_rounded,
                                const Color(0xFF15A99C),
                                [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: socialLinks
                                        .map(
                                          (l) => _LinkChip(
                                            label: _U.hostLabel(l),
                                            url: l,
                                            icon: _U.icon(l),
                                            color: const Color(0xFF15A99C),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ],

                            // ── Experience ──
                            if (expList.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'EXPERIENCE',
                                Icons.business_center_outlined,
                                const Color(0xFF2178B5),
                                expList.map(_ExpCard.new).toList(),
                              ),
                            ],

                            // ── Education (structured) ──
                            if (eduList.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'EDUCATION',
                                Icons.school_outlined,
                                _C.warning,
                                eduList.map(_EduCard.new).toList(),
                              ),
                            ] else if (education.isNotEmpty ||
                                university.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'EDUCATION',
                                Icons.school_outlined,
                                _C.warning,
                                [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _C.warningLt,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _C.warning.withValues(alpha: .2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (university.isNotEmpty)
                                          Text(
                                            university,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: _C.txt1,
                                            ),
                                          ),
                                        if (education.isNotEmpty)
                                          Text(
                                            education,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: _C.warning,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if (eduDur.isNotEmpty)
                                          Text(
                                            eduDur,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: _C.txt3,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // ── Certifications ──
                            if (certList.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'CERTIFICATIONS',
                                Icons.verified_outlined,
                                const Color(0xFFFF7A59),
                                certList
                                    .map(
                                      (c) => _CertCard(
                                        title: str(
                                          c['name'],
                                          str(
                                            c['certificationName'],
                                            'Certification',
                                          ),
                                        ),
                                        subtitle: str(
                                          c['organization'],
                                          str(c['issuingAuthority']),
                                        ),
                                        issueDate: str(c['issueDate']),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],

                            // ── Experience Documents (named links) ──
                            if (expDocs.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'EXPERIENCE DOCUMENTS',
                                Icons.folder_outlined,
                                const Color(0xFF15A99C),
                                [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: expDocs
                                        .map(
                                          (e) => _LinkChip(
                                            label: e.key,
                                            url: e.value,
                                            icon: Icons.description_outlined,
                                            color: const Color(0xFF15A99C),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ],

                            // ── Certification Documents ──
                            if (certDocs.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'CERTIFICATION DOCUMENTS',
                                Icons.workspace_premium_outlined,
                                const Color(0xFFFF7A59),
                                [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: certDocs
                                        .map(
                                          (e) => _LinkChip(
                                            label: e.key,
                                            url: e.value,
                                            icon: Icons.verified_outlined,
                                            color: const Color(0xFFFF7A59),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ],

                            // ── Awards ──
                            if (awards.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'AWARDS',
                                Icons.emoji_events_outlined,
                                const Color(0xFFF59E0B),
                                [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: awards
                                        .map(
                                          (a) => _TextChip(
                                            text: a,
                                            color: const Color(0xFFF59E0B),
                                            icon: Icons.star_rounded,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ],

                            // ── Publications ──
                            if (publications.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _Sec(
                                'PUBLICATIONS',
                                Icons.article_outlined,
                                const Color(0xFF2178B5),
                                [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: publications
                                        .map(
                                          (p) => _TextChip(
                                            text: p,
                                            color: const Color(0xFF2178B5),
                                            icon: Icons.article_outlined,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ],
                          ],
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
}

// ═════════════════════════════════════════════════════════════════════════════
//  CV ATOM WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _HdrItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HdrItem(this.icon, this.text);
  @override
  Widget build(BuildContext ctx) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white38, size: 13),
      const SizedBox(width: 6),
      Flexible(
        child: SelectableText(
          text,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12),
        ),
      ),
    ],
  );
}

/// Section header + indented body
class _Sec extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  const _Sec(this.title, this.icon, this.color, this.children);

  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _C.txt1,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Divider(height: 1, color: _C.border)),
        ],
      ),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.only(left: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    ],
  );
}

/// Two-column info row — either widget may be null
class _Row2 extends StatelessWidget {
  final Widget? left, right;
  const _Row2(this.left, this.right);

  @override
  Widget build(BuildContext ctx) {
    if (left == null && right == null) return const SizedBox.shrink();
    if (right == null) {
      return Padding(padding: const EdgeInsets.only(bottom: 10), child: left!);
    }
    if (left == null) {
      return Padding(padding: const EdgeInsets.only(bottom: 10), child: right!);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left!),
          const SizedBox(width: 12),
          Expanded(child: right!),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile(this.label, this.value);
  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _C.txt3,
          letterSpacing: .8,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: _C.txt2,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _CVRow extends StatelessWidget {
  final String label, value;
  const _CVRow(this.label, this.value);
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _C.txt3,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: _C.txt2,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

/// Plain text chip — publications, skills, awards
class _TextChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const _TextChip({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: .22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 230),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Clickable link chip — label is front-facing, url is the backend
class _LinkChip extends StatelessWidget {
  final String label, url;
  final IconData icon;
  final Color color;
  const _LinkChip({
    required this.label,
    required this.url,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext ctx) => Tooltip(
    message: url,
    waitDuration: const Duration(milliseconds: 500),
    child: InkWell(
      onTap: () {
        final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: color.withValues(alpha: .4),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new_rounded,
              size: 11,
              color: color.withValues(alpha: .5),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MATCH SCORE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _MatchScoreCard extends StatelessWidget {
  final dynamic overall, skillMatch, eduMatch, expMatch;
  final String recommendation, analysis;
  final List<String> strengths, weaknesses;

  const _MatchScoreCard({
    required this.overall,
    required this.recommendation,
    required this.skillMatch,
    required this.eduMatch,
    required this.expMatch,
    required this.strengths,
    required this.weaknesses,
    required this.analysis,
  });

  Color _col(dynamic v) {
    final n = int.tryParse(v?.toString() ?? '') ?? 0;
    if (n >= 70) return _C.success;
    if (n >= 40) return _C.warning;
    return _C.danger;
  }

  @override
  Widget build(BuildContext ctx) {
    final col = _col(overall);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top row: circle + sub-scores ──
        Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: col.withValues(alpha: .1),
                border: Border.all(color: col.withValues(alpha: .3), width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$overall',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: col,
                      ),
                    ),
                    Text(
                      '%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: col,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recommendation.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: col.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        recommendation,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: col,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Sub('Skills', skillMatch, const Color(0xFF2178B5)),
                      const SizedBox(width: 12),
                      _Sub('Education', eduMatch, _C.warning),
                      const SizedBox(width: 12),
                      _Sub('Experience', expMatch, const Color(0xFF2EC4B6)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Strengths ──
        if (strengths.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: _C.border),
          const SizedBox(height: 10),
          Text(
            'STRENGTHS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: _C.success,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 6),
          ...strengths.map(
            (s) =>
                _BulletRow(s, _C.success, Icons.check_circle_outline_rounded),
          ),
        ],

        // ── Weaknesses ──
        if (weaknesses.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'WEAKNESSES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: _C.danger,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 6),
          ...weaknesses.map(
            (w) => _BulletRow(w, _C.danger, Icons.highlight_off_rounded),
          ),
        ],

        // ── Analysis ──
        if (analysis.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Divider(height: 1, color: _C.border),
          const SizedBox(height: 8),
          Text(
            'ANALYSIS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: _C.txt3,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
          SelectableText(
            analysis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: _C.txt2,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _Sub extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;
  const _Sub(this.label, this.value, this.color);
  @override
  Widget build(BuildContext ctx) => Column(
    children: [
      Text(
        '$value%',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 9, color: _C.txt3),
      ),
    ],
  );
}

class _BulletRow extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _BulletRow(this.text, this.color, this.icon);
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: _C.txt2,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  EXPERIENCE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ExpCard extends StatelessWidget {
  final Map<String, dynamic> exp;
  const _ExpCard(this.exp);
  @override
  Widget build(BuildContext ctx) {
    final role =
        exp['role']?.toString() ??
        exp['jobTitle']?.toString() ??
        exp['position']?.toString() ??
        'Role';
    final org =
        exp['organization']?.toString() ??
        exp['companyName']?.toString() ??
        exp['company']?.toString() ??
        '';
    final start = exp['startDate']?.toString() ?? '';
    final end = exp['endDate']?.toString();
    final dur = exp['duration']?.toString().isNotEmpty == true
        ? exp['duration'].toString()
        : '$start – ${(end?.isNotEmpty == true) ? end : 'Present'}';
    final duties = exp['duties']?.toString() ?? exp['text']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _C.txt1,
            ),
          ),
          if (org.isNotEmpty)
            Text(
              org,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF2178B5),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            dur,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _C.txt3),
          ),
          if (duties.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              duties,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _C.txt2,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EDUCATION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _EduCard extends StatelessWidget {
  final Map<String, dynamic> edu;
  const _EduCard(this.edu);
  @override
  Widget build(BuildContext ctx) {
    final deg =
        edu['degree']?.toString() ??
        edu['majorSubjects']?.toString() ??
        'Degree';
    final inst =
        edu['institution']?.toString() ??
        edu['institutionName']?.toString() ??
        '';
    final dur = edu['duration']?.toString() ?? '';
    final cgpa =
        edu['marksOrCgpa']?.toString() ?? edu['cgpa']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.warningLt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.warning.withValues(alpha: .2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inst.isNotEmpty)
            Text(
              inst,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _C.txt1,
              ),
            ),
          Text(
            deg,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: _C.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (dur.isNotEmpty || cgpa.isNotEmpty)
            Row(
              children: [
                if (dur.isNotEmpty)
                  Text(
                    dur,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _C.txt3,
                    ),
                  ),
                if (dur.isNotEmpty && cgpa.isNotEmpty)
                  Text(
                    '  •  ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _C.txt4,
                    ),
                  ),
                if (cgpa.isNotEmpty)
                  Text(
                    cgpa,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: _C.txt3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CERT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _CertCard extends StatelessWidget {
  final String title, subtitle, issueDate;
  const _CertCard({
    required this.title,
    this.subtitle = '',
    this.issueDate = '',
  });
  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1EC),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFFF7A59).withValues(alpha: .2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_rounded, color: Color(0xFFFF7A59), size: 15),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _C.txt1,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: _C.txt2,
                  ),
                ),
              if (issueDate.isNotEmpty)
                Text(
                  'Issued: $issueDate',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: _C.txt3,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
