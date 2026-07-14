import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'brand.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  GLOBAL SITE HEADER — one nav bar shared across every screen.
//  White surface, brand logo + wordmark, static (no-hover) text links, and the
//  Login / Get Started actions. Responsive: links collapse on small widths.
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final String route;
  const _NavItem(this.label, this.route);
}

const _navItems = [
  _NavItem('Home', '/'),
  _NavItem('Pricing', '/pricing'),
  _NavItem('For Recruiters', '/register?role=recruiter'),
];

class HeaderNav extends StatelessWidget {
  const HeaderNav({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 900;
    final isMobile = w <= 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
            bottom: BorderSide(color: Brand.border, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Brand.ink.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
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
            vertical: isMobile ? 8 : 12,
          ),
          child: Row(
            children: [
              _logo(context, isMobile ? 36 : 42),
              const SizedBox(width: 10),
              _wordmark(context, isMobile),
              if (isDesktop) ...[
                const SizedBox(width: 32),
                for (final item in _navItems) _navLink(context, item),
              ],
              const Spacer(),
              _ghostButton(context, 'Login', () => context.go('/login'),
                  isMobile),
              const SizedBox(width: 8),
              _glowButton(context, 'Get Started', () => context.go('/register'),
                  isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo(BuildContext context, double size) {
    return GestureDetector(
      onTap: () => context.go('/'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Brand.teal.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: ClipOval(
            child: Image.asset('images/logo_new.jpeg',
                fit: BoxFit.cover, cacheWidth: 132, cacheHeight: 132),
          ),
        ),
      ),
    );
  }

  Widget _wordmark(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () => context.go('/'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MAHA',
              style: Brand.font(isMobile ? 14 : 16, FontWeight.w800, Brand.ink,
                  spacing: 2.4)),
          Text('HR SERVICES',
              style: Brand.font(
                  isMobile ? 7.5 : 8.5, FontWeight.w700, Brand.teal,
                  spacing: 3)),
        ],
      ),
    );
  }

  // Static text link — no hover color change (only a click cursor).
  Widget _navLink(BuildContext context, _NavItem item) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(item.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(item.label,
              style: Brand.font(14, FontWeight.w600, Brand.slate)),
        ),
      ),
    );
  }

  Widget _ghostButton(
      BuildContext context, String label, VoidCallback onTap, bool isMobile) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 18, vertical: isMobile ? 9 : 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Brand.navy.withValues(alpha: 0.6),
                width: 1.4),
          ),
          child: Text(label,
              style: Brand.font(
                  isMobile ? 12.5 : 14, FontWeight.w700, Brand.navy)),
        ),
      ),
    );
  }

  Widget _glowButton(
      BuildContext context, String label, VoidCallback onTap, bool isMobile) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 20, vertical: isMobile ? 10 : 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Brand.teal, Brand.navy]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Brand.teal.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: Brand.font(
                      isMobile ? 12.5 : 14, FontWeight.w700, Colors.white)),
              if (!isMobile) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded,
                    size: 15, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
