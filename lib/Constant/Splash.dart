import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'CTA_Dynamic.dart';
import 'hero.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maha Services - Smart End-To-End Hiring Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, brightness: Brightness.light),
      darkTheme: ThemeData(primarySwatch: Colors.indigo, brightness: Brightness.dark),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _workflowController;
  late Animation<double> _workflowAnimation;
  late AnimationController _rotationController;
  late AnimationController _controller;
  late AnimationController _contentAnimationController;
  late AnimationController _particleAnimationController;

  bool isDarkMode = false;
  late ScrollController _scrollController;
  bool _showScrollToTop = false;

  // Cached styles
  late TextStyle _logoTextStyle;

  @override
  void initState() {
    super.initState();
    _initializeTextStyles();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
    _rotationController =
    AnimationController(duration: const Duration(seconds: 30), vsync: this)..repeat();
    _particleAnimationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _contentAnimationController =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _workflowController =
        AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _workflowAnimation =
        CurvedAnimation(parent: _workflowController, curve: Curves.easeInOut);
    _workflowController.forward();

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    _scrollController = ScrollController()
      ..addListener(() {
        final show = _scrollController.offset > 400;
        if (show != _showScrollToTop) {
          setState(() => _showScrollToTop = show);
        }
      });
  }

  void _initializeTextStyles() {
    _logoTextStyle = GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14);
  }

  @override
  void dispose() {
    _controller.dispose();
    _workflowController.dispose();
    _fadeController.dispose();
    _rotationController.dispose();
    _particleAnimationController.dispose();
    _contentAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
      _initializeTextStyles();
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;
    final outerH = isMobile ? 12.0 : (isTablet ? 30.0 : 50.0);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.transparent,
      body: Stack(
        children: [
          // Animated grid background
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: _OptimizedGridPainter(_controller.value),
                  size: Size.infinite,
                  willChange: true,
                ),
              ),
            ),
          ),

          // Main scroll content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(outerH, 0, outerH, 0),
                  child: Column(
                    children: [
                      _buildTopBar(),
                      HeroSection(isDarkMode: isDarkMode),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildFeaturesSection()),
              SliverToBoxAdapter(child: _buildFooter()),
            ],
          ),

          // Floating CTA
          ScrollAwareCTAButtons(
            isDarkMode: isDarkMode,
            scrollController: _scrollController,
          ),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: _showScrollToTop ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton(
          onPressed: _scrollToTop,
          backgroundColor: const Color(0xFF6366F1),
          elevation: 4,
          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
        ),
      ),
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    if (!kIsWeb) return const SizedBox.shrink();
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;
    final hPad = isMobile ? 4.0 : (isTablet ? 20.0 : 65.0);
    final vPad = isMobile ? 6.0 : 10.0;

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: isMobile
            ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildEnhancedLogo(),
            _buildNavigation(),
            _buildThemeToggle(),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildEnhancedLogo(),
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedLogo() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final logoSize = isMobile ? 40.0 : 100.0;
    final cacheSize = isMobile ? 80 : 200;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: ClipOval(
        child: Image.asset(
          'images/logo.png',
          fit: BoxFit.fill,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;

    if (isMobile) {
      const double btnHPad = 10;
      const double btnVPad = 7;
      const double btnFont = 11;
      const double iconSz = 11;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedButton(
            onPressed: () => context.go('/login'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: btnHPad, vertical: btnVPad),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border:
                Border.all(color: const Color(0xFF6366F1), width: 1.5),
              ),
              child: Text('Login',
                  style: _logoTextStyle.copyWith(
                      color: const Color(0xFF6366F1), fontSize: btnFont)),
            ),
          ),
          const SizedBox(width: 6),
          _AnimatedButton(
            onPressed: () => context.go('/register'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: btnHPad, vertical: btnVPad),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Get Started',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: btnFont,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(width: 3),
                  const Icon(Icons.arrow_forward_rounded,
                      size: iconSz, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildNavItem(
              title: 'Pricing',
              icon: Icons.payments_outlined,
              route: '/pricing',
              isActive: false),
        ],
      );
    }

    // Tablet & Desktop
    final navBtnHPad = isTablet ? 14.0 : 24.0;
    final navBtnVPad = isTablet ? 8.0 : 12.0;
    final navBtnFont = isTablet ? 12.0 : 14.0;
    final navIconSz = isTablet ? 14.0 : 16.0;

    return Row(
      children: [
        _buildNavItem(
            title: 'View Pricing',
            icon: Icons.payments_outlined,
            route: '/pricing',
            isActive: false),
        SizedBox(width: isTablet ? 20 : 40),
        _AnimatedButton(
          onPressed: () => context.go('/login'),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: navBtnHPad, vertical: navBtnVPad),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6366F1), width: 2),
            ),
            child: Text('Login',
                style: _logoTextStyle.copyWith(
                    color: const Color(0xFF6366F1),
                    fontSize: navBtnFont)),
          ),
        ),
        SizedBox(width: isTablet ? 8 : 16),
        _AnimatedButton(
          onPressed: () => context.go('/register'),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: navBtnHPad, vertical: navBtnVPad),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Get Started',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: navBtnFont,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                SizedBox(width: isTablet ? 4 : 8),
                Icon(Icons.arrow_forward_rounded,
                    size: navIconSz, color: Colors.white),
              ],
            ),
          ),
        ),
        SizedBox(width: isTablet ? 8 : 16),
        _AnimatedButton(
          onPressed: () => context.go('/admin'),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: navBtnHPad, vertical: navBtnVPad),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Admin Panel',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: navBtnFont,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                SizedBox(width: isTablet ? 4 : 8),
                Icon(Icons.arrow_forward_rounded,
                    size: navIconSz, color: Colors.white),
              ],
            ),
          ),
        ),
        SizedBox(width: isTablet ? 8 : 15),
        _buildThemeToggle(),
      ],
    );
  }

  Widget _buildNavItem({
    required String title,
    required IconData icon,
    required String route,
    bool isActive = false,
  }) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;
    final primaryColor = const Color(0xFF6366F1);
    final inactiveColor =
    isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return StatefulBuilder(builder: (context, setItemState) {
      bool isHovered = false;
      return MouseRegion(
        onEnter: (_) => setItemState(() => isHovered = true),
        onExit: (_) => setItemState(() => isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => context.go(route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : (isTablet ? 10 : 14),
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? primaryColor.withOpacity(0.08)
                  : (isHovered
                  ? primaryColor.withOpacity(0.04)
                  : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: isMobile ? 13 : (isTablet ? 16.0 : 20.0),
                    color: isActive || isHovered ? primaryColor : inactiveColor),
                SizedBox(width: isMobile ? 4 : (isTablet ? 6 : 10)),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 11 : (isTablet ? 13.0 : 14.5),
                    fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive || isHovered
                        ? (isDarkMode
                        ? Colors.white
                        : const Color(0xFF1E293B))
                        : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildThemeToggle() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final pad = isMobile ? 6.0 : 10.0;
    final iconSize = isMobile ? 14.0 : 20.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: toggleTheme,
        child: Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF334155)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF475569)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Icon(
            isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDarkMode
                ? const Color(0xFFFBBF24)
                : const Color(0xFF6366F1),
            size: iconSize,
          ),
        ),
      ),
    );
  }

  // ─── Features Section ─────────────────────────────────────────────────────────

  Widget _buildFeaturesSection() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;
    final hPad = isMobile ? 16.0 : (isTablet ? 30.0 : 80.0);

    final features = [
      FeaturePortal(
        number: '01',
        title: 'Candidate Portal',
        subtitle: 'Your Career, Your Control',
        color: const Color(0xFF6366F1),
        icon: Icons.person_rounded,
        items: [
          FeatureItem('Profile Builder', 'Create comprehensive professional profiles', Icons.account_circle_rounded),
          FeatureItem('CV Generator', 'AI-powered resume creation tools', Icons.description_rounded),
          FeatureItem('Skill Showcase', 'Highlight expertise and certifications', Icons.workspace_premium_rounded),
          FeatureItem('Public Portfolio', 'Share your journey with recruiters', Icons.public_rounded),
        ],
      ),
      FeaturePortal(
        number: '02',
        title: 'Recruiter Portal',
        subtitle: 'Find Perfect Candidates Fast',
        color: const Color(0xFF10B981),
        icon: Icons.business_rounded,
        items: [
          FeatureItem('Candidate Search', 'Browse qualified talent pool', Icons.search_rounded),
          FeatureItem('Bulk Selection', 'Select multiple candidates at once', Icons.checklist_rounded),
          FeatureItem('Request Management', 'Submit hiring requests to admin', Icons.send_rounded),
          FeatureItem('Request Tracker', 'Realtime Recruitment Request Tracking', Icons.auto_graph),
        ],
      ),
      FeaturePortal(
        number: '03',
        title: 'Admin Portal',
        subtitle: 'End-to-End Hiring Management',
        color: const Color(0xFFF59E0B),
        icon: Icons.admin_panel_settings_rounded,
        items: [
          FeatureItem('Request Review', 'Evaluate recruiter requests', Icons.rate_review_rounded),
          FeatureItem('Interview Scheduling', 'Organize and conduct interviews', Icons.event_rounded),
          FeatureItem('Candidate Training', 'Skill development and preparation', Icons.school_rounded),
          FeatureItem('Final Selection', 'Complete hiring and onboarding', Icons.how_to_reg_rounded),
        ],
      ),
    ];

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 0),
        child: Column(
          children: [
            _buildSectionHeader(
              'COMPLETE ECOSYSTEM',
              'Complete Hiring Ecosystem',
              'Three powerful portals, one seamless journey',
              Icons.apps_rounded,
            ),
            SizedBox(height: isMobile ? 20 : 40),
            isMobile
                ? Column(
              children: [
                for (int i = 0; i < features.length; i++) ...[
                  RepaintBoundary(child: _buildFeatureCard(features[i])),
                  if (i < features.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Icon(Icons.arrow_downward,
                          color: isDarkMode
                              ? const Color(0xFF475569)
                              : const Color(0xFFD1D5DB),
                          size: 24),
                    ),
                ],
              ],
            )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < features.length; i++) ...[
                  Expanded(
                    child: RepaintBoundary(
                        child: _buildFeatureCard(features[i])),
                  ),
                  if (i < features.length - 1)
                    Padding(
                      padding: EdgeInsets.only(top: isTablet ? 60 : 100),
                      child: Icon(Icons.arrow_forward,
                          color: isDarkMode
                              ? const Color(0xFF475569)
                              : const Color(0xFFD1D5DB),
                          size: isTablet ? 28 : 40),
                    ),
                ],
              ],
            ),
            SizedBox(height: isMobile ? 20 : 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(FeaturePortal portal) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;
    final cardPad = isMobile ? 16.0 : (isTablet ? 20.0 : 32.0);
    final numberFontSize = isMobile ? 12.0 : 16.0;
    final numberHPad = isMobile ? 10.0 : 16.0;
    final numberVPad = isMobile ? 5.0 : 8.0;
    final iconContainerPad = isMobile ? 8.0 : 14.0;
    final portalIconSize = isMobile ? 22.0 : 32.0;
    final titleFontSize = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
    final subtitleFontSize = isMobile ? 12.0 : 14.0;
    final itemIconSize = isMobile ? 16.0 : 22.0;
    final itemIconPad = isMobile ? 7.0 : 10.0;
    final itemTitleFontSize = isMobile ? 13.0 : 15.0;
    final itemDescFontSize = isMobile ? 11.0 : 13.0;

    return Container(
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 24),
        border: Border.all(color: portal.color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: portal.color.withOpacity(0.08),
            blurRadius: isMobile ? 12 : 30,
            offset: Offset(0, isMobile ? 4 : 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: numberHPad, vertical: numberVPad),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [portal.color, portal.color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(portal.number,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: numberFontSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              Container(
                padding: EdgeInsets.all(iconContainerPad),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    portal.color.withOpacity(0.1),
                    portal.color.withOpacity(0.05),
                  ]),
                  borderRadius:
                  BorderRadius.circular(isMobile ? 10 : 16),
                ),
                child: Icon(portal.icon,
                    color: portal.color, size: portalIconSize),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 24),
          Text(portal.title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.white
                      : const Color(0xFF1F2937))),
          SizedBox(height: isMobile ? 3 : 8),
          Text(portal.subtitle,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: subtitleFontSize,
                  color: isDarkMode
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                  height: 1.5)),
          SizedBox(height: isMobile ? 14 : 28),
          ...portal.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                  bottom:
                  i < portal.items.length - 1 ? (isMobile ? 10 : 16) : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(itemIconPad),
                    decoration: BoxDecoration(
                      color: portal.color.withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(isMobile ? 8 : 12),
                      border: Border.all(
                          color: portal.color.withOpacity(0.2)),
                    ),
                    child: Icon(item.icon,
                        color: portal.color, size: itemIconSize),
                  ),
                  SizedBox(width: isMobile ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: itemTitleFontSize,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF1F2937))),
                        const SizedBox(height: 2),
                        Text(item.description,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: itemDescFontSize,
                                color: isDarkMode
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF9CA3AF),
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [const Color(0xFF111827), const Color(0xFF000000)]
                : [const Color(0xFF1F2937), const Color(0xFF111827)],
          ),
        ),
        child: Column(
          children: [
            _buildStatsShowcase(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (isTablet ? 30 : 50),
                vertical: 10,
              ),
              child: isMobile
                  ? _buildFooterBrand()
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildFooterBrand()),
                ],
              ),
            ),
            _buildFooterBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterBrand() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final titleFontSize = isMobile ? 18.0 : 28.0;
    final descFontSize = isMobile ? 12.0 : 14.0;
    final iconPad = isMobile ? 7.0 : 10.0;
    final iconSize = isMobile ? 16.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MAHA SERVICES',
            style: GoogleFonts.plusJakartaSans(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        SizedBox(height: isMobile ? 8 : 16),
        Text(
          'Revolutionizing recruitment through an intelligent 4-stage hiring ecosystem. Connecting talent with opportunity seamlessly.',
          style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF9CA3AF),
              fontSize: descFontSize,
              height: 1.8),
        ),
        SizedBox(height: isMobile ? 14 : 24),
        Row(
          children: [
            _buildSocialIcon(Icons.facebook, const Color(0xFF1877F2), iconPad, iconSize),
            const SizedBox(width: 12),
            _buildSocialIcon(Icons.link, const Color(0xFF0A66C2), iconPad, iconSize),
            const SizedBox(width: 12),
            _buildSocialIcon(Icons.mail_rounded, const Color(0xFFEA4335), iconPad, iconSize),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, double pad, double size) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }

  Widget _buildFooterBottom() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;
    final hPad = isMobile ? 16.0 : (isTablet ? 40.0 : 80.0);
    final vPad = isMobile ? 14.0 : 30.0;
    final copyrightFont = isMobile ? 11.0 : 13.0;
    final aiFont = isMobile ? 10.0 : 12.0;
    final aiIconSize = isMobile ? 13.0 : 16.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF374151), width: 1)),
      ),
      child: isMobile
          ? Column(
        children: [
          Text('© 2026 Maha Services. All rights reserved.',
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF6B7280),
                  fontSize: copyrightFont)),
          const SizedBox(height: 10),
          _buildAIBadge(aiFont, aiIconSize),
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('© 2025 Maha Services. All rights reserved.',
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF6B7280),
                  fontSize: copyrightFont)),
          _buildAIBadge(aiFont, aiIconSize),
        ],
      ),
    );
  }

  Widget _buildAIBadge(double fontSize, double iconSize) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: iconSize < 14 ? 10 : 12,
          vertical: iconSize < 14 ? 5 : 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_rounded,
              color: const Color(0xFF6366F1), size: iconSize),
          const SizedBox(width: 4),
          Text('Powered by AI',
              style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF6366F1),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      String badge, String title, String subtitle, IconData icon) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;
    final badgeFont = isMobile ? 10.0 : 13.0;
    final badgeIconSize = isMobile ? 13.0 : 18.0;
    final badgeHPad = isMobile ? 10.0 : 20.0;
    final badgeVPad = isMobile ? 6.0 : 10.0;
    final titleFont = isMobile ? 22.0 : (isTablet ? 34.0 : 48.0);
    final subtitleFont = isMobile ? 13.0 : 18.0;

    return FadeTransition(
      opacity: _workflowAnimation,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: badgeHPad, vertical: badgeVPad),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFF6366F1).withOpacity(0.2),
                const Color(0xFF8B5CF6).withOpacity(0.2),
              ]),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.5),
                  width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    color: const Color(0xFF7233FB),
                    size: badgeIconSize),
                SizedBox(width: isMobile ? 6 : 10),
                Text(badge,
                    style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF7233FB),
                        fontSize: badgeFont,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 12 : 24),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: titleFont,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode
                      ? Colors.white
                      : const Color(0xFF081D69),
                  letterSpacing: -1)),
          SizedBox(height: isMobile ? 8 : 16),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: subtitleFont,
                  color: isDarkMode
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _buildStatsShowcase() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;
    final vPad = isMobile ? 24.0 : 50.0;
    final hPad = isMobile ? 16.0 : (isTablet ? 30.0 : 80.0);
    final titleFont = isMobile ? 22.0 : (isTablet ? 32.0 : 42.0);
    final subtitleFont = isMobile ? 12.0 : 18.0;
    final provenFont = isMobile ? 10.0 : 12.0;
    final statSpacing = isMobile ? 10.0 : (isTablet ? 20.0 : 50.0);

    return Container(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: isMobile ? 5 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text('⚡ PROVEN SUCCESS',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: provenFont,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.5)),
          ),
          SizedBox(height: isMobile ? 12 : 20),
          Text('Trusted by Industry Leaders',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: titleFont,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          SizedBox(height: isMobile ? 8 : 12),
          Text('Real numbers, real impact - see how we transform hiring',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: subtitleFont,
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500)),
          SizedBox(height: isMobile ? 20 : 70),
          isMobile
              ? Wrap(
            spacing: statSpacing,
            runSpacing: statSpacing,
            alignment: WrapAlignment.center,
            children: [
              _buildSuccessMetric('15K+', 'Successfully Hired', Icons.people_rounded),
              _buildSuccessMetric('98%', 'Success Rate', Icons.trending_up_rounded),
              _buildSuccessMetric('24h', 'Avg. Response', Icons.schedule_rounded),
              _buildSuccessMetric('500+', 'Active Recruiters', Icons.business_rounded),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSuccessMetric('15K+', 'Successfully Hired', Icons.people_rounded),
              SizedBox(width: statSpacing),
              _buildSuccessMetric('98%', 'Success Rate', Icons.trending_up_rounded),
              SizedBox(width: statSpacing),
              _buildSuccessMetric('24h', 'Avg. Response', Icons.schedule_rounded),
              SizedBox(width: statSpacing),
              _buildSuccessMetric('500+', 'Active Recruiters', Icons.business_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMetric(String value, String label, IconData icon) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final hPad = isMobile ? 12.0 : 24.0;
    final vPad = isMobile ? 8.0 : 16.0;
    final iconSize = isMobile ? 16.0 : 24.0;
    final valueFont = isMobile ? 16.0 : 24.0;
    final labelFont = isMobile ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.6), size: iconSize),
          SizedBox(width: isMobile ? 8 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: valueFont,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: labelFont,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Animated Button ──────────────────────────────────────────────────────────

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _AnimatedButton({required this.onPressed, required this.child});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── Data Models ──────────────────────────────────────────────────────────────

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

// ─── Optimized Grid Painter ───────────────────────────────────────────────────

class _OptimizedGridPainter extends CustomPainter {
  final double animationValue;

  static final Paint _baseGridPaint = Paint()
    ..color = const Color(0xFF4A90E2).withOpacity(0.15)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;

  static final Paint _beamPaint = Paint()
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  static final Paint _intersectionPaint = Paint()
    ..color = const Color(0xFFFFFFFF).withOpacity(0.3)
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
            const Color(0xFFF7E6FF).withOpacity(0.4),
            const Color(0xFFF7E6FF).withOpacity(0.9),
            const Color(0xFFF7E6FF).withOpacity(0.4),
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
            const Color(0xFFE6EFFF).withOpacity(0.4),
            const Color(0xFFE6EFFF).withOpacity(0.9),
            const Color(0xFFE6EFFF).withOpacity(0.4),
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

    if (animationValue % 0.1 < 0.05) {
      vi = 0;
      for (double x = -gridSize + (offset % gridSize);
      x < size.width + gridSize;
      x += gridSize * 2) {
        hi = 0;
        for (double y = -gridSize + (offset % gridSize);
        y < size.height + gridSize;
        y += gridSize * 2) {
          final bpv = (animationValue * 2 + vi * 0.3) % 1.0;
          final bph = (animationValue * 1.5 + hi * 0.25) % 1.0;
          if ((bpv * size.height - y).abs() < 50 &&
              (bph * size.width - x).abs() < 50) {
            canvas.drawCircle(Offset(x, y), 8, _intersectionPaint);
          }
          hi++;
        }
        vi++;
      }
    }
  }

  @override
  bool shouldRepaint(_OptimizedGridPainter oldDelegate) => true;
}