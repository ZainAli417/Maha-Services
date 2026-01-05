// lib/screens/signup_screen_auth.dart - SIMPLIFIED VERSION (ACCOUNT CREATION ONLY)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:job_portal/SignUp%20/signup_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Constant/Header_Nav.dart';

class SignUp_Screen extends StatefulWidget {
  const SignUp_Screen({super.key});

  @override
  State<SignUp_Screen> createState() => _SignUp_ScreenState();
}

class _SignUp_ScreenState extends State<SignUp_Screen> with TickerProviderStateMixin {
  final _formKeyAccount = GlobalKey<FormState>();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<SignupProvider>(context, listen: false);
      p.clearAll();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        margin: const EdgeInsets.all(16),
        duration: Duration(milliseconds: isError ? 3500 : 2500),
      ),
    );
  }



  Widget leftPanel(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F0F23),
            const Color(0xFF1a1a3e),
            const Color(0xFF2d1b4e),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated background orbs
          _buildAnimatedOrbs(),

          // Glass noise texture overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.network(
                'https://grainy-gradients.vercel.app/noise.svg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main content - NO SCROLL
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompactHeader(),
                  const SizedBox(height: 15,),
                  _buildLiveMetrics(),
                  const SizedBox(height: 15,),
                  _buildCompactStats(),
                  const SizedBox(height: 15,),
                  _buildCompactFeatures(),
                  const SizedBox(height: 15,),
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
          builder: (context, child) {
            return Positioned(
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
            );
          },
        ),
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Positioned(
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
            color: const Color(0xFF667eea).withOpacity(0.15),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: const Color(0xFF667eea).withOpacity(0.3),
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
                      color: const Color(0xFF4ade80).withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
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
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.white.withOpacity(0.6),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveMetrics() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
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
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
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
                      color: const Color(0xFF667eea).withOpacity(0.4),
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
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AES-256 • Hash Algorithm',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
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
                  style: GoogleFonts.poppins(
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
      },
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
            icon: Icons.work_outline_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CompactMetric(
            value: '342',
            label: 'Online',
            color: const Color(0xFF4ade80),
            icon: Icons.people_outline_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CompactMetric(
            value: '5.4K',
            label: 'Hires',
            color: const Color(0xFFf093fb),
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
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        _CompactFeature(
          icon: Icons.auto_awesome_rounded,
          title: 'AI-Powered Matching',
        ),
        const SizedBox(height: 10),
        _CompactFeature(
          icon: Icons.speed_rounded,
          title: 'Seek More Borderless Jobs',
        ),
        const SizedBox(height: 10),
        _CompactFeature(
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
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TrustBadge(icon: Icons.shield_outlined, label: '256-bit'),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withOpacity(0.1),
          ),
          _TrustBadge(icon: Icons.verified_outlined, label: 'SOC 2'),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withOpacity(0.1),
          ),
          _TrustBadge(icon: Icons.security_outlined, label: 'GDPR'),
        ],
      ),
    );
  }





