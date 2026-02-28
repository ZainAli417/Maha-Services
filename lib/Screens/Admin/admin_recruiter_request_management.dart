// admin_dashboard_ui.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'admin_recruiter_request_provider.dart';

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
      body: AdminDashboardBody(),
    );
  }
}


class AdminDashboardBody extends StatefulWidget {
  const AdminDashboardBody({Key? key}) : super(key: key);

  @override
  State<AdminDashboardBody> createState() => _AdminDashboardBodyState();
}

class _AdminDashboardBodyState extends State<AdminDashboardBody> {
  bool _loadingDetails = false;
  final ScrollController _listScrollController = ScrollController();
  final ScrollController _detailScrollController = ScrollController();

  @override
  void dispose() {
    _listScrollController.dispose();
    _detailScrollController.dispose();
    super.dispose();
  }

  // --- Logic Helpers (Preserved 100%) ---

  Map<String, dynamic> _normalizeMap(dynamic m) {
    return AdminProvider.normalizeMapStatic(m);
  }

  Future<void> _openDetails(BuildContext context, String requestId) async {
    final prov = Provider.of<AdminProvider>(context, listen: false);
    if (prov.selectedRequestId == requestId) return;

    setState(() => _loadingDetails = true);

    await prov.selectRequest(requestId);

    if (mounted) {
      setState(() => _loadingDetails = false);
    }
  }

