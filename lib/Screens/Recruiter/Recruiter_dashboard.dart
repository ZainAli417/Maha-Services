import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Job_Seeker/job_hub.dart';
import 'R_Top_Bar.dart';
import 'Recruiter_provider.dart';

class RecruiterDashboard extends StatefulWidget {
  const RecruiterDashboard({super.key});

  @override
  State<RecruiterDashboard> createState() => _RecruiterDashboardState();
}

class _RecruiterDashboardState extends State<RecruiterDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showShadow = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _scrollController.addListener(() {
      if (_scrollController.offset > 10 && !_showShadow) {
        setState(() => _showShadow = true);
      } else if (_scrollController.offset <= 10 && _showShadow) {
        setState(() => _showShadow = false);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return '•••@•••.com';
    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '••@${domain[0]}•••.${domain.split('.').last}';
    }

    return '${username.substring(0, 2)}•••@${domain[0]}•••.${domain.split('.').last}';
  }

  String _maskPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length < 4) return '•••-•••';

    return '•••-•••-${cleaned.substring(cleaned.length - 2)}';
  }





  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Row(
        children: [
          RecruiterSidebar(activeIndex: 0),
          Expanded(
            child:Padding(padding: EdgeInsetsGeometry.all(0),

              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildDashboardContent(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildDashboardContent(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isTablet = MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1024;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: _buildAppBar(context),
      body: ChangeNotifierProvider(
        create: (_) => RecruiterProvider2(),
        builder: (context, _) {
          final prov = Provider.of<RecruiterProvider2>(context);

          return _buildDesktopLayout(prov, screenWidth);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext c) {
    return AppBar(
      elevation: 0,
      backgroundColor: Color(0xFFFFFFFF),
      toolbarHeight: 72,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.people_alt_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Candidate Management',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage and review candidates',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Privacy Badge
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.1),
                const Color(0xFF10B981).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.security_rounded,
                size: 16,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              Text(
                'Privacy Protected',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _showShadow
                  ? [
                const Color(0xFFE2E8F0),
                const Color(0xFFE2E8F0).withOpacity(0.5),
              ]
                  : [Colors.transparent, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }


// Updated _buildDesktopLayout - Filters now horizontal at top
  Widget _buildDesktopLayout(RecruiterProvider2 prov, double screenWidth) {
    return Container(

      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFFFFFFF),

            ),
            child: _buildSearchAndFilters(prov, false, screenWidth),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: prov.loading
                              ? _buildLoadingState()
                              : _buildCandidatesSection(prov, false),
                        ),
                      ),
                    ],
                  ),
                ),
                if (prov.selectedUids.isNotEmpty)
                  _buildBottomActionBar(prov, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Updated _buildSearchAndFilters - Now horizontal layout
  // Replace your SingleChildScrollView(...) with this
  Widget _buildSearchAndFilters(
      RecruiterProvider2 prov,
      bool isMobile,
      double screenWidth,
      ) {
    final natList = [
      'All',
      ...prov.nationalityOptions
          .where((s) => s.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => a.compareTo(b))
    ];
    final sortOptions = ['None', 'Name A→Z', 'Name Z→A', 'Recently Added'];

    // explicit height to ensure children are laid out before hit testing
    return SizedBox(
      height: 120, // tweak to match your app bar / line height
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  size: 20,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Filters',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 32),

              // Search (explicit width)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSectionLabel('Search'),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 280,
                      child: _buildSearchField(prov),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Nationality (bounded)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSectionLabel('Nationality'),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 200,
                      child: _buildNationalityDropdown(natList, prov),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Sort by (bounded)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSectionLabel('Sort By'),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 200,
                      child: _buildSortDropdown(sortOptions, prov),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Active filters (ensure this chunk has a fixed height and bounded width)
              if (_hasActiveFilters(prov)) ...[
                Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSectionLabel('Active Filters'),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: _buildActiveFiltersChips(prov),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
              ],

              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 24),

              // Clear button (bounded)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 80, maxWidth: 200),
                child: _buildClearButtonFull(prov),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
        letterSpacing: 0.3,
      ),
    );
  }

  bool _hasActiveFilters(RecruiterProvider2 prov) {
    return prov.searchQuery.isNotEmpty ||
        (prov.selectedNationality != null && prov.selectedNationality!.isNotEmpty) ||
        prov.sortOption != 'None';
  }

  Widget _buildActiveFiltersChips(RecruiterProvider2 prov) {
    final chips = <Widget>[];

    if (prov.searchQuery.isNotEmpty) {
      chips.add(_buildFilterChip(
        'Search: "${prov.searchQuery}"',
        Icons.search,
            () {
          _searchCtrl.clear();
          prov.setSearch('');
        },
      ));
    }

    if (prov.selectedNationality != null && prov.selectedNationality!.isNotEmpty) {
      chips.add(_buildFilterChip(
        prov.selectedNationality!,
        Icons.public,
            () => prov.setNationalityFilter(null),
      ));
    }

    if (prov.sortOption != 'None') {
      chips.add(_buildFilterChip(
        prov.sortOption,
        Icons.sort,
            () => prov.setSortOption('None'),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6366F1)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6366F1),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(RecruiterProvider2 prov) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: prov.searchQuery.isNotEmpty
              ? const Color(0xFF6366F1).withOpacity(0.3)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: prov.searchQuery.isNotEmpty
            ? [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ]
            : [],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => prov.setSearch(v),
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Search candidates...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w400,
          ),
          filled: false,
          border: InputBorder.none,
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.search_rounded,
              color: Color(0xFF6366F1),
              size: 20,
            ),
          ),
          suffixIcon: prov.searchQuery.isNotEmpty
              ? IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFF6366F1),
                size: 16,
              ),
            ),
            onPressed: () {
              _searchCtrl.clear();
              prov.setSearch('');
            },
          )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildNationalityDropdown(List<String> natList, RecruiterProvider2 prov) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        color: const Color(0xFFFFFFFF),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: prov.selectedNationality == null ||
            (prov.selectedNationality?.isEmpty ?? true)
            ? 'All'
            : prov.selectedNationality,
        items: natList
            .map((n) => DropdownMenuItem(
          value: n,
          child: Text(
            n,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
          ),
        ))
            .toList(),
        onChanged: (v) {
          if (v == null || v == 'All') {
            prov.setNationalityFilter(null);
          } else {
            prov.setNationalityFilter(v);
          }
        },
        decoration: const InputDecoration(
          filled: false,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.public_rounded,
            size: 20,
            color: Color(0xFF6366F1),
          ),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF64748B),
          size: 24,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
      ),
    );
  }

  Widget _buildSortDropdown(List<String> sortOptions, RecruiterProvider2 prov) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        color: const Color(0xFFFFFFFF),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: prov.sortOption,
        items: sortOptions
            .map((s) => DropdownMenuItem(
          value: s,
          child: Text(
            s,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
          ),
        ))
            .toList(),
        onChanged: (v) {
          if (v != null) prov.setSortOption(v);
        },
        decoration: const InputDecoration(
          filled: false,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.swap_vert_rounded,
            size: 20,
            color: Color(0xFF6366F1),
          ),
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF64748B),
          size: 24,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 8,
      ),
    );
  }

  Widget _buildClearButton(RecruiterProvider2 prov) {
    return TextButton.icon(
      onPressed: () {
        _searchCtrl.clear();
        prov.clearSelection();
      },
      icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF64748B)),
      label: Text(
        'Clear',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildClearButtonFull(RecruiterProvider2 prov) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _searchCtrl.clear();
          prov.clearSelection();
        },
        icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
        label: Text(
          'Clear All Filters',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: const Color(0xFFFFFFFF),
          foregroundColor: const Color(0xFF64748B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading candidates...',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait a moment',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCandidatesSection(RecruiterProvider2 prov, bool isMobile) {
    final list = prov.searchQuery.isEmpty ? prov.candidates : prov.filtered;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.05),
                    const Color(0xFF8B5CF6).withOpacity(0.02),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 64,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No candidates found',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Results Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                const Color(0xFFFFFFFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${list.length} ${list.length == 1 ? 'Candidate' : 'Candidates'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total results',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!isMobile) _buildTableHeader(),
        if (!isMobile) const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) =>
              _buildCandidateCard(context, list[idx], prov, isMobile),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    final minWidths = <double>[150, 150, 150, 150, 150, 150, 180];
    final cells = <Widget>[
      _headerText('Profile pic'),
      _headerText('Name'),
      _headerText('Email'),
      _headerText('Phone'),
      _headerText('Nationality'),
      _headerText('Actions'),
      _headerText('Select'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF1F5F9),
            const Color(0xFFFFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: _responsiveRow(
        cells: cells,
        minWidths: minWidths,
        gap: 10,
        cellPadding: EdgeInsets.all(3),
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w500,
        fontSize: 15,
        color: const Color(0xFF64748B),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCandidateCard(
      BuildContext context,
      Candidate candidate,
      RecruiterProvider2 prov,
      bool isMobile,
      ) {
    final isSelected = prov.selectedUids.contains(candidate.uid);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: _HoverScale(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(0.08),
                const Color(0xFF8B5CF6).withOpacity(0.04),
              ],
            )
                : const LinearGradient(
              colors: [Colors.white, Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF6366F1).withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 20 : 16,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              )
            ],
          ),
          child: isMobile
              ? _buildMobileCandidateCard(context, candidate, prov)
              : _responsiveRow(
            cells: <Widget>[
              _buildAvatar(candidate),
              _buildHighlightText(candidate.name, prov.searchQuery),
              // show masked email in table
              _buildHighlightText(_maskEmail(candidate.email), prov.searchQuery),
              // show masked phone in table
              _buildHighlightText(_maskPhone(candidate.phone), prov.searchQuery),
              _buildNationalityChip(candidate.nationality, prov.searchQuery),
              _buildViewDetailsButton(context, candidate, prov),
              _buildCheckbox(isSelected, () {
                prov.toggleSelection(candidate.uid, value: !isSelected);
              }),
            ],
            minWidths : <double>[150, 150, 150, 150, 150, 150, 180],

          gap: 10,
            cellPadding: const EdgeInsets.symmetric(vertical: 5),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isSelected, VoidCallback onChanged) {
    return GestureDetector(
      onTap: onChanged,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(0xFFCBD5E1),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
              : [],
        ),
        child: isSelected
            ? const Icon(
          Icons.check_rounded,
          size: 16,
          color: Colors.white,
        )
            : null,
      ),
    );
  }

  Widget _responsiveRow({
    required List<Widget> cells,
    required List<double> minWidths,
    double gap = 16,
    EdgeInsets cellPadding = const EdgeInsets.symmetric(vertical: 6),
  }) {
    assert(cells.length == minWidths.length);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final totalMin =
            minWidths.reduce((a, b) => a + b) + gap * (minWidths.length - 1);

        if (available < totalMin) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List<Widget>.generate(cells.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(right: i == cells.length - 1 ? 0 : gap),
                  child: SizedBox(
                    width: minWidths[i],
                    child: Padding(padding: cellPadding, child: cells[i]),
                  ),
                );
              }),
            ),
          );
        }

        final totalWeight = minWidths.reduce((a, b) => a + b);
        final flexes = minWidths
            .map((w) => (w / totalWeight * 1000).round().clamp(1, 10000))
            .toList();

        return Row(
          children: List<Widget>.generate(cells.length, (i) {
            final flex = flexes[i];
            return Expanded(
              flex: flex,
              child: Padding(
                padding: EdgeInsets.only(right: i == cells.length - 1 ? 0 : gap),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(padding: cellPadding, child: cells[i]),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildAvatar(Candidate candidate) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: candidate.pictureUrl.isEmpty
            ? const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundImage: candidate.pictureUrl.isNotEmpty
            ? NetworkImage(candidate.pictureUrl) as ImageProvider
            : null,
        backgroundColor: Colors.transparent,
        child: candidate.pictureUrl.isEmpty
            ? const Icon(Icons.person_rounded, color: Colors.white, size: 24)
            : null,
      ),
    );
  }

  Widget _buildMobileCandidateCard(
      BuildContext context,
      Candidate candidate,
      RecruiterProvider2 prov,
      ) {
    final isSelected = prov.selectedUids.contains(candidate.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAvatar(candidate),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHighlightText(candidate.name, prov.searchQuery),
                  const SizedBox(height: 4),
                  Text(
                    // masked email on mobile list
                    _maskEmail(candidate.email),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _buildCheckbox(isSelected, () {
              prov.toggleSelection(candidate.uid, value: !isSelected);
            }),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // masked phone here
                  Expanded(child: _buildMobileInfoChip(Icons.phone, _maskPhone(candidate.phone))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMobileInfoChip(Icons.public, candidate.nationality),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildViewDetailsButton(context, candidate, prov),
      ],
    );
  }

  Widget _buildMobileInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNationalityChip(String nationality, String query) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public_rounded, size: 16, color: Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Flexible(child: _buildHighlightText(nationality, query)),
        ],
      ),
    );
  }

  Widget _buildViewDetailsButton(
      BuildContext context,
      Candidate candidate,
      RecruiterProvider2 prov,
      ) {
    return InkWell(
      onTap: () async {
        final profile = await prov.fetchProfile(candidate.uid);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => CandidateDetailsDialog(
              candidate: candidate,
              profile: profile,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_outlined, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'View Details',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lcText = text.toLowerCase();
    final lcQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lcText.indexOf(lcQuery, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + lcQuery.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFDDD6FE),
            fontWeight: FontWeight.w700,
            color: Color(0xFF6366F1),
          ),
        ),
      );
      start = idx + lcQuery.length;
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
        children: spans,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBottomActionBar(RecruiterProvider2 prov, bool isMobile) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          )
        ],
      ),
      child: isMobile
          ? Column(
        children: [
          _buildSelectionBadge(prov),
          const SizedBox(height: 16),
          _buildSendButton(prov),
        ],
      )
          : Row(
        children: [
          _buildSelectionBadge(prov),
          const Spacer(),
          _buildSendButton(prov),
        ],
      ),
    );
  }

  Widget _buildSelectionBadge(RecruiterProvider2 prov) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${prov.selectedUids.length} Selected',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6366F1),
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Ready to send',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6366F1).withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(RecruiterProvider2 prov) {
    final isEnabled = prov.selectedUids.isNotEmpty;

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isEnabled ? () => _handleSendRequest(prov) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isEnabled ? null : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isEnabled
                ? [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: 0,
              )
            ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.send_rounded,
                size: 20,
                color: isEnabled ? Colors.white : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 12),
              Text(
                'Send to Admin',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isEnabled ? Colors.white : const Color(0xFF94A3B8),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendRequest(RecruiterProvider2 prov) async {
    final requestId = await prov.sendSelectedCandidatesToAdmin(
      notes: 'Sent from dashboard',
    );

    if (!mounted) return;

    if (requestId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (_) => _successDialog(requestId),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (_) => _errorDialog(),
      );
    }
  }

  Widget _successDialog(String requestId) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(0.1),
                    const Color(0xFF10B981).withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Request Sent!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'ID: $requestId',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The admin will review your request shortly',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEF4444).withOpacity(0.1),
                    const Color(0xFFEF4444).withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Request Failed',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to send request or no candidates selected.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hover scale widget for desktop micro-interactions
