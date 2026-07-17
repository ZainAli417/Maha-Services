// admin_login_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:job_portal/Constant/brand_snackbar.dart';
import '../../Constant/Forget Password.dart';
import 'admin_login_provider.dart';

// ─── Brand tokens (navy + teal) ─────────────────────────────────────────────
class _C {
  static const heroDeep = Color(0xFF061C31);
  static const heroMid = Color(0xFF0A2E4F);
  static const heroGlow = Color(0xFF0F4C75);
  static const navy = Color(0xFF14507F);
  static const blue = Color(0xFF2178B5);
  static const teal = Color(0xFF2EC4B6);
  static const tealBright = Color(0xFF43E0D2);
  static const tealDeep = Color(0xFF15A99C);
  static const coral = Color(0xFFFF7A59);
  static const ink = Color(0xFF0B2239);
  static const slate = Color(0xFF3E5C76);
  static const muted = Color(0xFF5E7A8E);
  static const border = Color(0xFFDCE7EF);
  static const bgSoft = Color(0xFFF4F9FB);
  static const tealTint = Color(0xFFE4F6F4);
  static const white = Color(0xFFFFFFFF);
  static const error = Color(0xFFEF4444);
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 700;
    final isWide = w >= 900;

    return Scaffold(
      backgroundColor: _C.bgSoft,
      body: isWide
          ? Row(
              children: [
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(flex: 5, child: _formArea(context, isMobile: false)),
              ],
            )
          : _formArea(context, isMobile: isMobile, showBanner: true),
    );
  }

  // Right/main auth area: white card, branded fields, gradient button.
  Widget _formArea(
    BuildContext context, {
    required bool isMobile,
    bool showBanner = false,
  }) {
    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: isMobile ? 24 : 40,
              ),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showBanner) ...[
                          const _BrandBanner(),
                          SizedBox(height: isMobile ? 20 : 28),
                        ],
                        _FormCard(isMobile: isMobile),
                        if (kIsWeb && showBanner) ...[
                          const SizedBox(height: 20),
                          const _GoHomeButton(dark: false),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // On the wide layout the ghost button sits on the light form side.
          if (kIsWeb && !showBanner)
            const Positioned(
              top: 14,
              right: 18,
              child: _GoHomeButton(dark: false),
            ),
        ],
      ),
    );
  }
}

