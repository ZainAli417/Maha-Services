import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'CTA_Dynamic.dart';
import 'Header_Nav.dart';
import 'site_chrome.dart';

/// Landing page entry point (route `/`).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const LandingPage();
}

// ─── Brand palette (derived from images/logo_new.jpeg — navy + teal) ─────────
class _B {
  // Dark hero surfaces
  static const heroDeep = Color(0xFF061C31);
  static const heroMid = Color(0xFF0A2E4F);
  static const heroGlow = Color(0xFF0F4C75);

  // Core brand
  static const navy = Color(0xFF14507F);
  static const blue = Color(0xFF2178B5);
  static const teal = Color(0xFF2EC4B6);
  static const tealBright = Color(0xFF43E0D2);
  static const tealDeep = Color(0xFF15A99C);

  // Warm accents
  static const coral = Color(0xFFFF7A59);
  static const amber = Color(0xFFFFB020);

  // Light-section neutrals
  static const ink = Color(0xFF0B2239);
  static const slate = Color(0xFF3E5C76);
  static const muted = Color(0xFF5E7A8E);
  static const faint = Color(0xFF8AA5B5);
  static const border = Color(0xFFDCE7EF);
  static const bgSoft = Color(0xFFF4F9FB);
  static const tealTint = Color(0xFFE4F6F4);
  static const navyTint = Color(0xFFE8F1F8);
}

