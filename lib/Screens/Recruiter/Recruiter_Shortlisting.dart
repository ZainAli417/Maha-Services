import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_portal/Screens/Recruiter/R_Top_Bar.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../Job_Seeker/job_seeker_provider.dart';
import 'View_Shortlisted.dart';

// PROFESSIONAL COLOR SCHEME
const _primary = Color(0xFF2563EB);
const _primaryLight = Color(0xFFDEEBFF);
const _accent = Color(0xFF0EA5E9);
const _background = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _textPrimary = Color(0xFF0F172A);
const _textSecondary = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _success = Color(0xFF10B981);
const _warning = Color(0xFFF59E0B);

// MAIN DASHBOARD
class Shortlisting extends StatefulWidget {
  const Shortlisting({super.key});
  @override
  State<Shortlisting> createState() => _ShortlistingState();
}

class _ShortlistingState extends State<Shortlisting>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _background,
      drawer: isMobile
          ? Drawer(
              child: RecruiterSidebar(activeIndex: 2, isDrawer: true),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) RecruiterSidebar(activeIndex: 2),
          Expanded(
            child: FadeTransition(
              opacity: _controller,
              child: Column(
                children: [
                  if (isMobile)
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu_rounded, size: 24),
                            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.star_rounded, size: 20, color: _primary),
                          ),
                          const SizedBox(width: 10),
                          Text('Shortlisting',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Consumer<JobSeekerProvider>(
                      builder: (context, provider, _) =>
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: provider.allJobsStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
                                );
                              }
                              if (snapshot.hasError) {
                                return _ErrorWidget(error: snapshot.error.toString());
                              }
                              final jobs = snapshot.data ?? [];
                              if (jobs.isEmpty) return _EmptyWidget();
                              return ShortlistingDashboard(jobs: jobs);
                            },
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

// MAIN SHORTLISTING DASHBOARD
class ShortlistingDashboard extends StatefulWidget {
  final List<Map<String, dynamic>> jobs;
  const ShortlistingDashboard({super.key, required this.jobs});

  @override
  State<ShortlistingDashboard> createState() => _ShortlistingDashboardState();
}