// ─── Left decorative brand panel (wide screens) ─────────────────────────────
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_C.heroDeep, _C.heroMid, _C.heroGlow],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft brand glow orbs (static — zero repaint cost).
            const _GlowOrb(
              top: -70,
              left: -60,
              size: 340,
              color: _C.teal,
              opacity: 0.22,
            ),
            const _GlowOrb(
              bottom: -50,
              right: -70,
              size: 320,
              color: _C.blue,
              opacity: 0.20,
            ),
            const _GlowOrb(
              top: 210,
              right: 30,
              size: 170,
              color: _C.tealBright,
              opacity: 0.12,
            ),
            if (kIsWeb)
              const Positioned(
                top: 22,
                right: 24,
                child: _GoHomeButton(dark: true),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 44,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandLogo(size: 78),
                    const SizedBox(height: 28),
                    const _SecurePill(),
                    const SizedBox(height: 22),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Colors.white, _C.tealBright],
                      ).createShader(b),
                      child: Text(
                        'Admin Portal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.08,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Text(
                        'Secure, role-restricted access to the Maha Services '
                        'control center. Manage users, content, and platform '
                        'operations with confidence.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    const _PanelFeature(
                      icon: Icons.verified_user_rounded,
                      label: 'Role-based access control',
                    ),
                    const _PanelFeature(
                      icon: Icons.lock_rounded,
                      label: 'AES-256 encrypted sessions',
                    ),
                    const _PanelFeature(
                      icon: Icons.monitor_heart_rounded,
                      label: 'Real-time platform monitoring',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact top banner (mobile / narrow screens) ───────────────────────────
class _BrandBanner extends StatelessWidget {
  const _BrandBanner();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_C.heroDeep, _C.heroMid, _C.heroGlow],
            stops: [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _C.heroDeep.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -40,
              right: -30,
              child: _GlowOrb(size: 150, color: _C.teal, opacity: 0.22),
            ),
            Column(
              children: [
                const _BrandLogo(size: 58),
                const SizedBox(height: 14),
                Text(
                  'Admin Portal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Secure access to the control center',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Circular logo ──────────────────────────────────────────────────────────
class _BrandLogo extends StatelessWidget {
  final double size;
  const _BrandLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
        boxShadow: [
          BoxShadow(
            color: _C.teal.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'images/logo_new.jpeg',
        fit: BoxFit.cover,
        cacheWidth: 176,
      ),
    );
  }
}

// ─── Static glow orb ────────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final double? top, left, right, bottom;
  final double size;
  final Color color;
  final double opacity;
  const _GlowOrb({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: opacity), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Secure-access pill ─────────────────────────────────────────────────────
class _SecurePill extends StatelessWidget {
  const _SecurePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _C.teal.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, size: 14, color: _C.tealBright),
          const SizedBox(width: 8),
          Text(
            'SECURE ACCESS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: _C.tealBright,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Panel feature row ──────────────────────────────────────────────────────
class _PanelFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PanelFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_C.teal, _C.tealDeep]),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _C.teal.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Login form card ────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final bool isMobile;
  const _FormCard({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminAuthProvider>();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 460),
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: _C.ink.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header ────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_C.teal, _C.navy]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _C.teal.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_rounded, color: _C.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADMIN ACCESS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: _C.tealDeep,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sign In',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 21 : 24,
                        fontWeight: FontWeight.w800,
                        color: _C.ink,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Access your admin dashboard',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: _C.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 22 : 28),

          // ── Email ──────────────────────────────────────────────────
          _Field(
            label: 'Email Address',
            hint: 'admin@company.com',
            icon: Icons.email_outlined,
            controller: prov.emailController,
            required: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // ── Password ───────────────────────────────────────────────
          _Field(
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            controller: prov.passwordController,
            required: true,
            obscure: prov.obscurePassword,
            textInputAction: TextInputAction.done,
            suffix: GestureDetector(
              onTap: prov.toggleObscure,
              child: Icon(
                prov.obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: _C.muted,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Forgot password ────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: _TextLink(
              label: 'Forgot password?',
              onTap: () => ForgotPasswordModal.show(context),
            ),
          ),
          const SizedBox(height: 22),

          // ── Error message (branded) ────────────────────────────────
          if (prov.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _C.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _C.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: _C.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      prov.errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: _C.error,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Sign in button ─────────────────────────────────────────
          _PrimaryButton(
            isLoading: prov.isLoading,
            isMobile: isMobile,
            onPressed: () async {
              final success = await prov.signIn();
              if (success) {
                if (context.mounted) context.go('/admin_dashboard');
              } else {
                if (prov.errorMessage != null && context.mounted) {
                  BrandSnack.error(context, prov.errorMessage!);
                }
              }
            },
          ),
          const SizedBox(height: 24),

          // ── Divider ────────────────────────────────────────────────
          Row(
            children: [
              const Expanded(child: Divider(color: _C.border, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'SECURED BY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: _C.muted,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: _C.border, thickness: 1)),
            ],
          ),
          const SizedBox(height: 18),

          // ── Security badges ────────────────────────────────────────
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 10,
            children: [
              _SecurityBadge(icon: Icons.shield_outlined, label: 'SSL Encrypted'),
              _SecurityBadge(
                icon: Icons.verified_user_outlined,
                label: 'Firebase Auth',
              ),
              _SecurityBadge(icon: Icons.lock_clock_outlined, label: '2FA Ready'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Branded form field ─────────────────────────────────────────────────────
class _Field extends StatefulWidget {
  final String label, hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final bool required;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _Field({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.required = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: widget.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _C.slate,
            ),
            children: widget.required
                ? [
                    TextSpan(
                      text: ' *',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _C.coral,
                      ),
                    ),
                  ]
                : const [],
          ),
        ),
        const SizedBox(height: 7),
        Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: _C.navy.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _C.ink,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _C.muted,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 8),
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _C.tealTint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(widget.icon, size: 18, color: _C.tealDeep),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                suffixIcon: widget.suffix != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: widget.suffix,
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                filled: true,
                fillColor: _C.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.border, width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.border, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.navy, width: 1.6),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.error, width: 1.4),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _C.error, width: 1.6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Primary (gradient) sign-in button ──────────────────────────────────────
class _PrimaryButton extends StatefulWidget {
  final bool isLoading;
  final bool isMobile;
  final VoidCallback onPressed;
  const _PrimaryButton({
    required this.isLoading,
    required this.isMobile,
    required this.onPressed,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: widget.isMobile ? 50 : 52,
        decoration: BoxDecoration(
          gradient: widget.isLoading
              ? LinearGradient(
                  colors: [
                    _C.teal.withValues(alpha: 0.55),
                    _C.navy.withValues(alpha: 0.55),
                  ],
                )
              : const LinearGradient(colors: [_C.teal, _C.navy]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.isLoading
              ? const []
              : [
                  BoxShadow(
                    color: _C.teal.withValues(alpha: _hovered ? 0.42 : 0.28),
                    blurRadius: _hovered ? 20 : 14,
                    offset: Offset(0, _hovered ? 8 : 5),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withValues(alpha: 0.12),
            child: Center(
              child: widget.isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Signing in…',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign In to Dashboard',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSlide(
                          offset: _hovered ? const Offset(0.2, 0) : Offset.zero,
                          duration: const Duration(milliseconds: 160),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
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

// ─── Text link ──────────────────────────────────────────────────────────────
class _TextLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _TextLink({required this.label, required this.onTap});

  @override
  State<_TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<_TextLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _hovered ? _C.navy : _C.tealDeep,
            decoration: _hovered
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: _C.navy,
          ),
        ),
      ),
    );
  }
}

// ─── Security badge ─────────────────────────────────────────────────────────
class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SecurityBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _C.muted),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            color: _C.slate,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Go-home ghost / glass button ───────────────────────────────────────────
class _GoHomeButton extends StatefulWidget {
  final bool dark;
  const _GoHomeButton({required this.dark});

  @override
  State<_GoHomeButton> createState() => _GoHomeButtonState();
}

class _GoHomeButtonState extends State<_GoHomeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final fg = dark ? Colors.white : _C.navy;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: _hovered ? 0.16 : 0.08)
                : (_hovered ? _C.navy.withValues(alpha: 0.06) : _C.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: _hovered ? 0.6 : 0.35)
                  : _C.navy.withValues(alpha: _hovered ? 0.5 : 0.35),
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_outlined, size: 16, color: fg),
              const SizedBox(width: 7),
              Text(
                'Go to Home',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
