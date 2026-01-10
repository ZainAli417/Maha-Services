


// admin_dashboard_ui.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:job_portal/Web_routes.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_provider.dart';

class AdminDashboardScreen2 extends StatelessWidget {
  const AdminDashboardScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: const _AdminDashboardBody(),
      ),
    );
  }
}

class _AdminDashboardBody extends StatefulWidget {
  const _AdminDashboardBody();

  @override
  State<_AdminDashboardBody> createState() => _AdminDashboardBodyState();
}

class _AdminDashboardBodyState extends State<_AdminDashboardBody> {
  String? _selectedRequestId;
  Map<String, dynamic>? _selectedRequestDetails;
  bool _loadingDetails = false;

  Map<String, dynamic> _normalizeMap(dynamic m) {
    return AdminProvider.normalizeMapStatic(m);
  }

  Future<void> _openDetails(BuildContext context, String requestId) async {
    setState(() {
      _selectedRequestId = requestId;
      _selectedRequestDetails = null;
      _loadingDetails = true;
    });

    final prov = Provider.of<AdminProvider>(context, listen: false);
    final details = await prov.fetchRequestDetails(requestId: requestId);
    if (mounted) {
      setState(() {
        _selectedRequestDetails = details;
        _loadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AdminProvider>(context);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        _buildModernHeader(context, prov),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  flex: isWide ? 3 : 1,
                  child: _buildRequestsList(context, prov, isWide),
                ),
                if (isWide) const SizedBox(width: 24),
                if (isWide)
                  Expanded(
                    flex: 5,
                    child: _buildDetailsSection(context, prov),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernHeader(BuildContext context, AdminProvider prov) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Manage & Monitor Requests',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _HeaderButton(
                onPressed: () => prov.fetchAllRequests(realtime: true),
                icon: Icons.wifi,
                tooltip: 'Enable realtime',
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                onPressed: () => prov.refresh(),
                icon: Icons.refresh,
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                onPressed: () => prov.clearCaches(),
                icon: Icons.cleaning_services_outlined,
                tooltip: 'Clear caches',
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                onPressed: () async {
                  try {
                    // Clear role cache only (profile is stream-based now)
                    //RoleService.clear();

                    // Sign out (this triggers AuthNotifier + GoRouter automatically)
                    await FirebaseAuth.instance.signOut();

                    // Optional: force navigation for immediate UX
                    if (context.mounted) {
                      context.go('/');
                    }
                  } catch (e) {
                    debugPrint('Logout error: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error signing out. Please try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: Icons.logout,
                tooltip: 'Sign Out',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(BuildContext context, AdminProvider prov, bool isWide) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.list_alt, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'All Requests',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              if (prov.loading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Syncing',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6366F1),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: prov.requests.isEmpty
                ? Center(
              child: prov.loading
                  ? const CircularProgressIndicator()
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No requests found',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Requests will appear here',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = _normalizeMap(prov.requests[index]);
                final id = r['id']?.toString() ?? '';
                final recruiterId = r['recruiter_id']?.toString() ?? '';
                final recruiterEmail = r['recruiter_email']?.toString() ?? '';
                final total = r['total_candidates'] ?? 0;
                final status = r['status']?.toString() ?? 'unknown';
                final createdAt = r['created_at'];
                final createdStr = createdAt is Timestamp
                    ? DateFormat.yMMMd().add_Hm().format(createdAt.toDate())
                    : (createdAt?.toString() ?? '-');

                return _RequestCard(
                  id: id,
                  recruiterEmail: recruiterEmail,
                  recruiterId: recruiterId,
                  totalCandidates: total,
                  status: status,
                  createdStr: createdStr,
                  isSelected: id == _selectedRequestId,
                  onTap: () {
                    if (isWide) {
                      _openDetails(context, id);
                    } else {
                      _showRequestDetailsModal(context, prov, id);
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, AdminProvider prov) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _loadingDetails
          ? const Center(child: CircularProgressIndicator())
          : (_selectedRequestId == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.touch_app,
                size: 48,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select a request',
              style: GoogleFonts.inter(
                color: const Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click on any request to view details',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          : (_selectedRequestDetails == null
          ? const Center(child: Text('No details loaded'))
          : _buildDetailsPanel(context, prov, _selectedRequestDetails!))),
    );
  }

  Widget _buildDetailsPanel(BuildContext context, AdminProvider prov, Map<String, dynamic> details) {
    final requestDoc = _normalizeMap(details['request_doc']);
    final recruiter = _normalizeMap(details['recruiter']);
    final rawCandidates = (details['candidates'] as List<dynamic>?)?.cast<dynamic>() ?? [];

    final reqData = _normalizeMap(requestDoc['data']);
    final reqId = requestDoc['id']?.toString() ?? '-';
    final status = reqData['status']?.toString() ?? 'pending';
    final notes = reqData['notes']?.toString() ?? '';
    final createdAt = reqData['created_at'];
    final createdStr = createdAt is Timestamp
        ? DateFormat.yMMMd().add_Hm().format(createdAt.toDate())
        : (createdAt?.toString() ?? '-');

    final recruiterData = _normalizeMap(recruiter['data']);
    final recruiterId = recruiter['id']?.toString() ?? '-';
    final recruiterName = recruiterData['name']?.toString() ?? recruiterId;
    final recruiterEmail = recruiterData['email']?.toString() ?? '-';
    final recruiterCompany = recruiterData['company']?.toString() ?? '';

    String canon(String s) => s.trim().toLowerCase();

    final Map<String, Map<String, dynamic>> uniqueByUid = {};
    final List<String> uidOrder = [];

    for (final c in rawCandidates) {
      final candidateData = _normalizeMap(c);
      String uid = candidateData['uid']?.toString() ?? '';
      final display = _normalizeMap(candidateData['display']);
      final profile = _normalizeMap(candidateData['profile']);
      if (uid.trim().isEmpty) {
        final emailFallback = (display['email'] ?? profile['email'] ?? '').toString().trim();
        if (emailFallback.isNotEmpty) {
          uid = 'email:$emailFallback';
        }
      }

      uid = uid.trim();
      if (uid.isEmpty || uid == '-' || uid == 'null') {
        continue;
      }

      final canonUid = canon(uid);

      if (!uniqueByUid.containsKey(canonUid)) {
        uniqueByUid[canonUid] = {
          'uid': uid,
          'display': display,
          'profile': profile,
          'basic': candidateData['basic'] ?? candidateData,
        };
        uidOrder.add(canonUid);
      } else {
        final existing = uniqueByUid[canonUid]!;
        final existingDisplay = _normalizeMap(existing['display']);
        final incomingDisplay = display;
        incomingDisplay.forEach((k, v) {
          if ((existingDisplay[k] == null || existingDisplay[k].toString().trim().isEmpty) &&
              v != null &&
              v.toString().trim().isNotEmpty) {
            existingDisplay[k] = v;
          }
        });
        existing['display'] = existingDisplay;

        final existingProfile = _normalizeMap(existing['profile']);
        final incomingProfile = profile;
        incomingProfile.forEach((k, v) {
          if ((existingProfile[k] == null || existingProfile[k].toString().trim().isEmpty) &&
              v != null &&
              v.toString().trim().isNotEmpty) {
            existingProfile[k] = v;
          }
        });
        existing['profile'] = existingProfile;

        uniqueByUid[canonUid] = existing;
      }
    }

    final List<Map<String, dynamic>> candidates = uidOrder.map((k) => uniqueByUid[k]!).toList();

    final candidateStatusRaw = _normalizeMap(reqData['candidate_statuses']);
    final Map<String, String> candidateStatusNormalized = {};
    candidateStatusRaw.forEach((k, v) {
      final key = k.toString() ?? '';
      if (key.isNotEmpty) candidateStatusNormalized[canon(key)] = v?.toString() ?? '';
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_outlined, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Details',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '#$reqId',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              _ModernStatusDropdown(
                currentStatus: status,
                onChanged: (newStatus) async {
                  final ok = await prov.updateRequestStatus(
                    requestId: reqId,
                    newStatus: newStatus,
                    performedBy: 'admin_dashboard',
                  );
                  if (ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status changed to $newStatus'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    final updated = await prov.fetchRequestDetails(requestId: reqId);
                    if (mounted) setState(() => _selectedRequestDetails = updated);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _MetadataChip(
                  icon: Icons.calendar_today,
                  label: 'Created',
                  value: createdStr,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetadataChip(
                  icon: Icons.people_outline,
                  label: 'Candidates',
                  value: candidates.length.toString(),
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.badge_outlined, color: Color(0xFFF59E0B), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Recruiter Information',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    recruiterName.isNotEmpty ? recruiterName.substring(0, 1).toUpperCase() : 'R',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recruiterName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            recruiterEmail,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (recruiterCompany.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.business_outlined, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              recruiterCompany,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.note_outlined, color: Color(0xFF64748B), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notes,
              style: GoogleFonts.inter(
                color: const Color(0xFF475569),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people_outline, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Candidates (${candidates.length})',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...candidates.map((c) {
            final candidateUidRaw = c['uid']?.toString() ?? '';
            final canonUid = canon(candidateUidRaw);
            final display = _normalizeMap(c['display']);
            final profile = _normalizeMap(c['profile']);

            final name = display['name']?.toString() ?? profile['name']?.toString() ?? candidateUidRaw;
            final email = display['email']?.toString() ?? profile['email']?.toString() ?? '';

            final candidateStatus = candidateStatusNormalized[canonUid] ?? 'unknown';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CandidateCard(
                name: name,
                email: email,
                status: candidateStatus,
                onMenuAction: (action) async {
                  if (action == 'open_cv') {
                    final cv = profile['cv']?.toString() ??
                        profile['cv_url']?.toString() ??
                        profile['resume_url']?.toString() ?? '';
                    if (cv.isNotEmpty && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('CV URL: $cv')),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No CV link')),
                      );
                    }
                  } else {
                    final ok = await prov.updateCandidateStatus(
                      requestId: reqId,
                      candidateUid: candidateUidRaw,
                      status: action,
                      performedBy: 'admin_dashboard',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? 'Updated to $action' : 'Failed')),
                      );
                    }
                    if (ok && mounted) {
                      final updated = await prov.fetchRequestDetails(requestId: reqId);
                      if (mounted) setState(() => _selectedRequestDetails = updated);
                    }
                  }
                },
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: $email', style: GoogleFonts.inter(fontSize: 13)),
                            const SizedBox(height: 16),
                            Text(
                              'Profile snapshot:',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            ..._profileMapToWidgets(profile),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close', style: GoogleFonts.inter(color: const Color(0xFF6366F1))),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showRequestDetailsModal(BuildContext context, AdminProvider prov, String requestId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: prov.fetchRequestDetails(requestId: requestId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            final details = snap.data;
            if (details == null) {
              return Container(
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(child: Text('Failed to load details')),
              );
            }

            final requestDoc = _normalizeMap(details['request_doc']);
            final recruiter = _normalizeMap(details['recruiter']);
            final reqData = _normalizeMap(requestDoc['data']);
            final recruiterData = _normalizeMap(recruiter['data']);
            final candidates = (details['candidates'] as List<dynamic>?)?.cast<dynamic>() ?? [];

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.description_outlined, color: Color(0xFF6366F1), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Request Details',
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            'ID: ${requestDoc['id']?.toString() ?? '-'}',
                            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _InfoCard(
                        title: 'Recruiter',
                        subtitle: recruiterData['name']?.toString() ?? recruiter['id']?.toString() ?? '-',
                        trailing: recruiterData['email']?.toString() ?? '-',
                        icon: Icons.person_outline,
                        colors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: 'Request Status',
                        subtitle: reqData['status']?.toString() ?? '-',
                        trailing: 'Total: ${reqData['total_candidates']?.toString() ?? '0'}',
                        icon: Icons.info_outline,
                        colors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Candidates',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ...candidates.map((c) {
                        final m = _normalizeMap(c);
                        final uid = m['uid']?.toString() ?? '-';
                        final profile = _normalizeMap(m['profile']);
                        final display = _normalizeMap(m['display']);
                        final name = display['name']?.toString() ?? profile['name']?.toString() ?? uid;
                        final email = display['email']?.toString() ?? profile['email']?.toString() ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF6366F1),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text(email, style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) async {
                                  if (action == 'open_cv') {
                                    final cv = profile['cv']?.toString() ?? profile['cv_url']?.toString() ?? '';
                                    if (cv.isNotEmpty) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Open CV: $cv')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('No CV link')),
                                      );
                                    }
                                  } else {
                                    await prov.updateCandidateStatus(
                                      requestId: requestId,
                                      candidateUid: uid,
                                      status: action,
                                      performedBy: 'admin',
                                    );
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Set $uid -> $action')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.more_vert, size: 20),
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'open_cv', child: Text('Open CV')),
                                  const PopupMenuItem(value: 'interview', child: Text('Mark Interview')),
                                  const PopupMenuItem(value: 'accepted', child: Text('Accept')),
                                  const PopupMenuItem(value: 'rejected', child: Text('Reject')),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Widget> _profileMapToWidgets(Map<String, dynamic> profile) {
    if (profile.isEmpty) return [Text('- no profile data -', style: GoogleFonts.inter(fontSize: 13))];
    final entries = profile.entries.toList();
    return entries.map((e) {
      final v = e.value;
      final display = (v is String && v.length > 200) ? '${v.substring(0, 200)}...' : v.toString();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '${e.key}:',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(display, style: GoogleFonts.inter(fontSize: 13))),
          ],
        ),
      );
    }).toList();
  }
}

class _HeaderButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  const _HeaderButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF475569), size: 20),
          ),
        ),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String id;
  final String recruiterEmail;
  final String recruiterId;
  final int totalCandidates;
  final String status;
  final String createdStr;
  final bool isSelected;
  final VoidCallback onTap;

  const _RequestCard({
    required this.id,
    required this.recruiterEmail,
    required this.recruiterId,
    required this.totalCandidates,
    required this.status,
    required this.createdStr,
    required this.isSelected,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'in_review':
        return const Color(0xFF3B82F6);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'closed':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.08) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1).withOpacity(0.3) : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    totalCandidates.toString(),
                    style: GoogleFonts.inter(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request #$id',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recruiterEmail.isNotEmpty ? recruiterEmail : recruiterId,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: const Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            createdStr,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getStatusColor().withOpacity(0.2)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    color: _getStatusColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _CandidateCard extends StatelessWidget {
  final String name;
  final String email;
  final String status;
  final Function(String) onMenuAction;
  final VoidCallback onTap;

  const _CandidateCard({
    required this.name,
    required this.email,
    required this.status,
    required this.onMenuAction,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'interview':
        return const Color(0xFF3B82F6);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C',
                    style: GoogleFonts.inter(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (status != 'unknown')
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.inter(
                              color: _getStatusColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onMenuAction,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.more_vert, size: 18, color: Color(0xFF64748B)),
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'open_cv',
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 18, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 10),
                        Text('Open CV', style: GoogleFonts.inter(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'interview',
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined, size: 18, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 10),
                        Text('Mark Interview', style: GoogleFonts.inter(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'accepted',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 10),
                        Text('Accept', style: GoogleFonts.inter(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'rejected',
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFEF4444)),
                        const SizedBox(width: 10),
                        Text('Reject', style: GoogleFonts.inter(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernStatusDropdown extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onChanged;

  const _ModernStatusDropdown({
    required this.currentStatus,
    required this.onChanged,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'in_review':
        return const Color(0xFF3B82F6);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'closed':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    const statuses = ['pending', 'in_review', 'accepted', 'rejected', 'closed'];
    final effectiveStatus = statuses.contains(currentStatus) ? currentStatus : 'pending';
    final statusColor = _getStatusColor(effectiveStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: DropdownButton<String>(
        value: effectiveStatus,
        underline: const SizedBox(),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: statusColor),
        style: GoogleFonts.inter(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        items: statuses.map((s) {
          final color = _getStatusColor(s);
          return DropdownMenuItem(
            value: s,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(s, style: GoogleFonts.inter(color: color, fontSize: 12)),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final List<Color> colors;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.first.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.first.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.first.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: colors.first, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}





/*


// admin_dashboard_ui.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:job_portal/Web_routes.dart';
import 'package:provider/provider.dart';

import 'admin_provider.dart';

class AdminDashboardScreen2 extends StatelessWidget {
  const AdminDashboardScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: const _AdminDashboardBody(),
      ),
    );
  }
}

class _AdminDashboardBody extends StatefulWidget {
  const _AdminDashboardBody();

  @override
  State<_AdminDashboardBody> createState() => _AdminDashboardBodyState();
}

class _AdminDashboardBodyState extends State<_AdminDashboardBody> {
  String? _selectedRequestId;
  Map<String, dynamic>? _selectedRequestDetails;
  bool _loadingDetails = false;

  Map<String, dynamic> _normalizeMap(dynamic m) {
    return AdminProvider.normalizeMapStatic(m);
  }

  Future<void> _openDetails(BuildContext context, String requestId) async {
    setState(() {
      _selectedRequestId = requestId;
      _selectedRequestDetails = null;
      _loadingDetails = true;
    });

    final prov = Provider.of<AdminProvider>(context, listen: false);
    final details = await prov.fetchRequestDetails(requestId: requestId);
    if (mounted) {
      setState(() {
        _selectedRequestDetails = details;
        _loadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AdminProvider>(context);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // Enhanced Modern Header
        _buildModernHeader(context, prov),

        // Stats Cards Row
       // _buildStatsSection(prov),

        // Main Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
            child: Row(
              children: [
                // Left: Requests list
                Expanded(
                  flex: isWide ? 3 : 1,
                  child: _buildRequestsList(context, prov, isWide),
                ),

                if (isWide) const SizedBox(width: 20),

                // Right: Details panel (only for wide screens)
                if (isWide)
                  Expanded(
                    flex: 5,
                    child: _buildDetailsSection(context, prov),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernHeader(BuildContext context, AdminProvider prov) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Logo & Actions
              Row(
                children: [
                  // Logo Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title Section
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage & Monitor Requests',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  Row(
                    children: [
                      _ModernHeaderButton(
                        onPressed: () => prov.fetchAllRequests(realtime: true),
                        icon: Icons.wifi_rounded,
                        tooltip: 'Enable realtime',
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      _ModernHeaderButton(
                        onPressed: () => prov.refresh(),
                        icon: Icons.refresh_rounded,
                        tooltip: 'Refresh',
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      _ModernHeaderButton(
                        onPressed: () => prov.clearCaches(),
                        icon: Icons.cleaning_services_rounded,
                        tooltip: 'Clear caches',
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),


                      _ModernHeaderButton(
                        onPressed: () async {
                          try {
                            // Clear all caches before logout
                            RoleService.clearCache();
                            ProfileCheckService.clearCache();
                            // Sign out from Firebase
                            await FirebaseAuth.instance.signOut();

                            // Navigate to home
                            if (context.mounted) {
                              context.go('/'); // Use context.go instead of router.pushReplacement
                            }
                          } catch (e) {
                            debugPrint('Logout error: $e');
                            // Optionally show error to user
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error signing out. Please try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icons.logout_rounded,
                        tooltip: 'Sign Out',
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),

                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Search Bar & Filters
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(AdminProvider prov) {
    final total = prov.requests.length;
    final pending = prov.requests.where((r) {
      final m = _normalizeMap(r);
      return m['status']?.toString() == 'pending';
    }).length;
    final inReview = prov.requests.where((r) {
      final m = _normalizeMap(r);
      return m['status']?.toString() == 'in_review';
    }).length;
    final completed = prov.requests.where((r) {
      final m = _normalizeMap(r);
      final status = m['status']?.toString() ?? '';
      return status == 'accepted' || status == 'closed';
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Total Requests',
              value: total.toString(),
              icon: Icons.assignment_rounded,
              gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Pending',
              value: pending.toString(),
              icon: Icons.pending_actions_rounded,
              gradient: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'In Review',
              value: inReview.toString(),
              icon: Icons.rate_review_rounded,
              gradient: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Completed',
              value: completed.toString(),
              icon: Icons.check_circle_rounded,
              gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(BuildContext context, AdminProvider prov, bool isWide) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // List Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xff5C738A)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.list_alt_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'All Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                if (prov.loading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Syncing',
                          style: TextStyle(
                            color: Color(0xFF6366F1),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // List Content
          Expanded(
            child: prov.requests.isEmpty
                ? Center(
              child: prov.loading
                  ? const CircularProgressIndicator()
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inbox_outlined,
                      size: 56,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No requests found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Requests will appear here',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = _normalizeMap(prov.requests[index]);
                final id = r['id']?.toString() ?? '';
                final recruiterId = r['recruiter_id']?.toString() ?? '';
                final recruiterEmail = r['recruiter_email']?.toString() ?? '';
                final total = r['total_candidates'] ?? 0;
                final status = r['status']?.toString() ?? 'unknown';
                final createdAt = r['created_at'];
                final createdStr = createdAt is Timestamp
                    ? DateFormat.yMMMd().add_Hm().format(createdAt.toDate())
                    : (createdAt?.toString() ?? '-');

                return _RequestCard(
                  id: id,
                  recruiterEmail: recruiterEmail,
                  recruiterId: recruiterId,
                  totalCandidates: total,
                  status: status,
                  createdStr: createdStr,
                  isSelected: id == _selectedRequestId,
                  onTap: () {
                    if (isWide) {
                      _openDetails(context, id);
                    } else {
                      _showRequestDetailsModal(context, prov, id);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, AdminProvider prov) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _loadingDetails
          ? const Center(child: CircularProgressIndicator())
          : (_selectedRequestId == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.1),
                    const Color(0xFF8B5CF6).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                size: 56,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select a request',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click on any request to view details',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          : (_selectedRequestDetails == null
          ? const Center(child: Text('No details loaded'))
          : _buildDetailsPanel(context, prov, _selectedRequestDetails!))),
    );
  }

  Widget _buildDetailsPanel(BuildContext context, AdminProvider prov, Map<String, dynamic> details) {
    final requestDoc = _normalizeMap(details['request_doc']);
    final recruiter = _normalizeMap(details['recruiter']);
    final rawCandidates = (details['candidates'] as List<dynamic>?)?.cast<dynamic>() ?? [];

    final reqData = _normalizeMap(requestDoc['data']);
    final reqId = requestDoc['id']?.toString() ?? '-';
    final status = reqData['status']?.toString() ?? 'pending';
    final notes = reqData['notes']?.toString() ?? '';
    final createdAt = reqData['created_at'];
    final createdStr = createdAt is Timestamp
        ? DateFormat.yMMMd().add_Hm().format(createdAt.toDate())
        : (createdAt?.toString() ?? '-');

    final recruiterData = _normalizeMap(recruiter['data']);
    final recruiterId = recruiter['id']?.toString() ?? '-';
    final recruiterName = recruiterData['name']?.toString() ?? recruiterId;
    final recruiterEmail = recruiterData['email']?.toString() ?? '-';
    final recruiterCompany = recruiterData['company']?.toString() ?? '';

    // local canon function to match provider canonicalization
    String canon(String s) => s.trim().toLowerCase();

    // ----- Deduplicate & filter empty candidate rows -----
    final Map<String, Map<String, dynamic>> uniqueByUid = {};
    final List<String> uidOrder = [];

    for (final c in rawCandidates) {
      final candidateData = _normalizeMap(c);
      // prefer explicit uid field
      String uid = candidateData['uid']?.toString() ?? '';
      // fallback to display/email if no uid present
      final display = _normalizeMap(candidateData['display']);
      final profile = _normalizeMap(candidateData['profile']);
      if (uid.trim().isEmpty) {
        final emailFallback = (display['email'] ?? profile['email'] ?? '').toString().trim();
        if (emailFallback.isNotEmpty) {
          uid = 'email:$emailFallback';
        }
      }

      uid = uid.trim();
      if (uid.isEmpty || uid == '-' || uid == 'null') {
        // skip rows with no meaningful id
        continue;
      }

      final canonUid = canon(uid);

      if (!uniqueByUid.containsKey(canonUid)) {
        // store a normalized candidate entry
        uniqueByUid[canonUid] = {
          'uid': uid,
          'display': display,
          'profile': profile,
          'basic': candidateData['basic'] ?? candidateData,
        };
        uidOrder.add(canonUid);
      } else {
        // merge missing fields (prefer existing)
        final existing = uniqueByUid[canonUid]!;
        final existingDisplay = _normalizeMap(existing['display']);
        final incomingDisplay = display;
        incomingDisplay.forEach((k, v) {
          if ((existingDisplay[k] == null || existingDisplay[k].toString().trim().isEmpty) &&
              v != null &&
              v.toString().trim().isNotEmpty) {
            existingDisplay[k] = v;
          }
        });
        existing['display'] = existingDisplay;

        final existingProfile = _normalizeMap(existing['profile']);
        final incomingProfile = profile;
        incomingProfile.forEach((k, v) {
          if ((existingProfile[k] == null || existingProfile[k].toString().trim().isEmpty) &&
              v != null &&
              v.toString().trim().isNotEmpty) {
            existingProfile[k] = v;
          }
        });
        existing['profile'] = existingProfile;

        uniqueByUid[canonUid] = existing;
      }
    }

    // Build ordered list of deduped candidates
    final List<Map<String, dynamic>> candidates = uidOrder.map((k) => uniqueByUid[k]!).toList();

    // Normalize candidate_statuses keys for reliable lookup
    final candidateStatusRaw = _normalizeMap(reqData['candidate_statuses']);
    final Map<String, String> candidateStatusNormalized = {};
    candidateStatusRaw.forEach((k, v) {
      final key = k.toString() ?? '';
      if (key.isNotEmpty) candidateStatusNormalized[canon(key)] = v?.toString() ?? '';
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with ID and Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request Details',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#$reqId',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              _ModernStatusDropdown(
                currentStatus: status,
                onChanged: (newStatus) async {
                  final ok = await prov.updateRequestStatus(
                    requestId: reqId,
                    newStatus: newStatus,
                    performedBy: 'admin_dashboard',
                  );
                  if (ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Status changed to $newStatus'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    final updated = await prov.fetchRequestDetails(requestId: reqId);
                    if (mounted) setState(() => _selectedRequestDetails = updated);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Metadata Row - use deduped candidates length
          Row(
            children: [
              Expanded(
                child: _MetadataChip(
                  icon: Icons.calendar_today_rounded,
                  label: 'Created',
                  value: createdStr,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetadataChip(
                  icon: Icons.people_rounded,
                  label: 'Candidates',
                  value: candidates.length.toString(),
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Recruiter Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFEF3C7).withOpacity(0.4),
                  const Color(0xFFFDE68A).withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_rounded, color: Color(0xFFF59E0B), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Recruiter Information',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          recruiterName.isNotEmpty ? recruiterName.substring(0, 1).toUpperCase() : 'R',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recruiterName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email_rounded, size: 13, color: Color(0xFF78716C)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  recruiterEmail,
                                  style: const TextStyle(
                                    color: Color(0xFF78716C),
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (recruiterCompany.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.business_rounded, size: 13, color: Color(0xFF78716C)),
                                  const SizedBox(width: 6),
                                  Text(
                                    recruiterCompany,
                                    style: const TextStyle(
                                      color: Color(0xFF78716C),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Notes Section
          if (notes.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.note_alt_rounded, color: Color(0xFF8B5CF6), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    notes,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          if (notes.isNotEmpty) const SizedBox(height: 20),

          // Candidates Section (use deduped list)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.people_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Candidates (${candidates.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...candidates.map((c) {
                final candidateUidRaw = c['uid']?.toString() ?? '';
                final canonUid = canon(candidateUidRaw);
                final display = _normalizeMap(c['display']);
                final profile = _normalizeMap(c['profile']);

                final name = display['name']?.toString() ?? profile['name']?.toString() ?? candidateUidRaw;
                final email = display['email']?.toString() ?? profile['email']?.toString() ?? '';

                final candidateStatus = candidateStatusNormalized[canonUid] ?? 'unknown';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CandidateCard(
                    name: name,
                    email: email,
                    status: candidateStatus,
                    onMenuAction: (action) async {
                      if (action == 'open_cv') {
                        final cv = profile['cv']?.toString() ??
                            profile['cv_url']?.toString() ??
                            profile['resume_url']?.toString() ?? '';
                        if (cv.isNotEmpty && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('CV URL: $cv')),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No CV link')),
                          );
                        }
                      } else {
                        final ok = await prov.updateCandidateStatus(
                          requestId: reqId,
                          candidateUid: candidateUidRaw,
                          status: action,
                          performedBy: 'admin_dashboard',
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Updated to $action' : 'Failed')),
                          );
                        }
                        if (ok && mounted) {
                          final updated = await prov.fetchRequestDetails(requestId: reqId);
                          if (mounted) setState(() => _selectedRequestDetails = updated);
                        }
                      }
                    },
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text(name),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Email: $email'),
                                const SizedBox(height: 16),
                                const Text(
                                  'Profile snapshot:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ..._profileMapToWidgets(profile),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }









  void _showRequestDetailsModal(BuildContext context, AdminProvider prov, String requestId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: prov.fetchRequestDetails(requestId: requestId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            final details = snap.data;
            if (details == null) {
              return Container(
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(child: Text('Failed to load details')),
              );
            }

            final requestDoc = _normalizeMap(details['request_doc']);
            final recruiter = _normalizeMap(details['recruiter']);
            final reqData = _normalizeMap(requestDoc['data']);
            final recruiterData = _normalizeMap(recruiter['data']);
            final candidates = (details['candidates'] as List<dynamic>?)?.cast<dynamic>() ?? [];

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.description, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Request Details',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            'ID: ${requestDoc['id']?.toString() ?? '-'}',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _InfoCard(
                        title: 'Recruiter',
                        subtitle: recruiterData['name']?.toString() ?? recruiter['id']?.toString() ?? '-',
                        trailing: recruiterData['email']?.toString() ?? '-',
                        icon: Icons.person,
                        colors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: 'Request Status',
                        subtitle: reqData['status']?.toString() ?? '-',
                        trailing: 'Total: ${reqData['total_candidates']?.toString() ?? '0'}',
                        icon: Icons.info,
                        colors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Candidates',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...candidates.map((c) {
                        final m = _normalizeMap(c);
                        final uid = m['uid']?.toString() ?? '-';
                        final profile = _normalizeMap(m['profile']);
                        final display = _normalizeMap(m['display']);
                        final name = display['name']?.toString() ?? profile['name']?.toString() ?? uid;
                        final email = display['email']?.toString() ?? profile['email']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text(email),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) async {
                                if (action == 'open_cv') {
                                  final cv = profile['cv']?.toString() ??
                                      profile['cv_url']?.toString() ?? '';
                                  if (cv.isNotEmpty) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Open CV: $cv')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No CV link')),
                                    );
                                  }
                                } else {
                                  await prov.updateCandidateStatus(
                                    requestId: requestId,
                                    candidateUid: uid,
                                    status: action,
                                    performedBy: 'admin',
                                  );
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Set $uid -> $action')),
                                  );
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'open_cv', child: Text('Open CV')),
                                const PopupMenuItem(value: 'interview', child: Text('Mark Interview')),
                                const PopupMenuItem(value: 'accepted', child: Text('Accept')),
                                const PopupMenuItem(value: 'rejected', child: Text('Reject')),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<Widget> _profileMapToWidgets(Map<String, dynamic> profile) {
    if (profile.isEmpty) return [const Text('- no profile data -')];
    final entries = profile.entries.toList();
    return entries.map((e) {
      final v = e.value;
      final display = (v is String && v.length > 200)
          ? '${v.substring(0, 200)}...'
          : v.toString();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                '${e.key}:',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(display)),
          ],
        ),
      );
    }).toList();
  }
}

// Modern Header Button
class _ModernHeaderButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color backgroundColor;

  const _ModernHeaderButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: gradient.first,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Metadata Chip Widget
class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Request Card Widget
class _RequestCard extends StatelessWidget {
  final String id;
  final String recruiterEmail;
  final String recruiterId;
  final int totalCandidates;
  final String status;
  final String createdStr;
  final bool isSelected;
  final VoidCallback onTap;

  const _RequestCard({
    required this.id,
    required this.recruiterEmail,
    required this.recruiterId,
    required this.totalCandidates,
    required this.status,
    required this.createdStr,
    required this.isSelected,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'in_review':
        return const Color(0xFF3B82F6);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'closed':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(0.08),
                const Color(0xFF8B5CF6).withOpacity(0.08),
              ],
            )
                : null,
            color: isSelected ? null : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_getStatusColor(), _getStatusColor().withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor().withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    totalCandidates.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request #$id',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recruiterEmail.isNotEmpty ? recruiterEmail : recruiterId,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            createdStr,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatusColor().withOpacity(0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
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

// Candidate Card Widget
class _CandidateCard extends StatelessWidget {
  final String name;
  final String email;
  final String status;
  final Function(String) onMenuAction;
  final VoidCallback onTap;

  const _CandidateCard({
    required this.name,
    required this.email,
    required this.status,
    required this.onMenuAction,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'interview':
        return const Color(0xFF3B82F6);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xff5C738A)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_getStatusColor(), _getStatusColor().withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor().withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (status != 'unknown')
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onMenuAction,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'open_cv',
                    child: Row(
                      children: [
                        Icon(Icons.description_rounded, size: 18, color: Color(0xFF8B5CF6)),
                        SizedBox(width: 10),
                        Text('Open CV'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'interview',
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded, size: 18, color: Color(0xFF3B82F6)),
                        SizedBox(width: 10),
                        Text('Mark Interview'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'accepted',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981)),
                        SizedBox(width: 10),
                        Text('Accept'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rejected',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 10),
                        Text('Reject'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modern Status Dropdown
class _ModernStatusDropdown extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onChanged;

  const _ModernStatusDropdown({
    required this.currentStatus,
    required this.onChanged,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'in_review':
        return const Color(0xFF3B82F6);
      case 'accepted':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'closed':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    const statuses = ['pending', 'in_review', 'accepted', 'rejected', 'closed'];
    final effectiveStatus = statuses.contains(currentStatus) ? currentStatus : 'pending';
    final statusColor = _getStatusColor(effectiveStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: effectiveStatus,
        underline: const SizedBox(),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down_rounded, color: statusColor),
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        items: statuses.map((s) {
          final color = _getStatusColor(s);
          return DropdownMenuItem(
            value: s,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(s, style: TextStyle(color: color)),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

// Info Card for Modal
class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final List<Color> colors;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.first.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

 */