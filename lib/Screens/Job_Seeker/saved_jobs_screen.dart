import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'JS_Top_Bar.dart';
import 'Job_Detail_Dialog.dart';
import 'saved_jobs_provider.dart';
import '../../Constant/js_header.dart';

// ── Brand palette ──────────────────────────────────────────────────────────
const _kNavy = Color(0xFF14507F);
const _kTeal = Color(0xFF2EC4B6);
const _kInk = Color(0xFF0B2239);
const _kSlate = Color(0xFF3E5C76);
const _kMuted = Color(0xFF5E7A8E);
const _kFaint = Color(0xFF8AA5B5);
const _kBorder = Color(0xFFDCE7EF);
const _kBgSoft = Color(0xFFF4F9FB);
const _kTealTint = Color(0xFFE4F6F4);
const _kNavyTint = Color(0xFFE8F1F8);
const _kError = Color(0xFFEF4444);

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBgSoft,
      drawer: isMobile
          ? Drawer(child: JobSeekerSidebar(activeIndex: 5, isDrawer: true))
          : null,
      body: Row(
        children: [
          if (!isMobile) const JobSeekerSidebar(activeIndex: 5),
          Expanded(
            child: Column(
              children: [
                JobSeekerHeader(
                  icon: Icons.bookmark_rounded,
                  title: 'Saved Jobs',
                  subtitle: 'Keep track of opportunities you want to revisit',
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: Consumer<SavedJobsProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const _BrandedLoading(
                          message: 'Loading saved jobs…',
                        );
                      }
                      if (provider.error != null) {
                        return _BrandedEmpty(
                          icon: Icons.error_outline_rounded,
                          title: 'Unable to load saved jobs',
                          subtitle: provider.error!,
                          accent: _kError,
                          isMobile: isMobile,
                        );
                      }
                      final ids = provider.savedJobIds.toList();
                      if (ids.isEmpty) {
                        return _BrandedEmpty(
                          icon: Icons.bookmark_border_rounded,
                          title: 'No saved jobs yet',
                          subtitle:
                              'Tap the bookmark button on a job to save it here and revisit it anytime.',
                          isMobile: isMobile,
                          actionLabel: 'Browse jobs',
                          onAction: () => context.go('/job-hub'),
                        );
                      }
                      return _SavedJobsList(jobIds: ids, isMobile: isMobile);
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

// ── List ────────────────────────────────────────────────────────────────────
class _SavedJobsList extends StatelessWidget {
  final List<String> jobIds;
  final bool isMobile;

  const _SavedJobsList({required this.jobIds, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadJobs(jobIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _BrandedLoading(message: 'Fetching job details…');
        }
        final jobs = snapshot.data!;
        if (jobs.isEmpty) {
          return _BrandedEmpty(
            icon: Icons.visibility_off_outlined,
            title: 'Saved jobs are no longer active',
            subtitle:
                'Archived or paused jobs are hidden from job seekers.',
            isMobile: isMobile,
            actionLabel: 'Browse jobs',
            onAction: () => context.go('/job-hub'),
          );
        }

        final pad = isMobile ? 12.0 : 24.0;
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 24),
          cacheExtent: 700,
          itemCount: jobs.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: _SavedJobCard(
                  jobData: jobs[index],
                  isMobile: isMobile,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadJobs(List<String> ids) async {
    final db = FirebaseFirestore.instance;
    final jobs = <Map<String, dynamic>>[];

    for (final id in ids) {
      try {
        final doc = await db.collection('Posted_jobs_public').doc(id).get();
        final data = doc.data();
        if (!doc.exists || data == null) continue;
        final status = (data['status'] ?? 'active').toString().toLowerCase();
        if (status != 'active') continue;
        jobs.add({...data, 'id': doc.id});
      } catch (_) {
        continue;
      }
    }

    return jobs;
  }
}

// ── Branded saved-job card ────────────────────────────────────────────────────
class _SavedJobCard extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final bool isMobile;

  const _SavedJobCard({required this.jobData, required this.isMobile});

  @override
  State<_SavedJobCard> createState() => _SavedJobCardState();
}

class _SavedJobCardState extends State<_SavedJobCard> {
  bool _hover = false;

  String _relativeTime(Timestamp? ts) {
    if (ts == null) return '';
    final d = DateTime.now().difference(ts.toDate());
    if (d.inDays > 30) return '${(d.inDays / 30).floor()}mo ago';
    if (d.inDays >= 1) return '${d.inDays}d ago';
    if (d.inHours >= 1) return '${d.inHours}h ago';
    if (d.inMinutes >= 1) return '${d.inMinutes}m ago';
    return 'just now';
  }

  void _viewDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobDetailModal(jobId: widget.jobData['id'] as String),
    );
  }

  void _unsave() {
    context.read<SavedJobsProvider>().toggleSaved(widget.jobData);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kInk,
          content: Text(
            'Removed from saved jobs',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.jobData;
    final isMobile = widget.isMobile;
    final title = job['title'] as String? ?? 'Untitled role';
    final company = job['company'] as String? ?? 'Unknown Company';
    final department = job['department'] as String? ?? '';
    final location = job['location'] as String? ?? '';
    final logoUrl = job['logoUrl'] as String?;
    final skills = (job['skills'] as List<dynamic>?)?.cast<String>() ?? const [];
    final postedAgo = _relativeTime(job['timestamp'] as Timestamp?);

    final cardPad = isMobile ? 14.0 : 18.0;
    final logoSize = isMobile ? 44.0 : 54.0;
    final titleSize = isMobile ? 15.0 : 17.0;
    final radius = isMobile ? 16.0 : 18.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _viewDetails,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          padding: EdgeInsets.all(cardPad),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: _hover ? _kTeal.withValues(alpha: 0.5) : _kBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: _hover
                    ? _kTeal.withValues(alpha: 0.18)
                    : _kInk.withValues(alpha: 0.05),
                blurRadius: _hover ? 22 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LogoTile(
                    url: logoUrl,
                    size: logoSize,
                    company: company,
                  ),
                  SizedBox(width: isMobile ? 12 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w600,
                            color: _kNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  _UnsaveButton(onTap: _unsave, isMobile: isMobile),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 12),
              // Meta row — stacks/wraps, brand icons, no overflow.
              Wrap(
                spacing: isMobile ? 8 : 12,
                runSpacing: 6,
                children: [
                  if (department.isNotEmpty)
                    _MetaItem(
                      icon: Icons.apartment_rounded,
                      label: department,
                      isMobile: isMobile,
                    ),
                  if (location.isNotEmpty)
                    _MetaItem(
                      icon: Icons.location_on_outlined,
                      label: location,
                      isMobile: isMobile,
                    ),
                  if (postedAgo.isNotEmpty)
                    _MetaItem(
                      icon: Icons.schedule_rounded,
                      label: postedAgo,
                      isMobile: isMobile,
                    ),
                ],
              ),
              if (skills.isNotEmpty) ...[
                SizedBox(height: isMobile ? 10 : 12),
                _SkillChips(skills: skills, isMobile: isMobile),
              ],
              SizedBox(height: isMobile ? 12 : 14),
              const Divider(height: 1, color: _kBorder),
              SizedBox(height: isMobile ? 10 : 12),
              Row(
                children: [
                  Expanded(
                    child: _GhostButton(
                      icon: Icons.bookmark_remove_outlined,
                      label: 'Remove',
                      onTap: _unsave,
                      isMobile: isMobile,
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: _GradientButton(
                      icon: Icons.arrow_forward_rounded,
                      label: 'View details',
                      onTap: _viewDetails,
                      isMobile: isMobile,
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

class _LogoTile extends StatelessWidget {
  final String? url;
  final double size;
  final String company;
  const _LogoTile({required this.url, required this.size, required this.company});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kNavyTint, _kTealTint],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        company.isNotEmpty ? company.characters.first.toUpperCase() : '?',
        style: GoogleFonts.plusJakartaSans(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: _kNavy,
        ),
      ),
    );

    if (url == null || url!.isEmpty) return fallback;

    final px = (size * 2).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        child: CachedNetworkImage(
          imageUrl: url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: px,
          memCacheHeight: px,
          placeholder: (_, _) => Container(color: _kBgSoft),
          errorWidget: (_, _, _) => fallback,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isMobile;
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isMobile ? 14 : 15, color: _kFaint),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? 150 : 220),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 11.5 : 12.5,
              fontWeight: FontWeight.w500,
              color: _kMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillChips extends StatelessWidget {
  final List<String> skills;
  final bool isMobile;
  const _SkillChips({required this.skills, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final maxChips = isMobile ? 3 : 5;
    final visible = skills.take(maxChips).toList();
    final extra = skills.length - visible.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in visible)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 10,
              vertical: isMobile ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: _kTeal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _kTeal.withValues(alpha: 0.3)),
            ),
            child: Text(
              s,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 10.5 : 11.5,
                fontWeight: FontWeight.w600,
                color: _kTeal,
              ),
            ),
          ),
        if (extra > 0)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 10,
              vertical: isMobile ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: _kNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _kNavy.withValues(alpha: 0.2)),
            ),
            child: Text(
              '+$extra',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 10.5 : 11.5,
                fontWeight: FontWeight.w700,
                color: _kNavy,
              ),
            ),
          ),
      ],
    );
  }
}

