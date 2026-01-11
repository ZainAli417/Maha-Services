import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'R_Top_Bar.dart';
import 'View_Shortlisted_Detials.dart';
import 'shortlisting_provider.dart';

class Shortlisting extends StatefulWidget {
  const Shortlisting({super.key});

  @override
  State<Shortlisting> createState() => _ShortlistingState();
}

class _ShortlistingState extends State<Shortlisting> with TickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _selectionBarController;
  late Animation<double> _selectionBarAnimation;

  static const _primary = Color(0xFF6366F1);
  static const _accent = Color(0xFFEC4899);
  static const _secondary = Color(0xFF8B5CF6);
  static const _surface = Color(0xFFFFFFFF);
  static const _background = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _selectionBarController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _selectionBarAnimation = CurvedAnimation(
      parent: _selectionBarController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    _selectionBarController.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    if (parts[0].length <= 2) return email;
    return '${parts[0].substring(0, 2)}•••@${parts[1]}';
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    return '•••-${phone.substring(phone.length - 4)}';
  }

  double _getScore(Candidate c) {
    if (c.matchScore == null) return 0.0;
    final score = c.matchScore!['overallScore'] ?? c.matchScore!['overall_score'] ?? 0;
    return (score is num) ? score.toDouble() : 0.0;
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return _success;
    if (score >= 70) return _primary;
    if (score >= 50) return _warning;
    return _error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Row(
        children: [
          RecruiterSidebar(activeIndex: 1),
          Expanded(
            child: ChangeNotifierProvider(
              create: (_) => Shortlisting_provider(),
              builder: (context, _) {
                final prov = Provider.of<Shortlisting_provider>(context);

                // Animate selection bar when items are selected
                if (prov.selectedUids.isNotEmpty && !_selectionBarController.isAnimating) {
                  _selectionBarController.forward();
                } else if (prov.selectedUids.isEmpty) {
                  _selectionBarController.reverse();
                }

                return prov.loading ? _buildLoading() : _buildMainContent(prov);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(Shortlisting_provider prov) {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            // SliverPadding(
            //   padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            //   sliver: SliverToBoxAdapter(child: _buildStatsGrid(prov)),
            // ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildChartsSection(prov)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(child: _buildSearchBar(prov)),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(child: _buildCandidatesTable(prov)),
            ),
          ],
        ),
        if (prov.selectedUids.isNotEmpty) _buildDynamicIslandBar(prov),
      ],
    );
  }

  Widget _buildDynamicIslandBar(Shortlisting_provider prov) {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: ScaleTransition(
          scale: _selectionBarAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_textPrimary, _textPrimary.withOpacity(0.95)],
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: _textPrimary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: _accent),
                      const SizedBox(width: 6),
                      Text(
                        '${prov.selectedUids.length}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Selected',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: prov.clearSelection,
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.white70,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Clear',
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _handleSend(prov),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text('Send to Admin', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_primary, _secondary]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.people_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Candidate Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Manage and review shortlisted candidates',
                style: GoogleFonts.inter(fontSize: 12, color: _textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Shortlisting_provider prov) {
    final scores = prov.candidates.map(_getScore).toList();
    final avg = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    final high = scores.where((s) => s >= 80).length;

    return Row(
      children: [
        Expanded(child: _buildStatCard(icon: Icons.group_rounded, label: 'Total', value: '${prov.candidates.length}', trend: '+12%', trendUp: true)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(icon: Icons.trending_up_rounded, label: 'Avg Score', value: '${avg.toInt()}%', trend: '+5%', trendUp: true)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(icon: Icons.stars_rounded, label: 'High Match', value: '$high', trend: '+8%', trendUp: true)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(icon: Icons.check_circle_rounded, label: 'Selected', value: '${prov.selectedUids.length}', trend: null, trendUp: null)),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, String? trend, bool? trendUp}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: _primary, size: 16),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: (trendUp! ? _accent : _error).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendUp ? Icons.arrow_upward : Icons.arrow_downward, size: 10, color: trendUp ? _accent : _error),
                      const SizedBox(width: 3),
                      Text(trend, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: trendUp ? _accent : _error)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: _textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Shortlisting_provider prov) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: prov.setSearch,
              style: GoogleFonts.inter(fontSize: 13, color: _textPrimary),
              decoration: InputDecoration(
                hintText: 'Search candidates...',
                hintStyle: GoogleFonts.inter(color: _textSecondary, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: _textSecondary, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildFilterChip('Nationality: ${prov.selectedNationality ?? "All"}', onTap: () {
          final opts = ['All', ...prov.nationalityOptions];
          final currIdx = opts.indexOf(prov.selectedNationality ?? 'All');
          final next = opts[(currIdx + 1) % opts.length];
          prov.setNationalityFilter(next == 'All' ? null : next);
        }),
        const SizedBox(width: 10),
        _buildFilterChip('Sort: ${prov.sortOption}', onTap: () {
          final opts = ['None', 'Score High→Low', 'Name A→Z'];
          final currIdx = opts.indexOf(prov.sortOption);
          final next = opts[(currIdx + 1) % opts.length];
          prov.setSortOption(next);
        }),
      ],
    );
  }

  Widget _buildFilterChip(String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: GoogleFonts.inter(fontSize: 12, color: _textPrimary, fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            Icon(Icons.unfold_more, size: 14, color: _textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(Shortlisting_provider prov) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildScoreDistributionChart(prov)),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildTrendChart(prov)),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildNationality(prov)),
        const SizedBox(width: 12),
        Expanded(child: _buildTopCandidates(prov)),
      ],
    );
  }

  Widget _buildScoreDistributionChart(Shortlisting_provider prov) {
    final scores = prov.candidates.map(_getScore).toList();
    final ranges = [
      ('90+', scores.where((s) => s >= 90).length),
      ('80-89', scores.where((s) => s >= 80 && s < 90).length),
      ('70-79', scores.where((s) => s >= 70 && s < 80).length),
      ('60-69', scores.where((s) => s >= 60 && s < 70).length),
      ('<60', scores.where((s) => s < 60).length),
    ];

    final maxY = ranges.map((e) => e.$2.toDouble()).reduce(max);
    final colors = [_success, _primary, _accent, _warning, _error];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: _primary, size: 16),
              const SizedBox(width: 6),
              Text('Score Distribution', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
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
                      getTitlesWidget: (value, meta) => value.toInt() >= 0 && value.toInt() < ranges.length
                          ? Padding(padding: const EdgeInsets.only(top: 6), child: Text(ranges[value.toInt()].$1, style: GoogleFonts.inter(fontSize: 10, color: _textSecondary)))
                          : const SizedBox(),
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.inter(fontSize: 10, color: _textSecondary)))),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1, getDrawingHorizontalLine: (value) => FlLine(color: _border, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(ranges.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: ranges[i].$2.toDouble(), gradient: LinearGradient(colors: [colors[i], colors[i].withOpacity(0.7)], begin: Alignment.topCenter, end: Alignment.bottomCenter), width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(Shortlisting_provider prov) {
    final weeklyData = [FlSpot(0, 65), FlSpot(1, 70), FlSpot(2, 68), FlSpot(3, 75), FlSpot(4, 78), FlSpot(5, 82), FlSpot(6, 85)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: _accent, size: 16),
              const SizedBox(width: 6),
              Text('Match Score Trend', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
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
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return value.toInt() >= 0 && value.toInt() < days.length ? Padding(padding: const EdgeInsets.only(top: 6), child: Text(days[value.toInt()], style: GoogleFonts.inter(fontSize: 10, color: _textSecondary))) : const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: GoogleFonts.inter(fontSize: 10, color: _textSecondary)))),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 60,
                maxY: 90,
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyData,
                    isCurved: true,
                    gradient: LinearGradient(colors: [_accent, _secondary]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: _accent, strokeWidth: 2, strokeColor: _surface)),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [_accent.withOpacity(0.2), _accent.withOpacity(0.05)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNationality(Shortlisting_provider prov) {
    // 1. Data Preparation
    final nationalityCounts = <String, int>{};
    for (var c in prov.candidates) {
      nationalityCounts[c.nationality] = (nationalityCounts[c.nationality] ?? 0) + 1;
    }

    // Sort and take top 5 for bar chart (Bars can handle more data than Pie)
    final sorted = nationalityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    // Calculate max for Y-axis scaling
    final maxY = top5.isNotEmpty ? top5.first.value.toDouble() * 1.2 : 10.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: _primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Nationality Distribution',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary
                    ),
                  ),
                ],
              ),
              // Total Count Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  'Top ${top5.length}',
                  style: GoogleFonts.inter(fontSize: 10, color: _textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart Content
          if (top5.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No nationality data available',
                  style: GoogleFonts.inter(fontSize: 12, color: _textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  // Hide Grid Lines for cleaner 3D look
                  gridData: FlGridData(show: false),
                  // Hide Borders
                  borderData: FlBorderData(show: false),
                  // Tooltip Customization
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => _textPrimary,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${top5[groupIndex].key}\n',
                          GoogleFonts.inter(
                            color: _surface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toInt()} Candidates',
                              style: GoogleFonts.inter(
                                color: _surface.withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= top5.length) return const SizedBox();
                          final name = top5[value.toInt()].key;
                          // Truncate name to 3 chars for cleaner axis (e.g., USA, IND)
                          final label = name.length > 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: GoogleFonts.inter(
                                  color: _textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: top5.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;

                    // Use different base colors for variety, or single color
                    final baseColor = index == 0 ? _primary : _primary.withOpacity(0.7 - (index * 0.1));

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.value.toDouble(),
                          width: 24, // Thicker bars for cylinder effect
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          // THE 3D TRICK: Linear Gradient from lighter to darker
                          gradient: LinearGradient(
                            colors: [
                              baseColor.withOpacity(0.6), // Highlight (Left)
                              baseColor,                  // Mid
                              baseColor.withOpacity(0.9), // Shadow (Right)
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: _background,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildTopCandidates(Shortlisting_provider prov) {
    final sorted = List<Candidate>.from(prov.candidates)..sort((a, b) => _getScore(b).compareTo(_getScore(a)));
    final top3 = sorted.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: _warning, size: 16),
              const SizedBox(width: 6),
              Text('Top 3', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (top3.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: Text('No data', style: GoogleFonts.inter(fontSize: 12, color: _textSecondary))))
          else
            ...top3.asMap().entries.map((entry) {
              final index = entry.key;
              final candidate = entry.value;
              final score = _getScore(candidate);
              return Padding(
                padding: EdgeInsets.only(bottom: index < 2 ? 12 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: index == 0 ? _warning.withOpacity(0.15) : _border, shape: BoxShape.circle),
                      child: Text('${index + 1}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: index == 0 ? _warning : _textSecondary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(candidate.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${score.toInt()}% match', style: GoogleFonts.inter(fontSize: 10, color: _textSecondary)),
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

  Widget _buildCandidatesTable(Shortlisting_provider prov) {
    final list = prov.searchQuery.isEmpty ? prov.candidates : prov.filtered;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Table Title Row ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'All Candidates',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${list.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _border),

          // --- Table Headers ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: _background,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Checkbox(
                    // Logic: Check if all current candidates are in the selected list
                    value: list.isNotEmpty && prov.selectedUids.length == list.length,
                    onChanged: (bool? value) {
                      prov.toggleAll(value, list); // Calls the toggle all logic
                    },
                    // MAKES IT A TOTAL CIRCLE
                    shape: const CircleBorder(),
                    activeColor: _primary,
                    side: BorderSide(color: _textSecondary.withOpacity(0.5), width: 1.5),
                  ),
                ),
                const SizedBox(width: 16),
                _tableHeader('NAME', flex: 4),
                _tableHeader('CONTACT', flex: 3),
                _tableHeader('SCORE', flex: 1),
                _tableHeader('ACTION', flex: 2),
              ],
            ),
          ),
          // --- Table Content ---
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: _textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'No candidates found',
                    style: GoogleFonts.inter(color: _textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ...list.map((c) => _buildCandidateRow(c, prov)),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primary, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            'Loading candidates...',
            style: GoogleFonts.inter(color: _textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
  Widget _buildCandidateRow(Candidate c, Shortlisting_provider prov) {
    final selected = prov.selectedUids.contains(c.uid);
    final score = _getScore(c);
    final scoreColor = _getScoreColor(score);

    return InkWell(
      onTap: () => prov.toggleSelection(c.uid),
      hoverColor: _primary.withOpacity(0.01),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _border)),
          color: selected ? _primary.withOpacity(0.02) : null,
        ),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 24,
              child: Checkbox(
                value: selected,
                activeColor: _primary,
                shape: const CircleBorder(),

                onChanged: (v) => prov.toggleSelection(c.uid, value: v),
              ),
            ),
            const SizedBox(width: 16),

            // 1. NAME COLUMN (Flex 4)
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _background,
                    backgroundImage: c.pictureUrl.isNotEmpty ? NetworkImage(c.pictureUrl) : null,
                    child: c.pictureUrl.isEmpty
                        ? Text(
                      c.name[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // 2. CONTACT COLUMN (Flex 3)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: _textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _maskEmail(c.email),
                          style: GoogleFonts.inter(fontSize: 13, color: _textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 14, color: _textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _maskPhone(c.phone),
                        style: GoogleFonts.inter(fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. SCORE COLUMN (Flex 1)
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: scoreColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${score.toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // 4. ACTION COLUMN (Flex 2) - UPDATED
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start, // Aligns button to the left of the column
                children: [
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () async {
                        final profile = await prov.fetchProfile(c.uid);
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (_) => CandidateDetailsDialog(
                              candidate: c,
                              profile: profile,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _primary.withOpacity(0.5)),
                        backgroundColor: Colors.transparent,
                        foregroundColor: _primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(
                        'View Details',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 12
                        ),
                      ),
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
  Future<void> _handleSend(Shortlisting_provider prov) async {
    final id = await prov.sendSelectedCandidatesToAdmin(notes: 'Sent from dashboard');
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: _accent, size: 28),
            const SizedBox(width: 12),
            Text(
              'Success',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Request $id submitted successfully.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}