class _HoverScale extends StatefulWidget {
  final Widget child;
  const _HoverScale({required this.child});

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final transform = Matrix4.identity()..scale(_hover ? 1.015 : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: transform,
        child: widget.child,
      ),
    );
  }
}



class CandidateDetailsDialog extends StatelessWidget {
  final Candidate candidate;
  final Map<String, dynamic>? profile;

  const CandidateDetailsDialog({
    required this.candidate,
    required this.profile,
    super.key,
  });

  // Helper: fetch nested canonical personal map if exists
  Map<String, dynamic> _personal(Map<String, dynamic> p) {
    if (p.containsKey('personalProfile') && p['personalProfile'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(p['personalProfile'] as Map<String, dynamic>);
    }
    if (p.containsKey('personal') && p['personal'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(p['personal'] as Map<String, dynamic>);
    }
    return p;
  }

  // Mask helpers
  String maskPhone(String raw) {
    final s = raw.replaceAll(' ', '');
    if (s.isEmpty) return '-';
    if (s.length <= 5) {
      if (s.length <= 2) return s;
      final first = s.substring(0, 1);
      final last = s.substring(s.length - 1);
      return '$first***$last';
    }
    final first = s.substring(0, 3);
    final last = s.substring(s.length - 2);
    final midLen = s.length - (3 + 2);
    final mid = 'x' * (midLen > 0 ? midLen : 1);
    return '$first$mid$last';
  }

  String maskEmail(String raw) {
    if (raw.trim().isEmpty) return '-';
    final parts = raw.split('@');
    if (parts.length != 2) return raw;
    final local = parts[0];
    final domain = parts[1];
    final first = local.isNotEmpty ? local[0] : '';
    return '$first***@$domain';
  }

  String _maskIfHiddenValue(String? val, {required bool isEmail, required bool isPhone}) {
    if (val == null || val.trim().isEmpty) return '-';
    if (!candidate.hideContact) {
      return val;
    }
    if (isEmail) return maskEmail(val);
    if (isPhone) return maskPhone(val);
    return '****';
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDob(dynamic dobRaw) {
    try {
      if (dobRaw == null) return '-';
      if (dobRaw is Timestamp) {
        final dt = dobRaw.toDate().toLocal();
        return '${DateFormat.yMMMMd().format(dt)} • ${_calculateAge(dt)}';
      }
      if (dobRaw is Map && (dobRaw.containsKey('seconds') || dobRaw.containsKey('_seconds'))) {
        final seconds = (dobRaw['seconds'] ?? dobRaw['_seconds']) as int;
        final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).toLocal();
        return '${DateFormat.yMMMMd().format(dt)} • ${_calculateAge(dt)}';
      }
      if (dobRaw is String) {
        final parsed = DateTime.tryParse(dobRaw);
        if (parsed != null) {
          final dt = parsed.toLocal();
          return '${DateFormat.yMMMMd().format(dt)} • ${_calculateAge(dt)}';
        }
        return dobRaw;
      }
      if (dobRaw is DateTime) {
        final dt = dobRaw.toLocal();
        return '${DateFormat.yMMMMd().format(dt)} • ${_calculateAge(dt)}';
      }
      return dobRaw.toString();
    } catch (_) {
      return dobRaw?.toString() ?? '-';
    }
  }

  String _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int years = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) years--;
    return '$years yrs';
  }

