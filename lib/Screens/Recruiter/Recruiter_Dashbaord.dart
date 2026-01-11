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
import 'package:job_portal/Constant/recruiter_AI.dart';
import 'package:job_portal/Screens/Recruiter/R_Top_Bar.dart';
import 'package:job_portal/Screens/Recruiter/post_a_job_form.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
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

class _Dashboard_RecruiterState extends State<Dashboard_Recruiter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showAIChat = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this)..forward();
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
                    builder: (context, provider, _) => StreamBuilder<List<Map<String, dynamic>>>(
                      stream: provider.allJobsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: _primary));
                        }
                        if (snapshot.hasError) return _ErrorWidget(error: snapshot.error.toString());
                        final jobs = snapshot.data ?? [];
                        if (jobs.isEmpty) return _EmptyWidget();
                        return JobListView_New(jobs: jobs);
                      },
                    ),
                  ),
                  if (_showAIChat) _AIFloatingChat(onClose: () => setState(() => _showAIChat = false)),
                  if (!_showAIChat)
                    Positioned(
                      right: 24,
                      bottom: 24,
                      child: _AIFABButton(onTap: () => setState(() => _showAIChat = true)),
                    ),
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
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Oops! Something went wrong', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.red.shade600)),
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
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.work_outline_rounded, size: 64, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text('No Positions Available', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

// AI FLOATING CHAT
class _AIFloatingChat extends StatelessWidget {
  final VoidCallback onClose;
  const _AIFloatingChat({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 20,
      top: 100,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 400,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _primary, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text('Recruite.AI', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const Spacer(),
                    IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Colors.white, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ],
                ),
              ),
              Expanded(child: GeminiChatWidget()),
            ],
          ),
        ),
      ),
    );
  }
}

