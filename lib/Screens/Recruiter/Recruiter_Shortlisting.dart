import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_portal/Screens/Recruiter/R_Top_Bar.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../Job_Seeker/job_seeker_provider.dart';
import 'View_Shortlisted.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
class _T {
  static const primary      = Color(0xFF2563EB);
  static const primaryLight = Color(0xFFEFF6FF);
  static const textPri      = Color(0xFF0D1117);
  static const textSec      = Color(0xFF57606A);
  static const textTert     = Color(0xFF8B949E);
  static const bg           = Color(0xFFF6F8FA);
  static const white        = Color(0xFFFFFFFF);
  static const border       = Color(0xFFD0D7DE);
  static const success      = Color(0xFF1A7F37);
  static const warning      = Color(0xFFBF8700);
  static const red          = Color(0xFFCF222E);

  static TextStyle label({double fs = 11, Color? c, FontWeight fw = FontWeight.w500}) =>
      GoogleFonts.ibmPlexSans(fontSize: fs, fontWeight: fw, color: c ?? textSec);
  static TextStyle head({double fs = 14, Color? c}) =>
      GoogleFonts.ibmPlexSans(fontSize: fs, fontWeight: FontWeight.w700, color: c ?? textPri);
  static TextStyle body({double fs = 13, Color? c}) =>
      GoogleFonts.ibmPlexSans(fontSize: fs, color: c ?? textPri, height: 1.5);
}

// ─── Layout InheritedWidget (computed once at root, no MediaQuery per child) ─
enum _Layout { mobile, tablet, desktop }

class _LD extends InheritedWidget {
  final _Layout layout;
  final double width;
  const _LD({required this.layout, required this.width, required super.child});

  static _LD of(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<_LD>()!;
  static bool isMobile(BuildContext ctx)  => of(ctx).layout == _Layout.mobile;
  static bool isDesktop(BuildContext ctx) => of(ctx).layout == _Layout.desktop;

  @override
  bool updateShouldNotify(_LD old) => old.layout != layout;
}

// ─── Safe Timestamp parser ─────────────────────────────────────────────────
DateTime _tsToDate(dynamic raw) {
  if (raw == null) return DateTime(0);
  if (raw is DateTime) return raw;
  if (raw is Timestamp) return raw.toDate();
  return DateTime(0);
}

// ═════════════════════════════════════════════════════════════════════════════
// ROOT SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class Shortlisting extends StatefulWidget {
  const Shortlisting({super.key});
  @override
  State<Shortlisting> createState() => _ShortlistingState();
}

class _ShortlistingState extends State<Shortlisting>
    with SingleTickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _fadeCtrl = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Single LayoutBuilder drives _LD — no MediaQuery in children
    return LayoutBuilder(builder: (ctx, bc) {
      final w = bc.maxWidth;
      final _Layout layout;
      if (w < 600)       layout = _Layout.mobile;
      else if (w < 960)  layout = _Layout.tablet;
      else               layout = _Layout.desktop;

      return _LD(
        layout: layout,
        width: w,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor:Colors.white,
          drawer: layout == _Layout.mobile
              ? Drawer(child: RecruiterSidebar(activeIndex: 3, isDrawer: true))
              : null,
          body: Row(children: [
            if (layout != _Layout.mobile)
              const RecruiterSidebar(activeIndex: 3),
            Expanded(
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: Column(children: [
                  // Top bar
                  RepaintBoundary(
                    child: layout == _Layout.mobile
                        ? _MobileTopBar(
                        onMenu: () =>
                            _scaffoldKey.currentState?.openDrawer())
                        : const _DesktopHeader(),
                  ),
                  // Stream content
                  Expanded(
                    child: Consumer<JobSeekerProvider>(
                      builder: (_, provider, __) =>
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: provider.allJobsStream,
                            builder: (_, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: _T.primary, strokeWidth: 2),
                                );
                              }
                              if (snap.hasError) {
                                return _ErrorState(
                                    error: snap.error.toString());
                              }
                              final jobs = snap.data ?? [];
                              if (jobs.isEmpty) return const _EmptyJobsState();
                              return _ShortlistingDashboard(jobs: jobs);
                            },
                          ),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TOP BARS
// ═════════════════════════════════════════════════════════════════════════════
class _MobileTopBar extends StatelessWidget {
  final VoidCallback onMenu;
  const _MobileTopBar({required this.onMenu});

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.border))),
    child: Row(children: [
      IconButton(
          icon: const Icon(Icons.menu_rounded, size: 22, color: _T.textSec),
          onPressed: onMenu),
      const SizedBox(width: 4),
      const _HeaderIconBox(),
      const SizedBox(width: 10),
      Text('Shortlisting Dashboard', style: _T.head(fs: 15)),
    ]),
  );
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    color: _T.white,
    child: Row(children: [
      const _HeaderIconBox(size: 22),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Shortlisting Dashboard', style: _T.head(fs: 17)),
          Text('Review & Manage Shortlisted Candidates',
              style: _T.label(c: _T.textSec),
              overflow: TextOverflow.ellipsis),
        ],
      )),
    ]),
  );
}

