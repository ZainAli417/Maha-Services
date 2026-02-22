import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'LIst_of_Applicants_provider.dart';
import 'R_Top_Bar.dart';

class RequestBoxScreen extends StatefulWidget {
  const RequestBoxScreen({super.key});

  @override
  State<RequestBoxScreen> createState() => _RequestBoxScreenState();
}

class _RequestBoxScreenState extends State<RequestBoxScreen> {
  // ─── Colors ───────────────────────────────────────────────────────────────
  static const _primary       = Color(0xFF6366F1);
  static const _textPrimary   = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _background    = Color(0xFFF8FAFC);
  static const _border        = Color(0xFFE2E8F0);
  static const _success       = Color(0xFF10B981);
  static const _warning       = Color(0xFFF59E0B);

  // ✅ Cached provider reference — safe to use in lifecycle hooks
  late ApplicantsProvider _provider;

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Cache here — always called before dispose, unlike initState for inherited widgets
    _provider = context.read<ApplicantsProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _provider.refresh();
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const RecruiterSidebar(activeIndex: 5),
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildHeader(),
                Expanded(
                  child: Consumer<ApplicantsProvider>(
                    // ✅ child: null — nothing static to hoist here, keep it simple
                    builder: (context, provider, _) {
                      final requests = provider.recruiterRequests;
                      if (requests.isEmpty) return _buildEmptyState();

                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: requests.length,
                        itemBuilder: (_, i) => _buildRequestCard(requests[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  // ✅ Extracted constants — avoids repeated Color allocation on every rebuild
  static const _kPrimaryBlue    = Color(0xFF1E40AF);
  static const _kHeaderTextPri  = Color(0xFF0F172A);
  static const _kHeaderTextSec  = Color(0xFF475569);

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.all_inbox_outlined, size: 24, color: _kPrimaryBlue),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Applicants Request Box',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _kHeaderTextPri,
                  height: 1.2,
                ),
              ),
              Text(
                'Manage & Onboard Applicants against Your Posted Jobs',
                style: GoogleFonts.poppins(fontSize: 13, color: _kHeaderTextSec, height: 1.2),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ─── Request Card ─────────────────────────────────────────────────────────
  Widget _buildRequestCard(Map<String, dynamic> request) {
    // ✅ Coerce date safely — avoids dynamic.toDate() crash if already DateTime
    final createdAt = _parseDate(request['created_at']);
    final status     = (request['status'] as String?) ?? 'pending';
    final candidates = (request['candidates'] as List?) ?? const [];
    final notes      = (request['notes'] as String?) ?? 'No notes provided';
    final requestId  = (request['request_id'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.send_rounded, color: _primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Candidate Submission Request',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
                          style: GoogleFonts.poppins(fontSize: 12, color: _textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildStatusBadge(status),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Message/Notes:',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary)),
                const SizedBox(height: 4),
                Text(notes,
                    style: GoogleFonts.poppins(fontSize: 14, color: _textPrimary)),
                const SizedBox(height: 20),
                Text('Candidates Sent (${candidates.length}):',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary)),
                const SizedBox(height: 12),
                _buildCandidatesGrid(candidates, requestId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Centralised safe date parser — handles Timestamp and DateTime alike
  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    try {
      return (raw as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  // ─── Status Badge ─────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    final color = _requestStatusColor(status.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Color _requestStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'accepted':
        return _success;
      case 'pending':
        return _warning;
      case 'rejected':
        return Colors.red;
      default:
        return _textSecondary;
    }
  }

  // ─── Candidates Grid ──────────────────────────────────────────────────────
  Widget _buildCandidatesGrid(List candidates, String requestId) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final c in candidates) _buildCandidateMiniCard(c, requestId),
      ],
    );
  }

  Widget _buildCandidateMiniCard(dynamic candidate, String requestId) {
    final name     = (candidate['name']      as String?) ?? 'Candidate';
    final email    = (candidate['email']     as String?) ?? '';
    final jobTitle = (candidate['job_title'] as String?) ?? 'N/A';
    final uid      = (candidate['uid']       as String?) ?? '';
    final status   = ((candidate['status']   as String?) ?? 'pending').toLowerCase();
    final isFinal  = status == 'hired' || status == 'rejected';

    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _primary.withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w700, color: _primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary),
                        overflow: TextOverflow.ellipsis),
                    Text(_obscureEmail(email),
                        style: GoogleFonts.poppins(fontSize: 10, color: _textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (isFinal)
                Icon(
                  status == 'hired' ? Icons.check_circle : Icons.cancel,
                  color: status == 'hired' ? _success : Colors.red,
                  size: 18,
                )
              else
              // ✅ Extracted to named widget — avoids rebuilding closure captures on every frame
                _CandidateActionMenu(
                  requestId: requestId,
                  candidateUid: uid,
                  currentStatus: status,
                  onStatusSelected: _onCandidateStatusChanged,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(jobTitle,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: _primary, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _candidateStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _candidateStatusColor(status)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Callback extracted — avoids creating async closures inside build()
  Future<void> _onCandidateStatusChanged({
    required String requestId,
    required String candidateUid,
    required String status,
    required String currentStatus,
  }) async {
    if (currentStatus.toLowerCase() != 'handover') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Candidates can only be Hired or Rejected after Admin Handover'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ok = await _provider.updateCandidateStatus(
      requestId: requestId,
      candidateUid: candidateUid,
      status: status,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Candidate marked as $status')),
      );
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Color _candidateStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'shortlist':
        return const Color(0xFF6366F1);
      case 'screening':
        return const Color(0xFF3B82F6);
      case 'interview':
        return const Color(0xFF8B5CF6);
      case 'technical':
        return const Color(0xFF06B6D4);
      case 'offer':
        return const Color(0xFFF59E0B);
      case 'handover':
      case 'hired':
        return const Color(0xFF10B981);
      case 'rejected':
        return Colors.red;
      default:
        return _textSecondary;
    }
  }

  String _obscureEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return '****';
    final user = parts[0];
    return '${user.length > 2 ? user.substring(0, 2) : '**'}****@${parts[1]}';
  }

  // ─── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 80, color: _border),
          const SizedBox(height: 20),
          Text('No requests yet',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600, color: _textSecondary)),
          const SizedBox(height: 8),
          Text(
            'Your candidate submission requests will appear here',
            style: GoogleFonts.poppins(
                fontSize: 14, color: Color.fromARGB(178, 100, 116, 139)),
          ),
        ],
      ),
    );
  }
}

