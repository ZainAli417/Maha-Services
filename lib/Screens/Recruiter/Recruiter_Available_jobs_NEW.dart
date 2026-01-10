import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_portal/Screens/Recruiter/post_a_job_form.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'LIst_of_Applicants.dart';
import 'job_detail_dialog_recrutier.dart';

// Background pattern painter

class JobListView_New extends StatefulWidget {
  final List<Map<String, dynamic>> jobs;
  const JobListView_New({super.key, required this.jobs});

  @override
  State<JobListView_New> createState() => _JobListView_NewState();
}

class _JobListView_NewState extends State<JobListView_New> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _filteredJobs = [];
  String _selectedCompany = '', _selectedDepartment = '', _selectedLocation = '', _selectedJobType = '';
  RangeValues _salaryRange = const RangeValues(0, 200000);
  final Set<String> _selectedBenefits = {};
  String _selectedSortOption = 'newest';

  // Professional color palette with accents
  static const _primary = Color(0xFF6366F1); // Indigo
  static const _accent = Color(0xFFEC4899); // Pink
  static const _secondary = Color(0xFF8B5CF6); // Purple
  static const _background = Color(0xFFF8FAFC);
  static const _surface = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _filteredJobs = List.from(widget.jobs);
    _searchController.addListener(_onSearchChanged);
    _initializeSalaryRange();
  }

  // <-- ADD THIS METHOD
  @override
  void didUpdateWidget(covariant JobListView_New oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.jobs, widget.jobs)) {
      _initializeSalaryRange();
      _applyFilters();
    }
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
    _debounceTimer = Timer(const Duration(milliseconds: 300), _applyFilters);
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredJobs = widget.jobs.where((job) {
        if (query.isNotEmpty) {
          final searchText = '${job['title']} ${job['company']} ${job['description']} ${(job['skills'] as List?)?.join(' ') ?? ''}'.toLowerCase();
          if (!searchText.contains(query)) return false;
        }
        if (_selectedCompany.isNotEmpty && job['company'] != _selectedCompany) return false;
        if (_selectedDepartment.isNotEmpty && job['department'] != _selectedDepartment) return false;
        if (_selectedLocation.isNotEmpty && job['location'] != _selectedLocation) return false;
        if (_selectedJobType.isNotEmpty && job['nature'] != _selectedJobType) return false;

        final sal = _parseSalary(job);
        if (sal != null && (sal < _salaryRange.start || sal > _salaryRange.end)) return false;

        if (_selectedBenefits.isNotEmpty) {
          final benefits = (job['benefits'] as List?)?.cast<String>().toSet() ?? {};
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
        _filteredJobs.sort((a, b) => ((b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0)).compareTo((a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0)));
        break;
      case 'oldest':
        _filteredJobs.sort((a, b) => ((a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0)).compareTo((b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0)));
        break;
      case 'company':
        _filteredJobs.sort((a, b) => (a['company'] ?? '').compareTo(b['company'] ?? ''));
        break;
    }
  }

  List<String> _getUnique(String field) {
    return widget.jobs.map((j) => j[field] as String? ?? '').where((s) => s.isNotEmpty).toSet().toList()..sort();
  }

  List<String> _getUniqueList(String field) {
    final all = <String>{};
    for (var j in widget.jobs) {
      (j[field] as List?)?.cast<String>().forEach(all.add);
    }
    return all.toList()..sort();
  }
  void _clearFilters() {
    HapticFeedback.mediumImpact();
    setState(() {
      _searchController.clear();
      _selectedCompany = _selectedDepartment = _selectedLocation = _selectedJobType = '';
      _selectedBenefits.clear();
      _initializeSalaryRange();
      _selectedSortOption = 'newest';
    });
    _applyFilters();
  }

  void _showBenefitsFilter() {
    final benefits = _getUniqueList('benefits');
    if (benefits.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        final tempSelected = Set<String>.from(_selectedBenefits);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.card_giftcard, color: _primary, size: 24),
                        const SizedBox(width: 12),
                        Text('Select Benefits', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: benefits.length,
                        itemBuilder: (context, index) {
                          final benefit = benefits[index];
                          final isSelected = tempSelected.contains(benefit);
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(benefit, style: GoogleFonts.poppins(fontSize: 14, color: _textPrimary)),
                            activeColor: _primary,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  tempSelected.add(benefit);
                                } else {
                                  tempSelected.remove(benefit);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setDialogState(() => tempSelected.clear());
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Clear', style: GoogleFonts.poppins(color: _textSecondary, fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedBenefits.clear();
                                _selectedBenefits.addAll(tempSelected);
                              });
                              _applyFilters();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Subtle background pattern

          Column(
            children: [
              _buildHeader(),
              _buildFilters(),
              Expanded(child: _buildJobList()),
            ],
          ),
        ],
      ),
    );
  }

