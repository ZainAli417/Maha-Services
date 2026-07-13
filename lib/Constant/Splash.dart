import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'CTA_Dynamic.dart';
import 'hero.dart';

/// Landing page entry point (route `/`).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const LandingPage();
}

// ─── Palette ───────────────────────────────────────────────────────────────
class _P {
  static const indigo = Color(0xFF6366F1);
  static const indigoDeep = Color(0xFF4F46E5);
  static const violet = Color(0xFF8B5CF6);
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const ink = Color(0xFF0F172A);
  static const slate = Color(0xFF475569);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
  static const border = Color(0xFFE7EBF3);
  static const bgSoft = Color(0xFFF7F8FC);
  static const bgTint = Color(0xFFEEF1FF);
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late final AnimationController _grid;
  late final ScrollController _scroll;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _grid = AnimationController(vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
    _scroll = ScrollController()
      ..addListener(() {
        final o = _scroll.offset;
        if ((o - _scrollOffset).abs() > 4) {
          setState(() => _scrollOffset = o);
        }
      });
  }

  @override
  void dispose() {
    _grid.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Breakpoints
  double get _w => MediaQuery.of(context).size.width;
  bool get _isMobile => _w < 700;
  bool get _isTablet => _w >= 700 && _w < 1024;
  double get _hPad => _isMobile ? 18 : (_isTablet ? 40 : 80);

  void _scrollTop() => _scroll.animateTo(0,
      duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);

  @override
  Widget build(BuildContext context) {
    final navH = _isMobile ? 62.0 : 76.0;
    final showTop = _scrollOffset > 500;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _hero(navH)),
              SliverToBoxAdapter(child: _trustStrip()),
              SliverToBoxAdapter(child: _howItWorks()),
              SliverToBoxAdapter(child: _ecosystem()),
              SliverToBoxAdapter(child: _rolesSplit()),
              SliverToBoxAdapter(child: _statsBand()),
              SliverToBoxAdapter(child: _finalCta()),
              SliverToBoxAdapter(child: _footer()),
            ],
          ),

          // Fixed glass nav
          Positioned(top: 0, left: 0, right: 0, child: _navBar(navH)),

          // Floating role CTAs (existing)
          ScrollAwareCTAButtons(isDarkMode: false, scrollController: _scroll),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: showTop ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: FloatingActionButton(
          onPressed: _scrollTop,
          backgroundColor: _P.indigo,
          elevation: 3,
          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
        ),
      ),
    );
  }

  // ─── Fixed navigation ──────────────────────────────────────────────────────
  Widget _navBar(double navH) {
    final scrolled = _scrollOffset > 24;
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: navH,
          padding: EdgeInsets.symmetric(horizontal: _hPad),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: scrolled ? 0.86 : 0.55),
            border: Border(
              bottom: BorderSide(
                color: scrolled ? _P.border : Colors.transparent,
              ),
            ),
            boxShadow: scrolled
                ? [
                    BoxShadow(
                      color: _P.ink.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _logo(),
              const SizedBox(width: 10),
              if (!_isMobile)
                Text('MAHA SERVICES',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _P.ink,
                        letterSpacing: 0.3)),
              const Spacer(),
              if (!_isMobile) ...[
                _navLink('Pricing', '/pricing'),
                const SizedBox(width: 6),
                _navLink('Admin', '/admin'),
                const SizedBox(width: 14),
              ],
              _ghostBtn('Login', () => context.go('/login')),
              const SizedBox(width: 8),
              _gradientBtn('Get Started', () => context.go('/register')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    final s = _isMobile ? 34.0 : 42.0;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: _P.indigo.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ClipOval(
        child: Image.asset('images/logo.png',
            fit: BoxFit.cover, cacheWidth: 120, cacheHeight: 120),
      ),
    );
  }

  Widget _navLink(String label, String route) {
    return _Hoverable(
      builder: (hover) => GestureDetector(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hover ? _P.indigo : _P.slate)),
        ),
      ),
    );
  }

  Widget _ghostBtn(String label, VoidCallback onTap) {
    return _Hoverable(
      builder: (hover) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: _isMobile ? 12 : 18, vertical: _isMobile ? 8 : 11),
          decoration: BoxDecoration(
            color: hover ? _P.bgTint : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _P.indigo, width: 1.5),
          ),
          child: Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: _isMobile ? 12 : 14,
                  fontWeight: FontWeight.w700,
                  color: _P.indigo)),
        ),
      ),
    );
  }

  Widget _gradientBtn(String label, VoidCallback onTap) {
    return _Hoverable(
      builder: (hover) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
              horizontal: _isMobile ? 12 : 18, vertical: _isMobile ? 8 : 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_P.indigo, _P.violet]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: _P.indigo.withValues(alpha: hover ? 0.45 : 0.28),
                  blurRadius: hover ? 18 : 10,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: _isMobile ? 12 : 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded,
                  size: 15, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero (animated grid + existing HeroSection) ────────────────────────────
  Widget _hero(double navH) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3F1FF), Color(0xFFF9FAFF), Colors.white],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _grid,
                builder: (_, _) => Opacity(
                  opacity: 0.5,
                  child: CustomPaint(
                    painter: _OptimizedGridPainter(_grid.value),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          // Soft gradient blobs
          Positioned(
              top: -80,
              right: -60,
              child: _blob(260, _P.violet.withValues(alpha: 0.18))),
          Positioned(
              bottom: 40,
              left: -70,
              child: _blob(220, _P.indigo.withValues(alpha: 0.14))),
          Padding(
            padding: EdgeInsets.fromLTRB(_hPad, navH + 8, _hPad, 0),
            child: HeroSection(isDarkMode: false),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      );

  // ─── Trust strip ────────────────────────────────────────────────────────────
  Widget _trustStrip() {
    final stats = const [
      ('15K+', 'Hired', Icons.people_alt_rounded),
      ('98%', 'Success rate', Icons.trending_up_rounded),
      ('24h', 'Avg. response', Icons.bolt_rounded),
      ('500+', 'Recruiters', Icons.business_center_rounded),
    ];
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(_hPad, _isMobile ? 24 : 40, _hPad, 0),
      child: _center(
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: _isMobile ? 14 : 28, vertical: _isMobile ? 16 : 22),
          decoration: BoxDecoration(
            color: _P.bgSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _P.border),
          ),
          child: Column(
            children: [
              Text('TRUSTED BY AVIATION & INDUSTRY LEADERS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: _isMobile ? 10.5 : 12,
                      fontWeight: FontWeight.w700,
                      color: _P.faint,
                      letterSpacing: 1.4)),
              SizedBox(height: _isMobile ? 14 : 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: _isMobile ? 14 : 40,
                runSpacing: 16,
                children: [
                  for (final s in stats)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.$3, size: _isMobile ? 18 : 22, color: _P.indigo),
                        const SizedBox(width: 8),
                        Text(s.$1,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: _isMobile ? 18 : 24,
                                fontWeight: FontWeight.w800,
                                color: _P.ink)),
                        const SizedBox(width: 6),
                        Text(s.$2,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: _isMobile ? 12 : 13,
                                fontWeight: FontWeight.w600,
                                color: _P.muted)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section header ─────────────────────────────────────────────────────────
  Widget _sectionHead(String eyebrow, String title, String subtitle, Color c) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.withValues(alpha: 0.25)),
          ),
          child: Text(eyebrow,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: c,
                  letterSpacing: 1)),
        ),
        SizedBox(height: _isMobile ? 12 : 16),
        Text(title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                fontSize: _isMobile ? 26 : (_isTablet ? 34 : 42),
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: _P.ink,
                letterSpacing: -0.5)),
        SizedBox(height: _isMobile ? 8 : 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: _isMobile ? 13.5 : 16,
                  height: 1.6,
                  color: _P.muted,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  // ─── How it works ─────────────────────────────────────────────────────────
  Widget _howItWorks() {
    final steps = const [
      (
        '01',
        'Build Your Profile',
        'Create a rich professional profile and let our AI craft your CV.',
        Icons.account_circle_rounded,
        _P.indigo
      ),
      (
        '02',
        'Get Discovered',
        'Recruiters browse the talent pool and shortlist candidates like you.',
        Icons.search_rounded,
        _P.emerald
      ),
      (
        '03',
        'Admin Review',
        'Requests are evaluated, interviews scheduled and training arranged.',
        Icons.verified_user_rounded,
        _P.amber
      ),
      (
        '04',
        'Get Hired',
        'Final selection and seamless onboarding — talent meets opportunity.',
        Icons.workspace_premium_rounded,
        _P.violet
      ),
    ];
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(_hPad, _isMobile ? 44 : 90, _hPad, 0),
      child: _center(
        Column(
          children: [
            _sectionHead('HOW IT WORKS', 'A seamless 4-stage journey',
                'From first profile to final hire — one intelligent ecosystem.',
                _P.indigo),
            SizedBox(height: _isMobile ? 28 : 48),
            _isMobile
                ? Column(
                    children: [
                      for (final s in steps)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _stepCard(s.$1, s.$2, s.$3, s.$4, s.$5),
                        ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < steps.length; i++) ...[
                        Expanded(
                            child: _stepCard(steps[i].$1, steps[i].$2,
                                steps[i].$3, steps[i].$4, steps[i].$5)),
                        if (i < steps.length - 1) const SizedBox(width: 16),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard(String n, String title, String desc, IconData icon, Color c) {
    return _Hoverable(
      builder: (hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, hover ? -6 : 0, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hover ? c.withValues(alpha: 0.4) : _P.border),
          boxShadow: [
            BoxShadow(
                color: _P.ink.withValues(alpha: hover ? 0.1 : 0.04),
                blurRadius: hover ? 26 : 14,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [c, Color.lerp(c, Colors.white, 0.3)!]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                Text(n,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: c.withValues(alpha: 0.18))),
              ],
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 17, fontWeight: FontWeight.w700, color: _P.ink)),
            const SizedBox(height: 6),
            Text(desc,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, height: 1.6, color: _P.muted)),
          ],
        ),
      ),
    );
  }

  // ─── Ecosystem (3 portals) ────────────────────────────────────────────────
  Widget _ecosystem() {
    final portals = [
      FeaturePortal(
        number: '01',
        title: 'Candidate Portal',
        subtitle: 'Your Career, Your Control',
        color: _P.indigo,
        icon: Icons.person_rounded,
        items: [
          FeatureItem('Profile Builder',
              'Create comprehensive professional profiles',
              Icons.account_circle_rounded),
          FeatureItem('CV Generator', 'AI-powered resume creation tools',
              Icons.description_rounded),
          FeatureItem('Skill Showcase',
              'Highlight expertise and certifications',
              Icons.workspace_premium_rounded),
          FeatureItem('Public Portfolio', 'Share your journey with recruiters',
              Icons.public_rounded),
        ],
      ),
      FeaturePortal(
        number: '02',
        title: 'Recruiter Portal',
        subtitle: 'Find Perfect Candidates Fast',
        color: _P.emerald,
        icon: Icons.business_rounded,
        items: [
          FeatureItem('Candidate Search', 'Browse qualified talent pool',
              Icons.search_rounded),
          FeatureItem('Bulk Selection', 'Select multiple candidates at once',
              Icons.checklist_rounded),
          FeatureItem('Request Management', 'Submit hiring requests to admin',
              Icons.send_rounded),
          FeatureItem('Request Tracker',
              'Realtime recruitment request tracking', Icons.auto_graph),
        ],
      ),
      FeaturePortal(
        number: '03',
        title: 'Admin Portal',
        subtitle: 'End-to-End Hiring Management',
        color: _P.amber,
        icon: Icons.admin_panel_settings_rounded,
        items: [
          FeatureItem('Request Review', 'Evaluate recruiter requests',
              Icons.rate_review_rounded),
          FeatureItem('Interview Scheduling',
              'Organize and conduct interviews', Icons.event_rounded),
          FeatureItem('Candidate Training',
              'Skill development and preparation', Icons.school_rounded),
          FeatureItem('Final Selection', 'Complete hiring and onboarding',
              Icons.how_to_reg_rounded),
        ],
      ),
    ];
    return Container(
      padding: EdgeInsets.fromLTRB(_hPad, _isMobile ? 44 : 90, _hPad, 0),
      child: _center(
        Column(
          children: [
            _sectionHead('COMPLETE ECOSYSTEM', 'Three portals, one journey',
                'Powerful, purpose-built experiences for every role in hiring.',
                _P.violet),
            SizedBox(height: _isMobile ? 28 : 48),
            _isMobile
                ? Column(
                    children: [
                      for (final p in portals)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _portalCard(p)),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < portals.length; i++) ...[
                        Expanded(child: _portalCard(portals[i])),
                        if (i < portals.length - 1) const SizedBox(width: 20),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _portalCard(FeaturePortal p) {
    return _Hoverable(
      builder: (hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, hover ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: hover ? p.color.withValues(alpha: 0.4) : _P.border),
          boxShadow: [
            BoxShadow(
                color: (hover ? p.color : _P.ink).withValues(alpha: hover ? 0.14 : 0.05),
                blurRadius: hover ? 30 : 16,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header band
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [p.color, Color.lerp(p.color, _P.violet, 0.35)!],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(p.icon, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  Text(p.number,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.35))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _P.ink)),
                  const SizedBox(height: 3),
                  Text(p.subtitle,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.color)),
                  const SizedBox(height: 18),
                  for (final it in p.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: p.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(it.icon, size: 15, color: p.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.title,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: _P.ink)),
                                Text(it.description,
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: _P.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Roles split CTA ────────────────────────────────────────────────────────
  Widget _rolesSplit() {
    return Container(
      padding: EdgeInsets.fromLTRB(_hPad, _isMobile ? 44 : 90, _hPad, 0),
      child: _center(
        _isMobile
            ? Column(children: [
                _roleCard(
                    'Join as Candidate',
                    'Begin your aviation career today.',
                    Icons.flight_takeoff_rounded,
                    _P.indigo,
                    () => context.go('/register?role=candidate')),
                const SizedBox(height: 16),
                _roleCard(
                    'Join as Recruiter',
                    "Find the world's best aviation professionals.",
                    Icons.business_center_rounded,
                    _P.emerald,
                    () => context.go('/register?role=recruiter')),
              ])
            : Row(children: [
                Expanded(
                    child: _roleCard(
                        'Join as Candidate',
                        'Begin your aviation career today.',
                        Icons.flight_takeoff_rounded,
                        _P.indigo,
                        () => context.go('/register?role=candidate'))),
                const SizedBox(width: 20),
                Expanded(
                    child: _roleCard(
                        'Join as Recruiter',
                        "Find the world's best aviation professionals.",
                        Icons.business_center_rounded,
                        _P.emerald,
                        () => context.go('/register?role=recruiter'))),
              ]),
      ),
    );
  }

  Widget _roleCard(String title, String subtitle, IconData icon, Color c,
      VoidCallback onTap) {
    return _Hoverable(
      builder: (hover) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(_isMobile ? 24 : 34),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c, Color.lerp(c, _P.ink, 0.35)!],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: c.withValues(alpha: hover ? 0.4 : 0.22),
                  blurRadius: hover ? 30 : 18,
                  offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 18),
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: _isMobile ? 20 : 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.9))),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('Get started',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(width: 6),
                  AnimatedSlide(
                    offset: Offset(hover ? 0.3 : 0, 0),
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.arrow_forward_rounded,
                        size: 18, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats band (dark) ──────────────────────────────────────────────────────
  Widget _statsBand() {
    final metrics = const [
      ('15K+', 'Successfully Hired', Icons.people_rounded),
      ('98%', 'Success Rate', Icons.trending_up_rounded),
      ('24h', 'Avg. Response', Icons.schedule_rounded),
      ('500+', 'Active Recruiters', Icons.business_rounded),
    ];
    return Container(
      margin: EdgeInsets.fromLTRB(_hPad, _isMobile ? 44 : 90, _hPad, 0),
      padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 20 : 48, vertical: _isMobile ? 34 : 56),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: _P.indigo.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 20)),
        ],
      ),
      child: _center(
        Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text('⚡ PROVEN SUCCESS',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5)),
            ),
            SizedBox(height: _isMobile ? 14 : 18),
            Text('Trusted by Industry Leaders',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: _isMobile ? 24 : 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Real numbers, real impact — see how we transform hiring',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: _isMobile ? 13 : 16,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500)),
            SizedBox(height: _isMobile ? 26 : 44),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: _isMobile ? 12 : 28,
              runSpacing: 16,
              children: [
                for (final m in metrics) _metric(m.$1, m.$2, m.$3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String value, String label, IconData icon) {
    return Container(
      width: _isMobile ? 150 : 200,
      padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 16 : 22, vertical: _isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: _isMobile ? 18 : 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: _isMobile ? 20 : 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: _isMobile ? 10.5 : 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Final CTA ────────────────────────────────────────────────────────────
  Widget _finalCta() {
    return Container(
      padding: EdgeInsets.fromLTRB(_hPad, _isMobile ? 48 : 96, _hPad, _isMobile ? 48 : 96),
      child: _center(
        Column(
          children: [
            Text('Ready to transform your hiring?',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: _isMobile ? 26 : 40,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: _P.ink,
                    letterSpacing: -0.5)),
            SizedBox(height: _isMobile ? 10 : 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                  'Join thousands of aviation professionals and recruiters already building the future of hiring.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: _isMobile ? 14 : 17,
                      height: 1.6,
                      color: _P.muted,
                      fontWeight: FontWeight.w500)),
            ),
            SizedBox(height: _isMobile ? 24 : 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 12,
              children: [
                _gradientBtn('Get Started Free', () => context.go('/register')),
                _ghostBtn('Explore Pricing', () => context.go('/pricing')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Footer ─────────────────────────────────────────────────────────────────
  Widget _footer() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F2937), Color(0xFF0B1120)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(_hPad, _isMobile ? 34 : 56, _hPad, 24),
      child: _center(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flex(
              direction: _isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: _isMobile ? 0 : 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MAHA SERVICES',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: _isMobile ? 20 : 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Text(
                            'Revolutionizing recruitment through an intelligent 4-stage hiring ecosystem. Connecting talent with opportunity seamlessly.',
                            style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 13.5,
                                height: 1.8)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _isMobile ? 0 : 40, height: _isMobile ? 28 : 0),
                _footerLinks('Product', const [
                  ('Find Jobs', '/login'),
                  ('For Recruiters', '/register?role=recruiter'),
                  ('Pricing', '/pricing'),
                ]),
                SizedBox(width: _isMobile ? 0 : 40, height: _isMobile ? 20 : 0),
                _footerLinks('Account', const [
                  ('Login', '/login'),
                  ('Get Started', '/register'),
                  ('Admin', '/admin'),
                ]),
              ],
            ),
            SizedBox(height: _isMobile ? 24 : 40),
            const Divider(color: Color(0xFF374151), height: 1),
            SizedBox(height: _isMobile ? 14 : 20),
            Flex(
              direction: _isMobile ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('© 2026 Maha Services. All rights reserved.',
                    style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF6B7280),
                        fontSize: _isMobile ? 11 : 13)),
                SizedBox(height: _isMobile ? 10 : 0),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _P.indigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _P.indigo.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.psychology_rounded,
                          color: Color(0xFF818CF8), size: 15),
                      const SizedBox(width: 5),
                      Text('Developed By mahaservices.org',
                          style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF818CF8),
                              fontSize: _isMobile ? 10 : 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerLinks(String heading, List<(String, String)> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
                letterSpacing: 1)),
        const SizedBox(height: 12),
        for (final l in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Hoverable(
              builder: (hover) => GestureDetector(
                onTap: () => context.go(l.$2),
                child: Text(l.$1,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: hover
                            ? Colors.white
                            : const Color(0xFF9CA3AF))),
              ),
            ),
          ),
      ],
    );
  }

  // Centers content at a comfortable max width.
  Widget _center(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: child,
        ),
      );
}

// ─── Hover helper ────────────────────────────────────────────────────────────
class _Hoverable extends StatefulWidget {
  const _Hoverable({required this.builder});
  final Widget Function(bool hover) builder;

  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: widget.builder(_hover),
    );
  }
}

