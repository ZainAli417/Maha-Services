import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

import 'LIst_of_Applicants.dart';
import 'job_detail_dialog_recrutier.dart';
import 'package:job_portal/Screens/Recruiter/R_Top_Bar.dart';

// ─── Shared color tokens ──────────────────────────────────────────────────────
const _kPrimary = Color(0xFF6366F1);
const _kAccent = Color(0xFF818CF8);
const _kSuccess = Color(0xFF10B981);
const _kSurface = Color(0xFFFFFFFF);
const _kBg = Color(0xFFFAFAFA);
const _kTxtPrimary = Color(0xFF0F172A);
const _kTxtSec = Color(0xFF64748B);
const _kTxtTert = Color(0xFF94A3B8);
const _kBorder = Color(0xFFE2E8F0);
const _kBorderLt = Color(0xFFF1F5F9);
const _kSurfaceEl = Color(0xFFFAFAFA);

// ─────────────────────────────────────────────────────────────────────────────
// TOP-LEVEL SCAFFOLD  (sidebar + appbar, no duplicate header)
// ─────────────────────────────────────────────────────────────────────────────
class Job_Applicant_Tracker extends StatefulWidget {
  const Job_Applicant_Tracker({super.key});
  @override
  State<Job_Applicant_Tracker> createState() => _Job_Applicant_TrackerState();
}

