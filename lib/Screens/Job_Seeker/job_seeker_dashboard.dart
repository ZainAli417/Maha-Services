import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'JS_Top_Bar.dart';
import 'List_applied_jobs_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  RESPONSIVE BREAKPOINTS
// ═══════════════════════════════════════════════════════════════════════════
class _BP {
  static const mobile = 600.0;
  static const tablet = 900.0;
  static const desktop = 1180.0;

  static bool isMobile(double w) => w < mobile;
  static bool isTablet(double w) => w >= mobile && w < desktop;
  static bool isDesktop(double w) => w >= desktop;

  // Responsive padding
  static double hPad(double w) => w < mobile
      ? 10
      : w < desktop
      ? 16
      : 22;
  static double vPad(double w) => w < mobile ? 8 : 12;
  static double cardPad(double w) => w < mobile ? 10 : 14;
}

// ═══════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════
class _C {
  static const canvas = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceL = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8ECF4);

  static const indigo = Color(0xFF14507F);
  static const indigoLt = Color(0xFFE8F1F8);
  static const teal = Color(0xFF2EC4B6);
  static const tealLt = Color(0xFFE4F6F4);
  static const emerald = Color(0xFF059669);
  static const emeraldL = Color(0xFFDCFCED);
  static const amber = Color(0xFFD97706);
  static const amberLt = Color(0xFFFEF3CD);
  static const rose = Color(0xFFE11D48);
  static const roseLt = Color(0xFFFCE7ED);
  static const violet = Color(0xFF15A99C);
  static const violetLt = Color(0xFFE4F6F4);
  static const slate = Color(0xFF64748B);

  static const t1 = Color(0xFF0F172A);
  static const t2 = Color(0xFF475569);
  static const t3 = Color(0xFF94A3B8);

  static TextStyle p(
    double size, {
    FontWeight fw = FontWeight.w600,
    Color color = t1,
  }) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: fw, color: color);
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedCompany = 'All';
  DateTimeRange? _appliedRange;
  final List<String> _statusOptions = [
    'All',
    'pending',
    'shortlist',
    'accepted',
    'rejected',
  ];
  List<String> _companyOptions = ['All'];
  String _sortBy = 'applied_desc';
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
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
      case 'applied_desc':
        list.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
        break;
      case 'applied_asc':
        list.sort((a, b) => a.appliedAt.compareTo(b.appliedAt));
        break;
      case 'title_asc':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'company_asc':
        list.sort((a, b) => a.company.compareTo(b.company));
        break;
      case 'status':
        list.sort((a, b) => a.status.compareTo(b.status));
        break;
    }
    return list;
  }

  void _clearFilters() => setState(() {
    _searchController.clear();
    _selectedStatus = 'All';
    _selectedCompany = 'All';
    _appliedRange = null;
  });

  bool _hasActiveFilters() =>
      _searchController.text.isNotEmpty ||
      _selectedStatus != 'All' ||
      _selectedCompany != 'All' ||
      _appliedRange != null;

  String _getSortLabel() {
    const m = {
      'applied_desc': 'Latest',
      'applied_asc': 'Oldest',
      'title_asc': 'Title',
      'company_asc': 'Unit / Base',
      'status': 'Status',
    };
    return m[_sortBy] ?? 'Latest';
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = _BP.isMobile(w);
    return ScrollConfiguration(
      behavior: SmoothScrollBehavior(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _C.canvas,
        drawer: isMobile
            ? Drawer(child: JobSeekerSidebar(activeIndex: 0, isDrawer: true))
            : null,
        body: SafeArea(
          top: isMobile,
          bottom: false,
          child: Row(
            children: [
              if (!isMobile) JobSeekerSidebar(activeIndex: 0),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        if (isMobile) _buildMobileAppBar('My Applications'),
                        Expanded(child: _buildContent(context)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAppBar(String title) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 22),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _C.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.work_history_rounded,
              color: _C.indigo,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: _C.p(14, fw: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          _FilterToggleBtn(
            active: _showFilters,
            onTap: () => setState(() => _showFilters = !_showFilters),
            compact: true,
          ),
        ],
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
                color: _C.indigo,
                strokeWidth: 2,
              ),
            );
          }

          if (prov.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: _C.roseLt,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            size: 36,
                            color: _C.rose,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Unable to Load Applications',
                          style: _C.p(15, fw: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          prov.error!,
                          style: _C.p(12, color: _C.t2, fw: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        _OutlineBtn(
                          label: 'Retry',
                          icon: Icons.refresh_rounded,
                          color: _C.indigo,
                          onTap: prov.refresh,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          _companyOptions =
              ['All'] +
              prov.applications.map((a) => a.company).toSet().toList();

          final filtered = prov.applications.where((app) {
            final q = _searchController.text.toLowerCase();
            return (_selectedStatus == 'All' ||
                    app.status == _selectedStatus) &&
                (_selectedCompany == 'All' ||
                    app.company == _selectedCompany) &&
                _inRange(app.appliedAt, _appliedRange) &&
                (q.isEmpty ||
                    app.title.toLowerCase().contains(q) ||
                    app.company.toLowerCase().contains(q) ||
                    app.jobId.toLowerCase().contains(q));
          }).toList();

          final sorted = _sortApplications(filtered);
          final analytics = prov.getAnalytics(sorted);

          return LayoutBuilder(
            builder: (_, constraints) {
              final w = constraints.maxWidth;
              final isMobile = _BP.isMobile(w);
              final isWide = _BP.isDesktop(w);

              return Column(
                children: [
                  // Fixed top bar — hide on mobile
                  if (!isMobile) _buildTopBar(analytics, sorted.length, w),
                  if (_showFilters) _buildFilterBar(prov, isMobile, w),

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // MAIN SCROLLABLE AREA
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: prov.refresh,
                            color: _C.indigo,
                            backgroundColor: _C.surface,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.all(_BP.hPad(w)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (prov.applications.isNotEmpty) ...[
                                    _KpiStrip(
                                      total:
                                          analytics['totalApplications'] as int,
                                      stats:
                                          analytics['statusBreakdown']
                                              as Map<String, dynamic>,
                                      responseRate:
                                          analytics['responseRate'] as double,
                                      avgResponse:
                                          analytics['averageResponseTime']
                                              as int,
                                      screenWidth: w,
                                    ),
                                    SizedBox(height: isMobile ? 14 : 18),
                                    _SectionHead(
                                      icon: Icons.analytics_outlined,
                                      title: 'Analytics Overview',
                                    ),
                                    SizedBox(height: isMobile ? 10 : 14),
                                    _AnalyticsCharts(analytics: analytics),
                                    SizedBox(height: isMobile ? 14 : 18),
                                    _SectionHead(
                                      icon: Icons.list_alt_rounded,
                                      title: 'Applications',
                                    ),
                                    SizedBox(height: isMobile ? 10 : 14),
                                  ],
                                  _buildTable(sorted, isMobile),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // RIGHT PANEL (wide screens only)
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
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TOP BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar(
    Map<String, dynamic> analytics,
    int filteredCount,
    double w,
  ) {
    final total = analytics['totalApplications'] as int;
    final accepted = (analytics['statusBreakdown'] as Map)['accepted'] as int;
    final pending = (analytics['statusBreakdown'] as Map)['pending'] as int;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: _BP.hPad(w)),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.work_history_rounded,
              color: _C.indigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Applications', style: _C.p(16, fw: FontWeight.w600)),
              Text(
                'Trends & insights',
                style: _C.p(11, fw: FontWeight.w500, color: _C.t3),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MiniStatChip(
                    icon: Icons.inbox_rounded,
                    label: '$total Total',
                    color: _C.indigo,
                  ),
                  const SizedBox(width: 6),
                  _MiniStatChip(
                    icon: Icons.check_circle_rounded,
                    label: '$accepted Accepted',
                    color: _C.emerald,
                  ),
                  const SizedBox(width: 6),
                  _MiniStatChip(
                    icon: Icons.timelapse_rounded,
                    label: '$pending Pending',
                    color: _C.amber,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          _FilterToggleBtn(
            active: _showFilters,
            onTap: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FILTER BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFilterBar(
    ListAppliedJobsProvider prov,
    bool isMobile,
    double w,
  ) {
    final hPad = _BP.hPad(w);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompactSearchField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  hint: 'Search...',
                ),
                const SizedBox(height: 7),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterDropdown(
                        label: 'Status',
                        value: _selectedStatus,
                        items: _statusOptions,
                        onChanged: (v) => setState(() => _selectedStatus = v!),
                      ),
                      const SizedBox(width: 6),
                      _FilterDropdown(
                        label: 'Unit',
                        value: _selectedCompany,
                        items: _companyOptions,
                        onChanged: (v) => setState(() => _selectedCompany = v!),
                      ),
                      const SizedBox(width: 6),
                      _DateRangeBtn(
                        range: _appliedRange,
                        onTap: _showDatePicker,
                      ),
                      // _SortDropdown hidden on mobile to save space as per request
                      if (_hasActiveFilters()) ...[
                        const SizedBox(width: 6),
                        _OutlineBtn(
                          label: 'Clear',
                          icon: Icons.clear_all_rounded,
                          color: _C.rose,
                          onTap: _clearFilters,
                        ),
                      ],
                    ],
                  ),
                ),
                if (Theme.of(context).platform == TargetPlatform.android)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'PULL DOWN LONG TO REFRESH DATA',
                      style: _C.p(
                        9,
                        fw: FontWeight.w500,
                        color: _C.t3.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _CompactSearchField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    hint: 'Search by title, unit or base...',
                  ),
                ),
                const SizedBox(width: 8),
                _FilterDropdown(
                  label: 'Status',
                  value: _selectedStatus,
                  items: _statusOptions,
                  onChanged: (v) => setState(() => _selectedStatus = v!),
                ),
                const SizedBox(width: 8),
                _FilterDropdown(
                  label: 'All Units',
                  value: _selectedCompany,
                  items: _companyOptions,
                  onChanged: (v) => setState(() => _selectedCompany = v!),
                ),
                const SizedBox(width: 8),
                _DateRangeBtn(range: _appliedRange, onTap: _showDatePicker),
                const SizedBox(width: 8),
                _SortDropdown(
                  value: _getSortLabel(),
                  onChanged: _onSortChanged,
                ),
                if (_hasActiveFilters()) ...[
                  const SizedBox(width: 8),
                  _OutlineBtn(
                    label: 'Clear',
                    icon: Icons.clear_all_rounded,
                    color: _C.rose,
                    onTap: _clearFilters,
                  ),
                ],
              ],
            ),
    );
  }

  void _onSortChanged(String? val) => setState(() {
    switch (val) {
      case 'Latest':
        _sortBy = 'applied_desc';
        break;
      case 'Oldest':
        _sortBy = 'applied_asc';
        break;
      case 'Title':
        _sortBy = 'title_asc';
        break;
      case 'Unit / Base':
        _sortBy = 'company_asc';
        break;
      case 'Status':
        _sortBy = 'status';
        break;
    }
  });

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
  //  TABLE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTable(List<dynamic> apps, bool isMobile) {
    if (apps.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 56),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: _C.canvas,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  size: 40,
                  color: _C.t3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No Applications Found',
                style: _C.p(16, fw: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Adjust filters or start applying to new positions',
                  style: _C.p(11, fw: FontWeight.w500, color: _C.t2),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // On mobile: card list; on desktop: table
    if (isMobile) {
      return Column(
        children: [
          ...apps.map(
            (app) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MobileAppCard(app: app),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _TableHeader(),
          ...apps.asMap().entries.map(
            (e) => _TableRow(app: e.value, isLast: e.key == apps.length - 1),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MOBILE APP CARD (replaces table rows on mobile)
// ═══════════════════════════════════════════════════════════════════════════
class _MobileAppCard extends StatelessWidget {
  final dynamic app;
  const _MobileAppCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.title,
                  style: _C.p(13, fw: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  app.department,
                  style: _C.p(10, fw: FontWeight.w500, color: _C.t2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.business, size: 11, color: _C.t3),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        app.company,
                        style: _C.p(11, color: _C.t1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: _C.t3,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMMMd().format(app.appliedAt),
                      style: _C.p(10, color: _C.t2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusBadge(status: app.status),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  RIGHT PANEL
// ═══════════════════════════════════════════════════════════════════════════
class _RightPanel extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final List<dynamic> applications;
  const _RightPanel({required this.analytics, required this.applications});

  @override
  Widget build(BuildContext context) {
    final stats = analytics['statusBreakdown'] as Map<String, dynamic>;
    final topCompanies =
        analytics['topCompanies'] as List<Map<String, dynamic>>;

    return SizedBox(
      width: 340,
      child: Column(
        children: [
          _PanelHdr(
            icon: Icons.bar_chart_rounded,
            iconBg: _C.indigoLt,
            iconColor: _C.indigo,
            title: 'Status Overview',
            sub: 'Application breakdown',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _StatusBarChart(stats: stats),
          ),

          const Divider(height: 1, thickness: 1, color: _C.border),

          if (topCompanies.isNotEmpty) ...[
            _PanelHdr(
              icon: Icons.business_rounded,
              iconBg: _C.tealLt,
              iconColor: _C.teal,
              title: 'Top Units',
              sub: 'Most applied to',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: topCompanies.take(4).map((c) {
                  final count = c['count'] as int;
                  final max = (topCompanies.first['count'] as int).clamp(
                    1,
                    9999,
                  );
                  final pct = count / max;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c['company'],
                                style: _C.p(11, color: _C.t1),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _Chip(label: '$count', color: _C.teal, tiny: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: _C.tealLt,
                            valueColor: const AlwaysStoppedAnimation(_C.teal),
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

          _PanelHdr(
            icon: Icons.work_history_rounded,
            iconBg: _C.violetLt,
            iconColor: _C.violet,
            title: 'Recent Applications',
            sub: '${applications.length} total',
            badge: _Chip(label: '${applications.length}', color: _C.violet),
          ),
          Expanded(
            child: applications.isEmpty
                ? const _Empty(
                    icon: Icons.inbox_outlined,
                    label: 'No applications yet',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                    itemCount: applications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _JobCard(app: applications[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STATUS BAR CHART
// ═══════════════════════════════════════════════════════════════════════════
class _StatusBarChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatusBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final labels = ['Pending', 'Shortlist', 'Accepted', 'Rejected'];
    final colors = [_C.amber, _C.violet, _C.emerald, _C.rose];
    final values = [
      (stats['pending'] as int).toDouble(),
      (stats['shortlist'] as int).toDouble(),
      (stats['accepted'] as int).toDouble(),
      (stats['rejected'] as int).toDouble(),
    ];
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.3;
    final safeMax = maxY < 1 ? 5.0 : maxY;

    return Container(
      height: 185,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
      ),
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
                _C.p(9, color: Colors.white),
              ),
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
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[i].substring(0, 3),
                      style: _C.p(8, fw: FontWeight.w500, color: _C.t3),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: _C.p(8, fw: FontWeight.w500, color: _C.t3),
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
                const FlLine(color: Color(0xFFF4F9FB), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(values.length, (i) {
            final col = Color.lerp(colors[i], _C.indigo, 0.3)!;
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
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: safeMax,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ],
            );
          }),
        ),
        swapAnimationDuration: const Duration(milliseconds: 600),
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
      sCol = _C.emerald;
      sIcon = Icons.check_circle_rounded;
    } else if (s == 'pending') {
      sCol = _C.amber;
      sIcon = Icons.timelapse_rounded;
    } else if (s == 'shortlist') {
      sCol = _C.violet;
      sIcon = Icons.star_rounded;
    } else if (s == 'rejected') {
      sCol = _C.rose;
      sIcon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(sIcon, color: sCol, size: 12),
              const SizedBox(width: 4),
              Text(s.toUpperCase(), style: _C.p(9, color: sCol)),
              const Spacer(),
              Text(
                DateFormat.MMMd().format(app.appliedAt),
                style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            app.title,
            style: _C.p(12, fw: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _C.canvas,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.business, size: 10, color: _C.t3),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  app.company,
                  style: _C.p(10, color: _C.t2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if ((app.department as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _C.canvas,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    size: 10,
                    color: _C.t3,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    app.department,
                    style: _C.p(10, fw: FontWeight.w500, color: _C.t3),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ANALYTICS CHARTS SECTION
// ═══════════════════════════════════════════════════════════════════════════
class _AnalyticsCharts extends StatelessWidget {
  final Map<String, dynamic> analytics;
  const _AnalyticsCharts({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final trendData =
        analytics['applicationTrend'] as List<Map<String, dynamic>>;
    final deptData =
        analytics['successRateByDepartment'] as List<Map<String, dynamic>>;
    final hasTrend = trendData.any((d) => (d['count'] as int) > 0);

    if (!hasTrend && deptData.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (_, constraints) {
        final wide = constraints.maxWidth > 640;
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTrend)
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 260,
                        child: _TrendChart(data: trendData),
                      ),
                    ),
                  if (hasTrend && deptData.isNotEmpty)
                    const SizedBox(width: 14),
                  if (deptData.isNotEmpty)
                    Expanded(flex: 2, child: _DeptCard(deptData: deptData)),
                ],
              )
            : Column(
                children: [
                  if (hasTrend) ...[
                    SizedBox(height: 230, child: _TrendChart(data: trendData)),
                    const SizedBox(height: 12),
                  ],
                  if (deptData.isNotEmpty) _DeptCard(deptData: deptData),
                ],
              );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  KPI STRIP
// ═══════════════════════════════════════════════════════════════════════════
class _KpiCard extends StatelessWidget {
  final _KD d;
  const _KpiCard({required this.d});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon bubble
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: d.bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(d.icon, color: d.accent, size: 16),
          ),
          const SizedBox(width: 10),
          // Number + label stacked
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: d.value),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutExpo,
                  builder: (_, v, _) =>
                      Text('$v', style: _C.p(20, fw: FontWeight.w800)),
                ),
                Text(
                  d.label,
                  style: _C.p(10, color: _C.t2, fw: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Subtle trend icon
          Icon(
            Icons.trending_up_rounded,
            color: d.accent.withValues(alpha: 0.25),
            size: 14,
          ),
        ],
      ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  final int total, avgResponse;
  final Map<String, dynamic> stats;
  final double responseRate, screenWidth;
  const _KpiStrip({
    required this.total,
    required this.stats,
    required this.responseRate,
    required this.avgResponse,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _KD(Icons.inbox_rounded, 'Total', total, _C.indigo, _C.indigoLt),
      _KD(
        Icons.check_circle_rounded,
        'Accepted',
        stats['accepted'] as int,
        _C.emerald,
        _C.emeraldL,
      ),
      _KD(
        Icons.star_rounded,
        'Shortlisted',
        stats['shortlist'] as int,
        _C.violet,
        _C.violetLt,
      ),
      _KD(
        Icons.timelapse_rounded,
        'Pending',
        stats['pending'] as int,
        _C.amber,
        _C.amberLt,
      ),
    ];

    // On very small screens: 2-col grid; otherwise single horizontal row
    if (screenWidth < 500) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.4, // wide + short = compact
        children: items.map((d) => _KpiCard(d: d)).toList(),
      );
    }

    // Tablet / desktop: single row, equal flex columns
    return Row(
      children: items.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < items.length - 1 ? 10 : 0),
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

// ═══════════════════════════════════════════════════════════════════════════
//  TREND CHART
// ═══════════════════════════════════════════════════════════════════════════
class _TrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _TrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Pre-process: only keep points where count > 0 OR they're needed for shape
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['count'] as int).toDouble());
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final safeMax = (maxY < 1 ? 4 : (maxY * 1.35)).ceilToDouble();

    // X-axis labels — only show every 5th date to avoid clutter
    final dates = data.map((d) => d['date'] as DateTime).toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(
            icon: Icons.show_chart_rounded,
            title: '30-Day Trend',
            sub: 'Application activity',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              LineChartData(
                minY: 0,
                maxY: safeMax,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMax / 4,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFF4F9FB), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: safeMax / 4,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        // Only show label every 5th point
                        if (i % 5 != 0 || i >= dates.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat.MMMd().format(dates[i]),
                            style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => _C.t1,
                    tooltipBorderRadius: BorderRadius.circular(4),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipItems: (spots) => spots.map((s) {
                      final i = s.x.toInt();
                      final date = i < dates.length
                          ? DateFormat.MMMd().format(dates[i])
                          : '';
                      return LineTooltipItem(
                        '$date\n',
                        _C.p(9, fw: FontWeight.w500, color: _C.t3),
                        children: [
                          TextSpan(
                            text: '${s.y.toInt()} applied',
                            style: _C.p(
                              11,
                              fw: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  // Only show dot on touch, not permanently
                  getTouchedSpotIndicator: (_, indices) => indices
                      .map(
                        (_) => TouchedSpotIndicatorData(
                          FlLine(
                            color: _C.indigo.withValues(alpha: 0.3),
                            strokeWidth: 1.5,
                            dashArray: [4, 4],
                          ),
                          FlDotData(
                            getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                              radius: 5,
                              color: Colors.white,
                              strokeColor: _C.indigo,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: _C.indigo,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    // NO dots rendered at all times
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _C.indigo.withValues(alpha: 0.18),
                          _C.indigo.withValues(alpha: 0.05),
                          _C.indigo.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0],
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _CardHead(
            icon: Icons.donut_small_rounded,
            title: 'Success Rate',
            sub: 'Acceptance by Unit/Bases',
          ),
          const SizedBox(height: 12),
          ...deptData.take(5).map((d) {
            final rate = d['rate'] as double;
            final color = rate >= 50
                ? _C.emerald
                : rate >= 25
                ? _C.amber
                : _C.rose;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          d['department'],
                          style: _C.p(11, color: _C.t1),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _Chip(
                        label: '${rate.toStringAsFixed(0)}%',
                        color: color,
                        tiny: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (rate / 100).clamp(0.0, 1.0),
                      backgroundColor: color.withValues(alpha: 0.08),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: _C.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _ColLabel('JOB POSITION')),
          Expanded(flex: 3, child: _ColLabel('UNIT / BASE')),
          Expanded(flex: 2, child: _ColLabel('DATE')),
          SizedBox(width: 110, child: Center(child: _ColLabel('STATUS'))),
        ],
      ),
    );
  }
}

class _ColLabel extends StatelessWidget {
  final String text;
  const _ColLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: _C.p(9, fw: FontWeight.w700, color: _C.t3),
  );
}

class _TableRow extends StatelessWidget {
  final dynamic app;
  final bool isLast;
  const _TableRow({required this.app, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : null,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF4F9FB))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.title,
                  style: _C.p(12, fw: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  app.department,
                  style: _C.p(10, fw: FontWeight.w500, color: _C.t2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _C.canvas,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(Icons.business, size: 11, color: _C.t3),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    app.company,
                    style: _C.p(11, color: _C.t1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _C.canvas,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: _C.t3,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    DateFormat.yMMMd().format(app.appliedAt),
                    style: _C.p(11, color: _C.t1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: Center(child: _StatusBadge(status: app.status)),
          ),
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
    Color col;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'pending':
        col = _C.amber;
        icon = Icons.timelapse_rounded;
        break;
      case 'shortlist':
        col = _C.violet;
        icon = Icons.star_rounded;
        break;
      case 'accepted':
        col = _C.emerald;
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        col = _C.rose;
        icon = Icons.cancel_rounded;
        break;
      default:
        col = _C.slate;
        icon = Icons.help_outline_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: col),
          const SizedBox(width: 4),
          Flexible(
            child: Text(status.toUpperCase(), style: _C.p(8, color: col)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PANEL HEADER
// ═══════════════════════════════════════════════════════════════════════════
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _C.p(12)),
                Text(
                  sub,
                  style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
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

// ═══════════════════════════════════════════════════════════════════════════
//  COMPACT SEARCH FIELD
// ═══════════════════════════════════════════════════════════════════════════
class _CompactSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  const _CompactSearchField({
    required this.controller,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: _C.p(12, fw: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _C.p(12, fw: FontWeight.w400, color: _C.t3),
          prefixIcon: const Icon(Icons.search, size: 16, color: _C.t3),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 14),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: _C.canvas,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: _C.indigo, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SMALL UTILITIES
// ═══════════════════════════════════════════════════════════════════════════
class _MiniStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: _C.p(10, color: color)),
        ],
      ),
    );
  }
}

class _FilterToggleBtn extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final bool compact;
  const _FilterToggleBtn({
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _C.indigo : _C.slate;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: compact
            ? Icon(
                active
                    ? Icons.filter_list_rounded
                    : Icons.filter_list_off_rounded,
                size: 16,
                color: color,
              )
            : Row(
                children: [
                  Icon(
                    active
                        ? Icons.filter_list_rounded
                        : Icons.filter_list_off_rounded,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    active ? 'Hide' : 'Filters',
                    style: _C.p(11, color: color),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _C.canvas,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _C.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          items: items.map((item) {
            final d = item == 'All'
                ? label
                : item[0].toUpperCase() + item.substring(1);
            return DropdownMenuItem(
              value: item,
              child: Text(d, style: _C.p(11, color: _C.t1)),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: _C.t2,
          ),
        ),
      ),
    );
  }
}

class _DateRangeBtn extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onTap;
  const _DateRangeBtn({required this.range, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = range != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _C.canvas,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? _C.indigo.withValues(alpha: 0.4) : _C.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: active ? _C.indigo : _C.t3,
            ),
            const SizedBox(width: 6),
            Text(
              active
                  ? '${DateFormat.MMMd().format(range!.start)} – ${DateFormat.MMMd().format(range!.end)}'
                  : 'Date Range',
              style: _C.p(11, color: active ? _C.indigo : _C.t2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _C.canvas,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _C.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          items: const [
            DropdownMenuItem(value: 'Latest', child: Text('Latest')),
            DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
            DropdownMenuItem(value: 'Title', child: Text('Title')),
            DropdownMenuItem(value: 'Unit / Base', child: Text('Unit / Base')),
            DropdownMenuItem(value: 'Status', child: Text('Status')),
          ],
          onChanged: onChanged,
          icon: const Icon(Icons.sort_rounded, size: 15, color: _C.t2),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label, style: _C.p(11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final double? height;
  const _Card({required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 3),
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
  const _CardHead({required this.icon, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _C.indigo, size: 14),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _C.p(12), overflow: TextOverflow.ellipsis),
              Text(
                sub,
                style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHead extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHead({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _C.indigo, size: 14),
        const SizedBox(width: 7),
        Text(title, style: _C.p(13)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: _C.border)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool tiny;
  const _Chip({required this.label, required this.color, this.tiny = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tiny ? 6 : 9,
        vertical: tiny ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: _C.p(tiny ? 8 : 9, color: color)),
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
          Icon(icon, color: _C.border, size: 30),
          const SizedBox(height: 7),
          Text(
            label,
            style: _C.p(11, fw: FontWeight.w500, color: _C.t3),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String status;
  final int count;
  final Color color;
  ChartData(this.status, this.count, this.color);
}
