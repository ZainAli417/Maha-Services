// JobDetailModal_recruiter.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Recruiter/Recruiter_provider_Job_listing.dart';


class JobDetailModal extends StatelessWidget {
  final String jobId; // now accept jobId and fetch from provider

  const JobDetailModal({super.key, required this.jobId});

  // --- Professional Color Palette (Slate & Indigo) ---
  static const Color _bgSurface = Colors.white;
  static const Color _bgBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color _textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color _textSecondary = Color(0xFF64748B); // Slate 500
  static const Color _accentPrimary = Color(0xFF4F46E5); // Indigo 600
  static const Color _borderColor = Color(0xFFE2E8F0); // Slate 200
  static const Color _dangerColor = Color(0xFFEF4444); // Red 500
  static const Color _successColor = Color(0xFF10B981); // Emerald 500

  // Helper to safely get job from provider
  Map<String, dynamic>? _findJob(BuildContext context) {
    final provider = Provider.of<job_listing_provider>(context, listen: true);
    try {
      final job = provider.jobList.firstWhere((j) {
        final id = j['id']?.toString();
        return id != null && id == jobId;
      }, orElse: () => <String, dynamic>{});
      if (job.isEmpty) return null;
      return Map<String, dynamic>.from(job);
    } catch (_) {
      return null;
    }
  }

  // Safely parse a Firestore Timestamp or ISO string to readable string
  String _fmtDate(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.year}-${_two(d.month)}-${_two(d.day)}';
    }
    if (ts is String) {
      // try to parse ISO
      try {
        final d = DateTime.parse(ts);
        return '${d.year}-${_two(d.month)}-${_two(d.day)}';
      } catch (_) {
        return ts;
      }
    }
    if (ts is DateTime) {
      final d = ts;
      return '${d.year}-${_two(d.month)}-${_two(d.day)}';
    }
    return ts.toString();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
        future: _fetchJobFromFirestore(),
        builder: (context, snapshot) {
          // Show loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading job details...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show error state
          if (snapshot.hasError || snapshot.data == null) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: _dangerColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Job not found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This job may have been removed or archived.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ✅ Job data loaded successfully
          final jobData = snapshot.data!;
    // --- Extract fields (use same keys your listing uses) ---
    final title = jobData['title'] as String? ?? 'Untitled Position';
    final company = jobData['company'] as String? ?? 'Unknown Company';
    final logoUrl = jobData['logoUrl'] as String? ?? '';
    final description =
        jobData['description'] as String? ?? 'No description provided.';
    final responsibilities =
        jobData['responsibilities'] as String? ??
            jobData['responsibilitiesHtml'] ??
            'Not specified.';
    final qualifications =
        jobData['qualifications'] as String? ?? 'Not specified.';
    final skills =
        (jobData['skills'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final workModes =
        (jobData['workModes'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final benefits =
        (jobData['benefits'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final department = jobData['department'] as String? ?? '';
    final experience = jobData['experience'] as String? ?? '';
    final deadline = _fmtDate(
      jobData['deadline'] ?? jobData['applicationDeadline'],
    );
    final contact =
        jobData['contactEmail'] as String? ??
            jobData['contact'] as String? ??
            '';
    final status = (jobData['status'] as String?)?.toLowerCase() ?? 'active';
    final jobIdField = jobData['id']?.toString() ?? jobId;
    final salary = jobData['salary'] ?? jobData['pay'] ?? 'Not disclosed';
    final nature = jobData['nature'] ?? jobData['type'] ?? 'Full-time';
    final timestampRaw = jobData['timestamp'];

    // Extract view count and application count
    final viewCount = jobData['viewCount'] ?? 0;
    final applicationCount = jobData['applicationCount'] ?? 0;

    // Build UI (keeps your original widgets + wiring to provider functions)
    return Dialog(
      backgroundColor: _bgSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
          color: _bgSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _borderColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: logoUrl.isNotEmpty
                          ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.business,
                            color: _textSecondary,
                          ),
                        ),
                      )
                          : const Center(
                        child: Icon(
                          Icons.business,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title & Company
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: _textSecondary),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: _borderColor),

            // Meta Row
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _buildMetaItem(
                      Icons.payments_outlined,
                      'Salary',
                      salary.toString(),
                    ),
                    const VerticalDivider(color: _borderColor, width: 32),
                    _buildMetaItem(
                      Icons.work_outline,
                      'Job Type',
                      nature.toString(),
                    ),
                    const VerticalDivider(color: _borderColor, width: 32),
                    _buildMetaItem(
                      Icons.location_on_outlined,
                      'Location',
                      jobData['location']?.toString() ?? 'Remote',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Content area
            Expanded(
              child: Container(
                color: _bgBackground,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Meta Row (deadline, dept, posted date)
                      Row(
                        children: [
                          _infoBadge('Department', department),
                          const SizedBox(width: 5),
                          // _infoBadge('Experience', experience),
                          //  const SizedBox(width: 5),
                          if (deadline.isNotEmpty)
                            _infoBadge('Deadline', deadline),
                          const SizedBox(width: 5),

                          if (timestampRaw != null)
                            Text(
                              'Posted: ${_fmtDate(timestampRaw)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // About the Role
                      _buildSectionTitle('About the Role'),
                      _buildRichText(description),
                      const SizedBox(height: 24),

                      // Key Responsibilities
                      _buildSectionTitle('Key Responsibilities'),
                      _buildRichText(responsibilities),
                      const SizedBox(height: 24),

                      // Qualifications
                      _buildSectionTitle('Qualifications'),
                      _buildRichText(qualifications),
                      const SizedBox(height: 32),

                      // Sidebar Cards row (skills, work mode, benefits)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 550,
                              child: _buildSidebarDetails(
                                  skills,
                                  workModes,
                                  benefits,
                                  department,
                                  experience,
                                  deadline,
                                  contact,
                                  viewCount.toString(),
                                  applicationCount.toString()
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),


          ],
        ),
      ),
    );

        }
    );
  }
  // Reusable small widgets

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
      ),
    );
  }

  Widget _buildRichText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 15,
        height: 1.6,
        color: const Color(0xFF334155),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }


  Widget _buildSidebarDetails(
      List<String> skills,
      List<String> workModes,
      List<String> benefits,
      String department,
      String experience,
      String deadline,
      String contact,
      String applicationCount,
      String viewCount,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarCard(
          title: 'Required Skills',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((e) => _buildChip(e, _accentPrimary)).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildSidebarCard(
          title: 'Work Arrangements',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: workModes
                .map((e) => _buildChip(e, Colors.orange.shade700))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildSidebarCard(
          title: 'Perks & Benefits',
          child: Column(
            children: benefits
                .map(
                  (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: _successColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
                .toList(),
          ),
        ),

      ],
    );
  }

  Widget _buildSidebarCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }



  Widget _infoBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchJobFromFirestore() async {
    final doc = await FirebaseFirestore.instance
        .collection('Posted_jobs_public')
        .doc(jobId)
        .get();
    return doc.exists ? {...doc.data()!, 'id': doc.id} : null;
  }
}
