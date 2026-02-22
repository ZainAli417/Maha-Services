import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'admin_analytics_dashboard_Provider.dart';

class AdminAnalyticsDashboardScreen extends StatefulWidget {
  const AdminAnalyticsDashboardScreen({super.key});

  @override
  State<AdminAnalyticsDashboardScreen> createState() => _AdminAnalyticsDashboardScreenState();
}

class _AdminAnalyticsDashboardScreenState extends State<AdminAnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminAnalyticsProvider>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<AdminAnalyticsProvider>(
        builder: (context, prov, child) {
          final isWide = MediaQuery.of(context).size.width > 1100;

          return Column(
            children: [
              _buildModernHeader(prov),
              Expanded(
                child: prov.loading && prov.totalUsers == 0
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                    : RefreshIndicator(
                  onRefresh: prov.refresh,
                  backgroundColor: Colors.white,
                  color: const Color(0xFF6366F1),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // MAIN CONTENT
                      Expanded(
                        flex: 7,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Overview Metrics'),
                              const SizedBox(height: 16),
                              _buildKPISection(prov, isWide),
                              const SizedBox(height: 32),
                              _buildSectionTitle('Platform Activity & Demand'),
                              const SizedBox(height: 16),
                              if (isWide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: _buildSkillsBarChart(prov)),
                                    const SizedBox(width: 24),
                                    Expanded(flex: 2, child: _buildTopRecruitersCard(prov)),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _buildSkillsBarChart(prov),
                                    const SizedBox(height: 24),
                                    _buildTopRecruitersCard(prov),
                                  ],
                                ),
                              const SizedBox(height: 32),
                              if (isWide)
                                Row(
                                  children: [
                                    Expanded(child: _buildPieCard(
                                      title: 'Requests Distribution',
                                      data: prov.requestsByStatus,
                                      colors: [const Color(0xFFF59E0B), const Color(0xFF10B981), const Color(0xFFEF4444)],
                                    )),
                                    const SizedBox(width: 24),
                                    Expanded(child: _buildPieCard(
                                      title: 'Jobs Distribution',
                                      data: prov.jobsByStatus,
                                      colors: [const Color(0xFF3B82F6), const Color(0xFF64748B)],
                                    )),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _buildPieCard(
                                      title: 'Requests Distribution',
                                      data: prov.requestsByStatus,
                                      colors: [const Color(0xFFF59E0B), const Color(0xFF10B981), const Color(0xFFEF4444)],
                                    ),
                                    const SizedBox(height: 24),
                                    _buildPieCard(
                                      title: 'Jobs Distribution',
                                      data: prov.jobsByStatus,
                                      colors: [const Color(0xFF3B82F6), const Color(0xFF64748B)],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // RIGHT SIDE PANEL: Recent Requests
                      if (isWide)
                        Container(
                          width: 380,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(left: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: _buildRightSidePanel(prov),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildModernHeader(AdminAnalyticsProvider prov) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Real-time Platform Insights',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (prov.loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  // ─── KPI Section ──────────────────────────────────────────────────────────

  Widget _buildKPISection(AdminAnalyticsProvider prov, bool isWide) {
    final kpis = [
      _KPI('Total Users', prov.totalUsers, Icons.groups_outlined, const Color(0xFF3B82F6),
          subtitle: 'JobSeeker: ${prov.totalJobSeekers} | Recruiter: ${prov.totalRecruiters} | Admin: ${prov.totalAdmins}'),
      _KPI('Total Jobs Posted', prov.totalJobs, Icons.work_outline, const Color(0xFF10B981),
          subtitle: 'Across platform'),
      _KPI('Total Requests', prov.totalRequests, Icons.forward_to_inbox, const Color(0xFFF59E0B),
          subtitle: 'Received from recruiters'),
      _KPI('Handover Candidates', prov.candidatesProcessed, Icons.verified_user_outlined, const Color(0xFF8B5CF6),
          subtitle: 'Candidates with status Handover'),
    ];

    if (isWide) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 3,
        children: kpis.map((kpi) => _buildKPICard(kpi)).toList(),
      );
    } else {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3,
        children: kpis.map((kpi) => _buildKPICard(kpi)).toList(),
      );
    }
  }

  Widget _buildKPICard(_KPI kpi) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: kpi.color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kpi.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(kpi.icon, color: kpi.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  kpi.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: kpi.value),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Text(
                      value.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  kpi.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Charts Section ───────────────────────────────────────────────────────

  Widget _buildSkillsBarChart(AdminAnalyticsProvider prov) {
    final skills = prov.skillFrequencies.keys.toList();
    final counts = prov.skillFrequencies.values.toList();
    final maxCount = counts.isNotEmpty ? counts.reduce((a, b) => a > b ? a : b) : 1;

    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'In-Demand Technical Skills',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            'Based on latest Job Seeker profiles',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: skills.isEmpty
                ? const Center(child: Text("Not enough data to graph", style: TextStyle(color: Colors.grey)))
                : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount.toDouble() * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${skills[group.x]}\n${rod.toY.round()} Users',
                        GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= skills.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            skills[index].length > 10 ? '${skills[index].substring(0, 8)}..' : skills[index],
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  skills.length,
                      (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: counts[i].toDouble(),
                        color: const Color(0xFF6366F1),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      )
                    ],
                  ),
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRecruitersCard(AdminAnalyticsProvider prov) {
    final tops = prov.topRecruiters;
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
             'Top Active Recruiters',
             style: GoogleFonts.poppins(
               fontSize: 16,
               fontWeight: FontWeight.w600,
               color: const Color(0xFF1E293B),
             ),
          ),
          Text(
            'By total request volume',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
             child: tops.isEmpty
                 ? const Center(child: Text("No recruiters activity yet", style: TextStyle(color: Colors.grey)))
                 : ListView.separated(
                   itemCount: tops.length,
                   separatorBuilder: (c,i) => const SizedBox(height: 16),
                   itemBuilder: (context, i) {
                     final email = tops.keys.elementAt(i);
                     final count = tops[email]!;
                     return Row(
                       children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                            child: Text(email[0].toUpperCase(), style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              email,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF334155)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                               color: const Color(0xFFF1F5F9),
                               borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text(
                              '$count reqs',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                            ),
                          )
                       ],
                     );
                   }
                 )
          )
        ],
      ),
    );
  }

  Widget _buildPieCard({required String title, required Map<String, int> data, required List<Color> colors}) {
    final hasData = data.values.any((v) => v > 0);
    int total = hasData ? data.values.reduce((a, b) => a + b) : 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          if (!hasData)
            const SizedBox(
              height: 180,
              child: Center(child: Text("No Data", style: TextStyle(color: Colors.grey))),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 45,
                        sections: List.generate(data.keys.length, (i) {
                          final key = data.keys.elementAt(i);
                          final value = data[key]!;
                          return PieChartSectionData(
                            color: colors[i % colors.length],
                            value: value.toDouble(),
                            title: '${((value / total) * 100).toStringAsFixed(0)}%',
                            radius: 20,
                            titleStyle: GoogleFonts.poppins(
                                fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 600),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(data.keys.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${data.keys.elementAt(i)} (${data.values.elementAt(i)})',
                                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF475569)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── RIGHT SIDE PANEL ──────────────────────────────────────────────────────

  Widget _buildRightSidePanel(AdminAnalyticsProvider prov) {
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          Container(
             padding: const EdgeInsets.all(24),
             decoration: const BoxDecoration(
               border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
             ),
             child: Row(
                children: [
                   const Icon(Icons.history, color: Color(0xFF6366F1), size: 20),
                   const SizedBox(width: 10),
                   Text(
                      'Recent Real-time Requests',
                      style: GoogleFonts.poppins(
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                         color: const Color(0xFF1E293B)
                      ),
                   )
                ],
             )
          ),
          Expanded(
             child: prov.recentRequests.isEmpty
                ? const Center(
                    child: Padding(
                       padding: EdgeInsets.all(24.0),
                       child: Text('No recent requests available.', style: TextStyle(color: Colors.grey)),
                    )
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: prov.recentRequests.length,
                    separatorBuilder: (c, i) => const Divider(height: 24, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                       final r = prov.recentRequests[index];
                       Color sColor = Colors.grey;
                       final s = r['status'].toString().toLowerCase();
                       if (s == 'approved' || s == 'active') sColor = const Color(0xFF10B981);
                       else if (s == 'pending') sColor = const Color(0xFFF59E0B);
                       else if (s == 'rejected' || s == 'closed') sColor = const Color(0xFFEF4444);

                       return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text(
                                    r['createdStr'],
                                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF94A3B8)),
                                 ),
                                 Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: sColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4)
                                    ),
                                    child: Text(
                                       s.toUpperCase(),
                                       style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: sColor),
                                    ),
                                 )
                               ],
                             ),
                             const SizedBox(height: 8),
                             Row(
                               children: [
                                  const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                     child: Text(
                                        r['recruiterEmail'],
                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                        overflow: TextOverflow.ellipsis,
                                     ),
                                  ),
                               ],
                             ),
                             const SizedBox(height: 4),
                             Row(
                               children: [
                                  const Icon(Icons.people_outline, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(
                                     '${r['candidatesCount']} Candidates Processed',
                                     style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                                  ),
                               ],
                             )
                          ],
                       );
                    }
                  )
          )
       ],
    );
  }
}

class _KPI {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String subtitle;

  _KPI(this.title, this.value, this.icon, this.color, {required this.subtitle});
}
