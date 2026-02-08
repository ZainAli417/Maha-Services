import 'dart:async';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_portal/Screens/Recruiter/post_a_job_form.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

import 'LIst_of_Applicants.dart';
import 'Recruiter_provider_Job_listing.dart';
import 'job_detail_dialog_recrutier.dart';

import 'package:job_portal/Screens/Recruiter/R_Top_Bar.dart';
import 'package:provider/provider.dart';
import '../Job_Seeker/job_seeker_provider.dart';

// CONSTANTS
const _primary = Color(0xFF6366F1);
const _background = Color(0xFFF8FAFC);

// MAIN DASHBOARD
class Job_Applicant_Tracker extends StatefulWidget {
  const Job_Applicant_Tracker({super.key});
  @override
  State<Job_Applicant_Tracker> createState() => _Dashboard_RecruiterState();
}

class _Dashboard_RecruiterState extends State<Job_Applicant_Tracker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
    return Scaffold(
      backgroundColor: _background,
      body: Row(
        children: [
          RecruiterSidebar(activeIndex: 1),
          Expanded(
            child: FadeTransition(
              opacity: _controller,
              child: Stack(
                children: [
                  // OPTIMIZED: Stream only job IDs, not full data
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Posted_jobs_public')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: _primary,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return _ErrorWidget(
                          error: snapshot.error.toString(),
                        );
                      }

                      // Extract only IDs - lightweight operation
                      final jobIds = snapshot.data?.docs.map((doc) => doc.id).toList() ?? [];

                      if (jobIds.isEmpty) return _EmptyWidget();

                      return Job_Applicant_Wrapper(jobIds: jobIds);
                    },
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
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 20),
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
              'Oops! Something went wrong',
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

/// OPTIMIZED: Now accepts list of job IDs instead of full job data
class Job_Applicant_Wrapper extends StatefulWidget {
  final List<String> jobIds;

  const Job_Applicant_Wrapper({
    super.key,
    required this.jobIds,
  });

  @override
  State<Job_Applicant_Wrapper> createState() => _Job_Applicant_TrackerState();
}

class _Job_Applicant_TrackerState extends State<Job_Applicant_Wrapper>
    with TickerProviderStateMixin {

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  // State - OPTIMIZED: Store only IDs
  List<String> _filteredJobIds = [];
  String _selectedCompany = '';
  String _selectedLocation = '';
  String _selectedJobType = '';
  final Set<String> _selectedBenefits = {};
  String _selectedSortOption = 'newest';
  bool _lockOuterScroll = false;
  bool _isLoading = false;

  // Cache for minimal job metadata (for filtering)
  final Map<String, Map<String, dynamic>> _jobMetadataCache = {};

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Professional color scheme - Corporate Navy
  static const Color _primary = Color(0xFF1E3A5F);
  static const Color _primaryLight = Color(0xFF2E4A6F);
  static const Color _accent = Color(0xFF3B82F6);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _error = Color(0xFFEF4444);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _background = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _filteredJobIds = List.from(widget.jobIds);
    _searchController.addListener(_onSearchChanged);
    _initializeAnimations();
    _loadJobMetadata();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void didUpdateWidget(covariant Job_Applicant_Wrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.jobIds, widget.jobIds)) {
      _loadJobMetadata();
    }
  }

  /// OPTIMIZED: Load minimal metadata for filtering only
  /// This is much lighter than loading full job data
  Future<void> _loadJobMetadata() async {
    setState(() => _isLoading = true);

    try {
      final futures = widget.jobIds.map((jobId) async {
        // Check cache first
        if (_jobMetadataCache.containsKey(jobId)) {
          return;
        }

        final doc = await FirebaseFirestore.instance
            .collection('Posted_jobs_public')
            .doc(jobId)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          // Store only fields needed for filtering/sorting
          _jobMetadataCache[jobId] = {
            'title': data['title'] ?? '',
            'company': data['company'] ?? '',
            'location': data['location'] ?? '',
            'nature': data['nature'] ?? '',
            'description': data['description'] ?? '',
            'skills': (data['skills'] as List?)?.cast<String>() ?? [],
            'benefits': (data['benefits'] as List?)?.cast<String>() ?? [],
            'timestamp': data['timestamp'],
            'applicationCount': data['applicationCount'] ?? 0,
          };
          print(data);

        }
      });

      await Future.wait(futures);
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading job metadata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _applyFilters);
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredJobIds = widget.jobIds.where((jobId) {
        final metadata = _jobMetadataCache[jobId];
        if (metadata == null) return false;

        // Search filter
        if (query.isNotEmpty) {
          final searchText = '${metadata['title']} ${metadata['company']} ${metadata['description']} ${(metadata['skills'] as List).join(' ')}'
              .toLowerCase();
          if (!searchText.contains(query)) return false;
        }

        // Company filter
        if (_selectedCompany.isNotEmpty && metadata['company'] != _selectedCompany) {
          return false;
        }

        // Location filter
        if (_selectedLocation.isNotEmpty && metadata['location'] != _selectedLocation) {
          return false;
        }

        // Job type filter
        if (_selectedJobType.isNotEmpty && metadata['nature'] != _selectedJobType) {
          return false;
        }

        // Benefits filter
        if (_selectedBenefits.isNotEmpty) {
          final benefits = (metadata['benefits'] as List).cast<String>().toSet();
          if (!_selectedBenefits.any(benefits.contains)) return false;
        }

        return true;
      }).toList();

      _sortResults();
    });
  }

  void _sortResults() {
    _filteredJobIds.sort((a, b) {
      final metadataA = _jobMetadataCache[a];
      final metadataB = _jobMetadataCache[b];

      if (metadataA == null || metadataB == null) return 0;

      switch (_selectedSortOption) {
        case 'newest':
          final timeA = (metadataA['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          final timeB = (metadataB['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          return timeB.compareTo(timeA);

        case 'oldest':
          final timeA = (metadataA['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          final timeB = (metadataB['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          return timeA.compareTo(timeB);

        case 'company':
          return (metadataA['company'] as String).compareTo(metadataB['company'] as String);

        case 'applications':
          return (metadataB['applicationCount'] as int).compareTo(metadataA['applicationCount'] as int);

        default:
          return 0;
      }
    });
  }

  List<String> _getUnique(String field) {
    final values = _jobMetadataCache.values
        .map((m) => m[field] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _jobMetadataCache.clear();
    _debounceTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: _lockOuterScroll
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildCommandBar()),
                _buildJobGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const Color kPrimaryBlue = Color(0xFF1E40AF);
    const Color kTextPrimary = Color(0xFF0F172A);
    const Color kTextSecondary = Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              Icons.track_changes_outlined,
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
                'Job Application Tracker',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                  height: 1.2,
                ),
              ),
              Text(
                'Manage & Analyze Applicants against Your Posted Jobs',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: kTextSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostJobButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const PostJobDialog(),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _accent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.add, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Post Job',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommandBar() {
    final companies = _getUnique('company');
    final locations = _getUnique('location');

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
      color: _background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: _textSecondary, size: 18),
                hintText: 'Search jobs...',
                hintStyle: GoogleFonts.poppins(
                  color: _textSecondary,
                  fontSize: 13,
                ),
                fillColor: _surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 16),

          _buildQuickStat(
            '${_filteredJobIds.length}',
            'Jobs',
            Icons.local_airport,
            _primary,
          ),
          const SizedBox(width: 16),

          _buildFilterChip(
            label: 'Company',
            value: _selectedCompany,
            options: companies,
            icon: Icons.business,
            onSelected: (v) {
              setState(() => _selectedCompany = v);
              _applyFilters();
            },
          ),
          const SizedBox(width: 12),

          _buildFilterChip(
            label: 'Location',
            value: _selectedLocation,
            options: locations,
            icon: Icons.location_on,
            onSelected: (v) {
              setState(() => _selectedLocation = v);
              _applyFilters();
            },
          ),

          const SizedBox(width: 12),

          _buildSortDropdown(),
          const SizedBox(width: 16),

          _buildPostJobButton(),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required List<String> options,
    required IconData icon,
    required Function(String) onSelected,
  }) {
    final isActive = value.isNotEmpty;

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: '',
          child: Text('All $label', style: GoogleFonts.poppins(fontSize: 13)),
        ),
        ...options.map((o) => PopupMenuItem(
          value: o,
          child: Text(o, style: GoogleFonts.poppins(fontSize: 13)),
        )),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? _primary.withOpacity(0.1) : _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _primary : _border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? _primary : _textSecondary),
            const SizedBox(width: 8),
            Text(
              isActive ? value : label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? _primary : _textSecondary,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: isActive ? _primary : _textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return PopupMenuButton<String>(
      initialValue: _selectedSortOption,
      offset: const Offset(0, 40),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 18, color: _textSecondary),
            const SizedBox(width: 8),
            Text(
              'Sort',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
        _buildSortItem('newest', 'Newest First'),
        _buildSortItem('oldest', 'Oldest First'),
        _buildSortItem('company', 'Company A-Z'),
        _buildSortItem('applications', 'Most Applications'),
      ],
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label) {
    final isSelected = _selectedSortOption == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (isSelected) Icon(Icons.check, size: 18, color: _primary),
          if (isSelected) const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? _primary : _textPrimary,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildJobGrid() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (_filteredJobIds.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: _textSecondary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No jobs found',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search or filters',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _buildPostJobButton(),
            ],
          ),
        ),
      );
    }

    // OPTIMIZED: Pass only job IDs to cards
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.4,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) => Job_Cards(
            jobId: _filteredJobIds[index],
          ),
          childCount: _filteredJobIds.length,
        ),
      ),
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

























