/// Country and nationality names to coordinates.
///
/// The admin dashboard aggregates candidates by whichever of nationality or
/// country the profile carries, so both spellings arrive: "Pakistan" and
/// "Pakistani", "UK" and "British". Every form is resolved to one place here so
/// the map does not show the same country twice under two names.
///
/// Coordinates are a representative point per country — a capital or population
/// centre, not a centroid. A pin should land where the people are, and a
/// centroid puts Canada's pin in Nunavut.
///
/// Pure and dependency-free, so the normalisation can be tested.
library;

typedef Place = ({String country, double lat, double lon});

/// Canonical country → coordinates.
const Map<String, ({double lat, double lon})> _coords = {
  // ── South Asia — the core of this pool ──
  'Pakistan': (lat: 33.7, lon: 73.0),
  'India': (lat: 28.6, lon: 77.2),
  'Bangladesh': (lat: 23.8, lon: 90.4),
  'Sri Lanka': (lat: 6.9, lon: 79.9),
  'Nepal': (lat: 27.7, lon: 85.3),
  'Afghanistan': (lat: 34.5, lon: 69.2),
  'Maldives': (lat: 4.2, lon: 73.5),
  'Bhutan': (lat: 27.5, lon: 89.6),

  // ── Gulf and Middle East — where the jobs are ──
  'United Arab Emirates': (lat: 24.5, lon: 54.4),
  'Saudi Arabia': (lat: 24.7, lon: 46.7),
  'Qatar': (lat: 25.3, lon: 51.5),
  'Kuwait': (lat: 29.4, lon: 48.0),
  'Bahrain': (lat: 26.2, lon: 50.6),
  'Oman': (lat: 23.6, lon: 58.5),
  'Yemen': (lat: 15.4, lon: 44.2),
  'Jordan': (lat: 31.9, lon: 35.9),
  'Lebanon': (lat: 33.9, lon: 35.5),
  'Iraq': (lat: 33.3, lon: 44.4),
  'Iran': (lat: 35.7, lon: 51.4),
  'Syria': (lat: 33.5, lon: 36.3),
  'Israel': (lat: 31.8, lon: 35.2),
  'Turkey': (lat: 39.9, lon: 32.9),

  // ── Africa ──
  'Egypt': (lat: 30.0, lon: 31.2),
  'Morocco': (lat: 34.0, lon: -6.8),
  'Algeria': (lat: 36.8, lon: 3.1),
  'Tunisia': (lat: 36.8, lon: 10.2),
  'Libya': (lat: 32.9, lon: 13.2),
  'Sudan': (lat: 15.6, lon: 32.5),
  'Nigeria': (lat: 9.1, lon: 7.5),
  'Ghana': (lat: 5.6, lon: -0.2),
  'Kenya': (lat: -1.3, lon: 36.8),
  'Ethiopia': (lat: 9.0, lon: 38.7),
  'Tanzania': (lat: -6.2, lon: 35.7),
  'Uganda': (lat: 0.3, lon: 32.6),
  'South Africa': (lat: -26.2, lon: 28.0),
  'Zimbabwe': (lat: -17.8, lon: 31.0),
  'Zambia': (lat: -15.4, lon: 28.3),
  'Senegal': (lat: 14.7, lon: -17.5),
  'Somalia': (lat: 2.0, lon: 45.3),
  'Cameroon': (lat: 3.9, lon: 11.5),
  'Ivory Coast': (lat: 5.3, lon: -4.0),

  // ── Europe ──
  'United Kingdom': (lat: 51.5, lon: -0.1),
  'Ireland': (lat: 53.3, lon: -6.3),
  'France': (lat: 48.9, lon: 2.4),
  'Germany': (lat: 52.5, lon: 13.4),
  'Netherlands': (lat: 52.4, lon: 4.9),
  'Belgium': (lat: 50.8, lon: 4.4),
  'Spain': (lat: 40.4, lon: -3.7),
  'Portugal': (lat: 38.7, lon: -9.1),
  'Italy': (lat: 41.9, lon: 12.5),
  'Switzerland': (lat: 46.9, lon: 7.4),
  'Austria': (lat: 48.2, lon: 16.4),
  'Sweden': (lat: 59.3, lon: 18.1),
  'Norway': (lat: 59.9, lon: 10.8),
  'Denmark': (lat: 55.7, lon: 12.6),
  'Finland': (lat: 60.2, lon: 24.9),
  'Poland': (lat: 52.2, lon: 21.0),
  'Ukraine': (lat: 50.4, lon: 30.5),
  'Russia': (lat: 55.8, lon: 37.6),
  'Romania': (lat: 44.4, lon: 26.1),
  'Greece': (lat: 38.0, lon: 23.7),
  'Czechia': (lat: 50.1, lon: 14.4),
  'Hungary': (lat: 47.5, lon: 19.0),
  'Serbia': (lat: 44.8, lon: 20.5),
  'Bulgaria': (lat: 42.7, lon: 23.3),
  'Croatia': (lat: 45.8, lon: 16.0),
  'Azerbaijan': (lat: 40.4, lon: 49.9),
  'Kazakhstan': (lat: 51.2, lon: 71.4),
  'Uzbekistan': (lat: 41.3, lon: 69.2),

  // ── East and South-East Asia ──
  'China': (lat: 39.9, lon: 116.4),
  'Japan': (lat: 35.7, lon: 139.7),
  'South Korea': (lat: 37.6, lon: 127.0),
  'Malaysia': (lat: 3.1, lon: 101.7),
  'Singapore': (lat: 1.35, lon: 103.8),
  'Indonesia': (lat: -6.2, lon: 106.8),
  'Thailand': (lat: 13.8, lon: 100.5),
  'Vietnam': (lat: 21.0, lon: 105.8),
  'Philippines': (lat: 14.6, lon: 121.0),
  'Myanmar': (lat: 16.9, lon: 96.2),
  'Hong Kong': (lat: 22.3, lon: 114.2),
  'Taiwan': (lat: 25.0, lon: 121.6),

  // ── Americas and Oceania ──
  'United States': (lat: 38.9, lon: -77.0),
  'Canada': (lat: 43.7, lon: -79.4),
  'Mexico': (lat: 19.4, lon: -99.1),
  'Brazil': (lat: -23.5, lon: -46.6),
  'Argentina': (lat: -34.6, lon: -58.4),
  'Chile': (lat: -33.4, lon: -70.7),
  'Colombia': (lat: 4.7, lon: -74.1),
  'Peru': (lat: -12.0, lon: -77.0),
  'Australia': (lat: -33.9, lon: 151.2),
  'New Zealand': (lat: -36.8, lon: 174.8),
};

