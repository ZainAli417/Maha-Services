import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../Constant/profile_Completeness.dart';
import 'JS_Profile/JS_Profile_Provider.dart';
import 'JS_Top_Bar.dart';
import 'List_applied_jobs_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS  (identical to AdminAnalyticsDashboard)
// ═══════════════════════════════════════════════════════════════════════════
class _C {
  static const canvas   = Color(0xFFFFFFFF);
  static const surface  = Color(0xFFFFFFFF);
  static const surfaceL = Color(0xFFFAFBFD);
  static const border   = Color(0xFFE8ECF4);

  static const indigo   = Color(0xFF4F46E5);
  static const indigoLt = Color(0xFFEEEDFC);
  static const teal     = Color(0xFF0891B2);
  static const tealLt   = Color(0xFFE0F5FA);
  static const emerald  = Color(0xFF059669);
  static const emeraldL = Color(0xFFDCFCED);
  static const amber    = Color(0xFFD97706);
  static const amberLt  = Color(0xFFFEF3CD);
  static const rose     = Color(0xFFE11D48);
  static const roseLt   = Color(0xFFFCE7ED);
  static const violet   = Color(0xFF7C3AED);
  static const violetLt = Color(0xFFF1ECFE);
  static const slate    = Color(0xFF64748B);

  static const t1 = Color(0xFF0F172A);
  static const t2 = Color(0xFF475569);
  static const t3 = Color(0xFF94A3B8);

  static TextStyle p(double size,
      {FontWeight fw = FontWeight.w600, Color color = t1}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: fw, color: color);
}

// ═══════════════════════════════════════════════════════════════════════════
//  SCROLL BEHAVIOUR
// ═══════════════════════════════════════════════════════════════════════════
class SmoothScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: ClampingScrollPhysics());
}

// ═══════════════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class job_seeker_dashboard extends StatefulWidget {
  const job_seeker_dashboard({super.key});

  @override
  State<job_seeker_dashboard> createState() => _job_seeker_dashboardState();
}

