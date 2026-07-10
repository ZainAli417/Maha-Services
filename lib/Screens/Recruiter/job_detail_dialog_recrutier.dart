// JobDetailModal_recruiter.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/quill_editor.dart';
import 'Recruiter_provider_Job_listing.dart';

class JobDetailModal_recruiter extends StatelessWidget {
  final String jobId;
  const JobDetailModal_recruiter({super.key, required this.jobId});

  // ─── Color Palette ────────────────────────────────────────────────────────
  static const Color _bgSurface = Colors.white;
  static const Color _bgBackground = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _accentPrimary = Color(0xFF4F46E5);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _dangerColor = Color(0xFFEF4444);
  static const Color _successColor = Color(0xFF10B981);

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _fmtDate(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.year}-${_two(d.month)}-${_two(d.day)}';
    }
    if (ts is String) {
      try {
        final d = DateTime.parse(ts);
        return '${d.year}-${_two(d.month)}-${_two(d.day)}';
      } catch (_) {
        return ts;
      }
    }
    if (ts is DateTime) return '${ts.year}-${_two(ts.month)}-${_two(ts.day)}';
    return ts.toString();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Stream<Map<String, dynamic>?> _jobStream() {
    return FirebaseFirestore.instance
        .collection('Posted_jobs_public')
        .doc(jobId)
        .snapshots(includeMetadataChanges: true)
        .map((doc) => doc.exists ? {...doc.data()!, 'id': doc.id} : null);
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isMobile = screenW < 600;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _jobStream(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _wrapDialog(
            isMobile: isMobile,
            screenW: screenW,
            screenH: screenH,
            child: SizedBox(
              height: 160,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(
                    'Loading job details…',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Error / Not found
        if (snapshot.hasError || snapshot.data == null) {
          return _wrapDialog(
            isMobile: isMobile,
            screenW: screenW,
            screenH: screenH,
            child: SizedBox(
              height: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: _dangerColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Job not found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'This job may have been removed or archived.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ── Data ready ──────────────────────────────────────────────────────
        final jobData = snapshot.data!;
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
        final skills = (jobData['skills'] as List?)?.cast<String>() ?? [];
        final workModes = (jobData['workModes'] as List?)?.cast<String>() ?? [];
        final benefits = (jobData['benefits'] as List?)?.cast<String>() ?? [];
        final department = jobData['department'] as String? ?? '';
        final experience = jobData['experience'] as String? ?? '';
        final deadline = _fmtDate(
          jobData['deadline'] ?? jobData['applicationDeadline'],
        );
        final contact =
            jobData['contactEmail'] as String? ??
            jobData['contact'] as String? ??
            '';
        final rawStatus =
            (jobData['status'] as String?)?.toLowerCase() ?? 'active';
        final status = rawStatus == 'archive' ? 'archived' : rawStatus;
        final jobIdField = jobData['id']?.toString() ?? jobId;
        final salary = jobData['salary'] ?? jobData['pay'] ?? 'Not disclosed';
        final nature = jobData['nature'] ?? jobData['type'] ?? 'Full-time';
        final location = jobData['location']?.toString() ?? 'Remote';
        final timestampRaw = jobData['timestamp'];
        final viewCount = jobData['viewCount'] ?? 0;
        final applicationCount = jobData['applicationCount'] ?? 0;

        return _wrapDialog(
          isMobile: isMobile,
          screenW: screenW,
          screenH: screenH,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 20,
                  vertical: isMobile ? 14 : 20,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Container(
                      width: isMobile ? 44 : 56,
                      height: isMobile ? 44 : 56,
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
                                errorBuilder: (_, _, _) => const Center(
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
                    const SizedBox(width: 12),
                    // Title & company
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 15 : 20,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            company,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 12 : 14,
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: _textSecondary,
                        ),
                        tooltip: 'Close',
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: _borderColor),

              // ── Meta strip (salary / type / location) ─────────────────
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 20,
                  vertical: isMobile ? 10 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: _borderColor)),
                ),
                child: isMobile
                    // On mobile: 3 chips in a Wrap to avoid overflow
                    ? Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _metaChip(Icons.payments_outlined, salary.toString()),
                          _metaChip(Icons.work_outline, nature.toString()),
                          _metaChip(Icons.location_on_outlined, location),
                        ],
                      )
                    // Desktop: horizontal row with dividers
                    : IntrinsicHeight(
                        child: Row(
                          children: [
                            _buildMetaItem(
                              Icons.payments_outlined,
                              'Salary',
                              salary.toString(),
                            ),
                            const VerticalDivider(
                              color: _borderColor,
                              width: 32,
                            ),
                            _buildMetaItem(
                              Icons.work_outline,
                              'Job Type',
                              nature.toString(),
                            ),
                            const VerticalDivider(
                              color: _borderColor,
                              width: 32,
                            ),
                            _buildMetaItem(
                              Icons.location_on_outlined,
                              'Location',
                              location,
                            ),
                          ],
                        ),
                      ),
              ),

              // ── Scrollable content ────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info badges row
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (department.isNotEmpty)
                            _infoBadge('Dept', department, isMobile),
                          if (deadline.isNotEmpty)
                            _infoBadge('Deadline', deadline, isMobile),
                          if (timestampRaw != null)
                            _infoBadge(
                              'Posted',
                              _fmtDate(timestampRaw),
                              isMobile,
                            ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 16 : 24),

                      // About the Role
                      _buildSectionTitle('About the Role', isMobile),
                      AppRichTextViewer(
                        deltaOrPlainText: description,
                        fontSize: isMobile ? 13 : 15,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),

                      // Key Responsibilities
                      _buildSectionTitle('Key Responsibilities', isMobile),
                      AppRichTextViewer(
                        deltaOrPlainText: responsibilities,
                        fontSize: isMobile ? 13 : 15,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),

                      // Qualifications
                      _buildSectionTitle('Qualifications', isMobile),
                      AppRichTextViewer(
                        deltaOrPlainText: qualifications,
                        fontSize: isMobile ? 13 : 15,
                      ),
                      SizedBox(height: isMobile ? 20 : 32),

                      // Sidebar detail cards — full width stacked on mobile,
                      // horizontal scroll on desktop
                      isMobile
                          ? _buildSidebarDetails(
                              skills,
                              workModes,
                              benefits,
                              department,
                              experience,
                              deadline,
                              contact,
                              viewCount.toString(),
                              applicationCount.toString(),
                              isMobile,
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: 580,
                                child: _buildSidebarDetails(
                                  skills,
                                  workModes,
                                  benefits,
                                  department,
                                  experience,
                                  deadline,
                                  contact,
                                  viewCount.toString(),
                                  applicationCount.toString(),
                                  isMobile,
                                ),
                              ),
                            ),

                      // Bottom safe-area padding for mobile
                      if (isMobile) const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: _borderColor),

              // ── Footer actions ────────────────────────────────────────
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 20,
                  vertical: isMobile ? 10 : 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: isMobile
                    // Mobile: stack status + archive vertically
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (status != 'archived')
                            _buildStatusToggle(
                              context,
                              status,
                              jobIdField,
                              jobData,
                              isMobile,
                            ),
                          const SizedBox(height: 8),
                          _buildArchiveButton(
                            context,
                            jobIdField,
                            isMobile,
                            status,
                          ),
                        ],
                      )
                    // Desktop: horizontal row
                    : Row(
                        children: [
                          if (status != 'archived')
                            _buildStatusToggle(
                              context,
                              status,
                              jobIdField,
                              jobData,
                              isMobile,
                            ),
                          const Spacer(),
                          _buildArchiveButton(
                            context,
                            jobIdField,
                            isMobile,
                            status,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Dialog wrapper ───────────────────────────────────────────────────────
  Widget _wrapDialog({
    required bool isMobile,
    required double screenW,
    required double screenH,
    required Widget child,
  }) {
    return Dialog(
      backgroundColor: _bgSurface,
      // On mobile use tighter insets so dialog is near-fullscreen
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Container(
        // Cap width on desktop; fill on mobile
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 740,
          maxHeight: screenH * (isMobile ? 0.93 : 0.88),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
          color: _bgSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
      ),
    );
  }

  // ─── Footer sub-widgets ───────────────────────────────────────────────────

  Widget _buildStatusToggle(
    BuildContext context,
    String status,
    String jobIdField,
    Map<String, dynamic> jobData,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: _bgBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Text(
            'Job Status:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 12 : 13,
              color: _textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: status == 'active',
            activeColor: _successColor,
            onChanged: (val) async {
              final provider = Provider.of<job_listing_provider>(
                context,
                listen: false,
              );
              final error = await provider.toggleJobStatus(
                jobIdField,
                jobData['status']?.toString() ?? 'paused',
              );
              if (error == null) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(val ? 'Job Activated' : 'Job Paused')),
                );
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed: $error')));
              }
            },
          ),
          const SizedBox(width: 6),
          Text(
            status == 'active' ? 'Active' : 'Paused',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: status == 'active' ? _successColor : _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveButton(
    BuildContext context,
    String jobIdField,
    bool isMobile,
    String status,
  ) {
    final isArchived = status == 'archived';
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: isMobile ? 8 : 10,
        ),
      ),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isArchived ? 'Restore Job' : 'Archive Job'),
            content: Text(
              isArchived
                  ? 'Restore this job and make it active again?'
                  : 'Archive this job? It will disappear from candidate job feeds.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  isArchived ? 'Restore' : 'Archive',
                  style: TextStyle(
                    color: isArchived ? _successColor : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final provider = Provider.of<job_listing_provider>(
            context,
            listen: false,
          );
          final error = isArchived
              ? await provider.restoreJob(jobIdField)
              : await provider.archiveJob(jobIdField);
          if (error != null && context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          }
          Navigator.of(context).pop();
        }
      },
      icon: Icon(
        isArchived ? Icons.restore_rounded : Icons.archive_outlined,
        size: 18,
        color: isArchived ? _successColor : _dangerColor,
      ),
      label: Text(
        isArchived ? 'Restore' : 'Archive',
        style: GoogleFonts.plusJakartaSans(
          color: isArchived ? _successColor : _dangerColor,
          fontSize: isMobile ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Small reusable widgets ───────────────────────────────────────────────

  /// Compact chip for mobile meta strip
  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bgBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _textSecondary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: isMobile ? 13 : 16,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, bool isMobile) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 11 : 13,
              color: _textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(String label, String value, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 10 : 12,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sidebar detail cards ─────────────────────────────────────────────────

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
    bool isMobile,
  ) {
    final gap = SizedBox(height: isMobile ? 10 : 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (skills.isNotEmpty) ...[
          _buildSidebarCard(
            title: 'Required Skills',
            isMobile: isMobile,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills
                  .map((e) => _buildChip(e, _accentPrimary, isMobile))
                  .toList(),
            ),
          ),
          gap,
        ],
        if (workModes.isNotEmpty) ...[
          _buildSidebarCard(
            title: 'Work Arrangements',
            isMobile: isMobile,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: workModes
                  .map((e) => _buildChip(e, Colors.orange.shade700, isMobile))
                  .toList(),
            ),
          ),
          gap,
        ],
        if (benefits.isNotEmpty) ...[
          _buildSidebarCard(
            title: 'Perks & Benefits',
            isMobile: isMobile,
            child: Column(
              children: benefits
                  .map(
                    (e) => Padding(
                      padding: EdgeInsets.only(bottom: isMobile ? 6 : 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: _successColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isMobile ? 12 : 13,
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
          gap,
        ],
        _buildSidebarCard(
          title: 'Additional Info',
          isMobile: isMobile,
          child: Column(
            children: [
              _buildInfoRow('Department', department, isMobile),
              _buildInfoRow('Experience', experience, isMobile),
              _buildInfoRow('Deadline', deadline, isMobile),
              _buildInfoRow('Contact', contact, isMobile),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarCard({
    required String title,
    required Widget child,
    required bool isMobile,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 20),
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isMobile ? 10 : 16),
          child,
        ],
      ),
    );
  }
}
