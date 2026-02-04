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
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Manage & Monitor Requests',
                style: GoogleFonts.poppins(
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
                    await FirebaseAuth.instance.signOut();
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
                style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Requests will appear here',
                    style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
                color: const Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click on any request to view details',
              style: GoogleFonts.poppins(
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

    // PATCHED SECTION: Handle both flat and nested data structures
    for (final c in rawCandidates) {
      final candidateData = _normalizeMap(c);
      String uid = candidateData['uid']?.toString() ?? '';

      // Check if data has nested structure (display/profile) or flat structure
      final hasNestedStructure = candidateData.containsKey('display') || candidateData.containsKey('profile');

      final Map<String, dynamic> display;
      final Map<String, dynamic> profile;

      if (hasNestedStructure) {
        // Old nested structure
        display = _normalizeMap(candidateData['display']);
        profile = _normalizeMap(candidateData['profile']);
      } else {
        // New flat structure - map fields appropriately
        display = {
          'name': candidateData['name'],
          'email': candidateData['email'],
          'phone': candidateData['phone'],
        };
        profile = candidateData; // Use full candidate data as profile
      }

      if (uid.trim().isEmpty) {
        final emailFallback = (display['email'] ?? profile['email'] ?? candidateData['email'] ?? '').toString().trim();
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
          'basic': candidateData,
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
    // END PATCHED SECTION

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
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '#$reqId',
                      style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
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
                            style: GoogleFonts.poppins(
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
                              style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
                        profile['resume_url']?.toString() ??
                        profile['documents']?.toString() ?? '';
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
                  // Extract full profile data - now compatible with flat structure
                  final personalProfile = _normalizeMap(profile['personalProfile'] ?? {});
                  final educationalProfile = (profile['educationalProfile'] as List?)?.cast<Map>() ??
                      (profile['educations'] as List?)?.cast<Map>() ?? [];
                  final professionalExperience = (profile['professionalExperience'] as List?)?.cast<Map>() ??
                      (profile['experiences'] as List?)?.cast<Map>() ?? [];
                  final certifications = (profile['certifications'] as List?)?.cast<Map>() ?? [];
                  final publications = (profile['publications'] as List?)?.cast<String>() ?? [];
                  final awards = (profile['awards'] as List?)?.cast<String>() ?? [];
                  final skills = (profile['skills'] as List?)?.cast<String>() ??
                      (personalProfile['skills'] as List?)?.cast<String>() ?? [];

                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 24,
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
                                          name,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.9), size: 14),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                email,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(Icons.close, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),

                            // CV Content
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Personal Information
                                    _buildCVSection(
                                      'Personal Information',
                                      Icons.person_outline,
                                      Color(0xFF6366F1),
                                      [
                                        _buildCVRow('Phone', personalProfile['contactNumber']?.toString() ??
                                            profile['phone']?.toString() ?? '-'),
                                        _buildCVRow('Nationality', personalProfile['nationality']?.toString() ??
                                            profile['nationality']?.toString() ?? '-'),
                                        _buildCVRow('Location', personalProfile['location']?.toString() ??
                                            profile['location']?.toString() ?? '-'),
                                        _buildCVRow('Date of Birth', personalProfile['dob']?.toString() ??
                                            profile['dob']?.toString() ?? '-'),
                                        if ((personalProfile['summary']?.toString() ?? profile['summary']?.toString() ?? '').isNotEmpty)
                                          _buildCVRow('Summary', personalProfile['summary']?.toString() ??
                                              profile['summary']?.toString() ?? '', isMultiline: true),
                                        if ((personalProfile['objectives']?.toString() ?? profile['objectives']?.toString() ?? '').isNotEmpty)
                                          _buildCVRow('Objectives', personalProfile['objectives']?.toString() ??
                                              profile['objectives']?.toString() ?? '', isMultiline: true),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // Skills
                                    if (skills.isNotEmpty)
                                      _buildCVSection(
                                        'Technical Skills',
                                        Icons.stars_outlined,
                                        Color(0xFF10B981),
                                        [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: skills.map((skill) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF10B981).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
                                              ),
                                              child: Text(
                                                skill,
                                                style: GoogleFonts.poppins(
                                                  color: Color(0xFF10B981),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )).toList(),
                                          ),
                                        ],
                                      ),

                                    const SizedBox(height: 24),

                                    // Professional Experience
                                    if (professionalExperience.isNotEmpty)
                                      _buildCVSection(
                                        'Professional Experience',
                                        Icons.work_outline,
                                        Color(0xFF3B82F6),
                                        professionalExperience.map((exp) {
                                          final expMap = _normalizeMap(exp);
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 16),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF3B82F6).withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Color(0xFF3B82F6).withOpacity(0.2)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        expMap['role']?.toString() ?? expMap['current_role']?.toString() ?? 'Position',
                                                        style: GoogleFonts.poppins(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 15,
                                                          color: Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                    ),
                                                    if ((expMap['rank']?.toString() ?? '').isNotEmpty)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Color(0xFF3B82F6).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          expMap['rank']?.toString() ?? '',
                                                          style: GoogleFonts.poppins(
                                                            color: Color(0xFF3B82F6),
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  expMap['organization']?.toString() ?? expMap['company']?.toString() ?? '',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: Color(0xFF3B82F6),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_today, size: 12, color: Color(0xFF64748B)),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      expMap['duration']?.toString() ?? '',
                                                      style: GoogleFonts.poppins(
                                                        color: Color(0xFF64748B),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    if ((expMap['location']?.toString() ?? '').isNotEmpty) ...[
                                                      const SizedBox(width: 16),
                                                      Icon(Icons.location_on, size: 12, color: Color(0xFF64748B)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        expMap['location']?.toString() ?? '',
                                                        style: GoogleFonts.poppins(
                                                          color: Color(0xFF64748B),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                if ((expMap['unit']?.toString() ?? '').isNotEmpty ||
                                                    (expMap['command']?.toString() ?? '').isNotEmpty ||
                                                    (expMap['aircraftType']?.toString() ?? '').isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 12,
                                                    runSpacing: 4,
                                                    children: [
                                                      if ((expMap['unit']?.toString() ?? '').isNotEmpty)
                                                        _buildInfoChip('Unit', expMap['unit']?.toString() ?? ''),
                                                      if ((expMap['command']?.toString() ?? '').isNotEmpty)
                                                        _buildInfoChip('Command', expMap['command']?.toString() ?? ''),
                                                      if ((expMap['aircraftType']?.toString() ?? '').isNotEmpty)
                                                        _buildInfoChip('Aircraft', expMap['aircraftType']?.toString() ?? ''),
                                                      if ((expMap['flightHours']?.toString() ?? '').isNotEmpty)
                                                        _buildInfoChip('Flight Hours', expMap['flightHours']?.toString() ?? ''),
                                                    ],
                                                  ),
                                                ],
                                                if ((expMap['duties']?.toString() ?? '').isNotEmpty) ...[
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    expMap['duties']?.toString() ?? '',
                                                    style: GoogleFonts.poppins(
                                                      color: Color(0xFF475569),
                                                      fontSize: 13,
                                                      height: 1.6,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),

                                    const SizedBox(height: 24),

                                    // Education
                                    if (educationalProfile.isNotEmpty)
                                      _buildCVSection(
                                        'Education',
                                        Icons.school_outlined,
                                        Color(0xFFF59E0B),
                                        educationalProfile.map((edu) {
                                          final eduMap = _normalizeMap(edu);
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFF59E0B).withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.2)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  eduMap['institutionName']?.toString() ?? eduMap['university']?.toString() ?? 'Institution',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  eduMap['majorSubjects']?.toString() ?? eduMap['education']?.toString() ?? '',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: Color(0xFFF59E0B),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(Icons.calendar_today, size: 11, color: Color(0xFF64748B)),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      eduMap['duration']?.toString() ?? eduMap['education_duration']?.toString() ?? '',
                                                      style: GoogleFonts.poppins(
                                                        color: Color(0xFF64748B),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    if ((eduMap['marksOrCgpa']?.toString() ?? eduMap['cgpa']?.toString() ?? '').isNotEmpty) ...[
                                                      const SizedBox(width: 16),
                                                      Icon(Icons.grade, size: 11, color: Color(0xFF64748B)),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        eduMap['marksOrCgpa']?.toString() ?? eduMap['cgpa']?.toString() ?? '',
                                                        style: GoogleFonts.poppins(
                                                          color: Color(0xFF64748B),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),

                                    const SizedBox(height: 24),

                                    // Certifications
                                    if (certifications.isNotEmpty)
                                      _buildCVSection(
                                        'Certifications',
                                        Icons.verified_outlined,
                                        Color(0xFF8B5CF6),
                                        certifications.map((cert) {
                                          final certMap = _normalizeMap(cert);
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF8B5CF6).withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Color(0xFF8B5CF6).withOpacity(0.2)),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.verified, color: Color(0xFF8B5CF6), size: 16),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        certMap['name']?.toString() ?? '',
                                                        style: GoogleFonts.poppins(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                          color: Color(0xFF0F172A),
                                                        ),
                                                      ),
                                                      if ((certMap['organization']?.toString() ?? '').isNotEmpty)
                                                        Text(
                                                          certMap['organization']?.toString() ?? '',
                                                          style: GoogleFonts.poppins(
                                                            color: Color(0xFF64748B),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),

                                    // Publications
                                    if (publications.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      _buildCVSection(
                                        'Publications',
                                        Icons.article_outlined,
                                        Color(0xFF06B6D4),
                                        publications.map((pub) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(top: 4),
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF06B6D4),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  pub,
                                                  style: GoogleFonts.poppins(
                                                    color: Color(0xFF475569),
                                                    fontSize: 13,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )).toList(),
                                      ),
                                    ],

                                    // Awards
                                    if (awards.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      _buildCVSection(
                                        'Awards & Honors',
                                        Icons.emoji_events_outlined,
                                        Color(0xFFFBBF24),
                                        awards.map((award) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.stars, color: Color(0xFFFBBF24), size: 16),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  award,
                                                  style: GoogleFonts.poppins(
                                                    color: Color(0xFF475569),
                                                    fontSize: 13,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            'ID: ${requestDoc['id']?.toString() ?? '-'}',
                            style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13),
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
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ...candidates.map((c) {
                        final m = _normalizeMap(c);
                        final uid = m['uid']?.toString() ?? '-';

                        // Handle both flat and nested structures
                        final hasNested = m.containsKey('display') || m.containsKey('profile');
                        final profile = hasNested ? _normalizeMap(m['profile']) : m;
                        final display = hasNested ? _normalizeMap(m['display']) : {
                          'name': m['name'],
                          'email': m['email'],
                        };

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
                                    style: GoogleFonts.poppins(
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
                                    Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text(email, style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 12)),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) async {
                                  if (action == 'open_cv') {
                                    final cv = profile['cv']?.toString() ??
                                        profile['cv_url']?.toString() ??
                                        profile['documents']?.toString() ?? '';
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

  // Helper methods for CV display
  Widget _buildCVSection(String title, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildCVRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isMultiline
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}

// Remaining helper widgets (_HeaderButton, _MetadataChip, _RequestCard, etc.) remain unchanged
// For brevity, I'm keeping them as in original. Add them back from the original file.

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
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recruiterEmail.isNotEmpty ? recruiterEmail : recruiterId,
                      style: GoogleFonts.poppins(
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
                            style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: GoogleFonts.poppins(
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
                            style: GoogleFonts.poppins(
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
                        Text('Open CV', style: GoogleFonts.poppins(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'interview',
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined, size: 18, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 10),
                        Text('Mark Interview', style: GoogleFonts.poppins(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'accepted',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 10),
                        Text('Accept', style: GoogleFonts.poppins(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'rejected',
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFEF4444)),
                        const SizedBox(width: 10),
                        Text('Reject', style: GoogleFonts.poppins(fontSize: 13)),
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
        style: GoogleFonts.poppins(
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
                Text(s, style: GoogleFonts.poppins(color: color, fontSize: 12)),
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
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}