import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../Constant/profile_Completeness.dart';
import 'JS_Profile/JS_Profile_Provider.dart';
import 'JS_Top_Bar.dart';
import 'List_applied_jobs_provider.dart';

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

  // Professional color palette
  static const Color kPrimaryBlue = Color(0xFF0F172A);
  static const Color kAccentBlue = Color(0xFF3B82F6);
  static const Color kTextPrimary = Color(0xFF0F172A);
  static const Color kTextSecondary = Color(0xFF64748B);
  static const Color kBorderLight = Color(0xFFE2E8F0);
  static const Color kBackgroundGray = Color(0xFFF8FAFC);
  static const Color kSuccessGreen = Color(0xFF10B981);
  static const Color kWarningOrange = Color(0xFFF59E0B);
  static const Color kErrorRed = Color(0xFFEF4444);
  static const Color kInfoPurple = Color(0xFF8B5CF6);
  static const Color kCardWhite = Color(0xFFFFFFFF);

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedCompany = 'All';
  DateTimeRange? _appliedRange;
  final List<String> _statusOptions = ['All', 'pending', 'shortlist', 'accepted', 'rejected'];
  List<String> _companyOptions = ['All'];
  String _sortBy = 'applied_desc';
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  bool _inRange(DateTime date, DateTimeRange? range) {
    if (range == null) return true;
    return date.isAfter(range.start.subtract(const Duration(days: 1))) &&
        date.isBefore(range.end.add(const Duration(days: 1)));
  }

  List<dynamic> _sortApplications(List applications) {
    final sortedList = List.from(applications);
    switch (_sortBy) {
      case 'applied_desc':
        sortedList.sort((a, b) => (b as dynamic).appliedAt.compareTo((a as dynamic).appliedAt));
        break;
      case 'applied_asc':
        sortedList.sort((a, b) => (a as dynamic).appliedAt.compareTo((b as dynamic).appliedAt));
        break;
      case 'title_asc':
        sortedList.sort((a, b) => (a as dynamic).title.compareTo((b as dynamic).title));
        break;
      case 'company_asc':
        sortedList.sort((a, b) => (a as dynamic).company.compareTo((b as dynamic).company));
        break;
      case 'status':
        sortedList.sort((a, b) => (a as dynamic).status.compareTo((b as dynamic).status));
        break;
    }
    return sortedList;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = 'All';
      _selectedCompany = 'All';
      _appliedRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: SmoothScrollBehavior(),
      child: Scaffold(
        backgroundColor: kBackgroundGray,
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

  Widget _buildContent(BuildContext context) {
    return ChangeNotifierProvider<ListAppliedJobsProvider>(
      create: (_) => ListAppliedJobsProvider()..refresh(),
      child: Consumer<ListAppliedJobsProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: kAccentBlue,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Loading your applications...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: kTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          if (prov.error != null) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCardWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kErrorRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.error_outline, size: 48, color: kErrorRed),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Unable to Load Applications',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prov.error!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: kTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => prov.refresh(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          _companyOptions = ['All'] +
              prov.applications.map((a) => a.company).toSet().toList();

          final filtered = prov.applications.where((app) {
            final query = _searchController.text.toLowerCase();
            return (_selectedStatus == 'All' || app.status == _selectedStatus) &&
                (_selectedCompany == 'All' || app.company == _selectedCompany) &&
                _inRange(app.appliedAt, _appliedRange) &&
                (query.isEmpty ||
                    app.title.toLowerCase().contains(query) ||
                    app.company.toLowerCase().contains(query) ||
                    app.jobId.toLowerCase().contains(query));
          }).toList();

          final sortedFiltered = _sortApplications(filtered);
          final analytics = prov.getAnalytics(sortedFiltered);

          return _buildMainLayout(prov, sortedFiltered, analytics);
        },
      ),
    );
  }

  Widget _buildMainLayout(
      ListAppliedJobsProvider prov, List<dynamic> sortedFiltered, Map<String, dynamic> analytics) {
    return Column(
      children: [
        _buildHeader(analytics, sortedFiltered.length),
        if (_showFilters) _buildCompactFilters(prov),
        if (prov.applications.isNotEmpty) _buildAnalyticsSection(analytics),
        Expanded(child: _buildJobsList(sortedFiltered)),
      ],
    );
  }
  Widget _buildHeader(Map<String, dynamic> analytics, int filteredCount) {
    const Color kPrimaryBlue = Color(0xFF1E40AF);
    const Color kTextPrimary = Color(0xFF0F172A);
    const Color kTextSecondary = Color(0xFF475569);
    const Color kBorderLight = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kBorderLight, width: 1)),
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
              Icons.person_add_alt_outlined,
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
                'Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                  height: 1.2,
                ),
              ),
              Text(
                'View your Latest Trends & Market Insights',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: kTextSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),

          const Spacer(),

          _buildFilterToggle(),
        ],
      ),
    );
  }



  Widget _buildStatChip(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggle() {
    return InkWell(
      onTap: () => setState(() => _showFilters = !_showFilters),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _showFilters ? kAccentBlue.withOpacity(0.08) : kBackgroundGray,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _showFilters ? kAccentBlue.withOpacity(0.3) : kBorderLight,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_off,
              size: 18,
              color: _showFilters ? kAccentBlue : kTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              _showFilters ? 'Hide Filters' : 'Show Filters',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _showFilters ? kAccentBlue : kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFilters(ListAppliedJobsProvider prov) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: kCardWhite,
        border: Border(
          bottom: BorderSide(color: kBorderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by title, Unit or Base...',
                  hintStyle: GoogleFonts.poppins(
                    color: kTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20, color: kTextSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: kBackgroundGray,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: kBorderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: kBorderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kAccentBlue, width: 2),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildCompactDropdown('Status', _selectedStatus, _statusOptions, (val) {
            setState(() => _selectedStatus = val!);
          }),
          const SizedBox(width: 12),
          _buildCompactDropdown('All Units/Base', _selectedCompany, _companyOptions, (val) {
            setState(() => _selectedCompany = val!);
          }),
          const SizedBox(width: 12),
          _buildCompactDateFilter(),
          const SizedBox(width: 12),
          _buildCompactSortDropdown(),
          if (_hasActiveFilters()) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: _clearFilters,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: kErrorRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kErrorRed.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.clear_all, size: 18, color: kErrorRed),
                    const SizedBox(width: 6),
                    Text(
                      'Clear Filters',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kErrorRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactDropdown(
      String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: kBackgroundGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item == 'All' ? label : item.substring(0, 1).toUpperCase() + item.substring(1),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
        ),
      ),
    );
  }

  Widget _buildCompactDateFilter() {
    return InkWell(
      onTap: _showDatePicker,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: kBackgroundGray,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorderLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: kTextSecondary),
            const SizedBox(width: 8),
            Text(
              _appliedRange == null
                  ? 'Date Range'
                  : '${DateFormat.MMMd().format(_appliedRange!.start)} - ${DateFormat.MMMd().format(_appliedRange!.end)}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSortDropdown() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: kBackgroundGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _getSortLabel(),
          isDense: true,
          items: const [
            DropdownMenuItem(value: 'Latest', child: Text('Latest')),
            DropdownMenuItem(value: 'Oldest', child: Text('Oldest')),
            DropdownMenuItem(value: 'Title', child: Text('Title')),
            DropdownMenuItem(value: 'Company', child: Text('Company')),
            DropdownMenuItem(value: 'Status', child: Text('Status')),
          ],
          onChanged: (val) {
            setState(() {
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
                case 'Company':
                  _sortBy = 'company_asc';
                  break;
                case 'Status':
                  _sortBy = 'status';
                  break;
              }
            });
          },
          icon: const Icon(Icons.sort, size: 18),
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'applied_desc':
        return 'Latest';
      case 'applied_asc':
        return 'Oldest';
      case 'title_asc':
        return 'Title';
      case 'company_asc':
        return 'Company';
      case 'status':
        return 'Status';
      default:
        return 'Latest';
    }
  }

  void _showDatePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kAccentBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: kTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _appliedRange = picked);
    }
  }

  Widget _buildAnalyticsSection(Map<String, dynamic> analytics) {
    final stats = analytics['statusBreakdown'] as Map<String, dynamic>;
    final total = analytics['totalApplications'] as int;
    final responseRate = analytics['responseRate'] as double;
    final avgResponse = analytics['averageResponseTime'] as int;
    final topCompanies = analytics['topCompanies'] as List<Map<String, dynamic>>;
    final deptData = analytics['successRateByDepartment'] as List<Map<String, dynamic>>;
    final trendData = analytics['applicationTrend'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kCardWhite,

      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (total > 0)
                SizedBox(
                  width: 260,
                  height: 220,
                  child: _buildDoughnutChart(stats),
                ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Response Rate',
                            '${responseRate.toStringAsFixed(1)}%',
                            Icons.trending_up,
                            kAccentBlue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMetricCard(
                            'Avg Response Time',
                            avgResponse > 0 ? '$avgResponse days' : 'N/A',
                            Icons.access_time,
                            kWarningOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (topCompanies.isNotEmpty)
                          Expanded(
                            child: _buildTopCompaniesTile(topCompanies),
                          ),
                        const SizedBox(width: 16),
                        if (deptData.isNotEmpty)
                          Expanded(
                            child: _buildDepartmentTile(deptData),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              if (trendData.any((d) => (d['count'] as int) > 0))
                SizedBox(
                  width: 380,
                  height: 220,
                  child: _buildTrendChart(trendData),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoughnutChart(Map<String, dynamic> stats) {
    final total = (stats['pending'] as int) +
        (stats['shortlist'] as int) +
        (stats['accepted'] as int) +
        (stats['rejected'] as int);

    final chartData = [
      ChartData('Pending', stats['pending'], kWarningOrange),
      ChartData('Shortlist', stats['shortlist'], kInfoPurple),
      ChartData('Accepted', stats['accepted'], kSuccessGreen),
      ChartData('Rejected', stats['rejected'], kErrorRed),
    ];

    return SfCircularChart(
      annotations: [
        CircularChartAnnotation(
          widget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'Total Apps',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: kTextSecondary,
        ),
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      series: [
        DoughnutSeries<ChartData, String>(
          dataSource: chartData,
          xValueMapper: (data, _) => data.status,
          yValueMapper: (data, _) => data.count,
          pointColorMapper: (data, _) => data.color,
          radius: '100%',
          innerRadius: '70%',
          dataLabelSettings: const DataLabelSettings(isVisible: false),
          strokeWidth: 0,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCompaniesTile(List<Map<String, dynamic>> companies) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBackgroundGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, size: 16, color: kAccentBlue),
              const SizedBox(width: 8),
              Text(
                'Top Units',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kTextSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...companies.take(3).map((c) {
            final company = c['company'] as String;
            final count = c['count'] as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: kAccentBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      company,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAccentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: kAccentBlue,
                      ),
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

  Widget _buildDepartmentTile(List<Map<String, dynamic>> deptData) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBackgroundGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, size: 16, color: kSuccessGreen),
              const SizedBox(width: 8),
              Text(
                'Success by Department',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kTextSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...deptData.take(3).map((d) {
            final dept = d['department'] as String;
            final rate = d['rate'] as double;
            Color rateColor = rate >= 50
                ? kSuccessGreen
                : rate >= 25
                ? kWarningOrange
                : kErrorRed;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: rateColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dept,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rateColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${rate.toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: rateColor,
                      ),
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

  Widget _buildTrendChart(List<Map<String, dynamic>> trendData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBackgroundGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, size: 16, color: kAccentBlue),
              const SizedBox(width: 8),
              Text(
                'Application Trend (30 Days)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kTextSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: DateTimeAxis(
                intervalType: DateTimeIntervalType.days,
                interval: 7,
                dateFormat: DateFormat.MMMd(),
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 10,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                  color: kBorderLight,
                  width: 1,
                  dashArray: [5, 5],
                ),
                axisLine: const AxisLine(width: 0),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 10,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: kPrimaryBlue,
                textStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              series: [
                SplineAreaSeries<Map<String, dynamic>, DateTime>(
                  dataSource: trendData,
                  xValueMapper: (data, _) => data['date'] as DateTime,
                  yValueMapper: (data, _) => data['count'] as int,
                  gradient: LinearGradient(
                    colors: [
                      kAccentBlue.withOpacity(0.3),
                      kAccentBlue.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderColor: kAccentBlue,
                  borderWidth: 2.5,
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    height: 6,
                    width: 6,
                    color: kAccentBlue,
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

  Widget _buildJobsList(List<dynamic> applications) {
    if (applications.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: kCardWhite,

          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kBackgroundGray,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.work_outline_rounded,
                  size: 64,
                  color: kTextSecondary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Applications Found',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or start applying to new positions',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: kCardWhite,

      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final isLast = index == applications.length - 1;
                return _buildJobRow(applications[index], index, isLast);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: kBackgroundGray,
        border: Border(bottom: BorderSide(color: kBorderLight, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'JOB POSITION',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: kTextSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'COMPANY',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: kTextSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'APPLIED DATE',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: kTextSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Center(
              child: Text(
                'STATUS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: kTextSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobRow(dynamic app, int index, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(color: kBorderLight.withOpacity(0.6), width: 1),
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : null,
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
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  app.department,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kTextSecondary,
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kBackgroundGray,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.business, size: 14, color: kTextSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    app.company,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kBackgroundGray,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.calendar_today, size: 14, color: kTextSecondary),
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormat.yMMMd().format(app.appliedAt),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 140,
            child: Center(child: _buildStatusBadge(app.status)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        color = kWarningOrange;
        icon = Icons.schedule;
        displayText = 'Pending';
        break;
      case 'shortlist':
        color = kInfoPurple;
        icon = Icons.star;
        displayText = 'Shortlist';
        break;
      case 'accepted':
        color = kSuccessGreen;
        icon = Icons.check_circle;
        displayText = 'Accepted';
        break;
      case 'rejected':
        color = kErrorRed;
        icon = Icons.cancel;
        displayText = 'Rejected';
        break;
      default:
        color = kTextSecondary;
        icon = Icons.help_outline;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            displayText.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchController.text.isNotEmpty ||
        _selectedStatus != 'All' ||
        _selectedCompany != 'All' ||
        _appliedRange != null;
  }
}

class ChartData {
  ChartData(this.status, this.count, this.color);
  final String status;
  final int count;
  final Color color;
}