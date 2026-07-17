import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Screens/Recruiter/LIst_of_Applicants_provider.dart';

// ─── Tokens ──────────────────────────────────────────────────────────────────
class _T {
  static const c0 = Color(0xFF0D1117);
  static const c1 = Color(0xFF161B22);
  static const c2 = Color(0xFF21262D);
  static const cSec = Color(0xFF57606A);
  static const cTert = Color(0xFF8B949E);
  static const cBdr = Color(0xFFD0D7DE);
  static const cBg = Color(0xFFF6F8FA);
  static const cWht = Color(0xFFFFFFFF);
  static const cAcc = Color(0xFF0969DA);
  static const cGrn = Color(0xFF1A7F37);
  static const cAmb = Color(0xFFBF8700);
  static const cPur = Color(0xFF8250DF);
  static const cRed = Color(0xFFCF222E);

  // Text styles — defined once, reused via const
  static TextStyle label({
    double fs = 11,
    Color? c,
    FontWeight fw = FontWeight.w500,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: fs,
    fontWeight: fw,
    color: c ?? cSec,
  );

  static TextStyle head({double fs = 14, Color? c}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fs,
        fontWeight: FontWeight.w700,
        color: c ?? c0,
      );

  static TextStyle body({double fs = 13, Color? c}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fs,
        fontWeight: FontWeight.w600,
        color: c ?? c1,
        height: 1.6,
      );
}

// ─── Layout breakpoints (computed once, passed down via InheritedWidget) ─────
enum _Layout { mobile, tablet, desktop }

class _LayoutData {
  final _Layout layout;
  final double sw;
  _LayoutData(this.layout, this.sw);

  bool get isMobile => layout == _Layout.mobile;
  bool get isDesktop => layout == _Layout.desktop;

  double get hPad => isMobile ? 14 : 24.0;
  double get vPad => isMobile ? 14 : 20.0;
  double get cardR => isMobile ? 8 : 10.0;
  double get bodyFs => isMobile ? 12 : 13.0;
  double get headFs => isMobile ? 13 : 15.0;
}

class _LD extends InheritedWidget {
  final _LayoutData data;
  const _LD({required this.data, required super.child});

  static _LayoutData of(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<_LD>()!.data;

  @override
  bool updateShouldNotify(_LD old) => old.data.layout != data.layout;
}

// ─── Email / phone masker (pure function) ────────────────────────────────────
String _mask(String v, {bool email = false}) {
  if (v.isEmpty) return 'Not provided';
  if (email) {
    final p = v.split('@');
    if (p.length != 2) return v;
    final u = p[0];
    return '${u.length > 2 ? u.substring(0, 2) : '**'}***@${p[1]}';
  }
  if (v.length <= 4) return '****';
  return '${v.substring(0, 2)}****${v.substring(v.length - 2)}';
}

// ═════════════════════════════════════════════════════════════════════════════
// ROOT
// ═════════════════════════════════════════════════════════════════════════════
class ViewApplicantDetails extends StatelessWidget {
  final ApplicantRecord applicant;
  const ViewApplicantDetails({super.key, required this.applicant});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, bc) {
        final sw = bc.maxWidth;
        final _Layout l;
        if (sw < 600) {
          l = _Layout.mobile;
        } else if (sw < 960) {
          l = _Layout.tablet;
        } else {
          l = _Layout.desktop;
        }
        final ld = _LayoutData(l, sw);

        final content = ClipRRect(
          borderRadius: BorderRadius.circular(ld.isMobile ? 0 : 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ld.isDesktop ? 1100 : (l == _Layout.tablet ? 780 : sw),
              maxHeight: ld.isMobile
                  ? MediaQuery.of(ctx).size.height
                  : (l == _Layout.tablet
                        ? MediaQuery.of(ctx).size.height * 0.92
                        : 860),
            ),
            child: Material(
              color: _T.cWht,
              child: Column(
                children: [
                  if (ld.isMobile)
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _T.cBdr,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  RepaintBoundary(child: _Header(applicant: applicant)),
                  Expanded(
                    child: ld.isDesktop
                        ? _DesktopBody(applicant: applicant)
                        : _MobileTabletBody(applicant: applicant),
                  ),
                ],
              ),
            ),
          ),
        );