/// Every spelling that resolves to a canonical name.
///
/// Nationalities are here because the aggregation prefers `nationality`, which
/// is an adjective on most profiles. Without this half the pool would fall off
/// the map for being called "Pakistani" rather than "Pakistan".
const Map<String, String> _aliases = {
  // nationalities
  'pakistani': 'Pakistan',
  'indian': 'India',
  'bangladeshi': 'Bangladesh',
  'sri lankan': 'Sri Lanka',
  'srilankan': 'Sri Lanka',
  'nepali': 'Nepal',
  'nepalese': 'Nepal',
  'afghan': 'Afghanistan',
  'afghani': 'Afghanistan',
  'emirati': 'United Arab Emirates',
  'saudi': 'Saudi Arabia',
  'qatari': 'Qatar',
  'kuwaiti': 'Kuwait',
  'bahraini': 'Bahrain',
  'omani': 'Oman',
  'yemeni': 'Yemen',
  'jordanian': 'Jordan',
  'lebanese': 'Lebanon',
  'iraqi': 'Iraq',
  'iranian': 'Iran',
  'syrian': 'Syria',
  'israeli': 'Israel',
  'turkish': 'Turkey',
  'egyptian': 'Egypt',
  'moroccan': 'Morocco',
  'algerian': 'Algeria',
  'tunisian': 'Tunisia',
  'libyan': 'Libya',
  'sudanese': 'Sudan',
  'nigerian': 'Nigeria',
  'ghanaian': 'Ghana',
  'kenyan': 'Kenya',
  'ethiopian': 'Ethiopia',
  'tanzanian': 'Tanzania',
  'ugandan': 'Uganda',
  'south african': 'South Africa',
  'zimbabwean': 'Zimbabwe',
  'zambian': 'Zambia',
  'senegalese': 'Senegal',
  'somali': 'Somalia',
  'cameroonian': 'Cameroon',
  'british': 'United Kingdom',
  'english': 'United Kingdom',
  'scottish': 'United Kingdom',
  'welsh': 'United Kingdom',
  'irish': 'Ireland',
  'french': 'France',
  'german': 'Germany',
  'dutch': 'Netherlands',
  'belgian': 'Belgium',
  'spanish': 'Spain',
  'portuguese': 'Portugal',
  'italian': 'Italy',
  'swiss': 'Switzerland',
  'austrian': 'Austria',
  'swedish': 'Sweden',
  'norwegian': 'Norway',
  'danish': 'Denmark',
  'finnish': 'Finland',
  'polish': 'Poland',
  'ukrainian': 'Ukraine',
  'russian': 'Russia',
  'romanian': 'Romania',
  'greek': 'Greece',
  'czech': 'Czechia',
  'hungarian': 'Hungary',
  'serbian': 'Serbia',
  'bulgarian': 'Bulgaria',
  'croatian': 'Croatia',
  'azerbaijani': 'Azerbaijan',
  'kazakh': 'Kazakhstan',
  'uzbek': 'Uzbekistan',
  'chinese': 'China',
  'japanese': 'Japan',
  'korean': 'South Korea',
  'malaysian': 'Malaysia',
  'singaporean': 'Singapore',
  'indonesian': 'Indonesia',
  'thai': 'Thailand',
  'vietnamese': 'Vietnam',
  'filipino': 'Philippines',
  'filipina': 'Philippines',
  'burmese': 'Myanmar',
  'american': 'United States',
  'canadian': 'Canada',
  'mexican': 'Mexico',
  'brazilian': 'Brazil',
  'argentine': 'Argentina',
  'argentinian': 'Argentina',
  'chilean': 'Chile',
  'colombian': 'Colombia',
  'peruvian': 'Peru',
  'australian': 'Australia',
  'kiwi': 'New Zealand',
  'new zealander': 'New Zealand',

  // short forms and older names
  'uae': 'United Arab Emirates',
  'u.a.e.': 'United Arab Emirates',
  'ksa': 'Saudi Arabia',
  'uk': 'United Kingdom',
  'u.k.': 'United Kingdom',
  'great britain': 'United Kingdom',
  'britain': 'United Kingdom',
  'england': 'United Kingdom',
  'scotland': 'United Kingdom',
  'usa': 'United States',
  'u.s.a.': 'United States',
  'us': 'United States',
  'united states of america': 'United States',
  'america': 'United States',
  'korea': 'South Korea',
  'republic of korea': 'South Korea',
  'burma': 'Myanmar',
  'czech republic': 'Czechia',
  'holland': 'Netherlands',
  'russian federation': 'Russia',
  'côte d\'ivoire': 'Ivory Coast',
  'cote d\'ivoire': 'Ivory Coast',
  'türkiye': 'Turkey',
  'turkiye': 'Turkey',
};