// --- Reusable Components (DRY Principle) ---




























  // ========== ACCOUNT PANEL ==========
  Widget accountPanel(BuildContext context, SignupProvider p) {
    final provider = context.watch<SignupProvider>();

    return Form(
      key: _formKeyAccount,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_circle_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start your journey to find the perfect opportunity',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Role selector
          _buildRoleSelector(p),

          const SizedBox(height: 28),

          // RECRUITER FLOW
          if (provider.role == 'recruiter') ...[
            _buildEnhancedTextField(
              controller: provider.nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name required';
                return null;
              },
            ),

            const SizedBox(height: 18),

            _buildEnhancedTextField(
              controller: provider.emailController,
              label: 'Email Address',
              hint: 'your.email@company.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              errorText: provider.emailError,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email required';
                final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                if (!emailRegex.hasMatch(v.trim())) return 'Enter valid email';
                return null;
              },
            ),

            const SizedBox(height: 18),

            _buildEnhancedTextField(
              controller: provider.passwordController,
              label: 'Password',
              hint: 'Create a strong password (min. 8 characters)',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              errorText: provider.passwordError,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password required';
                if (v.length < 8) return 'Minimum 8 characters';
                return null;
              },
            ),

            const SizedBox(height: 18),

            _buildEnhancedTextField(
              controller: provider.confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              errorText: provider.passwordError,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != provider.passwordController.text) {
                  return 'Passwords must match';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // FIXED SIGNUP BUTTON FOR RECRUITERS
            Center(
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Validate form
                    final okForm =
                        _formKeyAccount.currentState?.validate() ?? false;
                    final okEmail = provider.validateEmail();
                    final okPass = provider.validatePasswords();
                    final okName = provider.nameController.text
                        .trim()
                        .isNotEmpty;

                    if (!okForm || !okEmail || !okPass || !okName) {
                      _showSnackBar(
                        'Please fix all errors before proceeding',
                        isError: true,
                      );
                      return;
                    }

                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogCtx) => _buildLoadingDialog(),
                    );

                    try {
                      // Register recruiter
                      final success = await provider.registerRecruiter();

                      // Close loading dialog
                      if (mounted &&
                          Navigator.of(context, rootNavigator: true).canPop()) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      // Small delay for smooth transition
                      await Future.delayed(const Duration(milliseconds: 300));

                      if (success) {
                        _showSnackBar(
                          '✓ Recruiter account created successfully!',
                          isError: false,
                        );

                        // Navigation happens automatically via router
                        // The router will detect auth state and redirect to dashboard
                      } else {
                        _showSnackBar(
                          provider.generalError ?? 'Failed to create account',
                          isError: true,
                        );
                      }
                    } catch (e) {
                      // Close loading dialog on error
                      if (mounted &&
                          Navigator.of(context, rootNavigator: true).canPop()) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      _showSnackBar('Error: ${e.toString()}', isError: true);
                    }
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  label: Text(
                    'Create Recruiter Account',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ]
          // JOB SEEKER FLOW
          else ...[
            _buildEnhancedTextField(
              controller: p.emailController,
              label: 'Email Address',
              hint: 'your.email@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              errorText: p.emailError,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email required';
                final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                if (!emailRegex.hasMatch(v.trim())) return 'Enter valid email';
                return null;
              },
            ),

            const SizedBox(height: 18),

            _buildEnhancedTextField(
              controller: p.passwordController,
              label: 'Password',
              hint: 'Create a strong password (min. 8 characters)',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              errorText: p.passwordError,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password required';
                if (v.length < 8) return 'Minimum 8 characters';
                return null;
              },
            ),

            const SizedBox(height: 18),

            _buildEnhancedTextField(
              controller: p.confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              errorText: p.passwordError,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != p.passwordController.text) {
                  return 'Passwords must match';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),

            Center(
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Validate form
                    final okForm = _formKeyAccount.currentState?.validate() ?? false;
                    final okEmail = provider.validateEmail();
                    final okPass = provider.validatePasswords();


                    if (!okForm || !okEmail || !okPass) {
                      _showSnackBar(
                        'Please fix all errors before proceeding',
                        isError: true,
                      );
                      return;
                    }

                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogCtx) => _buildLoadingDialog(),
                    );

                    try {
                      // Register recruiter
                      final success = await provider.createJobSeekerAccount();

                      // Close loading dialog
                      if (mounted &&
                          Navigator.of(context, rootNavigator: true).canPop()) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      // Small delay for smooth transition
                      await Future.delayed(const Duration(milliseconds: 300));

                      if (success) {
                        _showSnackBar(
                          '✓ Account Created successfully!',
                          isError: false,
                        );

                        // Navigation happens automatically via router
                        // The router will detect auth state and redirect to dashboard
                      } else {
                        _showSnackBar(
                          provider.generalError ?? 'Failed to create account',
                          isError: true,
                        );
                      }
                    } catch (e) {
                      // Close loading dialog on error
                      if (mounted &&
                          Navigator.of(context, rootNavigator: true).canPop()) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      _showSnackBar('Error: ${e.toString()}', isError: true);
                    }
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  label: Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 20),
            Text('Creating Your Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Please wait...', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }


  Widget _buildRoleSelector(SignupProvider p) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleChip(
              label: 'Job Seeker',
              icon: Icons.person_search_rounded,
              isSelected: p.role == 'job_seeker',
              onTap: () => p.setRole('job_seeker'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildRoleChip(
              label: 'Recruiter',
              icon: Icons.business_center_rounded,
              isSelected: p.role == 'recruiter',
              onTap: () => p.setRole('recruiter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
          colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        )
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.15),
                    const Color(0xFF8B5CF6).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignupProvider(),
      child: const _SignUp_ScreenInner(),
    );
  }
}

// ========== INNER WIDGET ==========
class _SignUp_ScreenInner extends StatelessWidget {
  const _SignUp_ScreenInner();

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<SignupProvider>(context);
    final state = context.findAncestorStateOfType<_SignUp_ScreenState>()!;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderNav(),
            Expanded(
              child: Row(
                children: [
                  if (isWide) Flexible(flex: 5, child: RepaintBoundary(child: state.leftPanel(context))),
                  Flexible(
                    flex: 5,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.all(32),
                          child: FadeTransition(
                            opacity: state._fadeAnimation,
                            child: SlideTransition(
                              position: state._slideAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isWide) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.indigo,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(Icons.work_outline_rounded, color: Colors.white, size: 24),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Maha Services',
                                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                  ],
                                  state.accountPanel(context, p),
                                  SizedBox(height: 10),
                                  Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Already have an account?', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                                        TextButton(
                                          onPressed: () => context.go('/login'),
                                          child: Text('Login', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
}




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
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
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

  const _CompactFeature({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.5), size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}