class _HeaderIconBox extends StatelessWidget {
  final double size;
  const _HeaderIconBox({this.size = 18});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: _T.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.recent_actors_outlined, size: size, color: _T.primary),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// DASHBOARD (filter state lives here, isolated from root)
// ═════════════════════════════════════════════════════════════════════════════
class _ShortlistingDashboard extends StatefulWidget {
  final List<Map<String, dynamic>> jobs;
  const _ShortlistingDashboard({required this.jobs});

  @override
  State<_ShortlistingDashboard> createState() => _ShortlistingDashboardState();
}

class _ShortlistingDashboardState extends State<_ShortlistingDashboard> {
  final _searchCtrl   = TextEditingController();
  final _scrollCtrl   = ScrollController();
  Timer? _debounce;

  List<Map<String, dynamic>> _filtered = [];
  String? _selectedJobId;

  // Filter state
  String _company  = '';
  String _location = '';
  String _jobType  = '';
  String _sort     = 'newest';

  // Mobile: show detail panel over list - DEPRECATED in favor of bottom sheet
  // bool _showDetail = false;

  @override
  void initState() {
    super.initState();
    _filtered = List.from(widget.jobs);
    _applyFilters();
    if (_filtered.isNotEmpty) _selectedJobId = _filtered.first['id'] as String?;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void didUpdateWidget(_ShortlistingDashboard old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.jobs, widget.jobs)) {
      _applyFilters();
      if (_selectedJobId == null && _filtered.isNotEmpty) {
        setState(() => _selectedJobId = _filtered.first['id'] as String?);
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _applyFilters);
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.jobs.where((job) {
        if (q.isNotEmpty) {
          final hay =
          '${job['title']} ${job['company']} ${job['description']} '
              '${(job['skills'] as List?)?.join(' ') ?? ''}'
              .toLowerCase();
          if (!hay.contains(q)) return false;
        }
        if (_company.isNotEmpty  && job['company']  != _company)  return false;
        if (_location.isNotEmpty && job['location'] != _location) return false;
        if (_jobType.isNotEmpty  && job['nature']   != _jobType)  return false;
        return true;
      }).toList();
      _sortList();
    });
  }

  void _sortList() {
    switch (_sort) {
      case 'newest':
        _filtered.sort((a, b) =>
            _tsToDate(b['timestamp']).compareTo(_tsToDate(a['timestamp'])));
        break;
      case 'oldest':
        _filtered.sort((a, b) =>
            _tsToDate(a['timestamp']).compareTo(_tsToDate(b['timestamp'])));
        break;
      case 'company':
        _filtered.sort((a, b) =>
            (a['company'] ?? '').compareTo(b['company'] ?? ''));
        break;
    }
  }

  List<String> _unique(String field) => widget.jobs
      .map((j) => j[field] as String? ?? '')
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  void _selectJob(String? jobId) {
    setState(() => _selectedJobId = jobId);
    if (_LD.isMobile(context)) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _T.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: view_shortlisted(
                  key: ValueKey('sheet-$jobId'),
                  jobId: jobId,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _LD.isMobile(context);

    if (_filtered.isEmpty) return _NoResultsState(onClear: _clearFilters);

    if (isMobile) return _buildMobileLayout();
    return _buildDesktopLayout();
  }

  void _clearFilters() => setState(() {
    _company = _location = _jobType = '';
    _searchCtrl.clear();
    _applyFilters();
  });

  // ── MOBILE: stack-based back/forward navigation between list and detail ──
  Widget _buildMobileLayout() {
    return Column(children: [
      // Filter bar always visible
      RepaintBoundary(child: _FilterBar(
        searchCtrl: _searchCtrl,
        companies: _unique('company'),
        locations: _unique('location'),
        types:     _unique('nature'),
        company:   _company,  location: _location,  jobType: _jobType,
        sort:      _sort,
        onCompany:  (v) { setState(() => _company  = v); _applyFilters(); },
        onLocation: (v) { setState(() => _location = v); _applyFilters(); },
        onJobType:  (v) { setState(() => _jobType  = v); _applyFilters(); },
        onSort:     (v) { setState(() => _sort     = v); _applyFilters(); },
      )),
      Expanded(
    child: Padding(
    padding: const EdgeInsets.all(10),
          child: _JobListPanel(
            key: const ValueKey('job-list'),
            jobs: _filtered,
            selectedJobId: _selectedJobId,
            scrollCtrl: _scrollCtrl,
            onJobTap: _selectJob,
          ),
    ),
      ),
    ]);
  }

  // ── DESKTOP: side-by-side ─────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Column(children: [
      RepaintBoundary(child: _FilterBar(
        searchCtrl: _searchCtrl,
        companies: _unique('company'),
        locations: _unique('location'),
        types:     _unique('nature'),
        company:   _company,  location: _location,  jobType: _jobType,
        sort:      _sort,
        onCompany:  (v) { setState(() => _company  = v); _applyFilters(); },
        onLocation: (v) { setState(() => _location = v); _applyFilters(); },
        onJobType:  (v) { setState(() => _jobType  = v); _applyFilters(); },
        onSort:     (v) { setState(() => _sort     = v); _applyFilters(); },
      )),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Left — job list
            SizedBox(
              width: 360,
              child: RepaintBoundary(
                child: _JobListPanel(
                  jobs: _filtered,
                  selectedJobId: _selectedJobId,
                  scrollCtrl: _scrollCtrl,
                  onJobTap: _selectJob,
                  showCount: true,
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Right — applicants detail
            Expanded(
              child: RepaintBoundary(
                child: _selectedJobId != null
                    ? view_shortlisted(
                  key: ValueKey(_selectedJobId),
                  jobId: _selectedJobId,
                )
                    : const _EmptyApplicantsState(),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// JOB LIST PANEL  (stateless → stable identity, no unnecessary rebuilds)
// ═════════════════════════════════════════════════════════════════════════════
class _JobListPanel extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  final String? selectedJobId;
  final ScrollController scrollCtrl;
  final ValueChanged<String?> onJobTap;
  final bool showCount;

  const _JobListPanel({
    super.key,
    required this.jobs,
    required this.selectedJobId,
    required this.scrollCtrl,
    required this.onJobTap,
    this.showCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (showCount)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(children: [
            const Icon(Icons.work_outline_rounded, size: 17, color: _T.textPri),
            const SizedBox(width: 7),
            Text('Positions (${jobs.length})', style: _T.head(fs: 14)),
          ]),
        ),
      Expanded(
        child: ListView.separated(
          controller: scrollCtrl,
          padding: EdgeInsets.zero,
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final job = jobs[i];
            final id  = job['id'] as String?;
            return _JobCard(
              key: ValueKey(id),
              jobData: job,
              isSelected: id == selectedJobId,
              onTap: () => onJobTap(id),
            );
          },
        ),
      ),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FILTER BAR
// ═════════════════════════════════════════════════════════════════════════════
class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<String> companies, locations, types;
  final String company, location, jobType, sort;
  final ValueChanged<String> onCompany, onLocation, onJobType, onSort;

  const _FilterBar({
    required this.searchCtrl,
    required this.companies, required this.locations, required this.types,
    required this.company,   required this.location,  required this.jobType,
    required this.sort,
    required this.onCompany, required this.onLocation,
    required this.onJobType, required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _LD.isMobile(context);
    final h = isMobile ? 40.0 : 42.0;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical:   isMobile ? 10 : 14),
      decoration: const BoxDecoration(
          color: _T.white,
          border: Border(bottom: BorderSide(color: _T.border))),
      child: isMobile
          ? Column(children: [
        _SearchField(ctrl: searchCtrl, height: h),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _dropdowns(h)),
        ),
      ])
          : Row(children: [
        Expanded(flex: 3, child: _SearchField(ctrl: searchCtrl, height: h)),
        const SizedBox(width: 10),
        ..._dropdowns(h),
      ]),
    );
  }

  List<Widget> _dropdowns(double h) => [
    if (companies.isNotEmpty) ...[
      _FilterDropdown(
        label: 'Company', value: company, items: companies,
        icon: Icons.business_rounded, height: h, onChanged: onCompany,
      ),
      const SizedBox(width: 8),
    ],
    if (locations.isNotEmpty) ...[
      _FilterDropdown(
        label: 'Location', value: location, items: locations,
        icon: Icons.location_on_rounded, height: h, onChanged: onLocation,
      ),
      const SizedBox(width: 8),
    ],
    if (types.isNotEmpty) ...[
      _FilterDropdown(
        label: 'Type', value: jobType, items: types,
        icon: Icons.work_outline_rounded, height: h, onChanged: onJobType,
      ),
      const SizedBox(width: 8),
    ],
    _SortButton(value: sort, height: h, onChanged: onSort),
  ];
}

class _SearchField extends StatelessWidget {
  final TextEditingController ctrl;
  final double height;
  const _SearchField({required this.ctrl, required this.height});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: TextField(
      controller: ctrl,
      style: _T.body(fs: 13),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded,
            color: _T.textSec, size: 18),
        hintText: 'Search positions, companies, skills…',
        hintStyle: _T.label(fs: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _T.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _T.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        filled: true, fillColor: _T.bg,
        isDense: true,
      ),
    ),
  );
}

