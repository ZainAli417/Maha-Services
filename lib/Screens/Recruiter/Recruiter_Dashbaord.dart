import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:job_portal/Screens/Recruiter/R_Top_Bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'Recruiter_provider_Job_listing.dart';
import '../../Constant/js_header.dart';
import '../../core/interviews/interview.dart';
import '../../core/interviews/interview_calendar.dart';
import '../../core/interviews/interview_provider.dart';

// ─── Design Tokens (navy + teal brand) ──────────────────────────────────────
const _navy = Color(0xFF0A2E4F);
const _blue = Color(0xFF14507F);
const _blueLight = Color(0xFF2EC4B6);
const _cyan = Color(0xFF2178B5);
const _emerald = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);
const _rose = Color(0xFFEF4444);
const _violet = Color(0xFF15A99C);
const _slate50 = Color(0xFFF4F9FB);
const _slate100 = Color(0xFFF1F5F9);
const _slate200 = Color(0xFFDCE7EF);
const _slate400 = Color(0xFF8AA5B5);
const _slate600 = Color(0xFF5E7A8E);
const _slate900 = Color(0xFF0B2239);
const _white = Color(0xFFFFFFFF);

// ─── Main Dashboard ───────────────────────────────────────────────────────────
class Dashboard_Recruiter extends StatefulWidget {
  const Dashboard_Recruiter({super.key});
  @override
  State<Dashboard_Recruiter> createState() => _Dashboard_RecruiterState();
}

