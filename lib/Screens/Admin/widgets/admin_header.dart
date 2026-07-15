import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A modern gradient section header shared across the admin portal screens for
/// a consistent, professional-yet-vibrant look. Shows an icon tile, title,
/// subtitle, optional trailing actions and optional stat pills.
class AdminGradientHeader extends StatelessWidget {
  const AdminGradientHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.stats = const [],
    this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final List<AdminHeaderStat> stats;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        gradient: gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF061C31), Color(0xFF0A2E4F), Color(0xFF14507F)],
            ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2239).withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment:
                isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: Colors.white, size: isMobile ? 22 : 26),
              ),
              SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 14 : 0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                SizedBox(width: isMobile ? 0 : 12, height: isMobile ? 14 : 0),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          ),
          if (stats.isNotEmpty) ...[
            SizedBox(height: isMobile ? 16 : 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final s in stats) _StatPill(stat: s)],
            ),
          ],
        ],
      ),
    );
  }
}

class AdminHeaderStat {
  const AdminHeaderStat(this.label, this.value, {this.icon});
  final String label;
  final String value;
  final IconData? icon;
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.stat});
  final AdminHeaderStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stat.icon != null) ...[
            Icon(stat.icon, size: 15, color: Colors.white),
            const SizedBox(width: 7),
          ],
          Text(
            stat.value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            stat.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A translucent header action button matching the gradient header.
class AdminHeaderButton extends StatelessWidget {
  const AdminHeaderButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: filled ? const Color(0xFF14507F) : Colors.white,
                      ),
                    )
                  : Icon(icon,
                      size: 17,
                      color: filled ? const Color(0xFF14507F) : Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: filled ? const Color(0xFF14507F) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