class _FilterDropdown extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final IconData icon;
  final double height;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label, required this.value, required this.items,
    required this.icon,  required this.height, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = value.isNotEmpty;
    return SizedBox(
      height: height,
      child: PopupMenuButton<String>(
        onSelected: (v) { onChanged(v); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? _T.primaryLight : _T.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? _T.primary : _T.border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15,
                color: active ? _T.primary : _T.textSec),
            const SizedBox(width: 6),
            Text(active ? value : label,
                style: _T.label(fs: 12,
                    c: active ? _T.primary : _T.textSec,
                    fw: FontWeight.w600)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 15,
                color: active ? _T.primary : _T.textSec),
          ]),
        ),
        itemBuilder: (_) => [
          _menuItem('', 'All'),
          for (final i in items) _menuItem(i, i),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String v, String t) =>
      PopupMenuItem(value: v, child: Text(t, style: _T.body(fs: 13)));
}

class _SortButton extends StatelessWidget {
  final String value;
  final double height;
  final ValueChanged<String> onChanged;
  const _SortButton({required this.value, required this.height, required this.onChanged});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _T.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _T.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.sort_rounded, size: 15, color: _T.textSec),
          const SizedBox(width: 6),
          Text('Sort', style: _T.label(fs: 12, fw: FontWeight.w600)),
        ]),
      ),
      itemBuilder: (_) => [
        _item('newest', 'Newest First'),
        _item('oldest', 'Oldest First'),
        _item('company', 'Company A→Z'),
      ],
    ),
  );

  PopupMenuItem<String> _item(String v, String t) =>
      PopupMenuItem(value: v, child: Text(t, style: _T.body(fs: 13)));
}

