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
    _buttonTextStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      color: Colors.white,
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
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.transparent,
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
                  padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
                  child: Column(
                    children: [
                      _buildTopBar(),
                      HeroSection(isDarkMode: isDarkMode),
                    ],
                  ),
                ),
              ),

              /// ───────── FEATURES ─────────
              SliverToBoxAdapter(
                child: _buildFeaturesSection(),
              ),

              /// ───────── FOOTER ─────────
              SliverToBoxAdapter(
                child: _buildFooter(),
              ),
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
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 65, vertical: 10),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0x00f9fafb) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_buildEnhancedLogo(), _buildNavigation()],
        ),
      ),
    );
  }

  Widget _buildEnhancedLogo() {
    return Row(
      children: [
        Image.asset(
          'images/logo.png',
          width: 100,
          height: 100,
          fit: BoxFit.fill,
          cacheWidth: 200, // Web optimization
          cacheHeight: 200,
        ),
        const SizedBox(width: 14),
      ],
    );
  }

  Widget _buildNavigation() {
    return Row(
      children: [
        _buildNavItem('Features', Icons.stars_rounded),
        const SizedBox(width: 32),
        _buildNavItem('Workflow', Icons.account_tree_rounded),
        const SizedBox(width: 32),
        _buildNavItem('Pricing', Icons.payments_rounded, ),
        const SizedBox(width: 40),
        _AnimatedButton(
          onPressed: () => context.go('/login'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6366F1), width: 2),
            ),
            child: Text("Login", style: _logoTextStyle.copyWith(color: const Color(0xFF6366F1))),
          ),
        ),
        const SizedBox(width: 16),
        _AnimatedButton(
          onPressed: () => context.go('/register'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Get Started", style: _buttonTextStyle),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildThemeToggle(),
      ],
    );
  }

  Widget _buildNavItem(String title, IconData icon) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.go('/pricing');
        },
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: _navItemStyle.copyWith(
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: toggleTheme,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Icon(
            isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: isDarkMode ? const Color(0xFFFBBF24) : const Color(0xFF6366F1),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
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
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0x00f9fafb), const Color(0x00f9fafb)]
                : [const Color(0x00f9fafb), const Color(0x00f9fafb), const Color(0x00f9fafb)],
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
            const SizedBox(height: 40),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < features.length; i++) ...[
                  Expanded(child: RepaintBoundary(child: _buildFeatureCard(features[i]))),
                  if (i < features.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Icon(
                        Icons.arrow_forward,
                        color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFD1D5DB),
                        size: 40,
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(FeaturePortal portal) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: portal.color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: portal.color.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [portal.color, portal.color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  portal.number,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      portal.color.withOpacity(0.1),
                      portal.color.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(portal.icon, color: portal.color, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            portal.title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            portal.subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ...portal.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: i < portal.items.length - 1 ? 16 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: portal.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: portal.color.withOpacity(0.2)),
                    ),
                    child: Icon(item.icon, color: portal.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
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
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildFooterBrand()),
                      const SizedBox(width: 80),
                      Expanded(
                        child: _buildFooterColumn('For Candidates', [
                          'Create Profile',
                          'Build CV',
                          'Browse Jobs',
                          'Career Resources',
                        ]),
                      ),
                      const SizedBox(width: 60),
                      Expanded(
                        child: _buildFooterColumn('For Recruiters', [
                          'Find Talent',
                          'Submit Requests',
                          'Pricing Plans',
                          'Success Stories',
                        ]),
                      ),
                      const SizedBox(width: 60),
                      Expanded(
                        child: _buildFooterColumn('Company', [
                          'About Us',
                          'Contact',
                          'Careers',
                          'Privacy Policy',
                        ]),
                      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MAHA SERVICES',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Revolutionizing recruitment through an intelligent 4-stage hiring ecosystem. Connecting talent with opportunity seamlessly.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF9CA3AF),
            fontSize: 14,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 24),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildFooterColumn(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ...items.map(
              (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF6366F1), size: 12),
                  const SizedBox(width: 8),
                  Text(
                    item,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 13,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 30),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF374151), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '© 2025 Maha Services. All rights reserved.',
            style: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontSize: 13),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_rounded, color: Color(0xFF6366F1), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Powered by AI',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6366F1),
                    fontSize: 12,
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

  Widget _buildSectionHeader(String badge, String title, String subtitle, IconData icon) {
    return FadeTransition(
      opacity: _workflowAnimation,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.2),
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFF7233FB), size: 18),
                const SizedBox(width: 10),
                Text(
                  badge,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF7233FB),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : const Color(0xFF081D69),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsShowcase() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0x00f9fafb), const Color(0x00f9fafb), const Color(0x00f9fafb)]
              : [const Color(0x00f9fafb), const Color(0x00f9fafb), const Color(0x00f9fafb)],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              '⚡ PROVEN SUCCESS',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Trusted by Industry Leaders',
            style: GoogleFonts.poppins(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Real numbers, real impact - see how we transform hiring',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 70),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSuccessMetric('15K+', 'Successfully Hired', Icons.people_rounded),
              const SizedBox(width: 50),
              _buildSuccessMetric('98%', 'Success Rate', Icons.trending_up_rounded),
              const SizedBox(width: 50),
              _buildSuccessMetric('24h', 'Avg. Response', Icons.schedule_rounded),
              const SizedBox(width: 50),
              _buildSuccessMetric('500+', 'Active Recruiters', Icons.business_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMetric(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.6), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
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
    for (double x = -gridSize + (offset % gridSize); x < size.width + gridSize; x += gridSize) {
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
    for (double y = -gridSize + (offset % gridSize); y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _baseGridPaint);

      if (horizontalIndex % beamUpdateInterval == 0) {
        final beamProgress = (animationValue * 1.5 + horizontalIndex * 0.25) % 1.0;
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
    if (animationValue % 0.1 < 0.05) { // Only draw every 10th frame
      verticalIndex = 0;
      for (double x = -gridSize + (offset % gridSize); x < size.width + gridSize; x += gridSize * 2) {
        horizontalIndex = 0;
        for (double y = -gridSize + (offset % gridSize); y < size.height + gridSize; y += gridSize * 2) {
          final beamProgressV = (animationValue * 2 + verticalIndex * 0.3) % 1.0;
          final beamProgressH = (animationValue * 1.5 + horizontalIndex * 0.25) % 1.0;
          final verticalBeamY = beamProgressV * size.height;
          final horizontalBeamX = beamProgressH * size.width;

          if ((verticalBeamY - y).abs() < 50 && (horizontalBeamX - x).abs() < 50) {
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