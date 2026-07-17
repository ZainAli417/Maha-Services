import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'Job_Detail_Dialog.dart';
import 'saved_jobs_provider.dart';
import 'jobs_application_provider.dart';

void _showSideToast(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
  required Color color,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  final media = MediaQuery.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: media.padding.top + 18,
      right: 18,
      child: _SideToast(
        title: title,
        message: message,
        icon: icon,
        color: color,
        onFinished: () => entry.remove(),
      ),
    ),
  );
  overlay.insert(entry);
}

class _SideToast extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onFinished;

  const _SideToast({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.onFinished,
  });

  @override
  State<_SideToast> createState() => _SideToastState();
}

class _SideToastState extends State<_SideToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0.35, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _run();
  }

  Future<void> _run() async {
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width < 520 ? width - 32 : 360,
              minWidth: width < 520 ? width - 32 : 320,
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.color.withValues(alpha: 0.22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LiveJobsForSeeker extends StatefulWidget {
  final List<Map<String, dynamic>> jobs;
  const LiveJobsForSeeker({super.key, required this.jobs});

  @override
  State<LiveJobsForSeeker> createState() => _LiveJobsForSeekerState();
}

class _LiveJobsForSeekerState extends State<LiveJobsForSeeker>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Controllers & animations
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Timer? _debounceTimer;

  // Data
  List<Map<String, dynamic>> _filteredJobs = [];

  // Filters
  String? _selectedCompany;
  String? _selectedDepartment;
  String? _selectedLocation;
  String? _selectedJobType;
  String? _selectedExperience;
  String? _selectedSalaryType;
  String? _selectedRank;
  String? _selectedClearance;
  RangeValues _salaryRange = const RangeValues(0, 200000);
  final Set<String> _selectedBenefits = {};
  String _selectedSortOption = 'newest';

  // UI State
  bool _isSidebarCollapsed = false;
  @override
  void didUpdateWidget(covariant LiveJobsForSeeker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.jobs != widget.jobs) {
      _initializeSalaryRange();
      _applyFilters(); // 🔥 re-filter using latest jobs
    }
  }

  @override
  void initState() {
    super.initState();
    _filteredJobs = List.from(widget.jobs);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _searchController.addListener(_onSearchChanged);
    _initializeSalaryRange();
    Future.microtask(() {
      context.read<JobApplicationsProvider>().loadAppliedJobs();
    });
  }

  void _initializeSalaryRange() {
    final salaries = widget.jobs.map(_parseSalary).whereType<double>().toList();
    if (salaries.isNotEmpty) {
      final min = salaries.reduce((a, b) => a < b ? a : b);
      final max = salaries.reduce((a, b) => a > b ? a : b);
      _salaryRange = RangeValues(min, max);
    }
  }

  double? _parseSalary(Map<String, dynamic> job) {
    final s = job['salary']?.toString() ?? '';
    final m = RegExp(r'\d+(?:,\d{3})*').firstMatch(s);
    return m != null ? double.tryParse(m.group(0)!.replaceAll(',', '')) : null;
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), _applyFilters);
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredJobs = widget.jobs.where((job) {
        // Search filter
        if (query.isNotEmpty) {
          final searchText =
              '${job['title']} ${job['company']} ${job['description']} ${(job['skills'] as List?)?.join(' ') ?? ''}'
                  .toLowerCase();
          if (!searchText.contains(query)) return false;
        }

        // Dropdown filters
        if (_selectedCompany != null && job['company'] != _selectedCompany) {
          return false;
        }
        if (_selectedDepartment != null &&
            job['department'] != _selectedDepartment) {
          return false;
        }
        if (_selectedLocation != null && job['location'] != _selectedLocation) {
          return false;
        }
        if (_selectedJobType != null && job['nature'] != _selectedJobType) {
          return false;
        }
        if (_selectedExperience != null &&
            job['experience'] != _selectedExperience) {
          return false;
        }
        if (_selectedSalaryType != null &&
            job['salaryType'] != _selectedSalaryType) {
          return false;
        }
        if (_selectedRank != null && job['rankRequirement'] != _selectedRank) {
          return false;
        }
        if (_selectedClearance != null &&
            job['securityClearance'] != _selectedClearance) {
          return false;
        }

        // Salary range
        final sal = _parseSalary(job);
        if (sal != null &&
            (sal < _salaryRange.start || sal > _salaryRange.end)) {
          return false;
        }

        // Benefits
        if (_selectedBenefits.isNotEmpty) {
          final benefits =
              (job['benefits'] as List?)?.cast<String>().toSet() ?? {};
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
        _filteredJobs.sort(
          (a, b) => ((b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0))
              .compareTo(
                (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0),
              ),
        );
        break;
      case 'oldest':
        _filteredJobs.sort(
          (a, b) => ((a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0))
              .compareTo(
                (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0),
              ),
        );
        break;
      case 'company':
        _filteredJobs.sort(
          (a, b) => (a['company'] ?? '').compareTo(b['company'] ?? ''),
        );
        break;
    }
  }

  List<String> _getUnique(String field) {
    return widget.jobs
        .map((j) => j[field] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _getUniqueList(String field) {
    final all = <String>{};
    for (var j in widget.jobs) {
      (j[field] as List?)?.cast<String>().forEach(all.add);
    }
    return all.toList()..sort();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCompany = _selectedDepartment = _selectedLocation =
          _selectedJobType = _selectedExperience = _selectedSalaryType =
              _selectedRank = _selectedClearance = null;
      _selectedBenefits.clear();
      _salaryRange = const RangeValues(0, 200000);
      _selectedSortOption = 'newest';
    });
    _applyFilters();
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedCompany != null) count++;
    if (_selectedDepartment != null) count++;
    if (_selectedLocation != null) count++;
    if (_selectedJobType != null) count++;
    if (_selectedExperience != null) count++;
    if (_selectedSalaryType != null) count++;
    if (_selectedRank != null) count++;
    if (_selectedClearance != null) count++;
    if (_selectedBenefits.isNotEmpty) count++;
    return count;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 1000;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF4F9FB),
        endDrawer: isMobile
            ? Drawer(width: 340, child: _buildExpandedSidebar(isDrawer: true))
            : null,
        body: Row(
          children: [
            // Left Sidebar - Filters Panel (Desktop only)
            if (!isMobile)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isSidebarCollapsed ? 60 : 380,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Color(0xFFDCE7EF), width: 1),
                  ),
                ),
                child: _isSidebarCollapsed
                    ? _buildCollapsedSidebar()
                    : _buildExpandedSidebar(),
              ),

            // Main Content Area - A more robust layout
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. The header takes its natural height
                  _buildTopHeader(isMobile),

                  // 2. The list expands to fill the remaining space and handles its own scrolling
                  Expanded(child: _buildJobsList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedSidebar() {
    return Column(
      children: [
        // Expand button
        Container(
          height: 60,
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFDCE7EF))),
          ),
          child: IconButton(
            onPressed: () => setState(() => _isSidebarCollapsed = false),
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF14507F)),
            tooltip: 'Expand Filters',
          ),
        ),

        // Filter count indicator
        if (_activeFiltersCount > 0)
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF14507F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Icon(Icons.filter_list, color: Colors.white, size: 20),
                const SizedBox(height: 4),
                Text(
                  '$_activeFiltersCount',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedSidebar({bool isDrawer = false}) {
    return Column(
      children: [
        // Sidebar Header
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFDCE7EF)),
              top: BorderSide(color: Color(0xFFDCE7EF)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.tune_rounded, size: 22, color: Color(0xFF15A99C)),
              const SizedBox(width: 12),
              Text(
                'Filters & Search',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF14507F),
                ),
              ),
              const Spacer(),
              if (_activeFiltersCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14507F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_activeFiltersCount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (!isDrawer)
                IconButton(
                  onPressed: () => setState(() => _isSidebarCollapsed = true),
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF14507F),
                  ),
                  tooltip: 'Collapse Filters',
                )
              else
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF14507F)),
                ),
            ],
          ),
        ),

        // Scrollable Filters Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Section
                _buildSearchSection(),
                const SizedBox(height: 24),

                // Clear Filters Button
                if (_activeFiltersCount > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear All Filters'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF14507F),
                        side: const BorderSide(color: Color(0xFF14507F)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Basic Filters
                _buildFilterSection('Basic Filters', [
                  _buildDropdown(
                    'Company',
                    _selectedCompany,
                    _getUnique('company'),
                    (v) => setState(() => _selectedCompany = v),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Location',
                    _selectedLocation,
                    _getUnique('location'),
                    (v) => setState(() => _selectedLocation = v),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Job Type',
                    _selectedJobType,
                    _getUnique('nature'),
                    (v) => setState(() => _selectedJobType = v),
                  ),
                ]),

                const SizedBox(height: 24),

                // Advanced Filters
                _buildFilterSection('Advanced Filters', [
                  _buildDropdown(
                    'Department',
                    _selectedDepartment,
                    _getUnique('department'),
                    (v) => setState(() => _selectedDepartment = v),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Experience Level',
                    _selectedExperience,
                    _getUnique('experience'),
                    (v) => setState(() => _selectedExperience = v),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Salary Type',
                    _selectedSalaryType,
                    _getUnique('salaryType'),
                    (v) => setState(() => _selectedSalaryType = v),
                  ),
                ]),

                const SizedBox(height: 24),

                // Salary Range
                _buildSalaryRangeSection(),

                const SizedBox(height: 24),

                // Benefits
                _buildBenefitsSection(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(bottom: BorderSide(color: Color(0xFFDCE7EF), width: 1)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_filteredJobs.length} job${_filteredJobs.length == 1 ? '' : 's'} found',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF14507F),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      icon: Badge(
                        isLabelVisible: _activeFiltersCount > 0,
                        label: Text('$_activeFiltersCount'),
                        child: const Icon(
                          Icons.tune,
                          color: Color(0xFF14507F),
                          size: 20,
                        ),
                      ),
                      tooltip: 'Show Filters',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortDropdown(),
                      const SizedBox(width: 10),
                      _buildActiveBadge(),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  '${_filteredJobs.length} job${_filteredJobs.length == 1 ? '' : 's'} found',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF14507F),
                  ),
                ),
                const Spacer(),
                _buildActiveBadge(),
                const SizedBox(width: 16),
                _buildSortDropdown(),
              ],
            ),
    );
  }

  Widget _buildActiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${_filteredJobs.length} Active',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE7EF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF15A99C)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedSortOption,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(12),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF14507F),
            ),
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Newest First')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
              DropdownMenuItem(value: 'company', child: Text('Company A→Z')),
            ],
            onChanged: (val) {
              setState(() => _selectedSortOption = val!);
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 1000;
    final hPad = isMobile ? 12.0 : 24.0;
    final vPad = isMobile ? 12.0 : 24.0;

    if (_filteredJobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Branded gradient icon circle.
              Container(
                width: isMobile ? 76 : 96,
                height: isMobile ? 76 : 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE4F6F4), Color(0xFFE8F1F8)],
                  ),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: isMobile ? 36 : 46,
                  color: const Color(0xFF15A99C),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No jobs found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A2E4F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or search terms',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12.5 : 14,
                  color: const Color(0xFF5E7A8E),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (_activeFiltersCount > 0) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _clearFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2EC4B6,
                          ).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.clear_all_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Clear all filters',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      cacheExtent: 700,
      itemCount: _filteredJobs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 10 : 16),
          child: CompactJobCard(jobData: _filteredJobs[index]),
        );
      },
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SEARCH',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: const Color(0xFF15A99C),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Find your next role',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF14507F),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _searchFocusNode,
          builder: (context, _) {
            final focused = _searchFocusNode.hasFocus;
            return Container(
              decoration: BoxDecoration(
                color: focused ? Colors.white : const Color(0xFFF4F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: focused
                      ? const Color(0xFF2EC4B6)
                      : const Color(0xFFDCE7EF),
                  width: focused ? 1.6 : 1,
                ),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2EC4B6).withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF0B2239),
                ),
                decoration: InputDecoration(
                  hintText: 'Search jobs, companies, skills...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF8AA5B5),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: focused
                        ? const Color(0xFF15A99C)
                        : const Color(0xFF5E7A8E),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: Color(0xFF5E7A8E),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF2EC4B6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF14507F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSalaryRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Salary Range',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF14507F),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F9FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCE7EF)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${(_salaryRange.start / 1000).round()}k',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF15A99C),
                    ),
                  ),
                  Text(
                    '\$${(_salaryRange.end / 1000).round()}k',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF15A99C),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF2EC4B6),
                  inactiveTrackColor: const Color(0xFFDCE7EF),
                  thumbColor: const Color(0xFF14507F),
                  overlayColor: const Color(0xFF2EC4B6).withValues(alpha: 0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: RangeSlider(
                  values: _salaryRange,
                  min: 0,
                  max: 200000,
                  divisions: 40,
                  onChanged: (r) {
                    setState(() => _salaryRange = r);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefits',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF14507F),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _getUniqueList('benefits').map((benefit) {
            final isSelected = _selectedBenefits.contains(benefit);
            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  isSelected
                      ? _selectedBenefits.remove(benefit)
                      : _selectedBenefits.add(benefit);
                });
                _applyFilters();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2EC4B6).withValues(alpha: 0.14)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2EC4B6)
                        : const Color(0xFFDCE7EF),
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Text(
                  benefit.length > 15
                      ? '${benefit.substring(0, 15)}...'
                      : benefit,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF15A99C)
                        : const Color(0xFF3E5C76),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3E5C76),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: value != null ? const Color(0xFFE4F6F4) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: value != null
                  ? const Color(0xFF2EC4B6)
                  : const Color(0xFFDCE7EF),
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(
              'All ${label}s',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF8AA5B5),
              ),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF5E7A8E),
            ),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF14507F),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'All ${label}s',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF8AA5B5),
                  ),
                ),
              ),
              ...items.map(
                (item) => DropdownMenuItem(value: item, child: Text(item)),
              ),
            ],
            onChanged: (v) {
              onChanged(v);
              _applyFilters();
            },
          ),
        ),
      ],
    );
  }
}

