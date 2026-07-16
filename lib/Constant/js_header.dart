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
    this.onMenu,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onMenu;
  final Widget? trailing;

  static const _heroDeep = Color(0xFF061C31);
  static const _heroMid = Color(0xFF0A2E4F);
  static const _navy = Color(0xFF14507F);
  static const _tealBright = Color(0xFF43E0D2);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return RepaintBoundary(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 10 : 20,
            isMobile ? 8 : 18,
            isMobile ? 10 : 20,
            2,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 22,
              vertical: isMobile ? 12 : 18,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_heroDeep, _heroMid, _navy],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                if (isMobile && onMenu != null) ...[
                  IconButton(
                    icon: const Icon(Icons.menu_rounded,
                        size: 24, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 34, minHeight: 34),
                    onPressed: onMenu,
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: EdgeInsets.all(isMobile ? 9 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _tealBright.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(icon,
                      size: isMobile ? 18 : 24, color: _tealBright),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 17 : 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 11 : 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
