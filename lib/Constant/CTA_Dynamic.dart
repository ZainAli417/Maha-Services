import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Scroll-aware CTA buttons:
/// - If scrolled more than half the screen height downwards, two floating CTAs (left + right) appear
///   and remain fixed to the bottom edge of the screen until scrolled back up.
class ScrollAwareCTAButtons extends StatefulWidget {
  final bool isDarkMode;
  final ScrollController? scrollController;

  const ScrollAwareCTAButtons({
    super.key,
    required this.isDarkMode,
    this.scrollController,
  });

  @override
  State<ScrollAwareCTAButtons> createState() => _ScrollAwareCTAButtonsState();
}

class _ScrollAwareCTAButtonsState extends State<ScrollAwareCTAButtons>
    with TickerProviderStateMixin {

  // Animation controller for floating CTAs
  late final AnimationController _floatingController;
  late final Animation<Offset> _floatingSlide;
  late final Animation<double> _floatingOpacity;
  bool _isFloating = false;

  // store the position so we can remove listener safely
  ScrollPosition? _attachedPosition;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _floatingSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _floatingController, curve: Curves.easeOut));

    _floatingOpacity = CurvedAnimation(
      parent: _floatingController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeIn),
    );

    // Wait until first frame to attach to scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachToScrollPosition());
  }

  /// Attach to the provided ScrollController's position if available, otherwise to the nearest Scrollable's position.
  void _attachToScrollPosition() {
    ScrollPosition? position;
    if (widget.scrollController != null) {
      position = widget.scrollController!.position;
    } else {
      final scrollableState = Scrollable.maybeOf(context);
      if (scrollableState == null) {
        // No scrollable in the ancestor tree — still fine: we won't float.
        return;
      }
      position = scrollableState.position;
    }

    // remove previous if any
    _attachedPosition?.removeListener(_onScroll);
    _attachedPosition = position;
    position.addListener(_onScroll);

    // do an initial check
    _onScroll();
  }

  /// Called whenever scroll position changes. Determines if scrolled more than half screen height.
  /// If yes, start floating animation.
  void _onScroll() {
    if (!mounted) return;

    final position = _attachedPosition;
    if (position == null) {
      return;
    }

    final screenSize = MediaQuery.of(context).size;

    // Decide whether floating version should be shown
    final shouldFloat = position.pixels > screenSize.height / 1.25;

    if (shouldFloat != _isFloating) {
      _isFloating = shouldFloat;
      if (_isFloating) {
        _floatingController.forward();
      } else {
        _floatingController.reverse();
      }
      // update the rebuild
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant ScrollAwareCTAButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if the widget's tree changed (maybe moved into/out of a scrollable),
    // reattach to the scroll position on next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachToScrollPosition());
  }

  @override
  void dispose() {
    _attachedPosition?.removeListener(_onScroll);
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        // IgnorePointer allows underlying scroll to work; we only enable interactions on visible children.
        ignoring: !_isFloating,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            // We keep this builder around to rebuild position/opacity together
            return Stack(
              children: [
                // Left floating button
                Positioned(
                  left: 20,
                  bottom: MediaQuery.of(context).viewPadding.bottom + 50,
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - _floatingSlide.value.dy)),
                    child: Opacity(
                      opacity: _floatingOpacity.value,
                      child: _FloatingCTA(
                        label: 'Join as Candidate',
                        icon: Icons.person_add_rounded,
                        isPrimary: true,
                        isDarkMode: widget.isDarkMode,
                        onPressed: () => context.go('/register'),
                        // small elevation pop when entering
                        entranceProgress: _floatingController.value,
                      ),
                    ),
                  ),
                ),

                // Right floating button
                Positioned(
                  right: 20,
                  bottom: MediaQuery.of(context).viewPadding.bottom + 50,
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - _floatingSlide.value.dy)),
                    child: Opacity(
                      opacity: _floatingOpacity.value,
                      child: _FloatingCTA(
                        label: 'I\'m a Recruiter',
                        icon: Icons.business_center_rounded,
                        isPrimary: false,
                        isDarkMode: widget.isDarkMode,
                        onPressed: () => context.go('/register'),
                        entranceProgress: _floatingController.value,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Compact floating CTA widget used for the anchored buttons.
/// Adds entrance animation, hover effects, accessibility, and a subtle pulse to make it "alive".
class _FloatingCTA extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDarkMode;
  final VoidCallback onPressed;
  final double entranceProgress; // 0.0 .. 1.0

  const _FloatingCTA({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isDarkMode,
    required this.onPressed,
    required this.entranceProgress,
  });

  @override
  State<_FloatingCTA> createState() => _FloatingCTAState();
}

class _FloatingCTAState extends State<_FloatingCTA>
    with TickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Entrance animation (slide-in feel)
    final entranceScale = 0.88 + (0.12 * widget.entranceProgress);

    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_hoverController, _pulseController]),
        builder: (context, child) {
          final hover = _hoverController.value;
          final pulse = _pulseController.value * 0.015;

          final scale = entranceScale *
              (1.0 + hover * 0.04) *
              (1.0 + pulse);

          final elevation = (3 + hover * 5 + widget.entranceProgress * 4)
              .clamp(3.0, 12.0);

          final backgroundColor = widget.isPrimary
              ? const Color(0xFF6366F1)
              : (widget.isDarkMode
              ? const Color(0xFF1E293B)
              : Colors.white);

          final foregroundColor = widget.isPrimary
              ? Colors.white
              : const Color(0xFF10B981);

          final shadowColor = widget.isPrimary
              ? const Color(0xFF6366F1).withOpacity(0.4)
              : const Color(0xFF10B981).withOpacity(0.25);

          return Transform.scale(
            scale: scale,
            child: Material(
              elevation: elevation,
              color: backgroundColor,
              shadowColor: shadowColor,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(14),
                splashFactory: InkRipple.splashFactory,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: widget.isPrimary
                        ? null
                        : Border.all(
                      color: const Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        size: 20,
                        color: foregroundColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: foregroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
/// Full-width buttons used in the original layout (desktop friendly).
