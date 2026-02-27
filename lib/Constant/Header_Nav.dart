import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════
class _T {
  static const indigo     = Color(0xFF6366F1);
  static const indigoDk   = Color(0xFF4F46E5);
  static const bg         = Colors.white;
  static const divider    = Color(0xFFF1F1F4);
  static const dark       = Color(0xFF1E293B);
  static const mid        = Color(0xFF64748B);
  static const light      = Color(0xFF9CA3AF);
  static const surface    = Color(0xFFF5F5F7);
  static const surfaceAlt = Color(0xFFF8F9FB);

  static TextStyle p(double size,
      {FontWeight fw = FontWeight.w500, Color color = dark}) =>
      GoogleFonts.poppins(
          fontSize: size, fontWeight: fw, color: color, letterSpacing: -0.1);
}

// ═══════════════════════════════════════════════════════════════════════════
//  CLEAN INKWELL HELPER
//  Kills every default Material overlay so only our AnimatedContainer colour
//  is ever visible — zero grey flicker, on every widget.
// ═══════════════════════════════════════════════════════════════════════════
InkWell _cleanInkWell({
  required Widget child,
  required VoidCallback onTap,
  BorderRadius? borderRadius,
  GestureTapDownCallback? onTapDown,
  GestureTapUpCallback? onTapUp,
  GestureTapCancelCallback? onTapCancel,
}) =>
    InkWell(
      onTap: onTap,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      borderRadius: borderRadius,
      child: child,
    );

// ═══════════════════════════════════════════════════════════════════════════
//  NAV ITEMS CONFIG
// ═══════════════════════════════════════════════════════════════════════════
class _NavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData iconFill;
  const _NavItem(this.label, this.route, this.icon, this.iconFill);
}

const _navItems = [
  _NavItem('Home',           '/',                 Icons.home_outlined,            Icons.home_rounded),
  _NavItem('Create Profile', '/register',         Icons.person_add_outlined,      Icons.person_add_rounded),
  _NavItem('Find Jobs',      '/login',            Icons.search_outlined,          Icons.search_rounded),
  _NavItem('For Recruiters', '/recruiter-signup', Icons.business_center_outlined, Icons.business_center_rounded),
];

// ═══════════════════════════════════════════════════════════════════════════
//  HEADER NAV
// ═══════════════════════════════════════════════════════════════════════════
class HeaderNav extends StatefulWidget {
  const HeaderNav({super.key});

  @override
  State<HeaderNav> createState() => _HeaderNavState();
}

