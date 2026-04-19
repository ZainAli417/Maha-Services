import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_snackbars.dart';
import 'admin_recruiter_request_provider.dart';

class UserManagementSection extends StatefulWidget {
  const UserManagementSection({super.key});

  @override
  State<UserManagementSection> createState() => _UserManagementSectionState();
}
class _UserManagementSectionState extends State<UserManagementSection>
    with TickerProviderStateMixin, WidgetsBindingObserver { // ADD WidgetsBindingObserver

  String _searchQuery = '';
  String _selectedRoleFilter = 'all';
  String _selectedStatusFilter = 'all';
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _staggerController;

  // Scroll controller for table animations
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ADD THIS
    // Enhanced fade animation with smoother curve
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );

    // Slide animation for content entrance
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    // Stagger animation for list items
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scrollController.addListener(() {
      if (!mounted) return; // ADD THIS

      if (_scrollController.offset > 0 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 0 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _staggerController.forward();
  }

  @override

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _fadeController.stop();
      _slideController.stop();
      _staggerController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Consumer<AdminProvider>(
        builder: (context, provider, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                color: const Color(0xFFFAFAFA),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skip header on mobile — wrapper already shows it
                    if (!isMobile) _buildModernHeader(context, provider),
                    if (!isMobile) const SizedBox(height: 28),
                    _buildFilters(),
                    SizedBox(height: isMobile ? 12 : 24),
                    Expanded(child: _buildUsersTable(provider)),
                  ],
                ),
              ),
            ),
          );
        },
      );
  }


  Widget _buildModernHeader(BuildContext context, AdminProvider prov) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.supervised_user_circle,
              color: Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Management',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Add, Upgrade or Suspend Users from the portal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildAddUserButton(context, prov, isMobile),
        ],
      ),
    );
  }




  Widget _buildAddUserButton(BuildContext context, AdminProvider provider, bool isMobile) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: isMobile 
        ? IconButton(
            onPressed: () => _showAddUserDialog(context, provider),
            icon: const Icon(Icons.person_add_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )
        : ElevatedButton.icon(
          onPressed: () => _showAddUserDialog(context, provider),
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: Text(
            'Add User',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
            shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
          ).copyWith(
            elevation: WidgetStateProperty.resolveWith<double>(
                  (states) => states.contains(WidgetState.hovered) ? 4 : 0,
            ),
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (states) => states.contains(WidgetState.hovered)
                  ? const Color(0xFF4F46E5)
                  : const Color(0xFF6366F1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32),
      child: isMobile 
      ? Column(
          children: [
            const SizedBox(height: 12),

            _buildSearchBar(),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   _buildFilterDropdown(
                    'Role',
                    _selectedRoleFilter,
                    ['all', 'Job Seeker', 'Recruiter', 'Admin'],
                        (value) => setState(() => _selectedRoleFilter = value!),
                    Icons.work_outline,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterDropdown(
                    'Status',
                    _selectedStatusFilter,
                    ['all', 'active', 'suspended'],
                        (value) => setState(() => _selectedStatusFilter = value!),
                    Icons.toggle_on_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildRefreshButton(),
                ],
              ),
            ),
          ],
        )
      : Row(
        children: [
          Expanded(flex: 3, child: _buildSearchBar()),
          const SizedBox(width: 16),
          _buildFilterDropdown(
            'Role',
            _selectedRoleFilter,
            ['all', 'Job Seeker', 'Recruiter', 'Admin'],
                (value) => setState(() => _selectedRoleFilter = value!),
            Icons.work_outline,
          ),
          const SizedBox(width: 12),
          _buildFilterDropdown(
            'Status',
            _selectedStatusFilter,
            ['all', 'active', 'suspended'],
                (value) => setState(() => _selectedStatusFilter = value!),
            Icons.toggle_on_outlined,
          ),
          const SizedBox(width: 12),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: IconButton(
          onPressed: () {
            setState(() {
              _searchQuery = '';
              _selectedRoleFilter = 'all';
              _selectedStatusFilter = 'all';
            });
          },
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF64748B),
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: const Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),

      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: false,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
            onPressed: () => setState(() => _searchQuery = ''),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
      String label,
      String value,
      List<String> items,
      ValueChanged<String?> onChanged,
      IconData icon,
      ) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
          isExpanded: false,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item == 'all'
                        ? 'All ${label}s'
                        : item.replaceAll('_', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUsersTable(AdminProvider provider) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      margin: EdgeInsets.fromLTRB(isMobile ? 8 : 10, 0, isMobile ? 8 : 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!mounted) return const SizedBox.shrink();

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return _buildLoadingState();
            }

            var allUsers = _filterUsers(snapshot.data!.docs);
            int totalPages = (allUsers.length / _itemsPerPage).ceil();
            if (totalPages == 0) totalPages = 1;
            if (_currentPage > totalPages) _currentPage = totalPages;

            int start = (_currentPage - 1) * _itemsPerPage;
            int end = (start + _itemsPerPage).clamp(0, allUsers.length);
            var users = allUsers.sublist(start, end);

            if (allUsers.isEmpty) {
              return _buildEmptyState();
            }

            // ── MOBILE: Card-based layout (no horizontal scrolling) ──
            if (isMobile) {
              return Column(
                children: [
                  // Compact count header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFAFA),
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 8),
                        Text('${users.length} user${users.length != 1 ? 's' : ''}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final doc = users[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildMobileUserCard(context, provider, doc.id, data);
                      },
                    ),
                  ),
                  _buildTableFooter(allUsers.length, totalPages),
                ],
              );
            }

            // ── DESKTOP: Table layout ──
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTableHeader(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.zero,
                    itemCount: users.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final doc = users[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return AnimatedBuilder(
                        animation: _staggerController,
                        builder: (context, child) {
                          final animationValue = CurvedAnimation(
                            parent: _staggerController,
                            curve: Interval(
                              (index / users.length) * 0.5,
                              1.0,
                              curve: Curves.easeOutQuart,
                            ),
                          ).value;

                          return Opacity(
                            opacity: animationValue,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - animationValue)),
                              child: Column(
                                children: [
                                  _buildUserRow(context, provider, doc.id, data, index),
                                  if (index < users.length - 1)
                                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildTableFooter(allUsers.length, totalPages),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Mobile user card — replaces horizontal scrolling table ──
  Widget _buildMobileUserCard(BuildContext ctx, AdminProvider provider, String docId, Map<String, dynamic> data) {
    final status    = data['account_status'] ?? 'active';
    final name      = data['name'] ?? 'Unknown';
    final email     = data['email'] ?? 'No email';
    final role      = data['role'] ?? 'N/A';
    final userLevel = data['user_lvl'] ?? 'basic';

    return FutureBuilder<String>(
      future: provider.fetchUnifiedName(data['uid'] ?? docId),
      builder: (context, snapshot) {
        if (!mounted) return const SizedBox.shrink();
        final displayName = (snapshot.data != null && snapshot.data != 'Unknown User')
            ? snapshot.data!
            : (data['name']?.toString() ?? 'Unknown');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + name + status
              Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                        Text(email,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 10),
              // Bottom row: role + level + actions
              Row(
                children: [
                  _buildRoleBadge(role),
                  const SizedBox(width: 8),
                  _buildLevelBadge(userLevel),
                  const Spacer(),
                  // Compact actions
                  _buildActionButton(
                    Icons.edit_note_rounded, 'Edit', const Color(0xFF6366F1),
                    () => _showEditUserDialog(context, provider, data, docId, displayName),
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    status == 'active' ? Icons.block_rounded : Icons.check_circle_rounded,
                    status == 'active' ? 'Suspend' : 'Activate',
                    status == 'active' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    () async => await provider.suspendUser(docId, status),
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    Icons.lock_reset_rounded, 'Reset', const Color(0xFF8B5CF6),
                    () => _showResetPasswordDialog(context, provider, email),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> users) {
    return users.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = data['role'] ?? '';
      final status = data['account_status'] ?? 'active';

      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());

      final matchesRole = _selectedRoleFilter == 'all' || role == _selectedRoleFilter;
      final matchesStatus = _selectedStatusFilter == 'all' || status == _selectedStatusFilter;

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }
  Widget _buildTableHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border(
          bottom: BorderSide(
            color: _isScrolled ? const Color(0xFFE2E8F0) : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderCell('USER', icon: Icons.person_outline)),
          Expanded(flex: 2, child: _buildHeaderCell('ROLE', icon: Icons.badge_outlined)),
          Expanded(flex: 2, child: _buildHeaderCell('LEVEL', icon: Icons.stars_outlined)),
          Expanded(flex: 2, child: _buildHeaderCell('STATUS', icon: Icons.online_prediction_outlined)),
          Expanded(flex: 2, child: _buildHeaderCell('ACTIONS', align: TextAlign.center, icon: Icons.touch_app_outlined)),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {TextAlign align = TextAlign.left, IconData? icon}) {
    return Row(
      mainAxisAlignment: align == TextAlign.center ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          textAlign: align,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUserRow(
      BuildContext context,
      AdminProvider provider,
      String docId,
      Map<String, dynamic> data,
      int index,
      ) {
    final status = data['account_status'] ?? 'active';
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? 'No email';
    final role = data['role'] ?? 'N/A';
    final userLevel = data['user_lvl'] ?? 'basic';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: Colors.white,
      child: InkWell(
        onTap: () {},
        hoverColor: const Color(0xFFFAFAFA),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: FutureBuilder<String>(
            future: provider.fetchUnifiedName(data['uid'] ?? docId),
            builder: (context, snapshot) {
              if (!mounted) return const SizedBox.shrink(); // ADD THIS

              final displayName = (snapshot.data != null && snapshot.data != 'Unknown User')
                  ? snapshot.data!
                  : (data['name']?.toString() ?? 'Unknown');              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildUserInfo(displayName, email),
                  ),
                  Expanded(flex: 2, child: _buildRoleBadge(role)),
                  Expanded(flex: 2, child: _buildLevelBadge(userLevel)),
                  Expanded(flex: 2, child: _buildStatusBadge(status)),
                  Expanded(
                    flex: 2,
                    child: _buildActions(
                      context,
                      provider,
                      docId,
                      data,
                      status,
                      email,
                      displayName,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(String name, String email) {
    return Row(
      children: [
        Hero(
          tag: 'avatar_$name',
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                  height: 1.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    final roleConfig = _getRoleConfig(role);
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: 'Role: ${role.replaceAll('_', ' ').toUpperCase()}',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: roleConfig['bgColor'],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: roleConfig['color']!.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(roleConfig['icon'], size: 13, color: roleConfig['color']),
              const SizedBox(width: 6),
              Text(
                role.replaceAll('_', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: roleConfig['color'],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String userLevel) {
    final level = userLevel.toLowerCase();
    final isPremium = level == 'premium';
    final isBasic = level == 'basic' || level == 'free'; // Treat legacy free as basic

    Color bgColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData icon;

    if (isPremium) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFCD34D).withValues(alpha: 0.5);
      iconColor = const Color(0xFFF59E0B);
      textColor = const Color(0xFFB45309);
      icon = Icons.workspace_premium_rounded;
    } else {
      bgColor = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFE2E8F0);
      iconColor = const Color(0xFF64748B);
      textColor = const Color(0xFF64748B);
      icon = Icons.person_outline;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              userLevel[0].toUpperCase() + userLevel.substring(1),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status.toLowerCase() == 'active';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF6EE7B7).withValues(alpha: 0.5) : const Color(0xFFFCA5A5).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              status[0].toUpperCase() + status.substring(1),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
      BuildContext context,
      AdminProvider provider,
      String docId,
      Map<String, dynamic> data,
      String status,
      String email,
      String? name,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          Icons.edit_note_rounded,
          'Edit User',
          const Color(0xFF6366F1),
              () => _showEditUserDialog(context, provider, data, docId, name),
        ),
        const SizedBox(width: 6),
        _buildActionButton(
          status == 'active' ? Icons.block_rounded : Icons.check_circle_rounded,
          status == 'active' ? 'Suspend User' : 'Activate User',
          status == 'active' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              () async {
            await provider.suspendUser(docId, status);
            // Don't assume context is valid here - the provider should handle its own state
          },
        ),
        const SizedBox(width: 6),
        _buildActionButton(
          Icons.lock_reset_rounded,
          'Reset Password',
          const Color(0xFF8B5CF6),
              () => _showResetPasswordDialog(context, provider, email),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          hoverColor: color.withValues(alpha: 0.1),
          splashColor: color.withValues(alpha: 0.2),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
  Widget _buildTableFooter(int totalCount, int totalPages) {
    int start = totalCount == 0 ? 0 : (_currentPage - 1) * _itemsPerPage + 1;
    int end = (_currentPage * _itemsPerPage).clamp(0, totalCount);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Showing $start-$end of $totalCount',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              _buildPageButton(
                icon: Icons.chevron_left_rounded,
                onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_currentPage / $totalPages',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildPageButton(
                icon: Icons.chevron_right_rounded,
                onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({required IconData icon, VoidCallback? onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: onTap != null ? Colors.white : Colors.transparent,
        foregroundColor: onTap != null ? const Color(0xFF6366F1) : Colors.grey.shade400,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: onTap != null ? const Color(0xFFE2E8F0) : Colors.transparent),
        ),
      ),
    );
  }

  Map<String, dynamic> _getRoleConfig(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return {
          'color': const Color(0xFFDC2626),
          'bgColor': const Color(0xFFFEF2F2),
          'icon': Icons.admin_panel_settings_rounded,
        };
      case 'recruiter':
        return {
          'color': const Color(0xFF6366F1),
          'bgColor': const Color(0xFFEEF2FF),
          'icon': Icons.business_center_rounded,
        };
      case 'job seeker':
      case 'job_seeker':
        return {
          'color': const Color(0xFF10B981),
          'bgColor': const Color(0xFFECFDF5),
          'icon': Icons.work_rounded,
        };
      default:
        return {
          'color': const Color(0xFF64748B),
          'bgColor': const Color(0xFFF1F5F9),
          'icon': Icons.person_outline,
        };
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              strokeWidth: 3,
              backgroundColor: const Color(0xFFE0E7FF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading users...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFEE2E2), width: 2),
            ),
            child: const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
          ),
          const SizedBox(height: 20),
          Text(
            'Unable to Load Users',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              error,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Retry',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            ),
            child: Icon(Icons.people_outline_rounded, size: 56, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          Text(
            'No Users Found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters to find what you\'re looking for',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _selectedRoleFilter = 'all';
                _selectedStatusFilter = 'all';
              });
            },
            icon: const Icon(Icons.clear_all_rounded, size: 18),
            label: Text(
              'Clear Filters',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _showAddUserDialog(BuildContext context, AdminProvider provider) {
    provider.clearForm();
    _showUserDialog(context, provider, 'Add New User', false, null);
  }

  void _showEditUserDialog(
      BuildContext context,
      AdminProvider provider,
      Map<String, dynamic> data,
      String docId,
      String? resolvedName,
      ) {
    provider.editUser(data, docId, resolvedName: resolvedName);
    _showUserDialog(context, provider, 'Edit User', true, data);
  }

  void _showUserDialog(BuildContext context, AdminProvider provider, String title, bool isEdit, Map<String, dynamic>? existingData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        String selectedRole = existingData?['role'] ?? 'Job Seeker';
        String selectedLevel = existingData?['user_lvl'] ?? 'basic';

        return StatefulBuilder(
          builder: (stfContext, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              backgroundColor: Colors.transparent,
              child: Container(
                width: 540,
                constraints: const BoxConstraints(maxHeight: 700),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modern Header with Gradient
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6366F1),
                            const Color(0xFF6366F1).withValues(alpha: 0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEdit ? Icons.edit_note_rounded : Icons.person_add_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isEdit ? 'Update user information' : 'Create new account',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              provider.clearForm();
                              Navigator.pop(dialogContext);
                            },
                            icon: const Icon(Icons.close, color: Colors.white, size: 22),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: provider.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDialogField(
                                'Full Name',
                                provider.nameController,
                                Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 18),
                              _buildDialogField(
                                'Email Address',
                                provider.emailController,
                                Icons.alternate_email_rounded,
                                readOnly: isEdit,
                              ),
                              const SizedBox(height: 18),
                              if (!isEdit) ...[
                                _buildDialogField(
                                  'Password',
                                  provider.passwordController,
                                  Icons.lock_outline_rounded,
                                  obscureText: true,
                                  validator: (v) => (v?.length ?? 0) < 6 ? 'Password must be at least 6 characters' : null,
                                ),
                                const SizedBox(height: 18),
                              ],
                              _buildSectionLabel('User Role'),
                              const SizedBox(height: 12),
                              _buildRoleSelector(selectedRole, (value) {
                                setDialogState(() {
                                  selectedRole = value!;
                                  provider.roleController.text = value;
                                });
                              }),
                              const SizedBox(height: 18),
                              _buildSectionLabel('Account Level'),
                              const SizedBox(height: 12),
                              _buildLevelDropdown(selectedLevel, (value) {
                                setDialogState(() {
                                  selectedLevel = value!;
                                  provider.userLevelController.text = value;
                                });
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Footer Actions
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              provider.clearForm();
                              Navigator.pop(dialogContext);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                              if (provider.formKey.currentState!.validate()) {
                                provider.roleController.text = selectedRole;
                                provider.userLevelController.text = selectedLevel;

                                final success = await provider.addOrEditUser();

                                // CRITICAL FIX: Check mounted on the CORRECT context
                                if (!mounted) return; // Check the widget's context first

                                if (success) {
                                  CustomSnackbars.showSuccess(context, provider.message);
                                  // Check dialog context separately
                                  if (stfContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                } else {
                                  CustomSnackbars.showError(context, provider.message);
                                }
                              }
                            },
                            icon: provider.isLoading
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                            label: Text(
                              isEdit ? 'Save Changes' : 'Create User',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFCBD5E1),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ).copyWith(
                              elevation: WidgetStateProperty.resolveWith<double>(
                                    (states) => states.contains(WidgetState.hovered) ? 2 : 0,
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
          },
        );
      },
    );
  }

  Widget _buildRoleSelector(String selectedRole, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleOption(
              'Job Seeker',
              'Job Seeker',
              selectedRole,
              Icons.work_outline_rounded,
              onChanged,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildRoleOption(
              'Recruiter',
              'Recruiter',
              selectedRole,
              Icons.business_center_rounded,
              onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption(
      String label,
      String value,
      String groupValue,
      IconData icon,
      ValueChanged<String?> onChanged,
      ) {
    final isSelected = value == groupValue;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: const Color(0xFF6366F1),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelDropdown(String selectedLevel, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedLevel,
        focusColor: null,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w500,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
        items: [
          DropdownMenuItem(
            value: 'basic',
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 12),
                Text('Basic Account', style: GoogleFonts.plusJakartaSans(fontSize: 14)),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'premium',
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, size: 18, color: Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Text('Premium Account', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PRO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }



  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }















  void _showResetPasswordDialog(BuildContext context, AdminProvider provider, String email) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF8B5CF6),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Reset Password',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A password reset link will be sent to:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email_outlined, size: 18, color: const Color(0xFF94A3B8)),
                          const SizedBox(width: 10),
                          Text(
                            email,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: const Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          provider.resetPassword(email);
                          Navigator.pop(dialogContext);
                          CustomSnackbars.showSuccess(context, 'Password reset email sent');
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          'Send Link',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDialogField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool obscureText = false,
        bool readOnly = false,
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
            filled: false,
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator ?? (v) => v?.trim().isEmpty ?? true ? '$label is required' : null,
        ),
      ],
    );
  }
  @override
  void dispose() {
    // Stop animations first before disposing
    _fadeController.stop();
    _slideController.stop();
    _staggerController.stop();
    WidgetsBinding.instance.removeObserver(this); // ADD THIS
    _fadeController.dispose();
    _slideController.dispose();
    _staggerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

}