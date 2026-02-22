// admin_dashboard_ui.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'admin_provider.dart';

class AdminDashboardScreen2 extends StatefulWidget {
  const AdminDashboardScreen2({super.key});

  @override
  State<AdminDashboardScreen2> createState() => _AdminDashboardScreen2State();
}

class _AdminDashboardScreen2State extends State<AdminDashboardScreen2> {
  @override
  void initState() {
    super.initState();
    // Trigger real-time fetch on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminProvider>().fetchAllRequests(realtime: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: _AdminDashboardBody(),
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

  // Cache for request details to avoid redundant fetches
  final Map<String, Map<String, dynamic>> _detailsCache = {};

  @override
  void dispose() {
    _detailsCache.clear();
    super.dispose();
  }

  Map<String, dynamic> _normalizeMap(dynamic m) {
    return AdminProvider.normalizeMapStatic(m);
  }


  Future<void> _openDetails(BuildContext context, String requestId) async {
    if (_selectedRequestId == requestId && _selectedRequestDetails != null) return;

    setState(() {
      _selectedRequestId = requestId;
      _loadingDetails = true;
    });

    if (_detailsCache.containsKey(requestId)) {
      if (mounted) {
        setState(() {
          _selectedRequestDetails = _detailsCache[requestId];
          _loadingDetails = false;
        });
      }
      return;
    }

    final prov = Provider.of<AdminProvider>(context, listen: false);
    final details = await prov.fetchRequestDetails(requestId: requestId);

    if (!mounted) return;  // ← was `if (mounted)` which is same, but explicit return is cleaner
    setState(() {
      _selectedRequestDetails = details;
      _detailsCache[requestId] = details ?? {};
      _loadingDetails = false;
    });
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
                if (isWide) ...[
                  VerticalDivider(width: 2, color: Colors.grey.shade200),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 5,
                    child: _buildDetailsSection(context, prov),
                  ),
                ],
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
                'Request Management',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Real-time Recruiter Monitoring',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
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
        // Header Panel
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.format_list_bulleted_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incoming Requests',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live Updates',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // List Content
        Expanded(
          child: prov.requests.isEmpty
              ? Center(
            child: prov.loading
                ? const CircularProgressIndicator(
              color: Color(0xFF6366F1),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B)
                            .withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.inbox_outlined,
                    size: 40,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Requests',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF475569),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'New requests will appear automatically',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: prov.requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = _normalizeMap(prov.requests[index]);
              final id = r['id']?.toString() ?? '';
              final recruiterEmail =
                  r['recruiter_email']?.toString() ?? '';
              final total = r['total_candidates'] ?? 0;
              final status = r['status']?.toString() ?? 'unknown';
              final createdAt = r['created_at'];
              final createdStr = createdAt is Timestamp
                  ? DateFormat.yMMMd().add_Hm().format(createdAt.toDate())
                  : (createdAt?.toString() ?? '-');

              return _RequestCard(
                id: id,
                recruiterEmail: recruiterEmail,
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
          : _buildDetailsPanel(
          context, prov, _selectedRequestDetails!))),
    );
  }

