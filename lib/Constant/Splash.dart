import 'dart:math' as math;
import 'dart:ui' as ui;

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
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _workflowController;
  late Animation<double> _workflowAnimation;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  late AnimationController _controller;
  late AnimationController _contentAnimationController;
  late AnimationController _particleAnimationController;

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color charcoalGray = Colors.black87;

  bool isDarkMode = false;
  final int _activeStage = 0;

  // Cached text styles to avoid recreation
  late TextStyle _logoTextStyle;
  late TextStyle _navItemStyle;
  late TextStyle _buttonTextStyle;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    // Initialize text styles
    _initializeTextStyles();

    // Reduced duration for smoother animation on web
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _particleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _workflowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _workflowAnimation = CurvedAnimation(
      parent: _workflowController,
      curve: Curves.easeInOut,
    );
    _workflowController.forward();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    _scrollController = ScrollController();
  }

  void _initializeTextStyles() {
    _logoTextStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );
    _navItemStyle = GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );
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
      _initializeTextStyles(); // Refresh text styles
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final outerH = isMobile ? 12.0 : (isTablet ? 30.0 : 50.0);

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0F172A)
          : Colors.transparent,
      body: Stack(
        children: [
          // Optimized animated grid with RepaintBoundary
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _OptimizedGridPainter(_controller.value),
                    size: Size.infinite,
                    willChange: true, // Web optimization hint
                  );
                },
              ),
            ),
          ),

          // Content with ListView.builder for better performance
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              /// ───────── Top Bar + Hero ─────────
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

              /// ───────── FEATURES ─────────
              SliverToBoxAdapter(child: _buildFeaturesSection()),

              /// ───────── FOOTER ─────────
              SliverToBoxAdapter(child: _buildFooter()),
            ],
          ),

          // Floating CTA buttons
          ScrollAwareCTAButtons(
            isDarkMode: isDarkMode,
            scrollController: _scrollController,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final hPad = isMobile ? 8.0 : (isTablet ? 20.0 : 65.0);
    final vPad = isMobile ? 6.0 : 10.0;

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0x00f9fafb) : Colors.transparent,
        ),
        child: isMobile
            ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildEnhancedLogo(),   _buildNavigation(), _buildThemeToggle()],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_buildEnhancedLogo(), _buildNavigation()],
              ),
      ),
    );
  }

  Widget _buildEnhancedLogo() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final logoSize = isMobile ? 50.0 : 100.0;
    final cacheSize = isMobile ? 100 : 200;

    return Row(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ClipOval(
            child: Image.asset(
              'images/logo.png',
              fit: BoxFit.fill,
              cacheWidth: cacheSize,
              cacheHeight: cacheSize,
            ),
          ),
        ),
        SizedBox(width: isMobile ? 6 : 14),
      ],
    );
  }

  Widget _buildNavigation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (isMobile) {
      // On mobile: compact row with just Login + Get Started + Admin, no nav items
      final btnHPad = 10.0;
      final btnVPad = 8.0;
      final btnFontSize = 11.0;
      final iconSize = 12.0;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _AnimatedButton(
              onPressed: () => context.go('/login'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: btnHPad, vertical: btnVPad),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                ),
                child: Text(
                  "Login",
                  style: _logoTextStyle.copyWith(
                    color: const Color(0xFF6366F1),
                    fontSize: btnFontSize,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _AnimatedButton(
              onPressed: () => context.go('/register'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: btnHPad, vertical: btnVPad),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Get Started", style: GoogleFonts.poppins(
                      fontSize: btnFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            _AnimatedButton(
              onPressed: () => context.go('/admin'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: btnHPad, vertical: btnVPad),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "A",
                      style: GoogleFonts.poppins(
                        fontSize: btnFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            _buildNavItem(title: 'ViewPricing',icon: Icons.payments_outlined,route: '/pricing', isActive: false)

          ],
        ),
      );
    }

    // Tablet & Desktop
    final navSpacing = isTablet ? 16.0 : 32.0;
    final btnHPad = isTablet ? 14.0 : 24.0;
    final btnVPad = isTablet ? 8.0 : 12.0;
    final btnFontSize = isTablet ? 12.0 : 14.0;
    final iconSize = isTablet ? 14.0 : 16.0;

    return Row(
      children: [
        // _buildNavItem('Features', Icons.stars_rounded),
        // SizedBox(width: navSpacing),
        // _buildNavItem('Workflow', Icons.account_tree_rounded),
        // SizedBox(width: navSpacing),
        _buildNavItem(title: 'View Pricing',icon: Icons.payments_outlined,route: '/pricing', isActive: false),

        SizedBox(width: isTablet ? 20 : 40),
        _AnimatedButton(
          onPressed: () => context.go('/login'),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: btnHPad, vertical: btnVPad),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6366F1), width: 2),
            ),
            child: Text(
              "Login",
              style: _logoTextStyle.copyWith(
                color: const Color(0xFF6366F1),
                fontSize: btnFontSize,
              ),
            ),
          ),
        ),
        SizedBox(width: isTablet ? 8 : 16),
        _AnimatedButton(
          onPressed: () => context.go('/register'),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: btnHPad, vertical: btnVPad),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Get Started",  style: GoogleFonts.poppins(
                  fontSize: btnFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),),
                SizedBox(width: isTablet ? 4 : 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: iconSize,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: isTablet ? 8 : 16),
        _AnimatedButton(
          onPressed: () => context.go('/admin'),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: btnHPad, vertical: btnVPad),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Admin Panel",
                  style: GoogleFonts.poppins(
                    fontSize: btnFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: isTablet ? 4 : 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: iconSize,
                  color: Colors.white,
                ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Design Constants
    final primaryColor = const Color(0xFF6366F1); // Modern Indigo
    final inactiveColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: StatefulBuilder( // Using StatefulBuilder for localized hover state
        builder: (context, setItemState) {
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
                  horizontal: isTablet ? 10 : 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  // Sublte "Ghost" background on hover or active
                  color: isActive
                      ? primaryColor.withOpacity(0.08)
                      : (isHovered ? primaryColor.withOpacity(0.04) : Colors.transparent),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        icon,
                        key: ValueKey(isActive),
                        size: isTablet ? 16.0 : 20.0,
                        color: isActive || isHovered ? primaryColor : inactiveColor,
                      ),
                    ),
                    SizedBox(width: isTablet ? 6 : 10),
                    // Responsive Text
                    Text(
                      title,
                      style: GoogleFonts.inter( // Using Inter for better web readability
                        fontSize: isTablet ? 13.0 : 14.5,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive || isHovered
                            ? (isDarkMode ? Colors.white : const Color(0xFF1E293B))
                            : inactiveColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }




  Widget _buildThemeToggle() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final pad = isMobile ? 6.0 : 10.0;
    final iconSize = isMobile ? 16.0 : 20.0;

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

  Widget _buildFeaturesSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final hPad = isMobile ? 16.0 : (isTablet ? 30.0 : 80.0);

    final features = [
      FeaturePortal(
        number: '01',
        title: 'Candidate Portal',
        subtitle: 'Your Career, Your Control',
        color: const Color(0xFF6366F1),
        icon: Icons.person_rounded,
        items: [
          FeatureItem(
            'Profile Builder',
            'Create comprehensive professional profiles',
            Icons.account_circle_rounded,
          ),
          FeatureItem(
            'CV Generator',
            'AI-powered resume creation tools',
            Icons.description_rounded,
          ),
          FeatureItem(
            'Skill Showcase',
            'Highlight expertise and certifications',
            Icons.workspace_premium_rounded,
          ),
          FeatureItem(
            'Public Portfolio',
            'Share your journey with recruiters',
            Icons.public_rounded,
          ),
        ],
      ),
      FeaturePortal(
        number: '02',
        title: 'Recruiter Portal',
        subtitle: 'Find Perfect Candidates Fast',
        color: const Color(0xFF10B981),
        icon: Icons.business_rounded,
        items: [
          FeatureItem(
            'Candidate Search',
            'Browse qualified talent pool',
            Icons.search_rounded,
          ),
          FeatureItem(
            'Bulk Selection',
            'Select multiple candidates at once',
            Icons.checklist_rounded,
          ),
          FeatureItem(
            'Request Management',
            'Submit hiring requests to admin',
            Icons.send_rounded,
          ),
          FeatureItem(
            'Request Tracker',
            'Realtime Recruitment Request Tracking',
            Icons.auto_graph,
          ),
        ],
      ),
      FeaturePortal(
        number: '03',
        title: 'Admin Portal',
        subtitle: 'End-to-End Hiring Management',
        color: const Color(0xFFF59E0B),
        icon: Icons.admin_panel_settings_rounded,
        items: [
          FeatureItem(
            'Request Review',
            'Evaluate recruiter requests',
            Icons.rate_review_rounded,
          ),
          FeatureItem(
            'Interview Scheduling',
            'Organize and conduct interviews',
            Icons.event_rounded,
          ),
          FeatureItem(
            'Candidate Training',
            'Skill development and preparation',
            Icons.school_rounded,
          ),
          FeatureItem(
            'Final Selection',
            'Complete hiring and onboarding',
            Icons.how_to_reg_rounded,
          ),
        ],
      ),
    ];

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0x00f9fafb), const Color(0x00f9fafb)]
                : [
              const Color(0x00f9fafb),
              const Color(0x00f9fafb),
              const Color(0x00f9fafb),
            ],
          ),
        ),
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
                        RepaintBoundary(
                          child: _buildFeatureCard(features[i]),
                        ),
                        if (i < features.length - 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Icon(
                              Icons.arrow_downward,
                              color: isDarkMode
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFD1D5DB),
                              size: 28,
                            ),
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
                            child: _buildFeatureCard(features[i]),
                          ),
                        ),
                        if (i < features.length - 1)
                          Padding(
                            padding: EdgeInsets.only(top: isTablet ? 60 : 100),
                            child: Icon(
                              Icons.arrow_forward,
                              color: isDarkMode
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFD1D5DB),
                              size: isTablet ? 28 : 40,
                            ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final cardPad = isMobile ? 18.0 : (isTablet ? 20.0 : 32.0);
    final numberFontSize = isMobile ? 13.0 : 16.0;
    final numberHPad = isMobile ? 12.0 : 16.0;
    final numberVPad = isMobile ? 6.0 : 8.0;
    final iconContainerPad = isMobile ? 10.0 : 14.0;
    final portalIconSize = isMobile ? 24.0 : 32.0;
    final titleFontSize = isMobile ? 18.0 : (isTablet ? 20.0 : 24.0);
    final subtitleFontSize = isMobile ? 12.0 : 14.0;
    final itemIconSize = isMobile ? 18.0 : 22.0;
    final itemIconPad = isMobile ? 8.0 : 10.0;
    final itemTitleFontSize = isMobile ? 13.0 : 15.0;
    final itemDescFontSize = isMobile ? 11.0 : 13.0;

    return Container(
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
        border: Border.all(color: portal.color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: portal.color.withOpacity(0.08),
            blurRadius: isMobile ? 16 : 30,
            offset: Offset(0, isMobile ? 6 : 10),
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
                  horizontal: numberHPad,
                  vertical: numberVPad,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [portal.color, portal.color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  portal.number,
                  style: GoogleFonts.poppins(
                    fontSize: numberFontSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(iconContainerPad),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      portal.color.withOpacity(0.1),
                      portal.color.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                ),
                child: Icon(portal.icon, color: portal.color, size: portalIconSize),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Text(
            portal.title,
            style: GoogleFonts.poppins(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            portal.subtitle,
            style: GoogleFonts.poppins(
              fontSize: subtitleFontSize,
              color: isDarkMode
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 28),
          ...portal.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < portal.items.length - 1 ? (isMobile ? 10 : 16) : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(itemIconPad),
                    decoration: BoxDecoration(
                      color: portal.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                      border: Border.all(color: portal.color.withOpacity(0.2)),
                    ),
                    child: Icon(item.icon, color: portal.color, size: itemIconSize),
                  ),
                  SizedBox(width: isMobile ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: itemTitleFontSize,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: GoogleFonts.poppins(
                            fontSize: itemDescFontSize,
                            color: isDarkMode
                                ? const Color(0xFF64748B)
                                : const Color(0xFF9CA3AF),
                            height: 1.4,
                          ),
                        ),
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

  Widget _buildFooter() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

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
              child: Column(
                children: [
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFooterBrand(),
                            // const SizedBox(height: 24),
                            // _buildFooterColumn('For Candidates', [
                            //   'Create Profile',
                            //   'Build CV',
                            //   'Browse Jobs',
                            //   'Career Resources',
                            // ]),
                            // const SizedBox(height: 20),
                            // _buildFooterColumn('For Recruiters', [
                            //   'Find Talent',
                            //   'Submit Requests',
                            //   'Pricing Plans',
                            //   'Success Stories',
                            // ]),
                            // const SizedBox(height: 20),
                            // _buildFooterColumn('Company', [
                            //   'About Us',
                            //   'Contact',
                            //   'Careers',
                            //   'Privacy Policy',
                            // ]),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildFooterBrand()),
                            // SizedBox(width: isTablet ? 30 : 80),
                            // Expanded(
                            //   child: _buildFooterColumn('For Candidates', [
                            //     'Create Profile',
                            //     'Build CV',
                            //     'Browse Jobs',
                            //     'Career Resources',
                            //   ]),
                            // ),
                            // SizedBox(width: isTablet ? 20 : 60),
                            // Expanded(
                            //   child: _buildFooterColumn('For Recruiters', [
                            //     'Find Talent',
                            //     'Submit Requests',
                            //     'Pricing Plans',
                            //     'Success Stories',
                            //   ]),
                            // ),
                            // SizedBox(width: isTablet ? 20 : 60),
                            // Expanded(
                            //   child: _buildFooterColumn('Company', [
                            //     'About Us',
                            //     'Contact',
                            //     'Careers',
                            //     'Privacy Policy',
                            //   ]),
                            // ),
                          ],
                        ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final titleFontSize = isMobile ? 20.0 : 28.0;
    final descFontSize = isMobile ? 12.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MAHA SERVICES',
          style: GoogleFonts.poppins(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isMobile ? 10 : 16),
        Text(
          'Revolutionizing recruitment through an intelligent 4-stage hiring ecosystem. Connecting talent with opportunity seamlessly.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF9CA3AF),
            fontSize: descFontSize,
            height: 1.8,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),
        Row(
          children: [
            _buildSocialIcon(Icons.facebook, const Color(0xFF1877F2)),
            const SizedBox(width: 12),
            _buildSocialIcon(Icons.link, const Color(0xFF0A66C2)),
            const SizedBox(width: 12),
            _buildSocialIcon(Icons.mail_rounded, const Color(0xFFEA4335)),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final pad = isMobile ? 8.0 : 10.0;
    final iconSize = isMobile ? 16.0 : 20.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }

  Widget _buildFooterColumn(String title, List<String> items) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final titleFontSize = isMobile ? 14.0 : 16.0;
    final itemFontSize = isMobile ? 12.0 : 13.0;
    final arrowSize = isMobile ? 10.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 20),
        ...items.map(
              (item) => Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 10 : 14),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF6366F1),
                    size: arrowSize,
                  ),
                  SizedBox(width: isMobile ? 6 : 8),
                  Text(
                    item,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF9CA3AF),
                      fontSize: itemFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterBottom() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final hPad = isMobile ? 16.0 : (isTablet ? 40.0 : 80.0);
    final vPad = isMobile ? 16.0 : 30.0;
    final copyrightFontSize = isMobile ? 11.0 : 13.0;
    final aiFontSize = isMobile ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF374151), width: 1)),
      ),
      child: isMobile
          ? Column(
              children: [
                Text(
                  '© 2026 Maha Services. All rights reserved.',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6B7280),
                    fontSize: copyrightFontSize,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        color: Color(0xFF6366F1),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Powered by AI',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6366F1),
                          fontSize: aiFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© 2025 Maha Services. All rights reserved.',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6B7280),
                    fontSize: copyrightFontSize,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.psychology_rounded,
                        color: Color(0xFF6366F1),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Powered by AI',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6366F1),
                          fontSize: aiFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(
      String badge,
      String title,
      String subtitle,
      IconData icon,
      ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final badgeFontSize = isMobile ? 10.0 : 13.0;
    final badgeIconSize = isMobile ? 14.0 : 18.0;
    final badgeHPad = isMobile ? 12.0 : 20.0;
    final badgeVPad = isMobile ? 6.0 : 10.0;
    final titleFontSize = isMobile ? 24.0 : (isTablet ? 34.0 : 48.0);
    final subtitleFontSize = isMobile ? 13.0 : 18.0;

    return FadeTransition(
      opacity: _workflowAnimation,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: badgeHPad, vertical: badgeVPad),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.2),
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFF7233FB), size: badgeIconSize),
                SizedBox(width: isMobile ? 6 : 10),
                Text(
                  badge,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF7233FB),
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 14 : 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : const Color(0xFF081D69),
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: subtitleFontSize,
              color: isDarkMode
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsShowcase() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final vPad = isMobile ? 24.0 : 50.0;
    final hPad = isMobile ? 16.0 : (isTablet ? 30.0 : 80.0);
    final titleFontSize = isMobile ? 24.0 : (isTablet ? 32.0 : 42.0);
    final subtitleFontSize = isMobile ? 13.0 : 18.0;
    final provenFontSize = isMobile ? 10.0 : 12.0;
    final statSpacing = isMobile ? 12.0 : (isTablet ? 20.0 : 50.0);

    return Container(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
            const Color(0x00f9fafb),
            const Color(0x00f9fafb),
            const Color(0x00f9fafb),
          ]
              : [
            const Color(0x00f9fafb),
            const Color(0x00f9fafb),
            const Color(0x00f9fafb),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20,
              vertical: isMobile ? 5 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              '⚡ PROVEN SUCCESS',
              style: GoogleFonts.poppins(
                fontSize: provenFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 12 : 20),
          Text(
            'Trusted by Industry Leaders',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            'Real numbers, real impact - see how we transform hiring',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: subtitleFontSize,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 70),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final hPad = isMobile ? 14.0 : 24.0;
    final vPad = isMobile ? 10.0 : 16.0;
    final iconSize = isMobile ? 18.0 : 24.0;
    final valueFontSize = isMobile ? 18.0 : 24.0;
    final labelFontSize = isMobile ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
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
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: labelFontSize,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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

// Data Models
class WorkflowStage {
  final String step;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> details;

  WorkflowStage({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.details,
  });
}

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

// Optimized Grid Painter with reduced complexity
class _OptimizedGridPainter extends CustomPainter {
  final double animationValue;

  // Cache for paint objects
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

    // Reduce the number of beam calculations for web performance
    final beamUpdateInterval = 2; // Only update beams every 2 grid lines

    // Draw vertical lines
    int verticalIndex = 0;
    for (
    double x = -gridSize + (offset % gridSize);
    x < size.width + gridSize;
    x += gridSize
    ) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _baseGridPaint);

      if (verticalIndex % beamUpdateInterval == 0) {
        final beamProgress = (animationValue * 2 + verticalIndex * 0.3) % 1.0;
        final beamStart = beamProgress * size.height;
        final beamLength = size.height * 0.4;

        final verticalGradient = ui.Gradient.linear(
          Offset(x, beamStart - beamLength / 2),
          Offset(x, beamStart + beamLength / 2),
          [
            Colors.transparent,
            const Color(0xFFF7E6FF).withOpacity(0.4),
            const Color(0xFFF7E6FF).withOpacity(0.9),
            const Color(0xFFF7E6FF).withOpacity(0.4),
            Colors.transparent,
          ],
          [0.0, 0.2, 0.5, 0.8, 1.0],
        );

        _beamPaint.shader = verticalGradient;
        canvas.drawLine(
          Offset(x, math.max(0, beamStart - beamLength / 2)),
          Offset(x, math.min(size.height, beamStart + beamLength / 2)),
          _beamPaint,
        );
      }
      verticalIndex++;
    }

    // Draw horizontal lines
    int horizontalIndex = 0;
    for (
    double y = -gridSize + (offset % gridSize);
    y < size.height + gridSize;
    y += gridSize
    ) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _baseGridPaint);

      if (horizontalIndex % beamUpdateInterval == 0) {
        final beamProgress =
            (animationValue * 1.5 + horizontalIndex * 0.25) % 1.0;
        final beamStart = beamProgress * size.width;
        final beamLength = size.width * 0.6;

        final horizontalGradient = ui.Gradient.linear(
          Offset(beamStart - beamLength / 2, y),
          Offset(beamStart + beamLength / 2, y),
          [
            Colors.transparent,
            const Color(0xFFE6EFFF).withOpacity(0.4),
            const Color(0xFFE6EFFF).withOpacity(0.9),
            const Color(0xFFE6EFFF).withOpacity(0.4),
            Colors.transparent,
          ],
          [0.0, 0.2, 0.5, 0.8, 1.0],
        );

        _beamPaint.shader = horizontalGradient;
        canvas.drawLine(
          Offset(math.max(0, beamStart - beamLength / 2), y),
          Offset(math.min(size.width, beamStart + beamLength / 2), y),
          _beamPaint,
        );
      }
      horizontalIndex++;
    }

    // Simplified intersection glow (reduce calculations)
    if (animationValue % 0.1 < 0.05) {
      // Only draw every 10th frame
      verticalIndex = 0;
      for (
      double x = -gridSize + (offset % gridSize);
      x < size.width + gridSize;
      x += gridSize * 2
      ) {
        horizontalIndex = 0;
        for (
        double y = -gridSize + (offset % gridSize);
        y < size.height + gridSize;
        y += gridSize * 2
        ) {
          final beamProgressV =
              (animationValue * 2 + verticalIndex * 0.3) % 1.0;
          final beamProgressH =
              (animationValue * 1.5 + horizontalIndex * 0.25) % 1.0;
          final verticalBeamY = beamProgressV * size.height;
          final horizontalBeamX = beamProgressH * size.width;

          if ((verticalBeamY - y).abs() < 50 &&
              (horizontalBeamX - x).abs() < 50) {
            canvas.drawCircle(Offset(x, y), 8, _intersectionPaint);
          }
          horizontalIndex++;
        }
        verticalIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(_OptimizedGridPainter oldDelegate) => true;
}
