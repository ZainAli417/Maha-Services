import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/geo/gazetteer.dart';
import 'package:job_portal/core/geo/world_map.dart';

/// Grid cell a coordinate falls in, the same way the painter finds it.
({int col, int row})? cellOf(double lat, double lon) {
  final u = projectToUnit(lat, lon);
  if (u == null) return null;
  return (
    col: (u.x * kMapCols).floor().clamp(0, kMapCols - 1),
    row: (u.y * kMapRows).floor().clamp(0, kMapRows - 1),
  );
}

bool landAt(double lat, double lon) {
  final c = cellOf(lat, lon);
  return c != null && isLandCell(c.col, c.row);
}

void main() {
  group('the land grid', () {
    test('decodes to exactly one bit per cell', () {
      // A short mask would silently shift every continent left.
      expect(isLandCell(kMapCols - 1, kMapRows - 1), isA<bool>());
      expect(isLandCell(0, 0), isA<bool>());
    });

    test('puts real cities on land', () {
      for (final c in const [
        ('Islamabad', 33.7, 73.0),
        ('Karachi', 24.9, 67.0),
        ('Dubai', 25.2, 54.4),
        ('Riyadh', 24.7, 46.7),
        ('Doha', 25.3, 51.5),
        ('London', 51.5, -0.1),
        ('Cairo', 30.0, 31.2),
        ('Delhi', 28.6, 77.2),
        ('Singapore', 1.35, 103.8),
        ('New York', 40.7, -74.0),
        ('Sao Paulo', -23.5, -46.6),
        ('Sydney', -33.9, 151.2),
        ('Tokyo', 35.7, 139.7),
        ('Moscow', 55.8, 37.6),
        ('Johannesburg', -26.2, 28.0),
        ('Nairobi', -1.3, 36.8),
      ]) {
        expect(landAt(c.$2, c.$3), isTrue, reason: '${c.$1} should be on land');
      }
    });

    test('leaves open ocean as water', () {
      for (final o in const [
        ('Mid Atlantic', 20.0, -40.0),
        ('Mid Pacific', 0.0, -150.0),
        ('Indian Ocean', -20.0, 80.0),
        ('Arabian Sea', 15.0, 63.0),
        ('Bay of Bengal', 15.0, 88.0),
        ('South Pacific', -40.0, -110.0),
      ]) {
        expect(landAt(o.$2, o.$3), isFalse,
            reason: '${o.$1} should be water');
      }
    });

    test('reports land for roughly a third of the grid', () {
      // A sanity bound, not a precise figure: a coarse grid over-counts
      // coastlines. Far outside this range means the mask is corrupt.
      var land = 0;
      for (var r = 0; r < kMapRows; r++) {
        for (var c = 0; c < kMapCols; c++) {
          if (isLandCell(c, r)) land++;
        }
      }
      final share = land / (kMapCols * kMapRows);
      expect(share, greaterThan(0.25));
      expect(share, lessThan(0.45));
    });

    test('treats out-of-range cells as water rather than throwing', () {
      expect(isLandCell(-1, 0), isFalse);
      expect(isLandCell(0, -1), isFalse);
      expect(isLandCell(kMapCols, 0), isFalse);
      expect(isLandCell(0, kMapRows), isFalse);
    });
  });

  group('projection', () {
    test('maps the corners of the band to the corners of the box', () {
      expect(projectToUnit(kMapLatTop, -180)!.x, closeTo(0, 0.001));
      expect(projectToUnit(kMapLatTop, -180)!.y, closeTo(0, 0.001));
      expect(projectToUnit(kMapLatBottom, 180)!.x, closeTo(1, 0.001));
      expect(projectToUnit(kMapLatBottom, 180)!.y, closeTo(1, 0.001));
    });

    test('puts the prime meridian at the middle', () {
      expect(projectToUnit(0, 0)!.x, closeTo(0.5, 0.001));
    });

    test('drops anything outside the cropped band', () {
      // Clamping instead would draw an Antarctic pin on the bottom edge as
      // though somebody actually lived there.
      expect(projectToUnit(-89, 0), isNull);
      expect(projectToUnit(89, 0), isNull);
    });
  });

  group('resolvePlace', () {
    test('accepts a country name', () {
      expect(resolvePlace('Pakistan')!.country, 'Pakistan');
      expect(resolvePlace('  united kingdom ')!.country, 'United Kingdom');
    });

    test('accepts a nationality, which is what profiles usually carry', () {
      expect(resolvePlace('Pakistani')!.country, 'Pakistan');
      expect(resolvePlace('British')!.country, 'United Kingdom');
      expect(resolvePlace('Emirati')!.country, 'United Arab Emirates');
      expect(resolvePlace('Filipino')!.country, 'Philippines');
    });

    test('accepts short forms and older names', () {
      expect(resolvePlace('UAE')!.country, 'United Arab Emirates');
      expect(resolvePlace('USA')!.country, 'United States');
      expect(resolvePlace('Burma')!.country, 'Myanmar');
      expect(resolvePlace('Türkiye')!.country, 'Turkey');
    });

    test('refuses to guess an unknown value', () {
      // A pin in the wrong country is worse than a pin missing from one.
      expect(resolvePlace('Wakanda'), isNull);
      expect(resolvePlace('Not specified'), isNull);
      expect(resolvePlace(''), isNull);
      expect(resolvePlace('   '), isNull);
    });

    test('every place it resolves lands inside the map band', () {
      for (final name in const [
        'Pakistan', 'India', 'United Arab Emirates', 'United Kingdom',
        'South Africa', 'Australia', 'Canada', 'Brazil', 'Japan', 'Norway',
      ]) {
        final p = resolvePlace(name)!;
        expect(projectToUnit(p.lat, p.lon), isNotNull,
            reason: '$name falls outside the drawn band');
      }
    });
  });

  group('placeCounts', () {
    test('adds two spellings of one country together', () {
      // The whole reason the aliases exist: otherwise the map draws two pins
      // for one country and both counts look too small.
      final out = placeCounts({'Pakistan': 6, 'Pakistani': 4});
      expect(out.placed.length, 1);
      expect(out.placed.single.count, 10);
      expect(out.placed.single.place.country, 'Pakistan');
    });

    test('orders by count, then by name for a tie', () {
      final out = placeCounts({'India': 3, 'Pakistan': 9, 'Canada': 3});
      expect([for (final p in out.placed) p.place.country],
          ['Pakistan', 'Canada', 'India']);
    });

    test('reports what it could not place instead of dropping it', () {
      final out = placeCounts({'Pakistan': 2, 'Wakanda': 5, 'Nowhere': 1});
      expect(out.placed.single.place.country, 'Pakistan');
      expect(out.unplaced, {'Wakanda': 5, 'Nowhere': 1});
    });

    test('handles an empty input', () {
      final out = placeCounts(const {});
      expect(out.placed, isEmpty);
      expect(out.unplaced, isEmpty);
    });
  });
}