  Widget _buildDetailsPanel(
      BuildContext context, AdminProvider prov, Map<String, dynamic> details) {
    final requestDoc = _normalizeMap(details['request_doc']);
    final recruiter = _normalizeMap(details['recruiter']);
    final rawCandidates =
        (details['candidates'] as List<dynamic>?)?.cast<dynamic>() ?? [];

    final reqData = _normalizeMap(requestDoc['data']);
    final reqId = requestDoc['id']?.toString() ?? '-';
    final status = reqData['status']?.toString() ?? 'pending';
    final notes = reqData['notes']?.toString() ?? '';
    final createdAt = reqData['created_at'];
    final createdStr = createdAt is Timestamp
        ? DateFormat.yMMMd().add_Hm().format(createdAt.toDate())
        : (createdAt?.toString() ?? '-');

    final recruiterData = _normalizeMap(recruiter['data']);
    final recruiterName =
        recruiterData['name']?.toString() ?? recruiter['id']?.toString() ?? '-';
    final recruiterEmail = recruiterData['email']?.toString() ?? '-';
    final recruiterCompany = recruiterData['company']?.toString() ?? '';

    // Optimized deduplication
    final uniqueCandidates = <String, Map<String, dynamic>>{};
    for (final c in rawCandidates) {
      final candidateData = _normalizeMap(c);
      final uid = (candidateData['uid'] ?? candidateData['id'] ?? '').toString().trim();

      if (uid.isEmpty || uid.toLowerCase() == 'null') continue;

      final canonUid = uid.toLowerCase();
      if (!uniqueCandidates.containsKey(canonUid)) {
        uniqueCandidates[canonUid] = candidateData;
      }
    }

    final candidates = uniqueCandidates.values.toList();

    final candidateStatusRaw = _normalizeMap(reqData['candidate_statuses']);
    final Map<String, String> candidateStatusNormalized = {};
    candidateStatusRaw.forEach((k, v) {
      final key = k.toString();
      if (key.isNotEmpty) {
        candidateStatusNormalized[key.toLowerCase()] = v?.toString() ?? '';
      }
    });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
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
                    // ✅ Capture before any await — context is valid here
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await prov.updateRequestStatus(
                      requestId: reqId,
                      newStatus: newStatus,
                      performedBy: 'admin_dashboard',
                    );
                    if (!mounted) return;  // ← guard after first await
                    if (ok) {
                      messenger.showSnackBar(SnackBar(
                        content: Text('Status changed to $newStatus'),
                        backgroundColor: Colors.green,
                      ));
                      _detailsCache.remove(reqId);
                      final updated = await prov.fetchRequestDetails(requestId: reqId);
                      if (!mounted) return;  // ← guard after second await
                      setState(() {
                        _selectedRequestDetails = updated;
                        _detailsCache[reqId] = updated ?? {};
                      });
                    }
                  },
                ),


              ],
            ),
            const SizedBox(height: 24),

            // Metadata
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

            // Recruiter Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      recruiterName.isNotEmpty
                          ? recruiterName.substring(0, 1).toUpperCase()
                          : 'R',
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
                          const Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
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
                              const Icon(
                                Icons.business_outlined,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
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

            // Notes
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.note_outlined,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
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

            // Candidates Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
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

            // Optimized Grid for Candidates
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No candidates found',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.9,
                ),
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final c = candidates[index];
                  final candidateUid = c['uid']?.toString() ?? '';
                  final canonUid = candidateUid.toLowerCase();
                  final name = c['name']?.toString() ?? candidateUid;
                  final email = c['email']?.toString() ?? '';
                  final candidateStatus =
                      candidateStatusNormalized[canonUid] ?? 'unknown';


                  return _CandidateCard(
                    name: name,
                    email: email,
                    status: candidateStatus,
                    onTap: () => _showCandidateCV(context, c),
                    onMenuAction: (action) async {
                      // ✅ Capture before any await
                      final messenger = ScaffoldMessenger.of(context);

                      if (action == 'open_cv') {
                        final userData = _normalizeMap(c['user_data'] ?? {});
                        final experienceDocs =
                            (userData['experienceDocuments'] as List?)?.cast<String>() ?? [];
                        final cvUrl = experienceDocs.isNotEmpty ? experienceDocs.first : '';
                        if (!mounted) return;
                        messenger.showSnackBar(SnackBar(
                          content: Text(cvUrl.isNotEmpty ? 'CV URL: $cvUrl' : 'No CV document available'),
                        ));
                        return;
                      }

                      final ok = await prov.updateCandidateStatus(
                        requestId: reqId,
                        candidateUid: candidateUid,
                        status: action,
                        performedBy: 'admin_dashboard',
                      );
                      if (!mounted) return;  // ← guard after first await

                      messenger.showSnackBar(SnackBar(
                        content: Text(ok ? '✅ Updated to $action' : '❌ Failed to update'),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ));

                      if (!ok) return;

                      _detailsCache.remove(reqId);
                      final updated = await prov.fetchRequestDetails(requestId: reqId);
                      if (!mounted) return;  // ← guard after second await
                      setState(() {
                        _selectedRequestDetails = updated;
                        _detailsCache[reqId] = updated ?? {};
                      });
                    },
                  );


                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCandidateCV(BuildContext context, Map<String, dynamic> candidate) {
    // 1. Data Normalization (Supports Flat and Nested Structures)
    final rawData = _normalizeMap(candidate['user_data'] ?? candidate);
    final personalProfile = _normalizeMap(rawData['personalProfile'] ?? rawData);
    final professionalProfile = _normalizeMap(rawData['professionalProfile'] ?? rawData);

    // Dynamic extraction helper for flat/nested compatibility
    T getVal<T>(String flatKey, List<String> nestedPath, T fallback) {
      if (rawData.containsKey(flatKey) && rawData[flatKey] != null) return rawData[flatKey] as T;
      dynamic current = rawData;
      for (final p in nestedPath) {
        if (current is Map && current.containsKey(p)) {
          current = current[p];
        } else {
          return fallback;
        }
      }
      return (current as T?) ?? fallback;
    }

    final educationalProfile = (rawData['educationalProfile'] ?? rawData['educational_profile'] ?? []) as List;
    final professionalExperience = (rawData['professionalExperience'] ?? rawData['professional_experience'] ?? []) as List;
    final certificationList = (rawData['certifications'] ?? []) as List;

    List<String> safeStringList(dynamic field) {
      if (field == null) return [];
      if (field is List) {
        return field.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    final publications = safeStringList(rawData['publications']);
    final awards = safeStringList(rawData['awards']);
    final references = safeStringList(rawData['references']);
    final skills = safeStringList(rawData['skills'] ?? personalProfile['skills']);
    final socialLinks = safeStringList(rawData['social_links'] ?? rawData['socialLinks'] ?? personalProfile['socialLinks']);
    final experienceDocs = safeStringList(rawData['experienceDocuments'] ?? rawData['experience_documents']);

    final name = getVal<String>('name', ['personalProfile', 'name'], candidate['name']?.toString() ?? 'Unknown');
    final email = getVal<String>('email', ['personalProfile', 'email'], candidate['email']?.toString() ?? '');
    final phone = getVal<String>('phone', ['personalProfile', 'phone'], candidate['phone']?.toString() ?? '');
    
    // Fallback for personal profile fields if rawData is flat
    final nationality = getVal<String>('nationality', ['personalProfile', 'nationality'], '-');
    final dob = getVal<String>('dob', ['personalProfile', 'dob'], '-');
    final secondaryEmail = getVal<String>('secondary_email', ['personalProfile', 'secondary_email'], '');
    final personalSummary = getVal<String>('summary', ['personalProfile', 'summary'], '');
    final objectives = getVal<String>('objectives', ['personalProfile', 'objectives'], '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 900),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    _buildProfileAvatar(personalProfile, name),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              if (email.isNotEmpty)
                                _buildHeaderItem(Icons.email_outlined, email),
                              if (phone.isNotEmpty)
                                _buildHeaderItem(
                                    Icons.phone_android_outlined, phone),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Details
                      _buildSection(
                        'PERSONAL DETAILS',
                        Icons.person_outline,
                        const Color(0xFF6366F1),
                        [
                          _buildRow('Nationality', nationality),
                          _buildRow('Date of Birth', dob),
                          if (secondaryEmail.isNotEmpty)
                            _buildRow('Secondary Email', secondaryEmail),
                          if (personalSummary.isNotEmpty)
                            _buildRow(
                              'Summary',
                              personalSummary,
                              isMultiline: true,
                            ),
                          if (objectives.isNotEmpty)
                            _buildRow(
                              'Objectives',
                              objectives,
                              isMultiline: true,
                            ),
                        ],
                      ),

                      // Social Links
                      if (socialLinks.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection(
                          'SOCIAL LINKS',
                          Icons.link,
                          const Color(0xFF06B6D4),
                          [
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: socialLinks
                                  .map((link) => _buildClickableLink(
                                  link, const Color(0xFF06B6D4)))
                                  .toList(),
                            ),
                          ],
                        ),
                      ],

                      // Skills
                      if (skills.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection(
                          'TECHNICAL SKILLS',
                          Icons.auto_awesome_outlined,
                          const Color(0xFF10B981),
                          [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: skills
                                  .map((s) =>
                                  _buildBadge(s, const Color(0xFF10B981)))
                                  .toList(),
                            ),
                          ],
                        ),
                      ],

                      // Professional Profile
                      if (professionalProfile.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection(
                          'PROFESSIONAL PROFILE',
                          Icons.work_history_outlined,
                          const Color(0xFF8B5CF6),
                          [
                            if ((professionalProfile['status']?.toString() ?? '')
                                .isNotEmpty)
                              _buildRow('Status',
                                  professionalProfile['status']?.toString() ?? ''),
                            if ((professionalProfile['retirementDate']
                                ?.toString() ??
                                '')
                                .isNotEmpty)
                              _buildRow(
                                  'Retirement Date',
                                  professionalProfile['retirementDate']
                                      ?.toString() ??
                                      ''),
                            if ((professionalProfile['expectedRetirementDate']
                                ?.toString() ??
                                '')
                                .isNotEmpty)
                              _buildRow(
                                  'Expected Retirement',
                                  professionalProfile['expectedRetirementDate']
                                      ?.toString() ??
                                      ''),
                            if ((professionalProfile['summary']?.toString() ?? '')
                                .isNotEmpty)
                              _buildRow(
                                'Summary',
                                professionalProfile['summary']?.toString() ?? '',
                                isMultiline: true,
                              ),
                          ],
                        ),
                      ],

                      // Experience
                      if (professionalExperience.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection(
                          'PROFESSIONAL EXPERIENCE',
                          Icons.business_center_outlined,
                          const Color(0xFF3B82F6),
                          professionalExperience
                              .map((exp) =>
                              _buildExperienceCard(_normalizeMap(exp)))
                              .toList(),
                        ),
                      ],

                      // Education
                      if (educationalProfile.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection(
                          'ACADEMIC BACKGROUND',
                          Icons.school_outlined,
                          const Color(0xFFF59E0B),
                          educationalProfile
                              .map((edu) =>
                              _buildEducationCard(_normalizeMap(edu)))
                              .toList(),
                        ),
                      ],

                      // Certifications
                      if (certificationList.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection(
                          'CERTIFICATIONS',
                          Icons.verified_outlined,
                          const Color(0xFFEC4899),
                          certificationList.map((cert) {
                            final certMap = _normalizeMap(cert);
                            return _buildSimpleListCard(
                              certMap['name']?.toString() ??
                                  certMap['certificationName']?.toString() ??
                                  'Certification',
                              certMap['organization']?.toString() ??
                                  certMap['issuingAuthority']?.toString(),
                            );
                          }).toList(),
                        ),
                      ],

                      // Publications
                      if (publications.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection(
                          'PUBLICATIONS',
                          Icons.menu_book,
                          const Color(0xFF64748B),
                          publications
                              .map((p) => _buildSimpleTextItem(p))
                              .toList(),
                        ),
                      ],

                      // Awards
                      if (awards.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection(
                          'AWARDS & HONORS',
                          Icons.emoji_events_outlined,
                          const Color(0xFFF59E0B),
                          awards.map((a) => _buildSimpleTextItem(a)).toList(),
                        ),
                      ],

                      // References
                      if (references.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection(
                          'REFERENCES',
                          Icons.people_outline,
                          const Color(0xFF14B8A6),
                          references
                              .map((r) => _buildSimpleTextItem(r))
                              .toList(),
                        ),
                      ],

                      // Documents
                      if (experienceDocs.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection(
                          'ATTACHED DOCUMENTS',
                          Icons.attachment,
                          const Color(0xFFEF4444),
                          [
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: experienceDocs
                                  .map((doc) => _buildClickableLink(
                                  doc, const Color(0xFFEF4444),
                                  isDoc: true))
                                  .toList(),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI Helper Methods
  Widget _buildSection(
      String title, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
                child: Divider(thickness: 1, color: Color(0xFFE2E8F0))),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExperienceCard(Map<String, dynamic> exp) {
    final role = exp['role']?.toString() ??
        exp['jobTitle']?.toString() ??
        exp['position']?.toString() ??
        'Position';
    final organization = exp['organization']?.toString() ??
        exp['companyName']?.toString() ??
        exp['company']?.toString() ??
        '';
    final rank = exp['rank']?.toString() ?? '';
    final startDate = exp['startDate']?.toString() ?? '';
    final endDate = exp['endDate']?.toString() ?? '';
    final duration = exp['duration']?.toString() ?? '';
    final location = exp['location']?.toString() ?? '';
    final unit = exp['unit']?.toString() ?? '';
    final command = exp['command']?.toString() ?? '';
    final aircraftType = exp['aircraftType']?.toString() ?? '';
    final flightHours = exp['flightHours']?.toString() ?? '';
    final duties = exp['duties']?.toString() ?? exp['description']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  role,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (rank.isNotEmpty) _buildBadge(rank, const Color(0xFF3B82F6)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            organization,
            style: GoogleFonts.poppins(
              color: const Color(0xFF3B82F6),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                duration.isNotEmpty
                    ? duration
                    : "$startDate - ${endDate.isNotEmpty ? endDate : 'Present'}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.location_on,
                    size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
          if (unit.isNotEmpty ||
              command.isNotEmpty ||
              aircraftType.isNotEmpty ||
              flightHours.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (unit.isNotEmpty) _buildInfoChip('Unit', unit),
                if (command.isNotEmpty) _buildInfoChip('Command', command),
                if (aircraftType.isNotEmpty)
                  _buildInfoChip('Aircraft', aircraftType),
                if (flightHours.isNotEmpty)
                  _buildInfoChip('Flight Hours', flightHours),
              ],
            ),
          ],
          if (duties.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              duties,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ],
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
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> edu) {
    final degree = edu['degree']?.toString() ??
        edu['majorSubjects']?.toString() ??
        'Degree';
    final institution = edu['institution']?.toString() ??
        edu['institutionName']?.toString() ??
        '';
    final year = edu['year']?.toString() ?? edu['duration']?.toString() ?? '';
    final marksOrCgpa =
        edu['marksOrCgpa']?.toString() ?? edu['grade']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            institution,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            degree,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFFF59E0B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (year.isNotEmpty) ...[
                const Icon(Icons.calendar_today,
                    size: 11, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  year,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
              if (marksOrCgpa.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.grade, size: 11, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  marksOrCgpa,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTextItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableLink(String link, Color color, {bool isDoc = false}) {
    return InkWell(
      onTap: () {
        debugPrint('Opening: $link');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isDoc ? Icons.description_outlined : Icons.link,
                size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                link.length > 40 ? '${link.substring(0, 37)}...' : link,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: color,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleListCard(String title, String? subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Color(0xFFEC4899), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(Map<String, dynamic> profile, String name) {
    final url = profile['profilePicUrl']?.toString() ?? '';
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 3),
        image: url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
        color: url.isEmpty ? const Color(0xFF4F46E5) : null,
      ),
      child: url.isEmpty
          ? Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'C',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      )
          : null,
    );
  }

  void _showRequestDetailsModal(
      BuildContext context, AdminProvider prov, String requestId) async {
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
                height: 250,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Loading Request...",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final details = snap.data;
            if (details == null) {
              return Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF4444),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load details',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final requestDoc = _normalizeMap(details['request_doc']);
            final recruiter = _normalizeMap(details['recruiter']);
            final reqData = _normalizeMap(requestDoc['data']);
            final recruiterData = _normalizeMap(recruiter['data']);
            final candidates = (details['candidates'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
                [];

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assignment_outlined,
                                color: Color(0xFF6366F1),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Request Details',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    'Review recruiter requirements',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                'ID: ${requestDoc['id']?.toString() ?? '-'}',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(24),
                          children: [
                            _buildSectionLabel('RECRUITER INFORMATION'),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF64748B)
                                        .withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFFDBEAFE)),
                                    ),
                                    child: const Icon(
                                      Icons.business_outlined,
                                      color: Color(0xFF3B82F6),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recruiterData['name']?.toString() ??
                                              recruiter['id']?.toString() ??
                                              'Unknown Recruiter',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          recruiterData['email']?.toString() ??
                                              '-',
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF64748B),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSectionLabel('REQUEST STATUS'),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Current Status',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                                reqData['status'])
                                                .withOpacity(0.1),
                                            borderRadius:
                                            BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            (reqData['status']?.toString() ??
                                                'Pending')
                                                .toUpperCase(),
                                            style: GoogleFonts.poppins(
                                              color: _getStatusColor(
                                                  reqData['status']),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 16),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Candidates Found',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: const Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${candidates.length}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              color: const Color(0xFF1E293B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionLabel('MATCHED CANDIDATES'),
                                if (candidates.isNotEmpty)
                                  Text(
                                    '${candidates.length} Total',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                            if (candidates.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                alignment: Alignment.center,
                                child: Text(
                                  "No candidates attached to this request yet.",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ...candidates.map((c) {
                              final uid = c['uid']?.toString() ?? '-';
                              final name = c['name']?.toString() ?? uid;
                              final email = c['email']?.toString() ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF64748B)
                                          .withOpacity(0.03),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showCandidateCV(context, c);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF6366F1),
                                                  Color(0xFF8B5CF6)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF6366F1)
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                name.isNotEmpty
                                                    ? name
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                                    : 'C',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                    color:
                                                    const Color(0xFF1E293B),
                                                  ),
                                                ),
                                                Text(
                                                  email,
                                                  style: GoogleFonts.poppins(
                                                    color:
                                                    const Color(0xFF64748B),
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                  TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                              BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
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

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final s = status?.toString().toLowerCase() ?? '';
    if (s == 'active' || s == 'approved') return const Color(0xFF10B981);
    if (s == 'pending') return const Color(0xFFF59E0B);
    if (s == 'rejected' || s == 'closed') return const Color(0xFFEF4444);
    return const Color(0xFF6366F1);
  }
}

// Reusable Components
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
  final dynamic totalCandidates;
  final String status;
  final String createdStr;
  final bool isSelected;
  final VoidCallback onTap;

  const _RequestCard({
    required this.id,
    required this.recruiterEmail,
    required this.totalCandidates,
    required this.status,
    required this.createdStr,
    required this.isSelected,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'active':
        return const Color(0xFF10B981);
      case 'closed':
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
          isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          if (!isSelected)
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'ID: ${id.length > 8 ? id.substring(0, 8) : id}',
                        style: GoogleFonts.sourceCodePro(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Text(
                      createdStr,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                      child: Text(
                        recruiterEmail.isNotEmpty
                            ? recruiterEmail[0].toUpperCase()
                            : 'R',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6366F1),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        recruiterEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalCandidates Candidates',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
      case 'shortlist':
      case 'shortlisted':
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
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = ['Shortlist', 'Screening', 'Interview', 'Technical', 'Offer', 'Handover'];
    
    // Normalize status for pipeline index
    final displayStatus = status.toLowerCase() == 'shortlisted' ? 'shortlist' : status.toLowerCase();
    final currentIdx = stages.map((e) => e.toLowerCase()).toList().indexOf(displayStatus);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C',
                        style: GoogleFonts.poppins(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                    onSelected: onMenuAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'open_cv', child: Text('View Full Details')),
                      const PopupMenuDivider(),
                      ...stages.map((s) => PopupMenuItem(
                        value: s.toLowerCase(),
                        child: Text('Move to $s'),
                      )),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Pipeline View
              Row(
                children: List.generate(stages.length, (index) {
                  final isActive = index <= currentIdx;
                  final isLast = index == stages.length - 1;
                  
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: isActive ? _getStatusColor() : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (!isLast) const SizedBox(width: 4),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: _getStatusColor(),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Stage ${currentIdx + 1}/${stages.length}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (currentIdx < stages.length - 1)
                    ElevatedButton(
                      onPressed: () => onMenuAction(stages[currentIdx + 1].toLowerCase()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getStatusColor().withOpacity(0.1),
                        foregroundColor: _getStatusColor(),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Next', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 10),
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
      case 'in review':
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
    const statuses = ['pending', 'In Review', 'accepted', 'rejected', 'closed'];
    final effectiveStatus =
    statuses.contains(currentStatus) ? currentStatus : 'pending';
    final statusColor = _getStatusColor(effectiveStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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