class _HeaderNavState extends State<HeaderNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _fade;
  late Animation<double>   _fadeAnim;

  bool          _menuOpen    = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _headerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _removeOverlay();
    _fade.dispose();
    super.dispose();
  }

  void _toggleMenu() => _menuOpen ? _closeMenu() : _openMenu();

  void _openMenu() {
    if (_overlayEntry != null) return;
    setState(() => _menuOpen = true);
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeMenu() {
    _removeOverlay();
    setState(() => _menuOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(builder: (_) {
      final box       = _headerKey.currentContext?.findRenderObject() as RenderBox?;
      final headerH   = box?.size.height ?? 64;
      final headerTop = box?.localToGlobal(Offset.zero).dy ?? 0;
      return _MobileMenuOverlay(
        topOffset:  headerTop + headerH,
        onClose:    _closeMenu,
        onNavigate: (route) { _closeMenu(); context.go(route); },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final w         = MediaQuery.of(context).size.width;
    final isDesktop = w > 1024;
    final isTablet  = w > 640 && w <= 1024;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        key: _headerKey,
        decoration: const BoxDecoration(
          color: _T.bg,
          border: Border(bottom: BorderSide(color: _T.divider, width: 1)),
          boxShadow: [
            BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : isTablet ? 24 : 16,
              vertical:   isDesktop ? 10 : 8,
            ),
            child: isDesktop
                ? _DesktopNav(onNavigate: (r) => context.go(r))
                : _MobileNav(
              menuOpen:     _menuOpen,
              onToggleMenu: _toggleMenu,
              onNavigate:   (r) => context.go(r),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DESKTOP NAV
// ═══════════════════════════════════════════════════════════════════════════
class _DesktopNav extends StatelessWidget {
  final void Function(String) onNavigate;
  const _DesktopNav({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Logo(onTap: () => onNavigate('/'), size: 40),
        const SizedBox(width: 10),
        _LogoText(),
        const SizedBox(width: 40),
        ..._navItems.take(3).map((item) => _DesktopNavLink(
          label: item.label,
          onTap: () => onNavigate(item.route),
        )),
        const Spacer(),
        _OutlineBtn(label: 'Login',      onTap: () => onNavigate('/login')),
        const SizedBox(width: 10),
        _FilledBtn(label: 'Get Started', onTap: () => onNavigate('/register')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MOBILE NAV BAR
// ═══════════════════════════════════════════════════════════════════════════
class _MobileNav extends StatelessWidget {
  final bool menuOpen;
  final VoidCallback onToggleMenu;
  final void Function(String) onNavigate;
  const _MobileNav({
    required this.menuOpen,
    required this.onToggleMenu,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Logo(onTap: () => onNavigate('/'), size: 34),
        const SizedBox(width: 8),
        _LogoText(compact: true),
        const Spacer(),
        _TextBtn(label: 'Login', onTap: () => onNavigate('/login')),
        const SizedBox(width: 6),
        _HamburgerBtn(open: menuOpen, onTap: onToggleMenu),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MOBILE MENU OVERLAY
// ═══════════════════════════════════════════════════════════════════════════
class _MobileMenuOverlay extends StatefulWidget {
  final double topOffset;
  final VoidCallback onClose;
  final void Function(String) onNavigate;
  const _MobileMenuOverlay({
    required this.topOffset,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  State<_MobileMenuOverlay> createState() => _MobileMenuOverlayState();
}

class _MobileMenuOverlayState extends State<_MobileMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _slide;
  late Animation<double>   _fadeBg;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _slide  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fadeBg = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onClose();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          top: widget.topOffset,
          child: FadeTransition(
            opacity: _fadeBg,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(color: const Color(0x55000000)),
            ),
          ),
        ),
        // Slide-down panel
        Positioned(
          top: widget.topOffset, left: 0, right: 0,
          child: AnimatedBuilder(
            animation: _slide,
            builder: (_, child) => FractionalTranslation(
              translation: Offset(0, -(1 - _slide.value)),
              child: Opacity(opacity: _slide.value, child: child),
            ),
            child: _MenuPanel(
              onNavigate: (r) async {
                await _dismiss();
                widget.onNavigate(r);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MENU PANEL CONTENT
// ═══════════════════════════════════════════════════════════════════════════
class _MenuPanel extends StatelessWidget {
  final void Function(String) onNavigate;
  const _MenuPanel({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Column(
              children: _navItems.map((item) => _PanelNavItem(
                item: item,
                onTap: () => onNavigate(item.route),
              )).toList(),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _T.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _OutlineBtn(
                    label: 'Log In',
                    onTap: () => onNavigate('/login'),
                    fullWidth: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilledBtn(
                    label: 'Get Started',
                    onTap: () => onNavigate('/register'),
                    fullWidth: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PANEL NAV ITEM  — zero grey flicker
// ═══════════════════════════════════════════════════════════════════════════
class _PanelNavItem extends StatefulWidget {
  final _NavItem item;
  final VoidCallback onTap;
  const _PanelNavItem({required this.item, required this.onTap});

  @override
  State<_PanelNavItem> createState() => _PanelNavItemState();
}

class _PanelNavItemState extends State<_PanelNavItem> {
  bool _hovered = true;
  bool _pressed = true;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _pressed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: _cleanInkWell(
          onTap: widget.onTap,
          onTapDown:   (_) => setState(() => _pressed = true),
          onTapUp:     (_) => setState(() => _pressed = false),
          onTapCancel: ()  => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin:  const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: active ? _T.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: active
                        ? _T.indigo.withOpacity(0.08)
                        : _T.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    active ? widget.item.iconFill : widget.item.icon,
                    size: 19,
                    color: active ? _T.indigo : _T.mid,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(widget.item.label,
                      style: _T.p(15,
                          fw: FontWeight.w500,
                          color: _T.dark)),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: _T.light),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LOGO
// ═══════════════════════════════════════════════════════════════════════════
class _Logo extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  const _Logo({required this.onTap, required this.size});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: _cleanInkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset('images/logo.png',
                width: size, height: size, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _LogoText extends StatelessWidget {
  final bool compact;
  const _LogoText({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Text('Maha Services',
        style: GoogleFonts.poppins(
          fontSize: compact ? 15 : 17,
          fontWeight: FontWeight.w700,
          color: _T.dark,
          letterSpacing: -0.4,
        ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DESKTOP NAV LINK  — zero grey flicker
// ═══════════════════════════════════════════════════════════════════════════
class _DesktopNavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _DesktopNavLink({required this.label, required this.onTap});

  @override
  State<_DesktopNavLink> createState() => _DesktopNavLinkState();
}

class _DesktopNavLinkState extends State<_DesktopNavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: _cleanInkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: _hovered ? _T.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(widget.label,
                  style: _T.p(13.5,
                      fw: FontWeight.w500,
                      color: _T.mid)),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  HAMBURGER BUTTON  — zero grey flicker
// ═══════════════════════════════════════════════════════════════════════════
class _HamburgerBtn extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _HamburgerBtn({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: _cleanInkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: open ? _T.indigo.withOpacity(0.08) : _T.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: open
                      ? _T.indigo.withOpacity(0.3)
                      : Colors.transparent,
                  width: 1.2),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: Tween(begin: 0.25, end: 0.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                open ? Icons.close_rounded : Icons.menu_rounded,
                key: ValueKey(open),
                color: open ? _T.indigo : _T.dark,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  OUTLINE BUTTON  — zero grey flicker
// ═══════════════════════════════════════════════════════════════════════════
class _OutlineBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;
  const _OutlineBtn(
      {required this.label, required this.onTap, this.fullWidth = false});

  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: _cleanInkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _hovered
                  ? _T.indigo.withOpacity(0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _hovered ? _T.indigo : const Color(0xFFD1D5DB),
                  width: 1.5),
            ),
            child: Center(
              child: Text(widget.label,
                  style: _T.p(13.5,
                      fw: FontWeight.w600,
                      color: _hovered
                          ? _T.indigo
                          : const Color(0xFF374151))),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  FILLED BUTTON  — zero grey flicker
// ═══════════════════════════════════════════════════════════════════════════
class _FilledBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;
  const _FilledBtn(
      {required this.label, required this.onTap, this.fullWidth = false});

  @override
  State<_FilledBtn> createState() => _FilledBtnState();
}

class _FilledBtnState extends State<_FilledBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: _cleanInkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: widget.fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _hovered ? _T.indigoDk : _T.indigo,
              borderRadius: BorderRadius.circular(10),
              boxShadow: _hovered
                  ? [
                BoxShadow(
                    color: _T.indigo.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]
                  : [],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.label,
                      style: _T.p(13.5,
                          fw: FontWeight.w600, color: Colors.white)),
                  const SizedBox(width: 5),
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 160),
                    offset: _hovered
                        ? const Offset(0.2, 0)
                        : Offset.zero,
                    child: const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: Colors.white),
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

// ═══════════════════════════════════════════════════════════════════════════
//  TEXT BUTTON (mobile login)  — zero grey flicker
// ═══════════════════════════════════════════════════════════════════════════
class _TextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: _cleanInkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _T.indigo.withOpacity(0.07),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _T.indigo.withOpacity(0.2)),
            ),
            child: Text(label,
                style: _T.p(13, fw: FontWeight.w600, color: _T.indigo)),
          ),
        ),
      ),
    );
  }
}