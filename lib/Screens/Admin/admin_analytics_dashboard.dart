import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'admin_analytics_dashboard_Provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS  — Light Professional
// ═══════════════════════════════════════════════════════════════════════════
class _C {
  static const canvas = Color(0xFFF4F9FB); // bgSoft
  static const surface = Color(0xFFFFFFFF);
  static const surfaceL = Color(0xFFFAFBFD);
  static const border = Color(0xFFDCE7EF);

  // Brand primaries — navy + teal. Named for clarity in chart series.
  static const navy = Color(0xFF14507F);
  static const navyDeep = Color(0xFF0A2E4F);
  static const blue = Color(0xFF2178B5);
  static const tealDeep = Color(0xFF15A99C);
  static const tealBright = Color(0xFF43E0D2);
  static const coral = Color(0xFFFF7A59);
  static const coralLt = Color(0xFFFFEDE7);

  // Legacy token names retained, values rebranded to the navy+teal palette
  // (indigo → navy, violet → blue) so all charts/cards stay coherent.
  static const indigo = Color(0xFF14507F); // navy
  static const indigoLt = Color(0xFFE8F1F8); // navy tint
  static const teal = Color(0xFF2EC4B6);
  static const tealLt = Color(0xFFE4F6F4); // teal tint
  static const emerald = Color(0xFF10B981); // success
  static const emeraldL = Color(0xFFDCFCED);
  static const amber = Color(0xFFF59E0B); // warning / pending
  static const amberLt = Color(0xFFFEF3CD);
  static const rose = Color(0xFFEF4444); // error
  static const roseLt = Color(0xFFFCE7ED);
  static const violet = Color(0xFF2178B5); // blue
  static const violetLt = Color(0xFFE8F1F8); // navy tint
  static const slate = Color(0xFF3E5C76);

  static const t1 = Color(0xFF0B2239); // ink
  static const t2 = Color(0xFF3E5C76); // slate
  static const t3 = Color(0xFF8AA5B5); // faint

  static TextStyle p(
    double size, {
    FontWeight fw = FontWeight.w600,
    Color color = t1,
  }) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: fw, color: color);
}

// ═══════════════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class AdminAnalyticsDashboardScreen extends StatefulWidget {
  final Function(String)? onNavigate;
  const AdminAnalyticsDashboardScreen({super.key, this.onNavigate});

  @override
  State<AdminAnalyticsDashboardScreen> createState() =>
      _AdminAnalyticsDashboardScreenState();
}

