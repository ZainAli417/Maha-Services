// admin_login_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_snackbars.dart';
import '../../Constant/Forget Password.dart';
import 'admin_login_provider.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const _ink = Color(0xFF0D1B2A); // near-black text
const _indigo = Color(0xFF6366F1); // primary accent
const _indigoLt = Color(0xFF4C6EF5); // lighter shade
const _slate = Color(0xFF64748B); // muted text
const _border = Color(0xFFDDE1E7);
const _fill = Color(0xFFFAFAFA);
const _white = Color(0xFFFFFFFF);
const _errBg = Color(0xFFFFF1F0);
const _errBorder = Color(0xFFFFCDD2);
const _errText = Color(0xFFD32F2F);

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
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;
    final isWide = w >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // ── Static decorative background — zero repaint cost ─────────
          const _StaticBackground(),

          // ── Nav bar (web only) ───────────────────────────────────────
          if (kIsWeb) _NavBar(isMobile: isMobile),

          // ── Main content ─────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 40,
                  vertical: isMobile ? 72 : 48,
                ),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1160),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Expanded(flex: 5, child: _LeftPanel()),
                                SizedBox(width: 56),
                                Expanded(flex: 4, child: _FormCard()),
                              ],
                            )
                          : const Column(
                              children: [
                                _LeftPanel(),
                                SizedBox(height: 40),
                                _FormCard(),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Static Background (no animation = zero CPU overhead) ────────────────────
class _StaticBackground extends StatelessWidget {
  const _StaticBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: CustomPaint(painter: _DotGridPainter()));
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B5BDB).withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    const radius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }

    // Soft right-side radial wash
    final grad = RadialGradient(
      center: const Alignment(0.85, -0.6),
      radius: 0.9,
      colors: [
        const Color(0xFF3B5BDB).withValues(alpha: 0.06),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = grad,
    );
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false; // static — never repaints
}

