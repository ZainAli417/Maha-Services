import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/geo/gazetteer.dart';
import '../../../core/geo/world_map.dart';
import '../../../core/theme/app_colors.dart';

/// Where the candidate pool comes from, on a map.
///
/// Drawn with a CustomPainter over a baked land grid — no map package, no tile
/// requests, nothing to break when a CDN is unreachable. The dots are the
/// world; the pins are the data.
///
/// Pin area, not radius, scales with the count: a country with four times as
/// many candidates gets a circle four times the area, which is how the eye
/// actually reads size. Scaling the radius would make it look sixteen times
/// bigger and overstate every large country.
class CandidateMap extends StatefulWidget {
  const CandidateMap({
    super.key,
    required this.byName,
    this.height = 300,
  });

  /// Nationality or country → candidate count, straight off the provider.
  final Map<String, int> byName;

  final double height;

  @override
  State<CandidateMap> createState() => _CandidateMapState();
}

class _CandidateMapState extends State<CandidateMap> {
  /// The country under the cursor, or null.
  String? _hover;

  @override
  Widget build(BuildContext context) {
    final grouped = placeCounts(widget.byName);
    final placed = grouped.placed;
    final unplaced = grouped.unplaced;
    final total = placed.fold<int>(0, (n, p) => n + p.count);
    final peak = placed.isEmpty
        ? 0
        : placed.map((p) => p.count).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.public_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Where candidates are from',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const Spacer(),
            if (total > 0)
              Text(
                '$total placed across ${placed.length} '
                'countr${placed.length == 1 ? 'y' : 'ies'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (placed.isEmpty)
          _Empty(unplaced: unplaced)
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  // The map keeps the grid's aspect so the continents are not
                  // stretched; whatever is left over is padding, not distortion.
                  const aspect = kMapCols / kMapRows;
                  var w = c.maxWidth - 20;
                  var h = w / aspect;
                  if (h > c.maxHeight - 20) {
                    h = c.maxHeight - 20;
                    w = h * aspect;
                  }
                  return Center(
                    child: MouseRegion(
                      onExit: (_) => setState(() => _hover = null),
                      // localPosition is relative to this MouseRegion, which
                      // sizes to the map itself — so it is already map space.
                      // Going from a global position through the LayoutBuilder's
                      // box would also work, and would break the moment
                      // anything above it moved.
                      onHover: (event) {
                        final hit = _hitTest(
                          event.localPosition,
                          Size(w, h),
                          placed,
                          peak,
                        );
                        if (hit != _hover) setState(() => _hover = hit);
                      },
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: CustomPaint(
                          painter: _MapPainter(
                            places: placed,
                            peak: peak,
                            highlight: _hover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Legend(
            placed: placed,
            highlight: _hover,
            onHover: (name) => setState(() => _hover = name),
          ),
          if (unplaced.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Unplaced(unplaced: unplaced),
          ],
        ],
      ],
    );
  }

  /// Which pin the cursor is over, largest-first so a small pin sitting on top
  /// of a large one is still reachable.
  String? _hitTest(
    Offset local,
    Size size,
    List<({Place place, int count})> placed,
    int peak,
  ) {
    for (final p in placed.reversed) {
      final u = projectToUnit(p.place.lat, p.place.lon);
      if (u == null) continue;
      final centre = Offset(u.x * size.width, u.y * size.height);
      final r = _MapPainter.radiusFor(p.count, peak);
      if ((local - centre).distance <= r + 4) return p.place.country;
    }
    return null;
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter({
    required this.places,
    required this.peak,
    required this.highlight,
  });

  final List<({Place place, int count})> places;
  final int peak;
  final String? highlight;

  /// Area proportional to count, so two pins compare the way they look.
  static double radiusFor(int count, int peak) {
    if (peak <= 0) return 4;
    const minR = 4.0;
    const maxR = 15.0;
    final t = math.sqrt(count / peak);
    return minR + (maxR - minR) * t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / kMapCols;
    final cellH = size.height / kMapRows;
    // A round dot per land cell, slightly smaller than its cell so the grid
    // reads as dots rather than as a filled shape.
    final r = math.min(cellW, cellH) * 0.34;

    final land = Paint()..color = AppColors.textFaint.withValues(alpha: 0.55);
    for (var row = 0; row < kMapRows; row++) {
      for (var col = 0; col < kMapCols; col++) {
        if (!isLandCell(col, row)) continue;
        canvas.drawCircle(
          Offset((col + 0.5) * cellW, (row + 0.5) * cellH),
          r,
          land,
        );
      }
    }

    // Pins on top, smallest last so a small country is never buried under a
    // large neighbour's circle.
    final ordered = [...places]..sort((a, b) => b.count.compareTo(a.count));
    for (final p in ordered) {
      final u = projectToUnit(p.place.lat, p.place.lon);
      if (u == null) continue;
      final centre = Offset(u.x * size.width, u.y * size.height);
      final radius = radiusFor(p.count, peak);
      final on = highlight == null || highlight == p.place.country;

      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..color = AppColors.primary.withValues(alpha: on ? 0.22 : 0.07),
      );
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlight == p.place.country ? 2.2 : 1.4
          ..color = AppColors.primary.withValues(alpha: on ? 0.95 : 0.25),
      );
      canvas.drawCircle(
        centre,
        2.2,
        Paint()..color = AppColors.primary.withValues(alpha: on ? 1 : 0.3),
      );
    }

    // The label only for the hovered pin. Labelling all of them at once turns
    // a map into a wall of text at exactly the sizes this panel gets.
    final hit = highlight == null
        ? null
        : places.where((p) => p.place.country == highlight).firstOrNull;
    if (hit != null) {
      final u = projectToUnit(hit.place.lat, hit.place.lon);
      if (u != null) {
        _label(
          canvas,
          size,
          Offset(u.x * size.width, u.y * size.height),
          '${hit.place.country}  ·  ${hit.count}',
          radiusFor(hit.count, peak),
        );
      }
    }
  }

  void _label(
    Canvas canvas,
    Size size,
    Offset at,
    String text,
    double pinRadius,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padH = 8.0;
    const padV = 5.0;
    final w = tp.width + padH * 2;
    final h = tp.height + padV * 2;

    // Kept inside the canvas, and flipped above the pin when there is no room
    // below — a tooltip clipped at the edge is a tooltip nobody can read.
    var left = at.dx - w / 2;
    left = left.clamp(0.0, math.max(0.0, size.width - w));
    var top = at.dy + pinRadius + 6;
    if (top + h > size.height) top = at.dy - pinRadius - 6 - h;
    top = top.clamp(0.0, math.max(0.0, size.height - h));

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = AppColors.ink.withValues(alpha: 0.92));
    tp.paint(canvas, Offset(left + padH, top + padV));
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.highlight != highlight || old.places != places || old.peak != peak;
}

// ── legend and notes ───────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend({
    required this.placed,
    required this.highlight,
    required this.onHover,
  });

  final List<({Place place, int count})> placed;
  final String? highlight;
  final ValueChanged<String?> onHover;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final p in placed.take(12))
            MouseRegion(
              onEnter: (_) => onHover(p.place.country),
              onExit: (_) => onHover(null),
              child: Container(
                padding: const EdgeInsets.fromLTRB(9, 4, 5, 4),
                decoration: BoxDecoration(
                  color: highlight == p.place.country
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: highlight == p.place.country
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.place.country,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${p.count}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
}

/// Names the pool carried that could not be put on the map.
///
/// Shown rather than swallowed: a country missing from the gazetteer is a gap
/// worth knowing about, and silently dropping candidates from a distribution
/// chart makes the chart quietly wrong.
class _Unplaced extends StatelessWidget {
  const _Unplaced({required this.unplaced});

  final Map<String, int> unplaced;

  @override
  Widget build(BuildContext context) {
    final n = unplaced.values.fold<int>(0, (a, b) => a + b);
    final names = unplaced.keys.take(4).join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.help_outline_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '$n candidate${n == 1 ? '' : 's'} could not be placed — '
            '$names${unplaced.length > 4 ? ' and ${unplaced.length - 4} more' : ''}. '
            'Their profile gives a nationality the map does not recognise.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.unplaced});

  final Map<String, int> unplaced;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.public_off_rounded,
              size: 26,
              color: AppColors.textFaint,
            ),
            const SizedBox(height: 10),
            Text(
              unplaced.isEmpty
                  ? 'No candidate has a nationality or country on file yet.'
                  : 'None of the ${unplaced.length} nationalities on file '
                      'matched a country the map knows.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
}