/// Compact Job Card with clean, lightweight design
class CompactJobCard extends StatefulWidget {
  final Map<String, dynamic> jobData;
  const CompactJobCard({super.key, required this.jobData});

  @override
  State<CompactJobCard> createState() => _CompactJobCardState();
}

class _CompactJobCardState extends State<CompactJobCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getRelativeTime(Timestamp? ts) {
    if (ts == null) return '';
    return timeago.format(ts.toDate(), locale: 'en_short');
  }

  Future<void> _recordUniqueView(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseFirestore.instance;
    final publicJobRef = db.collection('Posted_jobs_public').doc(jobId);
    final viewRef = publicJobRef.collection('views').doc(user.uid);

    final existingView = await viewRef.get();
    if (existingView.exists) return;

    final batch = db.batch();
    batch.set(viewRef, {
      'jobId': jobId,
      'viewerUid': user.uid,
      'viewedAt': FieldValue.serverTimestamp(),
    });
    batch.update(publicJobRef, {'viewCount': FieldValue.increment(1)});

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('record job view failed: $e');
    }
  }

  void _showDetails() {
    HapticFeedback.lightImpact();

    final jobId = widget.jobData['id'] as String;
    _recordUniqueView(jobId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobDetailModal(jobId: widget.jobData['id']),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.jobData;
    final isActive = (job['status'] as String? ?? 'active') == 'active';
    final title = job['title'] as String? ?? 'No Title';
    final department = job['department'] as String? ?? 'N/A';
    final company = job['company'] as String? ?? 'Unknown Company';
    final location = job['location'] as String? ?? 'Unknown Location';
    final description = job['description'] as String? ?? '';
    final responsibilities = job['responsibilities'] as String? ?? '';
    final skills = (job['skills'] as List<dynamic>?)?.cast<String>() ?? [];
    final logoUrl = job['logoUrl'] as String?;
    final nature = job['nature'] as String? ?? '';
    final salary = job['salary'] as String? ?? '';
    final experience = job['experience'] as String? ?? '';
    final postedAgo = _getRelativeTime(job['timestamp'] as Timestamp?);
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 1000;
    final cardPad = isMobile ? 10.0 : 16.0;
    final titleSize = isMobile ? 15.0 : 17.0;
    final subSize = isMobile ? 11.0 : 13.0;
    final logoSize = isMobile ? 38.0 : 50.0;

    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: _showDetails,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(maxWidth: 800),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
            decoration: BoxDecoration(
              // Muted (color, not Opacity) treatment for inactive jobs so
              // no saveLayer is created while the list scrolls.
              color: isActive ? Colors.white : const Color(0xFFF4F9FB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isHovered
                    ? const Color(0xFF2EC4B6)
                    : const Color(0xFFDCE7EF),
                width: _isHovered ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? const Color(0xFF2EC4B6).withValues(alpha: 0.22)
                      : const Color(0xFF0B2239).withValues(alpha: 0.05),
                  blurRadius: _isHovered ? 22 : 16,
                  offset: Offset(0, _isHovered ? 12 : 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(cardPad),
                    decoration: const BoxDecoration(color: Color(0xFFF4F9FB)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company logo tile (rounded-square, brand-tinted).
                        Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              isMobile ? 10 : 12,
                            ),
                            border: Border.all(color: const Color(0xFFDCE7EF)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0B2239,
                                ).withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: logoUrl != null && logoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 9 : 11,
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: logoUrl,
                                    fit: BoxFit.cover,
                                    // Decode small — these are ~50px logos in
                                    // a scrolling list; caps raster cost.
                                    memCacheWidth: 120,
                                    memCacheHeight: 120,
                                  ),
                                )
                              : Icon(
                                  Icons.business_center_rounded,
                                  color: const Color(0xFF2178B5),
                                  size: isMobile ? 18 : 24,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF14507F),
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Company + department (muted row, brand icon).
                              Row(
                                children: [
                                  const Icon(
                                    Icons.apartment_rounded,
                                    size: 13,
                                    color: Color(0xFF15A99C),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '$company  •  $department',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: subSize,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF5E7A8E),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              // Location (muted row, brand icon).
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: Color(0xFF8AA5B5),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: isMobile ? 10 : 12,
                                        color: const Color(0xFF5E7A8E),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              // const SizedBox(height: 4),
                              // Row(
                              //   children: [
                              //     const Icon(Icons.visibility_outlined,
                              //         size: 12, color: Color(0xFF64748B)),
                              //     const SizedBox(width: 3),
                              //     Text('${job['viewCount'] ?? 0} views',
                              //         style: GoogleFonts.plusJakartaSans(
                              //             fontSize: 10,
                              //             color: const Color(0xFF64748B))),
                              //     const SizedBox(width: 10),
                              //     const Icon(Icons.people_outline,
                              //         size: 12, color: Color(0xFF64748B)),
                              //     const SizedBox(width: 3),
                              //     Text('${job['applicationCount'] ?? 0} apps',
                              //         style: GoogleFonts.plusJakartaSans(
                              //             fontSize: 10,
                              //             color: const Color(0xFF64748B))),
                              //   ],
                              // ),
                            ],
                          ),
                        ),
                        if (postedAgo.isNotEmpty && !isMobile)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF14507F,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(
                                  0xFF14507F,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 11,
                                  color: Color(0xFF14507F),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$postedAgo ago',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF14507F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 6),
                        Consumer<SavedJobsProvider>(
                          builder: (context, savedProvider, _) {
                            final jobId =
                                widget.jobData['id']?.toString() ?? '';
                            final isSaved = savedProvider.isSaved(jobId);
                            return Tooltip(
                              message: isSaved
                                  ? 'Remove saved job'
                                  : 'Save job',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () async {
                                    try {
                                      await savedProvider.toggleSaved(
                                        widget.jobData,
                                      );
                                      if (!mounted) return;
                                      _showSideToast(
                                        context,
                                        title: isSaved
                                            ? 'Removed from saved jobs'
                                            : 'Saved job',
                                        message: isSaved
                                            ? 'This job was removed from your list.'
                                            : 'You can revisit it from Saved Jobs.',
                                        icon: isSaved
                                            ? Icons.bookmark_remove_outlined
                                            : Icons.bookmark_added_rounded,
                                        color: isSaved
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF14507F),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      _showSideToast(
                                        context,
                                        title: 'Could not update saved job',
                                        message: e.toString(),
                                        icon: Icons.error_outline_rounded,
                                        color: Colors.redAccent,
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isSaved
                                          ? const Color(
                                              0xFF14507F,
                                            ).withValues(alpha: 0.12)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSaved
                                            ? const Color(0xFF14507F)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Icon(
                                      isSaved
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      size: 18,
                                      color: isSaved
                                          ? const Color(0xFF14507F)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(cardPad + 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Color-coded meta pills: employment type, salary,
                        // experience — brand palette, wraps on mobile.
                        if (nature.isNotEmpty ||
                            salary.isNotEmpty ||
                            experience.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (nature.isNotEmpty)
                                _ModernChip(
                                  text: nature,
                                  color: _brandTagColor(nature),
                                  icon: Icons.work_outline_rounded,
                                ),
                              if (salary.isNotEmpty)
                                _ModernChip(
                                  text: salary,
                                  color: const Color(0xFF15A99C),
                                  icon: Icons.payments_outlined,
                                ),
                              if (experience.isNotEmpty && !isMobile)
                                _ModernChip(
                                  text: experience,
                                  color: const Color(0xFF2178B5),
                                  icon: Icons.timeline_rounded,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (description.isNotEmpty)
                          _buildDetailSection(
                            'Job Description',
                            Icons.description_outlined,
                            Text(
                              description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isMobile ? 12.5 : 14,
                                color: const Color(0xFF3E5C76),
                                height: 1.5,
                              ),
                              maxLines: isMobile ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        if (responsibilities.isNotEmpty && !isMobile)
                          _buildDetailSection(
                            'Key Responsibilities',
                            Icons.checklist_rounded,
                            Text(
                              responsibilities,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF3E5C76),
                                height: 1.5,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        const SizedBox(height: 5),
                        if (skills.isNotEmpty) ...[
                          Text(
                            'SKILLS REQUIRED',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: const Color(0xFF15A99C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: skills
                                    .take(isMobile ? 3 : 4)
                                    .map((skill) {
                                      return _ModernChip(
                                        text: skill,
                                        color: const Color(0xFF2178B5),
                                      );
                                    })
                                    .toList(),
                              ),
                              if (skills.length > (isMobile ? 3 : 4))
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '+${skills.length - (isMobile ? 3 : 4)} more',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: const Color(0xFF5E7A8E),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 15),
                        Consumer<JobApplicationsProvider>(
                          builder: (ctx, appProv, _) {
                            // 1) Show SnackBar on any new error...
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              if (appProv.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(appProv.errorMessage!),
                                  ),
                                );
                                appProv.clearError();
                              }
                            });

                            // 2) Now build your two-button Row exactly as before:
                            return Row(
                              children: [
                                // 1. View Details button
                                // Secondary / ghost button — white, navy
                                // border, navy label.
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showDetails,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: isMobile ? 10 : 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF14507F),
                                          width: 1.4,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'View Details',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: isMobile ? 13 : 15,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF14507F),
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 11,
                                            color: Color(0xFF14507F),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // 2. Apply Now button
                                Expanded(
                                  child: () {
                                    final jobId =
                                        widget.jobData['id'] as String;
                                    final already = appProv.hasApplied(jobId);
                                    final loading = appProv.isApplyingTo(jobId);
                                    return GestureDetector(
                                      onTap: (already || loading)
                                          ? null
                                          : () => _applyForJob(),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isMobile ? 10 : 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: already
                                                ? const [
                                                    Color(0xFFE8F1F8),
                                                    Color(0xFFE4F6F4),
                                                  ]
                                                : const [
                                                    Color(0xFF2EC4B6),
                                                    Color(0xFF14507F),
                                                  ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: already
                                              ? Border.all(
                                                  color: const Color(
                                                    0xFFDCE7EF,
                                                  ),
                                                )
                                              : null,
                                          boxShadow: already
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF2EC4B6,
                                                    ).withValues(alpha: 0.35),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                        ),
                                        child: loading
                                            ? const Center(
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                          Colors.white,
                                                        ),
                                                  ),
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    already
                                                        ? Icons
                                                              .check_circle_rounded
                                                        : Icons.send_rounded,
                                                    size: isMobile ? 14 : 18,
                                                    color: already
                                                        ? const Color(
                                                            0xFF15A99C,
                                                          )
                                                        : Colors.white,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      already
                                                          ? 'Applied'
                                                          : 'Apply Now',
                                                      style:
                                                          GoogleFonts.plusJakartaSans(
                                                            fontSize: isMobile
                                                                ? 12
                                                                : 15,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: already
                                                                ? const Color(
                                                                    0xFF15A99C,
                                                                  )
                                                                : Colors.white,
                                                          ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    );
                                  }(),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _applyForJob() async {
    final provider = context.read<JobApplicationsProvider>();
    final jobId = widget.jobData['id'] as String;

    // Trigger light haptic
    HapticFeedback.mediumImpact();

    // Call & wait
    await provider.applyForJob(jobId);

    // If there was an error, show it and return
    if (provider.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Success → show dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success image
              SvgPicture.asset('images/applied.svg', width: 200, height: 200),
              const SizedBox(height: 16),

              // Title
              Text(
                'Application Submitted!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0A2E4F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Your profile has been shared with the recruiter.\nOnly shortlisted candidates will be notified for an interview session.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF3E5C76),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // OK button (brand gradient primary)
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2EC4B6).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'OK',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDetailSection(String title, IconData icon, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EC4B6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: const Color(0xFF15A99C)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF14507F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}

/// Maps an employment-type / status label to a brand accent color so tags
/// read as navy / teal / blue / amber (never indigo).
Color _brandTagColor(String value) {
  final t = value.toLowerCase();
  if (t.contains('full')) return const Color(0xFF15A99C); // teal deep
  if (t.contains('part')) return const Color(0xFF2178B5); // blue
  if (t.contains('contract') || t.contains('temp')) {
    return const Color(0xFFFFB020); // amber
  }
  if (t.contains('intern')) return const Color(0xFFFF7A59); // coral
  if (t.contains('remote')) return const Color(0xFF2EC4B6); // teal
  return const Color(0xFF14507F); // navy default
}

/// Brand pill: tinted background + accent border + accent w700 label.
/// Optional [icon] renders a small leading glyph in the accent color.
class _ModernChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _ModernChip({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: icon != null ? 10 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
