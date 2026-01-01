// lib/screens/admin_login.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'admin_login_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 1200;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Animated background patterns
          const _AnimatedBackgroundPattern(),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: isWideScreen
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(
                            flex: 5,
                            child: _LeftInfoSection(),
                          ),
                          SizedBox(width: 60),
                          Expanded(
                            flex: 4,
                            child: _LoginFormCard(),
                          ),
                        ],
                      )
                          : Column(
                        children: const [
                          _LeftInfoSection(),
                          SizedBox(height: 40),
                          _LoginFormCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top navigation bar
          const _TopNavigationBar(),
        ],
      ),
    );
  }
}

// Animated Grid Pattern Widget
class _AnimatedBackgroundPattern extends StatefulWidget {
  const _AnimatedBackgroundPattern();

  @override
  State<_AnimatedBackgroundPattern> createState() =>
      _AnimatedBackgroundPatternState();
}

class _AnimatedBackgroundPatternState
    extends State<_AnimatedBackgroundPattern>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated grid pattern
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _GridPainter(_controller.value),
                size: Size.infinite,
              );
            },
          ),
        ),
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF4A90E2).withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF50C878).withOpacity(0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// Custom Painter for Grid with Beaming Lines
class _GridPainter extends CustomPainter {
  final double animationValue;

  _GridPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 50.0;
    final offset = animationValue * gridSize;

    // Base grid paint (dimmed, more prominent)
    final baseGridPaint = Paint()
      ..color = const Color(0xFF4A90E2).withOpacity(0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Neon beam paint for grid lines
    final beamPaint = Paint()
      ..strokeWidth = 3.0
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
      final beamLength = size.height * 0.3; // Beam covers 30% of line

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
      final beamLength = size.width * 0.3; // Beam covers 30% of line

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
// Top Navigation Bar
class _TopNavigationBar extends StatelessWidget {
  const _TopNavigationBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'ADMIN PORTAL',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            _HoverButton(
              icon: Icons.help_outline,
              label: 'Go To Home?',
              onPressed: () {
                context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Left Info Section
class _LeftInfoSection extends StatelessWidget {
  const _LeftInfoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main heading with animation
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4A90E2).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user,
                        color: Color(0xFF4A90E2), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'SECURE ACCESS',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4A90E2),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Administrator\nControl Center',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: const Color(0xFF2C3E50),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Manage your platform with powerful tools and comprehensive analytics. Access user management, system settings, and real-time monitoring from one centralized dashboard.',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  height: 1.6,
                  color: const Color(0xFF546E7A),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Feature cards
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _FeatureCard(
              icon: Icons.people_alt_outlined,
              title: 'User Management',
              description: 'Control access & permissions',
              color: Color(0xFF4A90E2),
              delay: 200,
            ),
            _FeatureCard(
              icon: Icons.analytics_outlined,
              title: 'Analytics Dashboard',
              description: 'Real-time insights & reports',
              color: Color(0xFF50C878),
              delay: 400,
            ),
            _FeatureCard(
              icon: Icons.security_outlined,
              title: 'Security Center',
              description: 'Monitor & protect system',
              color: Color(0xFFE67E22),
              delay: 600,
            ),
            _FeatureCard(
              icon: Icons.settings_outlined,
              title: 'System Settings',
              description: 'Configure platform options',
              color: Color(0xFF9B59B6),
              delay: 800,
            ),
          ],
        ),
      ],
    );
  }
}

