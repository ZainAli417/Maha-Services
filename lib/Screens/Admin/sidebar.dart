import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Constant/logout_dialog.dart';

/// ── Brand palette (navy + teal) — coherent with the job seeker / recruiter
/// sidebars and the rest of the app. ──
class _S {
  static const heroDeep = Color(0xFF061C31);
  static const navy = Color(0xFF14507F);
  static const navyDeep = Color(0xFF0A2E4F);
  static const teal = Color(0xFF2EC4B6);
  static const tealDeep = Color(0xFF15A99C);
  static const ink = Color(0xFF0B2239);
  static const slate = Color(0xFF3E5C76);
  static const muted = Color(0xFF5E7A8E);
  static const faint = Color(0xFF8AA5B5);
  static const border = Color(0xFFDCE7EF);
  static const navyTint = Color(0xFFE8F1F8);
  static const bgSoft = Color(0xFFF4F9FB);
  static const error = Color(0xFFEF4444);
}

class AdminSidebar extends StatelessWidget {
  final Function(String) onMenuSelected;
  final String selectedMenu;

  const AdminSidebar({
    super.key,
    required this.onMenuSelected,
    required this.selectedMenu,
    required bool isDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 296,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _S.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0B2239),
            blurRadius: 16,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogoSection(),
            const Divider(height: 1, thickness: 1, color: _S.border),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: AdminProfile(),
            ),
            const Divider(height: 1, thickness: 1, color: _S.border),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                children: [
                  _buildSectionLabel('MAIN'),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    menuKey: 'Dashboard',
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel('MANAGEMENT'),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: 'User Management',
                    menuKey: 'User Management',
                  ),
                  // Recruiter Requests — LIVE BADGE from Firestore
                  _buildRecruiterRequestItem(),
                  // Locked items below Recruiter Requests
                  _buildMenuItem(
                    icon: Icons.quiz_outlined,
                    activeIcon: Icons.quiz,
                    label: 'Assessments',
                    menuKey: 'Assessments',
                  ),
                  _buildMenuItem(
                    icon: Icons.event_available_outlined,
                    activeIcon: Icons.event_available,
                    label: 'Interview Schedule',
                    menuKey: 'Interview Schedule',
                  ),
                  const SizedBox(height: 20),
                  _buildSectionLabel('SYSTEM'),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: 'Audit Logs',
                    menuKey: 'Audit Logs',
                  ),
                  _buildMenuItem(
                    icon: Icons.badge_outlined,
                    activeIcon: Icons.badge,
                    label: 'Role Templates',
                    menuKey: 'Role Templates',
                  ),
                  _buildLockedItem(
                    icon: Icons.report_outlined,
                    label: 'Reports',
                  ),
                  _buildLockedItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _S.border),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ── Recruiter Requests with LIVE Firestore badge ──
  Widget _buildRecruiterRequestItem() {
    final isSelected = selectedMenu == 'Recruiter Requests';
    return _MenuShell(
      isSelected: isSelected,
      onTap: () => onMenuSelected('Recruiter Requests'),
      child: Row(
        children: [
          Icon(
            isSelected
                ? Icons.business_center
                : Icons.business_center_outlined,
            size: 20,
            color: isSelected ? _S.tealDeep : _S.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Recruiter Requests',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _S.ink : _S.slate,
              ),
            ),
          ),
          // Live badge from Firestore
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('recruiter_requests')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              final count =
                  snapshot.hasData ? snapshot.data!.docs.length : 0;
              if (count == 0) return const SizedBox.shrink();
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _S.error,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _S.error.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Locked "Coming Soon" item ──
  Widget _buildLockedItem({required IconData icon, required String label}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Opacity(
        opacity: 0.75,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 20, color: _S.faint),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _S.faint,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_S.teal, _S.navy],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Soon',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _S.teal.withValues(alpha: 0.5), width: 2),
              image: const DecorationImage(
                image: AssetImage('images/logo_new.jpeg'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: _S.navy.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAHA HR SERVICES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _S.ink,
                    letterSpacing: 0.3,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _S.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Admin Portal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _S.tealDeep,
                      letterSpacing: 0.4,
                    ),
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
          color: _S.faint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String menuKey,
  }) {
    final isSelected = selectedMenu == menuKey;
    return _MenuShell(
      isSelected: isSelected,
      onTap: () => onMenuSelected(menuKey),
      child: Row(
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            size: 20,
            color: isSelected ? _S.tealDeep : _S.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _S.ink : _S.slate,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final shouldLogout = await showLogoutConfirm(context);
                if (shouldLogout == true) {
                  await FirebaseAuth.instance.signOut();
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: _S.error.withValues(alpha: 0.05),
                  border: Border.all(color: _S.error.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        size: 16, color: _S.error),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _S.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '© 2026 Maha HR Services',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _S.faint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Shared menu-row shell: navy-tint background + teal left accent bar when
/// selected, transparent otherwise. No grey hover fill (avoids the flicker).
class _MenuShell extends StatelessWidget {
  const _MenuShell({
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? _S.navyTint : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: _S.teal.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          hoverColor: _S.navyTint.withValues(alpha: 0.5),
          child: Row(
            children: [
              // Teal left accent bar on the active item
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 3,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? _S.tealDeep : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 11),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Compact Admin Profile Card
class AdminProfile extends StatelessWidget {
  const AdminProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'admin@mahaservices.com';
    final name = email.split('@')[0];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _S.bgSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _S.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_S.tealDeep, _S.navy],
              ),
              boxShadow: [
                BoxShadow(
                  color: _S.teal.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                          fontWeight: FontWeight.w700,
                          color: _S.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 14, color: _S.tealDeep),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Super Admin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _S.muted,
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

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