class _job_seeker_dashboardState extends State<job_seeker_dashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus  = 'All';
  String _selectedCompany = 'All';
  DateTimeRange? _appliedRange;
  final List<String> _statusOptions = [
    'All', 'pending', 'shortlist', 'accepted', 'rejected'
  ];
  List<String> _companyOptions = ['All'];
  String _sortBy    = 'applied_desc';
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this)
      ..forward();
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this)
      ..forward();
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _inRange(DateTime date, DateTimeRange? range) {
    if (range == null) return true;
    return date.isAfter(range.start.subtract(const Duration(days: 1))) &&
        date.isBefore(range.end.add(const Duration(days: 1)));
  }

  List<dynamic> _sortApplications(List apps) {
    final list = List.from(apps);
    switch (_sortBy) {
      case 'applied_desc': list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt)); break;
      case 'applied_asc':  list.sort((a, b) => a.appliedAt.compareTo(b.appliedAt)); break;
      case 'title_asc':    list.sort((a, b) => a.title.compareTo(b.title));         break;
      case 'company_asc':  list.sort((a, b) => a.company.compareTo(b.company));     break;
      case 'status':       list.sort((a, b) => a.status.compareTo(b.status));       break;
    }
    return list;
  }

  void _clearFilters() => setState(() {
    _searchController.clear();
    _selectedStatus  = 'All';
    _selectedCompany = 'All';
    _appliedRange    = null;
  });

  bool _hasActiveFilters() =>
      _searchController.text.isNotEmpty ||
          _selectedStatus  != 'All' ||
          _selectedCompany != 'All' ||
          _appliedRange    != null;

  String _getSortLabel() {
    const m = {
      'applied_desc': 'Latest',
      'applied_asc' : 'Oldest',
      'title_asc'   : 'Title',
      'company_asc' : 'Unit / Base',
      'status'      : 'Status',
    };
    return m[_sortBy] ?? 'Latest';
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: SmoothScrollBehavior(),
      child: Scaffold(
        backgroundColor: _C.canvas,
        body: Row(
          children: [
            JobSeekerSidebar(activeIndex: 0),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContent(BuildContext context) {
    return ChangeNotifierProvider<ListAppliedJobsProvider>(
      create: (_) => ListAppliedJobsProvider()..refresh(),
      child: Consumer<ListAppliedJobsProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) {
            return const Center(
                child: CircularProgressIndicator(
                    color: _C.indigo, strokeWidth: 2));
          }

          if (prov.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: _Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(14),
                          decoration:
                          BoxDecoration(color: _C.roseLt, shape: BoxShape.circle),
                          child: const Icon(Icons.error_outline,
                              size: 40, color: _C.rose)),
                      const SizedBox(height: 18),
                      Text('Unable to Load Applications',
                          style: _C.p(17, fw: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(prov.error!,
                          style: _C.p(13, color: _C.t2, fw: FontWeight.w500),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      _OutlineBtn(
                          label: 'Retry',
                          icon: Icons.refresh_rounded,
                          color: _C.indigo,
                          onTap: prov.refresh),
                    ],
                  ),
                ),
              ),
            );
          }

          _companyOptions =
              ['All'] + prov.applications.map((a) => a.company).toSet().toList();

          final filtered = prov.applications.where((app) {
            final q = _searchController.text.toLowerCase();
            return (_selectedStatus  == 'All' || app.status  == _selectedStatus) &&
                (_selectedCompany == 'All' || app.company == _selectedCompany) &&
                _inRange(app.appliedAt, _appliedRange) &&
                (q.isEmpty ||
                    app.title.toLowerCase().contains(q) ||
                    app.company.toLowerCase().contains(q) ||
                    app.jobId.toLowerCase().contains(q));
          }).toList();

          final sorted    = _sortApplications(filtered);
          final analytics = prov.getAnalytics(sorted);
          final w         = MediaQuery.of(context).size.width;
          final isWide    = w > 1180;

          // ── ROOT LAYOUT: fixed top bar + scrollable body ──────────
          return Column(
            children: [
              // Fixed top bar (never scrolls)
              _buildTopBar(analytics, sorted.length),
              if (_showFilters) _buildFilterBar(prov),

              // Body: main scrollable content + optional right panel
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── MAIN SCROLLABLE AREA ──────────────────────────
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: prov.refresh,
                        color: _C.indigo,
                        backgroundColor: _C.surface,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(isWide ? 24 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // KPI cards
                              if (prov.applications.isNotEmpty) ...[
                                _KpiStrip(
                                  total: analytics['totalApplications'] as int,
                                  stats: analytics['statusBreakdown']
                                  as Map<String, dynamic>,
                                  responseRate:
                                  analytics['responseRate'] as double,
                                  avgResponse:
                                  analytics['averageResponseTime'] as int,
                                ),
                                const SizedBox(height: 24),
                                _SectionHead(
                                    icon: Icons.analytics_outlined,
                                    title: 'Analytics Overview'),
                                const SizedBox(height: 16),
                                _AnalyticsCharts(analytics: analytics),
                                const SizedBox(height: 24),
                                _SectionHead(
                                    icon: Icons.list_alt_rounded,
                                    title: 'Applications'),
                                const SizedBox(height: 16),
                              ],
                              // Applications table (not Expanded — natural height)
                              _buildTable(sorted),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── RIGHT PANEL (wide screens only) ──────────────
                    if (isWide)
                      _RightPanel(
                        analytics: analytics,
                        applications: sorted,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TOP BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar(Map<String, dynamic> analytics, int filteredCount) {
    final total    = analytics['totalApplications'] as int;
    final accepted = (analytics['statusBreakdown'] as Map)['accepted'] as int;
    final pending  = (analytics['statusBreakdown'] as Map)['pending']  as int;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(bottom: BorderSide(color: _C.border, width: 1.5)),
        boxShadow: [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.work_history_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Applications', style: _C.p(16)),
              Text('Trends & market insights',
                  style: _C.p(10, fw: FontWeight.w500, color: _C.t3)),
            ],
          ),
          const SizedBox(width: 20),
          _MiniStatChip(
              icon: Icons.inbox_rounded, label: '$total Total', color: _C.indigo),
          const SizedBox(width: 8),
          _MiniStatChip(
              icon: Icons.check_circle_rounded,
              label: '$accepted Accepted', color: _C.emerald),
          const SizedBox(width: 8),
          _MiniStatChip(
              icon: Icons.timelapse_rounded,
              label: '$pending Pending', color: _C.amber),
          const Spacer(),
          _FilterToggleBtn(
              active: _showFilters,
              onTap: () => setState(() => _showFilters = !_showFilters)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FILTER BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFilterBar(ListAppliedJobsProvider prov) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: _C.p(13, fw: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Search by title, unit or base...',
                  hintStyle: _C.p(13, fw: FontWeight.w400, color: _C.t3),
                  prefixIcon: const Icon(Icons.search, size: 18, color: _C.t3),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      })
                      : null,
                  filled: true,
                  fillColor: _C.canvas,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _C.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _C.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _C.indigo, width: 2)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _FilterDropdown(
              label: 'Status',
              value: _selectedStatus,
              items: _statusOptions,
              onChanged: (v) => setState(() => _selectedStatus = v!)),
          const SizedBox(width: 12),
          _FilterDropdown(
              label: 'All Units / Base',
              value: _selectedCompany,
              items: _companyOptions,
              onChanged: (v) => setState(() => _selectedCompany = v!)),
          const SizedBox(width: 12),
          _DateRangeBtn(range: _appliedRange, onTap: _showDatePicker),
          const SizedBox(width: 12),
          _SortDropdown(
              value: _getSortLabel(),
              onChanged: (val) => setState(() {
                switch (val) {
                  case 'Latest':      _sortBy = 'applied_desc'; break;
                  case 'Oldest':      _sortBy = 'applied_asc';  break;
                  case 'Title':       _sortBy = 'title_asc';    break;
                  case 'Unit / Base': _sortBy = 'company_asc';  break;
                  case 'Status':      _sortBy = 'status';       break;
                }
              })),
          if (_hasActiveFilters()) ...[
            const SizedBox(width: 12),
            _OutlineBtn(
                label: 'Clear',
                icon: Icons.clear_all_rounded,
                color: _C.rose,
                onTap: _clearFilters),
          ],
        ],
      ),
    );
  }

  void _showDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _C.indigo,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _C.t1,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _appliedRange = picked);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TABLE  (natural height, no Expanded — lives inside SingleChildScrollView)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTable(List<dynamic> apps) {
    if (apps.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.border)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration:
                BoxDecoration(color: _C.canvas, shape: BoxShape.circle),
                child: const Icon(Icons.work_outline_rounded,
                    size: 48, color: _C.t3),
              ),
              const SizedBox(height: 18),
              Text('No Applications Found',
                  style: _C.p(18, fw: FontWeight.w700)),
              const SizedBox(height: 5),
              Text('Adjust filters or start applying to new positions',
                  style: _C.p(12, fw: FontWeight.w500, color: _C.t2)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: Column(
        children: [
          _TableHeader(),
          // Each row rendered as a natural-height widget — no ListView inside scroll
          ...apps.asMap().entries.map((e) =>
              _TableRow(app: e.value, isLast: e.key == apps.length - 1)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  RIGHT PANEL  —  Status Bar Chart  +  Recent Job Cards
// ═══════════════════════════════════════════════════════════════════════════
class _RightPanel extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final List<dynamic> applications;
  const _RightPanel(
      {required this.analytics, required this.applications});

  @override
  Widget build(BuildContext context) {
    final stats = analytics['statusBreakdown'] as Map<String, dynamic>;
    final topCompanies =
    analytics['topCompanies'] as List<Map<String, dynamic>>;
    final deptData =
    analytics['successRateByDepartment'] as List<Map<String, dynamic>>;

    return Container(
      width: 400,
      // decoration: const BoxDecoration(
      //   color: _C.surfaceL,
      //   border: Border(left: BorderSide(color: _C.border, width: 1.5)),
      // ),
      child: Column(
        children: [
          // ── STATUS BAR CHART ──────────────────────────────────────
          _PanelHdr(
            icon: Icons.bar_chart_rounded,
            iconBg: _C.indigoLt,
            iconColor: _C.indigo,
            title: 'Status Overview',
            sub: 'Application breakdown',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _StatusBarChart(stats: stats),
          ),

          const Divider(height: 1, thickness: 1, color: _C.border),

          // ── TOP UNITS + DEPT ──────────────────────────────────────
          if (topCompanies.isNotEmpty) ...[
            _PanelHdr(
              icon: Icons.business_rounded,
              iconBg: _C.tealLt,
              iconColor: _C.teal,
              title: 'Top Units',
              sub: 'Most applied to',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: topCompanies.take(4).map((c) {
                  final count = c['count'] as int;
                  final max = (topCompanies.first['count'] as int)
                      .clamp(1, 9999);
                  final pct = count / max;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(c['company'],
                                  style: _C.p(11, color: _C.t1),
                                  overflow: TextOverflow.ellipsis)),
                          _Chip(label: '$count', color: _C.teal, tiny: true),
                        ]),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: _C.tealLt,
                            valueColor:
                            const AlwaysStoppedAnimation(_C.teal),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _C.border),
          ],

          // ── RECENT JOB APPLICATION CARDS ──────────────────────────
          _PanelHdr(
            icon: Icons.work_history_rounded,
            iconBg: _C.violetLt,
            iconColor: _C.violet,
            title: 'Recent Applications',
            sub: '${applications.length} total',
            badge: _Chip(
                label: '${applications.length}',
                color: _C.violet),
          ),
          Expanded(
            child: applications.isEmpty
                ? const _Empty(
                icon: Icons.inbox_outlined,
                label: 'No applications yet')
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              itemCount: applications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  _JobCard(app: applications[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STATUS BAR CHART  (fl_chart, indigo→teal gradient like admin)
// ═══════════════════════════════════════════════════════════════════════════
class _StatusBarChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatusBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final labels = ['Pending', 'Shortlist', 'Accepted', 'Rejected'];
    final colors = [_C.amber, _C.violet, _C.emerald, _C.rose];
    final values = [
      (stats['pending']   as int).toDouble(),
      (stats['shortlist'] as int).toDouble(),
      (stats['accepted']  as int).toDouble(),
      (stats['rejected']  as int).toDouble(),
    ];
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.3;
    final safeMax = maxY < 1 ? 5.0 : maxY;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
      decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: safeMax,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => _C.t1,
              tooltipBorderRadius: BorderRadius.circular(4),
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '${labels[group.x]}\n${rod.toY.round()}',
                _C.p(10, color: Colors.white),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(labels[i],
                        style: _C.p(9, fw: FontWeight.w500, color: _C.t3)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
                ),
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
            const FlLine(color: Color(0xFFF0F3FA), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(values.length, (i) {
            final pct = safeMax > 0 ? values[i] / safeMax : 0.0;
            // Gradient from each status color blending toward indigo (admin style)
            final col = Color.lerp(colors[i], _C.indigo, 0.3)!;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  gradient: LinearGradient(
                    colors: [col.withOpacity(0.5), col],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 26,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: safeMax,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  JOB CARD (right panel)
// ═══════════════════════════════════════════════════════════════════════════
class _JobCard extends StatelessWidget {
  final dynamic app;
  const _JobCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final s = (app.status as String).toLowerCase();
    Color sCol = _C.slate;
    IconData sIcon = Icons.circle_outlined;
    if (s == 'accepted') {
      sCol = _C.emerald; sIcon = Icons.check_circle_rounded;
    } else if (s == 'pending') {
      sCol = _C.amber;   sIcon = Icons.timelapse_rounded;
    } else if (s == 'shortlist') {
      sCol = _C.violet;  sIcon = Icons.star_rounded;
    } else if (s == 'rejected') {
      sCol = _C.rose;    sIcon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(children: [
            Icon(sIcon, color: sCol, size: 13),
            const SizedBox(width: 5),
            Text(s.toUpperCase(), style: _C.p(9, color: sCol)),
            const Spacer(),
            Text(DateFormat.yMMMd().format(app.appliedAt),
                style: _C.p(9, fw: FontWeight.w500, color: _C.t3)),
          ]),
          const SizedBox(height: 9),
          // Title
          Text(app.title,
              style: _C.p(13, fw: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          // Company + dept
          Row(children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: _C.canvas, borderRadius: BorderRadius.circular(5)),
              child: const Icon(Icons.business, size: 12, color: _C.t3),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(app.company,
                  style: _C.p(11, color: _C.t2),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          if ((app.department as String).isNotEmpty) ...[
            const SizedBox(height: 5),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: _C.canvas, borderRadius: BorderRadius.circular(5)),
                child: const Icon(Icons.account_tree_rounded,
                    size: 12, color: _C.t3),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(app.department,
                    style: _C.p(11, fw: FontWeight.w500, color: _C.t3),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ANALYTICS CHARTS SECTION (main area — trend chart only, no donut)
// ═══════════════════════════════════════════════════════════════════════════
class _AnalyticsCharts extends StatelessWidget {
  final Map<String, dynamic> analytics;
  const _AnalyticsCharts({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final trendData    = analytics['applicationTrend'] as List<Map<String, dynamic>>;
    final deptData     = analytics['successRateByDepartment'] as List<Map<String, dynamic>>;
    final hasTrend     = trendData.any((d) => (d['count'] as int) > 0);

    return LayoutBuilder(builder: (_, constraints) {
      final wide = constraints.maxWidth > 700;
      if (!hasTrend && deptData.isEmpty) return const SizedBox.shrink();

      return wide
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTrend)
            Expanded(
                flex: 3,
                child: SizedBox(
                    height: 280, child: _TrendChart(data: trendData))),
          if (hasTrend && deptData.isNotEmpty)
            const SizedBox(width: 20),
          if (deptData.isNotEmpty)
            Expanded(
                flex: 2,
                child: _DeptCard(deptData: deptData)),
        ],
      )
          : Column(children: [
        if (hasTrend) ...[
          SizedBox(height: 260, child: _TrendChart(data: trendData)),
          const SizedBox(height: 16),
        ],
        if (deptData.isNotEmpty) _DeptCard(deptData: deptData),
      ]);
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  KPI STRIP
// ═══════════════════════════════════════════════════════════════════════════
class _KpiStrip extends StatelessWidget {
  final int total, avgResponse;
  final Map<String, dynamic> stats;
  final double responseRate;
  const _KpiStrip({
    required this.total,
    required this.stats,
    required this.responseRate,
    required this.avgResponse,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _KD(Icons.inbox_rounded,         'Total Applied', total,                     _C.indigo,  _C.indigoLt),
      _KD(Icons.check_circle_rounded,  'Accepted',      stats['accepted'] as int,  _C.emerald, _C.emeraldL),
      _KD(Icons.star_rounded,          'Shortlisted',   stats['shortlist'] as int, _C.violet,  _C.violetLt),
      _KD(Icons.timelapse_rounded,     'Pending',       stats['pending']  as int,  _C.amber,   _C.amberLt),
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding:
            EdgeInsets.only(right: e.key < items.length - 1 ? 16 : 0),
            child: _KpiCard(d: e.value),
          ),
        );
      }).toList(),
    );
  }
}

class _KD {
  final IconData icon;
  final String label;
  final int value;
  final Color accent, bg;
  const _KD(this.icon, this.label, this.value, this.accent, this.bg);
}

class _KpiCard extends StatelessWidget {
  final _KD d;
  const _KpiCard({required this.d});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: d.bg, borderRadius: BorderRadius.circular(9)),
              child: Icon(d.icon, color: d.accent, size: 17),
            ),
            Icon(Icons.trending_up_rounded,
                color: d.accent.withOpacity(0.3), size: 15),
          ]),
          const SizedBox(height: 12),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: d.value),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) =>
                Text('$v', style: _C.p(24, fw: FontWeight.w800)),
          ),
          const SizedBox(height: 2),
          Text(d.label, style: _C.p(11, color: _C.t2)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TREND CHART  (Syncfusion spline area)
// ═══════════════════════════════════════════════════════════════════════════
class _TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(
              icon: Icons.show_chart_rounded,
              title: '30-Day Application Trend',
              sub: 'Activity over time'),
          const SizedBox(height: 16),
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: DateTimeAxis(
                intervalType: DateTimeIntervalType.days,
                interval: 5,
                dateFormat: DateFormat.MMMd(),
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _C.t3),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                  color: _C.border,
                  width: 1,
                  dashArray: const [4, 4],
                ),
                axisLine: const AxisLine(width: 0),
                labelStyle: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _C.t3),
              ),
              series: [
                SplineAreaSeries<Map<String, dynamic>, DateTime>(
                  dataSource: data,
                  xValueMapper: (d, _) => d['date'] as DateTime,
                  yValueMapper: (d, _) => d['count'] as int,
                  gradient: LinearGradient(
                    colors: [
                      _C.indigo.withOpacity(0.2),
                      _C.indigo.withOpacity(0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderColor: _C.indigo,
                  borderWidth: 2.5,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    height: 6, width: 6,
                    color: _C.indigo,
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DEPT SUCCESS CARD
// ═══════════════════════════════════════════════════════════════════════════
class _DeptCard extends StatelessWidget {
  final List<Map<String, dynamic>> deptData;
  const _DeptCard({required this.deptData});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(
              icon: Icons.donut_small_rounded,
              title: 'Dept Success Rate',
              sub: 'Acceptance by department'),
          const SizedBox(height: 14),
          ...deptData.take(5).map((d) {
            final rate  = d['rate'] as double;
            final color = rate >= 50 ? _C.emerald : rate >= 25 ? _C.amber : _C.rose;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Text(d['department'],
                            style: _C.p(12, color: _C.t1),
                            overflow: TextOverflow.ellipsis)),
                    _Chip(
                        label: '${rate.toStringAsFixed(0)}%',
                        color: color,
                        tiny: true),
                  ]),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (rate / 100).clamp(0.0, 1.0),
                      backgroundColor: color.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TABLE HEADER + ROW
// ═══════════════════════════════════════════════════════════════════════════
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: const BoxDecoration(
        color: _C.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _ColLabel('JOB POSITION')),
          Expanded(flex: 3, child: _ColLabel('UNIT / BASE')),
          Expanded(flex: 2, child: _ColLabel('APPLIED DATE')),
          SizedBox(width: 130, child: Center(child: _ColLabel('STATUS'))),
        ],
      ),
    );
  }
}

class _ColLabel extends StatelessWidget {
  final String text;
  const _ColLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: _C.p(10, fw: FontWeight.w700, color: _C.t3));
}

class _TableRow extends StatelessWidget {
  final dynamic app;
  final bool isLast;
  const _TableRow({required this.app, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(14))
            : null,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F3FA))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.title,
                    style: _C.p(13, fw: FontWeight.w700),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(app.department,
                    style: _C.p(11, fw: FontWeight.w500, color: _C.t2)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: _C.canvas,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.business, size: 12, color: _C.t3)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(app.company,
                      style: _C.p(12, color: _C.t1),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ),
          Expanded(
            flex: 2,
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: _C.canvas,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.calendar_today_rounded,
                      size: 12, color: _C.t3)),
              const SizedBox(width: 8),
              Text(DateFormat.yMMMd().format(app.appliedAt),
                  style: _C.p(12, color: _C.t1)),
            ]),
          ),
          SizedBox(
              width: 130,
              child: Center(child: _StatusBadge(status: app.status))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color col; IconData icon;
    switch (status.toLowerCase()) {
      case 'pending':   col = _C.amber;   icon = Icons.timelapse_rounded;     break;
      case 'shortlist': col = _C.violet;  icon = Icons.star_rounded;          break;
      case 'accepted':  col = _C.emerald; icon = Icons.check_circle_rounded;  break;
      case 'rejected':  col = _C.rose;    icon = Icons.cancel_rounded;        break;
      default:          col = _C.slate;   icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: col.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: col.withOpacity(0.25), width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: col),
        const SizedBox(width: 5),
        Text(status.toUpperCase(), style: _C.p(9, color: col)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PANEL HEADER WIDGET
// ═══════════════════════════════════════════════════════════════════════════
class _PanelHdr extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, sub;
  final Widget? badge;
  const _PanelHdr({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.sub, this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: _C.p(13)),
            Text(sub, style: _C.p(10, fw: FontWeight.w500, color: _C.t3)),
          ]),
        ),
        if (badge != null) badge!,
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SMALL UTILITIES
// ═══════════════════════════════════════════════════════════════════════════
class _MiniStatChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _MiniStatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 5),
        Text(label, style: _C.p(11, color: color)),
      ]),
    );
  }
}

