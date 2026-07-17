import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:job_portal/Constant/brand_snackbar.dart';
import '../../Web_routes.dart' show AuthNotifier;
import '../../core/rbac/rbac.dart';
import '../../core/widgets/confirm_dialog.dart';
import 'admin_recruiter_request_provider.dart';
import 'user_detail_panel.dart';
import 'widgets/admin_header.dart';

/// Navy + teal brand tokens for the admin user-management screen. Values come
/// straight from the shared admin palette so this screen reads as one system
/// with the rest of the portal. No indigo/violet is permitted here.
class _C {
  const _C._();
  static const hero = Color(0xFF061C31);
  static const heroAlt = Color(0xFF0A2E4F);
  static const navy = Color(0xFF14507F);
  static const deepNavy = Color(0xFF0A2E4F);
  static const blue = Color(0xFF2178B5);
  static const teal = Color(0xFF2EC4B6);
  static const tealBright = Color(0xFF43E0D2);
  static const tealDeep = Color(0xFF15A99C);
  static const coral = Color(0xFFFF7A59);
  static const amber = Color(0xFFFFB020);
  static const ink = Color(0xFF0B2239);
  static const slate = Color(0xFF3E5C76);
  static const muted = Color(0xFF5E7A8E);
  static const faint = Color(0xFF8AA5B5);
  static const border = Color(0xFFDCE7EF);
  static const bgSoft = Color(0xFFF4F9FB);
  static const tealTint = Color(0xFFE4F6F4);
  static const navyTint = Color(0xFFE8F1F8);
  static const white = Color(0xFFFFFFFF);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  static const primaryGradient = LinearGradient(
    colors: [teal, navy],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const badgeGradient = LinearGradient(
    colors: [tealBright, navy],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static final cardShadow = BoxShadow(
    color: ink.withValues(alpha: 0.05),
    blurRadius: 16,
    offset: const Offset(0, 8),
  );
}

class UserManagementSection extends StatefulWidget {
  const UserManagementSection({super.key});

  @override
  State<UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends State<UserManagementSection>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ADD WidgetsBindingObserver

  String _searchQuery = '';
  String _selectedRoleFilter = 'all';
  String _selectedStatusFilter = 'all';
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  // Cap on documents streamed from the `users` collection. Bounds Firestore
  // reads (previously an unbounded full-collection listener). When the cap is
  // hit, a visible notice tells the admin the list is truncated — never a
  // silent drop. Client-side search/filter operate within this window.
  static const int _fetchCap = 300;

  // Bulk selection.
  final Set<String> _selected = {};
  bool _bulkBusy = false;

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
        );

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
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return Consumer<AdminProvider>(
      builder: (context, provider, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              color: _C.bgSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skip header on mobile — wrapper already shows it
                  if (!isMobile)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                      child: _buildModernHeader(context, provider),
                    ),
                  if (!isMobile) const SizedBox(height: 20),
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
    return AdminGradientHeader(
      icon: Icons.supervised_user_circle_rounded,
      title: 'User Management',
      subtitle: 'Create, verify, convert roles, suspend or remove accounts.',
      actions: [
        AdminHeaderButton(
          icon: Icons.person_add_rounded,
          label: 'Add user',
          filled: true,
          onPressed: () => _showAddUserDialog(context, prov),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
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
                        const [
          'all',
          'Job Seeker',
          'Recruiter',
          'Recruitment Agent',
          'Admin',
          'Super Admin',
        ],
                        (value) => setState(() => _selectedRoleFilter = value!),
                        Icons.work_outline,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterDropdown(
                        'Status',
                        _selectedStatusFilter,
                        const ['all', 'active', 'suspended', 'deleted'],
                        (value) =>
                            setState(() => _selectedStatusFilter = value!),
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
                  const [
          'all',
          'Job Seeker',
          'Recruiter',
          'Recruitment Agent',
          'Admin',
          'Super Admin',
        ],
                  (value) => setState(() => _selectedRoleFilter = value!),
                  Icons.work_outline,
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  'Status',
                  _selectedStatusFilter,
                  const ['all', 'active', 'suspended', 'deleted'],
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
          tooltip: 'Reset filters',
          style: IconButton.styleFrom(
            backgroundColor: _C.navyTint,
            foregroundColor: _C.navy,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: _C.border),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border, width: 1.2),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        cursorColor: _C.navy,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: _C.ink,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: _C.muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          filled: false,
          prefixIcon: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _C.tealTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: _C.tealDeep,
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _C.muted,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border, width: 1.2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: _C.ink,
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: _C.navy,
          ),
          isExpanded: false,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: _C.tealDeep),
                  const SizedBox(width: 8),
                  Text(
                    item == 'all'
                        ? 'All ${label}s'
                        : item
                              .replaceAll('_', ' ')
                              .split(' ')
                              .map(
                                (word) =>
                                    word[0].toUpperCase() + word.substring(1),
                              )
                              .join(' '),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _C.ink,
                    ),
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
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1600),
        margin: EdgeInsets.fromLTRB(
          isMobile ? 12 : 32,
          0,
          isMobile ? 12 : 32,
          32,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
          boxShadow: [_C.cardShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .limit(_fetchCap)
                .snapshots(),
            builder: (context, snapshot) {
              if (!mounted) return const SizedBox.shrink();

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }
              if (!snapshot.hasData) {
                return _buildLoadingState();
              }

              final capped = snapshot.data!.docs.length >= _fetchCap;
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
                    if (capped) _buildCappedNotice(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: _C.bgSoft,
                        border: Border(
                          bottom: BorderSide(color: _C.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 16,
                            color: _C.tealDeep,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${users.length} user${users.length != 1 ? 's' : ''}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _C.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: _scrollController,
                        cacheExtent: 700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = users[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildMobileUserCard(
                            context,
                            provider,
                            doc.id,
                            data,
                          );
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
                  if (capped) _buildCappedNotice(),
                  if (_selected.isNotEmpty)
                    _buildBulkBar(context, provider, users),
                  _buildTableHeader(),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: users.length,
                      cacheExtent: 700,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final doc = users[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return RepaintBoundary(
                          child: AnimatedBuilder(
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
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                _buildUserRow(
                                  context,
                                  provider,
                                  doc.id,
                                  data,
                                  index,
                                ),
                                if (index < users.length - 1)
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _C.border,
                                  ),
                              ],
                            ),
                          ),
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
      ),
    );
  }

  // ── Mobile user card — replaces horizontal scrolling table ──
  Widget _buildMobileUserCard(
    BuildContext ctx,
    AdminProvider provider,
    String docId,
    Map<String, dynamic> data,
  ) {
    final status = data['account_status'] ?? 'active';
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? 'No email';
    final role = data['role'] ?? 'N/A';
    final userLevel = data['user_lvl'] ?? 'basic';

    return FutureBuilder<String>(
      future: provider.fetchUnifiedName(data['uid'] ?? docId),
      builder: (context, snapshot) {
        if (!mounted) return const SizedBox.shrink();
        final displayName =
            (snapshot.data != null && snapshot.data != 'Unknown User')
            ? snapshot.data!
            : (data['name']?.toString() ?? 'Unknown');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
            boxShadow: [_C.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + name + status
              Row(
                children: [
                  _buildAvatar(displayName, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _C.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          email,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _C.muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: _C.border),
              const SizedBox(height: 12),
              // Bottom row: role + level + actions
              Row(
                children: [
                  Flexible(child: _buildRoleBadge(role)),
                  const SizedBox(width: 8),
                  Flexible(child: _buildLevelBadge(userLevel)),
                  const Spacer(),
                  // Compact actions
                  _buildActionButton(
                    Icons.edit_note_rounded,
                    'Edit',
                    _C.navy,
                    () => _showEditUserDialog(
                      context,
                      provider,
                      data,
                      docId,
                      displayName,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    status == 'active'
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    status == 'active' ? 'Suspend' : 'Activate',
                    status == 'active' ? _C.error : _C.success,
                    () async => await provider.suspendUser(docId, status),
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    Icons.lock_reset_rounded,
                    'Reset',
                    _C.tealDeep,
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

      final matchesSearch =
          _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());

      // Match by normalized role so legacy string variants filter correctly.
      final matchesRole = _selectedRoleFilter == 'all' ||
          UserRole.fromFirestore(role.toString()) ==
              UserRole.fromFirestore(_selectedRoleFilter);
      final matchesStatus =
          _selectedStatusFilter == 'all' || status == _selectedStatusFilter;

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  Widget _buildTableHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: _C.bgSoft,
        border: Border(
          bottom: BorderSide(
            color: _isScrolled ? _C.border : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(
            flex: 3,
            child: _buildHeaderCell('USER', icon: Icons.person_outline),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderCell('ROLE', icon: Icons.badge_outlined),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderCell('LEVEL', icon: Icons.stars_outlined),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderCell(
              'STATUS',
              icon: Icons.online_prediction_outlined,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildHeaderCell(
              'ACTIONS',
              align: TextAlign.center,
              icon: Icons.touch_app_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String title, {
    TextAlign align = TextAlign.left,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: align == TextAlign.center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: _C.tealDeep),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          textAlign: align,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _C.slate,
            letterSpacing: 1.2,
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

    final isSelected = _selected.contains(docId);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected ? _C.navyTint : Colors.white,
        border: Border(
          left: BorderSide(
            color: isSelected ? _C.teal : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {},
        hoverColor: _C.navyTint.withValues(alpha: 0.6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 16),
          child: FutureBuilder<String>(
            future: provider.fetchUnifiedName(data['uid'] ?? docId),
            builder: (context, snapshot) {
              if (!mounted) return const SizedBox.shrink(); // ADD THIS

              final displayName =
                  (snapshot.data != null && snapshot.data != 'Unknown User')
                  ? snapshot.data!
                  : (data['name']?.toString() ?? 'Unknown');
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    child: Checkbox(
                      value: isSelected,
                      activeColor: _C.navy,
                      side: const BorderSide(color: _C.faint, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: (v) => setState(() {
                        v == true
                            ? _selected.add(docId)
                            : _selected.remove(docId);
                      }),
                    ),
                  ),
                  Expanded(flex: 3, child: _buildUserInfo(displayName, email)),
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

  /// Branded gradient-initial avatar (navy -> teal). Avatars in this screen are
  /// initials-only (no network image), so no image decode is required; if a
  /// URL is ever attached it should be decoded via ResizeImage(...) <= 160px.
  Widget _buildAvatar(String name, {double size = 40}) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w.isEmpty ? '' : w[0])
            .join()
            .toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _C.badgeGradient,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: _C.teal.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: initials.length > 1 ? size * 0.34 : size * 0.4,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUserInfo(String name, String email) {
    return Row(
      children: [
        Hero(tag: 'avatar_$name', child: _buildAvatar(name, size: 40)),
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
                  fontWeight: FontWeight.w700,
                  color: _C.ink,
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
                  fontWeight: FontWeight.w600,
                  color: _C.muted,
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
    final label = UserRole.fromFirestore(role)?.displayLabel ??
        (role.trim().isEmpty ? 'Unknown' : role);
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: 'Role: ${label.toUpperCase()}',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _C.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: Colors.white,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (roleConfig['color'] as Color).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: (roleConfig['color'] as Color).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(roleConfig['icon'], size: 13, color: roleConfig['color']),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: roleConfig['color'],
                  ),
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
    final isBasic =
        level == 'basic' || level == 'free'; // Treat legacy free as basic

    Color bgColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData icon;

    if (isPremium) {
      bgColor = _C.amber.withValues(alpha: 0.12);
      borderColor = _C.amber.withValues(alpha: 0.3);
      iconColor = const Color(0xFFB45309);
      textColor = const Color(0xFFB45309);
      icon = Icons.workspace_premium_rounded;
    } else {
      bgColor = _C.navyTint;
      borderColor = _C.border;
      iconColor = _C.slate;
      textColor = _C.slate;
      icon = Icons.person_outline;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                userLevel[0].toUpperCase() + userLevel.substring(1),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    // active -> teal/green success; suspended/inactive -> amber; deleted -> red.
    final s = status.toLowerCase();
    final Color color;
    switch (s) {
      case 'active':
        color = _C.success;
      case 'suspended':
      case 'inactive':
        color = _C.warning;
      default:
        color = _C.error;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              status.isEmpty
                  ? 'Unknown'
                  : status[0].toUpperCase() + status.substring(1),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── C6: capped notice + bulk-action bar ───────────────────────────────────

  Widget _buildCappedNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: _C.amber.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing the first $_fetchCap users. Use search or filters to '
              'narrow the list.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFFB45309),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkBar(
    BuildContext context,
    AdminProvider provider,
    List<QueryDocumentSnapshot> pageDocs,
  ) {
    final pageIds = pageDocs.map((d) => d.id).toSet();
    final allOnPageSelected =
        pageIds.isNotEmpty && pageIds.every(_selected.contains);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: _C.navyTint,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => setState(() {
              allOnPageSelected
                  ? _selected.removeAll(pageIds)
                  : _selected.addAll(pageIds);
            }),
            style: TextButton.styleFrom(foregroundColor: _C.navy),
            icon: Icon(
              allOnPageSelected
                  ? Icons.remove_done_rounded
                  : Icons.done_all_rounded,
              size: 16,
            ),
            label: Text(
              allOnPageSelected ? 'Unselect page' : 'Select page',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_selected.length} selected',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _C.tealDeep,
            ),
          ),
          const Spacer(),
          if (_bulkBusy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_C.navy),
              ),
            )
          else ...[
            _bulkBtn('Activate', Icons.check_circle_rounded,
                _C.success, () => _runBulk(context, provider, 'activate')),
            const SizedBox(width: 6),
            _bulkBtn('Suspend', Icons.block_rounded, _C.warning,
                () => _runBulk(context, provider, 'suspend')),
            const SizedBox(width: 6),
            _bulkBtn('Delete', Icons.delete_outline_rounded,
                _C.error, () => _runBulk(context, provider, 'delete')),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Clear selection',
              onPressed: () => setState(_selected.clear),
              icon: const Icon(Icons.close_rounded, size: 18, color: _C.slate),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bulkBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Future<void> _runBulk(
    BuildContext context,
    AdminProvider provider,
    String action,
  ) async {
    final ids = _selected.toList();
    if (ids.isEmpty) return;
    final label = switch (action) {
      'delete' => 'Delete',
      'suspend' => 'Suspend',
      _ => 'Activate',
    };
    final ok = await ConfirmDialog.show(
      context,
      title: '$label ${ids.length} user${ids.length == 1 ? '' : 's'}?',
      message: action == 'delete'
          ? 'Soft-deletes the selected users. They can be restored later.'
          : 'This will $action the selected users.',
      confirmLabel: label,
      danger: action != 'activate',
    );
    if (!ok || !context.mounted) return;

    setState(() => _bulkBusy = true);
    final int done;
    switch (action) {
      case 'delete':
        done = await provider.bulkSoftDelete(ids);
      case 'suspend':
        done = await provider.bulkSetSuspended(ids, true);
      default:
        done = await provider.bulkSetSuspended(ids, false);
    }
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _bulkBusy = false;
    });
    if (context.mounted) {
      BrandSnack.success(context, '$label complete ($done)');
    }
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
    final isDeleted = status == 'deleted';
    // Two primary quick-actions + an overflow menu. Keeping the row to three
    // hit-targets prevents the action cell from overflowing on medium widths.
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          Icons.visibility_outlined,
          'View profile',
          _C.tealDeep,
          () => UserDetailPanel.show(context, uid: docId, userData: data),
        ),
        const SizedBox(width: 6),
        _buildActionButton(
          Icons.edit_note_rounded,
          'Edit user',
          _C.navy,
          () => _showEditUserDialog(context, provider, data, docId, name),
        ),
        const SizedBox(width: 6),
        _buildOverflowMenu(context, provider, docId, data, status, email, name,
            isDeleted),
      ],
    );
  }

  /// Secondary actions collapsed into a themed popup menu.
  Widget _buildOverflowMenu(
    BuildContext context,
    AdminProvider provider,
    String docId,
    Map<String, dynamic> data,
    String status,
    String email,
    String? name,
    bool isDeleted,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _C.navy.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.navy.withValues(alpha: 0.15)),
        ),
        child: const Icon(Icons.more_horiz_rounded, size: 18, color: _C.navy),
      ),
      padding: EdgeInsets.zero,
      color: Colors.white,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _C.border),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'convert':
            _showConvertRoleDialog(context, provider, docId, data, name);
          case 'toggle':
            await provider.suspendUser(docId, status);
          case 'reset':
            _showResetPasswordDialog(context, provider, email);
          case 'delete':
            _confirmSoftDelete(context, provider, docId, email);
          case 'restore':
            _confirmRestore(context, provider, docId, email);
        }
      },
      itemBuilder: (_) => [
        _menuItem('convert', Icons.swap_horiz_rounded, 'Convert role',
            const Color(0xFF2178B5)),
        if (!isDeleted)
          _menuItem(
            'toggle',
            status == 'active' ? Icons.block_rounded : Icons.check_circle_rounded,
            status == 'active' ? 'Suspend user' : 'Activate user',
            status == 'active' ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          ),
        _menuItem('reset', Icons.lock_reset_rounded, 'Reset password',
            const Color(0xFF2EC4B6)),
        const PopupMenuDivider(),
        if (isDeleted)
          _menuItem('restore', Icons.restore_rounded, 'Restore user',
              const Color(0xFF10B981))
        else
          _menuItem('delete', Icons.delete_outline_rounded, 'Delete user',
              const Color(0xFFEF4444)),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155))),
        ],
      ),
    );
  }

  // ── Role conversion / delete-restore handlers (C2) ─────────────────────────

  Future<void> _showConvertRoleDialog(
    BuildContext context,
    AdminProvider provider,
    String docId,
    Map<String, dynamic> data,
    String? name,
  ) async {
    final currentRaw = data['role']?.toString();
    final current = UserRole.fromFirestore(currentRaw);
    final email = data['email']?.toString() ?? '';
    final viewerRole = context.read<AuthNotifier>().roleEnum;
    final assignable = _assignableRoles(viewerRole);

    final selected = await showDialog<UserRole>(
      context: context,
      builder: (ctx) {
        UserRole? choice = current;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(
              'Convert Role',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${name ?? email}\nCurrent role: ${current?.displayLabel ?? currentRaw ?? 'Unknown'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                ...assignable.map(
                  (r) => RadioListTile<UserRole>(
                    value: r,
                    groupValue: choice,
                    onChanged: (v) => setLocal(() => choice = v),
                    title: Text(
                      r.displayLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: choice == null || choice == current
                    ? null
                    : () => Navigator.pop(ctx, choice),
                child: const Text('Convert'),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !context.mounted) return;
    final result = await provider.convertUserRole(
      uid: docId,
      targetRole: selected,
      fromRoleRaw: currentRaw,
      name: name,
      email: email,
    );
    if (!context.mounted) return;
    result.ok
        ? BrandSnack.success(context, result.message)
        : BrandSnack.error(context, result.message);
  }

  /// Roles the [viewer] is allowed to assign. Admin-tier assignment is
  /// restricted to those holding [Permission.assignAdminRoles] (super admin).
  List<UserRole> _assignableRoles(UserRole? viewer) {
    final base = <UserRole>[
      UserRole.jobSeeker,
      UserRole.recruiter,
      UserRole.recruitmentAgent,
    ];
    if (can(viewer, Permission.assignAdminRoles)) {
      base.addAll([UserRole.admin, UserRole.superAdmin]);
    }
    return base;
  }

  Future<void> _confirmSoftDelete(
    BuildContext context,
    AdminProvider provider,
    String docId,
    String email,
  ) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete user?',
      message:
          'This soft-deletes $email. Their account is disabled and signed out, '
          'but data is preserved and can be restored.',
      confirmLabel: 'Delete',
      danger: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !context.mounted) return;
    final result = await provider.softDeleteUser(docId, label: email);
    if (!context.mounted) return;
    result.ok
        ? BrandSnack.success(context, result.message)
        : BrandSnack.error(context, result.message);
  }

  Future<void> _confirmRestore(
    BuildContext context,
    AdminProvider provider,
    String docId,
    String email,
  ) async {
    final result = await provider.restoreUser(docId, label: email);
    if (!context.mounted) return;
    result.ok
        ? BrandSnack.success(context, result.message)
        : BrandSnack.error(context, result.message);
  }

  Widget _buildActionButton(
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback onTap,
  ) {
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
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
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
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              _buildPageButton(
                icon: Icons.chevron_left_rounded,
                onTap: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF14507F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_currentPage / $totalPages',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF14507F),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildPageButton(
                icon: Icons.chevron_right_rounded,
                onTap: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
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
        foregroundColor: onTap != null
            ? const Color(0xFF14507F)
            : Colors.grey.shade400,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: onTap != null ? const Color(0xFFE2E8F0) : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getRoleConfig(String role) {
    switch (UserRole.fromFirestore(role)) {
      case UserRole.superAdmin:
        return {
          'color': const Color(0xFF9333EA),
          'bgColor': const Color(0xFFF3E8FF),
          'icon': Icons.shield_moon_rounded,
        };
      case UserRole.admin:
        return {
          'color': const Color(0xFFDC2626),
          'bgColor': const Color(0xFFFEF2F2),
          'icon': Icons.admin_panel_settings_rounded,
        };
      case UserRole.recruiter:
        return {
          'color': const Color(0xFF14507F),
          'bgColor': const Color(0xFFEEF2FF),
          'icon': Icons.business_center_rounded,
        };
      case UserRole.recruitmentAgent:
        return {
          'color': const Color(0xFF0EA5E9),
          'bgColor': const Color(0xFFE0F2FE),
          'icon': Icons.badge_rounded,
        };
      case UserRole.jobSeeker:
        return {
          'color': const Color(0xFF10B981),
          'bgColor': const Color(0xFFECFDF5),
          'icon': Icons.work_rounded,
        };
      case null:
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
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF14507F),
              ),
              strokeWidth: 3,
              backgroundColor: Color(0xFFE0E7FF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading users...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
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
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFDC2626),
            ),
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
              backgroundColor: const Color(0xFF14507F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
            child: const Icon(
              Icons.people_outline_rounded,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
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
                color: const Color(0xFF14507F),
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

  void _showUserDialog(
    BuildContext context,
    AdminProvider provider,
    String title,
    bool isEdit,
    Map<String, dynamic>? existingData,
  ) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        String selectedRole =
            UserRole.fromFirestore(existingData?['role']?.toString())
                    ?.toFirestore() ??
                UserRole.jobSeeker.toFirestore();
        String selectedLevel = existingData?['user_lvl'] ?? 'basic';

        return StatefulBuilder(
          builder: (stfContext, setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                width: isMobile ? size.width : 540,
                constraints: BoxConstraints(
                  maxHeight: size.height * 0.85,
                  maxWidth: 540,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
                    // Modern Header with Gradient
                    Container(
                      padding: EdgeInsets.all(isMobile ? 20 : 28),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF14507F), Color(0xFF0A2E4F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isMobile ? 10 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEdit
                                  ? Icons.edit_note_rounded
                                  : Icons.person_add_rounded,
                              color: Colors.white,
                              size: isMobile ? 20 : 24,
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
                                    fontSize: isMobile ? 18 : 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEdit
                                      ? 'Update user information'
                                      : 'Create new account',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
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
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 20 : 28),
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
                              const SizedBox(height: 24),
                              _buildDialogField(
                                'Email Address',
                                provider.emailController,
                                Icons.alternate_email_rounded,
                                readOnly: isEdit,
                              ),
                              const SizedBox(height: 24),
                              if (!isEdit) ...[
                                _buildDialogField(
                                  'Password',
                                  provider.passwordController,
                                  Icons.lock_outline_rounded,
                                  obscureText: true,
                                  validator: (v) => (v?.length ?? 0) < 6
                                      ? 'Password must be at least 6 characters'
                                      : null,
                                ),
                                const SizedBox(height: 24),
                              ],
                              _buildSectionLabel('User Role'),
                              const SizedBox(height: 14),
                              _buildRoleSelector(selectedRole, (value) {
                                setDialogState(() {
                                  selectedRole = value!;
                                  provider.roleController.text = value;
                                });
                              }),
                              const SizedBox(height: 24),
                              _buildSectionLabel('Account Level'),
                              const SizedBox(height: 14),
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
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade100),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                                    if (provider.formKey.currentState!
                                        .validate()) {
                                      provider.roleController.text =
                                          selectedRole;
                                      provider.userLevelController.text =
                                          selectedLevel;

                                      final bool success;
                                      if (isEdit) {
                                        success = await provider.addOrEditUser();
                                      } else {
                                        // Create via the audited service so the
                                        // role's collection doc + audit entry
                                        // are written.
                                        final result = await provider
                                            .createUserWithRole(
                                              name:
                                                  provider.nameController.text,
                                              email: provider
                                                  .emailController.text,
                                              password: provider
                                                  .passwordController.text,
                                              role: UserRole.fromFirestore(
                                                    selectedRole,
                                                  ) ??
                                                  UserRole.jobSeeker,
                                              userLevel: selectedLevel,
                                            );
                                        success = result.ok;
                                        if (success) provider.clearForm();
                                      }

                                      // CRITICAL FIX: Check mounted on the CORRECT context
                                      if (!mounted) {
                                        return; // Check the widget's context first
                                      }

                                      if (success) {
                                        BrandSnack.success(
                                          context,
                                          provider.message,
                                        );
                                        // Check dialog context separately
                                        if (stfContext.mounted) {
                                          Navigator.pop(dialogContext);
                                        }
                                      } else {
                                        BrandSnack.error(
                                          context,
                                          provider.message,
                                        );
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
                                : Icon(
                                    isEdit
                                        ? Icons.save_rounded
                                        : Icons.add_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              isEdit ? 'Save Changes' : 'Create User',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style:
                                ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF14507F),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFFCBD5E1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ).copyWith(
                                  elevation:
                                      WidgetStateProperty.resolveWith<double>(
                                        (states) =>
                                            states.contains(WidgetState.hovered)
                                            ? 2
                                            : 0,
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

  static const Map<UserRole, IconData> _roleIcons = {
    UserRole.jobSeeker: Icons.work_outline_rounded,
    UserRole.recruiter: Icons.business_center_rounded,
    UserRole.recruitmentAgent: Icons.badge_outlined,
    UserRole.admin: Icons.admin_panel_settings_outlined,
    UserRole.superAdmin: Icons.shield_moon_outlined,
  };

  Widget _buildRoleSelector(
    String selectedRole,
    ValueChanged<String?> onChanged,
  ) {
    final viewerRole = context.read<AuthNotifier>().roleEnum;
    final roles = _assignableRoles(viewerRole);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final r in roles)
            _buildRoleOption(
              r.displayLabel,
              r.toFirestore(),
              selectedRole,
              _roleIcons[r] ?? Icons.person_outline_rounded,
              onChanged,
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
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
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
              size: 18,
              color: isSelected
                  ? const Color(0xFF0A2E4F)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0A2E4F)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelDropdown(
    String selectedLevel,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedLevel,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: const Color(0xFF0F172A),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A2E4F), width: 1.5),
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF94A3B8),
      ),
      items: [
        DropdownMenuItem(
          value: 'basic',
          child: Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 18,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Text('Basic Account', style: GoogleFonts.plusJakartaSans()),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'premium',
          child: Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                size: 18,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 12),
              Text(
                'Premium Account',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              const Badge(
                label: Text('PRO'),
                backgroundColor: Color(0xFFFEF3C7),
                textColor: Color(0xFFD97706),
              ),
            ],
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: const Color(0xFF3E5C76),
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
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5E7A8E).withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0A2E4F),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
          ),
          validator:
              validator ??
              (v) => v?.trim().isEmpty ?? true ? '$label is required' : null,
        ),
      ],
    );
  }

  void _showResetPasswordDialog(
    BuildContext context,
    AdminProvider provider,
    String email,
  ) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    showDialog(
      context: context,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.7),
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40),
        backgroundColor: Colors.transparent,
        child: Container(
          // Adaptive width: 95% on small screens, max 420 on large ones
          width: isMobile ? size.width : 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 24 : 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F3FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF2EC4B6),
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
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.alternate_email_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              email,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          provider.resetPassword(email);
                          Navigator.pop(dialogContext);
                          BrandSnack.success(
                            context,
                            'Reset link sent successfully',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14507F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Send Link',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
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