        return _LD(
          data: ld,
          child: ld.isMobile
              ? content
              : Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: l == _Layout.tablet ? 24 : 48,
                    vertical: 20,
                  ),
                  child: content,
                ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HEADER  (RepaintBoundary'd — only repaints on status change)
// ═════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final ApplicantRecord applicant;
  const _Header({required this.applicant});

  @override
  Widget build(BuildContext context) {
    final ld = _LD.of(context);
    final r = ld.isMobile ? 20.0 : 26.0;

    return Container(
      padding: EdgeInsets.fromLTRB(ld.hPad, ld.vPad, ld.hPad - 4, ld.vPad - 2),
      decoration: const BoxDecoration(
        color: _T.cWht,
        border: Border(bottom: BorderSide(color: _T.cBdr, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar
          SizedBox(
            width: r * 2,
            height: r * 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _T.cBdr, width: 1.5),
                    color: _T.cBg,
                  ),
                  child: ClipOval(
                    child: applicant.pictureUrl.isNotEmpty
                        ? Image.network(
                            applicant.pictureUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _InitAvatar(applicant.name, r),
                          )
                        : _InitAvatar(applicant.name, r),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: _T.cWht,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      applicant.status == 'accepted'
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: applicant.status == 'accepted' ? _T.cGrn : _T.cAmb,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: ld.isMobile ? 10 : 14),

          // ── Name + role + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  applicant.name,
                  style: _T.head(fs: ld.isMobile ? 15 : 18),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!ld.isMobile && (applicant.jobData?.title ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      applicant.jobData!.title,
                      style: _T.label(c: _T.cSec, fw: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 5),
                _BadgeRow(applicant: applicant),
              ],
            ),
          ),

          // ── Close
          _IconBtn(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final ApplicantRecord applicant;
  const _BadgeRow({required this.applicant});

  @override
  Widget build(BuildContext context) {
    final ld = _LD.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (applicant.nationality.isNotEmpty)
            _Chip(
              Icons.location_on_outlined,
              applicant.nationality,
              ld.isMobile,
            ),
          if (applicant.dob.isNotEmpty) ...[
            const SizedBox(width: 5),
            _Chip(Icons.cake_outlined, applicant.dob, ld.isMobile),
          ],
          const SizedBox(width: 5),
          _Chip(
            Icons.work_outline_rounded,
            '${applicant.experienceYears}y exp',
            ld.isMobile,
            color: _T.cAcc,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DESKTOP — sidebar + scrollable main
// ═════════════════════════════════════════════════════════════════════════════
class _DesktopBody extends StatelessWidget {
  final ApplicantRecord applicant;
  const _DesktopBody({required this.applicant});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar — fixed width, independent scroll
        SizedBox(
          width: 260,
          child: ColoredBox(
            color: _T.cBg,
            child: RepaintBoundary(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: _SideContent(applicant: applicant),
              ),
            ),
          ),
        ),
        // Vertical divider
        const VerticalDivider(width: 1, color: _T.cBdr),
        // Main
        Expanded(
          child: RepaintBoundary(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 36),
              child: _MainContent(
                applicant: applicant,
                includeSummaryEdu: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MOBILE / TABLET — tab view
// ═════════════════════════════════════════════════════════════════════════════
class _MobileTabletBody extends StatefulWidget {
  final ApplicantRecord applicant;
  const _MobileTabletBody({required this.applicant});
  @override
  State<_MobileTabletBody> createState() => _MobileTabletBodyState();
}

class _MobileTabletBodyState extends State<_MobileTabletBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tc = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ld = _LD.of(context);
    final p = EdgeInsets.fromLTRB(ld.hPad, ld.isMobile ? 16 : 22, ld.hPad, 32);

    return Column(
      children: [
        // ── Tab bar
        ColoredBox(
          color: _T.cWht,
          child: TabBar(
            controller: _tc,
            indicatorColor: _T.cAcc,
            indicatorWeight: 2,
            labelColor: _T.cAcc,
            unselectedLabelColor: _T.cSec,
            labelStyle: _T.label(
              fw: FontWeight.w700,
              c: _T.cAcc,
              fs: ld.isMobile ? 12 : 13,
            ),
            unselectedLabelStyle: _T.label(fs: ld.isMobile ? 12 : 13),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Experience & Docs'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: [
              // Tab 1
              RepaintBoundary(
                child: SingleChildScrollView(
                  padding: p,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SideContent(applicant: widget.applicant),
                      const SizedBox(height: 24),
                      const _SecHead('Executive Summary', Icons.dashboard_outlined),
                      const SizedBox(height: 10),
                      Text(
                        widget.applicant.summary.isNotEmpty
                            ? widget.applicant.summary
                            : widget.applicant.objectives,
                        style: _T.body(fs: ld.bodyFs),
                      ),
                      const SizedBox(height: 22),
                      const _SecHead('Education', Icons.school_outlined),
                      const SizedBox(height: 10),
                      widget.applicant.educations.isEmpty
                          ? const _EmptyState('No education listed')
                          : _EduList(widget.applicant.educations),
                    ],
                  ),
                ),
              ),
              // Tab 2
              RepaintBoundary(
                child: SingleChildScrollView(
                  padding: p,
                  child: _MainContent(
                    applicant: widget.applicant,
                    includeSummaryEdu: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SIDE CONTENT
// ═════════════════════════════════════════════════════════════════════════════
class _SideContent extends StatelessWidget {
  final ApplicantRecord applicant;
  const _SideContent({required this.applicant});

  @override
  Widget build(BuildContext context) {
    final ld = _LD.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Contact
        const _CatLabel('Contact'),
        const SizedBox(height: 8),
        _ContactRow(
          Icons.email_outlined,
          'Email',
          _mask(applicant.email, email: true),
        ),
        const SizedBox(height: 7),
        _ContactRow(Icons.phone_outlined, 'Phone', _mask(applicant.phone)),

        const SizedBox(height: 20),

        // ── Stats
        const _CatLabel('Quick Stats'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                '${applicant.experienceYears}+',
                'Yrs Exp',
                _T.cAcc,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _StatBox(
                '${applicant.certifications.length}',
                'Certs',
                _T.cGrn,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _StatBox('${applicant.skills.length}', 'Skills', _T.cPur),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Skills
        const _CatLabel('Skills'),
        const SizedBox(height: 8),
        applicant.skills.isEmpty
            ? const _EmptyState('No skills listed')
            : Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [for (final s in applicant.skills) _SkillPill(s)],
              ),

        // ── Social
        if (applicant.socialLinks.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _CatLabel('Social Links'),
          const SizedBox(height: 8),
          for (final _ in applicant.socialLinks)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 13, color: _T.cAcc),
                  const SizedBox(width: 6),
                  Text(
                    'Link Hidden',
                    style: _T
                        .label(c: _T.cAcc)
                        .copyWith(decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MAIN CONTENT
// ═════════════════════════════════════════════════════════════════════════════
class _MainContent extends StatelessWidget {
  final ApplicantRecord applicant;
  final bool includeSummaryEdu;
  const _MainContent({
    required this.applicant,
    required this.includeSummaryEdu,
  });

  @override
  Widget build(BuildContext context) {
    final ld = _LD.of(context);
    final gap = SizedBox(height: ld.isMobile ? 20.0 : 26.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary + Education (desktop only)
        if (includeSummaryEdu) ...[
          const _SecHead('Executive Summary', Icons.dashboard_outlined),
          const SizedBox(height: 10),
          Text(
            applicant.summary.isNotEmpty
                ? applicant.summary
                : applicant.objectives,
            style: _T.body(),
          ),
          const SizedBox(height: 26),
          const _SecHead('Education', Icons.school_outlined),
          const SizedBox(height: 10),
          applicant.educations.isEmpty
              ? const _EmptyState('No education listed')
              : _EduList(applicant.educations),
          gap,
        ],

        // Professional Experience
        const _SecHead('Professional Experience', Icons.work_history_outlined),
        SizedBox(height: ld.isMobile ? 10 : 14),
        applicant.experiences.isEmpty
            ? const _EmptyState('No experience listed')
            : _ExpList(applicant.experiences),
        gap,

        // Experience Documents
        const _SecHead('Experience Documents', Icons.folder_outlined),
        const SizedBox(height: 10),
        applicant.experienceDocuments.isEmpty
            ? const _EmptyState('No experience documents provided')
            : _DocList(applicant.experienceDocuments),
        gap,

        // Certifications
        const _SecHead('Certifications & Licenses', Icons.verified_user_outlined),
        const SizedBox(height: 10),
        applicant.certifications.isEmpty
            ? const _EmptyState('No certifications provided')
            : _CertGrid(applicant.certifications),
        gap,

        // Certification Documents
        const _SecHead('Certification Documents', Icons.attach_file_rounded),
        const SizedBox(height: 10),
        applicant.certificationDocuments.isEmpty
            ? const _EmptyState('No certification documents provided')
            : _DocList(applicant.certificationDocuments),
        gap,

        // Publications
        const _SecHead('Publications', Icons.article_outlined),
        const SizedBox(height: 10),
        applicant.publications.isEmpty
            ? const _EmptyState('No publications provided')
            : _NumberedList(applicant.publications),
        gap,

        // Awards
        const _SecHead('Awards', Icons.emoji_events_outlined),
        const SizedBox(height: 10),
        applicant.awards.isEmpty
            ? const _EmptyState('No awards provided')
            : _NumberedList(applicant.awards),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LIST BUILDERS  (build lazily via Column+map to avoid unnecessary ListView overhead
// inside nested scroll — fine for typical CV data sizes)
// ═════════════════════════════════════════════════════════════════════════════
class _ExpList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ExpList(this.items);
  @override
  Widget build(BuildContext context) =>
      Column(children: [for (final e in items) _ExpTile(e)]);
}

class _EduList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _EduList(this.items);
  @override
  Widget build(BuildContext context) =>
      Column(children: [for (final e in items) _EduTile(e)]);
}

class _DocList extends StatelessWidget {
  final List<Map<String, dynamic>> docs;
  const _DocList(this.docs);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final d in docs)
        _DocTile(d['name'] ?? 'Document', d['url'] ?? '', d['type'] ?? 'file'),
    ],
  );
}

class _NumberedList extends StatelessWidget {
  final List<String> items;
  const _NumberedList(this.items);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (int i = 0; i < items.length; i++) _NumItem(i + 1, items[i]),
    ],
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// TILES
// ═════════════════════════════════════════════════════════════════════════════
class _ExpTile extends StatelessWidget {
  final Map<String, dynamic> exp;
  const _ExpTile(this.exp);

  @override
  Widget build(BuildContext context) {
    final ld = _LD.of(context);
    final role = exp['role']?.toString() ?? 'Role Not Specified';
    final org = exp['organization']?.toString() ?? 'Unknown';
    final dur = exp['duration']?.toString() ?? '';
    final start = exp['startDate']?.toString() ?? '';
    final end = exp['endDate']?.toString() ?? '';
    final duties = exp['duties']?.toString() ?? exp['text']?.toString() ?? '';
    final rank = exp['rank']?.toString() ?? '';
    final unit = exp['unit']?.toString() ?? '';
    final cmd = exp['command']?.toString() ?? '';
    final loc = exp['location']?.toString() ?? '';
    final ac = exp['aircraftType']?.toString() ?? '';
    final fh = exp['flightHours']?.toString() ?? '';
    final isMil = rank.isNotEmpty || unit.isNotEmpty || cmd.isNotEmpty;
    final date = dur.isNotEmpty
        ? dur
        : start.isNotEmpty
        ? '$start${end.isNotEmpty ? ' – $end' : ' – Present'}'
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: ld.isMobile ? 10 : 14),
      decoration: BoxDecoration(
        color: _T.cWht,
        borderRadius: BorderRadius.circular(ld.cardR),
        border: Border.all(color: _T.cBdr),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(ld.isMobile ? 12 : 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBox(
                  isMil
                      ? Icons.military_tech_outlined
                      : Icons.business_center_outlined,
                  _T.cAcc,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role, style: _T.head(fs: ld.headFs)),
                      const SizedBox(height: 2),
                      Text(
                        org,
                        style: _T.label(c: _T.cAcc, fw: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (date.isNotEmpty) _DateBadge(date, ld.isMobile),
              ],
            ),
          ),

          // Military chips
          if (isMil)
            Padding(
              padding: EdgeInsets.fromLTRB(
                ld.isMobile ? 12 : 14,
                0,
                ld.isMobile ? 12 : 14,
                ld.isMobile ? 10 : 12,
              ),
              child: Container(
                padding: EdgeInsets.all(ld.isMobile ? 9 : 11),
                decoration: BoxDecoration(
                  color: _T.cBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Wrap(
                  spacing: ld.isMobile ? 10 : 16,
                  runSpacing: ld.isMobile ? 7 : 9,
                  children: [
                    if (rank.isNotEmpty)
                      _IChip(Icons.stars_outlined, 'Rank', rank),
                    if (unit.isNotEmpty)
                      _IChip(Icons.group_outlined, 'Unit', unit),
                    if (cmd.isNotEmpty) _IChip(Icons.flag_outlined, 'Cmd', cmd),
                    if (loc.isNotEmpty)
                      _IChip(Icons.location_on_outlined, 'Loc', loc),
                    if (ac.isNotEmpty)
                      _IChip(Icons.flight_outlined, 'Aircraft', ac),
                    if (fh.isNotEmpty)
                      _IChip(Icons.schedule_outlined, 'Hrs', fh),
                  ],
                ),
              ),
            ),

          // Duties
          if (duties.isNotEmpty) ...[
            const Divider(height: 1, color: _T.cBdr),
            Padding(
              padding: EdgeInsets.all(ld.isMobile ? 12 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KEY RESPONSIBILITIES',
                    style: _T.label(fs: 9, c: _T.cTert, fw: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    duties,
                    style: _T.body(fs: ld.bodyFs, c: _T.c2),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EduTile extends StatelessWidget {
  final Map<String, dynamic> edu;
  const _EduTile(this.edu);

  @override
  Widget build(BuildContext context) {
    final ld = _LD.of(context);
    final inst = edu['institutionName']?.toString() ?? 'Institution';
    final maj = edu['majorSubjects']?.toString() ?? '';
    final dur = edu['duration']?.toString() ?? '';
    final cgpa = edu['marksOrCgpa']?.toString() ?? '';

    return Container(
      padding: EdgeInsets.all(ld.isMobile ? 11 : 13),
      margin: EdgeInsets.only(bottom: ld.isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: _T.cWht,
        borderRadius: BorderRadius.circular(ld.cardR),
        border: Border.all(color: _T.cBdr),
      ),
      child: Row(
        children: [
          const _IconBox(Icons.school_outlined, _T.cSec),
          SizedBox(width: ld.isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inst, style: _T.head(fs: ld.isMobile ? 13 : 14)),
                if (maj.isNotEmpty) Text(maj, style: _T.label()),
                if (cgpa.isNotEmpty)
                  Text(
                    'CGPA: $cgpa',
                    style: _T.label(c: _T.cAcc, fw: FontWeight.w700),
                  ),
              ],
            ),
          ),
          if (dur.isNotEmpty)
            Text(dur, style: _T.label(fs: 10, fw: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _CertGrid extends StatelessWidget {
  final List<Map<String, String>> certs;
  const _CertGrid(this.certs);

  @override
  Widget build(BuildContext context) {
    final ld = _LD.of(context);
    return LayoutBuilder(
      builder: (_, bc) {
        final cols = bc.maxWidth < 380
            ? 1
            : bc.maxWidth < 680
            ? 1
            : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: ld.isMobile ? 7.5 : 3.4,
          ),
          itemCount: certs.length,
          itemBuilder: (_, i) => _CertCard(certs[i]),
        );
      },
    );
  }
}

class _CertCard extends StatelessWidget {
  final Map<String, String> cert;
  const _CertCard(this.cert);

  @override
  Widget build(BuildContext context) {
    final ld = _LD.of(context);
    final name = cert['name'] ?? 'Certification';
    final org = cert['organization'] ?? '';

    return Container(
      padding: EdgeInsets.all(ld.isMobile ? 9 : 11),
      decoration: BoxDecoration(
        color: _T.cBg,
        borderRadius: BorderRadius.circular(ld.cardR),
        border: Border.all(color: _T.cBdr),
      ),
      child: Row(
        children: [
          const _IconBox(Icons.verified_outlined, _T.cAcc, small: true),
          SizedBox(width: ld.isMobile ? 7 : 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: _T.head(fs: ld.isMobile ? 11 : 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (org.isNotEmpty)
                  Text(
                    org,
                    style: _T.label(fs: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final String name, url, type;
  const _DocTile(this.name, this.url, this.type);

  @override
  Widget build(BuildContext context) {
    final ld = _LD.of(context);
    final isPdf = type.toLowerCase().contains('pdf');

    return Container(
      margin: EdgeInsets.only(bottom: ld.isMobile ? 7 : 9),
      padding: EdgeInsets.symmetric(
        horizontal: ld.isMobile ? 10 : 13,
        vertical: ld.isMobile ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: _T.cBg,
        borderRadius: BorderRadius.circular(ld.cardR),
        border: Border.all(color: _T.cBdr),
      ),
      child: Row(
        children: [
          _IconBox(
            isPdf
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined,
            const Color(0xFF0969DA),
          ),
          SizedBox(width: ld.isMobile ? 9 : 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: _T.head(fs: ld.bodyFs),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(type.toUpperCase(), style: _T.label(fs: 9)),
              ],
            ),
          ),
          if (url.isNotEmpty)
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Contact Admin to view confidential attachments',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(ld.isMobile ? 6 : 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0969DA).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF0969DA).withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  Icons.download_rounded,
                  size: ld.isMobile ? 14 : 16,
                  color: const Color(0xFF0969DA),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumItem extends StatelessWidget {
  final int num;
  final String text;
  const _NumItem(this.num, this.text);

  @override
  Widget build(BuildContext context) {
    final ld = _LD.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: ld.isMobile ? 8 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _T.cPur.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                '$num',
                style: _T.label(fs: 11, c: _T.cPur, fw: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                style: _T.body(fs: ld.bodyFs, c: _T.c2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MICRO WIDGETS — all const-constructable
// ═════════════════════════════════════════════════════════════════════════════

/// Section heading with accent bar
class _SecHead extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SecHead(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    final sm = _LD.of(context).isMobile;
    return Row(
      children: [
        Container(
          width: 3,
          height: sm ? 14 : 16,
          decoration: BoxDecoration(
            color: _T.cAcc,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Icon(icon, size: sm ? 12 : 14, color: _T.cAcc),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title.toUpperCase(),
            style: _T
                .label(fs: sm ? 9 : 10, c: _T.cSec, fw: FontWeight.w700)
                .copyWith(letterSpacing: 0.6),
          ),
        ),
      ],
    );
  }
}

class _CatLabel extends StatelessWidget {
  final String text;
  const _CatLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: _T
        .label(fs: 9, c: _T.cTert, fw: FontWeight.w700)
        .copyWith(letterSpacing: 0.6),
  );
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ContactRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: _T.cWht,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _T.cBdr),
        ),
        child: Icon(icon, size: 14, color: _T.cSec),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _T.label(fs: 9, c: _T.cTert)),
            Text(
              value,
              style: _T.label(fs: 11, fw: FontWeight.w700, c: _T.c0),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatBox(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final sm = _LD.of(context).isMobile;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sm ? 7 : 10,
        vertical: sm ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: sm ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label, style: _T.label(fs: 9)),
        ],
      ),
    );
  }
}

class _SkillPill extends StatelessWidget {
  final String label;
  const _SkillPill(this.label);

  @override
  Widget build(BuildContext context) {
    final sm = _LD.of(context).isMobile;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sm ? 8 : 10,
        vertical: sm ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: _T.cWht,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _T.cBdr),
      ),
      child: Text(label, style: _T.label(fs: sm ? 10 : 11)),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool sm;
  final Color? color;
  const _Chip(this.icon, this.text, this.sm, {this.color});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final c = color ?? _T.cSec;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sm ? 6 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: sm ? 10 : 12, color: c),
          const SizedBox(width: 4),
          Text(
            text,
            style: _T.label(fs: sm ? 10 : 11, c: c),
          ),
        ],
      ),
    );
  }
}

/// Small icon inside a rounded background box
class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool small;
  const _IconBox(this.icon, this.color, {this.small = false});

  @override
  Widget build(BuildContext context) {
    final sm = _LD.of(context).isMobile;
    final p = small ? (sm ? 6.0 : 7.0) : (sm ? 8.0 : 9.0);
    final sz = small ? (sm ? 14.0 : 16.0) : (sm ? 16.0 : 18.0);
    return Container(
      padding: EdgeInsets.all(p),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: sz, color: color),
    );
  }
}

class _IChip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _IChip(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final sm = _LD.of(context).isMobile;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: sm ? 11 : 12, color: _T.cSec),
        const SizedBox(width: 4),
        Text('$label: ', style: _T.label(fs: sm ? 10 : 11)),
        Text(
          value,
          style: _T.label(fs: sm ? 10 : 11, c: _T.c0, fw: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DateBadge extends StatelessWidget {
  final String date;
  final bool sm;
  const _DateBadge(this.date, this.sm);

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: sm ? 7 : 9, vertical: sm ? 4 : 5),
    decoration: BoxDecoration(
      color: _T.cBg,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: _T.cBdr),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.calendar_today_outlined, size: 10, color: _T.cTert),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: sm ? 72 : 120),
          child: Text(
            date,
            style: _T.label(fs: sm ? 10 : 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sm = _LD.of(context).isMobile;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(sm ? 7 : 8),
        decoration: BoxDecoration(
          color: _T.cBg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _T.cBdr),
        ),
        child: Icon(icon, size: sm ? 16 : 18, color: _T.cSec),
      ),
    );
  }
}

class _InitAvatar extends StatelessWidget {
  final String name;
  final double r;
  const _InitAvatar(this.name, this.r);

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _T.cBg,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.plusJakartaSans(
          fontSize: r * 0.7,
          fontWeight: FontWeight.w800,
          color: _T.c0,
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String msg;
  const _EmptyState(this.msg);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Text(
      msg,
      style: _T
          .label(fs: 11, c: _T.cTert)
          .copyWith(fontStyle: FontStyle.italic),
    ),
  );
}
