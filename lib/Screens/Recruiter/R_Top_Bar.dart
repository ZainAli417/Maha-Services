import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_portal/Screens/Recruiter/R_Initials_provider.dart';
import 'package:provider/provider.dart';
import '../../Constant/logout_dialog.dart';

class RecruiterSidebar extends StatefulWidget {
  final int activeIndex;
  final bool isDrawer;

  const RecruiterSidebar({
    super.key,
    required this.activeIndex,
    this.isDrawer = false,
  });

  @override
  State<RecruiterSidebar> createState() => _RecruiterSidebarState();
}

class _RecruiterSidebarState extends State<RecruiterSidebar> {
  @override
  Widget build(BuildContext context) {
    return Consumer<R_TopNavProvider>(
      builder: (context, provider, child) {
        final initials = provider.initials;

        final sidebarWidth = widget.isDrawer
            // Mobile: Wider drawer for better spacing
            ? (MediaQuery.sizeOf(context).width * 0.42).clamp(220.0, 280.0)
            : 280.0; // Desktop: increased width for a more comfortable sidebar
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
                        onTap: () => context.go('/recruiter-dashboard'),
                      ),
                      _buildMenuItem(
                        icon: Icons.post_add_outlined,
                        activeIcon: Icons.post_add,
                        label: 'Post a Job',
                        index: 1,
                        isActive: widget.activeIndex == 1,
                        onTap: () => context.go('/post-job'),
                      ),
                      // _buildMenuItem(
                      //   icon: Icons.work_outline,
                      //   activeIcon: Icons.work,
                      //   label: 'My Jobs',
                      //   index: 5,
                      //   isActive: widget.activeIndex == 5,
                      //   onTap: () => context.go('/recruiter-jobs'),
                      // ),
                      _buildMenuItem(
                        icon: Icons.spatial_tracking_outlined,
                        activeIcon: Icons.spatial_tracking_rounded,
                        label: 'Job Application Tracker',
                        index: 2,
                        isActive: widget.activeIndex == 2,
                        onTap: () => context.go('/job-application-tracker'),
                      ),

                      _buildMenuItem(
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Shortlisting',
                        index: 3,
                        isActive: widget.activeIndex == 3,
                        onTap: () => context.go('/shortlisting'),
                      ),
                      _buildMenuItem(
                        icon: Icons.all_inbox_outlined,
                        activeIcon: Icons.all_inbox,
                        label: 'Request Box',
                        index: 4,
                        isActive: widget.activeIndex == 4,
                        onTap: () => context.go('/request-box'),
                      ),
                      _buildMenuItem(
                        icon: Icons.archive_outlined,
                        activeIcon: Icons.archive,
                        label: 'Archived Jobs',
                        index: 5,
                        isActive: widget.activeIndex == 5,
                        onTap: () => context.go('/archived-jobs'),
                      ),

                      // const SizedBox(height: 20),
                      // _buildSectionLabel('ACCOUNT'),
                      // const SizedBox(height: 8),
                      // _buildMenuItem(
                      //    icon: Icons.work_outline,
                      //    activeIcon: Icons.work,
                      //    label: 'Settings',
                      //    index: 5,
                      //    isActive: widget.activeIndex == 5,
                      //    onTap: () => context.go('/Settings'),
                      //  ),
                      //
                      // _buildMenuItem(
                      //   icon: Icons.help_outline,
                      //   activeIcon: Icons.help,
                      //   label: 'Help & Support',
                      //   index: 6,
                      //   isActive: widget.activeIndex == 6,
                      //   onTap: () => context.go('/help'),
                      // ),
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
    final email = user?.email ?? 'Recruiter@mahaservices.com';
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
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
                    const Icon(
                      Icons.verified,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Recruiter',
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