// Compact header with Post Job button
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, _secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.work_outline, color: Colors.white, size: 22),
          ),

          const SizedBox(width: 14),

          // Title block (bounded width, NOT Expanded)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Recruiter Dashboard',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_accent, _warning]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Pro',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Discover and manage candidates',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Push remaining content to the right
          const Spacer(),

          // Stats
          _buildStatPill('${_filteredJobs.length}', 'Jobs', Icons.rocket_launch, _primary),
          const SizedBox(width: 10),
          _buildStatPill('${_getUnique('company').length}', 'Companies', Icons.apartment, _secondary),

          const SizedBox(width: 16),

          // Post Job button (now always visible)
          _buildPostJobButton(),
        ],
      ),
    );
  }
  Widget _buildPostJobButton() {
    return  Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10), // 👈 ripple clipping
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => PostJobDialog(),
                );              },
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(10), // 👈 rounded edges
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Post A Job',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),


    );
  }


// Compact grid
  Widget _buildStatPill(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary)),
              Text(label, style: GoogleFonts.poppins(fontSize: 10, color: _textSecondary, fontWeight: FontWeight.w500)),
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
      color: _surface,
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: _textSecondary,
                      size: 20,
                    ),
                    hintText: 'Search jobs, companies, skills...',
                    hintStyle: GoogleFonts.poppins(
                      color: _textSecondary,
                      fontSize: 14,
                    ),
                    // ✅ outlined border (no fill)
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _textSecondary.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Color(0xFF6366F1),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.close, size: 18, color: _textSecondary),
                      onPressed: () => _searchController.clear(),
                    )
                        : null,
                    filled: false, // ✅ no background fill
                  ),
                ),
              ),

              const SizedBox(width: 12),
              _buildFilterDropdown('Company', _selectedCompany, companies, Icons.business, (v) => setState(() => _selectedCompany = v)),
              const SizedBox(width: 8),
              _buildFilterDropdown('Location', _selectedLocation, locations, Icons.location_on, (v) => setState(() => _selectedLocation = v)),
              const SizedBox(width: 8),
              _buildFilterDropdown('Type', _selectedJobType, types, Icons.work, (v) => setState(() => _selectedJobType = v)),
              const SizedBox(width: 8),
              _buildBenefitsButton(),
              const SizedBox(width: 12),
              _buildSortButton(),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearFilters,
                icon: Icon(Icons.refresh, color: _textSecondary),
                tooltip: 'Clear Filters',
              ),
            ],
          ),
          if (_selectedBenefits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedBenefits.map((b) => Chip(
                label: Text(b, style: GoogleFonts.poppins(fontSize: 12, color: _primary)),
                deleteIcon: Icon(Icons.close, size: 16, color: _primary),
                onDeleted: () {
                  setState(() => _selectedBenefits.remove(b));
                  _applyFilters();
                },
                backgroundColor: _primary.withOpacity(0.1),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildFilterDropdown(String label, String value, List<String> items, IconData icon, Function(String) onChanged) {
    if (items.isEmpty) return const SizedBox();

    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value.isNotEmpty ? _primary.withOpacity(0.1) : _background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: value.isNotEmpty ? _primary : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: value.isNotEmpty ? _primary : _textSecondary),
            const SizedBox(width: 6),
            Text(
              value.isEmpty ? label : value,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: value.isNotEmpty ? _primary : _textSecondary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: value.isNotEmpty ? _primary : _textSecondary),
          ],
        ),
      ),
      onSelected: (v) {
        setState(() {
          onChanged(v);
        });
        _applyFilters();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: '',
          child: Row(
            children: [
              if (value.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.check, size: 16, color: _primary),
                ),
              Text('All', style: GoogleFonts.poppins(fontSize: 13, fontWeight: value.isEmpty ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
        ...items.map((i) => PopupMenuItem<String>(
          value: i,
          child: Row(
            children: [
              if (value == i)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.check, size: 16, color: _primary),
                ),
              Text(i, style: GoogleFonts.poppins(fontSize: 13, fontWeight: value == i ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildBenefitsButton() {
    return InkWell(
      onTap: _showBenefitsFilter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _selectedBenefits.isNotEmpty ? _primary.withOpacity(0.1) : _background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _selectedBenefits.isNotEmpty ? _primary : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, size: 16, color: _selectedBenefits.isNotEmpty ? _primary : _textSecondary),
            const SizedBox(width: 6),
            Text(
              _selectedBenefits.isEmpty ? 'Benefits' : 'Benefits (${_selectedBenefits.length})',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _selectedBenefits.isNotEmpty ? _primary : _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      initialValue: _selectedSortOption,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 16, color: _textSecondary),
            const SizedBox(width: 6),
            Text('Sort', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: _textSecondary)),
          ],
        ),
      ),
      onSelected: (val) {
        setState(() => _selectedSortOption = val);
        _applyFilters();
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'newest', child: Text('Newest First', style: GoogleFonts.poppins(fontSize: 13))),
        PopupMenuItem(value: 'oldest', child: Text('Oldest First', style: GoogleFonts.poppins(fontSize: 13))),
        PopupMenuItem(value: 'company', child: Text('Company A→Z', style: GoogleFonts.poppins(fontSize: 13))),
      ],
    );
  }

  Widget _buildJobList() {
    if (_filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primary.withOpacity(0.1), _accent.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(Icons.search_off_rounded, size: 64, color: _textSecondary.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text('No jobs found', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Try adjusting your filters or search terms', style: GoogleFonts.poppins(fontSize: 15, color: _textSecondary)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 2.2, // Adjust this for card height (1.2 = taller, 1.8 = shorter)
      ),
      itemCount: _filteredJobs.length,
      itemBuilder: (context, index) => JobCard(jobData: _filteredJobs[index]),
    );
  }
}

class JobCard extends StatefulWidget {
  final Map<String, dynamic> jobData;
  const JobCard({super.key, required this.jobData});

  @override
  State<JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<JobCard> {
  bool _isHovered = false;

  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFF3B82F6);
  static const _accent = Color(0xFF8B5CF6);
  static const _secondary = Color(0xFF64748B);
  static const _surface = Color(0xFFFFFFFF);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);

  String _getRelativeTime(Timestamp? ts) {
    if (ts == null) return '';
    return timeago.format(ts.toDate(), locale: 'en_short');
  }

  void _showJobDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: JobDetailModal_recruiter(jobData: widget.jobData),
      ),
    );
  }

  void _showApplicants() {
    final mq = MediaQuery.of(context);
    final maxH = mq.size.height * 0.95;
    final maxW = mq.size.width * 0.8;
    final jobId = widget.jobData['id'] as String?; // Get job ID from jobData
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.55),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, anim, secondaryAnim) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxW,
                  maxHeight: maxH,
                  minHeight: maxH * 0.6,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Theme.of(context).cardColor,
                    elevation: 18,
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: Stack(
                        children: [
                          // --- Main Content ---
                          Scaffold(
                            backgroundColor: Theme.of(context).cardColor,
                            body: Column(
                              children: [
                                // Handle (optional visual cue)
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Container(
                                    width: 56,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                // Applicants Screen
                                Expanded(child: ApplicantsScreen(jobId: jobId)),
                              ],
                            ),
                          ),

                          // --- Close Button (Top-right corner) ---
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 22,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          final curved = Curves.easeOutCubic.transform(anim.value);
          return Opacity(
            opacity: anim.value,
            child: Transform.translate(
              offset: Offset(0, 40 * (1 - curved)),
              child: Transform.scale(
                scale: 0.98 + 0.02 * curved,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final job = widget.jobData;
    final title = job['title'] as String? ?? 'No Title';
    final company = job['company'] as String? ?? 'Unknown Company';
    final location = job['location'] as String? ?? 'Unknown Location';
    final description = job['description'] as String? ?? '';
    final skills = (job['skills'] as List<dynamic>?)?.cast<String>() ?? [];
    final logoUrl = job['logoUrl'] as String?;
    final postedAgo = _getRelativeTime(job['timestamp'] as Timestamp?);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? _primary.withOpacity(0.4) : _border,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered
              ? [
            BoxShadow(
              color: _primary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Subtle pattern
              Positioned.fill(
                child: CustomPaint(
                  painter: _PatternPainter(isHovered: _isHovered),
                ),
              ),
              // Content with proper constraints
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Compact Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Smaller logo
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_primary.withOpacity(0.08), _accent.withOpacity(0.08)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border, width: 1),
                          ),
                          child: logoUrl != null && logoUrl.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation(_primary),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.business_rounded,
                                color: _primary,
                                size: 22,
                              ),
                            ),
                          )
                              : Icon(Icons.business_rounded, color: _primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        // Title and meta - with flex to prevent overflow
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.apartment_rounded, size: 13, color: _textSecondary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      company,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _textSecondary,
                                        height: 1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 13, color: _textSecondary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      location,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _textSecondary,
                                        height: 1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Time badge - compact
                        if (postedAgo.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _success.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule_rounded, size: 11, color: _success),
                                const SizedBox(width: 4),
                                Text(
                                  postedAgo,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _success,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Description - compact
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Skills - more compact
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: skills.take(4).map((skill) {
                          final index = skills.indexOf(skill);
                          final colors = [
                            [_primary, _primaryLight],
                            [_accent, Color(0xFF9333EA)],
                            [_success, Color(0xFF059669)],
                            [_warning, Color(0xFFD97706)],
                          ];
                          final colorPair = colors[index % colors.length];

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorPair[0].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colorPair[0].withOpacity(0.2)),
                            ),
                            child: Text(
                              skill,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colorPair[0],
                                height: 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Spacer to push buttons to bottom
//HERE I WANA SHOW DIRECTLY THE GRPAHS NO ANY ACTION BUTTON IS ALLOWED HERE
                    // Compact action buttons
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showJobDetails,
                              borderRadius: BorderRadius.circular(8),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primary, _primaryLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.visibility_rounded, size: 15, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Details',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showApplicants,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _accent.withOpacity(0.3), width: 1.2),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.group_rounded, size: 15, color: _accent),
                                    const SizedBox(width: 6),
                                    Text(
                                      'View Applicants',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _accent,
                                        height: 1,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }}






// Custom painter for subtle background pattern
class _PatternPainter extends CustomPainter {
  final bool isHovered;

  _PatternPainter({required this.isHovered});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB).withOpacity(isHovered ? 0.02 : 0.01)
      ..style = PaintingStyle.fill;

    // Draw subtle dots pattern
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) => oldDelegate.isHovered != isHovered;
}