// ═════════════════════════════════════════════════════════════════════════════
// JOB CARD  (hover state isolated — only this card repaints on hover)
// ═════════════════════════════════════════════════════════════════════════════
class _JobCard extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final bool isSelected;
  final VoidCallback onTap;
  const _JobCard({super.key, required this.jobData,
    required this.isSelected, required this.onTap});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final job      = widget.jobData;
    final title    = job['title']    as String? ?? 'No Title';
    final company  = job['company']  as String? ?? 'Unknown';
    final location = job['location'] as String? ?? 'Remote';
    final nature   = job['nature']   as String? ?? '';
    final skills   = (job['skills']  as List?)?.cast<String>() ?? [];
    final logoUrl  = job['logoUrl']  as String?;
    final ts       = job['timestamp'] as Timestamp?;
    final ago      = ts != null ? timeago.format(ts.toDate(), locale: 'en_short') : '';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
              0, _hovered && !widget.isSelected ? -3 : 0, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? _T.primary.withOpacity(0.05)
                : _T.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? _T.primary
                  : _hovered
                  ? _T.primary.withOpacity(0.35)
                  : _T.border,
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: _hovered && !widget.isSelected
                ? [const BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10, offset: Offset(0, 4))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _LogoBox(logoUrl: logoUrl),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(title,
                          style: _T.head(fs: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                      if (ago.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _TimeBadge(ago),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    Text(company, style: _T.label(fs: 12, fw: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                )),
              ]),
              const SizedBox(height: 12),
              // ── Meta row
              Row(children: [
                _MetaChip(Icons.location_on_outlined, location),
                if (nature.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  _MetaChip(Icons.work_outline_rounded, nature),
                ],
                if (widget.isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: _T.primary, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: _T.primary.withOpacity(0.35),
                          blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: const Icon(Icons.check, size: 14, color: _T.white),
                  ),
                ],
              ]),
              // ── Skills
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: _T.border),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: [
                    for (final s in skills.take(3)) _SkillPill(s),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MICRO WIDGETS
// ═════════════════════════════════════════════════════════════════════════════
class _LogoBox extends StatelessWidget {
  final String? logoUrl;
  const _LogoBox({this.logoUrl});

  @override
  Widget build(BuildContext context) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
      color: _T.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: _T.border),
      boxShadow: const [BoxShadow(
          color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: logoUrl != null && logoUrl!.isNotEmpty
          ? CachedNetworkImage(
        imageUrl: logoUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _T.primary)),
        errorWidget: (_, __, ___) => const Icon(
            Icons.business_rounded, color: _T.textSec, size: 22),
      )
          : const Icon(Icons.business_rounded,
          color: _T.textSec, size: 22),
    ),
  );
}