  Color _getStatusColor(dynamic status) {
    final s = status?.toString().toLowerCase() ?? '';
    if (s == 'active' || s == 'approved') return const Color(0xFF10B981);
    if (s == 'pending') return const Color(0xFFF59E0B);
    if (s == 'rejected' || s == 'closed') return const Color(0xFFEF4444);
    return const Color(0xFF6366F1);
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AdminProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint logic: > 900px is "Wide" (Web/Desktop Dashboard)
        final isWide = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC), // Slate-50 background
          body: Column(
            children: [
              _buildModernHeader(context, prov),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: isWide
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Panel: Request List (Fixed width for consistency)
                    SizedBox(
                      width: 380,
                      child: _buildRequestsList(context, prov, isWide),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                    // Right Panel: Details (Fluid)
                    Expanded(
                      child: _buildDetailsSection(context, prov),
                    ),
                  ],
                )
                    : _buildRequestsList(context, prov, isWide), // Mobile: List only
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Header ---

  Widget _buildModernHeader(BuildContext context, AdminProvider prov) {
    return Container(
      height: 72,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF6366F1), size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request Management',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
              ),
              Text(
                'Real-time Recruiter Monitoring',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
              ),
            ],
          ),
          const Spacer(),
          // Optional: You could add a refresh button here
        ],
      ),
    );
  }

  // --- Left Panel / Mobile List ---

  Widget _buildRequestsList(BuildContext context, AdminProvider prov, bool isWide) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Sticky List Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text(
                  'INCOMING REQUESTS',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('LIVE', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List Content
          Expanded(
            child: prov.requests.isEmpty
                ? _buildEmptyStateList(prov.loading)
                : Scrollbar(
              controller: _listScrollController,
              thumbVisibility: isWide,
              child: ListView.separated(
                controller: _listScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: prov.requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final r = _normalizeMap(prov.requests[index]);
                  final id = r['id']?.toString() ?? '';
                  final recruiterEmail = r['recruiter_email']?.toString() ?? '';
                  final total = r['total_candidates'] ?? 0;
                  final status = r['status']?.toString() ?? 'unknown';
                  final createdAt = r['created_at'];
                  final createdStr = createdAt is Timestamp
                      ? DateFormat.yMMMd().add_Hm().format(createdAt.toDate())
                      : (createdAt?.toString() ?? '-');

                  final isSelected = id == prov.selectedRequestId;

                  return _RequestCard(
                    id: id,
                    recruiterEmail: recruiterEmail,
                    totalCandidates: total,
                    status: status,
                    createdStr: createdStr,
                    isSelected: isSelected,
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
      ),
    );
  }

  Widget _buildEmptyStateList(bool loading) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text('No Active Requests', style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
          Text('New items will appear here', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)),
        ],
      ),
    );
  }

  // --- Detail Section (Right Panel) ---

  Widget _buildDetailsSection(BuildContext context, AdminProvider prov) {
    if (_loadingDetails) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)));
    }

    if (prov.selectedRequestId == null) {
      return Container(
        color: const Color(0xFFF8FAFC),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE2E8F0))),
                child: const Icon(Icons.touch_app_outlined, size: 32, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 24),
              Text('Select a request', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              Text('View detailed information and candidates', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    if (prov.selectedRequestDetails == null) {
      return const Center(child: Text('No details loaded'));
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Scrollbar(
        controller: _detailScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _detailScrollController,
          padding: const EdgeInsets.all(32),
          child: _buildDetailsPanel(context, prov, prov.selectedRequestDetails!),
        ),
      ),
    );
  }

  Widget _buildDetailsPanel(BuildContext context, AdminProvider prov, Map<String, dynamic> details) {
    // --- Data Extraction (Preserved) ---
    final requestDoc = _normalizeMap(details['request_doc']);
    final recruiter = _normalizeMap(details['recruiter']);
    final rawCandidates = (details['candidates'] as List<dynamic>?)?.cast<dynamic>() ?? [];
    final reqData = _normalizeMap(requestDoc['data']);
    final reqId = requestDoc['id']?.toString() ?? '-';
    final status = reqData['status']?.toString() ?? 'pending';
    final notes = reqData['notes']?.toString() ?? '';
    final createdAt = reqData['created_at'];
    final createdStr = createdAt is Timestamp ? DateFormat.yMMMd().add_Hm().format(createdAt.toDate()) : (createdAt?.toString() ?? '-');
    final recruiterData = _normalizeMap(recruiter['data']);
    final recruiterName = recruiterData['name']?.toString() ?? recruiter['id']?.toString() ?? '-';
    final recruiterEmail = recruiterData['email']?.toString() ?? '-';
    final recruiterCompany = recruiterData['company']?.toString() ?? '';

    // Deduplication Logic (Preserved)
    final uniqueCandidates = <String, Map<String, dynamic>>{};
    for (final c in rawCandidates) {
      final candidateData = _normalizeMap(c);
      final uid = (candidateData['uid'] ?? candidateData['id'] ?? '').toString().trim();
      if (uid.isEmpty || uid.toLowerCase() == 'null') continue;
      final canonUid = uid.toLowerCase();
      if (!uniqueCandidates.containsKey(canonUid)) uniqueCandidates[canonUid] = candidateData;
    }
    final candidates = uniqueCandidates.values.toList();

    // Status Map (Preserved)
    final candidateStatusRaw = _normalizeMap(reqData['candidate_statuses']);
    final Map<String, String> candidateStatusNormalized = {};
    candidateStatusRaw.forEach((k, v) {
      final key = k.toString();
      if (key.isNotEmpty) candidateStatusNormalized[key.toLowerCase()] = v?.toString() ?? '';
    });

    // --- UI Construction ---

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Bar: ID and Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      SelectableText(
                        'Request-ID #$reqId',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                      ),
                      const SizedBox(width: 10),
                      _MetadataChip(icon: Icons.calendar_today, label: createdStr, color: const Color(0xFF64748B), isSmall: true),
                    ],
                  ),
                ],
              ),
            ),
            _ModernStatusDropdown(
              currentStatus: status,
              onChanged: (newStatus) async {
                final messenger = ScaffoldMessenger.of(context);
                await Future.delayed(const Duration(milliseconds: 150)); // Allow UI to settle
                final ok = await prov.updateRequestStatus(requestId: reqId, newStatus: newStatus, performedBy: 'admin_dashboard');
                if (!mounted) return;
                if (ok) {
                  messenger.showSnackBar(SnackBar(content: Text('Status changed to $newStatus'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 32),

        // 2. Recruiter Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RECRUITER PROFILE', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8), letterSpacing: 1.0)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: Text(recruiterName.isNotEmpty ? recruiterName[0].toUpperCase() : 'R', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(recruiterName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        SelectableText(recruiterEmail, style: GoogleFonts.poppins(color: const Color(0xFF6366F1), fontSize: 13, fontWeight: FontWeight.w500)),
                        if (recruiterCompany.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.business, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(recruiterCompany, style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (notes.isNotEmpty) ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(notes, style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 13, height: 1.5, fontStyle: FontStyle.italic))),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),

        // 3. Candidates Section
        Row(
          children: [
            Text('MATCHED CANDIDATES', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B), letterSpacing: 0.5)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(12)),
              child: Text('${candidates.length}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF4338CA))),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (candidates.isEmpty)
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('No candidates attached to this request.', style: GoogleFonts.poppins(color: const Color(0xFF94A3B8)))),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // INTELLIGENT GRID: Adapts column count based on width (max 400px per item)
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              mainAxisExtent: 180, // Fixed height for consistency
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final c = candidates[index];
              final candidateUid = c['uid']?.toString() ?? '';
              final canonUid = candidateUid.toLowerCase();
              final name = c['name']?.toString() ?? candidateUid;
              final email = c['email']?.toString() ?? '';
              final candidateStatus = candidateStatusNormalized[canonUid] ?? 'unknown';

              final rawData = _normalizeMap(c['user_data'] ?? c);
              String extractVal(String key1, String key2) {
                if (rawData.containsKey(key1) && rawData[key1] != null) return rawData[key1].toString();
                if (rawData.containsKey(key2) && rawData[key2] != null) {
                  return rawData[key2] is Map ? (rawData[key2][key1]?.toString() ?? '') : '';
                }
                return '';
              }
              final phone = extractVal('phone', 'personalProfile');
              final title = extractVal('title', 'professionalProfile');

              // Assuming CandidateCard is defined (preserved from previous context)
              return _CandidateCard(
                name: name,
                email: email,
                phone: phone,
                title: title,
                status: candidateStatus,
                // On Desktop/Wide, we don't need "dismiss" button usually, but keeping logic
                onTap: () => _showCandidateCV(context, c),
                onMenuAction: (action) async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (action == 'open_cv') {
                    final experienceDocs = (rawData['experienceDocuments'] as List?)?.cast<String>() ?? [];
                    final cvUrl = experienceDocs.isNotEmpty ? experienceDocs.first : '';
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(content: Text(cvUrl.isNotEmpty ? 'CV URL: $cvUrl' : 'No CV found')));
                    return;
                  }
                  await Future.delayed(const Duration(milliseconds: 150));
                  final ok = await prov.updateCandidateStatus(requestId: reqId, candidateUid: candidateUid, status: action, performedBy: 'admin_dashboard');
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text(ok ? 'Updated to $action' : 'Failed to update'), backgroundColor: ok ? Colors.green : Colors.red));
                },
              );
            },
          ),

        const SizedBox(height: 50), // Bottom padding
      ],
    );
  }

  // --- CV Viewing Modal (Logic Preserved 100%) ---

  void _showCandidateCV(BuildContext context, Map<String, dynamic> candidate) {
    // 1. Data Normalization
    final rawData = _normalizeMap(candidate['user_data'] ?? candidate);
    final personalProfile = _normalizeMap(rawData['personalProfile'] ?? rawData);
    final professionalProfile = _normalizeMap(rawData['professionalProfile'] ?? rawData);

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
    final nationality = getVal<String>('nationality', ['personalProfile', 'nationality'], '-');
    final dob = getVal<String>('dob', ['personalProfile', 'dob'], '-');
    final secondaryEmail = getVal<String>('secondary_email', ['personalProfile', 'secondary_email'], '');
    final personalSummary = getVal<String>('summary', ['personalProfile', 'summary'], '');
    final objectives = getVal<String>('objectives', ['personalProfile', 'objectives'], '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 900),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileAvatar(personalProfile, name),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(name.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 10,
                            children: [
                              if (email.isNotEmpty) _buildHeaderItem(Icons.email_outlined, email),
                              if (phone.isNotEmpty) _buildHeaderItem(Icons.phone_android_outlined, phone),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('PERSONAL DETAILS', Icons.person_outline, const Color(0xFF6366F1), [
                        _buildRow('Nationality', nationality),
                        _buildRow('Date of Birth', dob),
                        if (secondaryEmail.isNotEmpty) _buildRow('Secondary Email', secondaryEmail),
                        if (personalSummary.isNotEmpty) _buildRow('Summary', personalSummary, isMultiline: true),
                        if (objectives.isNotEmpty) _buildRow('Objectives', objectives, isMultiline: true),
                      ]),
                      if (socialLinks.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection('SOCIAL LINKS', Icons.link, const Color(0xFF06B6D4), [Wrap(spacing: 12, runSpacing: 8, children: socialLinks.map((link) => _buildClickableLink(link, const Color(0xFF06B6D4))).toList())]),
                      ],
                      if (skills.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection('TECHNICAL SKILLS', Icons.auto_awesome_outlined, const Color(0xFF10B981), [Wrap(spacing: 8, runSpacing: 8, children: skills.map((s) => _buildBadge(s, const Color(0xFF10B981))).toList())]),
                      ],
                      if (professionalProfile.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSection('PROFESSIONAL PROFILE', Icons.work_history_outlined, const Color(0xFF8B5CF6), [
                          if ((professionalProfile['status']?.toString() ?? '').isNotEmpty) _buildRow('Status', professionalProfile['status']?.toString() ?? ''),
                          if ((professionalProfile['retirementDate']?.toString() ?? '').isNotEmpty) _buildRow('Retirement Date', professionalProfile['retirementDate']?.toString() ?? ''),
                          if ((professionalProfile['summary']?.toString() ?? '').isNotEmpty) _buildRow('Summary', professionalProfile['summary']?.toString() ?? '', isMultiline: true),
                        ]),
                      ],
                      if (professionalExperience.isNotEmpty) ...[const SizedBox(height: 32), _buildSection('PROFESSIONAL EXPERIENCE', Icons.business_center_outlined, const Color(0xFF3B82F6), professionalExperience.map((exp) => _buildExperienceCard(_normalizeMap(exp))).toList())],
                      if (educationalProfile.isNotEmpty) ...[const SizedBox(height: 32), _buildSection('ACADEMIC BACKGROUND', Icons.school_outlined, const Color(0xFFF59E0B), educationalProfile.map((edu) => _buildEducationCard(_normalizeMap(edu))).toList())],
                      if (certificationList.isNotEmpty) ...[const SizedBox(height: 32), _buildSection('CERTIFICATIONS', Icons.verified_outlined, const Color(0xFFEC4899), certificationList.map((cert) { final certMap = _normalizeMap(cert); return _buildSimpleListCard(certMap['name']?.toString() ?? certMap['certificationName']?.toString() ?? 'Certification', certMap['organization']?.toString() ?? certMap['issuingAuthority']?.toString()); }).toList())],
                      if (publications.isNotEmpty) ...[const SizedBox(height: 32), _buildSection('PUBLICATIONS', Icons.menu_book, const Color(0xFF64748B), publications.map((p) => _buildSimpleTextItem(p)).toList())],
                      if (experienceDocs.isNotEmpty) ...[const SizedBox(height: 32), _buildSection('ATTACHED DOCUMENTS', Icons.attachment, const Color(0xFF099674), [Wrap(spacing: 12, runSpacing: 8, children: experienceDocs.map((doc) => _buildClickableLink(doc, const Color(0xFF099674), isDoc: true)).toList())])],
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

  // --- Mobile Modal (Preserved & Styled) ---

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
                height: 250,
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
              );
            }
            final details = snap.data;
            if (details == null) {
              return Container(
                height: 200,
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                child: const Center(child: Text('Failed to load details')),
              );
            }
            // (Reusing the exact same logic as details panel but adapted for mobile scroll)
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: _buildDetailsPanel(context, prov, details), // Reusing the main panel widget!
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- UI Component Helpers ---

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), letterSpacing: 1.2)),
            const SizedBox(width: 16),
            const Expanded(child: Divider(thickness: 1, color: Color(0xFFE2E8F0))),
          ],
        ),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.only(left: 32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          SelectableText(value, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF334155), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(text, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // ... (Keeping _buildExperienceCard, _buildEducationCard, _buildSimpleTextItem, _buildClickableLink, _buildSimpleListCard, _buildHeaderItem, _buildProfileAvatar, _buildInfoChip exactly as in original to ensure no logic loss, just implicit styling updates via GoogleFonts)

  Widget _buildExperienceCard(Map<String, dynamic> exp) {
    final role = exp['role']?.toString() ?? exp['jobTitle']?.toString() ?? exp['position']?.toString() ?? 'Position';
    final organization = exp['organization']?.toString() ?? exp['companyName']?.toString() ?? exp['company']?.toString() ?? '';
    final duration = exp['duration']?.toString() ?? "${exp['startDate'] ?? ''} - ${exp['endDate'] ?? 'Present'}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(role, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1E293B))),
        Text(organization, style: GoogleFonts.poppins(color: const Color(0xFF3B82F6), fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 4),
        Text(duration, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
      ]),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> edu) {
    final degree = edu['degree']?.toString() ?? edu['majorSubjects']?.toString() ?? 'Degree';
    final institution = edu['institution']?.toString() ?? edu['institutionName']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(institution, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
        Text(degree, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildSimpleTextItem(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.arrow_right, size: 18, color: Color(0xFF64748B)), Expanded(child: SelectableText(text, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF334155), height: 1.4)))]));

  Widget _buildClickableLink(String link, Color color, {bool isDoc = false}) => InkWell(onTap: () {}, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(6), color: color.withOpacity(0.05)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isDoc ? Icons.description_outlined : Icons.link, size: 14, color: color), const SizedBox(width: 6), Flexible(child: Text(link.length > 30 ? '${link.substring(0, 27)}...' : link, style: GoogleFonts.poppins(fontSize: 12, color: color, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis))])));

  Widget _buildSimpleListCard(String title, String? subtitle) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFDF4FF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.2))), child: Row(children: [const Icon(Icons.verified, color: Color(0xFFEC4899), size: 16), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))), if (subtitle != null) Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)))]))]));

  Widget _buildHeaderItem(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white70, size: 14), const SizedBox(width: 6), Flexible(child: SelectableText(text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)))]);

  Widget _buildProfileAvatar(Map<String, dynamic> profile, String name) {
    final url = profile['profilePicUrl']?.toString() ?? '';
    return Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 3), image: url.isNotEmpty ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null, color: url.isEmpty ? const Color(0xFF4F46E5) : null), child: url.isEmpty ? Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C', style: GoogleFonts.poppins(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))) : null);
  }
}

