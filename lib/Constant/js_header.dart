import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified header used across the Job Seeker screens (Job Hub, Saved Jobs,
/// Profile, CV Analyzer) so every screen shares one coherent navy→teal banner.
///
/// - [icon] shows inside a glass badge on the left.
/// - [title] / [subtitle] are the primary/secondary lines.
/// - [onMenu], when provided, renders a hamburger button on mobile (opens the
///   scaffold drawer). Pass null on screens without a drawer.
/// - [trailing] is an optional slot (status pill, progress, loader) shown at
///   the far right.
class JobSeekerHeader extends StatelessWidget {
  const JobSeekerHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.onMenu,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Optional tiny uppercase label shown above the title (brand eyebrow).
  final String? eyebrow;
  final VoidCallback? onMenu;
  final Widget? trailing;

  // Brand palette — navy + teal (matches Admin analytics modern header).
  static const _canvas = Color(0xFFF4F9FB);
  static const _navy = Color(0xFF14507F);
  static const _teal = Color(0xFF2EC4B6);
  static const _tealDeep = Color(0xFF15A99C);
  static const _t1 = Color(0xFF0B2239);
  static const _t2 = Color(0xFF3E5C76);
  static const _border = Color(0xFFDCE7EF);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return RepaintBoundary(
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(color: _canvas),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 12 : 32,
            isMobile ? 12 : 16,
            isMobile ? 12 : 32,
            isMobile ? 12 : 16,
          ),
          child: Row(
            children: [
              if (isMobile && onMenu != null) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onMenu,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_rounded,
                        size: 20, color: _t2),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_teal, _navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _teal.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: isMobile ? 20 : 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (eyebrow != null)
                      Text(
                        eyebrow!.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: _tealDeep,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        color: _t1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _t2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
