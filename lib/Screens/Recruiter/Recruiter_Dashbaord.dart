import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill_internal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:job_portal/Constant/recruiter_AI.dart';
import 'package:job_portal/Screens/Recruiter/R_Top_Bar.dart';
import 'package:job_portal/Screens/Recruiter/post_a_job_form.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../Constant/recruiter_doughnat_chart.dart';
import '../Job_Seeker/job_seeker_provider.dart';
import 'LIst_of_Applicants.dart';
import 'job_detail_dialog_recrutier.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _primary = Color(0xFF1E3A5F);
const _primaryLight = Color(0xFF2E4A6F);
const _accent = Color(0xFF3B82F6);
const _secondary = Color(0xFF8B5CF6);
const _background = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF0F172A);
const _textSecondary = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);
const _error = Color(0xFFEF4444);

// ─── Main Dashboard ───────────────────────────────────────────────────────────
class Dashboard_Recruiter extends StatefulWidget {
  const Dashboard_Recruiter({super.key});
  @override
  State<Dashboard_Recruiter> createState() => _Dashboard_RecruiterState();
}

class _Dashboard_RecruiterState extends State<Dashboard_Recruiter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _background,
      drawer: isMobile
          ? Drawer(child: RecruiterSidebar(activeIndex: 0, isDrawer: true))
          : null,
      body: Row(
        children: [
          if (!isMobile) RecruiterSidebar(activeIndex: 0),
          Expanded(
            child: FadeTransition(
              opacity: _controller,
              child: Column(
                children: [
                  if (isMobile) _buildMobileAppBar(context),
                  Expanded(
                    child: Consumer<JobSeekerProvider>(
                      builder: (context, provider, _) =>
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: provider.allJobsStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(color: _primary),
                                );
                              }
                              if (snapshot.hasError) {
                                return _ErrorWidget(
                                    error: snapshot.error.toString());
                              }
                              final jobs = snapshot.data ?? [];
                              if (jobs.isEmpty) return const _EmptyWidget();
                              return Recruiter_Analytics(jobs: jobs);
                            },
                          ),
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

  Widget _buildMobileAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.recent_actors_outlined,
                size: 20, color: Color(0xFF1E40AF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recruiter Dashboard',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/post-job'),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('Post',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Error Widget ─────────────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String error;
  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Oops! Something went wrong',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.red.shade600)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Widget ─────────────────────────────────────────────────────────────
class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.work_outline_rounded,
                size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text('No Positions Available',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

// ─── Analytics Widget ─────────────────────────────────────────────────────────
class Recruiter_Analytics extends StatefulWidget {
  final List<Map<String, dynamic>> jobs;
  const Recruiter_Analytics({super.key, required this.jobs});

  @override
  State<Recruiter_Analytics> createState() => _Recruiter_AnalyticsState();
}

class _Recruiter_AnalyticsState extends State<Recruiter_Analytics>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<String, Future<DocumentSnapshot>> _jobDataCache = {};
  bool _lockOuterScroll = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this)
      ..forward();
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this)
      ..forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _jobDataCache.clear();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ─── Responsive helpers ────────────────────────────────────────────────────

  /// Card padding: compact on mobile, comfortable on desktop
  EdgeInsets _cardPad(bool isMobile) =>
      EdgeInsets.all(isMobile ? 14 : 20);

  /// Section outer padding
  EdgeInsets _sectionPad(bool isMobile) => EdgeInsets.fromLTRB(
    isMobile ? 12 : 32,
    isMobile ? 8 : 0,
    isMobile ? 12 : 32,
    isMobile ? 12 : 24,
  );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        physics: _lockOuterScroll
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        slivers: [
          if (!isMobile)
            SliverToBoxAdapter(child: _buildHeader(isMobile)),
          SliverToBoxAdapter(child: _buildStatsOverview(isMobile)),
          SliverToBoxAdapter(child: _buildAnalyticsSection(isMobile)),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.recent_actors_outlined,
                size: 24, color: Color(0xFF1E40AF)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Recruiter Dashboard',
                    style: GoogleFonts.poppins(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                        height: 1.2)),
                Text('Manage Trends',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _textSecondary,
                        height: 1.2)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!isMobile) _buildPostJobButton(),
        ],
      ),
    );
  }

  Widget _buildPostJobButton() {
    return InkWell(
      onTap: () => context.go('/post-job'),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [_primary, _accent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: _primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.add, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Post Job',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ─── Stats Overview ────────────────────────────────────────────────────────

  Widget _buildStatsOverview(bool isMobile) {
    return Container(
      padding: _sectionPad(isMobile),
      color: _background,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAllApplicantsData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 100,
              child: Center(
                  child: CircularProgressIndicator(color: _primary)),
            );
          }
          final data = snapshot.data!;
          final totalApps = data['totalApplicants'] ?? 0;
          final pending = data['pending'] ?? 0;
          final accepted = data['accepted'] ?? 0;
          final rejected = data['rejected'] ?? 0;
          final shortlist = data['shortlist'] ?? 0;

          if (isMobile) {
            return Column(
              children: [
                Row(children: [
                  Expanded(
                      child: _buildCompactStatCard(
                          title: 'Total Apps',
                          value: totalApps.toString(),
                          icon: Icons.people_alt_outlined,
                          color: _accent)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildCompactStatCard(
                          title: 'Pending',
                          value: pending.toString(),
                          icon: Icons.hourglass_empty,
                          color: _warning)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _buildCompactStatCard(
                          title: 'Accepted',
                          value: accepted.toString(),
                          icon: Icons.check_circle_outline,
                          color: _success)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildCompactStatCard(
                          title: 'Rejected',
                          value: rejected.toString(),
                          icon: Icons.group_remove_outlined,
                          color: _error)),
                ]),
                const SizedBox(height: 8),
                _buildCompactStatCard(
                    title: 'Shortlist',
                    value: shortlist.toString(),
                    icon: Icons.star_outline,
                    color: _primary),
              ],
            );
          }

          // Desktop row
          final items = [
            (title: 'Total Apps', value: totalApps.toString(), sub: 'Across jobs', icon: Icons.people_alt_outlined, color: _accent),
            (title: 'Pending', value: pending.toString(), sub: 'Needs review', icon: Icons.hourglass_empty, color: _warning),
            (title: 'Accepted', value: accepted.toString(), sub: 'By Admin', icon: Icons.check_circle_outline, color: _success),
            (title: 'Rejected', value: rejected.toString(), sub: 'Candidates', icon: Icons.group_remove_outlined, color: _error),
            (title: 'Shortlist', value: shortlist.toString(), sub: 'Interview', icon: Icons.star_outline, color: _primary),
          ];

          return Row(
            children: items.asMap().entries.map((e) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: e.key < items.length - 1 ? 16 : 0),
                  child: _buildStatCardEnhanced(
                    title: e.value.title,
                    value: e.value.value,
                    subtitle: e.value.sub,
                    icon: e.value.icon,
                    color: e.value.color,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        height: 1.1)),
                Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardEnhanced({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          const SizedBox(height: 4),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: _textSecondary)),
        ],
      ),
    );
  }

  // ─── Analytics Section ─────────────────────────────────────────────────────

  Widget _buildAnalyticsSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 32,
        0,
        isMobile ? 12 : 32,
        24,
      ),
      color: _background,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAllApplicantsData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 300,
              child: Center(
                  child: CircularProgressIndicator(color: _primary)),
            );
          }
          final data = snapshot.data!;

          if (isMobile) {
            return Column(
              children: [
                _buildApplicationsTrendChart(data, isMobile),
                const SizedBox(height: 14),
                _buildStatusDistribution(data, isMobile),
                const SizedBox(height: 14),
                _buildTopSkillsChart(data, isMobile),
                const SizedBox(height: 14),
                _buildTopJobsList(data, isMobile),
              ],
            );
          }

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 3,
                      child: _buildApplicationsTrendChart(data, isMobile)),
                  const SizedBox(width: 20),
                  Expanded(
                      flex: 2,
                      child: _buildStatusDistribution(data, isMobile)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 2,
                      child: _buildTopSkillsChart(data, isMobile)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildTopJobsList(data, isMobile)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Trend Chart ───────────────────────────────────────────────────────────

  Widget _buildApplicationsTrendChart(
      Map<String, dynamic> data, bool isMobile) {
    final trendData = data['trendData'] as List<FlSpot>? ?? [];
    final dates = data['dates'] as List<DateTime>? ?? [];

    if (trendData.isEmpty) {
      return _buildEmptyChart('Application Trends', 'No data available',
          isMobile);
    }

    final chartHeight = isMobile ? 260.0 : 350.0;
    final titleFont = isMobile ? 14.0 : 18.0;
    final subFont = isMobile ? 11.0 : 13.0;

    return Container(
      height: chartHeight,
      padding: _cardPad(isMobile),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Application Trends',
                        style: GoogleFonts.poppins(
                            fontSize: titleFont,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text('Daily application volume',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: subFont, color: _textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 4 : 6),
                decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: _accent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${dates.length}d',
                        style: GoogleFonts.poppins(
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: FontWeight.w600,
                            color: _accent)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                  trendData.isNotEmpty ? trendData.last.y / 4 : 1,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: _border, strokeWidth: 1, dashArray: [5, 5]),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval:
                      (trendData.length / (isMobile ? 4 : 6))
                          .ceil()
                          .toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat(isMobile ? 'M/d' : 'MMM d')
                                  .format(dates[index]),
                              style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 9 : 11,
                                  color: _textSecondary),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isMobile ? 28 : 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: GoogleFonts.poppins(
                            fontSize: isMobile ? 9 : 11,
                            color: _textSecondary),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (trendData.length - 1).toDouble(),
                minY: 0,
                maxY: trendData.isNotEmpty ? trendData.last.y * 1.2 : 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: _accent,
                    barWidth: isMobile ? 2 : 3,
                    dotData: FlDotData(
                      show: !isMobile, // hide dots on mobile to reduce clutter
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                              radius: 4,
                              color: _accent,
                              strokeWidth: 2,
                              strokeColor: _background),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _accent.withOpacity(0.25),
                          _accent.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => _textPrimary.withOpacity(0.9),
                    getTooltipItems: (spots) => spots.map((spot) {
                      final idx = spot.x.toInt();
                      final date = idx < dates.length
                          ? DateFormat('MMM d, yyyy').format(dates[idx])
                          : '';
                      return LineTooltipItem(
                        '$date\n${spot.y.toInt()} apps',
                        GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status Distribution ───────────────────────────────────────────────────

  Widget _buildStatusDistribution(
      Map<String, dynamic> data, bool isMobile) {
    final pending = data['pending'] ?? 0;
    final accepted = data['accepted'] ?? 0;
    final rejected = data['rejected'] ?? 0;
    final shortlist = data['shortlist'] ?? 0;
    final total = pending + accepted + rejected + shortlist;

    if (total == 0) {
      return _buildEmptyChart(
          'Status Distribution', 'No data available', isMobile);
    }

    PieChartSectionData _section(
        Color color, int value, IconData icon) {
      final pct = ((value / total) * 100).toInt();
      return PieChartSectionData(
        color: color,
        value: value.toDouble(),
        title: '$pct%',
        radius: isMobile ? 32 : 40,
        titleStyle: GoogleFonts.poppins(
            fontSize: isMobile ? 10 : 12,
            fontWeight: FontWeight.w700,
            color: Colors.white),
        badgeWidget: _buildPieBadge(icon, color, isMobile),
        badgePositionPercentageOffset: 1.2,
      );
    }

    final chartHeight = isMobile ? 240.0 : 350.0;

    return Container(
      height: chartHeight,
      padding: _cardPad(isMobile),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Application Status',
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const SizedBox(height: 2),
          Text('Distribution by current status',
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 11 : 13,
                  color: _textSecondary)),
          SizedBox(height: isMobile ? 12 : 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        _section(_warning, pending, Icons.hourglass_empty),
                        _section(_success, accepted, Icons.check),
                        _section(_error, rejected, Icons.close),
                        _section(_primary, shortlist, Icons.star),
                      ],
                      centerSpaceRadius: isMobile ? 28 : 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                          'Pending', pending.toString(), _warning, isMobile),
                      SizedBox(height: isMobile ? 8 : 12),
                      _buildLegendItem(
                          'Accepted', accepted.toString(), _success, isMobile),
                      SizedBox(height: isMobile ? 8 : 12),
                      _buildLegendItem(
                          'Rejected', rejected.toString(), _error, isMobile),
                      SizedBox(height: isMobile ? 8 : 12),
                      _buildLegendItem(
                          'Shortlist', shortlist.toString(), _primary, isMobile),
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

  Widget _buildPieBadge(IconData icon, Color color, bool isMobile) {
    final size = isMobile ? 22.0 : 28.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: _background, width: 2),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Icon(icon, color: Colors.white, size: isMobile ? 10 : 14),
    );
  }

  Widget _buildLegendItem(
      String label, String value, Color color, bool isMobile) {
    return Row(
      children: [
        Container(
          width: isMobile ? 10 : 12,
          height: isMobile ? 10 : 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 11 : 13, color: _textSecondary)),
        ),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: isMobile ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary)),
      ],
    );
  }

  // ─── Top Skills Chart ──────────────────────────────────────────────────────

  Widget _buildTopSkillsChart(Map<String, dynamic> data, bool isMobile) {
    final topSkills =
        data['topSkills'] as List<MapEntry<String, int>>? ?? [];

    if (topSkills.isEmpty) {
      return _buildEmptyChart(
          'Top Skills', 'No skills data available', isMobile);
    }

    final maxValue = topSkills.first.value.toDouble();
    final chartHeight = isMobile ? 320.0 : 400.0;

    return Container(
      height: chartHeight,
      padding: _cardPad(isMobile),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Skills',
                        style: GoogleFonts.poppins(
                            fontSize: isMobile ? 14 : 18,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text('Most requested skills',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: isMobile ? 11 : 13,
                            color: _textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 12,
                    vertical: isMobile ? 4 : 6),
                decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('${topSkills.length} skills',
                    style: GoogleFonts.poppins(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w600,
                        color: _primary)),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 24),
          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _lockOuterScroll = true),
              onExit: (_) => setState(() => _lockOuterScroll = false),
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: topSkills.length > 10 ? 10 : topSkills.length,
                itemBuilder: (context, index) {
                  final skill = topSkills[index];
                  final percentage =
                  (skill.value / maxValue * 100).round();

                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: isMobile ? 10 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: isMobile ? 24 : 28,
                                    height: isMobile ? 24 : 28,
                                    decoration: BoxDecoration(
                                      color: index < 3
                                          ? _accent.withOpacity(0.1)
                                          : _surface,
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text('${index + 1}',
                                          style: GoogleFonts.poppins(
                                              fontSize:
                                              isMobile ? 10 : 12,
                                              fontWeight: FontWeight.w700,
                                              color: index < 3
                                                  ? _accent
                                                  : _textSecondary)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(skill.key,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                            fontSize:
                                            isMobile ? 12 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: _textPrimary)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${skill.value} ($percentage%)',
                              style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 10 : 12,
                                  color: _textSecondary),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 5 : 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: skill.value / maxValue,
                            backgroundColor:
                            _border.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              index < 3
                                  ? _accent
                                  : _primary.withOpacity(0.6),
                            ),
                            minHeight: isMobile ? 4 : 6,
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

  // ─── Top Jobs List ─────────────────────────────────────────────────────────

  Widget _buildTopJobsList(Map<String, dynamic> data, bool isMobile) {
    final topJobIds =
        data['topJobs'] as List<MapEntry<String, int>>? ?? [];

    if (topJobIds.isEmpty) {
      return _buildEmptyChart(
          'Top Performing Jobs', 'No data available', isMobile);
    }

    for (var jobEntry in topJobIds.take(5)) {
      if (!_jobDataCache.containsKey(jobEntry.key)) {
        _jobDataCache[jobEntry.key] = FirebaseFirestore.instance
            .collection('Posted_jobs_public')
            .doc(jobEntry.key)
            .get();
      }
    }

    final chartHeight = isMobile ? 320.0 : 400.0;

    return Container(
      height: chartHeight,
      padding: _cardPad(isMobile),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Performing Jobs',
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const SizedBox(height: 2),
          Text('Jobs with most applications',
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 11 : 13,
                  color: _textSecondary)),
          SizedBox(height: isMobile ? 12 : 24),
          Expanded(
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topJobIds.take(5).length,
              itemBuilder: (context, index) {
                final jobEntry = topJobIds[index];
                return FutureBuilder<DocumentSnapshot>(
                  future: _jobDataCache[jobEntry.key],
                  builder: (context, snapshot) {
                    String jobTitle = 'Loading...';
                    if (snapshot.hasData &&
                        snapshot.data!.data() != null) {
                      final d = snapshot.data!.data()
                      as Map<String, dynamic>;
                      jobTitle =
                          d['title']?.toString() ?? 'Unknown Job';
                    }

                    return Container(
                      margin: EdgeInsets.only(
                          bottom: isMobile ? 8 : 12),
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isMobile ? 30 : 36,
                            height: isMobile ? 30 : 36,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? _warning.withOpacity(0.1)
                                  : _primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${index + 1}',
                                  style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 12 : 14,
                                      fontWeight: FontWeight.w700,
                                      color: index == 0
                                          ? _warning
                                          : _primary)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(jobTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 12 : 14,
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary)),
                                const SizedBox(height: 2),
                                Text('${jobEntry.value} applications',
                                    style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 10 : 12,
                                        color: _textSecondary)),
                              ],
                            ),
                          ),
                          Icon(Icons.trending_up,
                              color: _success,
                              size: isMobile ? 16 : 20),
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

  // ─── Empty Chart ───────────────────────────────────────────────────────────

  Widget _buildEmptyChart(
      String title, String message, bool isMobile) {
    return Container(
      height: isMobile ? 200 : 350,
      padding: _cardPad(isMobile),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined,
              size: isMobile ? 44 : 64,
              color: _textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const SizedBox(height: 8),
          Text(message,
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 12 : 14,
                  color: _textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ─── Data Fetching (unchanged) ─────────────────────────────────────────────

  Future<Map<String, dynamic>> _fetchAllApplicantsData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final applicantsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('applied_jobs')
          .where('recruiterUid', isEqualTo: uid)
          .get();

      int totalApplicants = applicantsSnapshot.docs.length;
      int pending = 0, accepted = 0, rejected = 0, shortlist = 0;
      Map<String, int> skillsCount = {};
      Map<String, int> locationCount = {};
      Map<String, int> nationalityCount = {};
      Map<String, int> jobApplicationCount = {};
      Map<DateTime, int> dailyApplications = {};

      for (var doc in applicantsSnapshot.docs) {
        final data = doc.data();
        final status =
            data['status']?.toString().toLowerCase() ?? 'pending';

        switch (status) {
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

        final jobId = data['jobId']?.toString() ?? '';
        if (jobId.isNotEmpty) {
          jobApplicationCount[jobId] =
              (jobApplicationCount[jobId] ?? 0) + 1;
        }

        final profileSnapshot =
        data['profileSnapshot'] as Map<String, dynamic>?;
        if (profileSnapshot != null) {
          final accountData = profileSnapshot['user_Account_Data']
          as Map<String, dynamic>?;
          if (accountData != null) {
            final personalProfile =
            accountData['personalProfile'] as Map<String, dynamic>?;

            final skills = personalProfile?['skills'] as List?;
            if (skills != null) {
              for (var skill in skills) {
                final s = skill.toString();
                skillsCount[s] = (skillsCount[s] ?? 0) + 1;
              }
            }

            final location =
                personalProfile?['location']?.toString() ?? '';
            if (location.isNotEmpty) {
              locationCount[location] =
                  (locationCount[location] ?? 0) + 1;
            }

            final nationality =
                personalProfile?['nationality']?.toString() ?? '';
            if (nationality.isNotEmpty) {
              nationalityCount[nationality] =
                  (nationalityCount[nationality] ?? 0) + 1;
            }
          }
        }

        final appliedAt = data['appliedAt'];
        if (appliedAt is Timestamp) {
          final dt = appliedAt.toDate();
          final date = DateTime(dt.year, dt.month, dt.day);
          dailyApplications[date] =
              (dailyApplications[date] ?? 0) + 1;
        }
      }

      final topSkills = (skillsCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
          .take(10)
          .toList();

      final topLocations = (locationCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .toList();

      final topNationalities = (nationalityCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .toList();

      final topJobs = (jobApplicationCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .toList();

      final sortedDates = dailyApplications.keys.toList()..sort();
      List<FlSpot> trendData = [];
      int cumulative = 0;
      for (int i = 0; i < sortedDates.length; i++) {
        cumulative += dailyApplications[sortedDates[i]] ?? 0;
        trendData.add(FlSpot(i.toDouble(), cumulative.toDouble()));
      }

      return {
        'totalApplicants': totalApplicants,
        'pending': pending,
        'accepted': accepted,
        'rejected': rejected,
        'shortlist': shortlist,
        'topSkills': topSkills,
        'topLocations': topLocations,
        'topNationalities': topNationalities,
        'topJobs': topJobs,
        'trendData': trendData,
        'dates': sortedDates,
        'dailyApplications': dailyApplications,
      };
    } catch (e) {
      debugPrint('Error fetching applicants data: $e');
      return {};
    }
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