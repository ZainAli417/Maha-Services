import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../widgets/downloadcv.dart';
import '../../widgets/view_js_profile.dart';
import 'AI Candidate Matching.dart';
import 'AI Candidate Matching_Provider.dart';
import 'LIst_of_Applicants_provider.dart';

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

class ApplicantsScreen extends StatefulWidget {
  const ApplicantsScreen({super.key, this.jobId});
  final String? jobId; // Add this parameter
  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pass jobId to provider's refresh method
      context.read<ApplicantsProvider>().refresh(jobId: widget.jobId);
    });

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  String _maskEmail(String email) {
    if (email.isEmpty) return 'Not provided';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 3) return '***@$domain';
    return '${username.substring(0, 2)}****${username.substring(username.length - 1)}@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return 'Not provided';
    if (phone.length <= 4) return '****';
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 2)}';
  }

  String _maskUrl(String url) {
    if (url.isEmpty) return '';
    if (url.length <= 15) return '****';
    return '${url.substring(0, 8)}****${url.substring(url.length - 4)}';
  }

// State variables for expandable sections (add these at the top with other state variables)
  final Map<String, bool> _expandedSkills = {};
  final Map<String, bool> _expandedCerts = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<ApplicantsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
  style: GoogleFonts.poppins(color: Colors.red[700]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              // --- Middle Column becomes the main area and gains the Filters on top ---
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    children: [

                      // Candidates list below filters — expands to fill remaining space
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: _buildCandidatesColumn(provider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Column - Helper Widgets (unchanged)
              Container(
                width: 350,
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(-2, 0),
                    ),
                  ],
                ),
                child: _buildHelperColumn(provider),
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _buildCandidatesColumn(ApplicantsProvider provider) {
    return RepaintBoundary(
      child: Column(
        children: [
          // Header with count and sort
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E40AF),
                  const Color(0xFF3B82F6),
                  const Color(0xFF60A5FA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF1E40AF).withOpacity(0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.people_alt_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Applied Candidates',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review and manage applications',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.6),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${provider.filteredCount} candidates found',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildSortDropdown(provider),
                const SizedBox(width: 16),

                Consumer<AIMatchProvider>(
                  builder: (context, aiProvider, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8B5CF6),
                            const Color(0xFF7C3AED),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: aiProvider.isAnalyzing ? null : () {
                            // Show AI Match Processing Dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AIMatchScoreScreen(
                                jobId: widget.jobId ?? '',
                                jobTitle: provider.applicants.isNotEmpty
                                    ? (provider.applicants.first.jobData?.title ?? 'Job Position')
                                    : 'Job Position',
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (aiProvider.isAnalyzing) ...[
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ] else ...[
                                  Icon(
                                    Icons.psychology_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  aiProvider.isAnalyzing
                                      ? 'Analyzing...'
                                      : 'AI Match Analysis',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _buildFiltersColumn(provider),
          ),
          // Candidates List
          Expanded(
            child: Container(
              // internal padding so items don't touch rounded edges of the parent
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ Color(0xFFF8FAFC), Color(0xFFF1F5F9) ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: provider.applicants.isEmpty
                  ? _buildEmptyState()
                  : AnimatedList(
                // keep initialItemCount in sync with provider length
                initialItemCount: provider.applicants.length,
                // remove internal padding here — parent has padding now
                padding: EdgeInsets.zero,
                itemBuilder: (context, index, animation) {
                  if (index >= provider.applicants.length) return const SizedBox();

                  // horizontal gap between items and parent edges
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.vertical,
                      child: FadeTransition(
                        opacity: animation,
                        child: Material(
                          color: Colors.transparent,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            // Use a subtle panel style so each item visually belongs to the parent panel
                            child: Container(
                              // use white panel with light border (no heavy shadow)
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE8EEF6)),
                              ),
                              child: _buildCandidateCard(
                                provider.applicants[index],
                                provider,
                                index,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }


  //FILTERING SECTION
  Widget _buildFiltersColumn(ApplicantsProvider provider) {
    final sectionWidth = 250.0; // tweak this if you want wider/narrower cards

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /*
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sectionWidth,
              maxWidth: sectionWidth,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6),
                    const Color(0xFF1D4ED8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Advanced Filters',
    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (provider.hasActiveFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
           */
          // --- Search ---
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sectionWidth,
              maxWidth: sectionWidth,
            ),
            child: _buildSearchField(provider),
          ),

          const SizedBox(width: 20),

          // --- Status ---
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sectionWidth,
              maxWidth: sectionWidth,
            ),
            child: _buildStatusFilter(provider),
          ),

          const SizedBox(width: 20),

          // --- Job ---
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sectionWidth,
              maxWidth: sectionWidth,
            ),
            child: _buildJobFilter(provider),
          ),

          const SizedBox(width: 20),

          // --- Experience ---
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sectionWidth,
              maxWidth: sectionWidth,
            ),
            child: _buildExperienceFilter(provider),
          ),

          const SizedBox(width: 20),

          // --- Location ---
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sectionWidth,
              maxWidth: sectionWidth,
            ),
            child: _buildLocationFilter(provider),
          ),

          const SizedBox(width: 20),

          // --- Education ---
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sectionWidth,
              maxWidth: sectionWidth,
            ),
            child: _buildEducationFilter(provider),
          ),

          const SizedBox(width: 20),
    /*
          // --- Work Type ---
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sectionWidth,
              maxWidth: sectionWidth,
            ),
            child: _buildWorkTypeFilter(provider),
          ),
          // --- Skills ---
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sectionWidth,
              maxWidth: sectionWidth,
            ),
            child: _buildSkillsFilter(provider),
          ),

          const SizedBox(width: 20),

          // --- Salary Range ---
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sectionWidth,
              maxWidth: sectionWidth,
            ),
            child: _buildSalaryRangeFilter(provider),
          ),


     */

          // --- Date Range ---
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: sectionWidth,
              maxWidth: sectionWidth,
            ),
            child: _buildDateRangeFilter(provider),
          ),

          const SizedBox(width: 20),

          // --- Clear all (if active) ---
          if (provider.hasActiveFilters)
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: sectionWidth,
                maxWidth: sectionWidth,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: sectionWidth,
                child: ElevatedButton.icon(
                  onPressed: provider.clearAllFilters,
                  icon: const Icon(Icons.clear_all_outlined, size: 18),
                  label: const Text('Clear All Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFFEF4444).withOpacity(0.3),
                  ),
                ),
              ),
            ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }
  Widget _buildSearchField(ApplicantsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.search_outlined,
              size: 16,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 8),
            Text(
              'Search Candidates',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: provider.updateSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search by name, skills, or job title...',
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.search_outlined,
                  color: const Color(0xFF3B82F6),
                  size: 18,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildStatusFilter(ApplicantsProvider provider) {
    return _buildDropdownFilter(
      title: 'Application Status',
      icon: Icons.assignment_outlined,
      iconColor: const Color(0xFF8B5CF6),
      value: provider.statusFilter,
      items: ['All', 'pending', 'accepted', 'rejected'],
      onChanged: provider.updateStatusFilter,
      getDisplayText: (status) {
        if (status == 'All') return 'All Status';
        return status[0].toUpperCase() + status.substring(1);
      },
      getItemColor: (status) {
        switch (status) {
          case 'pending': return const Color(0xFFF59E0B);
          case 'accepted': return const Color(0xFF10B981);
          case 'rejected': return const Color(0xFFEF4444);
          default: return const Color(0xFF64748B);
        }
      },
    );
  }
  Widget _buildJobFilter(ApplicantsProvider provider) {
    final jobs = ['All', ...provider.availableJobs.toList()..sort()];
    return _buildDropdownFilter(
      title: 'Job Position',
      icon: Icons.work_outline,
      iconColor: const Color(0xFF06B6D4),
      value: provider.jobFilter,
      items: jobs,
      onChanged: provider.updateJobFilter,
    );
  }
  Widget _buildExperienceFilter(ApplicantsProvider provider) {
    final experiences = ['All', ...provider.availableExperiences];
    return _buildDropdownFilter(
      title: 'Experience Level',
      icon: Icons.trending_up_outlined,
      iconColor: const Color(0xFF10B981),
      value: provider.experienceFilter,
      items: experiences,
      onChanged: provider.updateExperienceFilter,
    );
  }
  Widget _buildLocationFilter(ApplicantsProvider provider) {
    final locations = ['All', ...provider.availableLocations.toList()..sort()];
    return _buildDropdownFilter(
      title: 'Location',
      icon: Icons.location_on_outlined,
      iconColor: const Color(0xFFEF4444),
      value: provider.locationFilter,
      items: locations,
      onChanged: provider.updateLocationFilter,
    );
  }
  Widget _buildEducationFilter(ApplicantsProvider provider) {
    final educations = ['All', ...provider.availableEducations.toList()..sort()];
    return _buildDropdownFilter(
      title: 'Education Level',
      icon: Icons.school_outlined,
      iconColor: const Color(0xFF8B5CF6),
      value: provider.educationFilter,
      items: educations,
      onChanged: provider.updateEducationFilter,
    );
  }
  /*
  Widget _buildWorkTypeFilter(ApplicantsProvider provider) {
    final workTypes = ['All', ...provider.availableWorkTypes];
    return _buildDropdownFilter(
      title: 'Work Type',
      icon: Icons.schedule_outlined,
      iconColor: const Color(0xFFF59E0B),
      value: provider.workTypeFilter,
      items: workTypes,
      onChanged: provider.updateWorkTypeFilter,
    );
  }

   */
  Widget _buildDropdownFilter({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
    String Function(String)? getDisplayText,
    Color Function(String)? getItemColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            if (value != 'All')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '1',
style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              onChanged: (newValue) => onChanged(newValue!),
              icon: Container(
                margin: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
              ),
              dropdownColor: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              items: items.map((item) {
                final color = getItemColor?.call(item) ?? const Color(0xFF64748B);
                return DropdownMenuItem<String>(
                  value: item,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        if (item != 'All')
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (item != 'All') const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            getDisplayText?.call(item) ?? item,
          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: item == value ? color : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (item == value)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: color,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              selectedItemBuilder: (context) {
                return items.map((item) {
                  final color = getItemColor?.call(item) ?? iconColor;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        if (item != 'All')
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (item != 'All') const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            getDisplayText?.call(item) ?? item,
          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ],
    );
  }
  /*
  Widget _buildSkillsFilter(ApplicantsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.code_outlined,
                size: 16,
                color: const Color(0xFFEC4899),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Skills & Technologies',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            if (provider.skillsFilter.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${provider.skillsFilter.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEC4899),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 160),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.availableSkills.map((skill) {
                final isSelected = provider.skillsFilter.contains(skill);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: GestureDetector(
                    onTap: () {
                      final newSkills = List<String>.from(provider.skillsFilter);
                      if (isSelected) {
                        newSkills.remove(skill);
                      } else {
                        newSkills.add(skill);
                      }
                      provider.updateSkillsFilter(newSkills);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                          colors: [
                            const Color(0xFFEC4899),
                            const Color(0xFFBE185D),
                          ],
                        )
                            : null,
                        color: isSelected ? null : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFEC4899)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          if (isSelected) const SizedBox(width: 4),
                          Text(
                            skill,
          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

   */
  /*
  Widget _buildSalaryRangeFilter(ApplicantsProvider provider) {
    // Ensure values are within bounds
    final double minValue = provider.minExpectedSalary.clamp(0.0, 200000.0);
    final double maxValue = provider.maxExpectedSalary.clamp(0.0, 200000.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.attach_money_outlined,
                size: 16,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Expected Salary Range',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                ),
              ),
              child: Text(
                '\$${(minValue / 1000).round()}k - \$${(maxValue / 1000).round()}k',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF10B981),
                  inactiveTrackColor: const Color(0xFFE2E8F0),
                  thumbColor: const Color(0xFF10B981),
                  overlayColor: const Color(0xFF10B981).withOpacity(0.2),
                  valueIndicatorColor: const Color(0xFF10B981),
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 12,
                    elevation: 4,
                    pressedElevation: 8,
                  ),
                  rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                ),
                child: RangeSlider(
                  values: RangeValues(minValue, maxValue),
                  min: 0,
                  max: 200000,
                  divisions: 40,
                  labels: RangeLabels(
                    '\$${(minValue / 1000).round()}k',
                    '\$${(maxValue / 1000).round()}k',
                  ),
                  onChanged: (values) {
                    provider.updateSalaryRange(values.start, values.end);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$0k',
    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '\$200k',
    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

   */
  Widget _buildDateRangeFilter(ApplicantsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.date_range_outlined,
                size: 16,
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Application Date Range',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            if (provider.appliedDateRange != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: provider.appliedDateRange,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF8B5CF6),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (range != null) {
              provider.updateAppliedDateRange(range);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: provider.appliedDateRange != null
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFFE2E8F0),
                width: provider.appliedDateRange != null ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: const Color(0xFF8B5CF6),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.appliedDateRange == null
                        ? 'Select date range'
                        : '${DateFormat('MMM dd').format(provider.appliedDateRange!.start)} - ${DateFormat('MMM dd').format(provider.appliedDateRange!.end)}',
  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: provider.appliedDateRange == null
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (provider.appliedDateRange != null)
                  GestureDetector(
                    onTap: () => provider.updateAppliedDateRange(null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildSortDropdown(ApplicantsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.sortBy,
          onChanged: (value) => provider.updateSorting(value!),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 8,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: Container(
            margin: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.sort_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          selectedItemBuilder: (context) {
            return [
              'applied_desc',
              'applied_asc',
              'name_asc',
              'name_desc',
              'experience_desc',
              'experience_asc',
              'salary_desc',
              'salary_asc',
              'status'
            ].map((value) {
              String displayText = '';
              IconData icon = Icons.sort;

              switch (value) {
                case 'applied_desc':
                  displayText = 'Latest Applied';
                  icon = Icons.schedule;
                  break;
                case 'applied_asc':
                  displayText = 'Oldest Applied';
                  icon = Icons.history;
                  break;
                case 'name_asc':
                  displayText = 'Name A-Z';
                  icon = Icons.sort_by_alpha;
                  break;
                case 'name_desc':
                  displayText = 'Name Z-A';
                  icon = Icons.sort_by_alpha;
                  break;
                case 'experience_desc':
                  displayText = 'Most Experience';
                  icon = Icons.trending_up;
                  break;
                case 'experience_asc':
                  displayText = 'Least Experience';
                  icon = Icons.trending_down;
                  break;
                case 'salary_desc':
                  displayText = 'Highest Salary';
                  icon = Icons.attach_money;
                  break;
                case 'salary_asc':
                  displayText = 'Lowest Salary';
                  icon = Icons.money_off;
                  break;
                case 'status':
                  displayText = 'Status';
                  icon = Icons.assignment;
                  break;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          items: [
            DropdownMenuItem(
              value: 'applied_desc',
              child: _buildSortItem(
                'Latest Applied',
                Icons.schedule_outlined,
                const Color(0xFF3B82F6),
              ),
            ),
            DropdownMenuItem(
              value: 'applied_asc',
              child: _buildSortItem(
                'Oldest Applied',
                Icons.history_outlined,
                const Color(0xFF6B7280),
              ),
            ),
            DropdownMenuItem(
              value: 'name_asc',
              child: _buildSortItem(
                'Name A-Z',
                Icons.sort_by_alpha_outlined,
                const Color(0xFF8B5CF6),
              ),
            ),
            DropdownMenuItem(
              value: 'name_desc',
              child: _buildSortItem(
                'Name Z-A',
                Icons.sort_by_alpha_outlined,
                const Color(0xFF8B5CF6),
              ),
            ),
            DropdownMenuItem(
              value: 'experience_desc',
              child: _buildSortItem(
                'Most Experience',
                Icons.trending_up_outlined,
                const Color(0xFF10B981),
              ),
            ),
            DropdownMenuItem(
              value: 'experience_asc',
              child: _buildSortItem(
                'Least Experience',
                Icons.trending_down_outlined,
                const Color(0xFFF59E0B),
              ),
            ),
            DropdownMenuItem(
              value: 'salary_desc',
              child: _buildSortItem(
                'Highest Salary',
                Icons.attach_money_outlined,
                const Color(0xFF10B981),
              ),
            ),
            DropdownMenuItem(
              value: 'salary_asc',
              child: _buildSortItem(
                'Lowest Salary',
                Icons.money_off_outlined,
                const Color(0xFFEF4444),
              ),
            ),
            DropdownMenuItem(
              value: 'status',
              child: _buildSortItem(
                'Status',
                Icons.assignment_outlined,
                const Color(0xFF06B6D4),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSortItem(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF64748B).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.search_off_outlined,
                size: 64,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Applications Found',
              style: GoogleFonts.poppins(
                fontSize: 24,
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your filters or search criteria\nto discover more candidates',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }









  Widget _buildCandidateCard(ApplicantRecord applicant, ApplicantsProvider provider, int index) {
    final applicantId = applicant.userId;

    // Initialize expansion states
    _expandedSkills[applicantId] ??= false;
    _expandedCerts[applicantId] ??= false;

    // Determine mandatory fields presence
    final hasEmail = applicant.email.isNotEmpty;
    final hasPhone = applicant.phone.isNotEmpty;
    final hasNationality = applicant.nationality.isNotEmpty;
    final hasCv = applicant.documents.isNotEmpty;
    final hasDob = applicant.dob.isNotEmpty;

    final missingMandatoryCount = [
      hasEmail,
      hasPhone,
      hasNationality,
      hasCv,
      hasDob,
    ].where((ok) => !ok).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant White Gradient Header with Proper Contrast
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFFAFAFA),
                  const Color(0xFFF5F5F5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enhanced Avatar with Status
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF3B82F6),
                        backgroundImage: applicant.pictureUrl.isNotEmpty
                            ? NetworkImage(applicant.pictureUrl)
                            : null,
                        child: applicant.pictureUrl.isEmpty
                            ? Text(
                          applicant.name.isNotEmpty
                              ? applicant.name[0].toUpperCase()
                              : 'JS',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _getStatusColor(applicant.status),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(applicant.status).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 20),

                // Name, Job, and Applied Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF2563EB),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.work_outline_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  applicant.jobData?.title ?? 'Job Title Not Available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Applied ${DateFormat('MMM dd, yyyy').format(applicant.appliedAt)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right Side Actions - Arranged in Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    _buildStatusBadge(applicant.status),

                    const SizedBox(width: 12),

                    // Status Update Dropdown
                    _buildStatusUpdateDropdown(applicant, provider),

                    const SizedBox(width: 12),

                    // Column for AI Match & Missing Fields
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // AI Match Score Badge
                        Consumer<AIMatchProvider>(
                          builder: (context, aiProvider, child) {
                            final matchResult = aiProvider.getMatchResult(applicantId);
                            final isProcessing = aiProvider.isProcessingApplicant(applicantId);

                            if (isProcessing) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: const AlwaysStoppedAnimation(
                                          Color(0xFF8B5CF6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Analyzing...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (matchResult != null) {
                              return InkWell(
                                onTap: () => _showMatchDetailsDialog(context, matchResult),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        matchResult.getScoreColor().withOpacity(0.15),
                                        matchResult.getScoreColor().withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: matchResult.getScoreColor().withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.stars_rounded,
                                        size: 20,
                                        color: matchResult.getScoreColor(),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${matchResult.overallScore}% Match',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: matchResult.getScoreColor(),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 12,
                                        color: matchResult.getScoreColor(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),

                        // Missing Fields Warning
                        if (missingMandatoryCount > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFDC2626).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 20,
                                  color: const Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$missingMandatoryCount missing',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content Area - Professional Layout
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Contact & Professional Info Cards
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact Information
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.contact_page_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Contact Info',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildMaskedDetailItem(
                              Icons.email_rounded,
                              'Email',
                              _maskEmail(applicant.email),
                              applicant.email,
                            ),
                            _buildMaskedDetailItem(
                              Icons.phone_rounded,
                              'Phone',
                              _maskPhone(applicant.phone),
                              applicant.phone,
                            ),
                            _buildDetailItem(
                              Icons.location_on_rounded,
                              'Location',
                              applicant.location,
                            ),
                            _buildDetailItem(
                              Icons.flag_rounded,
                              'Nationality',
                              applicant.nationality,
                            ),
                            _buildDetailItem(
                              Icons.cake_rounded,
                              'Date of Birth',
                              applicant.dob,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Professional Details
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.work_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Professional Details',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDetailItem(
                              Icons.trending_up_rounded,
                              'Experience',
                              '${applicant.experienceYears} years',
                            ),
                            _buildDetailItem(
                              Icons.school_rounded,
                              'Education',
                              applicant.education,
                            ),
                            _buildDetailItem(
                              Icons.apartment_rounded,
                              'University',
                              applicant.university,
                            ),
                            _buildDetailItem(
                              Icons.business_rounded,
                              'Company',
                              applicant.jobData?.company ?? 'Unknown Company',
                            ),
                            _buildDetailItem(
                              Icons.place_rounded,
                              'Job Location',
                              applicant.jobData?.location ?? 'Location not specified',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => ViewApplicantDetails(applicant: applicant),
                          );
                        },
                        icon: const Icon(Icons.visibility_rounded, size: 18),
                        label: Text(
                          'View Full Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (applicant.cvUrl.isNotEmpty || applicant.documents.isNotEmpty) {
                            try {
                              await downloadCvForUser(
                                context,
                                applicant.userId,
                                applicant: applicant,
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Download failed: $e')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('CV not available')),
                            );
                          }
                        },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          'Download CV',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    );
  }

  void _showMatchDetailsDialog(BuildContext context, AIMatchResult result) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      result.getScoreColor(),
                      result.getScoreColor().withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.applicantName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'AI Match Analysis',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${result.overallScore}',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recommendation Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: result.getRecommendationColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: result.getRecommendationColor(),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            result.recommendation,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: result.getRecommendationColor(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Score Breakdown
                      Text(
                        'Score Breakdown',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildScoreRow('Skills Match', result.skillsMatch),
                      const SizedBox(height: 12),
                      _buildScoreRow('Experience', result.experienceMatch),
                      const SizedBox(height: 12),
                      _buildScoreRow('Education', result.educationMatch),
                      const SizedBox(height: 24),

                      // Strengths
                      if (result.strengths.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: const Color(0xFF10B981), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Key Strengths',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...result.strengths.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 16),
                      ],

                      // Weaknesses
                      if (result.weaknesses.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: const Color(0xFFF59E0B), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Areas for Improvement',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...result.weaknesses.map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  w,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 16),
                      ],

                      // Detailed Analysis
                      Text(
                        'Detailed Analysis',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          result.detailedAnalysis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.6,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Close Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: result.getScoreColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildScoreRow(String label, int score) {
    final color = score >= 80
        ? const Color(0xFF10B981)
        : score >= 60
        ? const Color(0xFF3B82F6)
        : score >= 40
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: score / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$score%',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }




  Widget _buildMaskedDetailItem(
      IconData icon,
      String label,
      String maskedValue,
      String originalValue,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.5,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        maskedValue,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (originalValue.isNotEmpty)
                      Tooltip(
                        message: 'Sensitive data masked',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.visibility_off_outlined,
                            size: 14,
                            color: const Color(0xFF3B82F6),
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
    );
  }




  Widget _buildDetailItem(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatusBadge(String status, {bool compact = true}) {
    Color color;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = const Color(0xFFF59E0B);
        label = 'Pending';
        icon = Icons.schedule_rounded;
        break;
      case 'accepted':
        color = const Color(0xFF10B981);
        label = 'Accepted';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        color = const Color(0xFFEF4444);
        label = 'Rejected';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = const Color(0xFF64748B);
        label = status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'Unknown';
        icon = Icons.help_outline_rounded;
    }

    final fontSize = compact ? 12.0 : 13.0;
    final vertical = compact ? 6.0 : 8.0;
    final horizontal = compact ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Widget _buildStatusUpdateDropdown(ApplicantRecord applicant, ApplicantsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF64748B),
            const Color(0xFF475569),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: applicant.status,
          onChanged: (newStatus) {
            if (newStatus != null && newStatus != applicant.status) {
              provider.updateApplicationStatus(applicant.userId, applicant.docId, newStatus);

              // Get status color and label
              Color statusColor;
              String statusLabel;
              IconData statusIcon;

              switch (newStatus.toLowerCase()) {
                case 'accepted':
                  statusColor = const Color(0xFF10B981);
                  statusLabel = 'Accepted';
                  statusIcon = Icons.check_circle_rounded;
                  break;
                case 'rejected':
                  statusColor = const Color(0xFFEF4444);
                  statusLabel = 'Rejected';
                  statusIcon = Icons.cancel_rounded;
                  break;
                default:
                  statusColor = const Color(0xFFF59E0B);
                  statusLabel = 'Pending';
                  statusIcon = Icons.schedule_rounded;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Status updated to $statusLabel',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: statusColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: 16,
          icon: Container(
            margin: const EdgeInsets.only(left: 4, right: 8),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          items: [
            DropdownMenuItem(
              value: 'pending',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Pending',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'accepted',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Accepted',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DropdownMenuItem(
              value: 'rejected',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cancel_rounded,
                        color: const Color(0xFFEF4444),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Rejected',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          selectedItemBuilder: (context) {
            return ['pending', 'accepted', 'rejected'].map((status) {
              String displayText = 'Update Status';
              if (status == 'accepted') displayText = 'Accepted';
              if (status == 'rejected') displayText = 'Rejected';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayText,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
  Widget _buildHelperColumn(ApplicantsProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Widget
            _buildStatisticsWidget(provider),
            const SizedBox(height: 24),

            // Recent Applications
            _buildRecentApplicationsWidget(provider),
            const SizedBox(height: 24),

            // Application Status Chart
            _buildApplicationStatusChart(provider),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActionsWidget(provider),
          ],
        ),
      ),
    );
  }
// COMPACT: Statistics panel
  Widget _buildStatisticsWidget(ApplicantsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12), // was 24
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // was 16
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.06), // lighter
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics_outlined, color: const Color(0xFF3B82F6), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Application Statistics',
                style: GoogleFonts.poppins(
                  fontSize: 15, // was 18
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Applications',
                  provider.totalApplicants.toString(),
                  const Color(0xFF3B82F6),
                  Icons.assessment_outlined,
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Under Review',
                  provider.pendingCount.toString(),
                  const Color(0xFFF59E0B),
                  Icons.schedule_outlined,
                  compact: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Accepted',
                  provider.acceptedCount.toString(),
                  const Color(0xFF10B981),
                  Icons.check_circle_outline,
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Rejected',
                  provider.rejectedCount.toString(),
                  const Color(0xFFEF4444),
                  Icons.cancel_outlined,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// COMPACT: Stat card (adds compact flag)
  Widget _buildStatCard(String title, String value, Color color, IconData icon, {bool compact = false}) {
    final padding = compact ? 10.0 : 16.0;
    final valueSize = compact ? 20.0 : 28.0;
    final titleSize = compact ? 11.0 : 12.0;
    final iconSize = compact ? 16.0 : 18.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.06), color.withOpacity(0.10)],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.14), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: iconSize),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Live',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 350),
            style: GoogleFonts.poppins(
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.8,
            ),
            child: Text(value),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: titleSize,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// COMPACT: Recent Applications widget
  Widget _buildRecentApplicationsWidget(ApplicantsProvider provider) {
    final recentApplicants = provider.allApplicants.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(12), // was 24
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.schedule_outlined, color: const Color(0xFF8B5CF6), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Recent Applications',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (recentApplicants.isEmpty)
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.inbox_outlined, size: 28, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No recent applications',
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else
            ...recentApplicants.map((applicant) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, // was 44
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          applicant.name.isNotEmpty ? applicant.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(applicant.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(applicant.jobData?.title ?? 'Job Title',
                              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    _buildStatusBadge(applicant.status, compact: true),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

// COMPACT: Applications overview chart (more compact)
  Widget _buildApplicationStatusChart(ApplicantsProvider provider) {
    final total = provider.totalApplicants;
    final pendingPercentage = total > 0 ? (provider.pendingCount / total) : 0.0;
    final acceptedPercentage = total > 0 ? (provider.acceptedCount / total) : 0.0;
    final rejectedPercentage = total > 0 ? (provider.rejectedCount / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF06B6D4).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.pie_chart_outline, color: const Color(0xFF06B6D4), size: 16),
              ),
              const SizedBox(width: 10),
              Text('Applications Overview', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          if (total == 0)
            Center(
              child: Column(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.bar_chart_outlined, size: 28, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 10),
                  Text('No applications yet', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B))),
                ],
              ),
            )
          else ...[
            _buildProgressBar('Under Review', provider.pendingCount, pendingPercentage, const Color(0xFFF59E0B)),
            const SizedBox(height: 10),
            _buildProgressBar('Accepted', provider.acceptedCount, acceptedPercentage, const Color(0xFF10B981)),
            const SizedBox(height: 10),
            _buildProgressBar('Rejected', provider.rejectedCount, rejectedPercentage, const Color(0xFFEF4444)),
          ],
        ],
      ),
    );
  }

// COMPACT: small tweak to progress bar (keeps same look but thinner)
  Widget _buildProgressBar(String label, int count, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('$count (${(percentage * 100).toStringAsFixed(0)}%)', style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6, // thinner than before
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.9)]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

// COMPACT: Quick actions widget (less padding, tighter buttons)
  Widget _buildQuickActionsWidget(ApplicantsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFEC4899).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.flash_on_outlined, color: const Color(0xFFEC4899), size: 16),
              ),
              const SizedBox(width: 10),
              Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(icon: Icons.refresh_outlined, label: 'Refresh Data', onPressed: provider.refresh, color: const Color(0xFF3B82F6), compact: true),
          const SizedBox(height: 8),
          _buildQuickActionButton(icon: Icons.filter_list_off_outlined, label: 'Clear All Filters', onPressed: provider.hasActiveFilters ? provider.clearAllFilters : null, color: const Color(0xFFF59E0B), compact: true),
          const SizedBox(height: 8),
          _buildQuickActionButton(icon: Icons.download_outlined, label: 'Export Applications', onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export feature coming soon'))), color: const Color(0xFF10B981), compact: true),
          const SizedBox(height: 8),
          _buildQuickActionButton(icon: Icons.email_outlined, label: 'Send Bulk Email', onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bulk email coming soon'))), color: const Color(0xFF8B5CF6), compact: true),
        ],
      ),
    );
  }

// COMPACT: Quick action button
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
    bool compact = false,
  }) {
    final vertical = compact ? 10.0 : 16.0;
    final fontSize = compact ? 13.0 : 14.0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed != null ? color : const Color(0xFFF1F5F9),
          foregroundColor: onPressed != null ? Colors.white : const Color(0xFF94A3B8),
          padding: EdgeInsets.symmetric(vertical: vertical),
          textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: onPressed != null ? 1 : 0,
        ),
      ),
    );
  }



}