  Widget _infoCard(IconData icon, String label, String value, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            iconColor.withOpacity(0.08),
            iconColor.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.18), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [iconColor, iconColor.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: iconColor.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _experienceCard(Map<String, dynamic> exp) {
    final role = (exp['role'] ?? exp['title'] ?? exp['position'])?.toString() ?? '';
    final company = (exp['company'] ?? exp['organization'] ?? exp['employer'])?.toString() ?? '';
    final start = (exp['start'] ?? exp['from'])?.toString() ?? '';
    final end = (exp['end'] ?? exp['to'] ?? exp['duration'])?.toString() ?? '';
    final durationText = (start.isNotEmpty || end.isNotEmpty) ? '$start${start.isNotEmpty && end.isNotEmpty ? ' - ' : ''}$end' : '';

    // description fallback order: description, details, roleDescription, text, summary
    final description = (exp['description'] ?? exp['roleDescription'] ?? exp['details'] ?? exp['text'] ?? exp['summary'])?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFF59E0B).withOpacity(0.12), const Color(0xFFEC4899).withOpacity(0.12)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.26), width: 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEC4899)]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: const Icon(Icons.work_outline, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (role.isNotEmpty) Text(role, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
            if (company.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(company, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            ],
            if (durationText.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(durationText, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFF59E0B)))),
            ],
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF475569))),
            ]
          ]),
        )
      ]),
    );
  }

  Widget _educationCard(Map<String, dynamic> edu) {
    final title = (edu['degree'] ?? edu['title'] ?? edu['name'])?.toString() ?? '';
    final institute = (edu['institute'] ?? edu['company'] ?? edu['organization'] ?? edu['institutionName'])?.toString() ?? '';
    final year = (edu['year'] ?? edu['end'] ?? edu['to'] ?? edu['duration'])?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF10B981).withOpacity(0.12), const Color(0xFF059669).withOpacity(0.12)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.26), width: 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]), child: const Icon(Icons.school_outlined, color: Colors.white, size: 16)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title.isNotEmpty) Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
          if (institute.isNotEmpty) ...[ const SizedBox(height: 4), Text(institute, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))],
          if (year.isNotEmpty) ...[ const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(year, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)))) ],
        ]))
      ]),
    );
  }

  Widget _certificationBadge(String cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF6366F1).withOpacity(0.08), const Color(0xFF8B5CF6).withOpacity(0.06)]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.26), width: 1),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]), shape: BoxShape.circle), child: const Icon(Icons.verified_outlined, color: Colors.white, size: 14)),
        const SizedBox(width: 12),
        Expanded(child: Text(cert, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)))),
      ]),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      if (!await canLaunchUrl(uri)) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // ignore
    }
  }

  Widget _cvButton(dynamic link) {
    if (link == null) return const SizedBox.shrink();
    final s = link.toString();
    if (s.isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: () => _openUrl(s),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.22), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.picture_as_pdf, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Text('View Full CV/Resume', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)),
          const SizedBox(width: 8),
          const Icon(Icons.open_in_new, color: Colors.white, size: 16),
        ]),
      ),
    );
  }

  Widget _buildContactBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 8),
        Flexible(child: Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  // Safely read list fields with multiple fallback keys
  List<Map<String, dynamic>> _readList(Map<String, dynamic> p, List<String> keys) {
    for (final k in keys) {
      final v = p[k];
      if (v == null) continue;

      if (v is List) {
        return v.map<Map<String, dynamic>>((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return {'text': e?.toString() ?? ''};
        }).toList();
      }

      if (v is Map) {
        final out = <Map<String, dynamic>>[];
        for (final val in v.values) {
          if (val is Map) {
            out.add(Map<String, dynamic>.from(val));
          } else {
            out.add({'text': val?.toString() ?? ''});
          }
        }
        return out;
      }

      if (v is String && v.isNotEmpty) {
        return [
          {'text': v}
        ];
      }
    }
    return [];
  }

  // Read and normalize documents from various keys (also handles misspelling 'docuemnts')
  List<Map<String, dynamic>> _readDocuments(Map<String, dynamic> p) {
    final keys = ['documents', 'docuemnts', 'documentsList', 'documentsArray', 'docs', 'files'];
    for (final k in keys) {
      final v = p[k];
      if (v == null) continue;

      List<Map<String, dynamic>> toList = [];
      if (v is List) {
        toList = v.map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return {'name': e?.toString() ?? '', 'url': ''};
        }).toList();
      } else if (v is Map) {
        for (final val in v.values) {
          if (val is Map) {
            toList.add(Map<String, dynamic>.from(val));
          } else {
            toList.add({'name': val?.toString() ?? '', 'url': ''});
          }
        }
      } else if (v is String && v.isNotEmpty) {
        toList = [
          {'name': v}
        ];
      }

      return toList.map((doc) {
        final name = doc['name'] ??
            doc['fileName'] ??
            doc['title'] ??
            doc['displayName'] ??
            doc['nameString'] ??
            '';
        final url = doc['url'] ??
            doc['link'] ??
            doc['downloadUrl'] ??
            doc['fileUrl'] ??
            doc['download_link'] ??
            doc['storageUrl'] ??
            '';
        final contentType = doc['contentType'] ?? doc['mimeType'] ?? '';
        final uploadedAt = doc['uploadedAt'] ?? doc['createdAt'] ?? '';
        return {
          ...doc,
          'name': name,
          'url': url,
          'contentType': contentType,
          'uploadedAt': uploadedAt,
        };
      }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final p = profile ?? <String, dynamic>{};
    final personal = _personal(p);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // personal quick fields
    final fullName = candidate.name.isNotEmpty ? candidate.name : (personal['name'] ?? personal['fullName'] ?? '-').toString();
    final rawEmail = (personal['email'] ?? personal['secondary_email'] ?? candidate.email ?? '').toString();
    final rawPhone = (personal['contactNumber'] ?? personal['phone'] ?? candidate.phone ?? '').toString();

    final emailDisplay = _maskIfHiddenValue(rawEmail, isEmail: true, isPhone: false);
    final phoneDisplay = _maskIfHiddenValue(rawPhone, isEmail: false, isPhone: true);

    final socialRaw = (personal['socialLinks'] ?? personal['social'] ?? personal['social_links']);
    final socialList = <String>[];
    if (socialRaw is List) {
      for (final s in socialRaw) {
        if (s != null) socialList.add(s.toString());
      }
    } else if (socialRaw is String && socialRaw.isNotEmpty) {
      socialList.addAll(socialRaw.split(RegExp(r'[,;\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty));
    }

    final educationList = _readList(p, ['educationalProfile', 'education', 'educations', 'qualifications']);
    final experienceList = _readList(p, ['professionalExperience', 'experiences', 'experience', 'work_experience']);
    final certificationsList = (p['certifications'] ?? p['certiicaitons'] ?? p['certs'] ?? p['training']) is List ? (p['certifications'] ?? p['certiicaitons'] ?? p['certs'] ?? p['training']).cast<dynamic>().map((e) => e.toString()).toList() : <String>[];
    final publicationsList = (p['publications'] ?? p['papers']) is List ? (p['publications'] ?? p['papers']).cast<dynamic>().map((e) => e.toString()).toList() : <String>[];
    final awardsList = (p['awards'] ?? p['honors']) is List ? (p['awards'] ?? p['honors']).cast<dynamic>().map((e) => e.toString()).toList() : <String>[];
    final referencesList = (p['references'] ?? p['refs']) is List ? (p['references'] ?? p['refs']).cast<dynamic>().map((e) => e.toString()).toList() : <String>[];

    final documentsList = _readDocuments(p);

    // cv link - multiple fallbacks
    final cvLinkLegacy = (p['Cv/Resume'] ?? p['cv'] ?? p['cv_url'] ?? p['resume'] ?? p['resume_url'] ?? p['cvUrl'] ?? p['resumeUrl'])?.toString();
    final firstDocUrl = documentsList.isNotEmpty ? (documentsList.first['url']?.toString() ?? '') : '';
    final cvUrlToShow = firstDocUrl.isNotEmpty ? firstDocUrl : (cvLinkLegacy ?? '');

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: isMobile ? 16 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, spreadRadius: 4)]),
          child: SingleChildScrollView(
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                child: Row(children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]),
                    child: CircleAvatar(radius: 44, backgroundImage: candidate.pictureUrl.isNotEmpty ? NetworkImage(candidate.pictureUrl) as ImageProvider : null, backgroundColor: Colors.white, child: candidate.pictureUrl.isEmpty ? const Icon(Icons.person, size: 44, color: Color(0xFF6366F1)) : null),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(fullName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 10),
                      Row(children: [
                        _buildContactBadge(Icons.email_outlined, emailDisplay),
                        const SizedBox(width: 8),
                        _buildContactBadge(Icons.phone_outlined, phoneDisplay),
                        const SizedBox(width: 8),
                        if (socialList.isNotEmpty) _buildContactBadge(Icons.link, candidate.hideContact ? '****' : (socialList.join(' • '))),
                      ]),
                    ]),
                  ),
                ]),
              ),

              // Body content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Personal Info (section)
                  _sectionHeader('Personal Information', Icons.person_outline),
                  _infoCard(Icons.person, 'Full Name', fullName, const Color(0xFF6366F1)),
                  _infoCard(Icons.email_outlined, 'Email', _maskIfHiddenValue(rawEmail, isEmail: true, isPhone: false), const Color(0xFF8B5CF6)),
                  _infoCard(Icons.phone, 'Contact Number', _maskIfHiddenValue(rawPhone, isEmail: false, isPhone: true), const Color(0xFFF59E0B)),
                  _infoCard(Icons.flag_outlined, 'Nationality', (personal['nationality'] ?? candidate.nationality ?? '-').toString(), const Color(0xFF10B981)),
                  _infoCard(Icons.cake_outlined, 'Date of Birth', _formatDob(personal['dob'] ?? personal['date_of_birth']), const Color(0xFFEC4899)),
                  if (!candidate.hideContact && personal['socialLinks'] != null) _infoCard(Icons.link, 'Social Links', (socialList.isNotEmpty ? socialList.join(' • ') : '-'), const Color(0xFF6366F1)),

                  // Educational Profile
                  _sectionHeader('Educational Profile', Icons.school_outlined),
                  if (educationList.isNotEmpty)
                    ...educationList.map((e) => _educationCard(e))
                  else
                    Text('No education information available', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),

                  // Professional Summary (professionalProfile.summary)
                  _sectionHeader('Professional Summary', Icons.article_outlined),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                    child: Text(
                      (p['professionalProfile'] is Map && (p['professionalProfile']['summary'] ?? '').toString().isNotEmpty)
                          ? p['professionalProfile']['summary'].toString()
                          : (p['professionalSummary'] ?? personal['summary'] ?? '-').toString(),
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF475569), fontWeight: FontWeight.w600),
                    ),
                  ),

                  // Professional Experience
                  _sectionHeader('Professional Experience', Icons.work_outline),
                  if (experienceList.isNotEmpty)
                    ...experienceList.map((e) => _experienceCard(e))
                  else
                    Text('No experience information available', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),

                  // Skills & Expertise (from personal.skills)
                  _sectionHeader('Skills & Expertise', Icons.emoji_objects_outlined),
                  if ((personal['skills'] ?? p['skills']) is List && ((personal['skills'] ?? p['skills']) as List).isNotEmpty)
                    Wrap(spacing: 10, runSpacing: 10, children: ((personal['skills'] ?? p['skills']) as List).map<Widget>((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(18)), child: Text(s.toString(), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)))).toList())
                  else
                    Text('No skills listed', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),

                  // Certifications / Trainings
                  _sectionHeader('Certifications & Trainings', Icons.verified_outlined),
                  if (certificationsList.isNotEmpty)
                    ...certificationsList.map((c) => _certificationBadge(c)).toList()
                  else
                    Text('No certifications available', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),

                  // Publications
                  _sectionHeader('Publications', Icons.library_books_outlined),
                  if (publicationsList.isNotEmpty)
                    ...publicationsList.map((pub) => _certificationBadge(pub)).toList()
                  else
                    Text('No publications available', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),

                  // Awards
                  _sectionHeader('Awards & Honours', Icons.emoji_events_outlined),
                  if (awardsList.isNotEmpty)
                    ...awardsList.map((a) => _certificationBadge(a)).toList()
                  else
                    Text('No awards available', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),

                  // References
                  _sectionHeader('References', Icons.people_outline),
                  if (referencesList.isNotEmpty)
                    ...referencesList.map((r) => _certificationBadge(r)).toList()
                  else
                    Text('No references available', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),

                  // Documents / CV
                  _sectionHeader('Documents', Icons.description_outlined),
                  if (documentsList.isNotEmpty) ...[
                    for (final doc in documentsList)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                        leading: const Icon(Icons.picture_as_pdf_outlined),
                        title: Text(doc['name']?.toString() ?? 'Document', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: (doc['contentType'] ?? doc['uploadedAt']) != null && (doc['contentType']?.toString().isNotEmpty ?? false)
                            ? Text(doc['contentType']?.toString() ?? doc['uploadedAt'].toString(), style: GoogleFonts.poppins(fontSize: 12))
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () {
                            final u = doc['url']?.toString() ?? '';
                            if (u.isNotEmpty) _openUrl(u);
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (cvUrlToShow.isNotEmpty) _cvButton(cvUrlToShow),
                  ] else if (cvUrlToShow.isNotEmpty)
                    _cvButton(cvUrlToShow)
                  else
                    Text('No CV/Resume found', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),

                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.close, color: Color(0xFF64748B)), const SizedBox(width: 8), Text('Close', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))])),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}