/// Optimized Job Card that fetches data by ID
/// - Uses StreamBuilder for real-time updates
/// - Caches parsed data to prevent redundant processing
/// - Only rebuilds when job data actually changes
class Job_Cards extends StatefulWidget {
  final String jobId;

  const Job_Cards({
    super.key,
    required this.jobId,
  });

  @override
  State<Job_Cards> createState() => Job_Cards_State();
}

class Job_Cards_State extends State<Job_Cards> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Cache for parsed job data to prevent redundant parsing
  Map<String, dynamic>? _cachedJobData;
  String? _cachedDataKey;

  // Professional color scheme
  static const Color _primary = Color(0xFF1E3A5F);
  static const Color _primaryLight = Color(0xFF2E4A6F);
  static const Color _accent = Color(0xFF3B82F6);
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _error = Color(0xFFEF4444);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceElevated = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _textTertiary = Color(0xFF94A3B8);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _borderLight = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  /// Process raw Firestore data into normalized format
  /// Uses caching to prevent reprocessing unchanged data
  Map<String, dynamic> _processJobData(DocumentSnapshot doc) {
    if (!doc.exists) {
      return _getEmptyJobData();
    }

    final rawData = doc.data() as Map<String, dynamic>?;
    if (rawData == null) {
      return _getEmptyJobData();
    }

    // Create cache key based on data hash
    final timestamp = rawData['timestamp'];
    final applicationCount = rawData['applicationCount'] ?? 0;
    final cacheKey = '${doc.id}_${timestamp}_$applicationCount';

    // Return cached data if unchanged
    if (_cachedDataKey == cacheKey && _cachedJobData != null) {
      return _cachedJobData!;
    }

    // Process new data
    final processedData = {
      'id': doc.id,
      'title': rawData['title']?.toString() ?? 'Untitled Position',
      'company': rawData['company']?.toString() ?? 'Unknown Company',
      'location': rawData['location']?.toString() ?? 'Remote',
      'description': rawData['description']?.toString() ?? '',
      'salary': rawData['salary'],
      'nature': rawData['nature']?.toString() ?? 'Full-time',
      'experience': rawData['experience']?.toString() ?? 'Not specified',
      'logoUrl': rawData['logoUrl']?.toString(),
      'skills': (rawData['skills'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      'timestamp': rawData['timestamp'],
      'applicationCount': applicationCount is int
          ? applicationCount
          : (int.tryParse(applicationCount.toString()) ?? 0),
    };

    // Update cache
    _cachedDataKey = cacheKey;
    _cachedJobData = processedData;

    return processedData;
  }

  Map<String, dynamic> _getEmptyJobData() {
    return {
      'id': widget.jobId,
      'title': 'Untitled Position',
      'company': 'Unknown Company',
      'location': 'Remote',
      'description': '',
      'salary': null,
      'nature': 'Full-time',
      'experience': 'Not specified',
      'logoUrl': null,
      'skills': <String>[],
      'timestamp': null,
      'applicationCount': 0,
    };
  }

  String _getRelativeTime(Timestamp? ts) {
    if (ts == null) return '';
    return timeago.format(ts.toDate(), locale: 'en_short');
  }

  String _formatSalary(dynamic salary) {
    if (salary == null) return 'Salary not specified';
    if (salary is num) {
      return '\$${NumberFormat.compact().format(salary)}';
    }
    return salary.toString();
  }

  void _showJobDetails() {
    _scaleController.forward().then((_) => _scaleController.reverse());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
      ),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: JobDetailModal_recruiter(jobId: widget.jobId),
      ),
    );
  }

  void _showApplicants() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.6),
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Center(
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: Tween<double>(begin: 0.9, end: 1.0)
                          .animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ))
                          .value,
                      child: child,
                    );
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                      maxHeight: MediaQuery.of(context).size.height * 0.92,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Material(
                        color: _surface,
                        elevation: 24,
                        shadowColor: Colors.black.withOpacity(0.4),
                        child: Column(
                          children: [
                            // Drag Handle
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(
                                color: _textTertiary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Close Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _surfaceElevated,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _border),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(child: ApplicantsScreen(jobId: widget.jobId)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Stream job data directly from Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Posted_jobs_public')
          .doc(widget.jobId)
          .snapshots(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return _buildLoadingCard();
        }

        // Handle error state
        if (snapshot.hasError) {
          return _buildErrorCard();
        }

        // Process job data with caching
        final job = _processJobData(snapshot.data!);

        return _buildJobCard(job);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(_primary),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _error.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: _error, size: 32),
          const SizedBox(height: 8),
          Text(
            'Failed to load job',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final title = job['title'] as String;
    final company = job['company'] as String;
    final location = job['location'] as String;
    final description = job['description'] as String;
    final skills = job['skills'] as List<String>;
    final logoUrl = job['logoUrl'] as String?;
    final postedAgo = _getRelativeTime(job['timestamp'] as Timestamp?);
    final salary = _formatSalary(job['salary']);
    final nature = job['nature'] as String;
    final experience = job['experience'] as String;
    final applicationCount = job['applicationCount'] as int;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _scaleController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _scaleController.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _scaleController.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered ? _primary.withOpacity(0.3) : _borderLight,
                width: _isHovered ? 2 : 1,
              ),
              boxShadow: _isHovered
                  ? [
                BoxShadow(
                  color: _primary.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section with Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primary.withOpacity(0.03),
                          _accent.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Company Logo
                              Hero(
                                tag: 'job-logo-${job['id']}',
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _primary.withOpacity(0.1),
                                        _accent.withOpacity(0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _border,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primary.withOpacity(0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: logoUrl != null && logoUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                      imageUrl: logoUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: _surfaceElevated,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(_primary),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => _buildLogoFallback(company),
                                    )
                                        : _buildLogoFallback(company),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Title and Company Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: _textPrimary,
                                              height: 1.3,
                                              letterSpacing: -0.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            company,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Time Badge
                              if (postedAgo.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _success.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 12,
                                        color: _success,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        postedAgo,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Meta Info Row
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _buildMetaChip(
                                icon: Icons.location_on_outlined,
                                label: location,
                              ),
                              _buildMetaChip(
                                icon: Icons.work_outline,
                                label: nature,
                              ),
                              _buildMetaChip(
                                icon: Icons.attach_money,
                                label: salary,
                              ),
                              _buildMetaChip(
                                icon: Icons.trending_up,
                                label: experience,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Description Section
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _textSecondary,
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Skills Section
                  if (skills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Required Skills',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _textTertiary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills.take(6).map((skill) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _border),
                                ),
                                child: Text(
                                  skill,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (skills.length > 6)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '+${skills.length - 6} more skills',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Footer with Actions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _surfaceElevated,
                      border: Border(
                        top: BorderSide(color: _borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Applicants Count
                        Expanded(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _showApplicants,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: applicationCount > 0
                                      ? _accent.withOpacity(0.1)
                                      : _surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: applicationCount > 0
                                        ? _accent.withOpacity(0.3)
                                        : _border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      children: [
                                        Icon(
                                          Icons.group_outlined,
                                          size: 20,
                                          color: applicationCount > 0 ? _accent : _textTertiary,
                                        ),
                                        if (applicationCount > 0)
                                          Positioned(
                                            right: -2,
                                            top: -2,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: _success,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: _surface,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$applicationCount',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: applicationCount > 0 ? _accent : _textTertiary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ViewApplicants',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: applicationCount > 0 ? _accent.withOpacity(0.8) : _textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // View Details Button
                        Expanded(
                          flex: 2,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _showJobDetails,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isHovered
                                        ? [_primaryLight, _accent]
                                        : [_primary, _primaryLight],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.visibility_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'View Details',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      transform: Matrix4.translationValues(
                                        _isHovered ? 4 : 0,
                                        0,
                                        0,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildLogoFallback(String company) {
    return Container(
      color: _surfaceElevated,
      child: Center(
        child: Text(
          company.isNotEmpty ? company.substring(0, 1).toUpperCase() : 'C',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _textTertiary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}