// ─── Nav Bar ──────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final bool isMobile;
  const _NavBar({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 36,
            vertical: isMobile ? 12 : 18,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand mark
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _indigo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: _white,
                      size: 20,
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 10),
                    Text(
                      'ADMIN PORTAL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: _ink,
                      ),
                    ),
                  ],
                ],
              ),
              // Go home button
              _OutlineButton(
                label: 'Go to Home',
                icon: Icons.home_outlined,
                onTap: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Left Info Panel ──────────────────────────────────────────────────────────
class _LeftPanel extends StatelessWidget {
  const _LeftPanel();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;

    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        // Badge
        _PillBadge(
          icon: Icons.verified_user_rounded,
          label: 'SECURE ACCESS',
          color: _indigo,
        ),
        const SizedBox(height: 22),

        // Headline
        Text(
          isMobile ? 'Admin Control Panel' : 'Admin Control Panel',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 30 : 44,
            fontWeight: FontWeight.w800,
            height: 1.18,
            color: _ink,
            letterSpacing: -0.5,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 16),

        // Sub-text
        Text(
          'Manage your platform with powerful tools and '
          'comprehensive analytics. Access user management, '
          'system settings, and real-time monitoring.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 13 : 15,
            height: 1.65,
            color: _slate,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 10),

        // // Feature cards
        // Wrap(
        //   spacing: 10,
        //   runSpacing: 10,
        //   alignment:
        //   isMobile ? WrapAlignment.center : WrapAlignment.start,
        //   children: const [
        //     _FeatureChip(
        //         icon: Icons.people_alt_outlined,
        //         label: 'User Management',
        //         color: _indigo),
        //     _FeatureChip(
        //         icon: Icons.analytics_outlined,
        //         label: 'Analytics',
        //         color: Color(0xFF0CA678)),
        //     _FeatureChip(
        //         icon: Icons.security_outlined,
        //         label: 'Security Center',
        //         color: Color(0xFFE67E22)),
        //     _FeatureChip(
        //         icon: Icons.tune_rounded,
        //         label: 'System Settings',
        //         color: Color(0xFF7048E8)),
        //   ],
        // ),
        if (!isMobile) ...[
          const SizedBox(height: 44),
          // Divider line with text
          Row(
            children: [
              Container(width: 32, height: 2, color: _indigo),
              const SizedBox(width: 12),
              Text(
                'TRUSTED ADMIN DASHBOARD',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: _slate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: const [
              _StatItem(value: '99.9%', label: 'Uptime'),
              SizedBox(width: 32),
              _StatItem(value: 'AES-256', label: 'Encryption'),
              SizedBox(width: 32),
              _StatItem(value: '2FA', label: 'Ready'),
            ],
          ),
        ],
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PillBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<_FeatureChip> createState() => _FeatureChipState();
}

class _FeatureChipState extends State<_FeatureChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: _hovered ? widget.color.withValues(alpha: 0.07) : _white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? widget.color.withValues(alpha: 0.35) : _border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, size: 16, color: widget.color),
            ),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _indigo,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: _slate,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Login Form Card ──────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  const _FormCard();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminAuthProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: EdgeInsets.all(isMobile ? 24 : 36),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _indigo.withValues(alpha: 0.04),
            blurRadius: 48,
            offset: const Offset(0, 20),
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
                  color: _indigo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_rounded, color: _white, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign In',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Access your admin dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: _slate,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Email ──────────────────────────────────────────────────
          _Field(
            label: 'Email Address',
            hint: 'admin@company.com',
            icon: Icons.email_outlined,
            controller: prov.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),

          // ── Password ───────────────────────────────────────────────
          _Field(
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_outline_rounded,
            controller: prov.passwordController,
            obscure: prov.obscurePassword,
            textInputAction: TextInputAction.done,
            suffix: GestureDetector(
              onTap: prov.toggleObscure,
              child: Icon(
                prov.obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: _slate,
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
          const SizedBox(height: 24),

          // ── Error message ──────────────────────────────────────────
          if (prov.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _errBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _errBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: _errText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      prov.errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _errText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // ── Sign in button ─────────────────────────────────────────
          _SignInButton(
            isLoading: prov.isLoading,
            onPressed: () async {
              final success = await prov.signIn();
              if (success) {
                if (context.mounted) context.go('/admin_dashboard');
              } else {
                if (prov.errorMessage != null && context.mounted) {
                  CustomSnackbars.showError(context, prov.errorMessage!);
                }
              }
            },
          ),
          const SizedBox(height: 28),

          // ── Divider ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: Divider(color: _border, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'SECURED BY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                    color: _slate.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Expanded(child: Divider(color: _border, thickness: 1)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Security badges ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _Badge(icon: Icons.shield_outlined, label: 'SSL Encrypted'),
              SizedBox(width: 20),
              _Badge(
                icon: Icons.verified_user_outlined,
                label: 'Firebase Auth',
              ),
              SizedBox(width: 20),
              _Badge(icon: Icons.lock_clock_outlined, label: '2FA Ready'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Field ────────────────────────────────────────────────────────────────────
class _Field extends StatefulWidget {
  final String label, hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _Field({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
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
        Text(
          widget.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _ink,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 7),
        Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: _indigo.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _ink),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: _slate.withValues(alpha: 0.55),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: _focused ? _indigo : _slate.withValues(alpha: 0.7),
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
                fillColor: _focused ? const Color(0xFFF4F6FF) : _fill,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: _indigo, width: 1.8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sign In Button ───────────────────────────────────────────────────────────
class _SignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  const _SignInButton({required this.isLoading, required this.onPressed});

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isLoading
        ? _slate.withValues(alpha: 0.4)
        : (_hovered ? _indigoLt : _indigo);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.isLoading
              ? []
              : [
                  BoxShadow(
                    color: _indigo.withValues(alpha: _hovered ? 0.38 : 0.22),
                    blurRadius: _hovered ? 18 : 12,
                    offset: Offset(0, _hovered ? 6 : 4),
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
                            fontWeight: FontWeight.w600,
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
                            fontWeight: FontWeight.w600,
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

// ─── Text Link ────────────────────────────────────────────────────────────────
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _hovered ? _indigo : _slate,
            decoration: _hovered
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: _indigo,
          ),
        ),
      ),
    );
  }
}

// ─── Security Badge ───────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _slate.withValues(alpha: 0.55)),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: _slate.withValues(alpha: 0.65),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Outline Button ───────────────────────────────────────────────────────────
class _OutlineButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? _indigo.withValues(alpha: 0.06) : _white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? _indigo.withValues(alpha: 0.4) : _border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: _hovered ? _indigo : _slate),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? _indigo : _slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
