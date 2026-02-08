import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:job_portal/Constant/recruiter_AI.dart';
import 'package:job_portal/Screens/Recruiter/R_Top_Bar.dart';
import 'package:job_portal/Screens/Recruiter/post_a_job_form.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../Constant/recruiter_doughnat_chart.dart';
import '../Job_Seeker/job_seeker_provider.dart';
import 'LIst_of_Applicants.dart';
import 'job_detail_dialog_recrutier.dart';

// CONSTANTS
const _primary = Color(0xFF6366F1);
const _accent = Color(0xFFEC4899);
const _secondary = Color(0xFF8B5CF6);
const _background = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF0F172A);
const _textSecondary = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);
const _error = Color(0xFFEF4444);

// MAIN DASHBOARD
class Dashboard_Recruiter extends StatefulWidget {
  const Dashboard_Recruiter({super.key});
  @override
  State<Dashboard_Recruiter> createState() => _Dashboard_RecruiterState();
}

class _Dashboard_RecruiterState extends State<Dashboard_Recruiter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showAIChat = false;

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
    return Scaffold(
      backgroundColor: _background,
      body: Row(
        children: [
          RecruiterSidebar(activeIndex: 0),
          Expanded(
            child: FadeTransition(
              opacity: _controller,
              child: Stack(
                children: [
                  Consumer<JobSeekerProvider>(
                    builder: (context, provider, _) =>
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: provider.allJobsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: _primary,
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return _ErrorWidget(
                                error: snapshot.error.toString(),
                              );
                            }
                            final jobs = snapshot.data ?? [];
                            if (jobs.isEmpty) return _EmptyWidget();
                            return Recruiter_Analytics(jobs: jobs);
                          },
                        ),
                  ),
                  // AI Chat with built-in toggle
                  const AIFloatingChat(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ERROR WIDGET
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
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// EMPTY WIDGET
class _EmptyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Positions Available',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}



// COMPACT SIDE CHAT WIDGET - ADD THIS TO YOUR PARENT WIDGET FILE
class AIFloatingChat extends StatefulWidget {
  const AIFloatingChat({super.key});

  @override
  State<AIFloatingChat> createState() => _AIFloatingChatState();
}

class _AIFloatingChatState extends State<AIFloatingChat> {
  bool _showChat = false;

  void _toggleChat() {
    setState(() {
      _showChat = !_showChat;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Chat Widget (positioned at bottom-right corner, above FAB)
        if (_showChat)
          Positioned(
            right: 24,
            bottom: 90, // Above the FAB button
            child: AIJDBuilderWidget(
              onClose: _toggleChat,
            ),
          ),

        // FAB Button (positioned at bottom right)
        Positioned(
          right: 24,
          bottom: 24,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF4F46E5),
            child: InkWell(
              onTap: _toggleChat,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showChat ? Icons.close : Icons.smart_toy,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recruite.AI',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}






class Recruiter_Analytics extends StatefulWidget {
  final List<Map<String, dynamic>> jobs;
  const Recruiter_Analytics({super.key, required this.jobs});

  @override
  State<Recruiter_Analytics> createState() => _Recruiter_AnalyticsState();
}

class _Recruiter_AnalyticsState extends State<Recruiter_Analytics>
    with TickerProviderStateMixin {

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, Future<DocumentSnapshot>> _jobDataCache = {};
  Timer? _debounceTimer;
  bool _lockOuterScroll = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Professional color scheme - Corporate Navy
  static const Color _primary = Color(0xFF1E3A5F);
  static const Color _primaryLight = Color(0xFF2E4A6F);
  static const Color _accent = Color(0xFF3B82F6);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _error = Color(0xFFEF4444);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _background = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController.forward();
    _slideController.forward();
  }




  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _jobDataCache.clear();
    _debounceTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: _lockOuterScroll
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildStatsOverview()),
                SliverToBoxAdapter(child: _buildAnalyticsSection()),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildHeader() {
    const Color kPrimaryBlue = Color(0xFF1E40AF);
    const Color kTextPrimary = Color(0xFF0F172A);
    const Color kTextSecondary = Color(0xFF475569);
    const Color kBorderLight = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Left Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.recent_actors_outlined,
              size: 24,
              color: kPrimaryBlue,
            ),
          ),

          const SizedBox(width: 14),

          // Title & Subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recruiter Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                  height: 1.2,
                ),
              ),
              Text(
                'Discover and Manage Jobs & Candidates Trends',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: kTextSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),

          const Spacer(),
          _buildPostJobButton(),

        ],
      ),
    );
  }

  Widget _buildPostJobButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const PostJobDialog(),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _accent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Post Job',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  // STATS OVERVIEW CARDS
  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      color: _background,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAllApplicantsData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(color: _primary)),
            );
          }

          final data = snapshot.data!;
          final totalApps = data['totalApplicants'] ?? 0;
          final pending = data['pending'] ?? 0;
          final accepted = data['accepted'] ?? 0;
          final rejected = data['rejected'] ?? 0;
          final shortlist = data['shortlist'] ?? 0;

          return Row(
            children: [
              Expanded(
                child: _buildStatCardEnhanced(
                  title: 'Total Applications',
                  value: totalApps.toString(),
                  subtitle: 'Across all jobs Posted',
                  icon: Icons.people_alt_outlined,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCardEnhanced(
                  title: 'Pending Review',
                  value: pending.toString(),
                  subtitle: 'Awaiting recruiter action',
                  icon: Icons.hourglass_empty,
                  color: _warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCardEnhanced(
                  title: 'Accepted',
                  value: accepted.toString(),
                  subtitle: 'Candidates Handover by Admin',
                  icon: Icons.check_circle_outline,
                  color: _success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCardEnhanced(
                  title: 'Rejected',
                  value: rejected.toString(),
                  subtitle: 'Rejected candidates',
                  icon: Icons.group_remove_outlined,
                  color: _error,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: _buildStatCardEnhanced(
                  title: 'shortlist',
                  value: shortlist.toString(),
                  subtitle: 'In interview pipeline',
                  icon: Icons.star_outline,
                  color: _primary,
                ),
              ),
            ],
          );
        },
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),

                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ANALYTICS SECTION
  Widget _buildAnalyticsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      color: _background,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAllApplicantsData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator(color: _primary)),
            );
          }

          final data = snapshot.data!;

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildApplicationsTrendChart(data),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: _buildStatusDistribution(data),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTopSkillsChart(data),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildTopJobsList(data),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApplicationsTrendChart(Map<String, dynamic> data) {
    final trendData = data['trendData'] as List<FlSpot>? ?? [];
    final dates = data['dates'] as List<DateTime>? ?? [];

    if (trendData.isEmpty) {
      return _buildEmptyChart('Application Trends', 'No data available');
    }

    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Application Trends',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily application volume over time',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last ${dates.length} days',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: trendData.last.y / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: _border,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (trendData.length / 6).ceil().toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM d').format(dates[index]),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: _textSecondary,
                              ),
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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (trendData.length - 1).toDouble(),
                minY: 0,
                maxY: trendData.last.y * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: trendData,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: _accent,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: _accent,
                        strokeWidth: 2,
                        strokeColor: _background,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _accent.withOpacity(0.3),
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
                    getTooltipColor: (spot) => _textPrimary.withOpacity(0.9),
                    getTooltipItems: (spots) => spots.map((spot) {
                      final index = spot.x.toInt();
                      final date = index < dates.length
                          ? DateFormat('MMM d, yyyy').format(dates[index])
                          : '';
                      return LineTooltipItem(
                        '$date\n${spot.y.toInt()} applications',
                        GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildStatusDistribution(Map<String, dynamic> data) {
    final pending = data['pending'] ?? 0;
    final accepted = data['accepted'] ?? 0;
    final rejected = data['rejected'] ?? 0;
    final shortlist = data['shortlist'] ?? 0;
    final total = pending + accepted + rejected + shortlist;

    if (total == 0) {
      return _buildEmptyChart('Status Distribution', 'No data available');
    }

    final sections = [
      PieChartSectionData(
        color: _warning,
        value: pending.toDouble(),
        title: '${((pending / total) * 100).toInt()}%',
        radius: 60,
        titleStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: _buildPieBadge(Icons.hourglass_empty, _warning),
        badgePositionPercentageOffset: 1.2,
      ),
      PieChartSectionData(
        color: _success,
        value: accepted.toDouble(),
        title: '${((accepted / total) * 100).toInt()}%',
        radius: 60,
        titleStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: _buildPieBadge(Icons.check, _success),
        badgePositionPercentageOffset: 1.2,
      ),
      PieChartSectionData(
        color: _error,
        value: rejected.toDouble(),
        title: '${((rejected / total) * 100).toInt()}%',
        radius: 60,
        titleStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: _buildPieBadge(Icons.close, _error),
        badgePositionPercentageOffset: 1.2,
      ),
      PieChartSectionData(
        color: _primary,
        value: shortlist.toDouble(),
        title: '${((shortlist / total) * 100).toInt()}%',
        radius: 60,
        titleStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: _buildPieBadge(Icons.star, _primary),
        badgePositionPercentageOffset: 1.2,
      ),
    ];

    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Status',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Distribution by current status',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Pending', pending.toString(), _warning),
                      const SizedBox(height: 12),
                      _buildLegendItem('Accepted', accepted.toString(), _success),
                      const SizedBox(height: 12),
                      _buildLegendItem('Rejected', rejected.toString(), _error),
                      const SizedBox(height: 12),
                      _buildLegendItem('shortlist', shortlist.toString(), _primary),
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

  Widget _buildPieBadge(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: _background, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTopSkillsChart(Map<String, dynamic> data) {
    final topSkills = data['topSkills'] as List<MapEntry<String, int>>? ?? [];

    if (topSkills.isEmpty) {
      return _buildEmptyChart('Top Skills', 'No skills data available');
    }

    final maxValue = topSkills.first.value.toDouble();

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Skills',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Most requested skills by applicants',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${topSkills.length} skills',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _lockOuterScroll = true),
              onExit: (_) => setState(() => _lockOuterScroll = false),
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: topSkills.length > 10 ? 10 : topSkills.length,
                itemBuilder: (context, index) {
                  final skill = topSkills[index];
                  final percentage = (skill.value / maxValue * 100).round();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: index < 3
                                        ? _accent.withOpacity(0.1)
                                        : _surface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: index < 3 ? _accent : _textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  skill.key,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '${skill.value}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($percentage%)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: skill.value / maxValue,
                            backgroundColor: _border.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              index < 3 ? _accent : _primary.withOpacity(0.6),
                            ),
                            minHeight: 6,
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

  Widget _buildTopJobsList(Map<String, dynamic> data) {
    final topJobIds = data['topJobs'] as List<MapEntry<String, int>>? ?? [];

    if (topJobIds.isEmpty) {
      return _buildEmptyChart('Top Performing Jobs', 'No data available');
    }

    // Populate cache
    for (var jobEntry in topJobIds.take(5)) {
      if (!_jobDataCache.containsKey(jobEntry.key)) {
        _jobDataCache[jobEntry.key] = FirebaseFirestore.instance
            .collection('Posted_jobs_public')
            .doc(jobEntry.key)
            .get();
      }
    }

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performing Jobs',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jobs with most applications',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 24),
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
                    if (snapshot.hasData && snapshot.data!.data() != null) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      jobTitle = data['title']?.toString() ?? 'Unknown Job';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? _warning.withOpacity(0.1)
                                  : _primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: index == 0 ? _warning : _primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  jobTitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${jobEntry.value} applications',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.trending_up,
                            color: _success,
                            size: 20,
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

  Widget _buildEmptyChart(String title, String message) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 64,
            color: _textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // DATA FETCHING
  Future<Map<String, dynamic>> _fetchAllApplicantsData() async {
    try {
      final applicantsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('applied_jobs')
          .get();

      int totalApplicants = applicantsSnapshot.docs.length;
      int pending = 0;
      int accepted = 0;
      int rejected = 0;
      int shortlist = 0;

      Map<String, int> skillsCount = {};
      Map<String, int> locationCount = {};
      Map<String, int> nationalityCount = {};
      Map<String, int> jobApplicationCount = {};

      Map<DateTime, int> dailyApplications = {};

      for (var doc in applicantsSnapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? 'pending';

        // Count by status
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

        // Count by job
        final jobId = data['jobId']?.toString() ?? '';
        if (jobId.isNotEmpty) {
          jobApplicationCount[jobId] = (jobApplicationCount[jobId] ?? 0) + 1;
        }

        // Parse profile data
        final profileSnapshot =
        data['profileSnapshot'] as Map<String, dynamic>?;
        if (profileSnapshot != null) {
          final accountData =
          profileSnapshot['user_Account_Data'] as Map<String, dynamic>?;
          if (accountData != null) {
            final personalProfile =
            accountData['personalProfile'] as Map<String, dynamic>?;

            // Count skills
            final skills = personalProfile?['skills'] as List?;
            if (skills != null) {
              for (var skill in skills) {
                final skillStr = skill.toString();
                skillsCount[skillStr] = (skillsCount[skillStr] ?? 0) + 1;
              }
            }

            // Count locations
            final location = personalProfile?['location']?.toString() ?? '';
            if (location.isNotEmpty) {
              locationCount[location] = (locationCount[location] ?? 0) + 1;
            }

            // Count nationalities
            final nationality =
                personalProfile?['nationality']?.toString() ?? '';
            if (nationality.isNotEmpty) {
              nationalityCount[nationality] =
                  (nationalityCount[nationality] ?? 0) + 1;
            }
          }
        }

        // Track daily applications for trends
        final appliedAt = data['appliedAt'];
        if (appliedAt is Timestamp) {
          final date = DateTime(
            appliedAt.toDate().year,
            appliedAt.toDate().month,
            appliedAt.toDate().day,
          );
          dailyApplications[date] = (dailyApplications[date] ?? 0) + 1;
        }
      }

      // Sort to get top items
      final topSkills =
      (skillsCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
          .take(10)
          .toList();

      final topLocations =
      (locationCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .toList();

      final topNationalities =
      (nationalityCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .toList();

      // Get top jobs by application count
      final topJobs =
      (jobApplicationCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .toList();

      // Calculate trend data
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
  }}

// Helper function
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}









