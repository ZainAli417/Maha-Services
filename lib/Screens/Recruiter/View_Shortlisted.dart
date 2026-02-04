import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../widgets/view_js_profile.dart';
import 'LIst_of_Applicants_provider.dart';
import 'filter.dart';

class view_shortlisted extends StatefulWidget {
  const view_shortlisted({super.key, this.jobId});
  final String? jobId;

  @override
  State<view_shortlisted> createState() => view_shortlisted_state();
}

class view_shortlisted_state extends State<view_shortlisted> with SingleTickerProviderStateMixin {
  final Set<String> _selectedApplicants = {};
  bool _selectAll = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isRankingByScore = false;
  late AnimationController _selectionBarController;
  late Animation<double> _selectionBarAnimation;
  final ScrollController _scrollController = ScrollController();

  static const _primary = Color(0xFF6366F1);
  static const _accent = Color(0xFFEC4899);
  static const _secondary = Color(0xFF8B5CF6);
  static const _surface = Color(0xFFFFFFFF);
  static const _background = Color(0xFFF8FAFC);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _success = Color(0xFF10B981);
  static const _warning = Color(0xFFF59E0B);
  static const _error = Color(0xFFEF4444);


  @override
  void initState() {
    super.initState();

    // ✅ Initialize controller
    _selectionBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // ✅ Initialize animation
    _selectionBarAnimation = CurvedAnimation(
      parent: _selectionBarController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ApplicantsProvider>();
      provider.refresh(jobId: widget.jobId);

      // Listen to selection changes to animate
      provider.addListener(_handleSelectionChange);
    });

