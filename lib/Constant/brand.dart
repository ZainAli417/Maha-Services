import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Maha HR Services — shared brand system.
///
/// Navy + teal palette derived from `images/logo_new.jpeg`, plus the animated
/// hero backdrop and CTA widgets used on the landing page. Import this on the
/// pricing / login / signup screens so every entry-point shares one identity.
/// ═══════════════════════════════════════════════════════════════════════════
class Brand {
  // Dark hero surfaces
  static const heroDeep = Color(0xFF061C31);
  static const heroMid = Color(0xFF0A2E4F);
  static const heroGlow = Color(0xFF0F4C75);

  // Core brand
  static const navy = Color(0xFF14507F);
  static const blue = Color(0xFF2178B5);
  static const teal = Color(0xFF2EC4B6);
  static const tealBright = Color(0xFF43E0D2);
  static const tealDeep = Color(0xFF15A99C);

  // Warm accents
  static const coral = Color(0xFFFF7A59);
  static const amber = Color(0xFFFFB020);

  // Light-section neutrals
  static const ink = Color(0xFF0B2239);
  static const slate = Color(0xFF3E5C76);
  static const muted = Color(0xFF5E7A8E);
  static const faint = Color(0xFF8AA5B5);
  static const border = Color(0xFFDCE7EF);
  static const bgSoft = Color(0xFFF4F9FB);
  static const tealTint = Color(0xFFE4F6F4);
  static const navyTint = Color(0xFFE8F1F8);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [heroDeep, heroMid, heroGlow],
    stops: [0.0, 0.55, 1.0],
  );

  static const primaryGradient = LinearGradient(
    colors: [teal, tealDeep, navy],
  );

  static TextStyle font(double size, FontWeight w, Color c,
          {double? height, double? spacing}) =>
      GoogleFonts.plusJakartaSans(
          fontSize: size,
          fontWeight: w,
          color: c,
          height: height,
          letterSpacing: spacing);
}

// ═══ ANIMATED HERO BACKDROP ══════════════════════════════════════════════════
/// Self-contained widget: fills its parent with the navy hero gradient plus a
/// looping aurora-blob + particle animation. Drop it into a `Stack`'s
/// `Positioned.fill` or use directly as a background.
class BrandBackdrop extends StatefulWidget {
  const BrandBackdrop({super.key, this.showGradient = true});

  /// When false, paints only the animated blobs/particles (transparent base) —
  /// use over a surface that already has the hero gradient.
  final bool showGradient;

  @override
  State<BrandBackdrop> createState() => _BrandBackdropState();
}

class _BrandBackdropState extends State<BrandBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 26))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: widget.showGradient ? Brand.heroGradient : null,
      ),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _BackdropPainter(_c.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double x, y, r, speed, phase;
  final bool teal;
  const _Particle(this.x, this.y, this.r, this.speed, this.phase, this.teal);
}

class _BackdropPainter extends CustomPainter {
  final double t;
  _BackdropPainter(this.t);

  static final List<_Particle> _particles = _gen();
  static List<_Particle> _gen() {
    final rnd = math.Random(7);
    return List.generate(
      56,
      (_) => _Particle(
        rnd.nextDouble(),
        rnd.nextDouble(),
        0.8 + rnd.nextDouble() * 2.2,
        0.02 + rnd.nextDouble() * 0.07,
        rnd.nextDouble(),
        rnd.nextDouble() > 0.4,
      ),
    );
  }

  void _blob(Canvas canvas, Offset c, double r, Color color) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
          c, r, [color, color.withValues(alpha: 0)], [0.0, 1.0]);
    canvas.drawCircle(c, r, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final a = t * 2 * math.pi;

    _blob(
        canvas,
        Offset(w * 0.82 + 40 * math.sin(a), h * 0.18 + 30 * math.cos(a)),
        w * 0.34,
        Brand.teal.withValues(alpha: 0.16));
    _blob(
        canvas,
        Offset(w * 0.12 + 34 * math.cos(a * 0.8),
            h * 0.78 + 26 * math.sin(a * 0.8)),
        w * 0.30,
        Brand.blue.withValues(alpha: 0.18));
    _blob(
        canvas,
        Offset(w * 0.55 + 50 * math.sin(a * 0.6 + 1.7),
            h * 0.05 + 20 * math.cos(a * 0.6)),
        w * 0.20,
        Brand.coral.withValues(alpha: 0.08));
    _blob(
        canvas,
        Offset(w * 0.38 + 30 * math.cos(a * 1.2),
            h * 0.95 + 24 * math.sin(a * 1.2)),
        w * 0.24,
        Brand.tealDeep.withValues(alpha: 0.12));

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawPath(
        Path()
          ..moveTo(-40, h * 0.7)
          ..quadraticBezierTo(w * 0.4, h * 0.2, w + 40, h * 0.55),
        arc);
    canvas.drawPath(
        Path()
          ..moveTo(-40, h * 0.35)
          ..quadraticBezierTo(w * 0.55, h * 0.9, w + 40, h * 0.25),
        arc);

    for (final p in _particles) {
      final y = (p.y - t * p.speed * 4) % 1.0;
      final yy = y < 0 ? y + 1.0 : y;
      final twinkle =
          0.22 + 0.30 * (0.5 + 0.5 * math.sin(a * 2 + p.phase * 6.28));
      final color = p.teal
          ? Brand.tealBright.withValues(alpha: twinkle)
          : Colors.white.withValues(alpha: twinkle * 0.8);
      canvas.drawCircle(Offset(p.x * w, yy * h), p.r, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.t != t;
}

// ═══ PULSING DOT ═════════════════════════════════════════════════════════════
class BrandPulseDot extends StatefulWidget {
  const BrandPulseDot({super.key, this.color = Brand.tealBright, this.size = 8});
  final Color color;
  final double size;

  @override
  State<BrandPulseDot> createState() => _BrandPulseDotState();
}

class _BrandPulseDotState extends State<BrandPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: widget.color.withValues(alpha: 0.7),
                blurRadius: 4 + 8 * _c.value,
                spreadRadius: 1 + 2 * _c.value),
          ],
        ),
      ),
    );
  }
}