// AI FAB BUTTON
class _AIFABButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AIFABButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: _primary,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.smart_toy, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text('Recruite.AI', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// JOB LIST VIEW
class JobListView_New extends StatefulWidget {
  final List<Map<String, dynamic>> jobs;
  const JobListView_New({super.key, required this.jobs});

  @override
  State<JobListView_New> createState() => _JobListView_NewState();
}

class _JobListView_NewState extends State<JobListView_New> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _filteredJobs = [];
  String _selectedCompany = '', _selectedLocation = '', _selectedJobType = '';
  final Set<String> _selectedBenefits = {};
  String _selectedSortOption = 'newest';

  @override
  void initState() {
    super.initState();
    _filteredJobs = List.from(widget.jobs);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant JobListView_New oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.jobs, widget.jobs)) _applyFilters();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _applyFilters);
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredJobs = widget.jobs.where((job) {
        if (query.isNotEmpty) {
          final searchText = '${job['title']} ${job['company']} ${job['description']} ${(job['skills'] as List?)?.join(' ') ?? ''}'.toLowerCase();
          if (!searchText.contains(query)) return false;
        }
        if (_selectedCompany.isNotEmpty && job['company'] != _selectedCompany) return false;
        if (_selectedLocation.isNotEmpty && job['location'] != _selectedLocation) return false;
        if (_selectedJobType.isNotEmpty && job['nature'] != _selectedJobType) return false;
        if (_selectedBenefits.isNotEmpty) {
          final benefits = (job['benefits'] as List?)?.cast<String>().toSet() ?? {};
          if (!_selectedBenefits.any(benefits.contains)) return false;
        }
        return true;
      }).toList();
      _sortResults();
    });
  }

  void _sortResults() {
    switch (_selectedSortOption) {
      case 'newest':
        _filteredJobs.sort((a, b) => ((b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0)).compareTo((a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0)));
        break;
      case 'oldest':
        _filteredJobs.sort((a, b) => ((a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0)).compareTo((b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0)));
        break;
      case 'company':
        _filteredJobs.sort((a, b) => (a['company'] ?? '').compareTo(b['company'] ?? ''));
        break;
    }
  }

  List<String> _getUnique(String field) => widget.jobs.map((j) => j[field] as String? ?? '').where((s) => s.isNotEmpty).toSet().toList()..sort();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildFilters()),
          SliverToBoxAdapter(child: _buildStatsGrid()),
          SliverToBoxAdapter(child: _buildChartsSection()),
          _buildJobGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(color: _surface, border: Border(bottom: BorderSide(color: _border))),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [_primary, _secondary]), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.work_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recruiter Dashboard', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _textPrimary)),
              Text('Discover and manage candidates', style: GoogleFonts.poppins(fontSize: 12, color: _textSecondary)),
            ],
          ),
          const Spacer(),
          _buildStatPill('${_filteredJobs.length}', 'Jobs', Icons.rocket_launch, _primary),
          const SizedBox(width: 12),
          _buildStatPill('${_getUnique('company').length}', 'Companies', Icons.apartment, _secondary),
          const SizedBox(width: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => showDialog(context: context, barrierDismissible: false, builder: (_) => PostJobDialog()),
              child: Ink(
                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Post A Job', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 14, color: Colors.white)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
              Text(label, style: GoogleFonts.poppins(fontSize: 9, color: _textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final companies = _getUnique('company');
    final locations = _getUnique('location');
    final types = _getUnique('nature');

    return Container(
      color: _surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: _textSecondary, size: 18),
                hintText: 'Search jobs...',
                hintStyle: GoogleFonts.poppins(color: _textSecondary, fontSize: 13),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _primary)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: false,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildFilterDropdown('Company', _selectedCompany, companies, Icons.business, (v) => setState(() => _selectedCompany = v)),
          const SizedBox(width: 8),
          _buildFilterDropdown('Location', _selectedLocation, locations, Icons.location_on, (v) => setState(() => _selectedLocation = v)),
          const SizedBox(width: 8),
          _buildFilterDropdown('Type', _selectedJobType, types, Icons.work, (v) => setState(() => _selectedJobType = v)),
          const SizedBox(width: 8),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, IconData icon, Function(String) onChanged) {
    if (items.isEmpty) return const SizedBox();
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: value.isNotEmpty ? _primary.withOpacity(0.1) : _background, borderRadius: BorderRadius.circular(8), border: Border.all(color: value.isNotEmpty ? _primary : _border)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: value.isNotEmpty ? _primary : _textSecondary),
            const SizedBox(width: 6),
            Text(value.isEmpty ? label : value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: value.isNotEmpty ? _primary : _textSecondary)),
            Icon(Icons.arrow_drop_down, size: 16, color: value.isNotEmpty ? _primary : _textSecondary),
          ],
        ),
      ),
      onSelected: (v) {
        setState(() => onChanged(v));
        _applyFilters();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(value: '', child: Text('All', style: GoogleFonts.poppins(fontSize: 12))),
        ...items.map((i) => PopupMenuItem<String>(value: i, child: Text(i, style: GoogleFonts.poppins(fontSize: 12)))),
      ],
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      initialValue: _selectedSortOption,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 14, color: _textSecondary),
            const SizedBox(width: 6),
            Text('Sort', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: _textSecondary)),
          ],
        ),
      ),
      onSelected: (val) {
        setState(() => _selectedSortOption = val);
        _applyFilters();
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'newest', child: Text('Newest First', style: GoogleFonts.poppins(fontSize: 12))),
        PopupMenuItem(value: 'oldest', child: Text('Oldest First', style: GoogleFonts.poppins(fontSize: 12))),
        PopupMenuItem(value: 'company', child: Text('Company A→Z', style: GoogleFonts.poppins(fontSize: 12))),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer<JobSeekerProvider>(
        builder: (context, provider, _) => StreamBuilder<List<Map<String, dynamic>>>(
          stream: provider.allJobsStream(),
          builder: (context, snapshot) {
            final jobs = snapshot.data ?? [];
            final activeJobs = jobs.where((j) => j['status'] == 'active').length;
            final totalApplications = jobs.fold<int>(0, (sum, job) => sum + ((job['applications'] as int?) ?? 0));

            return Row(
              children: [
                Expanded(child: _buildStatCard(icon: Icons.work_rounded, label: 'Active Jobs', value: '$activeJobs', trend: '+3', trendUp: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(icon: Icons.people_rounded, label: 'Total Applications', value: '$totalApplications', trend: '+12%', trendUp: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(icon: Icons.trending_up_rounded, label: 'Response Rate', value: '68%', trend: '+5%', trendUp: true)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(icon: Icons.timer_rounded, label: 'Avg Fill Time', value: '18d', trend: '-2d', trendUp: true)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, String? trend, bool? trendUp}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: _primary, size: 16)),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: (trendUp! ? _accent : _error).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendUp ? Icons.arrow_upward : Icons.arrow_downward, size: 10, color: trendUp ? _accent : _error),
                      const SizedBox(width: 3),
                      Text(trend, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: trendUp ? _accent : _error)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: _textSecondary)),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildApplicationsChart()),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _buildJobStatusChart()),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: _buildDepartmentChart()),
          const SizedBox(width: 12),
          Expanded(child: _buildTopPerformingJobs()),
        ],
      ),
    );
  }

  Widget _buildApplicationsChart() {
    final weeklyData = [FlSpot(0, 12), FlSpot(1, 18), FlSpot(2, 15), FlSpot(3, 22), FlSpot(4, 28), FlSpot(5, 25), FlSpot(6, 32)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: _accent, size: 16),
              const SizedBox(width: 6),
              Text('Applications Trend', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 10, getDrawingHorizontalLine: (value) => FlLine(color: _border, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return value.toInt() >= 0 && value.toInt() < days.length
                            ? Padding(padding: const EdgeInsets.only(top: 6), child: Text(days[value.toInt()], style: GoogleFonts.poppins(fontSize: 10, color: _textSecondary)))
                            : const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: GoogleFonts.poppins(fontSize: 10, color: _textSecondary)))),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 40,
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyData,
                    isCurved: true,
                    color: _accent,
                    barWidth: 2,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: _accent, strokeWidth: 2, strokeColor: _surface)),
                    belowBarData: BarAreaData(show: true, color: _accent.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobStatusChart() {
    final statusData = [('Active', 12, _accent), ('Pending', 5, _warning), ('Closed', 8, _textSecondary), ('Draft', 3, _primary)];
    final maxY = statusData.map((e) => e.$2.toDouble()).reduce(max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: _primary, size: 16),
              const SizedBox(width: 6),
              Text('Job Status', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY > 0 ? maxY * 1.2 : 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => value.toInt() >= 0 && value.toInt() < statusData.length
                          ? Padding(padding: const EdgeInsets.only(top: 6), child: Text(statusData[value.toInt()].$1, style: GoogleFonts.poppins(fontSize: 10, color: _textSecondary)))
                          : const SizedBox(),
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.poppins(fontSize: 10, color: _textSecondary)))),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 2, getDrawingHorizontalLine: (value) => FlLine(color: _border, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(statusData.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: statusData[i].$2.toDouble(), color: statusData[i].$3, width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: _secondary, size: 16),
              const SizedBox(width: 6),
              Text('Job Distribution', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: 35, color: _primary, title: '35%', radius: 40, titleStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  PieChartSectionData(value: 25, color: _accent, title: '25%', radius: 40, titleStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  PieChartSectionData(value: 20, color: _secondary, title: '20%', radius: 40, titleStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  PieChartSectionData(value: 20, color: _warning, title: '20%', radius: 40, titleStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendItem('Engineering', _primary),
              _buildLegendItem('Design', _accent),
              _buildLegendItem('Marketing', _secondary),
              _buildLegendItem('Sales', _warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: _textSecondary)),
      ],
    );
  }

  Widget _buildTopPerformingJobs() {
    final topJobs = [('Senior Flutter Dev', 45), ('Backend Engineer', 38), ('UI/UX Designer', 32)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: _warning, size: 16),
              const SizedBox(width: 6),
              Text('Top Jobs', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...topJobs.asMap().entries.map((entry) {
            final index = entry.key;
            final job = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < 2 ? 12 : 0),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: index == 0 ? _warning.withOpacity(0.1) : _border, shape: BoxShape.circle),
                    child: Text('${index + 1}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: index == 0 ? _warning : _textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.$1, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${job.$2} applications', style: GoogleFonts.poppins(fontSize: 10, color: _textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildJobGrid() {
    if (_filteredJobs.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.search_off_rounded, size: 50, color: _textSecondary.withOpacity(0.5)),
              ),
              const SizedBox(height: 20),
              Text('No jobs found', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 8),
              Text('Try adjusting your filters', style: GoogleFonts.poppins(fontSize: 14, color: _textSecondary)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) => JobCard(jobData: _filteredJobs[index]),
          childCount: _filteredJobs.length,
        ),
      ),
    );
  }
}