class _FilterToggleBtn extends StatelessWidget {
  final bool active; final VoidCallback onTap;
  const _FilterToggleBtn({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? _C.indigo : _C.slate;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(active ? Icons.filter_list_rounded : Icons.filter_list_off_rounded,
              size: 16, color: color),
          const SizedBox(width: 7),
          Text(active ? 'Hide Filters' : 'Show Filters',
              style: _C.p(12, color: color)),
        ]),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _FilterDropdown({
    required this.label, required this.value,
    required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _C.canvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isDense: true,
          items: items.map((item) {
            final d = item == 'All'
                ? label
                : item[0].toUpperCase() + item.substring(1);
            return DropdownMenuItem(
                value: item,
                child: Text(d, style: _C.p(12, color: _C.t1)));
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: _C.t2),
        ),
      ),
    );
  }
}

class _DateRangeBtn extends StatelessWidget {
  final DateTimeRange? range; final VoidCallback onTap;
  const _DateRangeBtn({required this.range, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = range != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _C.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? _C.indigo.withOpacity(0.4) : _C.border),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              size: 14, color: active ? _C.indigo : _C.t3),
          const SizedBox(width: 8),
          Text(
            active
                ? '${DateFormat.MMMd().format(range!.start)} – ${DateFormat.MMMd().format(range!.end)}'
                : 'Date Range',
            style: _C.p(12, color: active ? _C.indigo : _C.t2),
          ),
        ]),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String value; final ValueChanged<String?> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: _C.canvas,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isDense: true,
          items: const [
            DropdownMenuItem(value: 'Latest',       child: Text('Latest')),
            DropdownMenuItem(value: 'Oldest',       child: Text('Oldest')),
            DropdownMenuItem(value: 'Title',        child: Text('Title')),
            DropdownMenuItem(value: 'Unit / Base',  child: Text('Unit / Base')),
            DropdownMenuItem(value: 'Status',       child: Text('Status')),
          ],
          onChanged: onChanged,
          icon: const Icon(Icons.sort_rounded, size: 16, color: _C.t2),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.icon,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(label, style: _C.p(12, color: color)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHARED PRIMITIVES  (identical to admin dashboard)
// ═══════════════════════════════════════════════════════════════════════════
class _Card extends StatelessWidget {
  final Widget child; final double? height;
  const _Card({required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: child,
    );
  }
}

class _CardHead extends StatelessWidget {
  final IconData icon; final String title, sub;
  const _CardHead({required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: _C.indigo, size: 16),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: _C.p(13)),
        Text(sub, style: _C.p(10, fw: FontWeight.w500, color: _C.t3)),
      ]),
    ]);
  }
}

class _SectionHead extends StatelessWidget {
  final IconData icon; final String title;
  const _SectionHead({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: _C.indigo, size: 16),
      const SizedBox(width: 8),
      Text(title, style: _C.p(15)),
      const SizedBox(width: 12),
      Expanded(child: Container(height: 1, color: _C.border)),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label; final Color color; final bool tiny;
  const _Chip({required this.label, required this.color, this.tiny = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: tiny ? 7 : 10, vertical: tiny ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label, style: _C.p(tiny ? 9 : 10, color: color)),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon; final String label;
  const _Empty({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: _C.border, size: 34),
        const SizedBox(height: 8),
        Text(label, style: _C.p(12, fw: FontWeight.w500, color: _C.t3)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CHART DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════
class ChartData {
  final String status; final int count; final Color color;
  ChartData(this.status, this.count, this.color);
}