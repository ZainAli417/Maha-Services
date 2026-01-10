import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class HeroSection extends StatefulWidget {
  final bool isDarkMode;

  const HeroSection({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  late AnimationController _contentAnimationController;
  late AnimationController _textAnimationController;
  late Timer _lottieTimer;
  int _currentLottieIndex = 0;

  // Cached text styles for performance
  late TextStyle _badgeTextStyle;
  late TextStyle _headlineTextStyle;
  late TextStyle _descriptionTextStyle;
  late TextStyle _subDescriptionTextStyle;
  late TextStyle _featureTextStyle;
  late TextStyle _buttonTextStyle;

  final List<Map<String, String>> _lottieData = const [
    {
      'title': 'Step 1: Candidates Apply for Jobs',
      'path': 'images/1.json',
    },
    {
      'title': 'Step 2: Recruiter Shortlist & Submit Request',
      'path': 'images/2.json',
    },
    {
      'title': 'Step 3: Admin Review Requested Candidates',
      'path': 'images/3.json',
    },
    {
      'title': 'Step 4: Admin Interview,Train & Handover Candidates',
      'path': 'images/4.json',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeTextStyles();

    // Optimized animation duration for web
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..forward();

    // Auto-switch Lottie animations every 5 seconds
    _lottieTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentLottieIndex = (_currentLottieIndex + 1) % _lottieData.length;
        });
      }
    });
  }

  void _initializeTextStyles() {
    _badgeTextStyle = GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    _headlineTextStyle = GoogleFonts.poppins(
      fontSize: 64,
      fontWeight: FontWeight.w700,
    );

    _descriptionTextStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.7,
      letterSpacing: 0.3,
    );

    _subDescriptionTextStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    _featureTextStyle = GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    _buttonTextStyle = GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
  }

  @override
  void didUpdateWidget(HeroSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _initializeTextStyles();
    }
  }

  @override
  void dispose() {
    _contentAnimationController.dispose();
    _textAnimationController.dispose();
    _lottieTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildHeroSection();
  }

  Widget _buildHeroSection() {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isDarkMode
                ? [const Color(0x00f9fafb), const Color(0x00f9fafb)]
                : [
              const Color(0x00f9fafb),
              const Color(0x00f9fafb),
              const Color(0x00f9fafb),
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left content - isolated from repaints
            Expanded(
              flex: 6,
              child: RepaintBoundary(
                child: _buildLeftContent(),
              ),
            ),
            const SizedBox(width: 40),
            // Right panel - Lottie animations with capsules
            Expanded(
              flex: 4,
              child: RepaintBoundary(
                child: _buildRightPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated badge
        RepaintBoundary(
          child: _buildAnimatedBadge(),
        ),
        const SizedBox(height: 30),

        // Animated headline with optimized shader
        RepaintBoundary(
          child: _buildAnimatedGradientHeadline(),
        ),
        const SizedBox(height: 30),

        // Enhanced description
        RepaintBoundary(
          child: _buildEnhancedDescription(),
        ),
        const SizedBox(height: 40),

        // Feature highlights
        RepaintBoundary(
          child: _buildFeatureHighlights(),
        ),
        const SizedBox(height: 40),

        // CTA Buttons
        RepaintBoundary(
          child: _buildEnhancedCTAButtons(),
        ),
      ],
    );
  }




  // ==================== RIGHT PANEL - LOTTIE ANIMATIONS ====================
  Widget _buildRightPanel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: SizedBox(  // ADD THIS - provides bounded constraints
        height: 700,    // ADD THIS
        key: ValueKey<int>(_currentLottieIndex),
        child: Stack(
          children: [
            // Main Lottie animation - positioned lower and bigger
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: Lottie.asset(
                  _lottieData[_currentLottieIndex]['path']!,
                  fit: BoxFit.contain,
                  width: 750,
                  height: 600,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
            // Animated capsule badge
            Positioned(
              top: 35,
              left: 20,
              child: _buildAnimatedCapsule(),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAnimatedCapsule() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF686BE1),
                  const Color(0xFF682EE8),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _lottieData[_currentLottieIndex]['title']!,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== ANIMATED COMPONENTS ====================


  Widget _buildAnimatedBadge() {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: _contentAnimationController,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isDarkMode
                  ? [const Color(0xFF312E81), const Color(0xFF4C1D95)]
                  : [const Color(0xFFEDE9FE), const Color(0xFFDDD6FE)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF6366F1),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI-Powered 4 Steps Recruitment Process',
                style: _badgeTextStyle.copyWith(
                  color: widget.isDarkMode
                      ? const Color(0xFFDDD6FE)
                      : const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedGradientHeadline() {
    const headline = 'Discover the Right Talent at Right time';

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: widget.isDarkMode
                    ? [Colors.white, const Color(0xFFDDD6FE)]
                    : [const Color(0xFF213246), const Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                headline,
                style: _headlineTextStyle.copyWith(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedDescription() {
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        padding: const EdgeInsets.only(left: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revolutionize your talent acquisition with our cutting-edge platform that seamlessly connects exceptional candidates with forward-thinking recruiters.',
              style: _descriptionTextStyle.copyWith(
                color: widget.isDarkMode
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '🇵🇰 Trusted Employment from Pakistan\'s Fastest Growing IT Sector',
                    style: _subDescriptionTextStyle.copyWith(
                      color: widget.isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights() {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    const features = [
      {
        'icon': Icons.psychology_rounded,
        'text': 'AI-Powered Matching',
        'color': Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.speed_rounded,
        'text': '3x Faster Hiring',
        'color': Color(0xFF10B981),
      },
      {
        'icon': Icons.security,
        'text': 'Enterprise Security',
        'color': Color(0xFFF59E0B),
      },
    ];

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: _contentAnimationController,
        child: Row(
          children: features.map((feature) {
            final color = feature['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(widget.isDarkMode ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      feature['icon'] as IconData,
                      size: 18,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feature['text'] as String,
                      style: _featureTextStyle.copyWith(
                        color: widget.isDarkMode
                            ? Colors.white
                            : const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEnhancedCTAButtons() {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: _contentAnimationController,
        child: Row(
          children: [
            Expanded(
              child: _EnhancedButton(
                onPressed: () => context.go('/register'),
                isPrimary: true,
                icon: Icons.person_add_rounded,
                label: 'Join as Candidate',
                isDarkMode: widget.isDarkMode,
                textStyle: _buttonTextStyle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _EnhancedButton(
                onPressed: () => context.go('/register'),
                isPrimary: false,
                icon: Icons.business_center_rounded,
                label: 'I\'m a Recruiter',
                isDarkMode: widget.isDarkMode,
                textStyle: _buttonTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData icon;
  final String label;
  final bool isDarkMode;
  final TextStyle textStyle;

  const _EnhancedButton({
    required this.onPressed,
    required this.isPrimary,
    required this.icon,
    required this.label,
    required this.isDarkMode,
    required this.textStyle,
  });

  @override
  State<_EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<_EnhancedButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isHovered
                ? [
              BoxShadow(
                color: (widget.isPrimary
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF10B981))
                    .withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
                : [
              BoxShadow(
                color: (widget.isPrimary
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF10B981))
                    .withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isPrimary
                  ? const Color(0xFF6366F1)
                  : (widget.isDarkMode
                  ? const Color(0xFF1E293B)
                  : Colors.white),
              foregroundColor: widget.isPrimary
                  ? Colors.white
                  : const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: widget.isPrimary
                    ? BorderSide.none
                    : const BorderSide(color: Color(0xFF10B981), width: 2),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 20),
                const SizedBox(width: 10),
                Text(widget.label, style: widget.textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

