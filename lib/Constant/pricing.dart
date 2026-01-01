import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'Header_Nav.dart';

class PremiumPricingPage extends StatefulWidget {
  const PremiumPricingPage({super.key});

  @override
  State<PremiumPricingPage> createState() => _PremiumPricingPageState();
}

class _PremiumPricingPageState extends State<PremiumPricingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _gridController;

  bool _isAnnual = true;
  int _hoveredCardIndex = -1;
  String _selectedUserType = 'Job Seeker'; // Job Seeker, Recruiter, Admin

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )
      ..forward();

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )
      ..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )
      ..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      body: Stack(
        children: [

          // Animated grid pattern background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gridController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _GridPainter(_gridController.value),
                  size: Size.infinite,
                );
              },
            ),
          ),

          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _fadeController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _slideController,
                            curve: Curves.easeOutCubic,
                          )),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Column(
                              children: [
                                const HeaderNav(),

                                const SizedBox(height: 20),
                                _buildHeader(),
                                const SizedBox(height: 40),
                                _buildUserTypeSelector(),
                                const SizedBox(height: 40),
                                _buildBillingToggle(),
                                const SizedBox(height: 64),
                                _buildPricingCards(),
                                const SizedBox(height: 80),
                                _buildFAQSection(),
                                const SizedBox(height: 80),
                                _buildFooter(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PRICING PLANS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Choose Your Perfect Plan',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            letterSpacing: -1.5,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 600,
          child: Text(
            'Tailored solutions for job seekers, recruiters, and admins. Start free, scale as you grow.',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.6,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeSelector() {
    final userTypes = [
      {'label': 'Job Seeker', 'icon': Icons.person_search},
      {'label': 'Recruiter', 'icon': Icons.business_center},
      {'label': 'Admin', 'icon': Icons.admin_panel_settings},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: userTypes.map((type) {
          final isSelected = _selectedUserType == type['label'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _selectedUserType = type['label'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      size: 20,
                      color: isSelected ? Colors.white : const Color(
                          0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(
                            0xFF64748B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('Monthly', !_isAnnual, () {
            setState(() => _isAnnual = false);
          }),
          const SizedBox(width: 4),
          _buildToggleOption('Annual', _isAnnual, () {
            setState(() => _isAnnual = true);
          }, showBadge: true),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isActive, VoidCallback onTap,
      {bool showBadge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF64748B),
                letterSpacing: -0.2,
              ),
            ),
            if (showBadge) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Save 20%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        final plans = _getPlansForUserType();

        if (isMobile) {
          return Column(
            children: plans
                .asMap()
                .entries
                .map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildPricingCard(entry.key, entry.value),
              );
            }).toList(),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: plans
              .asMap()
              .entries
              .map((entry) {
            return Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: entry.key == 1 ? 12 : 0,
                ),
                child: _buildPricingCard(entry.key, entry.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getPlansForUserType() {
    switch (_selectedUserType) {
      case 'Job Seeker':
        return [
          {
            'title': 'Free',
            'subtitle': 'For casual job seekers',
            'price': '0',
            'period': 'Forever free',
            'features': [
              {'text': 'Manual Profile Creation', 'included': true},
              {'text': 'Browse Job Listings', 'included': true},
              {'text': 'Up to 3 CV AI Analyses', 'included': true},
              {'text': 'Basic Job Alerts', 'included': true},
              {'text': 'Community Access', 'included': true},
              {'text': 'AI-Powered CV Builder', 'included': false},
              {'text': 'Priority Support', 'included': false},
              {'text': 'Interview Preparation AI', 'included': false},
            ],
            'buttonText': 'Get Started Free',
            'isPopular': false,
          },
          {
            'title': 'Professional',
            'subtitle': 'For serious job seekers',
            'price': _isAnnual ? '19' : '24',
            'period': _isAnnual ? 'per month, billed annually' : 'per month',
            'features': [
              {'text': 'Everything in Free', 'included': true},
              {'text': 'AI-Powered CV Builder', 'included': true},
              {'text': 'Unlimited CV Analyses', 'included': true},
              {'text': 'Advanced Job Matching', 'included': true},
              {'text': 'Interview Preparation AI', 'included': true},
              {'text': 'Priority Job Applications', 'included': true},
              {'text': 'Career Coach AI Assistant', 'included': true},
              {'text': 'Priority Support (24h response)', 'included': true},
            ],
            'buttonText': 'Start 14-Day Free Trial',
            'isPopular': true,
          },
          {
            'title': 'Premium',
            'subtitle': 'For executive-level seekers',
            'price': _isAnnual ? '49' : '59',
            'period': _isAnnual ? 'per month, billed annually' : 'per month',
            'features': [
              {'text': 'Everything in Professional', 'included': true},
              {'text': 'Executive Profile Optimization', 'included': true},
              {'text': 'Direct Recruiter Access', 'included': true},
              {'text': 'Personalized Job Concierge', 'included': true},
              {'text': 'Salary Negotiation AI', 'included': true},
              {'text': 'LinkedIn Profile Enhancement', 'included': true},
              {'text': 'VIP Support (4h response)', 'included': true},
              {'text': 'Monthly Career Strategy Session', 'included': true},
            ],
            'buttonText': 'Go Premium',
            'isPopular': false,
          },
        ];

      case 'Recruiter':
        return [
          {
            'title': 'Starter',
            'subtitle': 'For small teams',
            'price': '0',
            'period': 'Up to 3 active job posts',
            'features': [
              {'text': 'Up to 3 Active Job Posts', 'included': true},
              {'text': 'Basic Candidate Search', 'included': true},
              {'text': 'Manual Candidate Screening', 'included': true},
              {'text': 'Email Notifications', 'included': true},
              {'text': '50 Candidate Views/month', 'included': true},
              {'text': 'AI-Powered Candidate Matching', 'included': false},
              {'text': 'Auto Job Description Builder', 'included': false},
              {'text': 'Analytics Dashboard', 'included': false},
            ],
            'buttonText': 'Start Free',
            'isPopular': false,
          },
          {
            'title': 'Business',
            'subtitle': 'For growing companies',
            'price': _isAnnual ? '99' : '119',
            'period': _isAnnual ? 'per month, billed annually' : 'per month',
            'features': [
              {'text': 'Everything in Starter', 'included': true},
              {'text': 'Unlimited Job Posts', 'included': true},
              {'text': 'AI-Powered Candidate Matching', 'included': true},
              {'text': 'Auto Candidate Shortlisting', 'included': true},
              {'text': 'Auto Job Description Builder', 'included': true},
              {'text': 'Advanced Analytics Dashboard', 'included': true},
              {'text': 'Interview Scheduling Tools', 'included': true},
              {'text': 'Unlimited Candidate Views', 'included': true},
              {'text': 'Team Collaboration (5 users)', 'included': true},
            ],
            'buttonText': 'Start 14-Day Free Trial',
            'isPopular': true,
          },
          {
            'title': 'Enterprise',
            'subtitle': 'For large organizations',
            'price': _isAnnual ? '299' : '349',
            'period': _isAnnual ? 'per month, billed annually' : 'per month',
            'features': [
              {'text': 'Everything in Business', 'included': true},
              {'text': 'Dedicated Account Manager', 'included': true},
              {'text': 'Custom Branding', 'included': true},
              {'text': 'API Access for Integration', 'included': true},
              {'text': 'Advanced Workflow Automation', 'included': true},
              {'text': 'Unlimited Team Members', 'included': true},
              {'text': 'Priority Admin Review (2h)', 'included': true},
              {'text': 'Custom Training & Onboarding', 'included': true},
              {'text': 'SLA Guarantee', 'included': true},
            ],
            'buttonText': 'Contact Sales',
            'isPopular': false,
          },
        ];

      case 'Admin':
        return [
          {
            'title': 'Essential',
            'subtitle': 'For small platforms',
            'price': _isAnnual ? '199' : '239',
            'period': _isAnnual ? 'per month, billed annually' : 'per month',
            'features': [
              {'text': 'Recruiter Request Management', 'included': true},
              {'text': 'Candidate Vetting System', 'included': true},
              {'text': 'Interview Coordination', 'included': true},
              {'text': 'Basic Analytics Dashboard', 'included': true},
              {'text': 'Up to 50 Recruiters', 'included': true},
              {'text': 'Email Support', 'included': true},
              {'text': 'AI-Powered Fraud Detection', 'included': false},
              {'text': 'Advanced Reporting', 'included': false},
            ],
            'buttonText': 'Get Started',
            'isPopular': false,
          },
          {
            'title': 'Professional',
            'subtitle': 'For growing platforms',
            'price': _isAnnual ? '399' : '479',
            'period': _isAnnual ? 'per month, billed annually' : 'per month',
            'features': [
              {'text': 'Everything in Essential', 'included': true},
              {'text': 'AI-Powered Fraud Detection', 'included': true},
              {'text': 'Advanced Reporting & Analytics', 'included': true},
              {'text': 'Automated Candidate Matching', 'included': true},
              {'text': 'Quality Score System', 'included': true},
              {'text': 'Up to 200 Recruiters', 'included': true},
              {'text': 'Priority Support (8h response)', 'included': true},
              {'text': 'Custom Workflows', 'included': true},
              {'text': 'Multi-Admin Access (3 admins)', 'included': true},
            ],
            'buttonText': 'Start 14-Day Free Trial',
            'isPopular': true,
          },
          {
            'title': 'Enterprise',
            'subtitle': 'For large platforms',
            'price': _isAnnual ? '799' : '959',
            'period': _isAnnual ? 'per month, billed annually' : 'per month',
            'features': [
              {'text': 'Everything in Professional', 'included': true},
              {'text': 'Unlimited Recruiters', 'included': true},
              {'text': 'Unlimited Admins', 'included': true},
              {'text': 'White-Label Solution', 'included': true},
              {'text': 'Advanced AI Automation', 'included': true},
              {'text': 'Dedicated Success Manager', 'included': true},
              {'text': 'Custom Integrations', 'included': true},
              {'text': '24/7 VIP Support (1h response)', 'included': true},
              {'text': 'SLA with 99.9% Uptime', 'included': true},
            ],
            'buttonText': 'Contact Sales',
            'isPopular': false,
          },
        ];

      default:
        return [];
    }
  }

  Widget _buildPricingCard(int index, Map<String, dynamic> plan) {
    final isPopular = plan['isPopular'] as bool;
    final isHovered = _hoveredCardIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCardIndex = index),
      onExit: (_) => setState(() => _hoveredCardIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, isHovered ? -8.0 : 0.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPopular ? const Color(0xFF6366F1) : const Color(
                  0xFFE2E8F0),
              width: isPopular ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? (isPopular
                    ? const Color(0xFF6366F1).withOpacity(0.15)
                    : const Color(0xFF0F172A).withOpacity(0.08))
                    : const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: isHovered ? 32 : 16,
                offset: Offset(0, isHovered ? 12 : 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'MOST POPULAR',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    if (isPopular) const SizedBox(height: 20),
                    Text(
                      plan['title'],
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['subtitle'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                            height: 1.4,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                alignment: Alignment.centerLeft,
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            plan['price'],
                            key: ValueKey(plan['price']),
                            style: GoogleFonts.inter(
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan['period'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildCTAButton(plan['buttonText'], isPopular, isHovered),
                    const SizedBox(height: 32),
                    Container(height: 1, color: const Color(0xFFE2E8F0)),
                    const SizedBox(height: 24),
                    ...List.generate(
                      (plan['features'] as List).length,
                          (i) {
                        final feature = (plan['features'] as List)[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildFeatureItem(
                            feature['text'],
                            feature['included'],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (isHovered && isPopular)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCTAButton(String text, bool isPrimary, bool isHovered) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        )
            : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary
            ? null
            : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: isHovered
            ? [
          BoxShadow(
            color: isPrimary
                ? const Color(0xFF6366F1).withOpacity(0.4)
                : const Color(0xFF0F172A).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ]
            : null,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isPrimary ? Colors.white : const Color(0xFF0F172A),
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool included) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: included
                ? const Color(0xFF6366F1).withOpacity(0.1)
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              included ? Icons.check_rounded : Icons.close_rounded,
              size: 14,
              color: included ? const Color(0xFF6366F1) : const Color(
                  0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: included ? const Color(0xFF334155) : const Color(
                  0xFF94A3B8),
              letterSpacing: -0.1,
              decoration: included ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:  [const Color(0xFF1F2937), const Color(0xFF111827)],
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

  Widget _buildFAQSection() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        children: [
          Text(
            'Frequently asked questions',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildFAQItem(
            'Can I change plans at any time?',
            'Yes, you can upgrade or downgrade your plan at any time. Changes take effect immediately.',
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'What payment methods do you accept?',
            'We accept all major credit cards, PayPal, and bank transfers for annual plans.',
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'Is there a free trial?',
            'Yes! Professional and Enterprise plans come with a 14-day free trial. No credit card required.',
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'What happens when I cancel?',
            'You can cancel anytime. You\'ll retain access until the end of your billing period.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.6,
              letterSpacing: -0.1,
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
          colors:  [const Color(0x00f9fafb), const Color(0x00f9fafb), const Color(0x00f9fafb)],
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

class _GridPainter extends CustomPainter {
  final double animationValue;

  _GridPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 100.0;
    final offset = animationValue * gridSize;

    // Base grid paint (dimmed, more prominent)
    final baseGridPaint = Paint()
      ..color = const Color(0xFF4A90E2).withOpacity(0.15)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Neon beam paint for grid lines
    final beamPaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Draw vertical lines with moving beam effect
    int verticalIndex = 0;
    for (double x = -gridSize + (offset % gridSize);
    x < size.width + gridSize;
    x += gridSize) {

      // Draw base line
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        baseGridPaint,
      );

      // Create moving beam along the line
      final beamProgress = (animationValue * 2 + verticalIndex * 0.3) % 1.0;
      final beamStart = beamProgress * size.height;
      final beamLength = size.height * 0.4; // Beam covers 30% of line

      final verticalGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFFF7E6FF).withOpacity(0.4),
          const Color(0xFFF7E6FF).withOpacity(0.9),
          const Color(0xFFF7E6FF).withOpacity(0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      );

      beamPaint.shader = verticalGradient.createShader(
        Rect.fromLTWH(x - 20, beamStart - beamLength/2, 40, beamLength),
      );

      canvas.drawLine(
        Offset(x, math.max(0, beamStart - beamLength/2)),
        Offset(x, math.min(size.height, beamStart + beamLength/2)),
        beamPaint,
      );

      verticalIndex++;
    }

    // Draw horizontal lines with moving beam effect
    int horizontalIndex = 0;
    for (double y = -gridSize + (offset % gridSize);
    y < size.height + gridSize;
    y += gridSize) {

      // Draw base line
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        baseGridPaint,
      );

      // Create moving beam along the line
      final beamProgress = (animationValue * 1.5 + horizontalIndex * 0.25) % 1.0;
      final beamStart = beamProgress * size.width;
      final beamLength = size.width * 0.6; // Beam covers 30% of line

      final horizontalGradient = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFE6EFFF).withOpacity(0.4),
          const Color(0xFFE6EFFF).withOpacity(0.9),
          const Color(0xFFE6EFFF).withOpacity(0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      );

      beamPaint.shader = horizontalGradient.createShader(
        Rect.fromLTWH(beamStart - beamLength/2, y - 20, beamLength, 40),
      );

      canvas.drawLine(
        Offset(math.max(0, beamStart - beamLength/2), y),
        Offset(math.min(size.width, beamStart + beamLength/2), y),
        beamPaint,
      );

      horizontalIndex++;
    }

    // Add extra glow at beam intersections
    final intersectionPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    verticalIndex = 0;
    for (double x = -gridSize + (offset % gridSize);
    x < size.width + gridSize;
    x += gridSize) {
      horizontalIndex = 0;
      for (double y = -gridSize + (offset % gridSize);
      y < size.height + gridSize;
      y += gridSize) {

        final beamProgressV = (animationValue * 2 + verticalIndex * 0.3) % 1.0;
        final beamProgressH = (animationValue * 1.5 + horizontalIndex * 0.25) % 1.0;

        // Check if beams are near intersection
        final verticalBeamY = beamProgressV * size.height;
        final horizontalBeamX = beamProgressH * size.width;

        if ((verticalBeamY - y).abs() < 50 && (horizontalBeamX - x).abs() < 50) {
          canvas.drawCircle(
            Offset(x, y),
            8,
            intersectionPaint,
          );
        }

        horizontalIndex++;
      }
      verticalIndex++;
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => true;
}
