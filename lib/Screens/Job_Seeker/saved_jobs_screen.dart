import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_view.dart';
import 'JS_Top_Bar.dart';
import 'Job_seeker_Available_jobs.dart';
import 'saved_jobs_provider.dart';

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
      backgroundColor: Colors.white,
      drawer: isMobile
          ? Drawer(child: JobSeekerSidebar(activeIndex: 5, isDrawer: true))
          : null,
      body: Row(
        children: [
          if (!isMobile) const JobSeekerSidebar(activeIndex: 5),
          Expanded(
            child: Column(
              children: [
                _SavedJobsTopBar(
                  isMobile: isMobile,
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: Consumer<SavedJobsProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const LoadingView(message: 'Loading saved jobs…');
                      }
                      if (provider.error != null) {
                        return EmptyState(
                          icon: Icons.error_outline_rounded,
                          title: 'Unable to load saved jobs',
                          subtitle: provider.error!,
                          iconColor: const Color(0xFFEF4444),
                        );
                      }
                      final ids = provider.savedJobIds.toList();
                      if (ids.isEmpty) {
                        return const EmptyState(
                          icon: Icons.bookmark_border_rounded,
                          title: 'No saved jobs yet',
                          subtitle:
                              'Tap the bookmark button on a job to save it here.',
                        );
                      }
                      return _SavedJobsList(jobIds: ids);
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

class _SavedJobsTopBar extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onMenu;

  const _SavedJobsTopBar({required this.isMobile, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF14507F);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF475569);

    final hPad = isMobile ? 12.0 : 24.0;
    final vPad = isMobile ? 10.0 : 16.0;
    final iconSize = isMobile ? 18.0 : 24.0;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            if (isMobile) ...[
              IconButton(
                icon: const Icon(Icons.menu_rounded, size: 24),
                onPressed: onMenu,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
            ],
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bookmark_outline_rounded,
                size: iconSize,
                color: primaryBlue,
              ),
            ),
            SizedBox(width: isMobile ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Saved Jobs',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'Keep track of opportunities you want to revisit',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 11 : 12,
                      color: textSecondary,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _SavedJobsList extends StatelessWidget {
  final List<String> jobIds;

  const _SavedJobsList({required this.jobIds});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadJobs(jobIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingView();
        }
        final jobs = snapshot.data!;
        if (jobs.isEmpty) {
          return const EmptyState(
            icon: Icons.visibility_off_outlined,
            title: 'Saved jobs are no longer active',
            subtitle: 'Archived or paused jobs are hidden from job seekers.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: jobs.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CompactJobCard(jobData: jobs[index]),
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