// Feature Card
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final int delay;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.delay,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + widget.delay),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withOpacity(0.5)
                  : Colors.grey.shade200,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.color.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: icon + title
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Subtitle / description
              Text(
                widget.description,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: const Color(0xFF7F8C8D),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Login Form Card
class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminAuthProvider>();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFF4A90E2).withOpacity(0.05),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign In',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      'Access your admin dashboard',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: const Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 36),

            // Email field
            _AnimatedTextField(
              label: 'Email Address',
              hint: 'admin@company.com',
              icon: Icons.email_outlined,
              controller: prov.emailController,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 20),

            // Password field
            _AnimatedTextField(
              label: 'Password',
              hint: 'Enter your password',
              icon: Icons.lock_outline,
              controller: prov.passwordController,
              obscure: prov.obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  prov.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF7F8C8D),
                ),
                onPressed: prov.toggleObscure,
              ),
            ),

            const SizedBox(height: 16),

            // Remember me & Forgot password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: false,
                        onChanged: (val) {},
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: const Color(0xFF546E7A),
                      ),
                    ),
                  ],
                ),
                _HoverTextButton(
                  text: 'Forgot Password?',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password recovery not implemented')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Error message
            if (prov.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF5350),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFD32F2F), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        prov.errorMessage!,
                        style: GoogleFonts.roboto(
                          color: const Color(0xFFD32F2F),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Sign in button
            _SignInButton(
              isLoading: prov.isLoading,
              onPressed: () async {
                final success = await prov.signIn();
                if (success) {
                  if (context.mounted) context.go('/admin_dashboard');
                } else {
                  if (prov.errorMessage != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(prov.errorMessage!)),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 24),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'SECURE LOGIN',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: const Color(0xFF9E9E9E),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),

            const SizedBox(height: 24),

            // Security badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _SecurityBadge(
                  icon: Icons.shield_outlined,
                  label: 'SSL Secured',
                ),
                SizedBox(width: 20),
                _SecurityBadge(
                  icon: Icons.verified_user_outlined,
                  label: 'Firebase Auth',
                ),
                SizedBox(width: 20),
                _SecurityBadge(
                  icon: Icons.lock_clock_outlined,
                  label: '2FA Ready',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Animated TextField
class _AnimatedTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _AnimatedTextField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF546E7A),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) {
            setState(() => _isFocused = focused);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isFocused
                  ? [
                BoxShadow(
                  color: const Color(0xFF4A90E2).withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [],
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              style: GoogleFonts.roboto(
                fontSize: 15,
                color: const Color(0xFF2C3E50),
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.roboto(
                  color: const Color(0xFFBDBDBD),
                ),
                prefixIcon: Icon(
                  widget.icon,
                  color: _isFocused
                      ? const Color(0xFF4A90E2)
                      : const Color(0xFF9E9E9E),
                ),
                suffixIcon: widget.suffix,
                filled: true,
                fillColor: _isFocused
                    ? const Color(0xFFF5F9FF)
                    : const Color(0xFFF8F9FA),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: Color(0xFF4A90E2), width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Sign In Button
class _SignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isLoading
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : _isHovered
                ? [const Color(0xFF357ABD), const Color(0xFF2868A8)]
                : [const Color(0xFF4A90E2), const Color(0xFF357ABD)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!widget.isLoading)
              BoxShadow(
                color: const Color(0xFF4A90E2)
                    .withOpacity(_isHovered ? 0.4 : 0.25),
                blurRadius: _isHovered ? 16 : 12,
                offset: Offset(0, _isHovered ? 6 : 4),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: widget.isLoading
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Signing in...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In to Dashboard',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.translationValues(
                        _isHovered ? 4 : 0, 0, 0),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
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

// Security Badge
class _SecurityBadge extends StatefulWidget {
  final IconData icon;
  final String label;

  const _SecurityBadge({
    required this.icon,
    required this.label,
  });

  @override
  State<_SecurityBadge> createState() => _SecurityBadgeState();
}

class _SecurityBadgeState extends State<_SecurityBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _isHovered
              ? const Color(0xFF4A90E2).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              color: _isHovered
                  ? const Color(0xFF4A90E2)
                  : const Color(0xFF9E9E9E),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: _isHovered
                    ? const Color(0xFF4A90E2)
                    : const Color(0xFF7F8C8D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Hover Text Button
class _HoverTextButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _HoverTextButton({
    required this.text,
    required this.onPressed,
  });

  @override
  State<_HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<_HoverTextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _isHovered
                    ? const Color(0xFF4A90E2)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.text,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: _isHovered
                  ? const Color(0xFF4A90E2)
                  : const Color(0xFF546E7A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// Hover Button
class _HoverButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _HoverButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: TextButton.icon(
          onPressed: widget.onPressed ?? () {},
          icon: AnimatedRotation(
            turns: _isHovered ? 0.1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              widget.icon,
              color: _isHovered
                  ? const Color(0xFF4A90E2)
                  : const Color(0xFF7F8C8D),
              size: 18,
            ),
          ),
          label: Text(
            widget.label,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _isHovered
                  ? const Color(0xFF4A90E2)
                  : const Color(0xFF7F8C8D),
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: _isHovered
                ? const Color(0xFF4A90E2).withOpacity(0.1)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}