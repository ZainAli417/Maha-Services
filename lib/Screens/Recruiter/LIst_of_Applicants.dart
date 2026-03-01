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

// ─── Scroll behavior ──────────────────────────────────────────────────────────
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

// ─── Color tokens ─────────────────────────────────────────────────────────────
const _cPrimary  = Color(0xFF1E3A5F);
const _cAccent   = Color(0xFF3B82F6);
const _cPurple   = Color(0xFF8B5CF6);
const _cGreen    = Color(0xFF10B981);
const _cAmber    = Color(0xFFF59E0B);
const _cRed      = Color(0xFFEF4444);
const _cSlate    = Color(0xFF64748B);
const _cSurface  = Color(0xFFF8FAFC);
const _cBorder   = Color(0xFFE2E8F0);
const _cTxt      = Color(0xFF0F172A);
const _cTxtSec   = Color(0xFF64748B);
const _cTxtTert  = Color(0xFF94A3B8);
const _cTeal     = Color(0xFF086F63);

// ─────────────────────────────────────────────────────────────────────────────
class ApplicantsScreen extends StatefulWidget {
  const ApplicantsScreen({super.key, this.jobId});
  final String? jobId;

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final Set<String> _selected = {};
  bool _selectAll      = false;
  bool _rankByScore    = false;
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplicantsProvider>().refresh(jobId: widget.jobId);
    });
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ─── Notifications ──────────────────────────────────────────────────────
  void _toast(String msg, {bool error = false}) {
    error
        ? CustomSnackbars.showError(context, msg)
        : CustomSnackbars.showSuccess(context, msg);
  }

  // ─── Email masking ──────────────────────────────────────────────────────
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '****@****.com';
    final u = parts[0];
    return '${u.length > 2 ? u.substring(0, 2) : '**'}****@${parts[1]}';
  }

  // ─── Selection helpers ──────────────────────────────────────────────────
  void _toggleAll(ApplicantsProvider p) {
    setState(() {
      if (_selectAll) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_filtered(p).map((a) => a.userId));
      }
      _selectAll = !_selectAll;
    });
  }

  void _toggleOne(String id, ApplicantsProvider p) {
    setState(() {
      _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
      _selectAll = _selected.length == p.applicants.length;
    });
  }

  // ─── Filtering / sorting ────────────────────────────────────────────────
  List<ApplicantRecord> _filtered(ApplicantsProvider p) {
    var list = p.applicants;
    if (_search.text.isNotEmpty) {
      final q = _search.text.toLowerCase();
      list = list
          .where((a) =>
      a.name.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q) ||
          (a.jobData?.title ?? '').toLowerCase().contains(q))
          .toList();
    }
    if (_rankByScore) {
      list = [...list]..sort((a, b) => _score(b).compareTo(_score(a)));
    }
    return list;
  }

  int _score(ApplicantRecord a) {
    final d = a.matchScore;
    return (d is Map) ? (d['overallScore'] as int? ?? 0) : 0;
  }

  // ─── Shortlist selected ─────────────────────────────────────────────────
  Future<void> _shortlistSelected(ApplicantsProvider p) async {
    if (_selected.isEmpty) {
      _toast('Select at least one candidate');
      return;
    }
    int ok = 0, skip = 0;
    for (final id in _selected) {
      final a = p.applicants.firstWhere((x) => x.userId == id);
      if (a.status.toLowerCase() == 'shortlist') { skip++; continue; }
      await p.updateApplicationStatus(id, a.docId, 'shortlist');
      ok++;
    }
    setState(() { _selected.clear(); _selectAll = false; });
    if (skip > 0 && ok == 0) {
      _toast('All selected already shortlisted');
    } else if (skip > 0) {
      _toast('$ok shortlisted, $skip already in shortlist');
    } else {
      _toast('$ok candidate${ok > 1 ? 's' : ''} shortlisted');
    }
  }

  // ─── Auto shortlist ─────────────────────────────────────────────────────
  Future<void> _autoShortlist(ApplicantsProvider p) async {
    final eligible = p.applicants.where((a) {
      if (a.status.toLowerCase() == 'shortlist') return false;
      final d = a.matchScore;
      return (d is Map) && ((d['overallScore'] as int? ?? 0) > 65);
    }).map((a) => a.userId).toList();

    if (eligible.isEmpty) {
      _toast('No candidates with score > 65 outside shortlist', error: true);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          const Icon(Icons.auto_awesome, color: _cPurple),
          const SizedBox(width: 10),
          Text('Auto Shortlist',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          'Add ${eligible.length} candidate${eligible.length > 1 ? 's' : ''} '
              'with AI score > 65% to shortlist?\n\nAlready shortlisted will be skipped.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _cPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: Text('Confirm',
                  style: GoogleFonts.poppins(color: Colors.white))),
        ],
      ),
    );
    if (ok != true) return;

    int count = 0;
    for (final id in eligible) {
      try {
        final a = p.applicants.firstWhere((x) => x.userId == id);
        await p.updateApplicationStatus(id, a.docId, 'shortlist');
        count++;
      } catch (e) {
        debugPrint('Auto shortlist error: $e');
      }
    }
    _toast('$count candidate${count > 1 ? 's' : ''} auto-shortlisted');
  }

  // ─── Score helpers ──────────────────────────────────────────────────────
  Color _scoreColor(int s) {
    if (s >= 85) return _cGreen;
    if (s >= 70) return _cAccent;
    if (s >= 50) return _cAmber;
    return _cRed;
  }

  String _scoreLabel(int s) {
    if (s >= 85) return 'Excellent';
    if (s >= 70) return 'Good';
    if (s >= 50) return 'Medium';
    return 'Low';
  }

  // ─── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      body: Consumer<ApplicantsProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _cPurple));
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 44, color: Colors.red[300]),
                  const SizedBox(height: 14),
                  Text('Error: ${provider.error}',
                      style: GoogleFonts.poppins(color: Colors.red[700])),
                  const SizedBox(height: 14),
                  ElevatedButton(
                      onPressed: () => provider.refresh(jobId: widget.jobId),
                      child: const Text('Retry')),
                ],
              ),
            );
          }
          return Column(
            children: [
              _Header(
                isMobile: isMobile,
                selected: _selected,
                rankByScore: _rankByScore,
                jobId: widget.jobId,
                provider: provider,
                onShortlist: () => _shortlistSelected(provider),
                onAutoShortlist: () => _autoShortlist(provider),
                onToggleRank: () {
                  setState(() => _rankByScore = !_rankByScore);
                  _toast(_rankByScore
                      ? 'Ranked by AI match score'
                      : 'Ranking cleared');
                },
              ),
              Expanded(child: _buildTable(provider, isMobile)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTable(ApplicantsProvider p, bool isMobile) {
    final list = _filtered(p);
    if (list.isEmpty) return _EmptyResults(onClear: p.clearAllFilters);

    // ── Shared search bar + list, layout differs per breakpoint ──────────────
    return Column(
      children: [
        _SearchBar(controller: _search, isMobile: isMobile),
        if (!isMobile)
          _TableHeader(
            selectAll: _selectAll,
            isMobile: false,
            onToggleAll: () => _toggleAll(p),
          ),
        // ── Mobile: select-all row ──────────────────────────────────────────
        if (isMobile)
          _MobileSelectBar(
            total: list.length,
            selectedCount: _selected.length,
            selectAll: _selectAll,
            onToggleAll: () => _toggleAll(p),
          ),
        Expanded(
          child: ScrollConfiguration(
            behavior: SmoothScrollBehavior(),
            child: ListView.builder(
              padding: EdgeInsets.only(
                bottom: isMobile ? 16 : 0,
                top: isMobile ? 8 : 0,
              ),
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final a = list[i];
                final isSelected = _selected.contains(a.userId);

                // ── Mobile → card layout ──────────────────────────────────
                if (isMobile) {
                  return _ApplicantCard(
                    applicant: a,
                    index: i,
                    isSelected: isSelected,
                    maskEmail: _maskEmail,
                    scoreColor: _scoreColor,
                    scoreLabel: _scoreLabel,
                    onToggle: () => _toggleOne(a.userId, p),
                    onStatusChange: (s) =>
                        p.updateApplicationStatus(a.userId, a.docId, s),
                    onViewDetails: () {
                      if (isMobile) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => ViewApplicantDetails(applicant: a),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => ViewApplicantDetails(applicant: a),
                        );
                      }
                    },
                    onShowScore: (r) => _showScoreDialog(context, r),
                  );
                }

                // ── Desktop → table row ───────────────────────────────────
                return _TableRow(
                  applicant: a,
                  index: i,
                  isSelected: isSelected,
                  isMobile: false,
                  maskEmail: _maskEmail,
                  scoreColor: _scoreColor,
                  scoreLabel: _scoreLabel,
                  onToggle: () => _toggleOne(a.userId, p),
                  onStatusChange: (s) =>
                      p.updateApplicationStatus(a.userId, a.docId, s),
                  onViewDetails: () {
                    if (isMobile) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ViewApplicantDetails(applicant: a),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => ViewApplicantDetails(applicant: a),
                      );
                    }
                  },
                  onShowScore: (r) => _showScoreDialog(context, r),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  void _showScoreDialog(BuildContext ctx, AIMatchResult r) {
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
          child: Column(
            children: [
              // Header gradient
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    r.getScoreColor(),
                    r.getScoreColor().withOpacity(0.75),
                  ]),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: Row(children: [
                  const Icon(Icons.psychology, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.applicantName,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text('AI Match Analysis',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.85))),
                        ]),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: Text('${r.overallScore}',
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ]),
              ),
              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: r.getRecommendationColor()
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: r.getRecommendationColor(), width: 1.5),
                            ),
                            child: Text(r.recommendation,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: r.getRecommendationColor())),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Score Breakdown',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        _ScoreRow(label: 'Skills Match', score: r.skillsMatch),
                        const SizedBox(height: 10),
                        _ScoreRow(
                            label: 'Experience', score: r.experienceMatch),
                        const SizedBox(height: 10),
                        _ScoreRow(label: 'Education', score: r.educationMatch),
                        if (r.strengths.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _SectionHead(
                              'Key Strengths', Icons.check_circle, _cGreen),
                          const SizedBox(height: 10),
                          ...r.strengths.map((s) => _Bullet(s, _cGreen)),
                        ],
                        if (r.weaknesses.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SectionHead('Areas for Improvement',
                              Icons.warning_amber_rounded, _cAmber),
                          const SizedBox(height: 10),
                          ...r.weaknesses.map((w) => _Bullet(w, _cAmber)),
                        ],
                        const SizedBox(height: 16),
                        Text('Detailed Analysis',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: _cSurface,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(r.detailedAnalysis,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  height: 1.6,
                                  color: _cTxtSec)),
                        ),
                      ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: r.getScoreColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Close',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _MobileSelectBar extends StatelessWidget {
  final int total;
  final int selectedCount;
  final bool selectAll;
  final VoidCallback onToggleAll;

  const _MobileSelectBar({
    required this.total,
    required this.selectedCount,
    required this.selectAll,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: _cSurface,
        border: Border(bottom: BorderSide(color: _cBorder)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selectAll,
            onChanged: (_) => onToggleAll(),
            activeColor: _cPurple,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50)),
          ),
          const SizedBox(width: 8),
          Text(
            selectedCount == 0
                ? '$total candidate${total == 1 ? '' : 's'}'
                : '$selectedCount of $total selected',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selectedCount > 0 ? _cPurple : _cTxtSec,
            ),
          ),
        ],
      ),
    );
  }
}
class _ApplicantCard extends StatelessWidget {
  final ApplicantRecord applicant;
  final int index;
  final bool isSelected;
  final String Function(String) maskEmail;
  final Color Function(int) scoreColor;
  final String Function(int) scoreLabel;
  final VoidCallback onToggle;
  final Future<void> Function(String) onStatusChange;
  final VoidCallback onViewDetails;
  final void Function(AIMatchResult) onShowScore;

