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
  State<view_shortlisted> createState() => _ViewShortlistedState();
}

class _ViewShortlistedState extends State<view_shortlisted>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _selectionBarController;
  late final Animation<double> _selectionBarAnimation;

  // ✅ Cached reference — avoids repeated context.read inside lifecycle hooks
  late ApplicantsProvider _provider;
  bool _isRankingByScore = false;

  // ─── Colors ───────────────────────────────────────────────────────────────
  static const _primary        = Color(0xFF6366F1);
  static const _accent         = Color(0xFFEC4899);
  static const _textPrimary    = Color(0xFF0F172A);
  static const _textSecondary  = Color(0xFF64748B);
  static const _success        = Color(0xFF10B981);

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _selectionBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _selectionBarAnimation = CurvedAnimation(
      parent: _selectionBarController,
      curve: Curves.elasticOut,
    );

    _searchController.addListener(_onSearchChanged);

    // Defer provider work until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider = context.read<ApplicantsProvider>();
      _provider.addListener(_handleSelectionChange);
      _provider.refresh(jobId: widget.jobId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Safe place to cache the provider reference before dispose is called
    _provider = context.read<ApplicantsProvider>();
  }

  // ✅ AFTER
  @override
  void didUpdateWidget(view_shortlisted oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jobId == widget.jobId) return;

    _isRankingByScore = false;
    _searchController.clear();

    // Batch both into the same post-frame callback — tree is unlocked then
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider.clearSelection();
      _provider.refresh(jobId: widget.jobId);
    });
  }
  @override
  void dispose() {
    _provider.removeListener(_handleSelectionChange);
    // Defer so notifyListeners() doesn't fire while tree is locked
    Future.microtask(_provider.clearSelection);

    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _selectionBarController.dispose();
    super.dispose();
  }
  // ─── Listeners ────────────────────────────────────────────────────────────
  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  void _handleSelectionChange() {
    if (!mounted) return;
    final hasSelection = _provider.selectedApplicantIds.isNotEmpty;
    if (hasSelection && !_selectionBarController.isCompleted) {
      _selectionBarController.forward();
    } else if (!hasSelection && !_selectionBarController.isDismissed) {
      _selectionBarController.reverse();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  List<ApplicantRecord> _getFilteredApplicants(ApplicantsProvider provider) {
    var applicants = provider.getShortlistForJob(widget.jobId);

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      applicants = applicants.where((a) {
        return a.name.toLowerCase().contains(query) ||
            a.email.toLowerCase().contains(query) ||
            (a.jobData?.title ?? '').toLowerCase().contains(query);
      }).toList();
    }

    if (_isRankingByScore) {
      applicants = List<ApplicantRecord>.from(applicants)
        ..sort((a, b) => _getApplicantScore(b).compareTo(_getApplicantScore(a)));
    }

    return applicants;
  }

  int _getApplicantScore(ApplicantRecord a) {
    final data = a.profileSnapshot['match_score'];
    return (data is Map) ? (data['overallScore'] as int? ?? 0) : 0;
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '****@****.com';
    final user = parts[0];
    return '${user.length > 2 ? user.substring(0, 2) : '**'}****@${parts[1]}';
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 70) return const Color(0xFF3B82F6);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getScoreLabel(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Medium';
    return 'Low Match';
  }

  void _toggleSelectAll(ApplicantsProvider provider) {
    final applicants = _getFilteredApplicants(provider);
    final allSelected = applicants.every((a) => provider.isSelected(a.userId));
    allSelected ? provider.clearSelection() : provider.selectAll(applicants);
  }

  void _toggleRanking(ApplicantsProvider provider) {
    setState(() => _isRankingByScore = !_isRankingByScore);
    _showTopNotification(
      context,
      _isRankingByScore ? 'Candidates ranked by AI score' : 'Default sorting restored',
      backgroundColor: _success,
      icon: Icons.check_circle_outline,
    );
  }

  // ─── Notification ─────────────────────────────────────────────────────────
  void _showTopNotification(
      BuildContext context,
      String message, {
        required Color backgroundColor,
        required IconData icon,
      }) {
    final overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: 30,
        left: 400,
        right: 380,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message,
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 5), overlayEntry.remove);
  }

  // ─── Send to Admin ────────────────────────────────────────────────────────
  Future<void> _handleSendToAdmin(ApplicantsProvider provider) async {
    final notesController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, _, __) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            // ✅ Use a dedicated StatefulWidget to avoid StatefulBuilder
            // reset bug where isSubmitting resets on every setModalState call
            child: _SendToAdminDialog(
              selectedCount: provider.selectedApplicantIds.length,
              notesController: notesController,
              onSubmit: () => provider.sendSelectedCandidatesToAdmin(
                notes: notesController.text.trim().isEmpty
                    ? 'No notes provided'
                    : notesController.text.trim(),
              ),
            ),
          ),
        );
      },
    );

    notesController.dispose(); // ✅ Always dispose controllers

    if (!mounted) return;

    if (confirm == true) {
      messenger.showSnackBar(SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _textPrimary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: _success, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Submission Successful',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                    Text('Candidates are now pending admin review.',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
              TextButton(
                onPressed: messenger.hideCurrentSnackBar,
                child: const Text('OK', style: TextStyle(color: _primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ));
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ApplicantsProvider>(
        builder: (context, provider, _) {
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
                  Text('Error: ${provider.error}',
                      style: GoogleFonts.poppins(color: Colors.red[700])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(jobId: widget.jobId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final applicants = _getFilteredApplicants(provider);
          final hasSelection = provider.selectedApplicantIds.isNotEmpty;

          return Stack(
            children: [
              Positioned.fill(
                child: Column(children: [
                  Expanded(child: _buildDataTable(provider, applicants)),
                ]),
              ),
              if (hasSelection)
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

  Widget _buildDynamicIslandBar(ApplicantsProvider provider) {
    return Center(
      child: ScaleTransition(
        scale: _selectionBarAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_textPrimary, _textPrimary.withOpacity(0.95)]),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [BoxShadow(color: _textPrimary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
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
                child: Row(children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: _accent),
                  const SizedBox(width: 6),
                  Text(
                    '${provider.selectedApplicantIds.length}',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Text('Selected', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 16),
              IconButton(
                onPressed: provider.clearSelection,
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
                label: Text('Send to Admin',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable(ApplicantsProvider provider, List<ApplicantRecord> applicants) {
    return Column(
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
              icon: const Icon(Icons.filter_list),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ApplicantFilterWidget(),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _toggleRanking(provider),
              icon: Icon(_isRankingByScore ? Icons.filter_list : Icons.sort, size: 18),
              label: Text(
                _isRankingByScore ? 'Ranked' : 'Rank Now',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _isRankingByScore ? const Color(0xFF8B5CF6) : const Color(0xFF475569),
                backgroundColor: _isRankingByScore ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.white,
                side: BorderSide(color: _isRankingByScore ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTableHeader(provider),
        Expanded(
          child: applicants.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: applicants.length,
            itemBuilder: (_, i) => _buildTableRow(
              applicants[i],
              provider.isSelected(applicants[i].userId),
              provider,
              i,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by Candidate Name...',
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  Widget _buildTableHeader(ApplicantsProvider provider) {
    final applicants = _getFilteredApplicants(provider);
    final allSelected = applicants.isNotEmpty && applicants.every((a) => provider.isSelected(a.userId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: allSelected,
              onChanged: (_) => _toggleSelectAll(provider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              activeColor: const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: _headerText('CANDIDATE')),
          Expanded(flex: 3, child: _headerText('EXPERIENCE')),
          Expanded(flex: 2, child: _headerText('APPLIED ON')),
          Expanded(flex: 2, child: _headerText('AI MATCH SCORE')),
          Expanded(flex: 1, child: _headerText('STATUS')),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: _headerText('ACTIONS')),
        ],
      ),
    );
  }

  Text _headerText(String label) => Text(
    label,
    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary),
  );

  Widget _buildTableRow(
      ApplicantRecord applicant,
      bool isSelected,
      ApplicantsProvider provider,
      int index,
      ) {
    const avatarColors = [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF06B6D4)];
    final avatarColor = avatarColors[index % avatarColors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(
              value: applicant.sentToAdmin ? true : isSelected,
              onChanged: applicant.sentToAdmin
                  ? null
                  : (_) => provider.toggleSelection(applicant.userId),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              activeColor: applicant.sentToAdmin ? Colors.grey : const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(applicant.name,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(_maskEmail(applicant.email),
                          style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
                          overflow: TextOverflow.ellipsis),
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
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569), height: 1.4),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM dd, yyyy').format(applicant.appliedAt),
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569)),
            ),
          ),
          Expanded(flex: 2, child: _buildScoreDisplay(applicant)),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: applicant.sentToAdmin ? _buildSentBadge() : _buildStatusBadge(),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 18),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ViewApplicantDetails(applicant: applicant),
              ),
              tooltip: 'View Profile',
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(ApplicantRecord applicant) {
    final data = applicant.profileSnapshot['match_score'];
    if (data is! Map) {
      return Text('Not analyzed', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF94A3B8)));
    }
    final score = data['overallScore'] as int? ?? 0;
    final color = _getScoreColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('$score%', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 8),
          Text(_getScoreLabel(score), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ]),
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
    );
  }

  Widget _buildSentBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.withOpacity(0.5)),
    ),
    child: Center(
      child: Text('SENT',
          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blue[700])),
    ),
  );

  Widget _buildStatusBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
    decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(6)),
    child: Text('Shortlist',
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: _success)),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.person_search_sharp, size: 64, color: Color(0xFF94A3B8)),
        const SizedBox(height: 16),
        Text('No candidates in shortlist',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
        const SizedBox(height: 8),
        Text(
          widget.jobId != null
              ? 'No candidates in shortlist for this position yet'
              : 'Select a job to view shortlisted candidates',
          style: GoogleFonts.poppins(fontSize: 14, color: _textSecondary),
        ),
      ],
    ),
  );
}

// ─── Extracted dialog widget — fixes StatefulBuilder isSubmitting reset bug ─
class _SendToAdminDialog extends StatefulWidget {
  const _SendToAdminDialog({
    required this.selectedCount,
    required this.notesController,
    required this.onSubmit,
  });

  final int selectedCount;
  final TextEditingController notesController;
  final Future<dynamic> Function() onSubmit;

  @override
  State<_SendToAdminDialog> createState() => _SendToAdminDialogState();
}

class _SendToAdminDialogState extends State<_SendToAdminDialog> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.outbox_rounded, color: Color(0xFF6366F1), size: 24),
            ),
            const SizedBox(width: 16),
            Text('Send to Admin',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1E293B))),
          ]),
          const SizedBox(height: 20),
          Text(
            'Reviewing ${widget.selectedCount} candidate profile(s). These will be submitted to the super admin for final approval.',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: widget.notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Administrative Notes',
              labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6366F1)),
              hintText: 'e.g. High priority candidate, check English proficiency...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
              alignLabelWithHint: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
            ),
            style: GoogleFonts.inter(fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Discard',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                  setState(() => _isSubmitting = true);
                  final result = await widget.onSubmit();
                  if (mounted) Navigator.pop(context, result != null);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Confirm & Submit',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}