import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_portal/Screens/Job_Seeker/JS_Initials_provider.dart';
import 'package:provider/provider.dart';
import '../../Web_routes.dart';

class JobSeekerSidebar extends StatefulWidget {
  final int activeIndex;

  const JobSeekerSidebar({
    super.key,
    required this.activeIndex,
  });

  @override
  State<JobSeekerSidebar> createState() => _JobSeekerSidebarState();
}

class _JobSeekerSidebarState extends State<JobSeekerSidebar> {
  int? _hoveredIndex;
  final int _notificationCount = 3;

  @override
  Widget build(BuildContext context) {
    return Consumer<JS_TopNavProvider>(
        builder: (context, provider, child) {
          final initials = provider.initials;
          return Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
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
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                        label: 'AI Tools',
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
                        index: 4,
                        isActive: widget.activeIndex == 4,
                        onTap: () => context.go('/saved-jobs'),
                      ),
                      _buildMenuItem(
                        icon: Icons.send_outlined,
                        activeIcon: Icons.send,
                        label: 'Applications',
                        index: 5,
                        isActive: widget.activeIndex == 5,
                        onTap: () => context.go('/applications'),
                      ),

                      const SizedBox(height: 20),
                      _buildSectionLabel('COMMUNICATION'),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.video_call_outlined,
                        activeIcon: Icons.video_call,
                        label: 'Interviews',
                        index: 6,
                        isActive: widget.activeIndex == 6,
                        onTap: () => context.go('/alerts'),
                      ),
                      _buildMenuItem(
                        icon: Icons.chat_bubble_outline,
                        activeIcon: Icons.chat_bubble,
                        label: 'Messages',
                        index: 7,
                        isActive: widget.activeIndex == 7,
                        onTap: () => context.go('/messages'),
                      ),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        activeIcon: Icons.notifications,
                        label: 'Notifications',
                        index: 8,
                        isActive: widget.activeIndex == 8,
                        badge: _notificationCount > 0 ? _notificationCount.toString() : null,
                        onTap: () => context.go('/notifications'),
                      ),

                      const SizedBox(height: 20),
                      _buildSectionLabel('ACCOUNT'),
                      const SizedBox(height: 8),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        label: 'Settings',
                        index: 9,
                        isActive: widget.activeIndex == 9,
                        onTap: () => context.go('/settings'),
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        activeIcon: Icons.help,
                        label: 'Help & Support',
                        index: 10,
                        isActive: widget.activeIndex == 10,
                        onTap: () => context.go('/help'),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Footer
                _buildFooter(),
              ],
            ),
          );
        },
      
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: AssetImage('images/logo.png'),
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
                  'MAHA SERVICES',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Job Seeker Portal',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
            child: Center(
              child: Text(
                initials.isNotEmpty ? initials : 'JS',
                style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
        style: GoogleFonts.poppins(
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
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6366F1).withOpacity(0.08)
              : (isHovered ? Colors.grey.shade50 : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? const Color(0xFF6366F1).withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            splashColor: const Color(0xFF6366F1).withOpacity(0.1),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Icon
                  Icon(
                    isActive ? activeIcon : icon,
                    size: 20,
                    color: isActive
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 12),
                  // Label
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  // Badge
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
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
            '© 2025 Maha Services',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirm Logout',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from your account?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Clear in-memory role cache
                RoleService.clearCache();

                // Firebase sign out (router will redirect)
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),

        ],
      ),
    );
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}