TextStyle _f(double size, FontWeight w, Color c,
        {double? height, double? spacing}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        color: c,
        height: height,
        letterSpacing: spacing);

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late final AnimationController _bg;    // hero backdrop drift (loops)
  late final AnimationController _intro; // hero entrance stagger
  late final ScrollController _scroll;
  // Scroll-to-top button visibility. A ValueNotifier so only the FAB rebuilds
  // on scroll — never the whole page (that was the source of the jank).
  final ValueNotifier<bool> _showTop = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(vsync: this, duration: const Duration(seconds: 26))
      ..repeat();
    _intro = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _scroll = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    final off = _scroll.offset;
    final show = off > 600;
    if (show != _showTop.value) _showTop.value = show;

    // Pause the looping hero backdrop once it's well off-screen so it stops
    // repainting a full-screen canvas every frame while reading lower sections.
    final heroGone = off > MediaQuery.of(context).size.height;
    if (heroGone) {
      if (_bg.isAnimating) _bg.stop();
    } else if (!_bg.isAnimating) {
      _bg.repeat();
    }
  }

  @override
  void dispose() {
    _bg.dispose();
    _intro.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _showTop.dispose();
    super.dispose();
  }

  // Breakpoints
  double get _w => MediaQuery.of(context).size.width;
  bool get _isMobile => _w < 700;
  bool get _isTablet => _w >= 700 && _w < 1080;
  double get _hPad => _isMobile ? 18 : (_isTablet ? 40 : 80);

  void _scrollTop() => _scroll.animateTo(0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            physics: const ClampingScrollPhysics(),
            // Cache a viewport of content on each side so scrolling doesn't
            // stutter while off-screen slivers build/paint.
            cacheExtent: 800,
            slivers: [
              const SliverToBoxAdapter(child: RepaintBoundary(child: HeaderNav())),
              SliverToBoxAdapter(child: RepaintBoundary(child: _hero())),
              SliverToBoxAdapter(child: RepaintBoundary(child: _marqueeStrip())),
              SliverToBoxAdapter(child: RepaintBoundary(child: _howItWorks())),
              SliverToBoxAdapter(child: RepaintBoundary(child: _ecosystem())),
              const SliverToBoxAdapter(
                  child: RepaintBoundary(child: SiteStatsBand())),
              SliverToBoxAdapter(child: RepaintBoundary(child: _rolesSplit())),
              SliverToBoxAdapter(child: RepaintBoundary(child: _finalCta())),
              const SliverToBoxAdapter(
                  child: RepaintBoundary(child: SiteFooter())),
            ],
          ),
          // Scroll-aware floating role CTAs (appear once you scroll past the hero).
          ScrollAwareCTAButtons(isDarkMode: false, scrollController: _scroll),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _showTop,
        builder: (_, showTop, _) => AnimatedScale(
          scale: showTop ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_B.teal, _B.navy]),
              boxShadow: [
                BoxShadow(
                    color: _B.teal.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _scrollTop,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child:
                  const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ghostBtn(String label, VoidCallback onTap, {bool light = false}) {
    final c = light ? Colors.white : _B.navy;
    return _Hoverable(
      builder: (hover) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
              horizontal: _isMobile ? 12 : 18, vertical: _isMobile ? 8 : 10),
          decoration: BoxDecoration(
            color: hover
                ? c.withValues(alpha: light ? 0.14 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withValues(alpha: 0.65), width: 1.4),
          ),
          child: Text(label,
              style: _f(_isMobile ? 12 : 14, FontWeight.w700, c)),
        ),
      ),
    );
  }

  // ═══ HERO ═════════════════════════════════════════════════════════════════
  Widget _hero() {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_B.heroDeep, _B.heroMid, _B.heroGlow],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Animated aurora + particle backdrop
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _bg,
                builder: (_, _) => CustomPaint(
                  painter: _HeroBackdropPainter(_bg.value),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          // Content
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenH * 0.86),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  _hPad, _isMobile ? 30 : 52, _hPad, _isMobile ? 40 : 56),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: LayoutBuilder(builder: (context, box) {
                    final stacked = box.maxWidth < 900;
                    return stacked
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _heroCopy(centered: true),
                              SizedBox(height: _isMobile ? 24 : 34),
                              SizedBox(
                                height: _isMobile
                                    ? (box.maxWidth * 0.9)
                                        .clamp(300.0, 380.0)
                                    : (box.maxWidth * 0.72)
                                        .clamp(360.0, 460.0),
                                child: _StepTheater(intro: _intro),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                  flex: 11, child: _heroCopy(centered: false)),
                              const SizedBox(width: 44),
                              Expanded(
                                flex: 9,
                                child: SizedBox(
                                  height: (box.maxWidth * 0.42)
                                      .clamp(420.0, 560.0),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned.fill(
                                          child: _StepTheater(intro: _intro)),
                                      Positioned(
                                        top: -18,
                                        right: -14,
                                        child: _Floaty(
                                          phase: 0.0,
                                          child: _miniCard(
                                              Icons.trending_up_rounded,
                                              '98% Success',
                                              'placement rate',
                                              _B.teal),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -16,
                                        left: -22,
                                        child: _Floaty(
                                          phase: 0.5,
                                          child: _miniCard(
                                              Icons.bolt_rounded,
                                              '24h Response',
                                              'average time',
                                              _B.amber),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                  }),
                ),
              ),
            ),
          ),
          // Scroll hint
          if (!_isMobile)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _bg,
                  builder: (_, _) => Transform.translate(
                    offset: Offset(
                        0, 5 * math.sin(_bg.value * 2 * math.pi * 6)),
                    child: Icon(Icons.keyboard_double_arrow_down_rounded,
                        color: Colors.white.withValues(alpha: 0.45), size: 26),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _heroCopy({required bool centered}) {
    final cross =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final align = centered ? TextAlign.center : TextAlign.start;
    final hSize = (_w * 0.042).clamp(30.0, 58.0);

    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge
        _introSlide(
          0.0,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _B.teal.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingDot(color: _B.tealBright),
                const SizedBox(width: 9),
                Flexible(
                  child: Text('AI-POWERED 4-STAGE HIRING ECOSYSTEM',
                      overflow: TextOverflow.ellipsis,
                      style: _f(_isMobile ? 10 : 11.5, FontWeight.w700,
                          _B.tealBright,
                          spacing: 1.6)),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: _isMobile ? 20 : 28),

        // Headline with rotating gradient word
        _introSlide(
          0.12,
          Column(
            crossAxisAlignment: cross,
            children: [
              Text('Where Exceptional Talent',
                  textAlign: align,
                  style: _f(hSize, FontWeight.w800, Colors.white,
                      height: 1.08, spacing: -1)),
              Wrap(
                alignment:
                    centered ? WrapAlignment.center : WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  Text('Meets ',
                      style: _f(hSize, FontWeight.w800, Colors.white,
                          height: 1.15, spacing: -1)),
                  _RotatingWord(
                    words: const [
                      'Opportunity.',
                      'Top Recruiters.',
                      'Great Careers.',
                      'Success.'
                    ],
                    style: _f(hSize, FontWeight.w800, Colors.white,
                        height: 1.15, spacing: -1),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: _isMobile ? 16 : 22),

        // Description
        _introSlide(
          0.24,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'One intelligent platform connecting candidates, recruiters and '
              'admins — from profile to placement. Build your CV with AI, get '
              'shortlisted, and land the right role faster.',
              textAlign: align,
              style: _f(_isMobile ? 13.5 : 16, FontWeight.w500,
                  Colors.white.withValues(alpha: 0.78),
                  height: 1.7),
            ),
          ),
        ),
        SizedBox(height: _isMobile ? 20 : 28),

        // Feature chips
        _introSlide(
          0.36,
          Wrap(
            alignment: centered ? WrapAlignment.center : WrapAlignment.start,
            spacing: 10,
            runSpacing: 10,
            children: [
              _heroChip(Icons.psychology_rounded, 'AI-Powered Matching',
                  _B.tealBright),
              _heroChip(Icons.speed_rounded, '3x Faster Hiring', _B.amber),
              _heroChip(Icons.verified_user_rounded, 'Admin Verified',
                  _B.coral),
            ],
          ),
        ),
        SizedBox(height: _isMobile ? 26 : 34),

        // CTA buttons
        _introSlide(
          0.48,
          Wrap(
            alignment: centered ? WrapAlignment.center : WrapAlignment.start,
            spacing: 14,
            runSpacing: 12,
            children: [
              _GlowButton(
                label: "I'm a Candidate",
                icon: Icons.person_add_rounded,
                onTap: () => context.go('/register?role=candidate'),
              ),
              _GlassButton(
                label: "I'm a Recruiter",
                icon: Icons.business_center_rounded,
                onTap: () => context.go('/register?role=recruiter'),
              ),
            ],
          ),
        ),
        SizedBox(height: _isMobile ? 30 : 42),

        // Stat row
        _introSlide(
          0.6,
          Wrap(
            alignment: centered ? WrapAlignment.center : WrapAlignment.start,
            spacing: 0,
            runSpacing: 14,
            children: [
              _heroStat('15', 'K+', 'Professionals Hired'),
              _statDivider(),
              _heroStat('98', '%', 'Success Rate'),
              _statDivider(),
              _heroStat('500', '+', 'Active Recruiters'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 22),
        color: Colors.white.withValues(alpha: 0.16),
      );

  Widget _heroStat(String number, String suffix, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CountUp(
          end: double.parse(number),
          suffix: suffix,
          style: _f(_isMobile ? 22 : 28, FontWeight.w800, Colors.white),
          accent: _B.tealBright,
        ),
        Text(label,
            style: _f(_isMobile ? 10.5 : 12, FontWeight.w600,
                Colors.white.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _heroChip(IconData icon, String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _isMobile ? 14 : 17, color: c),
          const SizedBox(width: 7),
          Text(label,
              style: _f(_isMobile ? 11 : 13, FontWeight.w600,
                  Colors.white.withValues(alpha: 0.92))),
        ],
      ),
    );
  }

  Widget _miniCard(IconData icon, String title, String sub, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _B.heroDeep.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: c),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: _f(13, FontWeight.w800, _B.ink)),
              Text(sub, style: _f(10.5, FontWeight.w600, _B.muted)),
            ],
          ),
        ],
      ),
    );
  }

  /// Staggered hero entrance: slide up + fade, offset by [delay] fraction.
  Widget _introSlide(double delay, Widget child) {
    final anim = CurvedAnimation(
      parent: _intro,
      curve: Interval(delay, (delay + 0.45).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, _) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
            offset: Offset(0, 26 * (1 - anim.value)), child: child),
      ),
      child: child,
    );
  }

  // ═══ MARQUEE STRIP ═══════════════════════════════════════════════════════
  Widget _marqueeStrip() {
    return Container(
      color: _B.heroDeep,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const _Marquee(
          items: [
            (Icons.flight_takeoff_rounded, 'Pilots'),
            (Icons.airline_seat_recline_extra_rounded, 'Cabin Crew'),
            (Icons.build_circle_rounded, 'Aircraft Engineers'),
            (Icons.connecting_airports_rounded, 'Ground Operations'),
            (Icons.radar_rounded, 'ATC Specialists'),
            (Icons.route_rounded, 'Flight Dispatchers'),
            (Icons.computer_rounded, 'IT Professionals'),
            (Icons.groups_rounded, 'HR Experts'),
          ],
        ),
      ),
    );
  }

  // ═══ SECTION HEAD ═══════════════════════════════════════════════════════
  Widget _sectionHead(String eyebrow, String title, String subtitle, Color c) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.withValues(alpha: 0.3)),
          ),
          child: Text(eyebrow,
              style: _f(11.5, FontWeight.w700, c, spacing: 1.4)),
        ),
        SizedBox(height: _isMobile ? 12 : 16),
        Text(title,
            textAlign: TextAlign.center,
            style: _f(_isMobile ? 26 : (_isTablet ? 34 : 42), FontWeight.w800,
                _B.ink,
                height: 1.1, spacing: -0.5)),
        SizedBox(height: _isMobile ? 8 : 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(subtitle,
              textAlign: TextAlign.center,
              style: _f(_isMobile ? 13.5 : 16, FontWeight.w500, _B.muted,
                  height: 1.6)),
        ),
      ],
    );
  }

  // ═══ HOW IT WORKS ═══════════════════════════════════════════════════════
  Widget _howItWorks() {
    final steps = const [
      (
        '01',
        'Build Your Profile',
        'Create a rich professional profile and let our AI craft a standout CV for you.',
        Icons.account_circle_rounded,
        _B.teal
      ),
      (
        '02',
        'Get Discovered',
        'Recruiters browse the verified talent pool and shortlist candidates like you.',
        Icons.search_rounded,
        _B.blue
      ),
      (
        '03',
        'Admin Review',
        'Every request is evaluated — interviews scheduled and training arranged.',
        Icons.verified_user_rounded,
        _B.amber
      ),
      (
        '04',
        'Get Hired',
        'Final selection and seamless onboarding.',
        Icons.workspace_premium_rounded,
        _B.coral
      ),
    ];
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(_hPad, _isMobile ? 48 : 96, _hPad, 0),
      child: _center(
        Column(
          children: [
            _Reveal(
              child: _sectionHead(
                  'HOW IT WORKS',
                  'A seamless 4-stage journey',
                  'From first profile to final hire — one intelligent ecosystem guides every step.',
                  _B.teal),
            ),
            SizedBox(height: _isMobile ? 28 : 52),
            _isMobile
                ? Column(
                    children: [
                      for (int i = 0; i < steps.length; i++)
                        _Reveal(
                          delayMs: i * 90,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _stepCard(steps[i].$1, steps[i].$2,
                                steps[i].$3, steps[i].$4, steps[i].$5),
                          ),
                        ),
                    ],
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < steps.length; i++) ...[
                          Expanded(
                            child: _Reveal(
                              delayMs: i * 110,
                              child: _stepCard(steps[i].$1, steps[i].$2,
                                  steps[i].$3, steps[i].$4, steps[i].$5),
                            ),
                          ),
                          if (i < steps.length - 1) const SizedBox(width: 16),
                        ],
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard(
      String n, String title, String desc, IconData icon, Color c) {
    return _Hoverable(
      builder: (hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, hover ? -6 : 0, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: hover ? c.withValues(alpha: 0.04) : _B.bgSoft,
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: hover ? c.withValues(alpha: 0.45) : _B.border),
          boxShadow: hover
              ? [
                  BoxShadow(
                      color: c.withValues(alpha: 0.16),
                      blurRadius: 26,
                      offset: const Offset(0, 12)),
                ]
              : null,
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
                        colors: [c, Color.lerp(c, Colors.white, 0.25)!]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: c.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const Spacer(),
                Text(n,
                    style: _f(32, FontWeight.w800, c.withValues(alpha: 0.22))),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: _f(17, FontWeight.w700, _B.ink)),
            const SizedBox(height: 6),
            Text(desc, style: _f(13, FontWeight.w500, _B.muted, height: 1.6)),
          ],
        ),
      ),
    );
  }

  // ═══ ECOSYSTEM ══════════════════════════════════════════════════════════
  Widget _ecosystem() {
    final portals = [
      (
        '01',
        'Candidate Portal',
        'Your Career, Your Control',
        _B.teal,
        Icons.person_rounded,
        const [
          (Icons.account_circle_rounded, 'Profile Builder',
              'Create comprehensive professional profiles'),
          (Icons.description_rounded, 'CV Generator',
              'AI-powered resume creation tools'),
          (Icons.workspace_premium_rounded, 'Skill Showcase',
              'Highlight expertise and certifications'),
          (Icons.public_rounded, 'Public Portfolio',
              'Share your journey with recruiters'),
        ]
      ),
      (
        '02',
        'Recruiter Portal',
        'Find Perfect Candidates Fast',
        _B.navy,
        Icons.business_rounded,
        const [
          (Icons.search_rounded, 'Candidate Search',
              'Browse the qualified talent pool'),
          (Icons.checklist_rounded, 'Bulk Selection',
              'Select multiple candidates at once'),
          (Icons.send_rounded, 'Request Management',
              'Submit hiring requests to admin'),
          (Icons.auto_graph_rounded, 'Request Tracker',
              'Realtime recruitment request tracking'),
        ]
      ),
      (
        '03',
        'Admin Portal',
        'End-to-End Hiring Management',
        _B.coral,
        Icons.admin_panel_settings_rounded,
        const [
          (Icons.rate_review_rounded, 'Request Review',
              'Evaluate recruiter requests'),
          (Icons.event_rounded, 'Interview Scheduling',
              'Organize and conduct interviews'),
          (Icons.school_rounded, 'Candidate Training',
              'Skill development and preparation'),
          (Icons.how_to_reg_rounded, 'Final Selection',
              'Complete hiring and onboarding'),
        ]
      ),
    ];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, _B.bgSoft],
        ),
      ),
      padding: EdgeInsets.fromLTRB(_hPad, _isMobile ? 48 : 96, _hPad, 0),
      child: _center(
        Column(
          children: [
            _Reveal(
              child: _sectionHead(
                  'COMPLETE ECOSYSTEM',
                  'Three portals, one journey',
                  'Powerful, purpose-built experiences for every role in the hiring pipeline.',
                  _B.navy),
            ),
            SizedBox(height: _isMobile ? 28 : 52),
            _isMobile || _isTablet
                ? Column(
                    children: [
                      for (int i = 0; i < portals.length; i++)
                        _Reveal(
                          delayMs: i * 90,
                          child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _portalCard(portals[i])),
                        ),
                    ],
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < portals.length; i++) ...[
                          Expanded(
                            child: _Reveal(
                                delayMs: i * 120,
                                child: _portalCard(portals[i])),
                          ),
                          if (i < portals.length - 1)
                            const SizedBox(width: 20),
                        ],
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _portalCard(
      (String, String, String, Color, IconData,
          List<(IconData, String, String)>) p) {
    final c = p.$4;
    return _Hoverable(
      builder: (hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, hover ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: hover ? c.withValues(alpha: 0.45) : _B.border),
          boxShadow: [
            BoxShadow(
                color: (hover ? c : _B.ink)
                    .withValues(alpha: hover ? 0.16 : 0.05),
                blurRadius: hover ? 30 : 16,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c, Color.lerp(c, _B.heroDeep, 0.45)!],
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
                    child: Icon(p.$5, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  Text(p.$1,
                      style: _f(30, FontWeight.w800,
                          Colors.white.withValues(alpha: 0.35))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.$2, style: _f(19, FontWeight.w800, _B.ink)),
                  const SizedBox(height: 3),
                  Text(p.$3, style: _f(13, FontWeight.w600, c)),
                  const SizedBox(height: 18),
                  for (final it in p.$6)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(it.$1, size: 15, color: c),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.$2,
                                    style:
                                        _f(13.5, FontWeight.w700, _B.ink)),
                                Text(it.$3,
                                    style: _f(12, FontWeight.w500, _B.muted,
                                        height: 1.4)),
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
  // ═══ ROLES SPLIT ════════════════════════════════════════════════════════
  Widget _rolesSplit() {
    Widget candidate = _Reveal(
      child: _roleCard(
          'Join as Candidate',
          'Build your profile, generate an AI CV and get discovered by top recruiters.',
          Icons.flight_takeoff_rounded,
          const [_B.teal, _B.tealDeep],
          () => context.go('/register?role=candidate')),
    );
    Widget recruiter = _Reveal(
      delayMs: 120,
      child: _roleCard(
          'Join as Recruiter',
          'Search a verified talent pool and hire the best professionals, fast.',
          Icons.business_center_rounded,
          const [_B.blue, _B.navy],
          () => context.go('/register?role=recruiter')),
    );
    return Container(
      color: _B.bgSoft,
      padding: EdgeInsets.fromLTRB(_hPad, _isMobile ? 48 : 96, _hPad, 0),
      child: _center(
        _isMobile
            ? Column(
                children: [candidate, const SizedBox(height: 16), recruiter])
            : Row(children: [
                Expanded(child: candidate),
                const SizedBox(width: 20),
                Expanded(child: recruiter),
              ]),
      ),
    );
  }

  Widget _roleCard(String title, String subtitle, IconData icon,
      List<Color> grad, VoidCallback onTap) {
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
              colors: grad,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: grad.first.withValues(alpha: hover ? 0.45 : 0.25),
                  blurRadius: hover ? 32 : 18,
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
                  style: _f(_isMobile ? 20 : 24, FontWeight.w800,
                      Colors.white)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: _f(14, FontWeight.w500,
                      Colors.white.withValues(alpha: 0.9),
                      height: 1.5)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('Get started',
                      style: _f(14, FontWeight.w700, Colors.white)),
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

  // ═══ FINAL CTA ══════════════════════════════════════════════════════════
  Widget _finalCta() {
    return Container(
      color: _B.bgSoft,
      padding: EdgeInsets.fromLTRB(
          _hPad, _isMobile ? 48 : 96, _hPad, _isMobile ? 48 : 96),
      child: _center(
        _Reveal(
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: _isMobile ? 22 : 60,
                vertical: _isMobile ? 38 : 64),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, _B.tealTint, _B.navyTint],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: _B.teal.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Text('Ready to transform your hiring?',
                    textAlign: TextAlign.center,
                    style: _f(_isMobile ? 26 : 40, FontWeight.w800, _B.ink,
                        height: 1.15, spacing: -0.5)),
                SizedBox(height: _isMobile ? 10 : 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Text(
                      'Join thousands of professionals and recruiters already building the future of hiring with Maha HR Services.',
                      textAlign: TextAlign.center,
                      style: _f(_isMobile ? 14 : 17, FontWeight.w500,
                          _B.muted,
                          height: 1.6)),
                ),
                SizedBox(height: _isMobile ? 24 : 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    _GlowButton(
                      label: 'Get Started Free',
                      icon: Icons.rocket_launch_rounded,
                      onTap: () => context.go('/register'),
                    ),
                    _ghostBtn('Explore Pricing', () => context.go('/pricing')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _center(Widget child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: child,
        ),
      );
}

// ═══ STEP THEATER — glassmorphic Lottie carousel with progress ═══════════════
class _StepTheater extends StatefulWidget {
  const _StepTheater({required this.intro});
  final AnimationController intro;

  @override
  State<_StepTheater> createState() => _StepTheaterState();
}

class _StepTheaterState extends State<_StepTheater>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    ('Candidates Apply for Jobs', 'Profiles built, CVs generated by AI',
        'images/1.json', _B.tealBright),
    ('Recruiters Shortlist Talent', 'Requests submitted for review',
        'images/2.json', _B.amber),
    ('Admin Reviews Candidates', 'Every request carefully evaluated',
        'images/3.json', _B.coral),
    ('Interview, Train & Handover', 'Seamless onboarding to success',
        'images/4.json', Color(0xFF7DBBE8)),
  ];

  late final AnimationController _progress;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _index = (_index + 1) % _steps.length);
          _progress.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _jumpTo(int i) {
    setState(() => _index = i);
    _progress.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];
    final accent = step.$4;
    final isMobile = MediaQuery.of(context).size.width < 700;
    final pad = isMobile ? 14.0 : 20.0;
    final scale = CurvedAnimation(
        parent: widget.intro,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutBack));

    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.0).animate(scale),
      child: FadeTransition(
        opacity: CurvedAnimation(
            parent: widget.intro, curve: const Interval(0.25, 0.7)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, pad - 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(28),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.14)),
                boxShadow: [
                  BoxShadow(
                      color: _B.heroDeep.withValues(alpha: 0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 20)),
                ],
              ),
              child: Column(
                children: [
                  // Progress segments (tappable)
                  Row(
                    children: [
                      for (int i = 0; i < _steps.length; i++) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _jumpTo(i),
                            child: Container(
                              height: 14,
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: AnimatedBuilder(
                                animation: _progress,
                                builder: (_, _) {
                                  final double fill = i < _index
                                      ? 1
                                      : (i == _index ? _progress.value : 0);
                                  return Stack(
                                    children: [
                                      Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: fill,
                                        child: Container(
                                          height: 4,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [
                                              _B.teal,
                                              _B.tealBright
                                            ]),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        if (i < _steps.length - 1) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Step chip
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: accent.withValues(alpha: 0.45)),
                        ),
                        child: Text('STEP ${_index + 1}',
                            style: _f(10.5, FontWeight.w800, accent,
                                spacing: 1.2)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: Text(step.$1,
                              key: ValueKey('t$_index'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  _f(14.5, FontWeight.w700, Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Text(step.$2,
                          key: ValueKey('s$_index'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _f(12, FontWeight.w500,
                              Colors.white.withValues(alpha: 0.6))),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Lottie stage — bounded, never overflows
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.94, end: 1.0)
                              .animate(anim),
                          child: child,
                        ),
                      ),
                      child: Container(
                        key: ValueKey('l$_index'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.09),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: Lottie.asset(
                          step.$3,
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
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
}

// ═══ HERO BACKDROP — aurora blobs + drifting particles ═══════════════════════
class _Particle {
  final double x, y, r, speed, phase;
  final bool teal;
  const _Particle(this.x, this.y, this.r, this.speed, this.phase, this.teal);
}

class _HeroBackdropPainter extends CustomPainter {
  final double t;
  _HeroBackdropPainter(this.t);

  static final List<_Particle> _particles = _gen();
  static List<_Particle> _gen() {
    final rnd = math.Random(7);
    return List.generate(
      64,
      (_) => _Particle(
        rnd.nextDouble(),
        rnd.nextDouble(),
        0.8 + rnd.nextDouble() * 2.2,
        0.02 + rnd.nextDouble() * 0.07,
        rnd.nextDouble(),
        rnd.nextDouble() > 0.4,
      ),
    );
  }

  void _blob(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
          c, r, [color, color.withValues(alpha: 0)], [0.0, 1.0]);
    canvas.drawCircle(c, r, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final a = t * 2 * math.pi;

    // Aurora blobs drifting on slow orbits
    _blob(
        canvas,
        Offset(w * 0.82 + 40 * math.sin(a), h * 0.18 + 30 * math.cos(a)),
        w * 0.30,
        _B.teal.withValues(alpha: 0.16));
    _blob(
        canvas,
        Offset(w * 0.12 + 34 * math.cos(a * 0.8),
            h * 0.78 + 26 * math.sin(a * 0.8)),
        w * 0.26,
        _B.blue.withValues(alpha: 0.18));
    _blob(
        canvas,
        Offset(w * 0.55 + 50 * math.sin(a * 0.6 + 1.7),
            h * 0.05 + 20 * math.cos(a * 0.6)),
        w * 0.18,
        _B.coral.withValues(alpha: 0.08));
    _blob(
        canvas,
        Offset(w * 0.38 + 30 * math.cos(a * 1.2),
            h * 0.95 + 24 * math.sin(a * 1.2)),
        w * 0.22,
        _B.tealDeep.withValues(alpha: 0.12));

    // Flight-path arcs
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.05);
    final p1 = Path()
      ..moveTo(-40, h * 0.7)
      ..quadraticBezierTo(w * 0.4, h * 0.2, w + 40, h * 0.55);
    final p2 = Path()
      ..moveTo(-40, h * 0.35)
      ..quadraticBezierTo(w * 0.55, h * 0.9, w + 40, h * 0.25);
    canvas.drawPath(p1, arc);
    canvas.drawPath(p2, arc);

    // Drifting, twinkling particles
    for (final p in _particles) {
      final y = (p.y - t * p.speed * 4) % 1.0;
      final yy = y < 0 ? y + 1.0 : y;
      final twinkle =
          0.22 + 0.30 * (0.5 + 0.5 * math.sin(a * 2 + p.phase * 6.28));
      final color = p.teal
          ? _B.tealBright.withValues(alpha: twinkle)
          : Colors.white.withValues(alpha: twinkle * 0.8);
      canvas.drawCircle(Offset(p.x * w, yy * h), p.r, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_HeroBackdropPainter old) => old.t != t;
}

// ═══ ROTATING GRADIENT WORD ══════════════════════════════════════════════════
class _RotatingWord extends StatefulWidget {
  const _RotatingWord({required this.words, required this.style});
  final List<String> words;
  final TextStyle style;

  @override
  State<_RotatingWord> createState() => _RotatingWordState();
}

class _RotatingWordState extends State<_RotatingWord> {
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted) setState(() => _i = (_i + 1) % widget.words.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 0.55), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: ShaderMask(
        key: ValueKey(_i),
        shaderCallback: (bounds) => const LinearGradient(
          colors: [_B.tealBright, _B.teal, _B.coral],
        ).createShader(bounds),
        child: Text(widget.words[_i],
            style: widget.style.copyWith(color: Colors.white)),
      ),
    );
  }
}

// ═══ PULSING DOT ═════════════════════════════════════════════════════════════
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: widget.color.withValues(alpha: 0.7),
                blurRadius: 4 + 8 * _c.value,
                spreadRadius: 1 + 2 * _c.value),
          ],
        ),
      ),
    );
  }
}

// ═══ FLOATY — gentle vertical sine float ═════════════════════════════════════
class _Floaty extends StatefulWidget {
  const _Floaty({required this.child, this.phase = 0});
  final Widget child;
  final double phase;

  @override
  State<_Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<_Floaty>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(
            0, 8 * math.sin((_c.value + widget.phase) * 2 * math.pi)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

// ═══ GLOW BUTTON (primary gradient CTA) ══════════════════════════════════════
class _GlowButton extends StatefulWidget {
  const _GlowButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.compact = false,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool compact;

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final hPad = widget.compact ? (isMobile ? 13.0 : 18.0) : 26.0;
    final vPad = widget.compact ? (isMobile ? 9.0 : 11.0) : 16.0;
    final fs = widget.compact ? (isMobile ? 12.0 : 14.0) : 15.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_hover ? 1.03 : 1.0),
          transformAlignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hover
                  ? [_B.tealBright, _B.teal, _B.blue]
                  : [_B.teal, _B.tealDeep, _B.navy],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: _B.teal.withValues(alpha: _hover ? 0.55 : 0.3),
                  blurRadius: _hover ? 24 : 14,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label,
                  style: _f(fs, FontWeight.w700, Colors.white)),
              if (widget.icon != null) ...[
                const SizedBox(width: 8),
                AnimatedSlide(
                  offset: Offset(_hover ? 0.25 : 0, 0),
                  duration: const Duration(milliseconds: 180),
                  child: Icon(widget.icon,
                      size: fs + 3, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══ GLASS BUTTON (secondary CTA on dark hero) ═══════════════════════════════
class _GlassButton extends StatefulWidget {
  const _GlassButton(
      {required this.label, required this.onTap, this.icon});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _hover ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.white.withValues(alpha: _hover ? 0.6 : 0.3),
                width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(widget.label,
                  style: _f(15, FontWeight.w700, Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══ MARQUEE — infinite auto-scrolling ticker ════════════════════════════════
class _Marquee extends StatefulWidget {
  const _Marquee({required this.items});
  final List<(IconData, String)> items;

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 22))
        ..repeat();
  final GlobalKey _rowKey = GlobalKey();
  double _rowW = 1400;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _rowKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && mounted && box.size.width > 0) {
        setState(() => _rowW = box.size.width);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _row({Key? key}) => Row(
        key: key,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final it in widget.items) ...[
            Icon(it.$1, size: 17, color: _B.tealBright.withValues(alpha: 0.8)),
            const SizedBox(width: 9),
            Text(it.$2,
                style: _f(13.5, FontWeight.w600,
                    Colors.white.withValues(alpha: 0.6),
                    spacing: 0.6)),
            const SizedBox(width: 18),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: _B.coral.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 18),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.translate(
          offset: Offset(-(_c.value * _rowW), 0),
          child: child,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [_row(key: _rowKey), _row(), _row()],
        ),
      ),
    );
  }
}

// ═══ COUNT-UP NUMBER ═════════════════════════════════════════════════════════
class _CountUp extends StatelessWidget {
  const _CountUp(
      {required this.end,
      required this.suffix,
      required this.style,
      required this.accent});
  final double end;
  final String suffix;
  final TextStyle style;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: end),
      builder: (_, v, _) => RichText(
        text: TextSpan(
          text: v.round().toString(),
          style: style,
          children: [
            TextSpan(text: suffix, style: style.copyWith(color: accent)),
          ],
        ),
      ),
    );
  }
}

// ═══ SCROLL REVEAL — fades/slides in when scrolled into view ═════════════════
class _Reveal extends StatefulWidget {
  const _Reveal({required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));
  ScrollPosition? _pos;
  bool _shown = false;
  double _lastCheckedPixels = -1e9;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pos = Scrollable.maybeOf(context)?.position;
      _pos?.addListener(_onScroll);
      _check();
    });
  }

  // Gate the expensive geometry walk: only re-check after ~24px of scroll so
  // we do at most one render-object lookup per 24px instead of one per frame.
  void _onScroll() {
    final p = _pos?.pixels ?? 0;
    if ((p - _lastCheckedPixels).abs() < 24) return;
    _lastCheckedPixels = p;
    _check();
  }

  void _check() {
    if (_shown || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final vh = _pos?.viewportDimension ?? MediaQuery.of(context).size.height;
    if (top < vh * 0.92) {
      _shown = true;
      _pos?.removeListener(_onScroll);
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _pos?.removeListener(_onScroll);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
            offset: Offset(0, 34 * (1 - anim.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

// ═══ HOVER HELPER ════════════════════════════════════════════════════════════
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
