/// A minimal world map: a coarse land grid, and a place lookup for pins.
///
/// No map package and no tile server. The land grid was derived from the
/// Natural Earth Blue Marble texture and baked in as a bit per cell, so the map
/// renders offline, costs one string, and cannot be affected by a CDN being
/// blocked or a tile provider changing its terms.
///
/// The grid is only the *background*. Pins are placed from real coordinates, so
/// a country too small for a 2.6°-wide cell — Qatar, Bahrain, Singapore — still
/// gets a pin in the right place even if the dot under it reads as water.
library;

/// Equirectangular grid: 140 columns of longitude, 54 rows of latitude.
///
/// Latitude is cropped to +83…−56 rather than the full ±90. Antarctica and the
/// empty Arctic add a third to the height and carry no candidates, and cropping
/// them is what makes the populated world fill the panel.
const int kMapCols = 140;
const int kMapRows = 54;
const double kMapLatTop = 83;
const double kMapLatBottom = -56;

/// One bit per cell, row-major, base64. 1 = land.
const String _landMaskBase64 =
    'AAAAAF////+AAAAAACAAAAAAAAAAB////8AD8AAAAcAAAAAAAAP5Px///gAIAAUAf8AeAAAAAHif'
    '8A//4AAAAYU//7n8BoDwB/3f4P/8AAHAMP/////4CH///99PB/+AAP+X////////9/////z8f4eA'
    'H//////////wf////8+DwHAH//////////8H////weAcAAD7/////////8AeD//8H8AAAI+f////'
    '///1wAGAP//8/gAAHHv///////A8AAAD////8AAD7////////8PAQAAP////gAAv/////////BAQ'
    'AAB///+cAAD/////////wgAAAAf///4AAAf////////0QAAAAH///gAAA//4e/////7AAAAAB///'
    'wAAAPl///////4gAgAAAP//4AAADxT/5////0IAAAAAB//+AAAAf4C/////5fAAAAAAP//AAAAP/'
    'Mf/////OQAAAAAB//gAAAD////////wAAAAAAAf4IAAAB////////8AAAAAAAD8CAAAA////////'
    '/AAAAAAAAPBwAAAf////j///QAAAAEAAB7H4AAH////4Pz+AAAAAAAAAPwYAAB///78D4/DAAAAA'
    'AAAAfAAAAf///8A8H4wAAAAAAAAAxgAAH///5AGA+HAgAAAAAAAH/gAA////wBwLBgAAAAAAAAA/'
    '+AAH///8AEDBMAAAAAAAAAD/wAA8//+AAB4wAAAAAAAAAB/+AAAH//AAAO8wAAAAAAAAA//4AAB/'
    '/gAADvxAAAAAAAAAP//gAAP/wAAAd8/AAAAAAAAD//+AAD/8AAADAB7AAAAAAAAf//gAAf/AAAAN'
    'ofAAAAAAAAH//wAAH/wAAAAQQAAAAAAAAA//4AAB/8wAAAAeQAAAAAAAAH/+AAA//cAAAAP2AAAA'
    'AAAAA//gAAP/mAAAAH/gAAAAAAAAP/wAAB/xgAAAP/8ABAAAAAAD/4AAAf8YAAAD//gAAAAAAAA/'
    '8AAAD+AAAAA//8AAAAAAAAP+AAAA/gAAAAP//AAAAAAAAD/gAAAHwAAAAB//wAgAAAAAA/wAAAB4'
    'AAAAAcP4AAAAAAAAfwAAAAAAAAAAAA+AYAAAAAAH4AAAAAAAAAAAAEADAAAAAAB8AAAAAAAAAAAA'
    'AwDAAAAAAAeAAAAAAAAAAAAAABgAAAAAAHAAAAAAAAAAAAAAAQAAAAAABwAAAAAAAAAAAAAAAAAA'
    'AAAAcAAAAAAAAAAAAAAAAAAAAAADAAAAAAAAAAAAAAAA';

/// Decoded once, on first use.
List<bool>? _landCache;

List<bool> get _land {
  final cached = _landCache;
  if (cached != null) return cached;
  // Hand-rolled rather than dart:convert so this file stays a pure constant
  // with no import that a test would have to stand up.
  final bytes = _base64(_landMaskBase64);
  final out = List<bool>.filled(kMapCols * kMapRows, false);
  for (var i = 0; i < out.length; i++) {
    out[i] = (bytes[i >> 3] >> (7 - (i & 7))) & 1 == 1;
  }
  return _landCache = out;
}

const _b64chars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

List<int> _base64(String s) {
  final out = <int>[];
  var buffer = 0;
  var bits = 0;
  for (final ch in s.codeUnits) {
    final v = _b64chars.indexOf(String.fromCharCode(ch));
    if (v < 0) continue; // padding and newlines
    buffer = (buffer << 6) | v;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      out.add((buffer >> bits) & 0xFF);
    }
  }
  return out;
}

/// Whether the cell at [col], [row] is land.
bool isLandCell(int col, int row) {
  if (col < 0 || col >= kMapCols || row < 0 || row >= kMapRows) return false;
  return _land[row * kMapCols + col];
}

/// A point on the map in 0–1 space, ready to scale to any panel size.
///
/// Returns null for anything outside the cropped latitude band, so a place in
/// Antarctica is left off rather than clamped onto the bottom edge where it
/// would look like a real location.
({double x, double y})? projectToUnit(double lat, double lon) {
  if (lat > kMapLatTop || lat < kMapLatBottom) return null;
  return (
    x: (lon + 180) / 360,
    y: (kMapLatTop - lat) / (kMapLatTop - kMapLatBottom),
  );
}