// --- Internal Widget: Request Card (Optimized) ---

class _RequestCard extends StatelessWidget {
  final String id, recruiterEmail, status, createdStr;
  final int totalCandidates;
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

  Color _getStatusColor() {
    final s = status.toLowerCase();
    if (s == 'active') return const Color(0xFF10B981);
    if (s == 'pending') return const Color(0xFFF59E0B);
    if (s == 'rejected') return const Color(0xFFEF4444);
    return const Color(0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
        border: Border(left: BorderSide(color: isSelected ? const Color(0xFF6366F1) : Colors.transparent, width: 4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFFF8FAFC),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('REQ #$id', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  Text(createdStr, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(recruiterEmail, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569), fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: _getStatusColor().withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(status.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: _getStatusColor())),
                  ),
                  const Spacer(),
                  Icon(Icons.people_outline, size: 14, color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text('$totalCandidates', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Internal Widget: Status Dropdown (Optimized) ---

class _ModernStatusDropdown extends StatelessWidget {
  final String currentStatus;
  final Function(String) onChanged;

  const _ModernStatusDropdown({required this.currentStatus, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getColor(currentStatus);
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => ['Pending', 'Active', 'Rejected', 'Closed']
          .map((s) => PopupMenuItem(
        value: s.toLowerCase(),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: _getColor(s), shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Text(s, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ],
        ),
      ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(currentStatus.toUpperCase(), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, size: 16, color: statusColor),
          ],
        ),
      ),
    );
  }

  Color _getColor(String s) {
    final status = s.toLowerCase();
    if (status == 'active') return const Color(0xFF10B981);
    if (status == 'pending') return const Color(0xFFF59E0B);
    if (status == 'rejected' || status == 'closed') return const Color(0xFFEF4444);
    return const Color(0xFF6366F1);
  }
}

// --- Internal Widget: Metadata Chip ---
class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSmall;

  const _MetadataChip({required this.icon, required this.label, required this.color, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isSmall ? 14 : 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: isSmall ? 12 : 13, color: color, fontWeight: FontWeight.w500)),
      ],
    );
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














class _CandidateCard extends StatelessWidget {
  final String name, email, phone, title, status;
  final Function(String) onMenuAction;
  final VoidCallback onTap;

  const _CandidateCard({
    Key? key,
    required this.name,
    required this.email,
    required this.phone,
    required this.title,
    required this.status,
    required this.onMenuAction,
    required this.onTap,
  }) : super(key: key);

  Color _getStatusColor() {
    final s = status.toLowerCase();
    if (s.contains('shortlist')) return const Color(0xFF6366F1); // Indigo
    if (s.contains('screening')) return const Color(0xFF3B82F6); // Blue
    if (s.contains('interview')) return const Color(0xFF8B5CF6); // Violet
    if (s.contains('hired') || s.contains('handover')) return const Color(0xFF10B981); // Emerald
    if (s.contains('rejected')) return const Color(0xFFEF4444); // Red
    return const Color(0xFF64748B); // Slate
  }

  @override
  Widget build(BuildContext context) {
    // Logic Preserved 100%
    final stages = ['Shortlist', 'Screening', 'Interview', 'Technical', 'Offer', 'Hired'];
    final displayStatus = status.toLowerCase() == 'shortlisted' ? 'shortlist' : status.toLowerCase();
    final currentIdx = stages.map((e) => e.toLowerCase()).toList().indexOf(displayStatus);
    final primaryColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            hoverColor: const Color(0xFFF1F5F9),
            splashColor: primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context, primaryColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatar(primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name and Title Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              height: 1.2,
                                              color: const Color(0xFF1E293B),
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                          if (title.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  color: primaryColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  decoration: TextDecoration.none,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Action Button positioned top-right of content area
                                    _buildActionButton(stages, currentIdx, primaryColor),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Contact Details (Grid-like responsive behavior)
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 4,
                                  children: [
                                    _buildIconText(Icons.email_outlined, email),
                                    if (phone.isNotEmpty)
                                      _buildIconText(Icons.phone_android_outlined, phone),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPipeline(currentIdx, stages.length, primaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.6,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(List<String> stages, int currentIdx, Color color) {
    if (currentIdx >= stages.length - 1 || currentIdx == -1) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {}, // Handled by PopupMenu
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF94A3B8)),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: onMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'open_cv',
                height: 40,
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(
                      'Open CV',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // "Next" Button
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onMenuAction(stages[currentIdx + 1].toLowerCase()),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NEXT STEP',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipeline(int currentIdx, int total, Color color) {
    return SizedBox(
      height: 4,
      child: Row(
        children: List.generate(total, (index) {
          final isActive = index <= currentIdx;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: index == total - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: isActive ? color : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}