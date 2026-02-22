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
import '../../widgets/custom_snackbars.dart';

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
  final String? jobId;

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final Set<String> _selectedApplicants = {};
  bool _selectAll = false;
  final TextEditingController _searchController = TextEditingController();

  bool _isRankingByScore = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicantsProvider>().refresh(jobId: widget.jobId);
    });
    // Add this listener
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void showTopNotification(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    if (backgroundColor == Colors.red || backgroundColor == const Color(0xFFEF4444) || backgroundColor == const Color(0xFF7F1D1D)) {
       CustomSnackbars.showError(context, message);
    } else {
       CustomSnackbars.showSuccess(context, message);
    }
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

    if (username.length <= 2) {
      return '****@$domain';
    }

    return '${username.substring(0, 2)}****@$domain';
  }

  void _toggleSelectAll(ApplicantsProvider provider) {
    setState(() {
      if (_selectAll) {
        _selectedApplicants.clear();
      } else {
        _selectedApplicants.clear();
        for (var applicant in _getFilteredApplicants(provider)) {
          _selectedApplicants.add(applicant.userId);
        }
      }
      _selectAll = !_selectAll;
    });
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedApplicants.contains(userId)) {
        _selectedApplicants.remove(userId);
        _selectAll = false;
      } else {
        _selectedApplicants.add(userId);
        if (_selectedApplicants.length ==
            context.read<ApplicantsProvider>().applicants.length) {
          _selectAll = true;
        }
      }
    });
  }

  void _rankCandidatesByScore(ApplicantsProvider provider) {
    setState(() {
      // This will trigger a rebuild with sorted applicants
    });
    showSuccessLight(context, "Candidates ranked by AI match score");
  }

  Future<void> _autoShortlistHighScorers(ApplicantsProvider provider) async {
    final aiProvider = context.read<AIMatchProvider>();
    final eligibleCandidates = <String>[];

    for (var applicant in provider.applicants) {
      // Skip if already shortlisted
      if (applicant.status.toLowerCase() == 'shortlist') {
        continue;
      }

      // Check score from database
      final matchScoreData = applicant.profileSnapshot['match_score'];
      if (matchScoreData != null && matchScoreData is Map) {
        final score = matchScoreData['overallScore'] as int? ?? 0;
        if (score > 65) {
          eligibleCandidates.add(applicant.userId);
        }
      }
    }

    if (eligibleCandidates.isEmpty) {
      showErrorTop(
        context,
        "No eligible candidates found (score > 65 and not already in shortlist)",
      );

      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
            SizedBox(width: 12),
            Text(
              'Auto Shortlist',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'This will add ${eligibleCandidates.length} candidate${eligibleCandidates.length > 1 ? 's' : ''} to shortlist with AI match score > 65%.\n\nAlready in shortlist candidates will be skipped.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Perform shortlisting
    int successCount = 0;
    for (String userId in eligibleCandidates) {
      try {
        final applicant = provider.applicants.firstWhere(
          (a) => a.userId == userId,
        );
        await provider.updateApplicationStatus(
          userId,
          applicant.docId,
          'shortlist',
        );
        successCount++;
      } catch (e) {
        debugPrint('Failed to shortlist $userId: $e');
      }
    }
    showSuccessLight(
      context,
      "$successCount candidate${successCount > 1 ? 's' : ''} auto-shortlisted successfully",
    );
  }

  Future<void> _shortlistSelected(ApplicantsProvider provider) async {
    if (_selectedApplicants.isEmpty) {
      showSuccessLight(context, "Please select at least one candidate");

      return;
    }

    int alreadyShortlisted = 0;
    int successCount = 0;

    for (String userId in _selectedApplicants) {
      final applicant = provider.applicants.firstWhere(
        (a) => a.userId == userId,
      );

      // Validation: Skip if already shortlisted
      if (applicant.status.toLowerCase() == 'shortlist') {
        alreadyShortlisted++;
        continue;
      }

      await provider.updateApplicationStatus(
        userId,
        applicant.docId,
        'shortlist',
      );
      successCount++;
    }

    setState(() {
      _selectedApplicants.clear();
      _selectAll = false;
    });

    // Show appropriate message
    if (alreadyShortlisted > 0 && successCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('All selected candidates are already shortlisted'),
            ],
          ),
          backgroundColor: Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else if (alreadyShortlisted > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$successCount shortlisted, $alreadyShortlisted already shortlisted',
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('$successCount candidates shortlisted successfully'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
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

  List<ApplicantRecord> _getFilteredApplicants(ApplicantsProvider provider) {
    var applicants = provider.applicants;

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

  // Helper to get applicant score
  int _getApplicantScore(ApplicantRecord applicant) {
    final matchScoreData = applicant.profileSnapshot['match_score'];
    if (matchScoreData != null && matchScoreData is Map) {
      return matchScoreData['overallScore'] as int? ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  backgroundColor: const Color(0xFFFFFFFF),
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

          return Column(
            children: [
              _buildHeader(provider),
              // _buildStatsSection(provider),
              Expanded(child: _buildDataTable(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ApplicantsProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Candidate Shortlisting',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'AI Active',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Manage applicants Efficiently Using AI, Unlike Traditional Methods',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: _selectedApplicants.isEmpty
                ? null
                : () => _shortlistSelected(provider),
            icon: Icon(Icons.checklist_rounded, size: 18),
            label: Text(
              _selectedApplicants.isEmpty
                  ? 'Select To Mark as Shortlist'
                  : 'Shortlist Selected',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: _selectedApplicants.isEmpty
                ? OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  )
                : OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
          ),
          SizedBox(width: 12),
          Consumer<AIMatchProvider>(
            builder: (context, aiProvider, child) {
              return ElevatedButton.icon(
                onPressed: aiProvider.isAnalyzing
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AIMatchScoreScreen(
                            jobId: widget.jobId ?? '',
                            jobTitle: provider.applicants.isNotEmpty
                                ? (provider.applicants.first.jobData?.title ??
                                      'Job Position')
                                : 'Job Position',
                          ),
                        );
                      },
                icon: Icon(
                  aiProvider.isAnalyzing
                      ? Icons.hourglass_empty
                      : Icons.psychology_outlined,
                  size: 18,
                ),
                label: Text(
                  aiProvider.isAnalyzing ? 'Analyzing...' : 'Run AI Analysis',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF086F63),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),

          SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isRankingByScore = !_isRankingByScore;
              });
              _rankCandidatesByScore(provider);
            },
            icon: Icon(
              _isRankingByScore ? Icons.filter_list : Icons.sort,
              size: 18,
            ),
            label: Text(
              _isRankingByScore ? 'Ranked' : 'Rank Now',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _isRankingByScore
                  ? Color(0xFF8B5CF6)
                  : Color(0xFF475569),
              backgroundColor: _isRankingByScore
                  ? Color(0xFF8B5CF6).withOpacity(0.1)
                  : Colors.white,
              side: BorderSide(
                color: _isRankingByScore
                    ? Color(0xFF8B5CF6)
                    : Color(0xFFE2E8F0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Auto Shortlist Button
          ElevatedButton.icon(
            onPressed: () => _autoShortlistHighScorers(provider),
            icon: Icon(Icons.auto_awesome, size: 18),
            label: Text(
              'Auto Shortlist (>65%)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ApplicantsProvider provider) {
    return Container(
      padding: EdgeInsets.all(32),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildStatCard(
                  icon: Icons.people_outline,
                  iconColor: Color(0xFF3B82F6),
                  label: 'TOTAL APPLICANTS',
                  value: '${provider.applicants.length}',
                ),
                SizedBox(width: 24),
                Consumer<AIMatchProvider>(
                  builder: (context, aiProvider, child) {
                    int totalScore = 0;
                    int count = 0;

                    for (var applicant in provider.applicants) {
                      final match = aiProvider.getMatchResult(applicant.userId);
                      if (match != null) {
                        totalScore += match.overallScore;
                        count++;
                      }
                    }

                    final avgScore = count > 0
                        ? (totalScore / count).round()
                        : 0;

                    return _buildStatCard(
                      icon: Icons.star_outline,
                      iconColor: Color(0xFF10B981),
                      label: 'AVG MATCH SCORE',
                      value: '$avgScore%',
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 48),
          Expanded(flex: 2, child: _buildMatchDistribution(provider)),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchDistribution(ApplicantsProvider provider) {
    return Consumer<AIMatchProvider>(
      builder: (context, aiProvider, child) {
        int lowCount = 0;
        int medCount = 0;
        int highCount = 0;

        for (var applicant in provider.applicants) {
          final match = aiProvider.getMatchResult(applicant.userId);
          if (match != null) {
            if (match.overallScore < 50) {
              lowCount++;
            } else if (match.overallScore < 85) {
              medCount++;
            } else {
              highCount++;
            }
          }
        }

        final total = lowCount + medCount + highCount;

        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Match Distribution Analysis',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      _buildLegend('Low', Color(0xFFEF4444)),
                      SizedBox(width: 16),
                      _buildLegend('Med', Color(0xFFF59E0B)),
                      SizedBox(width: 16),
                      _buildLegend('High', Color(0xFF10B981)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '0-40%',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Spacer(),
                        Text(
                          '41-70%',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Spacer(),
                        Text(
                          '71-85%',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Spacer(),
                        Text(
                          '86-100%',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (total > 0)
                Row(
                  children: [
                    if (lowCount > 0)
                      Expanded(
                        flex: lowCount,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    if (medCount > 0)
                      Expanded(
                        flex: medCount,
                        child: Container(height: 8, color: Color(0xFFF59E0B)),
                      ),
                    if (highCount > 0)
                      Expanded(
                        flex: highCount,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981),
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              else
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(ApplicantsProvider provider) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 0),

      child: Column(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsetsGeometry.fromLTRB(280, 0, 280, 0),
              child: _buildSearchBar(),
            ),
          ),
          _buildTableHeader(provider),
          Expanded(
            child: _getFilteredApplicants(provider).isEmpty
                ? _buildEmptyState()
                : ScrollConfiguration(
                    behavior: SmoothScrollBehavior(),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _getFilteredApplicants(provider).length,
                      itemBuilder: (context, index) {
                        final applicant = _getFilteredApplicants(
                          provider,
                        )[index];
                        final isSelected = _selectedApplicants.contains(
                          applicant.userId,
                        );
                        return _buildTableRow(
                          applicant,
                          isSelected,
                          provider,
                          index,
                        );
                      },
                    ),
                  ),
          ),
          //  if (provider.applicants.isNotEmpty) _buildPagination(provider),
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
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or keywords...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            // SizedBox(width: 12),
            // OutlinedButton.icon(
            //   onPressed: () {},
            //   icon: Icon(Icons.tune, size: 18),
            //   label: Text('Filter', style: GoogleFonts.poppins(fontSize: 14)),
            //   style: OutlinedButton.styleFrom(
            //     foregroundColor: Color(0xFF475569),
            //     side: BorderSide(color: Color(0xFFE2E8F0)),
            //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            // ),
            // SizedBox(width: 8),
            // OutlinedButton.icon(
            //   onPressed: () {},
            //   icon: Icon(Icons.swap_vert, size: 18),
            //   label: Text('Sort', style: GoogleFonts.poppins(fontSize: 14)),
            //   style: OutlinedButton.styleFrom(
            //     foregroundColor: Color(0xFF475569),
            //     side: BorderSide(color: Color(0xFFE2E8F0)),
            //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(ApplicantsProvider provider) {
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
              value: _selectAll,
              onChanged: (value) => _toggleSelectAll(provider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              activeColor: Color(0xFF8B5CF6),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              'CANDIDATE',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'EXPERIENCE',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'APPLIED ON',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'AI MATCH SCORE',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'STATUS',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              'ACTIONS',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    ApplicantRecord applicant,
    bool isSelected,
    ApplicantsProvider provider,
    int index,
  ) {
    final avatarColors = [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
    ];
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
              value: isSelected,
              onChanged: (value) => _toggleSelection(applicant.userId),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              activeColor: Color(0xFF8B5CF6),
            ),
          ),
          SizedBox(width: 10),

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
                      applicant.name.isNotEmpty
                          ? applicant.name.substring(0, 2).toUpperCase()
                          : 'NA',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: avatarColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        _maskEmail(applicant.email),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
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
            child: Text(
              '${applicant.experienceYears} years\n${applicant.professionalStatus}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM dd, yyyy').format(applicant.appliedAt),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Builder(
              builder: (context) {
                final matchScoreData = applicant.matchScore;
                final aiProvider = context.watch<AIMatchProvider>();
                final isProcessing = aiProvider.isProcessingApplicant(applicant.userId);

                // 1️⃣ STATE: Currently being analyzed by the Node server
                if (isProcessing) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Analyzing...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  );
                }

                // 2️⃣ STATE: Not analyzed yet (Data is missing from Firestore)
                // Check if matchScoreData is null OR if the specific field 'overallScore' is missing
                if (matchScoreData == null || matchScoreData['overallScore'] == null) {
                  return Text(
                    'Not analyzed',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8), // Muted grey
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }

                // 3️⃣ STATE: Success (Data exists)
                final score = matchScoreData['overallScore'] as int;
                final color = _getScoreColor(score);
                final label = _getScoreLabel(score);

                // Reconstruct AIMatchResult for dialog
                final displayResult = AIMatchResult(
                  applicantId: applicant.userId,
                  applicantName: applicant.name,
                  overallScore: score,
                  skillsMatch: matchScoreData['skillsMatch'] as int? ?? 0,
                  experienceMatch: matchScoreData['experienceMatch'] as int? ?? 0,
                  educationMatch: matchScoreData['educationMatch'] as int? ?? 0,
                  strengths: List<String>.from(matchScoreData['strengths'] ?? []),
                  weaknesses: List<String>.from(matchScoreData['weaknesses'] ?? []),
                  recommendation: matchScoreData['recommendation']?.toString() ?? 'N/A',
                  detailedAnalysis: matchScoreData['detailedAnalysis']?.toString() ?? '',
                  timestamp: DateTime.now(),
                );

                return InkWell(
                  onTap: () => _showMatchDetailsDialog(context, displayResult),
                  borderRadius: BorderRadius.circular(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock, size: 12, color: color.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            '$score%',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 20),
          Expanded(flex: 1, child: _buildStatusDropdown(applicant, provider)),
          SizedBox(width: 10),

          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
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
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
                // SizedBox(width: 4),
                // IconButton(
                //   icon: Icon(Icons.download_outlined, size: 18),
                //   onPressed: () async {
                //     if (applicant.cvUrl.isNotEmpty ||
                //         applicant.documents.isNotEmpty) {
                //       try {
                //         await downloadCvForUser(
                //           context,
                //           applicant.userId,
                //           applicant: applicant,
                //         );
                //       } catch (e) {
                //         ScaffoldMessenger.of(context).showSnackBar(
                //           SnackBar(content: Text('Download failed: $e')),
                //         );
                //       }
                //     } else {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(content: Text('CV not available')),
                //       );
                //     }
                //   },
                //   tooltip: 'Download CV',
                //   color: Color(0xFF64748B),
                //   padding: EdgeInsets.all(8),
                //   constraints: BoxConstraints(),
                // ),
                // SizedBox(width: 4),
                // IconButton(
                //   icon: Icon(Icons.chat_bubble_outline, size: 18),
                //   onPressed: () {},
                //   tooltip: 'Message',
                //   color: Color(0xFF64748B),
                //   padding: EdgeInsets.all(8),
                //   constraints: BoxConstraints(),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(
    ApplicantRecord applicant,
    ApplicantsProvider provider,
  ) {
    final statusConfig = {
      'pending': {
        'label': 'Pending',
        'color': Color(0xFFF59E0B),
        'bgColor': Color(0xFFFEF3C7),
      },

      'rejected': {
        'label': 'Rejected',
        'color': Color(0xFF64748B),
        'bgColor': Color(0xFFF1F5F9),
      },
      'shortlist': {
        'label': 'Shortlist',
        'color': Color(0xFF10B981),
        'bgColor': Color(0xFFD1FAE5),
      },
    };

    final currentStatus = applicant.status.toLowerCase();
    final config =
        statusConfig[currentStatus] ??
        {
          'label': 'Unknown',
          'color': Color(0xFF64748B),
          'bgColor': Color(0xFFF1F5F9),
        };

    return PopupMenuButton<String>(
      onSelected: (newStatus) async {
        await provider.updateApplicationStatus(
          applicant.userId,
          applicant.docId,
          newStatus,
        );
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pending',
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text('Pending', style: GoogleFonts.poppins(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'shortlist',
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text('Shortlist', style: GoogleFonts.poppins(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rejected',
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFF64748B),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text('Rejected', style: GoogleFonts.poppins(fontSize: 13)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        decoration: BoxDecoration(
          color: config['bgColor'] as Color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              config['label'] as String,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: config['color'] as Color,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: config['color'] as Color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text(
            'No Candidates Found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'There are no applicants for this position yet',
            style: GoogleFonts.poppins(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  void _showMatchDetailsDialog(BuildContext context, AIMatchResult result) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
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
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: result.getRecommendationColor().withOpacity(
                              0.1,
                            ),
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
                      if (result.strengths.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: const Color(0xFF10B981),
                              size: 20,
                            ),
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
                        ...result.strengths.map(
                          (s) => Padding(
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
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (result.weaknesses.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 20,
                            ),
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
                        ...result.weaknesses.map(
                          (w) => Padding(
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
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
}