// ─── Extracted menu widget ────────────────────────────────────────────────────
// ✅ Prevents async closure captures from being re-created inside build() loops,
//    and gives the PopupMenuButton a stable widget identity across list rebuilds.
class _CandidateActionMenu extends StatelessWidget {
  const _CandidateActionMenu({
    required this.requestId,
    required this.candidateUid,
    required this.currentStatus,
    required this.onStatusSelected,
  });

  final String requestId;
  final String candidateUid;
  final String currentStatus;
  final Future<void> Function({
  required String requestId,
  required String candidateUid,
  required String status,
  required String currentStatus,
  }) onStatusSelected;

  static const _success = Color(0xFF10B981);
  static const _textSecondary = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 18, color: _textSecondary),
      onSelected: (val) => onStatusSelected(
        requestId: requestId,
        candidateUid: candidateUid,
        status: val,
        currentStatus: currentStatus,
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'hired',
          child: Row(children: [
            const Icon(Icons.check_circle, color: _success, size: 18),
            const SizedBox(width: 8),
            const Text('Mark as Hired'),
          ]),
        ),
        PopupMenuItem(
          value: 'rejected',
          child: Row(children: [
            const Icon(Icons.cancel, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            const Text('Mark as Rejected'),
          ]),
        ),
      ],
    );
  }
}