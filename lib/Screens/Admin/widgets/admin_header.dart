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

  // Brand palette — navy + teal (matches Admin analytics modern header).
  static const _navy = Color(0xFF14507F);
  static const _teal = Color(0xFF2EC4B6);
  static const _tealDeep = Color(0xFF15A99C);
  static const _t1 = Color(0xFF0B2239);
  static const _t2 = Color(0xFF3E5C76);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFFF4F9FB)),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 8,
        vertical: isMobile ? 8 : 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment:
                isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Row(
                children: [
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
                    child: Icon(icon,
                        color: Colors.white, size: isMobile ? 22 : 24),
                  ),
                  const SizedBox(width: 16),
                  if (isMobile)
                    Expanded(child: _titleBlock(isMobile)),
                ],
              ),
              if (!isMobile) ...[
                Expanded(child: _titleBlock(isMobile)),
              ],
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

  Widget _titleBlock(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADMIN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _tealDeep,
          ),
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
    const navy = Color(0xFF14507F);
    const t2 = Color(0xFF3E5C76);
    const border = Color(0xFFDCE7EF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stat.icon != null) ...[
            Icon(stat.icon, size: 15, color: navy),
            const SizedBox(width: 7),
          ],
          Text(
            stat.value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            stat.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: t2,
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
    const navy = Color(0xFF14507F);
    const teal = Color(0xFF2EC4B6);
    const border = Color(0xFFDCE7EF);
    const slate = Color(0xFF3E5C76);
    final fg = filled ? Colors.white : slate;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(colors: [teal, navy])
                : null,
            color: filled ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: border),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: teal.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
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
                        color: fg,
                      ),
                    )
                  : Icon(icon, size: 17, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
