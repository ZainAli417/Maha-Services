// lib/screens/signup_screen_auth.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Constant/captcha.dart';
import '../core/widgets/custom_snackbars.dart';
import 'package:job_portal/SignUp%20/signup_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Constant/Header_Nav.dart';
import '../Constant/captcha_web_listeners.dart';

class SignUp_Screen extends StatefulWidget {
  /// Role selected from the navigation context ("Job Seeker" or "Recruiter").
  /// When null (direct visit to /register) the flow defaults to Job Seeker.
  final String? initialRole;

  const SignUp_Screen({super.key, this.initialRole});

  @override
  State<SignUp_Screen> createState() => _SignUp_ScreenState();
}

class _SignUp_ScreenState extends State<SignUp_Screen>
    with TickerProviderStateMixin {
  final _formKeyAccount = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _floatingController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      registerRecaptchaView('6LfUnUAsAAAAAE580fSsiwknCmKCYghhujXtycaQ');
    }
    _initializeAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<SignupProvider>(context, listen: false);
      provider.clearAll();
      // Role is fixed by navigation context; no on-screen role toggle.
      // Direct /register visits default to Job Seeker.
      provider.setRole(widget.initialRole == 'Recruiter'
          ? 'Recruiter'
          : 'Job Seeker');
      if (kIsWeb) {
        setupCaptchaListeners(provider);
      }
    });
  }

  void _initializeAnimations() {
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
        _floatingController.repeat(reverse: true);
        _pulseController.repeat();
      }
    });
  }

  // Captcha listeners moved to captcha_web_listeners.dart for platform safety

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    if (isError) {
      CustomSnackbars.showError(context, message);
    } else {
      CustomSnackbars.showSuccess(context, message);
    }
  }

  // ─── LEFT PANEL (desktop only) ───────────────────────────────────────────────

  Widget leftPanel(BuildContext context) {
    return RepaintBoundary(
      child: Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 32,
                ),
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
      ),
    );
  }

  Widget _buildAnimatedOrbs() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            final offset = (_floatingController.value * 50).clamp(0.0, 50.0);
            return Positioned(
              top: 100 + offset,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF667eea).withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            final offset = (_floatingController.value * 30).clamp(0.0, 30.0);
            return Positioned(
              bottom: 50 - offset,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFf093fb).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
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
            color: const Color(0xFF667eea).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: const Color(0xFF667eea).withValues(alpha: 0.3),
              width: 1,
            ),
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
                      color: const Color(0xFF4ade80).withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFb8c5ff)],
          ).createShader(bounds),
          child: Text(
            'Maha Services',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Next-gen recruitment powered by intelligent automation',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMetrics() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enterprise Grade',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AES-256 • Hash Algorithm',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF4ade80),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'ACTIVE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F0F23),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStats() {
    return const Row(
      children: [
        Expanded(
          child: _CompactMetric(
            value: '1.2K',
            label: 'Jobs',
            color: Color(0xFF667eea),
            icon: Icons.work_outline_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _CompactMetric(
            value: '342',
            label: 'Online',
            color: Color(0xFF4ade80),
            icon: Icons.people_outline_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _CompactMetric(
            value: '5.4K',
            label: 'Hires',
            color: Color(0xFFf093fb),
            icon: Icons.trending_up_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CAPABILITIES',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        const _CompactFeature(
          icon: Icons.auto_awesome_rounded,
          title: 'AI-Powered Matching',
        ),
        const SizedBox(height: 10),
        const _CompactFeature(
          icon: Icons.speed_rounded,
          title: 'Seek More Borderless Jobs',
        ),
        const SizedBox(height: 10),
        const _CompactFeature(
          icon: Icons.verified_user_rounded,
          title: 'Verified Employers across Globe',
        ),
      ],
    );
  }

  Widget _buildTrustBadges() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _TrustBadge(icon: Icons.shield_outlined, label: '256-bit'),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const _TrustBadge(icon: Icons.verified_outlined, label: 'SOC 2'),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const _TrustBadge(icon: Icons.security_outlined, label: 'GDPR'),
        ],
      ),
    );
  }

  // ─── ACCOUNT PANEL ───────────────────────────────────────────────────────────

  Widget accountPanel(BuildContext context, SignupProvider p, bool isWide) {
    final double fieldGap = isWide ? 18 : 14;
    final double sectionGap = isWide ? 28 : 18;

    return Form(
      key: _formKeyAccount,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isWide, p),
          SizedBox(height: sectionGap),
          _buildEnhancedTextField(
            controller: p.nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline_rounded,
            isWide: isWide,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name required';
              return null;
            },
          ),
          SizedBox(height: fieldGap),
          _buildEnhancedTextField(
            controller: p.emailController,
            label: 'Email Address',
            hint: 'abc@mail.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: p.emailError,
            isWide: isWide,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email required';
              final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
              if (!emailRegex.hasMatch(v.trim())) return 'Enter valid email';
              return null;
            },
          ),
          SizedBox(height: fieldGap),
          _buildEnhancedTextField(
            controller: p.passwordController,
            label: 'Password',
            hint: isWide
                ? 'Create a strong password (min. 8 characters)'
                : 'Min. 8 characters',
            icon: Icons.lock_outline_rounded,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.next,
            errorText: p.passwordError,
            isWide: isWide,
            helperText: 'Spaces are not allowed and will be removed',
            onChanged: (v) {
              if (p.confirmPasswordController.text.isNotEmpty) {
                _formKeyAccount.currentState?.validate();
              }
            },
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'Password required';
              if (val.length < 8) return 'Minimum 8 characters';
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          SizedBox(height: fieldGap),
          _buildEnhancedTextField(
            controller: p.confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            icon: Icons.lock_outline_rounded,
            obscureText: !_isConfirmPasswordVisible,
            textInputAction: TextInputAction.done,
            errorText: p.passwordError,
            isWide: isWide,
            onChanged: (v) => _formKeyAccount.currentState?.validate(),
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'Confirm your password';
              if (val != p.passwordController.text.trim()) {
                return 'Passwords must match';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
              onPressed: () => setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
              ),
            ),
          ),
          SizedBox(height: isWide ? 24 : 18),
          if (p.role == 'Job Seeker') ...[
            _buildJobAlertsCheckbox(p, isWide),
            SizedBox(height: isWide ? 24 : 16),
          ],
          _buildReCaptcha(p),
          SizedBox(height: isWide ? 20 : 16),
          _buildSubmitButton(p, isWide),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isWide, SignupProvider p) {
    final double iconPad = isWide ? 14 : 10;
    final double iconSize = isWide ? 28 : 22;
    final double titleSize = isWide ? 26 : 20;
    final double subSize = isWide ? 13 : 12;

    final isRecruiter = p.role == 'Recruiter';
    final title =
        isRecruiter ? 'Create Recruiter Account' : 'Create Candidate Account';
    final subtitle = isRecruiter
        ? "Find the world's best aviation professionals."
        : 'Begin your aviation career today.';
    final headerIcon = isRecruiter
        ? Icons.business_center_rounded
        : Icons.flight_takeoff_rounded;

    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.1),
            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(iconPad),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              headerIcon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: subSize,
                    color: Colors.grey.shade600,
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

  Widget _buildReCaptcha(SignupProvider provider) {
    // reCAPTCHA is web-only; on mobile, auto-verify
    if (!kIsWeb) {
      if (!provider.isCaptchaVerified) {
        provider.setCaptchaVerified(true, token: 'mobile-bypass');
      }
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 304,
          height: 78,
          child: HtmlElementView(viewType: 'recaptcha-view'),
        ),
        const SizedBox(height: 8),
        if (!provider.isCaptchaVerified)
          Text(
            'Please verify that you are not a robot',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          )
        else
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text(
                'Security verified',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildJobAlertsCheckbox(SignupProvider provider, bool isWide) {
    return GestureDetector(
      onTap: () => provider.toggleJobAlerts(!provider.jobAlertsEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(isWide ? 16 : 12),
        decoration: BoxDecoration(
          color: provider.jobAlertsEnabled
              ? const Color(0xFF6366F1).withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: provider.jobAlertsEnabled
                ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: provider.jobAlertsEnabled ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isWide ? 24 : 22,
              height: isWide ? 24 : 22,
              decoration: BoxDecoration(
                gradient: provider.jobAlertsEnabled
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      )
                    : null,
                color: provider.jobAlertsEnabled ? null : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: provider.jobAlertsEnabled
                      ? Colors.transparent
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: provider.jobAlertsEnabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: provider.jobAlertsEnabled
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: isWide ? 14 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        size: 16,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Job Alerts & Newsletter',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isWide ? 14 : 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Receive email notifications when new positions are posted. '
                    'Get career tips and platform updates.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isWide ? 12 : 11,
                      color: Colors.grey.shade600,
                      height: 1.4,
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

  Widget _buildSubmitButton(SignupProvider provider, bool isWide) {
    final verified = provider.isCaptchaVerified;
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isWide ? 280 : double.infinity,
        decoration: BoxDecoration(
          gradient: verified
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                )
              : LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade200],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: verified ? Colors.transparent : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: verified
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: verified ? () => _handleSubmit(provider) : null,
          icon: Icon(
            verified ? Icons.person_add_rounded : Icons.lock_outline_rounded,
            size: 20,
            color: verified ? Colors.white : Colors.grey.shade500,
          ),
          label: Text(
            verified
                ? (provider.role == 'Recruiter'
                      ? 'Create Recruiter Account'
                      : 'Create Job Seeker Account')
                : 'Verify First',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: verified ? Colors.white : Colors.grey.shade500,
              fontSize: isWide ? 15 : 14,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: isWide ? 18 : 15),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            disabledBackgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(SignupProvider provider) async {
    final okForm = _formKeyAccount.currentState?.validate() ?? false;
    final okEmail = provider.validateEmail();
    final okPass = provider.validatePasswords();

    if (!okForm || !okEmail || !okPass) {
      _showSnackBar('Please fix all errors before proceeding', isError: true);
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildLoadingDialog(),
    );

    try {
      if (provider.role == 'Recruiter') {
        final success = await provider.registerRecruiter();

        if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        if (!mounted) return;

        if (success) {
          _showSnackBar('✓ Account created successfully!', isError: false);
          context.go('/recruiter-dashboard');
        } else {
          _showSnackBar(
            provider.generalError ?? 'Failed to create account',
            isError: true,
          );
        }
      } else {
        final route = await provider.createJobSeekerAccount();

        if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        if (!mounted) return;

        if (route != null) {
          _showSnackBar('✓ Account created successfully!', isError: false);
          await Future.delayed(const Duration(milliseconds: 500));
          // New job seekers begin with the aviation onboarding wizard, then
          // continue to the profile builder (the router enforces this too).
          if (mounted) context.go('/onboarding');
        } else {
          _showSnackBar(
            provider.generalError ?? 'Failed to create account',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Widget _buildLoadingDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.indigo),
            const SizedBox(height: 20),
            Text(
              'Creating Your Account',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait...',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isWide,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int maxLines = 1,
    Widget? suffixIcon,
    String? helperText,
    AutovalidateMode? autovalidateMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
          autovalidateMode:
              autovalidateMode ?? AutovalidateMode.onUserInteraction,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
            helperText: helperText,
            helperStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF6366F1),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(isWide ? 12 : 10),
              padding: EdgeInsets.all(isWide ? 10 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.15),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF6366F1), size: 18),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isWide ? 18 : 14,
            ),
            errorText: errorText,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SignUp_ScreenInner();
  }
}

// ─── INNER WIDGET ─────────────────────────────────────────────────────────────

class _SignUp_ScreenInner extends StatelessWidget {
  const _SignUp_ScreenInner();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SignupProvider>();
    final state = context.findAncestorStateOfType<_SignUp_ScreenState>()!;
    final isWide = MediaQuery.of(context).size.width > 900;

    // Responsive paddings
    final double hPad = isWide ? 32 : 20;
    final double vPad = isWide ? 32 : 20;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            if (isWide) const HeaderNav() else _buildMobileLogoHeader(context),
            Expanded(
              child: Row(
                children: [
                  if (isWide)
                    Flexible(flex: 5, child: state.leftPanel(context)),
                  Flexible(
                    flex: 5,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: hPad,
                        vertical: vPad,
                      ),
                      child: FadeTransition(
                        opacity: state._fadeAnimation,
                        child: SlideTransition(
                          position: state._slideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Mobile brand header
                              state.accountPanel(context, p, isWide),
                              const SizedBox(height: 8),
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Already have an account?',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/login'),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.only(left: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Login',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.indigo,
                                        ),
                                      ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLogoHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/login'),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (ctx, _, _) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Maha Services',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable components ──────────────────────────────────────────────────────

class _CompactMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _CompactMetric({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactFeature extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CompactFeature({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.9),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