class _AdminAnalyticsDashboardScreenState
    extends State<AdminAnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminAnalyticsProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.canvas,
      body: Consumer<AdminAnalyticsProvider>(
        builder: (context, prov, _) {
          final w = MediaQuery.sizeOf(context).width;
          final isWide = w > 1180;
          final isMid = w > 760;

          return Column(
            children: [
              if (isMid) _buildModernHeader(context, prov),
              Expanded(
                child: prov.loading && prov.totalUsers == 0
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: _C.navy,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading analytics…',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5E7A8E),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: prov.refresh,
                        color: _C.navy,
                        backgroundColor: _C.surface,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.all(isWide ? 28 : 16),
                                child: _MainContent(
                                  prov: prov,
                                  isWide: isWide,
                                  isMid: isMid,
                                  onNavigate: widget.onNavigate,
                                ),
                              ),
                            ),
                            if (isWide) _RightPanel(prov: prov),
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

  Widget _buildModernHeader(BuildContext context, AdminAnalyticsProvider prov) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return Container(
      height: 72,
      decoration: const BoxDecoration(color: _C.canvas),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.teal, _C.navy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _C.teal.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.supervised_user_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN ANALYTICS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: _C.tealDeep,
                  ),
                ),
                Text(
                  'Insights Dashboard',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w800,
                    color: _C.t1,
                  ),
                ),
                Text(
                  'View Your Platform Performance at a Glance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.t2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _BarBtn(
            icon: Icons.refresh_rounded,
            onTap: prov.refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TOP BAR
// ═══════════════════════════════════════════════════════════════════════════

class _BarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _BarBtn({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: _C.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _C.t2, size: 18),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MAIN CONTENT
// ═══════════════════════════════════════════════════════════════════════════
class _MainContent extends StatelessWidget {
  final AdminAnalyticsProvider prov;
  final bool isWide, isMid;
  final Function(String)? onNavigate;
  const _MainContent({
    required this.prov,
    required this.isWide,
    required this.isMid,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PAGE HEADING
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _C.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live · Real-time data',
                      style: _C.p(12, fw: FontWeight.w500, color: _C.t3),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const _Chip(
              label: 'Today',
              icon: Icons.calendar_today_rounded,
              color: _C.indigo,
              tiny: false,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // KPI CARDS
        _KpiGrid(prov: prov, isMid: isMid, onNavigate: onNavigate),
        const SizedBox(height: 28),

        // USER BREAKDOWN
        const _SectionHead(icon: Icons.people_alt_rounded, title: 'User Composition'),
        const SizedBox(height: 14),
        _UserBreakdown(prov: prov, isMid: isMid),
        const SizedBox(height: 28),

        // SKILLS + RECRUITERS
        const _SectionHead(
          icon: Icons.stacked_bar_chart_rounded,
          title: 'Demand Intelligence',
        ),
        const SizedBox(height: 14),
        isMid
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _SkillsChart(prov: prov)),
                  const SizedBox(width: 20),
                  // Expanded(flex: 2, child: _TopRecruiters(prov: prov)),
                ],
              )
            : Column(
                children: [
                  _SkillsChart(prov: prov),
                  // const SizedBox(height: 20),
                  // _TopRecruiters(prov: prov),
                ],
              ),
        const SizedBox(height: 28),

        // STATUS BREAKDOWN  — line chart + bar chart
        const _SectionHead(icon: Icons.analytics_outlined, title: 'Status Breakdown'),
        const SizedBox(height: 14),
        isMid
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _RequestsLineCard(data: prov.requestsByStatus),
                  ),
                  const SizedBox(width: 20),
                  Expanded(child: _JobsBarCard(data: prov.jobsByStatus)),
                ],
              )
            : Column(
                children: [
                  _RequestsLineCard(data: prov.requestsByStatus),
                  const SizedBox(height: 20),
                  _JobsBarCard(data: prov.jobsByStatus),
                ],
              ),
        const SizedBox(height: 28),

        // GEOGRAPHICAL DISTRIBUTION — jobs + applicants by location
        const _SectionHead(
          icon: Icons.public_rounded,
          title: 'Geographical Distribution',
        ),
        const SizedBox(height: 14),
        isMid
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _GeoCard(data: prov.jobsByLocation)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _GeoCard(
                      data: prov.applicantsByLocation,
                      icon: Icons.groups_rounded,
                      title: 'Applicants by Region',
                      subtitle: 'Top applicant countries / regions',
                      emptyLabel: 'No applicant region data yet',
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _GeoCard(data: prov.jobsByLocation),
                  const SizedBox(height: 20),
                  _GeoCard(
                    data: prov.applicantsByLocation,
                    icon: Icons.groups_rounded,
                    title: 'Applicants by Region',
                    subtitle: 'Top applicant countries / regions',
                    emptyLabel: 'No applicant region data yet',
                  ),
                ],
              ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// Branded "Jobs by Location" card — ranked proportional bars (teal→navy) with
/// a no-data state. Lightweight (no chart lib) and RepaintBoundary-isolated.
class _GeoCard extends StatelessWidget {
  final Map<String, int> data;
  final IconData icon;
  final String title;
  final String subtitle;
  final String emptyLabel;
  const _GeoCard({
    required this.data,
    this.icon = Icons.public_rounded,
    this.title = 'Jobs by Location',
    this.subtitle = 'Top hiring regions',
    this.emptyLabel = 'No location data yet',
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxV = entries.isEmpty
        ? 1
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140B2239),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.tealDeep, _C.navy],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: _C.p(15, fw: FontWeight.w800)),
                      Text(subtitle,
                          style:
                              _C.p(12, fw: FontWeight.w500, color: _C.t3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: _C.tealLt,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.map_outlined,
                            color: _C.tealDeep, size: 26),
                      ),
                      const SizedBox(height: 12),
                      Text(emptyLabel,
                          style: _C.p(13, fw: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'Data appears here as records are added.',
                        textAlign: TextAlign.center,
                        style: _C.p(12, fw: FontWeight.w500, color: _C.t3),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(entries.length, (i) {
                final e = entries[i];
                final frac = maxV == 0 ? 0.0 : e.value / maxV;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: i == entries.length - 1 ? 0 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _C.p(13, fw: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${e.value}',
                              style: _C.p(13,
                                  fw: FontWeight.w800, color: _C.navy)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          children: [
                            Container(height: 8, color: _C.canvas),
                            FractionallySizedBox(
                              widthFactor: frac.clamp(0.04, 1.0),
                              child: Container(
                                height: 8,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_C.teal, _C.navy],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

void _showJobsPopup(BuildContext context, AdminAnalyticsProvider prov) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  color: _C.tealLt,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: _C.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.work_history_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Jobs',
                            style: _C.p(
                              20,
                              fw: FontWeight.w800,
                              color: _C.teal,
                            ),
                          ),
                          Text(
                            'Overview of latest posted listings',
                            style: _C.p(13, color: _C.t2),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _C.t2),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 24,
                    ),
                  ],
                ),
              ),
              // BODY
              Expanded(
                child: prov.allJobs.isEmpty
                    ? Center(
                        child: Text(
                          'No jobs found.',
                          style: _C.p(15, color: _C.t3),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: prov.allJobs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, i) {
                          final job = prov.allJobs[i];
                          final status = (job['status'] ?? 'Open').toString();
                          final isOpen = status.toLowerCase() == 'open';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _C.surface,
                              border: Border.all(color: _C.border),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x05000000),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job['title'] ?? 'Untitled Job',
                                        style: _C.p(16, fw: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.business_center_rounded,
                                            size: 14,
                                            color: _C.t3,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              job['company'] ??
                                                  'Unknown Company',
                                              style: _C.p(13, color: _C.t2),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_rounded,
                                            size: 14,
                                            color: _C.t3,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            job['location'] ?? 'Remote',
                                            style: _C.p(12, color: _C.t3),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: _C.t3,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            job['type'] ?? 'Full-time',
                                            style: _C.p(12, color: _C.t3),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Right Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOpen ? _C.emeraldL : _C.roseLt,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: _C.p(
                                      11,
                                      fw: FontWeight.w700,
                                      color: isOpen ? _C.emerald : _C.rose,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showMultiSelectSkills(BuildContext context, AdminAnalyticsProvider prov) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 350,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Skills', style: _C.p(16, fw: FontWeight.w700)),
                  if (prov.selectedSkills.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => prov.clearSkills(),
                      child: Text('Clear', style: _C.p(14, color: _C.rose)),
                    ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Consumer<AdminAnalyticsProvider>(
                  builder: (context, p, _) {
                    final allSkills = p.getAllRawSkills();
                    if (allSkills.isEmpty) {
                      return Center(
                        child: Text(
                          'No skills available',
                          style: _C.p(14, color: _C.t3),
                        ),
                      );
                    }
                    return Scrollbar(
                      child: ListView.builder(
                        itemCount: allSkills.length,
                        itemBuilder: (context, i) {
                          final skill = allSkills[i];
                          return CheckboxListTile(
                            title: Text(
                              skill,
                              style: _C.p(14, fw: FontWeight.w600),
                            ),
                            value: p.selectedSkills.contains(skill),
                            onChanged: (_) => p.toggleSkill(skill),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: _C.indigo,
                            dense: true,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: _C.p(14, fw: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  KPI GRID
// ═══════════════════════════════════════════════════════════════════════════
// ─── KPI data model ───────────────────────────────────────────────────────
class _KD {
  final IconData icon;
  final String label, sub;
  final int value;
  final Color accent, bg;
  final VoidCallback? onTap;
  const _KD(
    this.icon,
    this.label,
    this.value,
    this.sub,
    this.accent,
    this.bg, {
    this.onTap,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// KPI GRID
// Three layouts driven by breakpoint:
//   desktop (isMid) → single row of 4 cards (existing behaviour)
//   tablet           → 2×2 grid, cards have fixed compact height
//   mobile (<480)   → vertical list of horizontal mini-cards (no overflow)
// ═════════════════════════════════════════════════════════════════════════════
class _KpiGrid extends StatelessWidget {
  final AdminAnalyticsProvider prov;
  final bool isMid;
  final Function(String)? onNavigate;
  const _KpiGrid({required this.prov, required this.isMid, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = [
      _KD(
        Icons.groups_rounded,
        'Total Users',
        prov.totalUsers,
        '${prov.activeUsers} active',
        _C.indigo,
        _C.indigoLt,
        onTap: () => onNavigate?.call('User Management'),
      ),
      _KD(
        Icons.verified_user_rounded,
        'Active Users',
        prov.activeUsers,
        'account_status = active',
        _C.emerald,
        _C.emeraldL,
        onTap: () => onNavigate?.call('User Management'),
      ),
      _KD(
        Icons.person_search_rounded,
        'Job Seekers',
        prov.totalJobSeekers,
        'Candidates',
        _C.blue,
        _C.indigoLt,
        onTap: () => onNavigate?.call('User Management'),
      ),
      _KD(
        Icons.business_center_rounded,
        'Recruiters',
        prov.totalRecruiters,
        '${prov.totalRecruitmentAgents} agents',
        _C.teal,
        _C.tealLt,
        onTap: () => onNavigate?.call('User Management'),
      ),
      _KD(
        Icons.badge_rounded,
        'Recruitment Agents',
        prov.totalRecruitmentAgents,
        'Recruiter-tier',
        _C.tealDeep,
        _C.tealLt,
        onTap: () => onNavigate?.call('User Management'),
      ),
      _KD(
        Icons.admin_panel_settings_rounded,
        'Admins',
        prov.totalAdmins,
        'Admin + super admin',
        _C.coral,
        _C.coralLt,
        onTap: () => onNavigate?.call('User Management'),
      ),
      _KD(
        Icons.work_rounded,
        'Jobs Posted',
        prov.totalJobs,
        'Public listings',
        _C.navy,
        _C.indigoLt,
        onTap: () => _showJobsPopup(context, prov),
      ),
      _KD(
        Icons.inbox_rounded,
        'Requests',
        prov.totalRequests,
        'From recruiters',
        _C.amber,
        _C.amberLt,
        onTap: () => onNavigate?.call('Recruiter Requests'),
      ),
      _KD(
        Icons.how_to_reg_rounded,
        'Candidates Processed',
        prov.candidatesProcessed,
        'Handed over',
        _C.tealDeep,
        _C.tealLt,
      ),
    ];

    // Desktop — responsive wrap so any number of KPI cards flows across rows.
    if (isMid) {
      return LayoutBuilder(
        builder: (context, c) {
          const spacing = 16.0;
          final perRow = c.maxWidth >= 1180 ? 4 : 3;
          final cardW =
              (c.maxWidth - spacing * (perRow - 1)) / perRow;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final d in items)
                SizedBox(width: cardW, child: _KpiCardVertical(d: d)),
            ],
          );
        },
      );
    }

    final w = MediaQuery.sizeOf(context).width;

    // Tablet (600–960) — compact 2×2 grid, fixed aspect ratio
    if (w >= 480) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.85, // wider than tall → no overflow
        ),
        itemBuilder: (_, i) => _KpiCardVertical(d: items[i], compact: true),
      );
    }

    // Mobile (<480) — horizontal list cards, fixed height, never overflows
    return Column(
      children: items
          .asMap()
          .entries
          .map(
            (e) => Padding(
              padding: EdgeInsets.only(
                bottom: e.key < items.length - 1 ? 10 : 0,
              ),
              child: _KpiCardHorizontal(d: e.value),
            ),
          )
          .toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VERTICAL CARD  (desktop + tablet)
// ═════════════════════════════════════════════════════════════════════════════
class _KpiCardVertical extends StatelessWidget {
  final _KD d;
  final bool compact;
  const _KpiCardVertical({required this.d, this.compact = false});

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    final p = compact ? 14.0 : 20.0;
    return Container(
      padding: EdgeInsets.all(p),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 8 : 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      d.accent,
                      Color.lerp(d.accent, _C.navyDeep, 0.45)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: d.accent.withValues(alpha: 0.30),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(d.icon, color: Colors.white, size: compact ? 15 : 18),
              ),
              if (d.onTap != null)
                InkWell(
                  onTap: d.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: d.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: _C.p(10, color: d.accent, fw: FontWeight.w700),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 8,
                          color: d.accent,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Icon(
                  Icons.trending_up_rounded,
                  color: d.accent.withValues(alpha: 0.35),
                  size: 15,
                ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: d.value),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(
              _fmt(v),
              style: _C.p(compact ? 20 : 26, fw: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 2),
          Text(d.label, style: _C.p(compact ? 10 : 11, color: _C.t2)),
          const SizedBox(height: 1),
          Text(
            d.sub,
            style: _C.p(compact ? 9 : 10, fw: FontWeight.w500, color: _C.t3),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HORIZONTAL CARD  (mobile — fixed height, never overflows)
// Layout: [icon box] | [label + sub] | [animated number]
// ═════════════════════════════════════════════════════════════════════════════
class _KpiCardHorizontal extends StatelessWidget {
  final _KD d;
  const _KpiCardHorizontal({required this.d});

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64, // fixed — zero chance of overflow
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon box — tinted gradient badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [d.accent, Color.lerp(d.accent, _C.navyDeep, 0.45)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: d.accent.withValues(alpha: 0.28),
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(d.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),

          // Label + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(d.label, style: _C.p(12, fw: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(
                  d.sub,
                  style: _C.p(10, color: _C.t3),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          // Animated count — right-aligned
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (d.onTap != null) ...[
                InkWell(
                  onTap: d.onTap,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: _C.p(10, color: d.accent, fw: FontWeight.w700),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 8,
                          color: d.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: d.value),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text(
                  _fmt(v),
                  style: _C.p(22, fw: FontWeight.w800, color: d.accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} // ═══════════════════════════════════════════════════════════════════════════

//  USER BREAKDOWN ROW
// ═══════════════════════════════════════════════════════════════════════════
class _UserBreakdown extends StatelessWidget {
  final AdminAnalyticsProvider prov;
  final bool isMid;
  const _UserBreakdown({required this.prov, required this.isMid});

  @override
  Widget build(BuildContext context) {
    final total = prov.totalUsers;
    final tiles = [
      _UD(
        'Job Seekers',
        prov.totalJobSeekers,
        Icons.person_search_rounded,
        _C.teal,
        _C.tealLt,
        total,
      ),
      _UD(
        'Recruiters',
        prov.totalRecruiters,
        Icons.business_center_rounded,
        _C.indigo,
        _C.indigoLt,
        total,
      ),
      _UD(
        'Admins',
        prov.totalAdmins,
        Icons.admin_panel_settings_rounded,
        _C.violet,
        _C.violetLt,
        total,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: isMid
          ? Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: total == 0
                      ? const Icon(
                          Icons.donut_large_rounded,
                          color: _C.t3,
                          size: 48,
                        )
                      : RepaintBoundary(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 30,
                              sections: [
                                PieChartSectionData(
                                  color: _C.teal,
                                  value: prov.totalJobSeekers.toDouble(),
                                  title: '',
                                  radius: 16,
                                ),
                                PieChartSectionData(
                                  color: _C.navy,
                                  value: prov.totalRecruiters.toDouble(),
                                  title: '',
                                  radius: 16,
                                ),
                                PieChartSectionData(
                                  color: _C.blue,
                                  value: prov.totalAdmins.toDouble(),
                                  title: '',
                                  radius: 16,
                                ),
                              ],
                            ),
                            swapAnimationDuration: const Duration(
                              milliseconds: 700,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 24),
                Container(width: 1, height: 80, color: _C.border),
                const SizedBox(width: 24),
                ...tiles.map((t) => Expanded(child: _UserTile(d: t))),
              ],
            )
          : Column(
              children: tiles
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _UserTile(d: t),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

// 1. A wrapper to lay them out as compact cards
Widget _buildUserStatsGrid(List<_UD> stats) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    // Using a tight cross-axis count to keep cards compact
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, // Two cards per row
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      mainAxisExtent: 90, // Strict height for compactness
    ),
    itemCount: stats.length,
    itemBuilder: (context, index) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _UserTile(d: stats[index]),
      );
    },
  );
}

// 2. Updated _UserTile (Kept exactly as requested, just minor spacing fix)
class _UserTile extends StatelessWidget {
  final _UD d;
  const _UserTile({required this.d});

  @override
  Widget build(BuildContext context) {
    final pct = d.total > 0 ? (d.value / d.total).clamp(0.0, 1.0) : 0.0;
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center, // Added for compact vertical centering
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: d.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(d.icon, color: d.accent, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.label,
                    style: _C.p(11, fw: FontWeight.w500, color: _C.t2),
                  ),
                  Text(
                    '${d.value}',
                    style: _C.p(16, fw: FontWeight.w800),
                  ), // Slightly smaller for compact
                ],
              ),
            ),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: _C.p(11, color: d.accent, fw: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10), // Spacing before progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: d.bg,
            valueColor: AlwaysStoppedAnimation(d.accent),
            minHeight: 4, // Slightly thinner for "Compact" look
          ),
        ),
      ],
    );
  }
}

class _UD {
  final String label;
  final int value, total;
  final IconData icon;
  final Color accent, bg;
  const _UD(
    this.label,
    this.value,
    this.icon,
    this.accent,
    this.bg,
    this.total,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  SKILLS BAR CHART
// ═══════════════════════════════════════════════════════════════════════════
class _SkillsChart extends StatelessWidget {
  final AdminAnalyticsProvider prov;
  const _SkillsChart({required this.prov});

  @override
  Widget build(BuildContext context) {
    final skills = prov.skillFrequencies.keys.toList();
    final counts = prov.skillFrequencies.values.toList();
    final maxY = counts.isNotEmpty
        ? counts.reduce((a, b) => a > b ? a : b).toDouble() * 1.3
        : 10.0;

    return RepaintBoundary(
      child: _Card(
      height: 370,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _CardHead(
                  icon: Icons.bar_chart_rounded,
                  title: 'Candidates Skills',
                  sub: 'Top ${skills.length} from job seeker profiles',
                  // badge: _Chip(
                  //     label: 'Profiles',
                  //     icon: Icons.people_rounded,
                  //     color: _C.teal),
                ),
              ),
              // Multi-select Skills
              InkWell(
                onTap: () => _showMultiSelectSkills(context, prov),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: prov.selectedSkills.isNotEmpty
                        ? _C.indigoLt
                        : _C.surface,
                    border: Border.all(
                      color: prov.selectedSkills.isNotEmpty
                          ? _C.indigo
                          : _C.border,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 16,
                        color: prov.selectedSkills.isNotEmpty
                            ? _C.indigo
                            : _C.t3,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        prov.selectedSkills.isNotEmpty
                            ? '${prov.selectedSkills.length} Selected'
                            : 'Select Skills',
                        style: _C.p(
                          12,
                          fw: FontWeight.w600,
                          color: prov.selectedSkills.isNotEmpty
                              ? _C.indigo
                              : _C.t2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: skills.isEmpty
                ? const _Empty(
                    icon: Icons.bar_chart_rounded,
                    label: 'No skill data yet',
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => _C.t1,
                          tooltipBorderRadius: BorderRadius.circular(8),

                          getTooltipItem: (group, gi, rod, ri) =>
                              BarTooltipItem(
                                '${skills[group.x]}\n${rod.toY.round()}',
                                _C.p(11, color: Colors.white),
                              ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= skills.length) {
                                return const SizedBox.shrink();
                              }
                              final lbl = skills[i].length > 9
                                  ? '${skills[i].substring(0, 7)}..'
                                  : skills[i];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  lbl,
                                  style: _C.p(
                                    9,
                                    fw: FontWeight.w500,
                                    color: _C.t3,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFFF0F3FA),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(skills.length, (i) {
                        final pct = maxY > 0 ? counts[i] / maxY : 0.0;
                        final col = Color.lerp(
                          _C.indigo,
                          _C.teal,
                          pct.clamp(0.0, 1.0).toDouble(),
                        )!;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: counts[i].toDouble(),
                              gradient: LinearGradient(
                                colors: [col.withValues(alpha: 0.5), col],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 22,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: const Color(0xFFF4F6FB),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 700),
                    swapAnimationCurve: Curves.easeOutCubic,
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TOP RECRUITERS
// ═══════════════════════════════════════════════════════════════════════════
// class _TopRecruiters extends StatelessWidget {
//   final AdminAnalyticsProvider prov;
//   const _TopRecruiters({required this.prov});
//
//   static const _ac = [_C.indigo, _C.teal, _C.emerald, _C.amber, _C.violet];
//
//   @override
//   Widget build(BuildContext context) {
//     final tops = prov.topRecruiters;
//     final keys = tops.keys.toList();
//     final maxV =
//     tops.values.isNotEmpty ? tops.values.reduce((a, b) => a > b ? a : b) : 1;
//
//     return _Card(
//       height: 370,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _CardHead(
//               icon: Icons.leaderboard_rounded,
//               title: 'Top Recruiters',
//               sub: 'By request volume'),
//           const SizedBox(height: 20),
//           Expanded(
//             child: tops.isEmpty
//                 ? _Empty(
//                 icon: Icons.person_search_rounded,
//                 label: 'No recruiter activity yet')
//                 : ListView.builder(
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: keys.length,
//               itemBuilder: (_, i) {
//                 final email = keys[i];
//                 final count = tops[email]!;
//                 final pct = count / maxV;
//                 final col = _ac[i % _ac.length];
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Container(
//                             width: 26,
//                             height: 26,
//                             decoration: BoxDecoration(
//                                 color: col.withValues(alpha: 0.1),
//                                 shape: BoxShape.circle),
//                             alignment: Alignment.center,
//                             child: Text('${i + 1}',
//                                 style: _C.p(10, color: col)),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Text(email,
//                                 style: _C.p(12, color: _C.t1),
//                                 overflow: TextOverflow.ellipsis),
//                           ),
//                           const SizedBox(width: 8),
//                           _Chip(label: '$count req', color: col, tiny: true),
//                         ],
//                       ),
//                       const SizedBox(height: 7),
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(4),
//                         child: LinearProgressIndicator(
//                           value: pct,
//                           backgroundColor: col.withValues(alpha: 0.08),
//                           valueColor: AlwaysStoppedAnimation(col),
//                           minHeight: 4,
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ═══════════════════════════════════════════════════════════════════════════
//  REQUESTS LINE CHART  (replaces requests donut)
// ═══════════════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════
//  REQUESTS BAR CHART (Replaced Line Chart with Jobs styling)
// ═══════════════════════════════════════════════════════════════════════════
class _RequestsLineCard extends StatelessWidget {
  final Map<String, int> data;
  const _RequestsLineCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final labels = data.keys.toList();
    final values = data.values.map((v) => v.toDouble()).toList();
    final hasData = values.any((v) => v > 0);
    final rawMax = hasData ? values.reduce((a, b) => a > b ? a : b) : 0.0;
    final maxY = rawMax < 1 ? 5.0 : rawMax * 1.35;
    final total = values.fold(0, (s, v) => s + v.toInt());

    return RepaintBoundary(
      child: _Card(
      height: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(
            icon: Icons.forward_to_inbox_rounded,
            title: 'Requests by Status',
            sub: 'Distribution across all requests',
            badge: _Chip(label: '$total total', color: _C.indigo, tiny: false),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            const Expanded(
              child: _Empty(icon: Icons.inbox_outlined, label: 'No data yet'),
            )
          else ...[
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => _C.t1,
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipItem: (group, _, rod, _) {
                        final i = group.x;
                        return BarTooltipItem(
                          '${i < labels.length ? labels[i] : ''}\n${rod.toY.round()}',
                          _C.p(10, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[i],
                              style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Color(0xFFF0F3FA), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(labels.length, (i) {
                    // Gradient logic exactly from jobs/skills
                    final pct = maxY > 0 ? values[i] / maxY : 0.0;
                    final col = Color.lerp(
                      _C.indigo,
                      _C.teal,
                      pct.clamp(0.0, 1.0),
                    )!;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          gradient: LinearGradient(
                            colors: [col.withValues(alpha: 0.5), col],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: const Color(0xFFF4F6FB),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
              ),
            ),
            const SizedBox(height: 10),
            // Updated legend to match Bar Chart aesthetics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(labels.length, (i) {
                final pct = maxY > 0 ? values[i] / maxY : 0.0;
                final col = Color.lerp(
                  _C.indigo,
                  _C.teal,
                  pct.clamp(0.0, 1.0),
                )!;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: col,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      labels[i],
                      style: _C.p(10, fw: FontWeight.w500, color: _C.t2),
                    ),
                    const SizedBox(width: 4),
                    Text('${values[i].toInt()}', style: _C.p(10, color: col)),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  JOBS BAR CHART  (replaces jobs donut)  — same gradient style as skills
// ═══════════════════════════════════════════════════════════════════════════
class _JobsBarCard extends StatelessWidget {
  final Map<String, int> data;
  const _JobsBarCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final labels = data.keys.toList();
    final values = data.values.map((v) => v.toDouble()).toList();
    final hasData = values.any((v) => v > 0);
    final rawMax = hasData ? values.reduce((a, b) => a > b ? a : b) : 0.0;
    final maxY = rawMax < 1 ? 5.0 : rawMax * 1.35;
    final total = values.fold(0, (s, v) => s + v.toInt());

    return RepaintBoundary(
      child: _Card(
      height: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(
            icon: Icons.work_outline_rounded,
            title: 'Jobs by Status',
            sub: 'Open vs closed listings',
            badge: _Chip(label: '$total total', color: _C.teal, tiny: false),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            const Expanded(
              child: _Empty(
                icon: Icons.work_outline_rounded,
                label: 'No data yet',
              ),
            )
          else ...[
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => _C.t1,
                      tooltipBorderRadius: const BorderRadius.all(
                        Radius.circular(8),
                      ),
                      getTooltipItem: (group, _, rod, _) {
                        final i = group.x;
                        return BarTooltipItem(
                          '${i < labels.length ? labels[i] : ''}\n${rod.toY.round()}',
                          _C.p(10, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[i],
                              style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Color(0xFFF0F3FA), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(labels.length, (i) {
                    // Lerp indigo→teal based on bar value (same as skills chart)
                    final pct = maxY > 0 ? values[i] / maxY : 0.0;
                    final col = Color.lerp(
                      _C.indigo,
                      _C.teal,
                      pct.clamp(0.0, 1.0),
                    )!;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          gradient: LinearGradient(
                            colors: [col.withValues(alpha: 0.5), col],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: const Color(0xFFF4F6FB),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
              ),
            ),
            const SizedBox(height: 10),
            // Value legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(labels.length, (i) {
                final pct = maxY > 0 ? values[i] / maxY : 0.0;
                final col = Color.lerp(
                  _C.indigo,
                  _C.teal,
                  pct.clamp(0.0, 1.0),
                )!;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: col,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      labels[i],
                      style: _C.p(10, fw: FontWeight.w500, color: _C.t2),
                    ),
                    const SizedBox(width: 4),
                    Text('${values[i].toInt()}', style: _C.p(10, color: col)),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  RIGHT PANEL  — Jobs Glance  +  Live Requests Feed
// ═══════════════════════════════════════════════════════════════════════════
class _RightPanel extends StatelessWidget {
  final AdminAnalyticsProvider prov;
  const _RightPanel({required this.prov});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,

      child: Column(
        children: [
          // ── JOBS AT A GLANCE ──────────────────────────────────────
          _PanelHdr(
            icon: Icons.work_rounded,
            iconBg: _C.tealLt,
            iconColor: _C.teal,
            title: 'Jobs at a Glance',
            sub: 'Platform listings overview',
            badge: _Chip(
              label: '${prov.totalJobs} total',
              icon: Icons.numbers_rounded,
              color: _C.teal,
              tiny: true,
            ),
          ),
          _JobsGlance(prov: prov),

          const Divider(height: 1, thickness: 1, color: _C.border),

          // ── REQUESTS SUMMARY MINI STATS ───────────────────────────
          _PanelHdr(
            icon: Icons.inbox_rounded,
            iconBg: _C.amberLt,
            iconColor: _C.amber,
            title: 'Request Metrics',
            sub: 'Quick snapshot',
            badge: _Chip(
              label: '${prov.totalRequests} total',
              color: _C.amber,
              tiny: false,
            ),
          ),
          _RequestMetrics(prov: prov),

          const Divider(height: 1, thickness: 1, color: _C.border),

          // ── LIVE FEED ─────────────────────────────────────────────
          _PanelHdr(
            icon: Icons.stream_rounded,
            iconBg: _C.indigoLt,
            iconColor: _C.indigo,
            title: 'Live Feed',
            sub: '${prov.recentRequests.length} recent requests',
            badge: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: prov.loading ? _C.amber : _C.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  prov.loading ? 'Syncing' : 'Live',
                  style: _C.p(10, color: prov.loading ? _C.amber : _C.emerald),
                ),
              ],
            ),
          ),
          Expanded(
            child: prov.recentRequests.isEmpty
                ? const _Empty(
                    icon: Icons.inbox_outlined,
                    label: 'No recent requests',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    itemCount: prov.recentRequests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _RequestTile(r: prov.recentRequests[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PanelHdr extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, sub;
  final Widget? badge;
  const _PanelHdr({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.sub,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _C.p(13)),
                Text(
                  sub,
                  style: _C.p(10, fw: FontWeight.w500, color: _C.t3),
                ),
              ],
            ),
          ),
          ?badge,
        ],
      ),
    );
  }
}

class _JobsGlance extends StatelessWidget {
  final AdminAnalyticsProvider prov;
  const _JobsGlance({required this.prov});

  @override
  Widget build(BuildContext context) {
    final open = prov.jobsByStatus['Open'] ?? 0;
    final closed = prov.jobsByStatus['Closed'] ?? 0;
    final total = open + closed;
    final pct = total > 0 ? open / total : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniTile(
                  icon: Icons.radio_button_checked_rounded,
                  label: 'Open',
                  value: open,
                  accent: _C.emerald,
                  bg: _C.emeraldL,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Closed',
                  value: closed,
                  accent: _C.slate,
                  bg: const Color(0xFFF1F5F9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Open rate',
                style: _C.p(10, fw: FontWeight.w500, color: _C.t3),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: _C.p(10, color: _C.emerald),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: _C.border,
              valueColor: const AlwaysStoppedAnimation(_C.emerald),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestMetrics extends StatelessWidget {
  final AdminAnalyticsProvider prov;
  const _RequestMetrics({required this.prov});

  @override
  Widget build(BuildContext context) {
    final pending = prov.requestsByStatus['Pending'] ?? 0;
    final approved = prov.requestsByStatus['Approved'] ?? 0;
    final rejected = prov.requestsByStatus['Rejected'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: _MiniTile(
              icon: Icons.timelapse_rounded,
              label: 'Pending',
              value: pending,
              accent: _C.amber,
              bg: _C.amberLt,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MiniTile(
              icon: Icons.check_circle_outline_rounded,
              label: 'Approved',
              value: approved,
              accent: _C.emerald,
              bg: _C.emeraldL,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MiniTile(
              icon: Icons.cancel_outlined,
              label: 'Rejected',
              value: rejected,
              accent: _C.rose,
              bg: _C.roseLt,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color accent, bg;
  const _MiniTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 15),
          const SizedBox(height: 6),
          Text('$value', style: _C.p(16, fw: FontWeight.w800)),
          Text(
            label,
            style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final Map<String, dynamic> r;
  const _RequestTile({required this.r});

  @override
  Widget build(BuildContext context) {
    final s = r['status'].toString().toLowerCase();
    Color sCol = _C.slate;
    IconData sIcon = Icons.circle_outlined;
    if (s == 'approved' || s == 'active') {
      sCol = _C.emerald;
      sIcon = Icons.check_circle_rounded;
    } else if (s == 'pending') {
      sCol = _C.amber;
      sIcon = Icons.timelapse_rounded;
    } else if (s == 'rejected' || s == 'closed') {
      sCol = _C.rose;
      sIcon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(sIcon, color: sCol, size: 13),
              const SizedBox(width: 5),
              Text(s.toUpperCase(), style: _C.p(9, color: sCol)),
              const Spacer(),
              Text(
                r['createdStr'],
                style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _C.violetLt,
                child: Text(
                  (r['recruiterEmail'] as String).isNotEmpty
                      ? (r['recruiterEmail'] as String)[0].toUpperCase()
                      : '?',
                  style: _C.p(11, color: _C.violet),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r['recruiterEmail'],
                  style: _C.p(12, color: _C.t1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, size: 12, color: _C.t3),
              const SizedBox(width: 5),
              Text(
                '${r['candidatesCount']} candidates processed',
                style: _C.p(10, fw: FontWeight.w500, color: _C.t2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHARED PRIMITIVES
// ═══════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  final double? height;
  const _Card({required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHead extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final Widget? badge;
  const _CardHead({
    required this.icon,
    required this.title,
    required this.sub,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _C.indigo, size: 17),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _C.p(14)),
              Text(
                sub,
                style: _C.p(11, fw: FontWeight.w500, color: _C.t3),
              ),
            ],
          ),
        ),
        ?badge,
      ],
    );
  }
}

class _SectionHead extends StatelessWidget {
  final IconData icon;
  final String title;
  final String eyebrow;
  const _SectionHead({
    required this.icon,
    required this.title,
    this.eyebrow = 'OVERVIEW',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_C.teal, _C.navy],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _C.teal.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 15),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              eyebrow,
              style: _C.p(
                9.5,
                fw: FontWeight.w700,
                color: _C.tealDeep,
              ).copyWith(letterSpacing: 1.2),
            ),
            Text(title, style: _C.p(15, fw: FontWeight.w800)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: _C.border)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool tiny;
  const _Chip({
    required this.label,
    required this.color,
    this.icon,
    required this.tiny,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tiny ? 8 : 10,
        vertical: tiny ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: tiny ? 10 : 11),
            const SizedBox(width: 4),
          ],
          Text(label, style: _C.p(tiny ? 9 : 10, color: color)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Empty({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _C.border, size: 34),
          const SizedBox(height: 8),
          Text(
            label,
            style: _C.p(12, fw: FontWeight.w500, color: _C.t3),
          ),
        ],
      ),
    );
  }
}