  const _ApplicantCard({
    required this.applicant,
    required this.index,
    required this.isSelected,
    required this.maskEmail,
    required this.scoreColor,
    required this.scoreLabel,
    required this.onToggle,
    required this.onStatusChange,
    required this.onViewDetails,
    required this.onShowScore,
  });

  static const _avatarColors = [
    Color(0xFF3B82F6), Color(0xFF8B5CF6),
    Color(0xFFEC4899), Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColors[index % _avatarColors.length];

    // ── Score data ──────────────────────────────────────────────────────────
    final scoreData = applicant.matchScore;
    final hasScore  = scoreData != null && scoreData['overallScore'] != null;
    final score     = hasScore ? (scoreData['overallScore'] as int) : 0;
    final sColor    = hasScore ? scoreColor(score) : _cTxtTert;
    final sLabel    = hasScore ? scoreLabel(score) : 'Not analyzed';

    return GestureDetector(
      onTap: onViewDetails,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _cPurple.withOpacity(0.4) : _cBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Top row: checkbox + avatar + name + status ────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Checkbox
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggle(),
                      activeColor: _cPurple,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Avatar
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: avatarColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        applicant.name.isNotEmpty
                            ? applicant.name.substring(0, 2).toUpperCase()
                            : 'NA',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: avatarColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Name + email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicant.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _cTxt,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          maskEmail(applicant.email),
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: _cTxtSec),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status dropdown
                  _StatusDropdown(
                    applicant: applicant,
                    onStatusChange: onStatusChange,
                  ),
                ],
              ),
            ),

            // ── Divider ───────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Divider(height: 1, color: _cBorder),
            ),

            // ── Meta row: experience + applied date ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _MetaChip(
                    icon: Icons.work_outline_rounded,
                    label: '${applicant.experienceYears}y exp',
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('MMM d, yy')
                        .format(applicant.appliedAt),
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.badge_outlined,
                    label: applicant.professionalStatus,
                    maxWidth: 100,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── AI Score row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Builder(builder: (ctx) {
                final ai   = ctx.watch<AIMatchProvider>();
                final busy = ai.isProcessingApplicant(applicant.userId);

                if (busy) {
                  return Row(children: [
                    const SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation(_cPurple),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Analyzing…',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: _cTxtSec)),
                  ]);
                }

                return Row(
                  children: [
                    // Score pill / label
                    GestureDetector(
                      onTap: hasScore
                          ? () {
                        final result = AIMatchResult(
                          applicantId: applicant.userId,
                          applicantName: applicant.name,
                          overallScore: score,
                          skillsMatch: scoreData['skillsMatch'] as int? ?? 0,
                          experienceMatch: scoreData['experienceMatch'] as int? ?? 0,
                          educationMatch: scoreData['educationMatch'] as int? ?? 0,
                          strengths: List<String>.from(scoreData['strengths'] ?? []),
                          weaknesses: List<String>.from(scoreData['weaknesses'] ?? []),
                          recommendation: scoreData['recommendation']?.toString() ?? 'N/A',
                          detailedAnalysis: scoreData['detailedAnalysis']?.toString() ?? '',
                          timestamp: DateTime.now(),
                        );
                        onShowScore(result);
                      }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: sColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sColor.withOpacity(0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.auto_awesome,
                              size: 11, color: sColor),
                          const SizedBox(width: 4),
                          Text(
                            hasScore ? '$score%  $sLabel' : sLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sColor,
                            ),
                          ),
                        ]),
                      ),
                    ),

                    // Progress bar (only if score exists)
                    if (hasScore) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: score / 100,
                            backgroundColor: _cBorder,
                            valueColor: AlwaysStoppedAnimation(sColor),
                            minHeight: 5,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // View profile button
                    GestureDetector(
                      onTap: onViewDetails,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _cSurface,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: _cBorder),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.visibility_outlined,
                              size: 14, color: _cTxtSec),
                          const SizedBox(width: 5),
                          Text('View',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _cTxtSec)),
                        ]),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? maxWidth;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _cSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _cBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: _cTxtTert),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 80),
          child: Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 10, fontWeight: FontWeight.w600, color: _cTxtSec),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// HEADER WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isMobile;
  final Set<String> selected;
  final bool rankByScore;
  final String? jobId;
  final ApplicantsProvider provider;
  final VoidCallback onShortlist;
  final VoidCallback onAutoShortlist;
  final VoidCallback onToggleRank;

  const _Header({
    required this.isMobile,
    required this.selected,
    required this.rankByScore,
    required this.jobId,
    required this.provider,
    required this.onShortlist,
    required this.onAutoShortlist,
    required this.onToggleRank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 28,
        isMobile ? 14 : 20,
        isMobile ? 14 : 28,
        isMobile ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _cBorder)),
      ),
      child: isMobile ? _mobileHeader(context) : _desktopHeader(context),
    );
  }

  // Mobile: title row + scrollable action chips
  Widget _mobileHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Candidate Shortlisting',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _cTxt,
                          letterSpacing: -0.4)),
                  const SizedBox(height: 2),
                  Text('AI-powered applicant management',
                      style: GoogleFonts.poppins(fontSize: 11, color: _cTxtSec)),
                ]),
          ),
          _AIBadge(small: true),
          const SizedBox(width: 8),
          // Mobile action menu button
          GestureDetector(
            onTap: () => _showMobileActions(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cPrimary.withOpacity(0.2)),
              ),
              child: const Icon(Icons.more_horiz_rounded,
                  size: 20, color: _cPrimary),
            ),
          ),
        ]),
        // Selection status if any selected
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _cPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cPurple.withOpacity(0.3)),
              ),
              child: Text('${selected.length} selected',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _cPurple)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onShortlist,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _cPurple,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Shortlist',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ]),
        ],
      ],
    );
  }

  // Mobile bottom sheet for actions
  void _showMobileActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: _cBorder,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('Actions',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _cTxt)),
            const SizedBox(height: 14),
            // Run AI Analysis
            Consumer<AIMatchProvider>(builder: (ctx, ai, _) {
              return _ActionTile(
                icon: ai.isAnalyzing
                    ? Icons.hourglass_empty
                    : Icons.psychology_outlined,
                label: ai.isAnalyzing ? 'Analyzing…' : 'Run AI Analysis',
                color: _cTeal,
                onTap: ai.isAnalyzing
                    ? null
                    : () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AIMatchScoreScreen(
                      jobId: jobId ?? '',
                      jobTitle: provider.applicants.isNotEmpty
                          ? (provider.applicants.first.jobData
                          ?.title ??
                          'Job Position')
                          : 'Job Position',
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 10),
            _ActionTile(
              icon: rankByScore ? Icons.filter_list : Icons.sort,
              label: rankByScore ? 'Clear Ranking' : 'Rank by AI Score',
              color: _cPurple,
              active: rankByScore,
              onTap: () { Navigator.pop(context); onToggleRank(); },
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.auto_awesome,
              label: 'Auto Shortlist (Score > 65%)',
              color: _cGreen,
              onTap: () { Navigator.pop(context); onAutoShortlist(); },
            ),
          ],
        ),
      ),
    );
  }

  // Desktop: full inline
  Widget _desktopHeader(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Candidate Shortlisting',
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _cTxt,
                    letterSpacing: -0.5)),
            const SizedBox(width: 10),
            const _AIBadge(small: false),
          ]),
          const SizedBox(height: 4),
          Text('Manage applicants efficiently using AI',
              style: GoogleFonts.poppins(fontSize: 13, color: _cTxtSec)),
        ]),
      ),
      const SizedBox(width: 16),
      _DesktopActions(
        selected: selected,
        rankByScore: rankByScore,
        jobId: jobId,
        provider: provider,
        onShortlist: onShortlist,
        onAutoShortlist: onAutoShortlist,
        onToggleRank: onToggleRank,
      ),
    ]);
  }
}

