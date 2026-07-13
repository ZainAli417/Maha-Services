import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class HeroSection extends StatefulWidget {
  final bool isDarkMode;
  const HeroSection({super.key, required this.isDarkMode});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  late AnimationController _contentAnimationController;
  late AnimationController _textAnimationController;
  late Timer _lottieTimer;
  int _currentLottieIndex = 0;

  final List<Map<String, String>> _lottieData = const [
    {'title': 'Step 1: Candidates Apply for Jobs', 'path': 'images/1.json'},
    {
      'title': 'Step 2: Recruiter Shortlist & Submit Request',
      'path': 'images/2.json',
    },
    {
      'title': 'Step 3: Admin Review Requested Candidates',
      'path': 'images/3.json',
    },
    {
      'title': 'Step 4: Admin Interview, Train & Handover Candidates',
      'path': 'images/4.json',
    },
  ];

  @override
  void initState() {
    super.initState();
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..forward();

    _lottieTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _currentLottieIndex = (_currentLottieIndex + 1) % _lottieData.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _contentAnimationController.dispose();
    _textAnimationController.dispose();
    _lottieTimer.cancel();
    super.dispose();
  }

  // ─── Responsive text style helpers ───────────────────────────────────────────

  TextStyle _badgeStyle(bool isMobile) => GoogleFonts.plusJakartaSans(
    fontSize: isMobile ? 10 : 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  TextStyle _headlineStyle(bool isMobile, bool isTablet) =>
      GoogleFonts.plusJakartaSans(
        fontSize: isMobile ? 26 : (isTablet ? 38 : 64),
        fontWeight: FontWeight.w700,
      );

  TextStyle _descStyle(bool isMobile) => GoogleFonts.plusJakartaSans(
    fontSize: isMobile ? 12 : 14,
    fontWeight: FontWeight.w600,
    height: 1.7,
    letterSpacing: 0.3,
  );

  TextStyle _subDescStyle(bool isMobile) => GoogleFonts.plusJakartaSans(
    fontSize: isMobile ? 11 : 14,
    fontWeight: FontWeight.w600,
  );

  TextStyle _featureStyle(bool isMobile) => GoogleFonts.plusJakartaSans(
    fontSize: isMobile ? 10 : 14,
    fontWeight: FontWeight.w600,
  );

  TextStyle _btnStyle(bool isMobile) => GoogleFonts.plusJakartaSans(
    fontSize: isMobile ? 12 : 15,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;
    final hPad = isMobile ? 0.0 : (isTablet ? 20.0 : 30.0);
    final vPad = isMobile ? 16.0 : 40.0;

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RepaintBoundary(child: _buildLeftContent()),
                  const SizedBox(height: 24),
                  RepaintBoundary(child: _buildRightPanel()),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: RepaintBoundary(child: _buildLeftContent()),
                  ),
                  SizedBox(width: isTablet ? 16 : 20),
                  Expanded(
                    flex: 4,
                    child: RepaintBoundary(child: _buildRightPanel()),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── Left Content ─────────────────────────────────────────────────────────────

  Widget _buildLeftContent() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final s1 = isMobile ? 12.0 : 30.0;
    final s2 = isMobile ? 12.0 : 30.0;
    final s3 = isMobile ? 16.0 : 40.0;
    final s4 = isMobile ? 16.0 : 40.0;

    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        RepaintBoundary(child: _buildAnimatedBadge()),
        SizedBox(height: s1),
        RepaintBoundary(child: _buildAnimatedGradientHeadline()),
        SizedBox(height: s2),
        RepaintBoundary(child: _buildEnhancedDescription()),
        SizedBox(height: s3),
        RepaintBoundary(child: _buildFeatureHighlights()),
        SizedBox(height: s4),
        RepaintBoundary(child: _buildEnhancedCTAButtons()),
      ],
    );
  }

  // ─── Right Panel ──────────────────────────────────────────────────────────────

  Widget _buildRightPanel() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;
    final panelHeight = isMobile ? 300.0 : (isTablet ? 500.0 : 700.0);
    final lottieW = isMobile ? 320.0 : (isTablet ? 500.0 : 750.0);
    final lottieH = isMobile ? 240.0 : (isTablet ? 400.0 : 600.0);
    final capsuleTop = isMobile ? 0.0 : 35.0;
    final lottieTop = isMobile ? 36.0 : 60.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: SizedBox(
        height: panelHeight,
        key: ValueKey<int>(_currentLottieIndex),
        child: Stack(
          children: [
            Positioned(
              top: lottieTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: Lottie.asset(
                  _lottieData[_currentLottieIndex]['path']!,
                  fit: BoxFit.contain,
                  width: lottieW,
                  height: lottieH,
                  repeat: true,
                  animate: true,
                ),
              ),
            ),
            Positioned(
              top: capsuleTop,
              left: isMobile ? 0 : 20,
              right: isMobile ? 0 : null,
              child: isMobile
                  ? Center(child: _buildAnimatedCapsule())
                  : _buildAnimatedCapsule(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCapsule() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final hPad = isMobile ? 10.0 : 20.0;
    final vPad = isMobile ? 7.0 : 12.0;
    final dotSize = isMobile ? 6.0 : 8.0;
    final fontSize = isMobile ? 10.0 : 14.0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF686Be1), Color(0xFF682EE8)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(width: isMobile ? 6 : 10),
              Flexible(
                child: Text(
                  _lottieData[_currentLottieIndex]['title']!,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Animated components ──────────────────────────────────────────────────────

  Widget _buildAnimatedBadge() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final hPad = isMobile ? 10.0 : 20.0;
    final vPad = isMobile ? 6.0 : 10.0;
    final iconPad = isMobile ? 4.0 : 6.0;
    final iconSize = isMobile ? 12.0 : 16.0;

    final slideAnimation =
        Tween<Offset>(begin: const Offset(-0.5, 0), end: Offset.zero).animate(
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
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isDarkMode
                  ? [const Color(0xFF312E81), const Color(0xFF4C1D95)]
                  : [const Color(0xFFEDE9FE), const Color(0xFFDDD6FE)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(iconPad),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: const Color(0xFF6366F1),
                  size: iconSize,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Flexible(
                child: Text(
                  'AI-Powered 4 Steps Recruitment Process',
                  style: _badgeStyle(isMobile).copyWith(
                    color: widget.isDarkMode
                        ? const Color(0xFFDDD6FE)
                        : const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedGradientHeadline() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final isTablet = w >= 600 && w < 1024;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
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
              'Discover the Right Talent at Right time',
              textAlign: isMobile ? TextAlign.center : TextAlign.start,
              style: _headlineStyle(
                isMobile,
                isTablet,
              ).copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDescription() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final verifiedIconSize = isMobile ? 14.0 : 20.0;

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: Column(
        crossAxisAlignment: isMobile
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            'Revolutionize your talent acquisition with our cutting-edge platform that seamlessly connects exceptional candidates with forward-thinking recruiters.',
            textAlign: isMobile ? TextAlign.center : TextAlign.start,
            style: _descStyle(isMobile).copyWith(
              color: widget.isDarkMode
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF4B5563),
            ),
          ),
          SizedBox(height: isMobile ? 8 : 16),
          Row(
            mainAxisAlignment: isMobile
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_rounded,
                size: verifiedIconSize,
                color: const Color(0xFF10B981),
              ),
              SizedBox(width: isMobile ? 5 : 8),
              Flexible(
                child: Text(
                  '🇵🇰 Trusted Employment from Pakistan\'s Fastest Growing IT Sector',
                  style: _subDescStyle(isMobile).copyWith(
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
    );
  }

  Widget _buildFeatureHighlights() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;
    final featureIconSize = isMobile ? 13.0 : 18.0;
    final featureHPad = isMobile ? 8.0 : 16.0;
    final featureVPad = isMobile ? 6.0 : 10.0;

    final slideAnimation =
        Tween<Offset>(begin: const Offset(-0.2, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentAnimationController,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
          ),
        );

    final features = [
      {
        'icon': Icons.psychology_rounded,
        'text': 'AI-Powered',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.speed_rounded,
        'text': '3x Faster Hiring',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.security,
        'text': 'Enterprise Security',
        'color': const Color(0xFFF59E0B),
      },
    ];

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: _contentAnimationController,
        child: Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: isMobile ? 6 : 12,
          runSpacing: isMobile ? 6 : 10,
          children: features.map((feature) {
            final color = feature['color'] as Color;
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: featureHPad,
                vertical: featureVPad,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: widget.isDarkMode ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    size: featureIconSize,
                    color: color,
                  ),
                  SizedBox(width: isMobile ? 4 : 8),
                  Text(
                    feature['text'] as String,
                    style: _featureStyle(isMobile).copyWith(
                      color: widget.isDarkMode
                          ? Colors.white
                          : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEnhancedCTAButtons() {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    final slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Expanded(
              child: _EnhancedButton(
                onPressed: () => context.go('/register?role=candidate'),
                isPrimary: true,
                icon: Icons.person_add_rounded,
                label: "I'm a Candidate",
                isDarkMode: widget.isDarkMode,
                textStyle: _btnStyle(isMobile),
                isMobile: isMobile,
              ),
            ),
            SizedBox(width: isMobile ? 8 : 16),
            Expanded(
              child: _EnhancedButton(
                onPressed: () => context.go('/register?role=recruiter'),
                isPrimary: false,
                icon: Icons.business_center_rounded,
                label: "I'm a Recruiter",
                isDarkMode: widget.isDarkMode,
                textStyle: _btnStyle(isMobile),
                isMobile: isMobile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Enhanced Button ──────────────────────────────────────────────────────────

class _EnhancedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData icon;
  final String label;
  final bool isDarkMode;
  final TextStyle textStyle;
  final bool isMobile;

  const _EnhancedButton({
    required this.onPressed,
    required this.isPrimary,
    required this.icon,
    required this.label,
    required this.isDarkMode,
    required this.textStyle,
    this.isMobile = false,
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = widget.isMobile ? 12.0 : 28.0;
    final vPad = widget.isMobile ? 13.0 : 25.0;
    final iconSize = widget.isMobile ? 15.0 : 20.0;
    final radius = widget.isMobile ? 10.0 : 14.0;

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
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color:
                    (widget.isPrimary
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF10B981))
                        .withValues(alpha: _isHovered ? 0.3 : 0.15),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 6 : 3),
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
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
                side: widget.isPrimary
                    ? BorderSide.none
                    : const BorderSide(color: Color(0xFF10B981), width: 2),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: iconSize),
                SizedBox(width: widget.isMobile ? 6 : 10),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: widget.textStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