    _searchController.addListener(() {
      setState(() {});
    });
  }

  // 🆕 ADD: Handle selection animation
  void _handleSelectionChange() {
    final provider = context.read<ApplicantsProvider>();
    if (provider.selectedApplicantIds.isNotEmpty) {
      if (_selectionBarController.status != AnimationStatus.completed) {
        _selectionBarController.forward();
      }
    } else {

      if (_selectionBarController.status != AnimationStatus.dismissed) {
        _selectionBarController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectionBarController.dispose();

    // 🔧 ADD: Clean up listener
    final provider = context.read<ApplicantsProvider>();
    provider.removeListener(_handleSelectionChange);
    provider.clearSelection(); // Clear on exit

    super.dispose();
  }

  // 🔧 REPLACE: Toggle select all
  void _toggleSelectAll(ApplicantsProvider provider) {
    final applicants = _getFilteredApplicants(provider);

    // Check if all are selected
    final allSelected = applicants.every(
            (a) => provider.isSelected(a.userId)
    );

    if (allSelected) {
      // Clear all selections
      provider.clearSelection();
    } else {
      // Select all
      provider.selectAll(applicants);
    }
  }

  // 🔧 REPLACE: Toggle individual selection
  void _toggleSelection(String userId, ApplicantsProvider provider) {
    provider.toggleSelection(userId);
  }



  @override
  void didUpdateWidget(view_shortlisted oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.jobId != widget.jobId) {
      debugPrint('🔄 Job changed from ${oldWidget.jobId} to ${widget.jobId}');

      // 🔧 FIX: Clear provider selection, not local variable
      final provider = context.read<ApplicantsProvider>();
      provider.clearSelection();

      _selectAll = false;
      _searchController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ApplicantsProvider>().refresh(jobId: widget.jobId);
      });
    }
  }



  // 🔧 FIX: Get filtered applicants for THIS SPECIFIC JOB
  List<ApplicantRecord> _getFilteredApplicants(ApplicantsProvider provider) {
    // Get shortlisted applicants for THIS job only
    var applicants = provider.getShortlistedForJob(widget.jobId);

    debugPrint('📊 Found ${applicants.length} shortlisted for job ${widget.jobId}');

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      applicants = applicants.where((applicant) {
        return applicant.name.toLowerCase().contains(query) ||
            applicant.email.toLowerCase().contains(query) ||
            (applicant.jobData?.title ?? '').toLowerCase().contains(query);
      }).toList();
    }

    // Sort by AI match score if ranking is active
    if (_isRankingByScore) {
      applicants.sort((a, b) {
        final scoreA = _getApplicantScore(a);
        final scoreB = _getApplicantScore(b);
        return scoreB.compareTo(scoreA); // Descending order
      });
    }

    return applicants;
  }

  int _getApplicantScore(ApplicantRecord applicant) {
    final matchScoreData = applicant.profileSnapshot['match_score'];
    if (matchScoreData != null && matchScoreData is Map) {
      return matchScoreData['overallScore'] as int? ?? 0;
    }
    return 0;
  }

  void showTopNotification(
      BuildContext context,
      String message, {
        required Color backgroundColor,
        required IconData icon,
      }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 30,
        left: 400,
        right: 380,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 5), () {
      overlayEntry.remove();
    });
  }

  void showSuccessLight(BuildContext context, String message) {
    showTopNotification(
      context,
      message,
      backgroundColor: const Color(0xFF10B981),
      icon: Icons.check_circle_outline,
    );
  }

  void showErrorTop(BuildContext context, String message) {
    showTopNotification(
      context,
      message,
      backgroundColor: const Color(0xFF7F1D1D),
      icon: Icons.error,
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '****@****.com';
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) return '****@$domain';
    return '${username.substring(0, 2)}****@$domain';
  }


  void _rankCandidatesByScore(ApplicantsProvider provider) {
    setState(() {
      _isRankingByScore = !_isRankingByScore;
    });
    showSuccessLight(context, _isRankingByScore ? "Candidates ranked by AI score" : "Default sorting restored");
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return Color(0xFF10B981);
    if (score >= 70) return Color(0xFF3B82F6);
    if (score >= 50) return Color(0xFFF59E0B);
    return Color(0xFFEF4444);
  }

  String _getScoreLabel(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Medium';
    return 'Low Match';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onPressed: () => provider.refresh(jobId: widget.jobId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final shortlistedForThisJob = _getFilteredApplicants(provider);

          return Stack(
            children: [
              /// Main content
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      child: _buildDataTable(provider, shortlistedForThisJob),
                    ),
                  ],
                ),
              ),

              /// 🔧 FIX: Use provider.selectedApplicantIds instead
              if (provider.selectedApplicantIds.isNotEmpty)
                Positioned(
                  top: 20,
                  left: 16,
                  right: 16,
                  child: _buildDynamicIslandBar(provider),
                ),
            ],
          );
        },
      ),
    );
  }



  // 🔧 REPLACE: Dynamic Island Bar
  Widget _buildDynamicIslandBar(ApplicantsProvider provider) {
    return Center(
      child: ScaleTransition(
        scale: _selectionBarAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_textPrimary, _textPrimary.withOpacity(0.95)],
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: _textPrimary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: _accent),
                    const SizedBox(width: 6),
                    Text(
                      '${provider.selectedApplicantIds.length}', // 🔧 USE provider
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Selected',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => provider.clearSelection(), // 🔧 USE provider
                icon: const Icon(Icons.close, size: 18),
                color: Colors.white70,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Clear Selection',
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _handleSendToAdmin(provider),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  'Send to Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔧 REPLACE: Handle send to admin
  Future<void> _handleSendToAdmin(ApplicantsProvider provider) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _primary),
                SizedBox(height: 16),
                Text(
                  'Sending candidates...',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Send request
    final requestId = await provider.sendSelectedCandidatesToAdmin(
      notes: 'Shortlisted candidates sent from recruiter dashboard',
    );

    // Close loading dialog
    if (!mounted) return;
    Navigator.pop(context);

    // Show result
    if (requestId != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: _success, size: 28),
              const SizedBox(width: 12),
              Text(
                'Success',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request submitted successfully!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Request ID: $requestId',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Request sent to admin for review.',
                // '${provider.selectedApplicantIds.length} candidate(s) sent to admin for review.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: _primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Show error
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: _error, size: 28),
              const SizedBox(width: 12),
              Text(
                'Error',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            provider.error ?? 'Failed to send candidates to admin.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: _error),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }



  Widget _buildDataTable(ApplicantsProvider provider, List<ApplicantRecord> applicants) {
    return Container(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _buildSearchBar(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ApplicantFilterWidget(),
                  );
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _rankCandidatesByScore(provider),
                icon: Icon(_isRankingByScore ? Icons.filter_list : Icons.sort, size: 18),
                label: Text(
                  _isRankingByScore ? 'Ranked' : 'Rank Now',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _isRankingByScore ? const Color(0xFF8B5CF6) : const Color(0xFF475569),
                  backgroundColor: _isRankingByScore ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.white,
                  side: BorderSide(
                    color: _isRankingByScore ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTableHeader(provider),
          Expanded(
            child: applicants.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: applicants.length,
              itemBuilder: (context, index) {
                final applicant = applicants[index];

                // 🔧 FIX: Use provider.isSelected instead
                final isSelected = provider.isSelected(applicant.userId);

                return _buildTableRow(applicant, isSelected, provider, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by Candidate Name...',
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFF8B5CF6)),
          ),
          filled: true,
          fillColor: Color(0xFFF8FAFC),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  Widget _buildTableHeader(ApplicantsProvider provider) {
    final applicants = _getFilteredApplicants(provider);
    final allSelected = applicants.isNotEmpty &&
        applicants.every((a) => provider.isSelected(a.userId));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: allSelected,
              onChanged: (value) => _toggleSelectAll(provider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              activeColor: Color(0xFF8B5CF6),
            ),
          ),
          SizedBox(width: 10,),
          Expanded(
            flex: 3,
            child: Text('CANDIDATE', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 3,
            child: Text('EXPERIENCE', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 2,
            child: Text('APPLIED ON', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 2,
            child: Text('AI MATCH SCORE', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          Expanded(
            flex: 1,
            child: Text('STATUS', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text('ACTIONS', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(ApplicantRecord applicant, bool isSelected, ApplicantsProvider provider, int index) {
    final avatarColors = [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF06B6D4)];
    final avatarColor = avatarColors[index % avatarColors.length];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFFF5F3FF) : Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: provider.isSelected(applicant.userId), // 🔧 USE provider
              onChanged: (value) => _toggleSelection(
                applicant.userId,
                provider,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              activeColor: Color(0xFF8B5CF6),
            ),
          ),
          SizedBox(width: 10,),

          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      applicant.name.isNotEmpty ? applicant.name.substring(0, 2).toUpperCase() : 'NA',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: avatarColor),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(applicant.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                      SizedBox(height: 2),
                      Text(_maskEmail(applicant.email), style: GoogleFonts.poppins(fontSize: 13, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${applicant.experienceYears} years\n${applicant.professionalStatus}',
              style: GoogleFonts.poppins(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM dd, yyyy').format(applicant.appliedAt),
              style: GoogleFonts.poppins(fontSize: 13, color: Color(0xFF475569)),
            ),
          ),
          Expanded(flex: 2, child: _buildScoreDisplay(applicant)),
          SizedBox(width: 20),
          Expanded(flex: 1, child: _buildStatusBadge(applicant)),
          SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: IconButton(
              icon: Icon(Icons.visibility_outlined, size: 18),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) =>
                      ViewApplicantDetails(applicant: applicant),
                );
              },
              tooltip: 'View Profile',
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(ApplicantRecord applicant) {
    final matchScoreData = applicant.profileSnapshot['match_score'];

    if (matchScoreData != null && matchScoreData is Map) {
      final score = matchScoreData['overallScore'] as int? ?? 0;
      final color = _getScoreColor(score);
      final label = _getScoreLabel(score);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$score%', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              SizedBox(width: 8),
              Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
            ],
          ),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      );
    }

    return Text('Not analyzed', style: GoogleFonts.poppins(fontSize: 12, color: Color(0xFF94A3B8)));
  }

  Widget _buildStatusBadge(ApplicantRecord applicant) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        color: Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Shortlist',
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_sharp, size: 64, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text(
            'No Shortlisted Applicants',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          SizedBox(height: 8),
          Text(
            widget.jobId != null
                ? 'No candidates shortlisted for this position yet'
                : 'Select a job to view shortlisted candidates',
            style: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