class _ShortlistingDashboardState extends State<ShortlistingDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _filteredJobs = [];
  String? _selectedJobId;
  String _selectedCompany = '';
  String _selectedLocation = '';
  String _selectedJobType = '';
  String _selectedSortOption = 'newest';

  @override
  void initState() {
    super.initState();
    _filteredJobs = List.from(widget.jobs);
    _applyFilters();
    if (_filteredJobs.isNotEmpty) {
      _selectedJobId = _filteredJobs.first['id'] as String?;
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant ShortlistingDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.jobs, widget.jobs)) {
      _applyFilters();
      if (_selectedJobId == null && _filteredJobs.isNotEmpty) {
        setState(() {
          _selectedJobId = _filteredJobs.first['id'] as String?;
        });
      }
    }
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
          final searchText =
              '${job['title']} ${job['company']} ${job['description']} ${(job['skills'] as List?)?.join(' ') ?? ''}'
                  .toLowerCase();
          if (!searchText.contains(query)) return false;
        }
        if (_selectedCompany.isNotEmpty && job['company'] != _selectedCompany)
          return false;
        if (_selectedLocation.isNotEmpty &&
            job['location'] != _selectedLocation)
          return false;
        if (_selectedJobType.isNotEmpty && job['nature'] != _selectedJobType)
          return false;
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

  List<String> _getUnique(String field) =>
      widget.jobs
          .map((j) => j[field] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const Color kPrimaryBlue = Color(0xFF1E40AF);
    const Color kTextPrimary = Color(0xFF0F172A);
    const Color kTextSecondary = Color(0xFF475569);
    const Color kBorderLight = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Icons.recent_actors_outlined,
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
                'Shortlisting Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                  height: 1.2,
                ),
              ),
              Text(
                'Review & Manage Shortlisted candidates',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: kTextSecondary,
                  height: 1.2,
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              height: 44,
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(fontSize: 14, color: _textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _textSecondary,
                    size: 20,
                  ),
                  hintText: 'Search positions, companies, skills...',
                  hintStyle: GoogleFonts.poppins(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: _background,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterDropdown(
            'Company',
            _selectedCompany,
            companies,
            Icons.business_rounded,
            (v) => setState(() => _selectedCompany = v),
          ),
          const SizedBox(width: 10),
          _buildFilterDropdown(
            'Location',
            _selectedLocation,
            locations,
            Icons.location_on_rounded,
            (v) => setState(() => _selectedLocation = v),
          ),
          const SizedBox(width: 10),
          _buildFilterDropdown(
            'Type',
            _selectedJobType,
            types,
            Icons.work_outline_rounded,
            (v) => setState(() => _selectedJobType = v),
          ),
          const SizedBox(width: 10),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    IconData icon,
    Function(String) onChanged,
  ) {
    if (items.isEmpty) return const SizedBox();
    return Container(
      height: 44,
      child: PopupMenuButton<String>(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: value.isNotEmpty ? _primaryLight : _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value.isNotEmpty ? _primary : _border,
              width: value.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: value.isNotEmpty ? _primary : _textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                value.isEmpty ? label : value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: value.isNotEmpty ? _primary : _textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: value.isNotEmpty ? _primary : _textSecondary,
              ),
            ],
          ),
        ),
        onSelected: (v) {
          setState(() => onChanged(v));
          _applyFilters();
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: '',
            child: Text('All', style: GoogleFonts.poppins(fontSize: 13)),
          ),
          ...items.map(
            (i) => PopupMenuItem<String>(
              value: i,
              child: Text(i, style: GoogleFonts.poppins(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return Container(
      height: 44,
      child: PopupMenuButton<String>(
        initialValue: _selectedSortOption,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort_rounded, size: 18, color: _textSecondary),
              const SizedBox(width: 8),
              Text(
                'Sort',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
        onSelected: (val) {
          setState(() => _selectedSortOption = val);
          _applyFilters();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'newest',
            child: Text('Newest First', style: GoogleFonts.poppins(fontSize: 13)),
          ),
          PopupMenuItem(
            value: 'oldest',
            child: Text('Oldest First', style: GoogleFonts.poppins(fontSize: 13)),
          ),
          PopupMenuItem(
            value: 'company',
            child: Text('Company A→Z', style: GoogleFonts.poppins(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 60,
                color: _primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No positions found',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search filters',
              style: GoogleFonts.poppins(fontSize: 15, color: _textSecondary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: Job Cards List
          SizedBox(
            width: 380,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.work_outline_rounded,
                        size: 20,
                        color: _textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Positions (${_filteredJobs.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: _filteredJobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final job = _filteredJobs[index];
                      final jobId = job['id'] as String?;
                      final isSelected = jobId == _selectedJobId;
                      return JobCard(
                        jobData: job,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedJobId = jobId),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // RIGHT: Applicants View
          Expanded(
            child: _selectedJobId != null
                ? view_shortlisted(
                    key: ValueKey(_selectedJobId),
                    jobId: _selectedJobId,
                  )
                : _EmptyApplicantsView(),
          ),
        ],
      ),
    );
  }
}

// PROFESSIONAL JOB CARD

class JobCard extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final bool isSelected;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.jobData,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isHovered = false;

  String _getRelativeTime(Timestamp? ts) {
    if (ts == null) return '';
    return timeago.format(ts.toDate(), locale: 'en_short');
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.jobData;
    final title = job['title'] as String? ?? 'No Title';
    final company = job['company'] as String? ?? 'Unknown Company';
    final location = job['location'] as String? ?? 'Remote';
    final skills = (job['skills'] as List<dynamic>?)?.cast<String>() ?? [];
    final logoUrl = job['logoUrl'] as String?;
    final postedAgo = _getRelativeTime(job['timestamp'] as Timestamp?);

    // UX: Define animation curve for smoother interactions
    const animationDuration = Duration(milliseconds: 200);
    const animationCurve = Curves.easeOutCubic;
    const Color _primary = Color(0xFF2563EB);
    const Color _primaryLight = Color(0xFFEFF6FF);
    const Color _surface = Colors.white;
    const Color _background = Color(0xFFF8FAFC);
    const Color _border = Color(0xFFE2E8F0);
    const Color _textPrimary = Color(0xFF1E293B);
    const Color _textSecondary = Color(0xFF64748B);
    const Color _accent = Color(0xFF3B82F6);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: animationDuration,
          curve: animationCurve,
          // UX: Physically lift the card on hover for tactile feedback
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered && !widget.isSelected ? -4.0 : 0.0),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSelected ? _primary.withOpacity(0.04) : _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? _primary
                  : _isHovered
                  ? _primary.withOpacity(0.3)
                  : _border,
              width: widget.isSelected ? 2 : 1,
            ),

          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header Section: Logo + Title + Date ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(logoUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (postedAgo.isNotEmpty)
                              _buildTimeBadge(postedAgo),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- Middle Section: Location & Attributes ---
              Row(
                children: [
                  _buildIconText(Icons.location_on_outlined, location),
                  const SizedBox(width: 16),
                  // Example of adding a second attribute like "Full-time"
                  _buildIconText(Icons.work_outline_rounded, "Full-time"),
                ],
              ),

              if (skills.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: _border, thickness: 0.5),
                const SizedBox(height: 12),

                // --- Footer Section: Skills & Selected Indicator ---
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.take(3).map((skill) => _buildSkillChip(skill)).toList(),
                      ),
                    ),
                    if (widget.isSelected) ...[
                      const SizedBox(width: 8),
                      _buildSelectedIndicator(),
                    ]
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLogo(String? logoUrl) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: logoUrl != null && logoUrl.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: logoUrl,
          fit: BoxFit.contain, // Contain usually looks better for logos so they don't get cropped
          placeholder: (_, __) => Padding(
            padding: const EdgeInsets.all(12.0),
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          ),
          errorWidget: (_, __, ___) => Icon(Icons.business, color: _textSecondary),
        )
            : Icon(Icons.business, color: _textSecondary),
      ),
    );
  }

  Widget _buildTimeBadge(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        time,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _textSecondary,
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        // Removed border for a cleaner, modern "pill" look
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _primary,
        ),
      ),
    );
  }

  Widget _buildSelectedIndicator() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.check,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}
// EMPTY APPLICANTS VIEW
class _EmptyApplicantsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryLight, _primary.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_alt_rounded, size: 80, color: _primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Select a Job Position',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click on any job card to view applicants',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
            ),
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
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Positions Available',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
