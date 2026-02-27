import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderNav extends StatefulWidget {
  const HeaderNav({super.key});

  @override
  State<HeaderNav> createState() => _HeaderNavState();
}

class _HeaderNavState extends State<HeaderNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFF1F1F4),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop
                  ? 40
                  : isTablet
                      ? 24
                      : 16,
              vertical: 10,
            ),
            child: isDesktop
                ? _buildDesktopNav(context)
                : _buildMobileNav(context),
          ),
        ),
      ),
    );
  }

  // ===== DESKTOP NAV =====
  Widget _buildDesktopNav(BuildContext context) {
    return Row(
      children: [
        // Logo
        _buildLogo(context),

        const SizedBox(width: 48),

        // Nav links
        _HeaderNavLink(
          label: 'Home',
          onTap: () => context.go('/'),
        ),
        _HeaderNavLink(
          label: 'Create Profile',
          onTap: () => context.go('/register'),
        ),
        _HeaderNavLink(
          label: 'Find Jobs',
          onTap: () => context.go('/login'),
        ),

        const Spacer(),

        // Login
        _HeaderOutlineButton(
          label: 'Login',
          onTap: () => context.go('/login'),
        ),

        const SizedBox(width: 10),

        // Get Started
        _HeaderFilledButton(
          label: 'Get Started',
          onTap: () => context.go('/register'),
        ),
      ],
    );
  }

  // ===== MOBILE NAV =====
  Widget _buildMobileNav(BuildContext context) {
    return Row(
      children: [
        // Logo
        _buildLogo(context, compact: true),

        const Spacer(),

        // Login text button
        _HeaderTextLink(
          label: 'Login',
          onTap: () => context.go('/login'),
        ),

        const SizedBox(width: 8),

        // Menu button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showMobileMenu(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Color(0xFF1E293B),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===== LOGO =====
  Widget _buildLogo(BuildContext context, {bool compact = false}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'images/logo.png',
                width: compact ? 36 : 44,
                height: compact ? 36 : 44,
                fit: BoxFit.contain,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 12),
              Text(
                'Maha Services',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== MOBILE MENU =====
  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MobileMenuSheet(parentContext: context),
    );
  }
}

// ─────────────────────────────────────────────
// NAV LINK (Desktop)
// ─────────────────────────────────────────────
class _HeaderNavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderNavLink({
    required this.label,
    required this.onTap,
  });

  @override
  State<_HeaderNavLink> createState() => _HeaderNavLinkState();
}

class _HeaderNavLinkState extends State<_HeaderNavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color:
                  _hovered ? const Color(0xFFF5F5F7) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: _hovered ? FontWeight.w600 : FontWeight.w500,
                color: _hovered
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// OUTLINE BUTTON (Desktop - Login)
// ─────────────────────────────────────────────
class _HeaderOutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderOutlineButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_HeaderOutlineButton> createState() => _HeaderOutlineButtonState();
}

class _HeaderOutlineButtonState extends State<_HeaderOutlineButton> {
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF6366F1).withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF6366F1)
                  : const Color(0xFFD1D5DB),
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _hovered
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILLED BUTTON (Desktop - Get Started)
// ─────────────────────────────────────────────
class _HeaderFilledButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderFilledButton({
    required this.label,
    required this.onTap,
  });

  @override
  State<_HeaderFilledButton> createState() => _HeaderFilledButtonState();
}

class _HeaderFilledButtonState extends State<_HeaderFilledButton> {
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF4F46E5)
                : const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                offset: _hovered ? const Offset(0.15, 0) : Offset.zero,
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TEXT LINK (Mobile - Login)
// ─────────────────────────────────────────────
class _HeaderTextLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderTextLink({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6366F1),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MOBILE MENU BOTTOM SHEET
// ─────────────────────────────────────────────
class _MobileMenuSheet extends StatelessWidget {
  final BuildContext parentContext;

  const _MobileMenuSheet({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Menu items
              _MobileMenuItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () {
                  Navigator.pop(context);
                  parentContext.go('/');
                },
              ),
              _MobileMenuItem(
                icon: Icons.person_add_outlined,
                label: 'Create Profile',
                onTap: () {
                  Navigator.pop(context);
                  parentContext.go('/register');
                },
              ),
              _MobileMenuItem(
                icon: Icons.search_rounded,
                label: 'Find Jobs',
                onTap: () {
                  Navigator.pop(context);
                  parentContext.go('/login');
                },
              ),
              _MobileMenuItem(
                icon: Icons.business_center_outlined,
                label: 'For Recruiters',
                onTap: () {
                  Navigator.pop(context);
                  parentContext.go('/recruiter-signup');
                },
              ),

              const SizedBox(height: 16),

              // Get Started CTA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    parentContext.go('/register');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MOBILE MENU ITEM
// ─────────────────────────────────────────────
class _MobileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MobileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}