class _UnsaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isMobile;
  const _UnsaveButton({required this.onTap, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final s = isMobile ? 34.0 : 38.0;
    return Tooltip(
      message: 'Remove from saved',
      child: Material(
        color: _kError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: s,
            height: s,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kError.withValues(alpha: 0.25)),
            ),
            child: Icon(
              Icons.bookmark_remove_rounded,
              size: isMobile ? 18 : 20,
              color: _kError,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isMobile;
  const _GradientButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: isMobile ? 42 : 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kTeal, _kNavy],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _kTeal.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12.5 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: isMobile ? 16 : 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isMobile;
  const _GhostButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: isMobile ? 42 : 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kNavy.withValues(alpha: 0.5), width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: isMobile ? 16 : 18, color: _kNavy),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12.5 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Branded loading / empty / error ───────────────────────────────────────────
class _BrandedLoading extends StatelessWidget {
  final String message;
  const _BrandedLoading({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _kNavy.withValues(alpha: 0.08),
                  _kTeal.withValues(alpha: 0.10),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(_kTeal),
                backgroundColor: _kNavyTint,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandedEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool isMobile;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _BrandedEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isMobile,
    this.accent = _kNavy,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 20 : 26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.12),
                    _kTeal.withValues(alpha: 0.12),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, size: isMobile ? 40 : 52, color: accent),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 17 : 20,
                fontWeight: FontWeight.w800,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12.5 : 13.5,
                  fontWeight: FontWeight.w500,
                  color: _kMuted,
                  height: 1.4,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: isMobile ? 20 : 24),
              _GradientButton(
                icon: Icons.search_rounded,
                label: actionLabel!,
                onTap: onAction!,
                isMobile: isMobile,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
