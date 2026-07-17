import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'R_Top_Bar.dart';
import 'Recruiter_provider_Job_listing.dart';
import 'job_detail_dialog_recrutier.dart';
import '../../Constant/js_header.dart';

const _primary = Color(0xFF14507F);
const _primaryLight = Color(0xFFE8F1F8);
const _textPrimary = Color(0xFF0B2239);
const _textSecondary = Color(0xFF5E7A8E);
const _border = Color(0xFFDCE7EF);
const _bgWhite = Color(0xFFF4F9FB);
const _bgLight = Color(0xFFF4F9FB);
const _success = Color(0xFF10B981);
const _successLight = Color(0xFFF0FDF4);
const _warning = Color(0xFFFB923C);
const _info = Color(0xFF2178B5);

class ArchivedJobsScreen extends StatefulWidget {
  const ArchivedJobsScreen({super.key});

  @override
  State<ArchivedJobsScreen> createState() => _ArchivedJobsScreenState();
}

class _ArchivedJobsScreenState extends State<ArchivedJobsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgWhite,
      drawer: isMobile
          ? const Drawer(child: RecruiterSidebar(activeIndex: 5, isDrawer: true))
          : null,
      body: Row(
        children: [
          if (!isMobile) const RecruiterSidebar(activeIndex: 5),
          Expanded(
            child: Column(
              children: [
                _ArchivedHeader(
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: Consumer<job_listing_provider>(
                    builder: (context, provider, _) {
                      if (!provider.isInitialized) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 60,
                                width: 60,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _primary,
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading archived jobs...',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: _textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final jobs = provider.archivedJobList;
                      if (jobs.isEmpty) {
                        return const _EmptyArchivedJobs();
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 28,
                          vertical: isMobile ? 16 : 24,
                        ),
                        itemCount: jobs.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ArchivedJobCard(job: jobs[index]),
                        ),
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
}

class _ArchivedHeader extends StatelessWidget {
  final VoidCallback onMenu;

  const _ArchivedHeader({required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return JobSeekerHeader(
      icon: Icons.archive_rounded,
      title: 'Archived Jobs',
      subtitle: 'Manage and restore your hidden job postings',
      onMenu: onMenu,
    );
  }
}

class _ArchivedJobCard extends StatefulWidget {
  final Map<String, dynamic> job;

  const _ArchivedJobCard({required this.job});

  @override
  State<_ArchivedJobCard> createState() => _ArchivedJobCardState();
}

class _ArchivedJobCardState extends State<_ArchivedJobCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final jobId = widget.job['id']?.toString() ?? '';
    final title = widget.job['title']?.toString() ?? 'Untitled job';
    final company = widget.job['company']?.toString() ?? 'Unknown company';
    final location = widget.job['location']?.toString() ?? 'Unknown location';
    final applications = widget.job['applicationCount'] ?? 0;
    final views = widget.job['viewCount'] ?? 0;
    final isMobile = MediaQuery.sizeOf(context).width < 680;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? _primary.withValues(alpha: 0.3) : _border,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? _primary.withValues(alpha: 0.12)
                  : const Color(0xFF000000).withValues(alpha: 0.05),
              blurRadius: _isHovered ? 12 : 6,
              offset: Offset(0, _isHovered ? 6 : 2),
              spreadRadius: _isHovered ? 0 : 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primaryLight,
                        _primaryLight.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.archive_rounded,
                    color: _primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 16 : 17,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.business_outlined,
                            size: 14,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: _textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: _textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isMobile) const SizedBox(width: 12),
                if (!isMobile) const _ArchivedBadge(),
              ],
            ),
            const SizedBox(height: 16),

            // Metrics Row
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border, width: 0.8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricDisplay(
                      icon: Icons.person_outline,
                      count: applications,
                      label: 'Applications',
                      primaryColor: _info,
                      lightColor: _info.withValues(alpha: 0.1),
                    ),
                  ),
                  const _MetricDivider(),
                  Expanded(
                    child: _MetricDisplay(
                      icon: Icons.visibility_outlined,
                      count: views,
                      label: 'Views',
                      primaryColor: _warning,
                      lightColor: _warning.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mobile Badge
            if (isMobile) ...[
              const _ArchivedBadge(),
              const SizedBox(height: 14),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: jobId.isEmpty
                        ? null
                        : () => showDialog(
                            context: context,
                            builder: (_) =>
                                JobDetailModal_recruiter(jobId: jobId),
                          ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: _border, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      foregroundColor: _primary,
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(
                      'View Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: jobId.isEmpty
                        ? null
                        : () => _restoreJob(context, jobId),
                    style: FilledButton.styleFrom(
                      backgroundColor: _success,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: Text(
                      'Restore',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreJob(BuildContext context, String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Restore Job?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
        content: Text(
          'This job will be activated and visible in your active listings again.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: _textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: _textSecondary,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Restore',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final provider = context.read<job_listing_provider>();
    final error = await provider.restoreJob(jobId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              'Job restored successfully! It is now visible to candidates.',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error == null ? _success : const Color(0xFFEF4444),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 40,
        width: 1.5,
        decoration: BoxDecoration(
          color: _border,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class _MetricDisplay extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color primaryColor;
  final Color lightColor;

  const _MetricDisplay({
    required this.icon,
    required this.count,
    required this.label,
    required this.primaryColor,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: lightColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArchivedBadge extends StatelessWidget {
  const _ArchivedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _warning.withValues(alpha: 0.15),
            _warning.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _warning.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.archive_rounded, size: 12, color: _warning),
          const SizedBox(width: 4),
          Text(
            'Archived',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _warning,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyArchivedJobs extends StatelessWidget {
  const _EmptyArchivedJobs();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primaryLight, _primaryLight.withValues(alpha: 0.5)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.archive_outlined,
                size: 50,
                color: _primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Archived Jobs',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'When you archive jobs from your active listings, they will appear here. Archive jobs to temporarily hide them without permanently deleting them.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: _primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pro tip: You can restore archived jobs anytime to make them active again.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