// Desktop action buttons row
class _DesktopActions extends StatelessWidget {
  final Set<String> selected;
  final bool rankByScore;
  final String? jobId;
  final ApplicantsProvider provider;
  final VoidCallback onShortlist;
  final VoidCallback onAutoShortlist;
  final VoidCallback onToggleRank;

  const _DesktopActions({
    required this.selected,
    required this.rankByScore,
    required this.jobId,
    required this.provider,
    required this.onShortlist,
    required this.onAutoShortlist,
    required this.onToggleRank,
  });

  @override
  Widget build(BuildContext context) {
    const pad = EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    const radius = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)));
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        // Shortlist selected
        OutlinedButton.icon(
          onPressed: selected.isEmpty ? null : onShortlist,
          icon: const Icon(Icons.checklist_rounded, size: 16),
          label: Text(
            selected.isEmpty ? 'Select to Shortlist' : 'Shortlist (${selected.length})',
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600),
          ),
          style: selected.isEmpty
              ? OutlinedButton.styleFrom(
              foregroundColor: _cTxtSec,
              side: const BorderSide(color: _cBorder),
              padding: pad, shape: radius)
              : OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _cPurple,
              padding: pad, shape: radius),
        ),
        // Run AI
        Consumer<AIMatchProvider>(builder: (ctx, ai, _) {
          return ElevatedButton.icon(
            onPressed: ai.isAnalyzing
                ? null
                : () => showDialog(
              context: ctx,
              barrierDismissible: false,
              builder: (_) => AIMatchScoreScreen(
                jobId: jobId ?? '',
                jobTitle: provider.applicants.isNotEmpty
                    ? (provider.applicants.first.jobData?.title ??
                    'Job Position')
                    : 'Job Position',
              ),
            ),
            icon: Icon(
                ai.isAnalyzing ? Icons.hourglass_empty : Icons.psychology_outlined,
                size: 16),
            label: Text(ai.isAnalyzing ? 'Analyzing…' : 'Run AI Analysis',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: pad,
              shape: radius,
            ),
          );
        }),
        // Rank
        OutlinedButton.icon(
          onPressed: onToggleRank,
          icon: Icon(rankByScore ? Icons.filter_list : Icons.sort, size: 16),
          label: Text(rankByScore ? 'Ranked' : 'Rank by Score',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: rankByScore ? _cPurple : _cTxtSec,
            backgroundColor:
            rankByScore ? _cPurple.withOpacity(0.08) : Colors.white,
            side: BorderSide(color: rankByScore ? _cPurple : _cBorder),
            padding: pad,
            shape: radius,
          ),
        ),
        // Auto shortlist
        ElevatedButton.icon(
          onPressed: onAutoShortlist,
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: Text('Auto Shortlist >65%',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _cGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: pad,
            shape: radius,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BAR
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isMobile;
  const _SearchBar({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 10 : 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _cBorder))),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(fontSize: 13, color: _cTxt),
        decoration: InputDecoration(
          hintText: 'Search by name, email or keyword…',
          hintStyle: GoogleFonts.poppins(fontSize: 12, color: _cTxtTert),
          prefixIcon: const Icon(Icons.search, color: _cTxtTert, size: 18),
          filled: true,
          fillColor: _cSurface,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _cBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _cBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _cPurple, width: 1.5)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLE HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  final bool selectAll;
  final bool isMobile;
  final VoidCallback onToggleAll;

  const _TableHeader({
    required this.selectAll,
    required this.isMobile,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: _cSurface,
        border: Border(bottom: BorderSide(color: _cBorder)),
      ),
      child: Row(children: [
        SizedBox(
          width: 36,
          child: Checkbox(
            value: selectAll,
            onChanged: (_) => onToggleAll(),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50)),
            activeColor: _cPurple,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        _th('CANDIDATE',      flex: 3),
        _th('EXPERIENCE',     flex: 2),
        _th('APPLIED',        flex: 2),
        _th('AI SCORE',       flex: 2),
        _th('STATUS',         flex: 1),
        const SizedBox(width: 8),
        const SizedBox(width: 56, child: _ThLabel('ACTIONS')),
      ]),
    );
  }

  Widget _th(String label, {int flex = 1}) =>
      Expanded(flex: flex, child: _ThLabel(label));
}

