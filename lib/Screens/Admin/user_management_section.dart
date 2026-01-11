import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_provider.dart';

class UserManagementSection extends StatefulWidget {
  const UserManagementSection({super.key});

  @override
  State<UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends State<UserManagementSection>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';
  String _selectedStatusFilter = 'all';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, provider),
                  _buildFilters(),
                  Expanded(child: _buildUsersTable(provider)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AdminProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.people_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Management',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage users, roles, and permissions across the platform',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildAddUserButton(context, provider),
        ],
      ),
    );
  }

  Widget _buildAddUserButton(BuildContext context, AdminProvider provider) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton.icon(
          onPressed: () => _showAddUserDialog(context, provider),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            'Add New User',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
          ).copyWith(
            elevation: WidgetStateProperty.resolveWith<double>(
                  (states) => states.contains(WidgetState.hovered) ? 6 : 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildSearchBar()),
          const SizedBox(width: 16),
          _buildFilterDropdown(
            'Role',
            _selectedRoleFilter,
            ['all', 'job_seeker', 'recruiter', 'admin'],
                (value) => setState(() => _selectedRoleFilter = value!),
          ),
          const SizedBox(width: 12),
          _buildFilterDropdown(
            'Status',
            _selectedStatusFilter,
            ['all', 'active', 'suspended'],
                (value) => setState(() => _selectedStatusFilter = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Search users by name or email...',
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
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
      ) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey.shade600),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item == 'all'
                    ? 'All ${label}s'
                    : item.replaceAll('_', ' ').split(' ')
                    .map((word) => word[0].toUpperCase() + word.substring(1))
                    .join(' '),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUsersTable(AdminProvider provider) {
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return _buildLoadingState();
            }

            var users = _filterUsers(snapshot.data!.docs);

            if (users.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                _buildTableHeader(),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: users.length,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade50,
                      indent: 24,
                      endIndent: 24,
                    ),
                    itemBuilder: (context, index) {
                      final doc = users[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildUserRow(context, provider, doc.id, data, index);
                    },
                  ),
                ),
                _buildTableFooter(users.length),
              ],
            );
          },
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('USER', flex: 3),
          _buildHeaderCell('ROLE', flex: 2),
          _buildHeaderCell('LEVEL', flex: 2),
          _buildHeaderCell('STATUS', flex: 2),
          _buildHeaderCell('ACTIONS', flex: 2, align: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: align,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 1.2,
        ),
      ),
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
    final userLevel = data['user_lvl'] ?? 'free';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: [
              _buildUserInfo(name, email),
              _buildRoleBadge(role),
              _buildLevelBadge(userLevel),
              _buildStatusBadge(status),
              _buildActions(context, provider, docId, data, status, email),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(String name, String email) {
    return Expanded(
      flex: 3,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getRoleColor(role).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getRoleColor(role).withOpacity(0.2),
            width: 1,
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
                color: _getRoleColor(role),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              role.replaceAll('_', ' ').split(' ')
                  .map((word) => word[0].toUpperCase() + word.substring(1))
                  .join(' '),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getRoleColor(role),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String userLevel) {
    final isPro = userLevel.toLowerCase() == 'pro';
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isPro
              ? const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          )
              : null,
          color: isPro ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPro ? Icons.workspace_premium : Icons.account_circle_outlined,
              size: 14,
              color: isPro ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              userLevel.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPro ? Colors.white : Colors.grey.shade700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status.toLowerCase() == 'active';
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF10B981).withOpacity(0.08)
              : const Color(0xFFEF4444).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? const Color(0xFF10B981).withOpacity(0.2)
                : const Color(0xFFEF4444).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                        .withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Text(
              status[0].toUpperCase() + status.substring(1),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                letterSpacing: 0.3,
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
      ) {
    return Expanded(
      flex: 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            Icons.edit_outlined,
            'Edit User',
            const Color(0xFF6366F1),
                () => _showEditUserDialog(context, provider, data, docId),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            status == 'active' ? Icons.block_outlined : Icons.check_circle_outline,
            status == 'active' ? 'Suspend User' : 'Activate User',
            status == 'active' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                () => provider.suspendUser(docId, status),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            Icons.lock_reset_outlined,
            'Reset Password',
            const Color(0xFF8B5CF6),
                () => _showResetPasswordDialog(context, provider, email),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableFooter(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(
            'Showing $count user${count != 1 ? 's' : ''}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFEF4444);
      case 'recruiter':
        return const Color(0xFF6366F1);
      case 'job_seeker':
        return const Color(0xFF10B981);
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading users...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
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
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            'Error Loading Users',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 20),
          Text(
            'No Users Found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add a new user',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, AdminProvider provider) {
    provider.clearForm();
    _showUserDialog(context, provider, 'Add New User', false);
  }

  void _showEditUserDialog(
      BuildContext context,
      AdminProvider provider,
      Map<String, dynamic> data,
      String docId,
      ) {
    provider.editUser(data, docId);
    _showUserDialog(context, provider, 'Edit User', true);
  }

  void _showUserDialog(BuildContext context, AdminProvider provider, String title, bool isEdit) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          width: 550,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Dialog Content
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
                        const SizedBox(height: 20),
                        _buildDialogField(
                          'Email Address',
                          provider.emailController,
                          Icons.email_outlined,
                          readOnly: isEdit,
                        ),
                        const SizedBox(height: 20),
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
                          const SizedBox(height: 20),
                        ],
                        _buildDialogField(
                          'Role',
                          provider.roleController,
                          Icons.badge_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildDialogField(
                          'User Level',
                          provider.userLevelController,
                          Icons.workspace_premium_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Dialog Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100),
                  ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () {
                        if (provider.formKey.currentState!.validate()) {
                          provider.addOrEditUser(context);
                          Navigator.pop(dialogContext);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: provider.isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : Text(
                        isEdit ? 'Update User' : 'Add User',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.2,
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

  void _showResetPasswordDialog(BuildContext context, AdminProvider provider, String email) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: Color(0xFFEF4444),
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Reset Password',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Send a password reset email to:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.resetPassword(email);
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Send Reset Email',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
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
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: readOnly,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator ?? (v) => v?.trim().isEmpty ?? true ? '$label is required' : null,
        ),
      ],
    );
  }
}