class _Dashboard_RecruiterState extends State<Dashboard_Recruiter>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _slate50,
      drawer: isMobile
          ? Drawer(child: RecruiterSidebar(activeIndex: 0, isDrawer: true))
          : null,
      body: Row(
        children: [
          if (!isMobile) RecruiterSidebar(activeIndex: 0),
          Expanded(
            child: FadeTransition(
              opacity: _fadeCtrl,
              child: Column(
                children: [
                  _RecruiterDashboardTopBar(
                    scaffoldKey: _scaffoldKey,
                  ),
                  Expanded(
                    child: Consumer<job_listing_provider>(
                      builder: (context, provider, _) {
                        if (!provider.isInitialized) {
                          return const _LoadingView();
                        }
                        final jobs = provider.allOwnedJobList;
                        if (jobs.isEmpty) return const _EmptyView();
                        return _AnalyticsDashboard(jobs: jobs);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} // End of _Dashboard_RecruiterState

class _RecruiterDashboardTopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _RecruiterDashboardTopBar({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return JobSeekerHeader(
      icon: Icons.recent_actors_rounded,
      title: 'Recruiter Dashboard',
      subtitle: 'Hiring analytics & job status overview',
      onMenu: () => scaffoldKey.currentState?.openDrawer(),
      trailing: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/post-job'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2EC4B6).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 5),
                Text(
                  'Post',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mobile App Bar ───────────────────────────────────────────────────────────

// ─── State Views ──────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: const AlwaysStoppedAnimation(_blue),
            backgroundColor: _blue.withValues(alpha: 0.12),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Loading analytics…',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _slate600),
        ),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _rose.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _rose.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _rose.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: _rose,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Something went wrong',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _slate600),
          ),
        ],
      ),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _blue.withValues(alpha: 0.08),
                _cyan.withValues(alpha: 0.08),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.work_outline_rounded, size: 48, color: _blue),
        ),
        const SizedBox(height: 18),
        Text(
          'No Jobs Posted Yet',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _slate900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Post your first job to see analytics here',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _slate600),
        ),
      ],
    ),
  );
}

// ─── Analytics Dashboard ──────────────────────────────────────────────────────
class _AnalyticsDashboard extends StatefulWidget {
  final List<Map<String, dynamic>> jobs;
  const _AnalyticsDashboard({required this.jobs});

  @override
  State<_AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<_AnalyticsDashboard> {
  final _scroll = ScrollController();
  final _jobCache = <String, Future<DocumentSnapshot>>{};
  bool _lockScroll = false;
  bool _isRefreshing = false;
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
      _jobCache.clear();
      _dataFuture = _fetchData();
    });
    await _dataFuture;
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    Widget scrollView = FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snap) {
        final loading = !snap.hasData;
        final data = snap.data ?? {};

        return CustomScrollView(
          controller: _scroll,
          physics: isMobile
              ? const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                )
              : (_lockScroll
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics()),
          slivers: [
            // Pull-to-refresh hint — mobile only
            if (isMobile)
              SliverToBoxAdapter(
                child: AnimatedOpacity(
                  opacity: _isRefreshing ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 13,
                          color: _slate400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pull down to refresh',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _slate400,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Stats
            SliverToBoxAdapter(
              child: loading
                  ? _shimmerStats(isMobile)
                  : _buildStats(data, isMobile),
            ),

            // Interviews. Placed above the charts because a booking today is
            // more urgent than a trend this quarter, and the awaiting-link
            // state is something the recruiter has to chase.
            SliverToBoxAdapter(child: _buildInterviews(isMobile)),

            // Charts
            SliverToBoxAdapter(
              child: loading
                  ? _shimmerCharts(isMobile)
                  : _buildCharts(data, isMobile),
            ),

            if (!loading)
              SliverToBoxAdapter(child: _buildArchivedJobs(isMobile)),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );

    // Wrap in RefreshIndicator on mobile
    if (isMobile) {
      scrollView = RefreshIndicator(
        onRefresh: _refresh,
        color: _blue,
        backgroundColor: _white,
        strokeWidth: 2.5,
        child: scrollView,
      );
    }

    return scrollView;
  }

  // ─── Interview Calendar ─────────────────────────────────────────────────
  Widget _buildInterviews(bool isMobile) {
    final provider = context.watch<InterviewProvider>();
    final upcoming = provider.upcoming;
    final awaitingLink = upcoming
        .where((i) => i.status == InterviewStatus.requested)
        .length;

    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 28, 8, isMobile ? 16 : 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 18, color: _blue),
              const SizedBox(width: 9),
              Text(
                'Interview schedule',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _slate900,
                ),
              ),
              const SizedBox(width: 10),
              if (upcoming.isNotEmpty)
                _Pill(
                  text: '${upcoming.length} upcoming',
                  color: _blue,
                ),
              if (awaitingLink > 0) ...[
                const SizedBox(width: 6),
                _Pill(
                  text: '$awaitingLink awaiting link',
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          InterviewCalendar(compact: isMobile),
        ],
      ),
    );
  }

  // ─── Stats Cards ────────────────────────────────────────────────────────
  Widget _buildStats(Map<String, dynamic> data, bool isMobile) {
    final totalJobs = data['totalJobs'] ?? 0;
    final openJobs = data['openJobs'] ?? 0;
    final archivedJobs = data['archivedJobs'] ?? 0;
    final total = data['totalApplicants'] ?? 0;
    final pending = data['pending'] ?? 0;
    final shortlist = data['shortlist'] ?? 0;

    final cards = [
      _StatMeta(
        'Total Jobs',
        totalJobs.toString(),
        Icons.work_outline_rounded,
        _blue,
        'All postings',
      ),
      _StatMeta(
        'Open',
        openJobs.toString(),
        Icons.radio_button_checked_rounded,
        _emerald,
        'Visible jobs',
      ),
      _StatMeta(
        'Archived',
        archivedJobs.toString(),
        Icons.archive_outlined,
        _slate600,
        'Hidden jobs',
      ),
      _StatMeta(
        'Applicants',
        total.toString(),
        Icons.people_alt_outlined,
        _cyan,
        'All applicants',
      ),
      _StatMeta(
        'Pending',
        pending.toString(),
        Icons.hourglass_top_rounded,
        _amber,
        'Needs review',
      ),
      _StatMeta(
        'Shortlisted',
        shortlist.toString(),
        Icons.star_rounded,
        _violet,
        'Interview stage',
      ),
    ];

    final pad = EdgeInsets.fromLTRB(
      isMobile ? 14 : 32,
      isMobile ? 12 : 20,
      isMobile ? 14 : 32,
      isMobile ? 12 : 16,
    );

    if (isMobile) {
      return Padding(
        padding: pad,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.35,
          ),
          itemBuilder: (context, index) =>
              _StatCard(meta: cards[index], isMobile: true),
        ),
      );
    }

    return Padding(
      padding: pad,
      child: Row(
        children: cards
            .asMap()
            .entries
            .map(
              (e) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: e.key < cards.length - 1 ? 14 : 0,
                  ),
                  child: _StatCard(meta: e.value, isMobile: false),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildArchivedJobs(bool isMobile) {
    final archived = widget.jobs.where((job) {
      final status = (job['status'] ?? 'active').toString().toLowerCase();
      return status == 'archived' || status == 'archive';
    }).toList();

    if (archived.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 32,
        0,
        isMobile ? 14 : 32,
        16,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              title: 'Archived Jobs',
              subtitle: 'Hidden from job seekers and active hiring tools',
              isMobile: isMobile,
              badge: archived.length.toString(),
              badgeColor: _slate600,
            ),
            const SizedBox(height: 12),
            ...archived.take(5).map((job) => _ArchivedJobRow(job: job)),
            if (archived.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${archived.length - 5} more archived jobs',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: _slate600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Charts Layout ───────────────────────────────────────────────────────
  Widget _buildCharts(Map<String, dynamic> data, bool isMobile) {
    final hPad = isMobile ? 14.0 : 32.0;

    if (isMobile) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Column(
          children: [
            _TrendChart(data: data, isMobile: true),
            const SizedBox(height: 14),
            _StatusPie(data: data, isMobile: true),
            const SizedBox(height: 14),
            _TopSkillsCard(
              data: data,
              isMobile: true,
              onLockScroll: (v) => setState(() => _lockScroll = v),
            ),
            const SizedBox(height: 14),
            _TopJobsCard(data: data, isMobile: true, cache: _jobCache),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
      child: Column(
        children: [
          SizedBox(
            height: 320,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _TrendChart(data: data, isMobile: false),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _StatusPie(data: data, isMobile: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 360,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _TopSkillsCard(
                    data: data,
                    isMobile: false,
                    onLockScroll: (v) => setState(() => _lockScroll = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _TopJobsCard(
                    data: data,
                    isMobile: false,
                    cache: _jobCache,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shimmer placeholders ────────────────────────────────────────────────
  Widget _shimmerStats(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 14 : 32),
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _ShimmerBox(height: 78, radius: 16)),
                    const SizedBox(width: 10),
                    Expanded(child: _ShimmerBox(height: 78, radius: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                _ShimmerBox(height: 78, radius: 16),
              ],
            )
          : Row(
              children: List.generate(
                6,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 5 ? 14 : 0),
                    child: _ShimmerBox(height: 110, radius: 18),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _shimmerCharts(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 32),
      child: Column(
        children: [
          _ShimmerBox(height: isMobile ? 260 : 300, radius: 18),
          const SizedBox(height: 14),
          _ShimmerBox(height: 240, radius: 18),
        ],
      ),
    );
  }

  // ─── Data fetch ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _fetchData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      // The orderBy is not cosmetic: an equality filter on a collection group
      // with no ordering needs a COLLECTION_GROUP-scoped single-field index,
      // which Firestore does not create automatically. Ordering by appliedAt
      // makes this reuse the (recruiterUid, appliedAt) composite index the
      // applicant list already relies on, so the dashboard needs no index of
      // its own.
      final snap = await FirebaseFirestore.instance
          .collectionGroup('applied_jobs')
          .where('recruiterUid', isEqualTo: uid)
          .orderBy('appliedAt', descending: true)
          .get();

      int total = snap.docs.length;
      int pending = 0, accepted = 0, rejected = 0, shortlist = 0;
      final skillsCount = <String, int>{};
      final jobCount = <String, int>{};
      final daily = <DateTime, int>{};

      for (var doc in snap.docs) {
        final d = doc.data();
        switch ((d['status']?.toString().toLowerCase() ?? 'pending')) {
          case 'accepted':
            accepted++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'shortlist':
            shortlist++;
            break;
          default:
            pending++;
        }
        final jid = d['jobId']?.toString() ?? '';
        if (jid.isNotEmpty) jobCount[jid] = (jobCount[jid] ?? 0) + 1;

        final snapshot =
            ((d['profileSnapshot'] as Map?) ?? {})['candidate_profile'] as Map?;
        final personal = snapshot?['personalInfo'] as Map?;
        final roleData = snapshot?['roleSpecificData'] as Map?;
        // Free-form skills plus the template's competencies and tools: the
        // chart is meant to show what this pool can do, and templated roles
        // put most of that in the role data.
        for (final s in [
          ...(personal?['skills'] as List? ?? const []),
          ...(roleData?['technicalCompetencies'] as List? ?? const []),
          ...(roleData?['toolsAndSystems'] as List? ?? const []),
        ]) {
          final sk = s.toString();
          skillsCount[sk] = (skillsCount[sk] ?? 0) + 1;
        }

        final at = d['appliedAt'];
        if (at is Timestamp) {
          final dt = at.toDate();
          final day = DateTime(dt.year, dt.month, dt.day);
          daily[day] = (daily[day] ?? 0) + 1;
        }
      }

      final topSkills =
          (skillsCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(10)
              .toList();
      final topJobs =
          (jobCount.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .take(5)
              .toList();
      final totalJobs = widget.jobs.length;
      final archivedJobs = widget.jobs.where((job) {
        final status = (job['status'] ?? 'active').toString().toLowerCase();
        return status == 'archived' || status == 'archive';
      }).length;
      final pausedJobs = widget.jobs.where((job) {
        final status = (job['status'] ?? 'active').toString().toLowerCase();
        return status == 'paused';
      }).length;
      final openJobs = max(0, totalJobs - archivedJobs - pausedJobs);

      final sortedDays = daily.keys.toList()..sort();
      int cum = 0;
      final spots = <FlSpot>[];
      for (int i = 0; i < sortedDays.length; i++) {
        cum += daily[sortedDays[i]] ?? 0;
        spots.add(FlSpot(i.toDouble(), cum.toDouble()));
      }

      return {
        'totalApplicants': total,
        'pending': pending,
        'accepted': accepted,
        'rejected': rejected,
        'shortlist': shortlist,
        'totalJobs': totalJobs,
        'openJobs': openJobs,
        'pausedJobs': pausedJobs,
        'archivedJobs': archivedJobs,
        'topSkills': topSkills,
        'topJobs': topJobs,
        'trendData': spots,
        'dates': sortedDays,
      };
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
      return {};
    }
  }
}

class _ArchivedJobRow extends StatelessWidget {
  final Map<String, dynamic> job;

  const _ArchivedJobRow({required this.job});

  @override
  Widget build(BuildContext context) {
    final title = (job['title'] ?? 'Untitled job').toString();
    final company = (job['company'] ?? 'Unknown company').toString();
    final applications = job['applicationCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _slate200),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _slate600.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.archive_outlined,
              size: 18,
              color: _slate600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$company • $applications applicants',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: _slate600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _slate600.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Archived',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Post Job Button ──────────────────────────────────────────────────────────
class _PostJobButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/post-job'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_blue, _blueLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: _white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Post',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Meta ────────────────────────────────────────────────────────────────
class _StatMeta {
  final String label, value, subtitle;
  final IconData icon;
  final Color color;
  const _StatMeta(this.label, this.value, this.icon, this.color, this.subtitle);
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final _StatMeta meta;
  final bool isMobile;
  const _StatCard({required this.meta, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _slate200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.icon, color: meta.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _slate900,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    meta.label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _slate600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Desktop vertical card
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(meta.icon, color: meta.color, size: 20),
              ),
              // accent bar
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            meta.value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _slate900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _slate900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            meta.subtitle,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _slate400),
          ),
        ],
      ),
    );
  }
}

// ─── Trend Chart ──────────────────────────────────────────────────────────────
class _TrendChart extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMobile;
  const _TrendChart({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final spots = data['trendData'] as List<FlSpot>? ?? [];
    final dates = data['dates'] as List<DateTime>? ?? [];

    return _ChartCard(
      isMobile: isMobile,
      height: isMobile ? 260 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Application Trends',
            subtitle: 'Cumulative applicants over time',
            isMobile: isMobile,
            badge: spots.isEmpty ? null : '${dates.length} day(s)',
            badgeColor: _blue,
          ),
          SizedBox(height: isMobile ? 14 : 20),
          Expanded(
            child: spots.isEmpty
                ? _EmptyHint(message: 'No trend data yet', isMobile: isMobile)
                : LineChart(_lineData(spots, dates)),
          ),
        ],
      ),
    );
  }

  LineChartData _lineData(List<FlSpot> spots, List<DateTime> dates) {
    final maxY = spots.map((s) => s.y).reduce(max) * 1.25;
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: _slate200, strokeWidth: 1, dashArray: [4, 4]),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: isMobile ? 28 : 36,
            getTitlesWidget: (v, m) => Text(
              '${v.toInt()}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 9 : 10,
                color: _slate400,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: max(
              1,
              (spots.length / (isMobile ? 4 : 6)).ceil(),
            ).toDouble(),
            getTitlesWidget: (v, m) {
              final i = v.toInt();
              if (i < 0 || i >= dates.length) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  DateFormat(isMobile ? 'M/d' : 'MMM d').format(dates[i]),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 9 : 10,
                    color: _slate400,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.4,
          color: _blue,
          barWidth: isMobile ? 2.5 : 3,
          dotData: FlDotData(
            show: spots.length < 15,
            getDotPainter: (s, p, b, i) => FlDotCirclePainter(
              radius: 3.5,
              color: _blue,
              strokeWidth: 2,
              strokeColor: _white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _blue.withValues(alpha: 0.16),
                _blue.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => _navy,
          tooltipBorderRadius: BorderRadius.circular(10),
          getTooltipItems: (ts) => ts.map((t) {
            final i = t.x.toInt();
            final d = i < dates.length
                ? DateFormat('MMM d').format(dates[i])
                : '';
            return LineTooltipItem(
              '$d\n${t.y.toInt()} total',
              GoogleFonts.plusJakartaSans(
                color: _white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Status Pie ───────────────────────────────────────────────────────────────
class _StatusPie extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMobile;
  const _StatusPie({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final pending = (data['pending'] ?? 0) as int;
    final accepted = (data['accepted'] ?? 0) as int;
    final rejected = (data['rejected'] ?? 0) as int;
    final shortlist = (data['shortlist'] ?? 0) as int;
    final total = pending + accepted + rejected + shortlist;

    return _ChartCard(
      isMobile: isMobile,
      height: isMobile ? 250 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Status Breakdown',
            subtitle: 'Application pipeline',
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 14 : 20),
          Expanded(
            child: total == 0
                ? _EmptyHint(message: 'No applicants yet', isMobile: isMobile)
                : Row(
                    children: [
                      Expanded(
                        flex: isMobile ? 5 : 4,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              _pieSection(_amber, pending, total),
                              _pieSection(_emerald, accepted, total),
                              _pieSection(_rose, rejected, total),
                              _pieSection(_violet, shortlist, total),
                            ],
                            centerSpaceRadius: isMobile ? 28 : 38,
                            sectionsSpace: 3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: isMobile ? 4 : 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PieLegend('Pending', pending, _amber, isMobile),
                            _PieLegend(
                              'Accepted',
                              accepted,
                              _emerald,
                              isMobile,
                            ),
                            _PieLegend('Rejected', rejected, _rose, isMobile),
                            _PieLegend(
                              'Shortlisted',
                              shortlist,
                              _violet,
                              isMobile,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _pieSection(Color color, int value, int total) {
    final pct = total == 0 ? 0 : (value / total * 100).round();
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: value == 0 ? '' : '$pct%',
      radius: isMobile ? 34 : 44,
      titleStyle: GoogleFonts.plusJakartaSans(
        fontSize: isMobile ? 9 : 11,
        fontWeight: FontWeight.w700,
        color: _white,
      ),
    );
  }
}

class _PieLegend extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isMobile;
  const _PieLegend(this.label, this.value, this.color, this.isMobile);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 11 : 12,
                color: _slate600,
              ),
            ),
          ),
          Text(
            '$value',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: _slate900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Skills ───────────────────────────────────────────────────────────────
class _TopSkillsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMobile;
  final ValueChanged<bool> onLockScroll;
  const _TopSkillsCard({
    required this.data,
    required this.isMobile,
    required this.onLockScroll,
  });

  @override
  Widget build(BuildContext context) {
    final skills = data['topSkills'] as List<MapEntry<String, int>>? ?? [];
    final maxVal = skills.isEmpty ? 1.0 : skills.first.value.toDouble();

    return _ChartCard(
      isMobile: isMobile,
      height: isMobile ? 360 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Top Skills',
            subtitle: 'Most common applicant skills',
            isMobile: isMobile,
            badge: skills.isEmpty ? null : '${skills.length}',
            badgeColor: _violet,
          ),
          SizedBox(height: isMobile ? 14 : 18),
          Expanded(
            child: skills.isEmpty
                ? _EmptyHint(message: 'No skill data yet', isMobile: isMobile)
                : MouseRegion(
                    onEnter: (_) => onLockScroll(true),
                    onExit: (_) => onLockScroll(false),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      itemCount: skills.length > 10 ? 10 : skills.length,
                      itemBuilder: (ctx, i) {
                        final sk = skills[i];
                        final pct = sk.value / maxVal;
                        final isTop = i < 3;

                        return Padding(
                          padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Rank badge
                                  Container(
                                    width: isMobile ? 22 : 26,
                                    height: isMobile ? 22 : 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isTop
                                          ? _violet.withValues(alpha: 0.12)
                                          : _slate100,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: isMobile ? 10 : 11,
                                        fontWeight: FontWeight.w800,
                                        color: isTop ? _violet : _slate400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Skill name
                                  Expanded(
                                    child: Text(
                                      sk.key,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: isMobile ? 12 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: _slate900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Count
                                  Text(
                                    '${sk.value}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: isMobile ? 11 : 12,
                                      fontWeight: FontWeight.w700,
                                      color: isTop ? _violet : _slate600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: isMobile ? 5 : 6,
                                  backgroundColor: _slate100,
                                  valueColor: AlwaysStoppedAnimation(
                                    isTop
                                        ? _violet
                                        : _blue.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Top Jobs ─────────────────────────────────────────────────────────────────
class _TopJobsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMobile;
  final Map<String, Future<DocumentSnapshot>> cache;
  const _TopJobsCard({
    required this.data,
    required this.isMobile,
    required this.cache,
  });

  @override
  Widget build(BuildContext context) {
    final jobs = data['topJobs'] as List<MapEntry<String, int>>? ?? [];

    for (var e in jobs.take(5)) {
      cache.putIfAbsent(
        e.key,
        () => FirebaseFirestore.instance
            .collection('Posted_jobs_public')
            .doc(e.key)
            .get(),
      );
    }

    return _ChartCard(
      isMobile: isMobile,
      height: isMobile ? 360 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Top Performing Jobs',
            subtitle: 'Ranked by applications received',
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 14 : 18),
          Expanded(
            child: jobs.isEmpty
                ? _EmptyHint(message: 'No job data yet', isMobile: isMobile)
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jobs.take(5).length,
                    itemBuilder: (ctx, i) {
                      final entry = jobs[i];
                      final rankColor = i == 0
                          ? _amber
                          : i == 1
                          ? _slate400
                          : _blue.withValues(alpha: 0.55);

                      return FutureBuilder<DocumentSnapshot>(
                        future: cache[entry.key],
                        builder: (ctx, snap) {
                          String title = '…';
                          if (snap.hasData && snap.data!.data() != null) {
                            title =
                                ((snap.data!.data() as Map)['title']
                                    ?.toString()) ??
                                'Untitled';
                          }

                          return Container(
                            margin: EdgeInsets.only(bottom: isMobile ? 8 : 10),
                            padding: EdgeInsets.all(isMobile ? 12 : 14),
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? _amber.withValues(alpha: 0.05)
                                  : _slate50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: i == 0
                                    ? _amber.withValues(alpha: 0.2)
                                    : _slate200,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Rank circle — fixed size
                                Container(
                                  width: isMobile ? 30 : 34,
                                  height: isMobile ? 30 : 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: rankColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: isMobile ? 12 : 13,
                                      fontWeight: FontWeight.w800,
                                      color: rankColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Title + count — left-aligned
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: isMobile ? 12 : 13,
                                          fontWeight: FontWeight.w700,
                                          color: _slate900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${entry.value} application${entry.value == 1 ? '' : 's'}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: isMobile ? 10 : 11,
                                          color: _slate400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Trailing icon
                                Icon(
                                  Icons.trending_up_rounded,
                                  color: _emerald,
                                  size: isMobile ? 16 : 18,
                                ),
                              ],
                            ),
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

// ─── Chart Card Shell ─────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      );
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  final bool isMobile;
  final double? height;
  const _ChartCard({required this.child, required this.isMobile, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      constraints: height == null ? const BoxConstraints(minHeight: 220) : null,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Card Header ──────────────────────────────────────────────────────────────
class _CardHeader extends StatelessWidget {
  final String title, subtitle;
  final bool isMobile;
  final String? badge;
  final Color? badgeColor;
  const _CardHeader({
    required this.title,
    required this.subtitle,
    required this.isMobile,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  color: _slate900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 11 : 12,
                  color: _slate400,
                ),
              ),
            ],
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 10,
              vertical: isMobile ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: (badgeColor ?? _blue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: badgeColor ?? _blue,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Empty Hint ───────────────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final String message;
  final bool isMobile;
  const _EmptyHint({required this.message, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: isMobile ? 36 : 44,
            color: _slate200,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 12 : 13,
              color: _slate400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Box ──────────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double height;
  final double radius;
  const _ShimmerBox({required this.height, required this.radius});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: _slate100.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