class _TimeBadge extends StatelessWidget {
  final String time;
  const _TimeBadge(this.time);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
        color: _T.bg, borderRadius: BorderRadius.circular(5)),
    child: Text(time, style: _T.label(fs: 10)),
  );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: _T.textSec),
      const SizedBox(width: 4),
      Flexible(child: Text(text, style: _T.label(fs: 11),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
    ],
  );
}

class _SkillPill extends StatelessWidget {
  final String label;
  const _SkillPill(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
        color: _T.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(5)),
    child: Text(label, style: _T.label(fs: 11, c: _T.primary, fw: FontWeight.w600)),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY / ERROR STATES
// ═════════════════════════════════════════════════════════════════════════════
class _EmptyApplicantsState extends StatelessWidget {
  const _EmptyApplicantsState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: _T.primaryLight, shape: BoxShape.circle),
        child: const Icon(Icons.people_alt_rounded,
            size: 64, color: _T.primary),
      ),
      const SizedBox(height: 20),
      Text('Select a Job Position', style: _T.head(fs: 20)),
      const SizedBox(height: 6),
      Text('Tap any job card to view its applicants',
          style: _T.label(fs: 13)),
    ]),
  );
}

class _NoResultsState extends StatelessWidget {
  final VoidCallback onClear;
  const _NoResultsState({required this.onClear});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
            color: _T.primaryLight,
            borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.search_off_rounded,
            size: 52, color: _T.primary.withOpacity(0.55)),
      ),
      const SizedBox(height: 20),
      Text('No positions found', style: _T.head(fs: 18)),
      const SizedBox(height: 6),
      Text('Try adjusting your filters', style: _T.label(fs: 13)),
      const SizedBox(height: 16),
      TextButton.icon(
        onPressed: onClear,
        icon: const Icon(Icons.clear_all_rounded, size: 17),
        label: Text('Clear filters', style: _T.label(fs: 13, c: _T.primary)),
      ),
    ]),
  );
}

class _EmptyJobsState extends StatelessWidget {
  const _EmptyJobsState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: _T.bg, shape: BoxShape.circle),
        child: const Icon(Icons.work_outline_rounded,
            size: 56, color: _T.textTert),
      ),
      const SizedBox(height: 20),
      Text('No Positions Available', style: _T.head(fs: 18, c: _T.textSec)),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.red.withOpacity(0.25)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded,
            size: 52, color: _T.red.withOpacity(0.7)),
        const SizedBox(height: 14),
        Text('Something went wrong',
            style: _T.head(fs: 16, c: _T.red)),
        const SizedBox(height: 6),
        Text(error, textAlign: TextAlign.center,
            style: _T.label(fs: 12, c: _T.red)),
      ]),
    ),
  );
}