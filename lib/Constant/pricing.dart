import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Header_Nav.dart';
import 'brand.dart';
import 'site_chrome.dart';
import 'package:go_router/go_router.dart';

class PremiumPricingPage extends StatefulWidget {
  const PremiumPricingPage({super.key});

  @override
  State<PremiumPricingPage> createState() => _PremiumPricingPageState();
}

class _PremiumPricingPageState extends State<PremiumPricingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;

  bool _isAnnual = true;
  int _hoveredCardIndex = -1;
  String _selectedUserType = 'Job Seeker'; // Job Seeker, Recruiter, Admin

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: Brand.bgSoft,
      body: Stack(
        children: [
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
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _slideController,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: Column(
                              children: [
                                const HeaderNav(),
                                const SizedBox(height: 32),
                                _buildHeader(isMobile),
                                const SizedBox(height: 40),
                                _buildUserTypeSelector(isMobile),
                                const SizedBox(height: 28),
                                _buildBillingToggle(isMobile),
                                const SizedBox(height: 56),
                                _buildPricingCards(),
                                const SizedBox(height: 72),
                                _buildFAQSection(isMobile),
                                const SizedBox(height: 20),
                                const SiteStatsBand(),
                                const SiteFooter(),
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

  // ─── Page header (light) ───────────────────────────────────────────────────
  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Brand.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Brand.teal.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandPulseDot(color: Brand.teal),
                const SizedBox(width: 9),
                Text(
                  'PRICING PLANS',
                  style: Brand.font(12, FontWeight.w700, Brand.tealDeep,
                      spacing: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Choose Your Perfect Plan',
            style: Brand.font(
                isMobile ? 32 : 48, FontWeight.w800, Brand.ink,
                height: 1.1, spacing: -1.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: isMobile ? double.infinity : 600,
            child: Text(
              'Tailored solutions for job seekers, recruiters and admins. Start free, scale as you grow.',
              style: Brand.font(
                  isMobile ? 15 : 18, FontWeight.w500, Brand.muted,
                  height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector(bool isMobile) {
    final userTypes = [
      {'label': 'Job Seeker', 'icon': Icons.person_search_rounded},
      {'label': 'Recruiter', 'icon': Icons.business_center_rounded},
      {'label': 'Admin', 'icon': Icons.admin_panel_settings_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.border),
        boxShadow: [
          BoxShadow(
            color: Brand.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: userTypes
                  .map((type) => _buildUserTypeItem(type, isMobile))
                  .toList(),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: userTypes
                  .map((type) => _buildUserTypeItem(type, isMobile))
                  .toList(),
            ),
    );
  }

  Widget _buildUserTypeItem(Map<String, dynamic> type, bool isMobile) {
    final isSelected = _selectedUserType == type['label'];
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: () =>
            setState(() => _selectedUserType = type['label'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isMobile ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [Brand.teal, Brand.tealDeep])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Brand.teal.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: isMobile
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                type['icon'] as IconData,
                size: 20,
                color: isSelected ? Colors.white : Brand.muted,
              ),
              const SizedBox(width: 8),
              Text(
                type['label'] as String,
                style: Brand.font(15, FontWeight.w600,
                    isSelected ? Colors.white : Brand.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillingToggle(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Brand.border),
        boxShadow: [
          BoxShadow(
            color: Brand.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          _buildToggleOption('Monthly', !_isAnnual, () {
            setState(() => _isAnnual = false);
          }),
          _buildToggleOption('Annual', _isAnnual, () {
            setState(() => _isAnnual = true);
          }, showBadge: true),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String label,
    bool isActive,
    VoidCallback onTap, {
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Brand.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Brand.font(15, FontWeight.w600,
                  isActive ? Colors.white : Brand.muted),
            ),
            if (showBadge) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Brand.teal,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Save 20%',
                  style: Brand.font(11, FontWeight.w700,
                      isActive ? Brand.tealDeep : Colors.white, spacing: 0.5),
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
            children: plans.asMap().entries.map((entry) {
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
          children: plans.asMap().entries.map((entry) {
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
        transform: Matrix4.identity()..translate(0.0, isHovered ? -8.0 : 0.0),
        child: Container(
          constraints: BoxConstraints(maxWidth: isHovered ? 400 : 380),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPopular ? Brand.teal : Brand.border,
              width: isPopular ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? (isPopular
                          ? Brand.teal.withValues(alpha: 0.2)
                          : Brand.ink.withValues(alpha: 0.1))
                    : Brand.ink.withValues(alpha: 0.05),
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
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Brand.teal, Brand.tealDeep],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'MOST POPULAR',
                          style: GoogleFonts.plusJakartaSans(
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Brand.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['subtitle'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Brand.muted,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Brand.ink,
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              color: Brand.ink,
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Brand.muted,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildCTAButton(
                      plan['buttonText'],
                      isPopular,
                      isHovered,
                      () => context.go('/login'),
                    ),
                    const SizedBox(height: 32),
                    Container(height: 1, color: Brand.border),
                    const SizedBox(height: 24),
                    ...List.generate((plan['features'] as List).length, (i) {
                      final feature = (plan['features'] as List)[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildFeatureItem(
                          feature['text'],
                          feature['included'],
                        ),
                      );
                    }),
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
                            Colors.white.withValues(alpha: 0.1),
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.05),
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

  Widget _buildCTAButton(
    String text,
    bool isPrimary,
    bool isHovered,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(colors: [Brand.teal, Brand.tealDeep])
              : null,
          color: isPrimary ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(color: Brand.border, width: 1.5),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: isPrimary
                        ? Brand.teal.withValues(alpha: 0.4)
                        : Brand.ink.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : Brand.ink,
            letterSpacing: -0.2,
          ),
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
                ? Brand.teal.withValues(alpha: 0.12)
                : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              included ? Icons.check_rounded : Icons.close_rounded,
              size: 14,
              color: included ? Brand.tealDeep : Brand.faint,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: included ? Brand.slate : Brand.faint,
              letterSpacing: -0.1,
              decoration: included ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFAQSection(bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 40),
      child: Column(
        children: [
          Text(
            'Frequently asked questions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 28 : 32,
              fontWeight: FontWeight.w700,
              color: Brand.ink,
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
            'What happens when i cancel?',
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
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Brand.ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Brand.muted,
              height: 1.6,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

}
