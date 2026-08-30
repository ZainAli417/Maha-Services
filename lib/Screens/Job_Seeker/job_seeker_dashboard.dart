import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'JS_Top_Bar.dart';
import 'List_applied_jobs_provider.dart';
import '../../Constant/js_header.dart';
import 'JS_Profile/JS_Profile_Provider.dart';
import 'widgets/profile_timeline.dart';
import 'assessment/assessment_invite_banner.dart';

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
  static const border = Color(0xFFDCE7EF);
  static const bgSoft = Color(0xFFF4F9FB);

  // Navy / blue family
  static const indigo = Color(0xFF14507F); // primary navy
  static const indigoLt = Color(0xFFE8F1F8); // navy tint
  static const navyDeep = Color(0xFF0A2E4F);
  static const blue = Color(0xFF2178B5);
  // Teal family
  static const teal = Color(0xFF2EC4B6);
  static const tealLt = Color(0xFFE4F6F4); // teal tint
  static const tealBright = Color(0xFF43E0D2);
  static const tealDeep = Color(0xFF15A99C);
  // Status (brand semantics)
  static const emerald = Color(0xFF10B981); // success
  static const emeraldL = Color(0xFFDCFCED);
  static const amber = Color(0xFFF59E0B); // warning
  static const amberLt = Color(0xFFFEF3CD);
  static const rose = Color(0xFFEF4444); // error
  static const roseLt = Color(0xFFFCE7ED);
  static const coral = Color(0xFFFF7A59);
  static const violet = Color(0xFF15A99C); // (teal deep — no purple)
  static const violetLt = Color(0xFFE4F6F4);
  static const slate = Color(0xFF5E7A8E); // muted

  static const t1 = Color(0xFF0B2239); // ink
  static const t2 = Color(0xFF3E5C76); // slate
  static const t3 = Color(0xFF8AA5B5); // faint

  // Brand card shadows
  static const softShadow = [
    BoxShadow(color: Color(0x0D0B2239), blurRadius: 16, offset: Offset(0, 8)),
  ];
  static const hoverShadow = [
    BoxShadow(color: Color(0x262EC4B6), blurRadius: 22, offset: Offset(0, 10)),
  ];

  // Brand primary gradient (teal → navy)
  static const brandGradient = LinearGradient(
    colors: [teal, indigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
        backgroundColor: _C.bgSoft,
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
                        const AssessmentInviteBanner(),
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
    return JobSeekerHeader(
      icon: Icons.work_history_rounded,
      title: title,
      subtitle: 'Trends & insights',
      onMenu: () => _scaffoldKey.currentState?.openDrawer(),
      trailing: _FilterToggleBtn(
        active: _showFilters,
        onTap: () => setState(() => _showFilters = !_showFilters),
        compact: true,
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
            return const _BrandLoader();
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _C.rose.withValues(alpha: 0.16),
                                _C.rose.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _C.rose.withValues(alpha: 0.22),
                            ),
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            size: 34,
                            color: _C.rose,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to Load Applications',
                          style: _C.p(15, fw: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          prov.error!,
                          style: _C.p(12, color: _C.t2, fw: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        _GradientBtn(
                          label: 'Retry',
                          icon: Icons.refresh_rounded,
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
                            color: _C.teal,
                            backgroundColor: _C.surface,
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              cacheExtent: 700,
                              slivers: [
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(
                                    _BP.hPad(w),
                                    _BP.hPad(w),
                                    _BP.hPad(w),
                                    0,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Shown before the application stats:
                                        // a brand-new candidate has a profile
                                        // but no applications yet.
                                        _CareerTimelineCard(isMobile: isMobile),
                                        SizedBox(height: isMobile ? 14 : 18),
                                        if (prov.applications.isNotEmpty) ...[
                                          _KpiStrip(
                                            total:
                                                analytics['totalApplications']
                                                    as int,
                                            stats:
                                                analytics['statusBreakdown']
                                                    as Map<String, dynamic>,
                                            responseRate:
                                                analytics['responseRate']
                                                    as double,
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
                                      ],
                                    ),
                                  ),
                                ),
                                ..._buildTableSlivers(sorted, isMobile, w),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 16),
                                ),
                              ],
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
    return JobSeekerHeader(
      icon: Icons.work_history_rounded,
      title: 'My Applications',
      subtitle: 'Trends & insights',
      trailing: _FilterToggleBtn(
        active: _showFilters,
        onTap: () => setState(() => _showFilters = !_showFilters),
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
        color: _C.bgSoft, // match JobSeekerHeader canvas (0xFFF4F9FB)
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
  List<Widget> _buildTableSlivers(
    List<dynamic> apps,
    bool isMobile,
    double w,
  ) {
    final hPad = _BP.hPad(w);

    if (apps.isEmpty) {
      return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          sliver: SliverToBoxAdapter(
            child: _EmptyState(isMobile: isMobile),
          ),
        ),
      ];
    }

    // On mobile: lazy card list (SliverList.builder)
    if (isMobile) {
      return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          sliver: SliverList.builder(
            itemCount: apps.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MobileAppCard(app: apps[i]),
            ),
          ),
        ),
      ];
    }

    // Desktop: bordered table shell with lazily-built rows
    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        sliver: SliverToBoxAdapter(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
              boxShadow: _C.softShadow,
            ),
            child: Column(
              children: [
                _TableHeader(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: apps.length,
                  itemBuilder: (_, i) =>
                      _TableRow(app: apps[i], isLast: i == apps.length - 1),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
        boxShadow: _C.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompanyLogo(company: app.company, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        app.title,
                        style: _C.p(13, fw: FontWeight.w800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: app.status),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  app.department,
                  style: _C.p(10, fw: FontWeight.w600, color: _C.teal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.business_rounded,
                      size: 11,
                      color: _C.t3,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        app.company,
                        style: _C.p(11, fw: FontWeight.w600, color: _C.t1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: _C.t3,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMMMd().format(app.appliedAt),
                      style: _C.p(10, fw: FontWeight.w500, color: _C.t2),
                    ),
                  ],
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
//  RIGHT PANEL
// ═══════════════════════════════════════════════════════════════════════════
/// Career progression, education and credential validity, read from the
/// role-template profile onboarding wrote. Collapses to a prompt when the
/// candidate has not built one yet.
class _CareerTimelineCard extends StatelessWidget {
  const _CareerTimelineCard({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider_NEW>();
    final candidate = profile.candidateProfile;

    if (profile.isLoading && candidate == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionHead(
                icon: Icons.timeline_rounded,
                title: candidate == null
                    ? 'Your Profile'
                    : 'Career Timeline'
                        '${candidate.targetRole.roleTitle.isEmpty ? '' : ' · ${candidate.targetRole.roleTitle}'}',
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: Text(candidate == null ? 'Complete profile' : 'View profile'),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 10 : 14),
        _Card(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: ProfileTimeline(
              profile: candidate,
              maxItems: isMobile ? 4 : 6,
              onViewAll: () => context.go('/profile'),
            ),
          ),
        ),
      ],
    );
  }
}

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

    return RepaintBoundary(
      child: Container(
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  JOB CARD (right panel)
// ═══════════════════════════════════════════════════════════════════════════
class _JobCard extends StatefulWidget {
  final dynamic app;
  const _JobCard({required this.app});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
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

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(12),
            // Uniform border (non-uniform + borderRadius throws on paint).
            border: Border.all(
              color: _hover ? sCol : _C.border,
              width: _hover ? 1.6 : 1,
            ),
            boxShadow: _hover ? _C.hoverShadow : _C.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyLogo(company: app.company, size: 34),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.title,
                          style: _C.p(12, fw: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(sIcon, color: sCol, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              s.toUpperCase(),
                              style: _C.p(9, fw: FontWeight.w700, color: sCol),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat.MMMd().format(app.appliedAt),
                              style: _C.p(9, fw: FontWeight.w500, color: _C.t3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _C.bgSoft,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      size: 10,
                      color: _C.t3,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      app.company,
                      style: _C.p(10, fw: FontWeight.w600, color: _C.t2),
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
                        color: _C.bgSoft,
                        borderRadius: BorderRadius.circular(5),
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
        ),
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
  final bool compact;
  const _KpiCard({required this.d, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 12 : 16);
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: d.bg, // soft tinted tile (was pure white → read as blank)
          borderRadius: radius,
          // Uniform border only — a non-uniform border with borderRadius throws
          // "A borderRadius can only be given on borders with uniform colors".
          border: Border.all(color: _C.border),
          boxShadow: _C.softShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent stripe (flush to the rounded edge)
                Container(width: 3, color: d.accent),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 10 : 13,
                      compact ? 9 : 12,
                      compact ? 10 : 13,
                      compact ? 9 : 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // White icon chip (contrasts against the tinted tile)
                        Container(
                          padding: EdgeInsets.all(compact ? 7 : 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              compact ? 9 : 11,
                            ),
                          ),
                          child: Icon(
                            d.icon,
                            color: d.accent,
                            size: compact ? 15 : 18,
                          ),
                        ),
                        SizedBox(width: compact ? 9 : 11),
                        // Number + label stacked
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TweenAnimationBuilder<int>(
                                tween: IntTween(begin: 0, end: d.value),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutExpo,
                                builder: (_, v, _) => Text(
                                  '$v',
                                  style: _C.p(
                                    compact ? 18 : 23,
                                    fw: FontWeight.w800,
                                    color: d.accent,
                                  ),
                                ),
                              ),
                              Text(
                                d.label,
                                style: _C.p(
                                  compact ? 9.5 : 10.5,
                                  color: _C.t1,
                                  fw: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

    // Mobile: compact 2-up grid; tablet/desktop: single horizontal row
    if (screenWidth < _BP.mobile) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.5, // wide + short = compact
        children: items.map((d) => _KpiCard(d: d, compact: true)).toList(),
      );
    }

    // Tablet / desktop: single row, equal flex columns
    return Row(
      children: items.asMap().entries.map((e) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < items.length - 1 ? 12 : 0),
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

    return RepaintBoundary(
      child: _Card(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        color: _C.bgSoft,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
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
    style: _C.p(9, fw: FontWeight.w700, color: _C.slate).copyWith(
      letterSpacing: 0.8,
    ),
  );
}

class _TableRow extends StatefulWidget {
  final dynamic app;
  final bool isLast;
  const _TableRow({required this.app, required this.isLast});

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final isLast = widget.isLast;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: _hover ? _C.tealLt.withValues(alpha: 0.5) : Colors.transparent,
          // Bottom-only divider (no borderRadius here → avoids the
          // "borderRadius on non-uniform border" paint crash). The last row's
          // rounded corner is handled by the table shell's clip.
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : const BorderSide(color: _C.bgSoft),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _CompanyLogo(company: app.company, size: 32),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.title,
                          style: _C.p(12, fw: FontWeight.w800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          app.department,
                          style: _C.p(10, fw: FontWeight.w600, color: _C.teal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
                      color: _C.bgSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      size: 11,
                      color: _C.t3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      app.company,
                      style: _C.p(11, fw: FontWeight.w600, color: _C.t1),
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
                    color: _C.bgSoft,
                    borderRadius: BorderRadius.circular(6),
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
                    style: _C.p(11, fw: FontWeight.w600, color: _C.t1),
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
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: col.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: col),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.toUpperCase(),
              style: _C.p(8, fw: FontWeight.w700, color: col),
            ),
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
          fillColor: _C.bgSoft,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.teal, width: 1.6),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SMALL UTILITIES
// ═══════════════════════════════════════════════════════════════════════════
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
    final isActive = active;
    final bgColor = isActive
        ? const Color(0xFF2EC4B6)
        : Colors.white;
    final borderColor = isActive
        ? const Color(0xFF2EC4B6)
        : const Color(0xFF0B2239).withValues(alpha: 0.25);
    final contentColor = isActive
        ? Colors.white
        : const Color(0xFF0B2239);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B2239).withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: compact
            ? Icon(
                active
                    ? Icons.filter_list_rounded
                    : Icons.filter_list_off_rounded,
                size: 16,
                color: contentColor,
              )
            : Row(
                children: [
                  Icon(
                    active
                        ? Icons.filter_list_rounded
                        : Icons.filter_list_off_rounded,
                    size: 14,
                    color: contentColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    active ? 'Hide' : 'Filters',
                    style: _C.p(11, color: contentColor).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
        color: _C.bgSoft,
        borderRadius: BorderRadius.circular(10),
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
          color: active ? _C.tealLt : _C.bgSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? _C.teal.withValues(alpha: 0.45) : _C.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: active ? _C.tealDeep : _C.t3,
            ),
            const SizedBox(width: 6),
            Text(
              active
                  ? '${DateFormat.MMMd().format(range!.start)} – ${DateFormat.MMMd().format(range!.end)}'
                  : 'Date Range',
              style: _C.p(11, color: active ? _C.tealDeep : _C.t2),
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
        color: _C.bgSoft,
        borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: _C.softShadow,
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
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _C.tealLt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _C.tealDeep, size: 14),
        ),
        const SizedBox(width: 9),
        Text(title, style: _C.p(13, fw: FontWeight.w800)),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.border, _C.border.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: _C.p(tiny ? 8 : 9, fw: FontWeight.w700, color: color),
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

// ═══════════════════════════════════════════════════════════════════════════
//  BRAND: COMPANY LOGO / MONOGRAM
// ═══════════════════════════════════════════════════════════════════════════
class _CompanyLogo extends StatelessWidget {
  final String company;
  final double size;
  const _CompanyLogo({required this.company, this.size = 36});

  // [tint bg, accent] pairs — navy/teal brand family only
  static const List<List<Color>> _tints = [
    [_C.indigoLt, _C.indigo],
    [_C.tealLt, _C.tealDeep],
    [_C.emeraldL, _C.emerald],
    [_C.amberLt, _C.amber],
    [_C.indigoLt, _C.blue],
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = company.trim();
    final letter = (trimmed.isEmpty || trimmed == '—')
        ? '?'
        : trimmed[0].toUpperCase();
    final pair = _tints[trimmed.hashCode.abs() % _tints.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pair[0],
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: pair[1].withValues(alpha: 0.18)),
      ),
      child: Text(
        letter,
        style: _C.p(size * 0.42, fw: FontWeight.w800, color: pair[1]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BRAND: GRADIENT PRIMARY BUTTON
// ═══════════════════════════════════════════════════════════════════════════
class _GradientBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _C.brandGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _C.teal.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: _C.p(12, fw: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BRAND: LOADING STATE
// ═══════════════════════════════════════════════════════════════════════════
class _BrandLoader extends StatelessWidget {
  const _BrandLoader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: _C.tealLt,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: _C.teal,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Loading your applications…',
            style: _C.p(12, fw: FontWeight.w600, color: _C.t2),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BRAND: EMPTY STATE (applications)
// ═══════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool isMobile;
  const _EmptyState({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 56,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: _C.softShadow,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_C.tealLt, _C.indigoLt],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: _C.teal.withValues(alpha: 0.18)),
              ),
              child: Icon(
                Icons.work_outline_rounded,
                size: isMobile ? 34 : 40,
                color: _C.tealDeep,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Applications Found',
              style: _C.p(isMobile ? 15 : 16, fw: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Adjust your filters or start applying to new positions to see them here.',
                style: _C.p(11, fw: FontWeight.w500, color: _C.t2),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
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