class _ThLabel extends StatelessWidget {
  final String text;
  const _ThLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _cTxtSec,
          letterSpacing: 0.4));
}

// ─────────────────────────────────────────────────────────────────────────────
// TABLE ROW
// ─────────────────────────────────────────────────────────────────────────────
class _TableRow extends StatelessWidget {
  final ApplicantRecord applicant;
  final int index;
  final bool isSelected;
  final bool isMobile;
  final String Function(String) maskEmail;
  final Color Function(int) scoreColor;
  final String Function(int) scoreLabel;
  final VoidCallback onToggle;
  final Future<void> Function(String) onStatusChange;
  final VoidCallback onViewDetails;
  final void Function(AIMatchResult) onShowScore;

  const _TableRow({
    required this.applicant,
    required this.index,
    required this.isSelected,
    required this.isMobile,
    required this.maskEmail,
    required this.scoreColor,
    required this.scoreLabel,
    required this.onToggle,
    required this.onStatusChange,
    required this.onViewDetails,
    required this.onShowScore,
  });

  static const _avatarColors = [
    Color(0xFF3B82F6), Color(0xFF8B5CF6),
    Color(0xFFEC4899), Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColors[index % _avatarColors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
        border: const Border(bottom: BorderSide(color: _cBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox
          SizedBox(
            width: 36,
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
              activeColor: _cPurple,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),

          // Candidate
          Expanded(
            flex: 3,
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    applicant.name.isNotEmpty
                        ? applicant.name.substring(0, 2).toUpperCase()
                        : 'NA',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: avatarColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(applicant.name,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _cTxt),
                          overflow: TextOverflow.ellipsis),
                      Text(maskEmail(applicant.email),
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: _cTxtSec),
                          overflow: TextOverflow.ellipsis),
                    ]),
              ),
            ]),
          ),

          // Experience
          Expanded(
            flex: 2,
            child: Text(
              '${applicant.experienceYears}y  ${applicant.professionalStatus}',
              style: GoogleFonts.poppins(fontSize: 12, color: _cTxtSec),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Applied date
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM d, yy').format(applicant.appliedAt),
              style: GoogleFonts.poppins(fontSize: 12, color: _cTxtSec),
            ),
          ),

          // AI Score
          Expanded(flex: 2, child: _ScoreCell(
            applicant: applicant,
            scoreColor: scoreColor,
            scoreLabel: scoreLabel,
            onShowScore: onShowScore,
          )),

          // Status
          Expanded(flex: 1, child: _StatusDropdown(
            applicant: applicant,
            onStatusChange: onStatusChange,
          )),

          const SizedBox(width: 8),

          // Actions
          SizedBox(
            width: 56,
            child: IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 17),
              onPressed: onViewDetails,
              tooltip: 'View Profile',
              color: _cTxtSec,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCORE CELL
