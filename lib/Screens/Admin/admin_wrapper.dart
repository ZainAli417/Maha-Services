// admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_portal/Screens/Admin/sidebar.dart';
import 'admin_analytics_dashboard.dart';
import 'admin_recruiter_request_management.dart';
import 'user_management_section.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedMenu = 'Dashboard'; // Default selected menu
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Map menu keys to their icon + subtitle for the engaging header
  static const _menuMeta = <String, Map<String, dynamic>>{
    'Dashboard':          {'icon': Icons.dashboard_rounded,        'sub': 'Platform overview & analytics'},
    'User Management':    {'icon': Icons.supervised_user_circle,   'sub': 'Manage accounts & permissions'},
    'Recruiter Requests': {'icon': Icons.business_center_rounded,  'sub': 'Review & approve recruiters'},
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
                  child: Container(color: Colors.white, child: _buildContent()),
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
    final sub  = meta?['sub'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
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
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF6366F1)),
            ),
            const SizedBox(width: 10),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedMenu,
                    style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A), height: 1.2,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(sub,
                      style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w400,
                        color: const Color(0xFF94A3B8), height: 1.3,
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
        return const AdminAnalyticsDashboardScreen();
      case 'User Management':
        return const UserManagementSection();
      case 'Recruiter Requests':
        return const AdminDashboardScreen2();
      default:
        return const Center(child: Text('Select a menu item'));
    }
  }
}