// ─── Data models (unchanged) ──────────────────────────────────────────────────
class FeaturePortal {
  final String number;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<FeatureItem> items;

  FeaturePortal({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.items,
  });
}

class FeatureItem {
  final String title;
  final String description;
  final IconData icon;

  FeatureItem(this.title, this.description, this.icon);
}

// ─── Animated grid painter (unchanged) ────────────────────────────────────────
class _OptimizedGridPainter extends CustomPainter {
  final double animationValue;

  static final Paint _baseGridPaint = Paint()
    ..color = const Color(0xFF4A90E2).withValues(alpha: 0.15)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;

  static final Paint _beamPaint = Paint()
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  static final Paint _intersectionPaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

  _OptimizedGridPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 100.0;
    final offset = animationValue * gridSize;
    const beamUpdateInterval = 2;

    int vi = 0;
    for (double x = -gridSize + (offset % gridSize);
        x < size.width + gridSize;
        x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _baseGridPaint);
      if (vi % beamUpdateInterval == 0) {
        final bp = (animationValue * 2 + vi * 0.3) % 1.0;
        final bs = bp * size.height;
        final bl = size.height * 0.4;
        _beamPaint.shader = ui.Gradient.linear(
          Offset(x, bs - bl / 2),
          Offset(x, bs + bl / 2),
          [
            Colors.transparent,
            const Color(0xFFF7E6FF).withValues(alpha: 0.4),
            const Color(0xFFF7E6FF).withValues(alpha: 0.9),
            const Color(0xFFF7E6FF).withValues(alpha: 0.4),
            Colors.transparent,
          ],
          [0.0, 0.2, 0.5, 0.8, 1.0],
        );
        canvas.drawLine(
          Offset(x, math.max(0, bs - bl / 2)),
          Offset(x, math.min(size.height, bs + bl / 2)),
          _beamPaint,
        );
      }
      vi++;
    }

    int hi = 0;
    for (double y = -gridSize + (offset % gridSize);
        y < size.height + gridSize;
        y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _baseGridPaint);
      if (hi % beamUpdateInterval == 0) {
        final bp = (animationValue * 1.5 + hi * 0.25) % 1.0;
        final bs = bp * size.width;
        final bl = size.width * 0.6;
        _beamPaint.shader = ui.Gradient.linear(
          Offset(bs - bl / 2, y),
          Offset(bs + bl / 2, y),
          [
            Colors.transparent,
            const Color(0xFFE6EFFF).withValues(alpha: 0.4),
            const Color(0xFFE6EFFF).withValues(alpha: 0.9),
            const Color(0xFFE6EFFF).withValues(alpha: 0.4),
            Colors.transparent,
          ],
          [0.0, 0.2, 0.5, 0.8, 1.0],
        );
        canvas.drawLine(
          Offset(math.max(0, bs - bl / 2), y),
          Offset(math.min(size.width, bs + bl / 2), y),
          _beamPaint,
        );
      }
      hi++;
    }
  }

  @override
  bool shouldRepaint(_OptimizedGridPainter oldDelegate) => true;
}
