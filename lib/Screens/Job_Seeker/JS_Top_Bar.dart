import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_portal/Screens/Job_Seeker/JS_Initials_provider.dart';
import 'package:provider/provider.dart';
import '../../Constant/logout_dialog.dart';
import 'assessment/my_sittings_provider.dart';

class JobSeekerSidebar extends StatefulWidget {
  final int activeIndex;
  final bool isDrawer;

  const JobSeekerSidebar({
    super.key,
    required this.activeIndex,
    this.isDrawer = false,
  });

  @override
  State<JobSeekerSidebar> createState() => _JobSeekerSidebarState();
}

class _JobSeekerSidebarState extends State<JobSeekerSidebar> {
  @override
  Widget build(BuildContext context) {
    return Consumer<JS_TopNavProvider>(
      builder: (context, provider, child) {
        final initials = provider.initials;
        final sidebarWidth = widget.isDrawer
            ? (MediaQuery.of(context).size.width * 0.75).clamp(240.0, 280.0)
            : 260.0;
        return Container(
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border(
              right: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Section
                _buildLogoSection(),

                const Divider(height: 1, thickness: 1),

                // Profile Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildProfileCard(initials),
                ),

                const Divider(height: 1, thickness: 1),

                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    children: [
                      _buildSectionLabel('MAIN MENU'),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        label: 'Dashboard',
                        index: 0,
                        isActive: widget.activeIndex == 0,
                        onTap: () => context.go('/dashboard'),
                      ),
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profile',
                        index: 1,
                        isActive: widget.activeIndex == 1,
                        onTap: () => context.go('/profile'),
                      ),
                      _buildMenuItem(
                        icon: Icons.auto_awesome_outlined,
                        activeIcon: Icons.auto_awesome,
                        label: 'ATS Cv Analyzer',
                        index: 2,
                        isActive: widget.activeIndex == 2,
                        onTap: () => context.go('/ai-tools'),
                      ),

                      const SizedBox(height: 20),
                      _buildSectionLabel('JOB SEARCH'),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.work_outline,
                        activeIcon: Icons.work,
                        label: 'Job Hub',
                        index: 3,
                        isActive: widget.activeIndex == 3,
                        onTap: () => context.go('/job-hub'),
                      ),
                      _buildMenuItem(
                        icon: Icons.bookmark_outline,
                        activeIcon: Icons.bookmark,
                        label: 'Saved Jobs',
                        index: 5,
                        isActive: widget.activeIndex == 5,
                        onTap: () => context.go('/saved-jobs'),
                      ),
                      // The badge is the whole point of putting it here: an
                      // invitation lapses in 24 hours, and an email is easy to
                      // miss. Watching the provider means the count clears
                      // itself the moment the test is sat.
                      Builder(builder: (context) {
                        final waiting =
                            context.watch<MySittingsProvider>().toDoCount;
                        return _buildMenuItem(
                          icon: Icons.fact_check_outlined,
                          activeIcon: Icons.fact_check,
                          label: 'Assessments',
                          index: 6,
                          isActive: widget.activeIndex == 6,
                          onTap: () => context.go('/my-assessments'),
                          badge: waiting > 0 ? '$waiting' : null,
                        );
                      }),

                      // _buildProMenuItem(
                      //   icon: Icons.send_outlined,
                      //   label: 'Applications',
                      // ),
                      const SizedBox(height: 20),
                      _buildSectionLabel('COMMUNICATION'),
                      const SizedBox(height: 8),
                      _buildProMenuItem(
                        icon: Icons.video_call_outlined,
                        label: 'Interviews',
                      ),
                      _buildProMenuItem(
                        icon: Icons.chat_bubble_outline,
                        label: 'Messages',
                      ),
                      _buildProMenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                      ),

                      const SizedBox(height: 20),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .get(),
                        builder: (context, snapshot) {
                          final role =
                              (snapshot.data?.data()
                                  as Map<String, dynamic>?)?['role'] ??
                              '';
                          if (role != 'Job Seeker') {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionLabel('ACCOUNT'),
                              const SizedBox(height: 8),
                              _buildMenuItem(
                                icon: Icons.settings_outlined,
                                activeIcon: Icons.settings,
                                label: 'Settings',
                                index: 4,
                                isActive: widget.activeIndex == 4,
                                onTap: () => context.go('/js-settings'),
                              ),
                            ],
                          );
                        },
                      ),
                      _buildProMenuItem(
                        icon: Icons.help_outline,
                        label: 'Help & Support',
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Footer
                _buildFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Row(
        children: [
          // Logo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2EC4B6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const ClipOval(
              child: Image(
                image: AssetImage('images/logo_new.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Brand Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAHA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B2239),
                    letterSpacing: 2.2,
                  ),
                ),
                Text(
                  'HR SERVICES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2EC4B6),
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String initials) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'jobseeker@mahaservices.com';
    final name = email.split('@')[0];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF14507F), Color(0xFF2EC4B6)],
              ),
            ),
            child: Center(
              child: Text(
                initials.isNotEmpty ? initials : 'JS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name.capitalize(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified,
                      size: 14,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Job Seeker',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildProMenuItem({required IconData icon, required String label}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Greyed icon
            Icon(icon, size: 20, color: const Color(0xFFCBD5E1)),
            const SizedBox(width: 12),
            // Label (greyed)
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ),
            // Lock icon
            const Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(width: 6),
            // PRO badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'PRO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  const Color(0xFF14507F).withValues(alpha: 0.12),
                  const Color(0xFF2EC4B6).withValues(alpha: 0.10),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: const Color(0xFF14507F).withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  // Active accent bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 3,
                    height: 20,
                    margin: EdgeInsets.only(right: isActive ? 9 : 12),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Icon
                  Icon(
                    isActive ? activeIcon : icon,
                    size: 20,
                    color: isActive
                        ? const Color(0xFF14507F)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 12),
                  // Label
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  // Badge
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Logout Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 16,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Copyright
          Text(
            '© 2026 Maha HR Services',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final ok = await showLogoutConfirm(context);
    if (!ok) return;
    try {
      await FirebaseAuth.instance.signOut();
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
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