// ═══ GLOW BUTTON (primary gradient CTA) ══════════════════════════════════════
class BrandGlowButton extends StatefulWidget {
  const BrandGlowButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expand = false,
    this.loading = false,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool expand;
  final bool loading;

  @override
  State<BrandGlowButton> createState() => _BrandGlowButtonState();
}

class _BrandGlowButtonState extends State<BrandGlowButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(_hover && !widget.expand ? 1.03 : 1.0),
      transformAlignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _hover
              ? [Brand.tealBright, Brand.teal, Brand.blue]
              : [Brand.teal, Brand.tealDeep, Brand.navy],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Brand.teal.withValues(alpha: _hover ? 0.55 : 0.3),
              blurRadius: _hover ? 24 : 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: widget.loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white))
          : Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.label,
                    style: Brand.font(15, FontWeight.w700, Colors.white)),
                if (widget.icon != null) ...[
                  const SizedBox(width: 8),
                  AnimatedSlide(
                    offset: Offset(_hover ? 0.25 : 0, 0),
                    duration: const Duration(milliseconds: 180),
                    child: Icon(widget.icon, size: 18, color: Colors.white),
                  ),
                ],
              ],
            ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: widget.expand ? SizedBox(width: double.infinity, child: child) : child,
      ),
    );
  }
}

// ═══ GLASS BUTTON (secondary CTA on dark) ════════════════════════════════════
class BrandGlassButton extends StatefulWidget {
  const BrandGlassButton(
      {super.key, required this.label, required this.onTap, this.icon});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<BrandGlassButton> createState() => _BrandGlassButtonState();
}

class _BrandGlassButtonState extends State<BrandGlassButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _hover ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.white.withValues(alpha: _hover ? 0.6 : 0.3),
                width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(widget.label,
                  style: Brand.font(15, FontWeight.w700, Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══ HOVER HELPER ════════════════════════════════════════════════════════════
class BrandHoverable extends StatefulWidget {
  const BrandHoverable({super.key, required this.builder});
  final Widget Function(bool hover) builder;

  @override
  State<BrandHoverable> createState() => _BrandHoverableState();
}

class _BrandHoverableState extends State<BrandHoverable> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: widget.builder(_hover),
    );
  }
}

// ═══ COUNT-UP NUMBER ═════════════════════════════════════════════════════════
class BrandCountUp extends StatelessWidget {
  const BrandCountUp(
      {super.key,
      required this.end,
      required this.suffix,
      required this.style,
      required this.accent});
  final double end;
  final String suffix;
  final TextStyle style;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: end),
      builder: (_, v, _) => RichText(
        text: TextSpan(
          text: v.round().toString(),
          style: style,
          children: [
            TextSpan(text: suffix, style: style.copyWith(color: accent)),
          ],
        ),
      ),
    );
  }
}

// ═══ SHARED "DARK PANEL" (left side of login / signup) ═══════════════════════
/// Glassmorphic marketing panel shown beside auth forms on wide screens.
class BrandAuthPanel extends StatelessWidget {
  const BrandAuthPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.features,
  });

  final String title;
  final String subtitle;
  final List<(IconData, String)> features;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const BrandBackdrop(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: Brand.teal.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandPulseDot(),
                      const SizedBox(width: 9),
                      Text('LIVE · SECURE PLATFORM',
                          style: Brand.font(
                              10.5, FontWeight.w700, Brand.tealBright,
                              spacing: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Colors.white, Brand.tealBright],
                  ).createShader(b),
                  child: Text(title,
                      style: Brand.font(40, FontWeight.w800, Colors.white,
                          height: 1.08, spacing: -1)),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Text(subtitle,
                      style: Brand.font(15, FontWeight.w500,
                          Colors.white.withValues(alpha: 0.75),
                          height: 1.6)),
                ),
                const SizedBox(height: 34),
                for (final f in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Brand.teal, Brand.tealDeep]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Brand.teal.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Icon(f.$1, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Text(f.$2,
                            style: Brand.font(14.5, FontWeight.w600,
                                Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                // Trust stats
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _stat('15K+', 'Hired'),
                      _divider(),
                      _stat('98%', 'Success'),
                      _divider(),
                      _stat('24h', 'Response'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: Colors.white.withValues(alpha: 0.16));

  Widget _stat(String v, String l) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(v, style: Brand.font(20, FontWeight.w800, Colors.white)),
          Text(l,
              style: Brand.font(
                  11, FontWeight.w600, Colors.white.withValues(alpha: 0.6))),
        ],
      );
}