class _Job_Applicant_TrackerState extends State<Job_Applicant_Tracker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBg,
      drawer: isMobile
          ? Drawer(child: RecruiterSidebar(activeIndex: 2, isDrawer: true))
          : null,
      body: Row(
        children: [
          if (!isMobile) const RecruiterSidebar(activeIndex: 2),
          Expanded(
            child: FadeTransition(
              opacity: _controller,
              child: Column(
                children: [
                  // ── Single AppBar (mobile AND desktop) ─────────────────
                  _AppBar(scaffoldKey: _scaffoldKey, isMobile: isMobile),
                  // ── Content ────────────────────────────────────────────
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      key: ValueKey(
                        FirebaseAuth.instance.currentUser?.uid ?? '',
                      ),
                      stream: FirebaseFirestore.instance
                          .collection('Posted_jobs_public')
                          .where(
                            'recruiterUid',
                            isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                          )
                          .orderBy('timestamp', descending: true)
                          .snapshots(includeMetadataChanges: true),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: _kPrimary),
                          );
                        }
                        if (snapshot.hasError) {
                          return _ErrorWidget(error: snapshot.error.toString());
                        }
                        final docs = snapshot.data?.docs ?? [];
                        final activeDocs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = (data['status'] ?? 'active')
                              .toString()
                              .toLowerCase()
                              .trim();
                          return status != 'archived' && status != 'archive';
                        }).toList();
                        final jobIds = activeDocs.map((d) => d.id).toList();
                        final version = activeDocs
                            .map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return '${doc.id}:${data['status']}:${data['updatedAt']}:${data['applicationCount']}:${data['viewCount']}';
                            })
                            .join('|');
                        if (jobIds.isEmpty) return const _EmptyWidget();
                        return Job_Applicant_Wrapper(
                          jobIds: jobIds,
                          snapshotVersion: version,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Unified AppBar (replaces both _buildMobileAppBar + _buildHeader) ─────────
class _AppBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool isMobile;
  const _AppBar({required this.scaffoldKey, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20),
        decoration: const BoxDecoration(color: Color(0xFFFAFAFA)),
        child: Row(
          children: [
            if (isMobile) ...[
              IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  size: 24,
                  color: _kTxtPrimary,
                ),
                onPressed: () => scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 2),
            ],
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.track_changes_outlined,
                size: 20,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Job Application Tracker',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: _kTxtPrimary,
                      height: 1.2,
                    ),
                  ),
                  if (!isMobile)
                    Text(
                      'Manage & Analyse Applicants',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: _kTxtSec,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Post Job button in appbar
            GestureDetector(
              onTap: () => context.go('/post-job'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kPrimary, _kAccent]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Post',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WRAPPER  (search, filters, grid)
// ─────────────────────────────────────────────────────────────────────────────
class Job_Applicant_Wrapper extends StatefulWidget {
  final List<String> jobIds;
  final String snapshotVersion;
  const Job_Applicant_Wrapper({
    super.key,
    required this.jobIds,
    required this.snapshotVersion,
  });

  @override
  State<Job_Applicant_Wrapper> createState() => _Job_Applicant_WrapperState();
}

class _Job_Applicant_WrapperState extends State<Job_Applicant_Wrapper>
    with TickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _debounce;

  List<String> _filteredIds = [];
  String _selCompany = '';
  String _selLocation = '';
  String _selJobType = '';
  String _selSort = 'newest';
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _cache = {};

  @override
  void initState() {
    super.initState();
    _filteredIds = List.from(widget.jobIds);
    _searchCtrl.addListener(_onSearch);
    _loadMetadata();
  }

  @override
  void didUpdateWidget(covariant Job_Applicant_Wrapper old) {
    super.didUpdateWidget(old);
    if (!_listEq(old.jobIds, widget.jobIds) ||
        old.snapshotVersion != widget.snapshotVersion) {
      _loadMetadata();
    }
  }

  Future<void> _loadMetadata() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await Future.wait(
        widget.jobIds.map((id) async {
          final doc = await FirebaseFirestore.instance
              .collection('Posted_jobs_public')
              .doc(id)
              .get();

          if (doc.exists) {
            final d = doc.data()!;
            _cache[id] = {
              'title': d['title'] ?? '',
              'company': d['company'] ?? '',
              'location': d['location'] ?? '',
              'nature': d['nature'] ?? '',
              'description': d['description'] ?? '',
              'skills': (d['skills'] as List?)?.cast<String>() ?? [],
              'benefits': (d['benefits'] as List?)?.cast<String>() ?? [],
              'timestamp': d['timestamp'],
              'applicationCount': d['applicationCount'] ?? 0,
            };
          }
        }),
      );

      if (!mounted) return;
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading metadata: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _applyFilters);
  }

  void _applyFilters() {
    if (!mounted) return;

    final q = _searchCtrl.text.toLowerCase();

    setState(() {
      _filteredIds = widget.jobIds.where((id) {
        final m = _cache[id];
        if (m == null) return false;

        if (q.isNotEmpty) {
          final txt =
              '${m['title']} ${m['company']} ${m['description']} ${(m['skills'] as List).join(' ')}'
                  .toLowerCase();
          if (!txt.contains(q)) return false;
        }

        if (_selCompany.isNotEmpty && m['company'] != _selCompany) return false;
        if (_selLocation.isNotEmpty && m['location'] != _selLocation) {
          return false;
        }
        if (_selJobType.isNotEmpty && m['nature'] != _selJobType) return false;

        return true;
      }).toList();

      _sortIds();
    });
  }

  void _sortIds() {
    _filteredIds.sort((a, b) {
      final ma = _cache[a];
      final mb = _cache[b];
      if (ma == null || mb == null) return 0;
      switch (_selSort) {
        case 'newest':
          final ta = (ma['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          final tb = (mb['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          return tb.compareTo(ta);
        case 'oldest':
          final ta = (ma['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          final tb = (mb['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
          return ta.compareTo(tb);
        case 'company':
          return (ma['company'] as String).compareTo(mb['company'] as String);
        case 'applications':
          return (mb['applicationCount'] as int).compareTo(
            ma['applicationCount'] as int,
          );
        default:
          return 0;
      }
    });
  }

  List<String> _unique(String field) =>
      _cache.values
          .map((m) => m[field] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: CustomScrollView(
        controller: _scrollCtrl,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildCommandBar(isMobile)),
          _buildGrid(w, isMobile),
        ],
      ),
    );
  }

  // ── Command bar ─────────────────────────────────────────────────────────────
  Widget _buildCommandBar(bool isMobile) {
    return Container(
      color: Color(0xFFFAFAFA),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        isMobile ? 12 : 16,
        isMobile ? 12 : 24,
        isMobile ? 10 : 16,
      ),
      child: isMobile ? _mobileBar() : _desktopBar(),
    );
  }

  // Mobile: search + filter button row
  Widget _mobileBar() {
    final hasFilter =
        _selCompany.isNotEmpty ||
        _selLocation.isNotEmpty ||
        _selJobType.isNotEmpty ||
        _selSort != 'newest';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _searchField(true)),
            const SizedBox(width: 8),
            // Filter icon button
            GestureDetector(
              onTap: _showMobileFilters,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: hasFilter
                      ? _kPrimary.withValues(alpha: 0.1)
                      : _kSurfaceEl,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasFilter ? _kPrimary : _kBorder,
                    width: hasFilter ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: hasFilter ? _kPrimary : _kTxtSec,
                      ),
                    ),
                    if (hasFilter)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _kAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Active filter chips (compact)
        if (hasFilter)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_selCompany.isNotEmpty)
                  _activeChip(_selCompany, () {
                    setState(() => _selCompany = '');
                    _applyFilters();
                  }),
                if (_selLocation.isNotEmpty)
                  _activeChip(_selLocation, () {
                    setState(() => _selLocation = '');
                    _applyFilters();
                  }),
                if (_selJobType.isNotEmpty)
                  _activeChip(_selJobType, () {
                    setState(() => _selJobType = '');
                    _applyFilters();
                  }),
                if (_selSort != 'newest')
                  _activeChip(_sortLabel(_selSort), () {
                    setState(() => _selSort = 'newest');
                    _applyFilters();
                  }),
              ],
            ),
          ),
        // Count pill
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${_filteredIds.length} position${_filteredIds.length == 1 ? '' : 's'}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: _kTxtSec,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Desktop: full inline filter row
  Widget _desktopBar() {
    final companies = _unique('company');
    final locations = _unique('location');
    return Row(
      children: [
        Expanded(flex: 3, child: _searchField(false)),
        const SizedBox(width: 12),
        _statBadge('${_filteredIds.length}', 'Jobs'),
        const SizedBox(width: 12),
        _filterChip('Company', _selCompany, companies, Icons.business, (v) {
          setState(() => _selCompany = v);
          _applyFilters();
        }),
        const SizedBox(width: 8),
        _filterChip('Location', _selLocation, locations, Icons.location_on, (
          v,
        ) {
          setState(() => _selLocation = v);
          _applyFilters();
        }),
        const SizedBox(width: 8),
        _sortChip(),
      ],
    );
  }

  // ── Search field ──────────────────────────────────────────────────────────
  Widget _searchField(bool isMobile) {
    return TextField(
      controller: _searchCtrl,
      style: GoogleFonts.plusJakartaSans(
        fontSize: isMobile ? 13 : 14,
        color: _kTxtPrimary,
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: _kTxtSec, size: 18),
        hintText: 'Search positions…',
        hintStyle: GoogleFonts.plusJakartaSans(
          color: _kTxtTert,
          fontSize: isMobile ? 12 : 13,
        ),
        filled: true,
        fillColor: _kSurfaceEl,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isMobile ? 10 : 11,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      ),
    );
  }

  // ── Desktop filter chip ───────────────────────────────────────────────────
  Widget _filterChip(
    String label,
    String value,
    List<String> opts,
    IconData icon,
    void Function(String) onSel,
  ) {
    final active = value.isNotEmpty;
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      onSelected: onSel,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: '',
          child: Text(
            'All $label',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
        ),
        ...opts.map(
          (o) => PopupMenuItem(
            value: o,
            child: Text(o, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
          ),
        ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? _kPrimary.withValues(alpha: 0.08) : _kSurfaceEl,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? _kPrimary : _kBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: active ? _kPrimary : _kTxtSec),
            const SizedBox(width: 6),
            Text(
              active ? value : label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? _kPrimary : _kTxtSec,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: active ? _kPrimary : _kTxtSec,
            ),
          ],
        ),
      ),
    );
  }

  // ── Desktop sort chip ─────────────────────────────────────────────────────
  Widget _sortChip() {
    return PopupMenuButton<String>(
      initialValue: _selSort,
      offset: const Offset(0, 44),
      onSelected: (v) {
        setState(() => _selSort = v);
        _applyFilters();
      },
      itemBuilder: (_) => [
        _sortItem('newest', 'Newest First'),
        _sortItem('oldest', 'Oldest First'),
        _sortItem('company', 'Company A–Z'),
        _sortItem('applications', 'Most Applications'),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _kSurfaceEl,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 16, color: _kTxtSec),
            const SizedBox(width: 6),
            Text(
              'Sort',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kTxtSec,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _sortItem(String val, String lbl) {
    final sel = _selSort == val;
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          if (sel) ...[
            const Icon(Icons.check, size: 16, color: _kPrimary),
            const SizedBox(width: 8),
          ],
          Text(
            lbl,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              color: sel ? _kPrimary : _kTxtPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat badge ────────────────────────────────────────────────────────────
  Widget _statBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kSurfaceEl,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_airport_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kTxtPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _kTxtSec),
          ),
        ],
      ),
    );
  }

  // ── Active filter chip (mobile) ───────────────────────────────────────────
  Widget _activeChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  // ── Mobile filter bottom sheet ────────────────────────────────────────────
  void _showMobileFilters() {
    final companies = _unique('company');
    final locations = _unique('location');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          // local copies so user can "Apply" or "Cancel"
          String lComp = _selCompany;
          String lLoc = _selLocation;
          String lType = _selJobType;
          String lSort = _selSort;

          return Container(
            decoration: const BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: StatefulBuilder(
              builder: (ctx2, setS2) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _kBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kTxtPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setS2(() {
                            lComp = '';
                            lLoc = '';
                            lType = '';
                            lSort = 'newest';
                          });
                        },
                        child: Text(
                          'Clear all',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: _kAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Company
                  _sheetSection(
                    'Company',
                    companies,
                    lComp,
                    (v) => setS2(() => lComp = v),
                  ),
                  const SizedBox(height: 14),

                  // Location
                  _sheetSection(
                    'Location',
                    locations,
                    lLoc,
                    (v) => setS2(() => lLoc = v),
                  ),
                  const SizedBox(height: 14),

                  // Sort
                  Text(
                    'Sort by',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kTxtSec,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        {
                          'newest': 'Newest',
                          'oldest': 'Oldest',
                          'company': 'Company A–Z',
                          'applications': 'Most Applied',
                        }.entries.map((e) {
                          final sel = lSort == e.key;
                          return GestureDetector(
                            onTap: () => setS2(() => lSort = e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? _kPrimary.withValues(alpha: 0.1)
                                    : _kSurfaceEl,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel ? _kPrimary : _kBorder,
                                  width: sel ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                e.value,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: sel
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: sel ? _kPrimary : _kTxtSec,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _selCompany = lComp;
                          _selLocation = lLoc;
                          _selJobType = lType;
                          _selSort = lSort;
                        });
                        _applyFilters();
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetSection(
    String label,
    List<String> opts,
    String current,
    void Function(String) onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kTxtSec,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // "All" pill
            GestureDetector(
              onTap: () => onTap(''),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: current.isEmpty
                      ? _kPrimary.withValues(alpha: 0.1)
                      : _kSurfaceEl,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: current.isEmpty ? _kPrimary : _kBorder,
                    width: current.isEmpty ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  'All',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: current.isEmpty
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: current.isEmpty ? _kPrimary : _kTxtSec,
                  ),
                ),
              ),
            ),
            ...opts.map((o) {
              final sel = current == o;
              return GestureDetector(
                onTap: () => onTap(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? _kPrimary.withValues(alpha: 0.1) : _kSurfaceEl,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? _kPrimary : _kBorder,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    o,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                      color: sel ? _kPrimary : _kTxtSec,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  // ── Grid ─────────────────────────────────────────────────────────────────
  Widget _buildGrid(double w, bool isMobile) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }
    if (_filteredIds.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 52,
                  color: _kTxtSec,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No jobs found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _kTxtPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Adjust your filters or post a new position',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _kTxtSec,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Responsive column count & card height
    final cols = isMobile ? 1 : (w < 1100 ? 2 : 3);
    // Card height: mobile needs more room since items stack differently
    final cardH = isMobile ? 360.0 : 340.0;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 10 : 24,
        0,
        isMobile ? 10 : 24,
        24,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: isMobile ? 10 : 16,
          mainAxisSpacing: isMobile ? 10 : 16,
          mainAxisExtent: cardH,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => Job_Cards(jobId: _filteredIds[i]),
          childCount: _filteredIds.length,
        ),
      ),
    );
  }

  String _sortLabel(String s) {
    switch (s) {
      case 'oldest':
        return 'Oldest';
      case 'company':
        return 'Company A–Z';
      case 'applications':
        return 'Most Applied';
      default:
        return 'Newest';
    }
  }

  bool _listEq<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOB CARD  (overflow-safe, responsive padding)
// ─────────────────────────────────────────────────────────────────────────────
class Job_Cards extends StatefulWidget {
  final String jobId;
  const Job_Cards({super.key, required this.jobId});

  @override
  State<Job_Cards> createState() => _Job_CardsState();
}

class _Job_CardsState extends State<Job_Cards>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  Map<String, dynamic>? _cachedJob;
  String? _cachedKey;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.975,
    ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _process(DocumentSnapshot doc) {
    if (!doc.exists) return _empty();
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final appCount = d['applicationCount'] ?? 0;
    final ts = d['timestamp'];
    final key = '${doc.id}_${ts}_$appCount';
    if (_cachedKey == key && _cachedJob != null) return _cachedJob!;

    _cachedJob = {
      'id': doc.id,
      'title': d['title']?.toString() ?? 'Untitled Position',
      'company': d['company']?.toString() ?? 'Unknown Unit',
      'location': d['location']?.toString() ?? 'Remote',
      'description': d['description']?.toString() ?? '',
      'salary': d['salary'],
      'nature': d['nature']?.toString() ?? 'Full-time',
      'experience': d['experience']?.toString() ?? 'Not specified',
      'logoUrl': d['logoUrl']?.toString(),
      'skills': (d['skills'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      'timestamp': ts,
      'applicationCount': appCount is int
          ? appCount
          : (int.tryParse(appCount.toString()) ?? 0),
    };
    _cachedKey = key;
    return _cachedJob!;
  }

  Map<String, dynamic> _empty() => {
    'id': widget.jobId,
    'title': 'Untitled Position',
    'company': 'Unknown Unit',
    'location': 'Remote',
    'description': '',
    'salary': null,
    'nature': 'Full-time',
    'experience': 'Not specified',
    'logoUrl': null,
    'skills': <String>[],
    'timestamp': null,
    'applicationCount': 0,
  };

  String _ago(Timestamp? ts) =>
      ts == null ? '' : timeago.format(ts.toDate(), locale: 'en_short');

  String _sal(dynamic s) {
    if (s == null) return 'Not specified';
    if (s is num) return '\$${NumberFormat.compact().format(s)}';
    return s.toString();
  }

  void _details() {
    _scaleCtrl.forward().then((_) => _scaleCtrl.reverse());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 380),
      ),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: JobDetailModal_recruiter(jobId: widget.jobId),
      ),
    );
  }

  void _applicants() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 0),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Expanded(child: ApplicantsScreen(jobId: widget.jobId)),
            ],
          ),
        ),
      );
      return;
    }

    // Desktop/Web Transition
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (ctx, anim, _) => FadeTransition(
          opacity: anim,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: AnimatedBuilder(
                animation: anim,
                builder: (_, child) => Transform.scale(
                  scale: Tween(begin: 0.92, end: 1.0)
                      .animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        ),
                      )
                      .value,
                  child: child,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(ctx).size.width * 0.88,
                    maxHeight: MediaQuery.of(ctx).size.height * 0.92,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Material(
                      color: _kSurface,
                      elevation: 20,
                      shadowColor: Colors.black.withValues(alpha: 0.35),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _kTxtTert.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: GestureDetector(
                                onTap: () => Navigator.of(ctx).pop(),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: _kSurfaceEl,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _kBorder),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: _kTxtSec,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ApplicantsScreen(jobId: widget.jobId),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Posted_jobs_public')
          .doc(widget.jobId)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return _loadingCard();
        }
        if (snap.hasError) return _errorCard();
        return _card(_process(snap.data!));
      },
    );
  }

  Widget _loadingCard() => Container(
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kBorderLt),
    ),
    child: const Center(
      child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
    ),
  );

  Widget _errorCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 28),
        const SizedBox(height: 6),
        Text(
          'Failed to load',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _kTxtSec),
        ),
      ],
    ),
  );

  Widget _card(Map<String, dynamic> job) {
    final title = job['title'] as String;
    final company = job['company'] as String;
    final location = job['location'] as String;
    final desc = job['description'] as String;
    final skills = job['skills'] as List<String>;
    final logoUrl = job['logoUrl'] as String?;
    final ago = _ago(job['timestamp'] as Timestamp?);
    final salary = _sal(job['salary']);
    final nature = job['nature'] as String;
    final exp = job['experience'] as String;
    final appCount = job['applicationCount'] as int;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
          _scaleCtrl.forward();
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          _scaleCtrl.reverse();
        },
        onTapCancel: () {
          setState(() => _pressed = false);
          _scaleCtrl.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnim,
          builder: (_, child) =>
              Transform.scale(scale: _scaleAnim.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovered
                    ? _kPrimary.withValues(alpha: 0.28)
                    : _kBorderLt,
                width: _hovered ? 1.5 : 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                        spreadRadius: -4,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _kPrimary.withValues(alpha: 0.03),
                          _kAccent.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo
                            Hero(
                              tag: 'logo-${job['id']}',
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _kSurfaceEl,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: _kBorder,
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: logoUrl != null && logoUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: logoUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) => const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: _kPrimary,
                                            ),
                                          ),
                                          errorWidget: (_, _, _) =>
                                              _logoFallback(company),
                                        )
                                      : _logoFallback(company),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Title + company
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _kTxtPrimary,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _kPrimary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      company,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _kPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Time badge
                            if (ago.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _kSuccess.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _kSuccess.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 10,
                                      color: _kSuccess,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      ago,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: _kSuccess,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Meta chips row — scrollable to prevent overflow
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _meta(Icons.location_on_outlined, location),
                              const SizedBox(width: 6),
                              _meta(Icons.work_outline, nature),
                              const SizedBox(width: 6),
                              _meta(Icons.attach_money, salary),
                              const SizedBox(width: 6),
                              _meta(Icons.trending_up, exp),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Description ────────────────────────────────────────
                  if (desc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: Text(
                        desc,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: _kTxtSec,
                          height: 1.55,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // ── Skills ─────────────────────────────────────────────
                  if (skills.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Text(
                        'Skills',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _kTxtTert,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 5, 14, 0),
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          ...skills
                              .take(4)
                              .map(
                                (s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kSurfaceEl,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _kBorder),
                                  ),
                                  child: Text(
                                    s,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _kTxtSec,
                                    ),
                                  ),
                                ),
                              ),
                          if (skills.length > 4)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _kAccent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _kAccent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                '+${skills.length - 4}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _kAccent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // ── Footer ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: const BoxDecoration(
                      color: _kSurfaceEl,
                      border: Border(top: BorderSide(color: _kBorderLt)),
                    ),
                    child: Row(
                      children: [
                        // Applicants count button
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _applicants,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: appCount > 0
                                    ? _kAccent.withValues(alpha: 0.08)
                                    : _kSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: appCount > 0
                                      ? _kAccent.withValues(alpha: 0.25)
                                      : _kBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.group_outlined,
                                    size: 16,
                                    color: appCount > 0 ? _kAccent : _kTxtTert,
                                  ),
                                  const SizedBox(width: 5),

                                  Text(
                                    '$appCount',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: appCount > 0
                                          ? _kAccent
                                          : _kTxtTert,
                                    ),
                                  ),
                                  const SizedBox(width: 2),

                                  Text(
                                    'Applicant(s)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _kAccent,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // View details button
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _details,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _hovered
                                      ? [const Color(0xFF2E4A6F), _kAccent]
                                      : [_kPrimary, const Color(0xFF2E4A6F)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kPrimary.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.visibility_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'View Job',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    transform: Matrix4.translationValues(
                                      _hovered ? 3 : 0,
                                      0,
                                      0,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }

  Widget _logoFallback(String company) => Container(
    color: _kSurfaceEl,
    child: Center(
      child: Text(
        company.isNotEmpty ? company[0].toUpperCase() : 'C',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      ),
    ),
  );

  Widget _meta(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _kBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: _kTxtTert),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 90),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _kTxtSec,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY / ERROR WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_outline_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Positions Available',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  const _ErrorWidget({required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