/// Resolves whatever the profile said into a place, or null.
///
/// Null is deliberate: an unrecognised value is reported as unplaced rather
/// than guessed onto the map, because a pin in the wrong country is worse than
/// a pin missing from one.
Place? resolvePlace(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final key = trimmed.toLowerCase();
  if (key == 'not specified' || key == 'n/a' || key == 'unknown') return null;

  final canonical = _aliases[key] ??
      _coords.keys.firstWhere(
        (c) => c.toLowerCase() == key,
        orElse: () => '',
      );
  if (canonical.isEmpty) return null;

  final c = _coords[canonical];
  if (c == null) return null;
  return (country: canonical, lat: c.lat, lon: c.lon);
}

/// Groups counts by resolved country, and reports what could not be placed.
///
/// Two spellings of one country add up rather than drawing two pins — the whole
/// reason the aliases exist.
({List<({Place place, int count})> placed, Map<String, int> unplaced})
    placeCounts(Map<String, int> byName) {
  final merged = <String, ({Place place, int count})>{};
  final unplaced = <String, int>{};

  for (final e in byName.entries) {
    final place = resolvePlace(e.key);
    if (place == null) {
      unplaced[e.key.trim()] = (unplaced[e.key.trim()] ?? 0) + e.value;
      continue;
    }
    final prev = merged[place.country];
    merged[place.country] =
        (place: place, count: (prev?.count ?? 0) + e.value);
  }

  final placed = merged.values.toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0
          ? byCount
          : a.place.country.compareTo(b.place.country);
    });
  return (placed: placed, unplaced: unplaced);
}
