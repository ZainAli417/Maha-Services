import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const navy = Color(0xFF0F172A);
  static const slate600 = Color(0xFF475569);
  static const slate400 = Color(0xFF94A3B8);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate50 = Color(0xFFF8FAFC);
  static const indigo = Color(0xFF4F46E5);
  static const indigoSoft = Color(0xFFEEF2FF);
  static const white = Colors.white;

  static TextStyle label(double size, {Color color = navy}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.1,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  NAV ITEMS
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final String route;
  const _NavItem(this.label, this.route);
}

const _navItems = [
  _NavItem('Home', '/'),
  _NavItem('Find Jobs', '/login'),
  _NavItem('For Recruiters', '/register?role=recruiter'),
];

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER NAV
// ─────────────────────────────────────────────────────────────────────────────
class HeaderNav extends StatelessWidget {
  const HeaderNav({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 900;
    final isMobile = w <= 600;

    return Container(
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.slate200, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop
                ? 40
                : isMobile
                ? 16
                : 24,
            vertical: isMobile ? 6 : 10,
          ),
          child: isDesktop
              ? _buildDesktop(context)
              : _buildCompactRow(context, isMobile),
        ),
      ),
    );
  }

  // ── Desktop: logo · nav links · spacer · Login · Get Started ──
  Widget _buildDesktop(BuildContext context) {
    return Row(
      children: [
        _buildLogo(context, 38),
        const SizedBox(width: 10),
        _buildBrandText(16),
        const SizedBox(width: 36),
        ..._navItems.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: TextButton(
              onPressed: () => context.go(item.route),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                foregroundColor: _T.slate600,
                overlayColor: Colors.transparent,
              ),
              child: Text(item.label, style: _T.label(14, color: _T.slate600)),
            ),
          ),
        ),
        const Spacer(),
        // Login
        OutlinedButton(
          onPressed: () => context.go('/login'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            side: const BorderSide(color: _T.slate200, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            foregroundColor: _T.navy,
            overlayColor: Colors.transparent,
          ),
          child: Text('Login', style: _T.label(13.5, color: _T.navy)),
        ),
        const SizedBox(width: 10),
        // Get Started
        ElevatedButton(
          onPressed: () => context.go('/register'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _T.indigo,
            foregroundColor: _T.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            overlayColor: Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Get Started', style: _T.label(13.5, color: _T.white)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 15),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile / Tablet: Everything in a single compact row ──
  Widget _buildCompactRow(BuildContext context, bool isMobile) {
    return Row(
      children: [
        _buildLogo(context, isMobile ? 32 : 36),
        const SizedBox(width: 8),
        _buildBrandText(isMobile ? 14 : 15),
        const Spacer(),
        // Nav items as compact text buttons in the same row
        ..._navItems
            .where((n) => n.label != 'Home')
            .map(
              (item) => Padding(
                padding: EdgeInsets.only(right: isMobile ? 2 : 6),
                child: TextButton(
                  onPressed: () => context.go(item.route),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 12,
                      vertical: isMobile ? 6 : 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    foregroundColor: _T.slate600,
                    overlayColor: Colors.transparent,
                  ),
                  child: Text(
                    item.label,
                    style: _T.label(isMobile ? 12 : 13, color: _T.slate600),
                  ),
                ),
              ),
            ),
        // Login button
        Container(
          decoration: BoxDecoration(
            color: _T.indigoSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              foregroundColor: _T.indigo,
              overlayColor: Colors.transparent,
            ),
            child: Text(
              'Login',
              style: _T.label(isMobile ? 12 : 13, color: _T.indigo),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared: Logo ──
  Widget _buildLogo(BuildContext context, double size) {
    return GestureDetector(
      onTap: () => context.go('/'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // ── Shared: Brand text ──
  Widget _buildBrandText(double size) {
    return Text(
      'Maha Services',
      style: GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: _T.navy,
        letterSpacing: -0.3,
      ),
    );
  }
}
