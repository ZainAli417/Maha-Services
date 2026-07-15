// admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_portal/Screens/Admin/sidebar.dart';
import 'admin_analytics_dashboard.dart';
import 'admin_recruiter_request_management.dart';
import 'audit_logs_section.dart';
import 'questionnaire_management_section.dart';
import 'user_management_section.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedMenu = 'Dashboard'; // Default selected menu
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Map menu keys to their icon + subtitle for the engaging header
  static const _menuMeta = <String, Map<String, dynamic>>{
    'Dashboard': {
      'icon': Icons.dashboard_rounded,
      'sub': 'Platform overview & analytics',
    },
    'User Management': {
      'icon': Icons.supervised_user_circle,
      'sub': 'Manage accounts & permissions',
    },
    'Recruiter Requests': {
      'icon': Icons.business_center_rounded,
      'sub': 'Review & approve recruiters',
    },
    'Audit Logs': {
      'icon': Icons.receipt_long_rounded,
      'sub': 'Immutable admin action trail',
    },
    'Questionnaires': {
      'icon': Icons.quiz_rounded,
      'sub': 'Manage onboarding questions & roles',
    },
  };

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              child: AdminSidebar(
                onMenuSelected: (menu) {
                  setState(() => _selectedMenu = menu);
                  Navigator.of(context).pop();
                },
                selectedMenu: _selectedMenu,
                isDrawer: true,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            AdminSidebar(
              onMenuSelected: (menu) => setState(() => _selectedMenu = menu),
              selectedMenu: _selectedMenu,
              isDrawer: true,
            ),
          Expanded(
            child: Column(
              children: [
                // Mobile top bar — engaging header with icon + subtitle
                if (isMobile) _buildMobileTopBar(),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF4F9FB),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar() {
    final meta = _menuMeta[_selectedMenu];
    final icon = meta?['icon'] as IconData? ?? Icons.apps_rounded;
    final sub = meta?['sub'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE7EF))),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Hamburger
            IconButton(
              icon: const Icon(Icons.menu_rounded, size: 22),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 8),
            // Icon
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF15A99C), Color(0xFF14507F)],
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedMenu,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                        height: 1.3,
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

  Widget _buildContent() {
    switch (_selectedMenu) {
      case 'Dashboard':
        return AdminAnalyticsDashboardScreen(
          onNavigate: (menu) {
            if (_menuMeta.containsKey(menu)) {
              setState(() => _selectedMenu = menu);
            }
          },
        );
      case 'User Management':
        return const UserManagementSection();
      case 'Recruiter Requests':
        return const Admin_Recruiter_Request_screen();
      case 'Audit Logs':
        return const AuditLogsSection();
      case 'Questionnaires':
        return const QuestionnaireManagementSection();
      default:
        return const Center(child: Text('Select a menu item'));
    }
  }
}