// ─────────────────────────────────────────────────────────────────────────────
class _ScoreCell extends StatelessWidget {
  final ApplicantRecord applicant;
  final Color Function(int) scoreColor;
  final String Function(int) scoreLabel;
  final void Function(AIMatchResult) onShowScore;

  const _ScoreCell({
    required this.applicant,
    required this.scoreColor,
    required this.scoreLabel,
    required this.onShowScore,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (ctx) {
      final data = applicant.matchScore;
      final ai   = ctx.watch<AIMatchProvider>();
      final busy = ai.isProcessingApplicant(applicant.userId);

      if (busy) {
        return Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation(_cPurple)),
          ),
          const SizedBox(width: 6),
          Text('Analyzing…',
              style:
              GoogleFonts.poppins(fontSize: 11, color: _cTxtSec)),
        ]);
      }

      if (data == null || data['overallScore'] == null) {
        return Text('Not analyzed',
            style: GoogleFonts.poppins(
                fontSize: 11,
                color: _cTxtTert,
                fontStyle: FontStyle.italic));
      }

      final score  = data['overallScore'] as int;
      final color  = scoreColor(score);
      final label  = scoreLabel(score);

      final result = AIMatchResult(
        applicantId:      applicant.userId,
        applicantName:    applicant.name,
        overallScore:     score,
        skillsMatch:      data['skillsMatch']      as int? ?? 0,
        experienceMatch:  data['experienceMatch']  as int? ?? 0,
        educationMatch:   data['educationMatch']   as int? ?? 0,
        strengths:        List<String>.from(data['strengths']  ?? []),
        weaknesses:       List<String>.from(data['weaknesses'] ?? []),
        recommendation:   data['recommendation']?.toString() ?? 'N/A',
        detailedAnalysis: data['detailedAnalysis']?.toString() ?? '',
        timestamp:        DateTime.now(),
      );

      return GestureDetector(
        onTap: () => onShowScore(result),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Text('$score%',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const SizedBox(width: 5),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: color)),
            ]),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: _cBorder,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 5,
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────
class _StatusDropdown extends StatelessWidget {
  final ApplicantRecord applicant;
  final Future<void> Function(String) onStatusChange;

