// login_screen.dart — FIXED
// ─── Fix applied ──────────────────────────────────────────────────────────────
//
// FIX 2 [CRITICAL — UI never navigated after successful login]:
//   login() in the provider returns the target route (e.g. '/dashboard') on
//   success, but _onLogin() only showed a SnackBar and never called
//   context.go(route). Navigation only happened if a GoRouter authStateChanges
//   redirect fired on its own — which is timing-dependent and unreliable.
//   Fix: call context.go(route) explicitly after a successful login.
//
// All other code is 100% preserved.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'widgets/custom_snackbars.dart';

import 'Constant/Header_Nav.dart';
import 'Constant/Forget Password.dart';
import 'login_provider.dart';

class JobSeekerLoginScreen extends StatefulWidget {
  const JobSeekerLoginScreen({super.key});
  @override
  State<JobSeekerLoginScreen> createState() => _JobSeekerLoginScreenState();
}

class _JobSeekerLoginScreenState extends State<JobSeekerLoginScreen>
    with TickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  bool   _obscure = true;
  String _role    = 'Job Seeker';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatController;
  late Animation<double>   _fadeAnimation;
  late Animation<Offset>   _slideAnimation;
  late Animation<double>   _floatAnimation;
  late AnimationController _floatingController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _floatController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _snack(String text, {bool error = false}) {
    if (!mounted) return;
    if (error) {
      CustomSnackbars.showError(context, text);
    } else {
      CustomSnackbars.showSuccess(context, text);
    }
  }

  // ── LOGIN HANDLER — FIXED ──────────────────────────────────────────────────
  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<LoginProvider>(context, listen: false);
    provider.clearError();

    try {
      final route = await provider.login(
        email: _email.text.trim().toLowerCase(),
        password: _password.text,
        expectedRole: _role == 'Job Seeker' ? 'Job Seeker' : 'Recruiter',
      );

      if (!mounted) return;

      if (route != null) {
        // ── FIX 2: actually navigate to the returned route ─────────────────
        _snack('Welcome back! 🎉');
        context.go(route);
      } else {
        _snack(provider.errorMessage ?? 'Invalid credentials', error: true);
      }
    } catch (e) {
      debugPrint('Login exception: $e');
      if (!mounted) return;
      _snack('Connection error. Please try again', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width  = MediaQuery.sizeOf(context).width;
    final isWide = width > 900;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: !isWide,
        bottom: false,
        child: isWide
            ? Column(
          children: [
            const HeaderNav(),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 5, child: _leftPanel(context)),
                  Expanded(flex: 5, child: _buildFormPanel(true)),
                ],
              ),
            ),
          ],
        )
            : SingleChildScrollView(
          child: _buildFormPanel(false),
        ),
      ),
    );
  }

  // ── LEFT PANEL (desktop only) — unchanged ─────────────────────────────────

  Widget _leftPanel(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0F23), Color(0xFF1a1a3e), Color(0xFF2d1b4e)],
        ),
      ),
      child: Stack(
        children: [
          _buildAnimatedOrbs(),
          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompactHeader(),
                  const SizedBox(height: 15),
                  _buildLiveMetrics(),
                  const SizedBox(height: 15),
                  _buildCompactStats(),
                  const SizedBox(height: 15),
                  _buildCompactFeatures(),
                  const SizedBox(height: 15),
                  _buildTrustBadges(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedOrbs() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) => Positioned(
            top: 100 + (_floatingController.value * 50),
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF667eea).withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) => Positioned(
            bottom: 50 - (_floatingController.value * 30),
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFf093fb).withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.15),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
                color: const Color(0xFF667eea).withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ade80),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF4ade80).withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1)
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text('LIVE',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 1)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFb8c5ff)]).createShader(bounds),
          child: Text('Maha Services',
              style: GoogleFonts.poppins(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -1.2)),
        ),
        const SizedBox(height: 12),
        Text(
          'Next-gen recruitment powered by intelligent automation',
          style: GoogleFonts.poppins(
              fontSize: 13, color: Colors.white.withOpacity(0.6), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildLiveMetrics() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ],
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enterprise Grade',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('AES-256 • Hash Algorithm',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6))),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xFF4ade80),
                  borderRadius: BorderRadius.circular(100)),
              child: Text('ACTIVE',
                  style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F0F23),
                      letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStats() {
    return Row(
      children: [
        Expanded(
            child: _CompactMetric(
                value: '1.2K',
                label: 'Jobs',
                color: const Color(0xFF667eea),
                icon: Icons.work_outline_rounded)),
        const SizedBox(width: 12),
        Expanded(
            child: _CompactMetric(
                value: '342',
                label: 'Online',
                color: const Color(0xFF4ade80),
                icon: Icons.people_outline_rounded)),
        const SizedBox(width: 12),
        Expanded(
            child: _CompactMetric(
                value: '5.4K',
                label: 'Hires',
                color: const Color(0xFFf093fb),
                icon: Icons.trending_up_rounded)),
      ],
    );
  }

  Widget _buildCompactFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CAPABILITIES',
            style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 1.3)),
        const SizedBox(height: 14),
        const _CompactFeature(
            icon: Icons.auto_awesome_rounded, title: 'AI-Powered Matching'),
        const SizedBox(height: 10),
        const _CompactFeature(
            icon: Icons.speed_rounded,
            title: 'Seek More Borderless Jobs'),
        const SizedBox(height: 10),
        const _CompactFeature(
            icon: Icons.verified_user_rounded,
            title: 'Verified Employers across Globe'),
      ],
    );
  }

  Widget _buildTrustBadges() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _TrustBadge(
              icon: Icons.shield_outlined, label: '256-bit'),
          Container(
              width: 1, height: 20, color: Colors.white.withOpacity(0.1)),
          const _TrustBadge(
              icon: Icons.verified_outlined, label: 'SOC 2'),
          Container(
              width: 1, height: 20, color: Colors.white.withOpacity(0.1)),
          const _TrustBadge(
              icon: Icons.security_outlined, label: 'GDPR'),
        ],
      ),
    );
  }

  // ── FORM PANEL — unchanged except _onLogin now navigates ──────────────────

  Widget _buildFormPanel(bool isWide) {
    final double hPad          = isWide ? 80 : 20;
    final double vPad          = isWide ? 48 : 24;
    final double headerFontSize = isWide ? 32 : 24;
    final double subFontSize   = isWide ? 15 : 13;
    final double iconSize      = isWide ? 28 : 22;
    final double iconPad       = isWide ? 12 : 10;
    final double sectionGap    = isWide ? 32 : 20;
    final double fieldGap      = isWide ? 24 : 16;
    final double btnHeight     = isWide ? 56 : 50;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isWide)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Center(
                        child: Image.asset('images/logo.png',
                            height: 150, fit: BoxFit.fill),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconPad),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.waving_hand_rounded,
                            color: Colors.white, size: iconSize),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome Back!',
                                style: GoogleFonts.poppins(
                                    fontSize: headerFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1F2937),
                                    letterSpacing: -0.5)),
                            const SizedBox(height: 2),
                            Text('Sign in to continue your journey',
                                style: GoogleFonts.poppins(
                                    color: const Color(0xFF6B7280),
                                    fontSize: subFontSize,
                                    fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isWide ? 20 : 16),

                  // Role Selector
                  Container(
                    padding: EdgeInsets.all(isWide ? 6 : 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                            child: _buildRoleButton(
                                'Job Seeker', Icons.person_search_rounded,
                                compact: !isWide)),
                        Expanded(
                            child: _buildRoleButton(
                                'Recruiter', Icons.business_center_rounded,
                                compact: !isWide)),
                      ],
                    ),
                  ),
                  SizedBox(height: sectionGap),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Email Address'),
                        const SizedBox(height: 8),
                        _emailField(isWide),
                        SizedBox(height: fieldGap),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _fieldLabel('Password'),
                            TextButton(
                              onPressed: () =>
                                  ForgotPasswordModal.show(context),
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap),
                              child: Text('Forgot password?',
                                  style: GoogleFonts.poppins(
                                      color: const Color(0xFF6366F1),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _passwordField(isWide),
                        SizedBox(height: sectionGap),

                        // Login Button
                        Consumer<LoginProvider>(
                          builder: (_, provider, __) => Container(
                            width: double.infinity,
                            height: btnHeight,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6)
                                  ]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF6366F1)
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10))
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed:
                              provider.isLoading ? null : _onLogin,
                              child: provider.isLoading
                                  ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white))
                                  : Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text('Log In',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  const SizedBox(width: 8),
                                  const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isWide ? 32 : 20),

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Don't have an account?",
                            style: GoogleFonts.poppins(
                                color: const Color(0xFF6B7280),
                                fontSize: 13,
                                fontWeight: FontWeight.w400)),
                        TextButton(
                          onPressed: () => context.go('/admin'),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(left: 4),
                              minimumSize: Size.zero,
                              tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap),
                          child: Text('Sign Up',
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFF6366F1),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
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

  // ── Shared field helpers — unchanged ──────────────────────────────────────

  Widget _fieldLabel(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937)));
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Widget prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF)),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Color(0xFF6366F1), width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Color(0xFFEF4444), width: 1)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: Color(0xFFEF4444), width: 2)),
    );
  }

  Widget _emailField(bool isWide) {
    return TextFormField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style:
      GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF1F2937)),
      decoration: _inputDecoration(
        hint: 'you@example.com',
        prefix: const Icon(Icons.email_rounded,
            color: Color(0xFF6366F1), size: 20),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required';
        if (!v.contains('@')) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _passwordField(bool isWide) {
    return TextFormField(
      controller: _password,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onLogin(),
      style:
      GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF1F2937)),
      decoration: _inputDecoration(
        hint: '••••••••',
        prefix: const Icon(Icons.lock_rounded,
            color: Color(0xFF6366F1), size: 20),
        suffix: IconButton(
          icon: Icon(
              _obscure
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: const Color(0xFF6B7280),
              size: 20),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Password is required';
        return null;
      },
    );
  }

  Widget _buildRoleButton(String value, IconData icon,
      {bool compact = false}) {
    final selected = _role == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: Container(
          padding:
          EdgeInsets.symmetric(vertical: compact ? 10 : 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
              BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: compact ? 16 : 18,
                  color: selected
                      ? Colors.white
                      : const Color(0xFF6B7280)),
              SizedBox(width: compact ? 6 : 8),
              Text(value,
                  style: GoogleFonts.poppins(
                      color: selected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      fontSize: compact ? 13 : 14,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets — unchanged ────────────────────────────────────────────────────

class _CompactMetric extends StatelessWidget {
  final String value, label;
  final Color  color;
  final IconData icon;
  const _CompactMetric(
      {required this.value,
        required this.label,
        required this.color,
        required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }
}

class _CompactFeature extends StatelessWidget {
  final IconData icon;
  final String   title;
  const _CompactFeature({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white.withOpacity(0.12),
              Colors.white.withOpacity(0.04)
            ]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: Colors.white.withOpacity(0.9), size: 16),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.85))),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.5), size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}