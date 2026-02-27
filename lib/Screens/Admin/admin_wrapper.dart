// admin_dashboard_screen.dart
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              child: AdminSidebar(
                onMenuSelected: (menu) {
                  setState(() {
                    _selectedMenu = menu;
                  });
                  Navigator.of(context).pop(); // close drawer
                },
                selectedMenu: _selectedMenu,
                isDrawer: true,
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar — hidden on mobile
          if (!isMobile)
            AdminSidebar(
              onMenuSelected: (menu) {
                setState(() {
                  _selectedMenu = menu;
                });
              },
              selectedMenu: _selectedMenu, isDrawer: true,
            ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Mobile top bar with hamburger
                if (isMobile)
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom:
                            BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu_rounded, size: 24),
                          onPressed: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedMenu,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Container(
                      color: Colors.white, child: _buildContent()),
                ),
              ],
            ),
          ),
        ],
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