// JOB CARD
class JobCard extends StatefulWidget {
  final Map<String, dynamic> jobData;
  const JobCard({super.key, required this.jobData});

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isHovered = false;

  String _getRelativeTime(Timestamp? ts) {
    if (ts == null) return '';
    return timeago.format(ts.toDate(), locale: 'en_short');
  }

  void _showJobDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: JobDetailModal_recruiter(jobData: widget.jobData)),
    );
  }

  void _showApplicants() {
    final jobId = widget.jobData['id'] as String?;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.55),
        pageBuilder: (context, anim, secondaryAnim) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8, maxHeight: MediaQuery.of(context).size.height * 0.95),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Colors.white,
                  elevation: 18,
                  child: Stack(
                    children: [
                      Scaffold(backgroundColor: Colors.white, body: Column(children: [Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Container(width: 56, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)))), Expanded(child: ApplicantsScreen(jobId: jobId))])),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))]), child: const Icon(Icons.close_rounded, size: 22, color: Colors.black87)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.jobData;
    final title = job['title'] as String? ?? 'No Title';
    final company = job['company'] as String? ?? 'Unknown Company';
    final location = job['location'] as String? ?? 'Unknown Location';
    final description = job['description'] as String? ?? '';
    final skills = (job['skills'] as List<dynamic>?)?.cast<String>() ?? [];
    final logoUrl = job['logoUrl'] as String?;
    final postedAgo = _getRelativeTime(job['timestamp'] as Timestamp?);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isHovered ? _primary.withOpacity(0.4) : _border, width: _isHovered ? 1.5 : 1),
          boxShadow: _isHovered ? [BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [_primary.withOpacity(0.08), _accent.withOpacity(0.08)]), borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                    child: logoUrl != null && logoUrl.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(9), child: CachedNetworkImage(imageUrl: logoUrl, fit: BoxFit.cover, placeholder: (_, __) => Center(child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(_primary))), errorWidget: (_, __, ___) => Icon(Icons.business_rounded, color: _primary, size: 20)))
                        : Icon(Icons.business_rounded, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(children: [Icon(Icons.apartment_rounded, size: 12, color: _textSecondary), const SizedBox(width: 4), Flexible(child: Text(company, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: _textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                        const SizedBox(height: 3),
                        Row(children: [Icon(Icons.location_on_rounded, size: 12, color: _textSecondary), const SizedBox(width: 4), Flexible(child: Text(location, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: _textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                      ],
                    ),
                  ),
                  if (postedAgo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: _success.withOpacity(0.1), borderRadius: BorderRadius.circular(5), border: Border.all(color: _success.withOpacity(0.2))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.schedule_rounded, size: 10, color: _success), const SizedBox(width: 3), Text(postedAgo, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: _success))]),
                    ),
                ],
              ),
              if (description.isNotEmpty) ...[const SizedBox(height: 10), Text(description, style: GoogleFonts.poppins(fontSize: 11, color: _textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis)],
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: skills.take(4).map((skill) {
                    final index = skills.indexOf(skill);
                    final colors = [[_primary, Color(0xFF3B82F6)], [_accent, Color(0xFF9333EA)], [_success, Color(0xFF059669)], [_warning, Color(0xFFD97706)]];
                    final colorPair = colors[index % colors.length];
                    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: colorPair[0].withOpacity(0.1), borderRadius: BorderRadius.circular(5), border: Border.all(color: colorPair[0].withOpacity(0.2))), child: Text(skill, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: colorPair[0])));
                  }).toList(),
                ),
              ],
              const Spacer(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showJobDetails,
                        borderRadius: BorderRadius.circular(8),
                        child: Ink(
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [_primary, Color(0xFF3B82F6)]), borderRadius: BorderRadius.circular(8)),
                          child: Container(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.visibility_rounded, size: 14, color: Colors.white), const SizedBox(width: 6), Text('Details', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))])),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showApplicants,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: _accent.withOpacity(0.3))),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.group_rounded, size: 14, color: _accent), const SizedBox(width: 6), Text('Applicants', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _accent))]),
                        ),
                      ),
                    ),
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