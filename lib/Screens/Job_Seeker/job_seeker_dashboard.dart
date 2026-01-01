import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedCompany = 'All';
  DateTimeRange? _appliedRange;
  DateTimeRange? _createdRange;
  final List<String> _statusOptions = ['All', 'pending', 'accepted', 'rejected'];
  List<String> _companyOptions = ['All'];
  String _sortBy = 'applied_desc';
  late Animation<Offset> _slideAnimation;
  bool _showFilters = true;

  @override
  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward(); // <--- start the slide animation immediately

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
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

  List<dynamic> _sortApplications(List<dynamic> applications) {
    final sortedList = List<dynamic>.from(applications);
    switch (_sortBy) {
      case 'applied_desc':
        sortedList.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
        break;
      case 'applied_asc':
        sortedList.sort((a, b) => a.appliedAt.compareTo(b.appliedAt));
        break;
      case 'title_asc':
        sortedList.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'company_asc':
        sortedList.sort((a, b) => a.company.compareTo(b.company));
        break;
      case 'status':
        sortedList.sort((a, b) => a.status.compareTo(b.status));
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
      _createdRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: SmoothScrollBehavior(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
           JobSeekerSidebar(activeIndex: 0),
            Expanded(
              child:Padding(padding: EdgeInsetsGeometry.all(0),

              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(context),
                ),
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
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            );
          }

          if (prov.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(prov.error!, style: GoogleFonts.inter(color: Color(0xFF64748B))),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => prov.refresh(),
                    child: Text('Retry'),
                  ),
                ],
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
                _inRange(app.createdAt, _createdRange) &&
                (query.isEmpty ||
                    app.title.toLowerCase().contains(query) ||
                    app.company.toLowerCase().contains(query) ||
                    app.jobId.toLowerCase().contains(query));
          }).toList();

          final sortedFiltered = _sortApplications(filtered);

          return _buildMainLayout(prov, sortedFiltered);
        },
      ),
    );
  }

  Widget _buildMainLayout(ListAppliedJobsProvider prov, List<dynamic> sortedFiltered) {
    return Column(

        children: [

        // Header Section
        _buildHeader(prov, sortedFiltered.length),

        // Horizontal Filters (Collapsible)
        if (_showFilters) _buildHorizontalFilters(prov),

        // Main Content Area
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Jobs List
              Expanded(
                flex: prov.applications.isEmpty ? 1 : 3,
                child: _buildJobsList(sortedFiltered),
              ),

              // Stats Sidebar - Only show if there are applications
              if (prov.applications.isNotEmpty)
                Container(
                  width: 340,
                  child: _buildStatsSidebar(prov),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ListAppliedJobsProvider prov, int count) {
    final pending = prov.applications.where((a) => a.status == 'pending').length;
    final accepted = prov.applications.where((a) => a.status == 'accepted').length;
    final rejected = prov.applications.where((a) => a.status == 'rejected').length;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Title Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applied Jobs',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? 'application' : 'applications'} found',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Stats
              Row(
                children: [
                  _buildQuickStatCard('Pending', pending, const Color(0xFFF59E0B)),
                  const SizedBox(width: 12),
                  _buildQuickStatCard('Accepted', accepted, const Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  _buildQuickStatCard('Rejected', rejected, const Color(0xFFEF4444)),
                ],
              ),

              const SizedBox(width: 16),

              // Filter Toggle Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _showFilters ? const Color(0xFF6366F1).withOpacity(0.08) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _showFilters ? const Color(0xFF6366F1).withOpacity(0.3) : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showFilters ? Icons.filter_list : Icons.filter_list_off,
                          size: 16,
                          color: _showFilters ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showFilters ? 'Hide Filters' : 'Show Filters',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _showFilters ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalFilters(ListAppliedJobsProvider prov) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by job title, company, or ID...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_outlined,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 13),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filter Chips Row
          Row(
            children: [
              // Status Filter
              _buildFilterChip(
                label: 'Status',
                icon: Icons.pending_actions_outlined,
                value: _selectedStatus == 'All' ? 'All Status' : _selectedStatus,
                options: _statusOptions.map((s) => s == 'All' ? 'All Status' : s).toList(),
                onSelect: (val) {
                  setState(() {
                    _selectedStatus = val == 'All Status' ? 'All' : val;
                  });
                },
              ),

              const SizedBox(width: 12),

              // Company Filter
              _buildFilterChip(
                label: 'Company',
                icon: Icons.business_outlined,
                value: _selectedCompany == 'All' ? 'All Companies' : _selectedCompany,
                options: _companyOptions.map((c) => c == 'All' ? 'All Companies' : c).toList(),
                onSelect: (val) {
                  setState(() {
                    _selectedCompany = val == 'All Companies' ? 'All' : val;
                  });
                },
              ),

              const SizedBox(width: 12),

              // Applied Date Filter
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showDatePicker(true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Applied Date',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              _appliedRange == null
                                  ? 'Any time'
                                  : '${DateFormat.MMMd().format(_appliedRange!.start)} - ${DateFormat.MMMd().format(_appliedRange!.end)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Sort Filter
              _buildFilterChip(
                label: 'Sort',
                icon: Icons.sort_outlined,
                value: _getSortLabel(),
                options: const [
                  'Latest Applied',
                  'Oldest Applied',
                  'Title A-Z',
                  'Company A-Z',
                  'Status',
                ],
                onSelect: (val) {
                  setState(() {
                    switch (val) {
                      case 'Latest Applied':
                        _sortBy = 'applied_desc';
                        break;
                      case 'Oldest Applied':
                        _sortBy = 'applied_asc';
                        break;
                      case 'Title A-Z':
                        _sortBy = 'title_asc';
                        break;
                      case 'Company A-Z':
                        _sortBy = 'company_asc';
                        break;
                      case 'Status':
                        _sortBy = 'status';
                        break;
                    }
                  });
                },
              ),

              const Spacer(),

              // Clear Filters Button
              if (_hasActiveFilters())
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _clearFilters,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.clear_all,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Clear Filters',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required Function(String) onSelect,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelect,
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: Text(
            option,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, size: 20, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'applied_desc': return 'Latest Applied';
      case 'applied_asc': return 'Oldest Applied';
      case 'title_asc': return 'Title A-Z';
      case 'company_asc': return 'Company A-Z';
      case 'status': return 'Status';
      default: return 'Latest Applied';
    }
  }

  void _showDatePicker(bool isAppliedDate) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: isAppliedDate ? _appliedRange : _createdRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF6366F1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        if (isAppliedDate) {
          _appliedRange = range;
        } else {
          _createdRange = range;
        }
      });
    }
  }

  Widget _buildJobsList(List<dynamic> applications) {
    if (applications.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.work_outline,
                  size: 48,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Applications Found',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try adjusting your filters or start applying to jobs',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'JOB TITLE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'COMPANY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'APPLIED DATE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Center(
                    child: Text(
                      'STATUS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final app = applications[index];
                return _buildJobRow(app, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobRow(dynamic app, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          // Job Title
          Expanded(
            flex: 3,
            child: Text(
              app.title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Company
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(
                  Icons.business_outlined,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    app.company,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Applied Date
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat.MMMd().format(app.appliedAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          SizedBox(
            width: 100,
            child: Center(
              child: _buildStatusBadge(app.status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = const Color(0xFFF59E0B);
        icon = Icons.schedule;
        break;
      case 'accepted':
        color = const Color(0xFF10B981);
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = const Color(0xFFEF4444);
        icon = Icons.cancel;
        break;
      default:
        color = const Color(0xFF64748B);
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSidebar(ListAppliedJobsProvider prov) {
    final profileProv = Provider.of<ProfileProvider_NEW>(context, listen: true);

    return Container(
      margin: const EdgeInsets.only(right: 20, top: 20, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Overview',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Profile Completeness
            ProfileCompletenessCard.fromProvider(profileProv),

            const SizedBox(height: 20),

            // Application Stats
            _buildApplicationStats(prov),

            const SizedBox(height: 20),

            // Recent Activity
            _buildRecentActivity(prov),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationStats(ListAppliedJobsProvider prov) {
    final pending = prov.applications.where((a) => a.status == 'pending').length;
    final accepted = prov.applications.where((a) => a.status == 'accepted').length;
    final rejected = prov.applications.where((a) => a.status == 'rejected').length;
    final total = prov.applications.length;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 32,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'No Statistics Yet',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'APPLICATION STATS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1,
            ),
          ),
        ),

        // Stats Cards
        _buildStatCard('Pending', pending, total, const Color(0xFFF59E0B), Icons.schedule),
        const SizedBox(height: 8),
        _buildStatCard('Accepted', accepted, total, const Color(0xFF10B981), Icons.check_circle),
        const SizedBox(height: 8),
        _buildStatCard('Rejected', rejected, total, const Color(0xFFEF4444), Icons.cancel),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, int total, Color color, IconData icon) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      count.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$percentage%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
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

  Widget _buildRecentActivity(ListAppliedJobsProvider prov) {
    final recentApps = prov.applications.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Text(
            'RECENT ACTIVITY',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1,
            ),
          ),
        ),

        if (recentApps.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 32,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No Recent Activity',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: recentApps.asMap().entries.map((entry) {
                final index = entry.key;
                final app = entry.value;
                final isLast = index == recentApps.length - 1;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: isLast ? null : Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getStatusColor(app.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.title,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              app.company,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildMiniStatusBadge(app.status),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniStatusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  bool _hasActiveFilters() {
    return _searchController.text.isNotEmpty ||
        _selectedStatus != 'All' ||
        _selectedCompany != 'All' ||
        _appliedRange != null ||
        _createdRange != null;
  }
}