  const _StatusDropdown(
      {required this.applicant, required this.onStatusChange});

  static const _cfg = {
    'pending':   {'label': 'Pending',   'color': _cAmber,               'bg': Color(0xFFFEF3C7)},
    'shortlist': {'label': 'Shortlist', 'color': _cGreen,               'bg': Color(0xFFD1FAE5)},
    'rejected':  {'label': 'Rejected',  'color': Color(0xFF64748B),     'bg': Color(0xFFF1F5F9)},
  };

  @override
  Widget build(BuildContext context) {
    final s = applicant.status.toLowerCase();
    final cfg = _cfg[s] ?? {'label': 'Unknown', 'color': _cSlate, 'bg': _cSurface};
    final color = cfg['color'] as Color;
    final bg    = cfg['bg']    as Color;

    return PopupMenuButton<String>(
      onSelected: onStatusChange,
      itemBuilder: (_) => _cfg.entries.map((e) {
        final c = e.value['color'] as Color;
        return PopupMenuItem(
          value: e.key,
          child: Row(children: [
            Container(width: 7, height: 7,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(e.value['label'] as String,
                style: GoogleFonts.poppins(fontSize: 12)),
          ]),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(cfg['label'] as String,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_drop_down, size: 15, color: color),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _AIBadge extends StatelessWidget {
  final bool small;
  const _AIBadge({required this.small});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 10, vertical: 3),
    decoration: BoxDecoration(
      color: _cPurple.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _cPurple.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.auto_awesome, size: small ? 10 : 13, color: _cPurple),
      const SizedBox(width: 4),
      Text('AI Active',
          style: GoogleFonts.poppins(
              fontSize: small ? 9 : 11,
              fontWeight: FontWeight.w600,
              color: _cPurple)),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.08) : _cSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: active ? color.withOpacity(0.4) : _cBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: onTap == null ? _cTxtTert : _cTxt)),
        ),
        if (active)
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
      ]),
    ),
  );
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  const _ScoreRow({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? _cGreen
        : score >= 60 ? _cAccent
        : score >= 40 ? _cAmber
        : _cRed;
    return Row(children: [
      Expanded(flex: 2,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600))),
      Expanded(
        flex: 3,
        child: Row(children: [
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                  color: _cBorder,
                  borderRadius: BorderRadius.circular(4)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: score / 100,
                child: Container(
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$score%',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
      ),
    ]);
  }
}

class _SectionHead extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionHead(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 17),
    const SizedBox(width: 7),
    Text(label,
        style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700)),
  ]);
}

class _Bullet extends StatelessWidget {
  final String text;
  final Color color;
  const _Bullet(this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          margin: const EdgeInsets.only(top: 6),
          width: 5, height: 5,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 9),
      Expanded(
        child: Text(text,
            style: GoogleFonts.poppins(fontSize: 12, color: _cTxtSec)),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY RESULTS
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyResults extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyResults({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: _cSurface, shape: BoxShape.circle),
            child: const Icon(Icons.person_search_rounded,
                size: 54, color: _cTxtTert),
          ),
          const SizedBox(height: 18),
          Text('No applicants found',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B))),
          const SizedBox(height: 6),
          SizedBox(
            width: 280,
            child: Text(
              'Try adjusting your search or clearing filters.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: _cTxtSec),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_rounded, size: 16),
            label: Text('Clear filters',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _cPurple,
              side: const BorderSide(color: _cBorder),
              padding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}