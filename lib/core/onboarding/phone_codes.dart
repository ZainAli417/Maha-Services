/// Country dial codes for the phone field.
///
/// The flag is derived from the ISO 3166-1 alpha-2 code rather than shipped as
/// an asset: the two letters map directly onto Unicode regional indicator
/// symbols, so `AE` renders 🇦🇪 with no image to load, no licence to track and
/// no missing-asset build break. Platforms without flag glyphs fall back to
/// showing the two letters, which is still readable.
class PhoneCountry {
  const PhoneCountry(this.iso, this.name, this.dialCode);

  /// ISO 3166-1 alpha-2, uppercase.
  final String iso;
  final String name;

  /// Includes the leading `+`.
  final String dialCode;

  /// Regional indicator pair, e.g. `AE` -> 🇦🇪.
  String get flag => String.fromCharCodes(
        iso.codeUnits.map((c) => 0x1F1E6 + c - 0x41),
      );

  /// What the picker shows in its list and what a search matches against.
  String get label => '$flag  $name  $dialCode';

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        iso.toLowerCase() == q ||
        dialCode.contains(q.replaceAll('+', ''));
  }
}

abstract final class PhoneCodes {
  /// Shown at the top of the picker before the alphabetical list.
  ///
  /// Aviation recruitment for this platform is Gulf- and South-Asia-weighted,
  /// so these are the codes most candidates reach for; everything else is one
  /// search away.
  static const priorityIso = ['AE', 'SA', 'QA', 'PK', 'IN', 'GB', 'US'];

  /// Fallback when we cannot infer anything from an existing value.
  static const defaultIso = 'AE';

  /// `ISO|Name|dial` — compact on purpose. Parsed once into [all].
  static const _raw = <String>[
    'AF|Afghanistan|93', 'AL|Albania|355', 'DZ|Algeria|213', 'AD|Andorra|376',
    'AO|Angola|244', 'AR|Argentina|54', 'AM|Armenia|374', 'AU|Australia|61',
    'AT|Austria|43', 'AZ|Azerbaijan|994', 'BH|Bahrain|973', 'BD|Bangladesh|880',
    'BY|Belarus|375', 'BE|Belgium|32', 'BZ|Belize|501', 'BJ|Benin|229',
    'BT|Bhutan|975', 'BO|Bolivia|591', 'BA|Bosnia and Herzegovina|387',
    'BW|Botswana|267', 'BR|Brazil|55', 'BN|Brunei|673', 'BG|Bulgaria|359',
    'BF|Burkina Faso|226', 'BI|Burundi|257', 'KH|Cambodia|855',
    'CM|Cameroon|237', 'CA|Canada|1', 'CV|Cape Verde|238', 'CF|Central African Republic|236',
    'TD|Chad|235', 'CL|Chile|56', 'CN|China|86', 'CO|Colombia|57',
    'KM|Comoros|269', 'CG|Congo|242', 'CD|Congo (DRC)|243', 'CR|Costa Rica|506',
    'CI|Côte d\'Ivoire|225', 'HR|Croatia|385', 'CU|Cuba|53', 'CY|Cyprus|357',
    'CZ|Czechia|420', 'DK|Denmark|45', 'DJ|Djibouti|253',
    'DO|Dominican Republic|1809', 'EC|Ecuador|593', 'EG|Egypt|20',
    'SV|El Salvador|503', 'GQ|Equatorial Guinea|240', 'ER|Eritrea|291',
    'EE|Estonia|372', 'ET|Ethiopia|251', 'FJ|Fiji|679', 'FI|Finland|358',
    'FR|France|33', 'GA|Gabon|241', 'GM|Gambia|220', 'GE|Georgia|995',
    'DE|Germany|49', 'GH|Ghana|233', 'GR|Greece|30', 'GT|Guatemala|502',
    'GN|Guinea|224', 'GY|Guyana|592', 'HT|Haiti|509', 'HN|Honduras|504',
    'HK|Hong Kong|852', 'HU|Hungary|36', 'IS|Iceland|354', 'IN|India|91',
    'ID|Indonesia|62', 'IR|Iran|98', 'IQ|Iraq|964', 'IE|Ireland|353',
    'IL|Israel|972', 'IT|Italy|39', 'JM|Jamaica|1876', 'JP|Japan|81',
    'JO|Jordan|962', 'KZ|Kazakhstan|7', 'KE|Kenya|254', 'KW|Kuwait|965',
    'KG|Kyrgyzstan|996', 'LA|Laos|856', 'LV|Latvia|371', 'LB|Lebanon|961',
    'LS|Lesotho|266', 'LR|Liberia|231', 'LY|Libya|218', 'LI|Liechtenstein|423',
    'LT|Lithuania|370', 'LU|Luxembourg|352', 'MO|Macau|853', 'MG|Madagascar|261',
    'MW|Malawi|265', 'MY|Malaysia|60', 'MV|Maldives|960', 'ML|Mali|223',
    'MT|Malta|356', 'MR|Mauritania|222', 'MU|Mauritius|230', 'MX|Mexico|52',
    'MD|Moldova|373', 'MC|Monaco|377', 'MN|Mongolia|976', 'ME|Montenegro|382',
    'MA|Morocco|212', 'MZ|Mozambique|258', 'MM|Myanmar|95', 'NA|Namibia|264',
    'NP|Nepal|977', 'NL|Netherlands|31', 'NZ|New Zealand|64',
    'NI|Nicaragua|505', 'NE|Niger|227', 'NG|Nigeria|234',
    'MK|North Macedonia|389', 'NO|Norway|47', 'OM|Oman|968', 'PK|Pakistan|92',
    'PS|Palestine|970', 'PA|Panama|507', 'PG|Papua New Guinea|675',
    'PY|Paraguay|595', 'PE|Peru|51', 'PH|Philippines|63', 'PL|Poland|48',
    'PT|Portugal|351', 'QA|Qatar|974', 'RO|Romania|40', 'RU|Russia|7',
    'RW|Rwanda|250', 'SA|Saudi Arabia|966', 'SN|Senegal|221', 'RS|Serbia|381',
    'SC|Seychelles|248', 'SL|Sierra Leone|232', 'SG|Singapore|65',
    'SK|Slovakia|421', 'SI|Slovenia|386', 'SO|Somalia|252',
    'ZA|South Africa|27', 'KR|South Korea|82', 'SS|South Sudan|211',
    'ES|Spain|34', 'LK|Sri Lanka|94', 'SD|Sudan|249', 'SE|Sweden|46',
    'CH|Switzerland|41', 'SY|Syria|963', 'TW|Taiwan|886', 'TJ|Tajikistan|992',
    'TZ|Tanzania|255', 'TH|Thailand|66', 'TG|Togo|228', 'TT|Trinidad and Tobago|1868',
    'TN|Tunisia|216', 'TR|Türkiye|90', 'TM|Turkmenistan|993', 'UG|Uganda|256',
    'UA|Ukraine|380', 'AE|United Arab Emirates|971', 'GB|United Kingdom|44',
    'US|United States|1', 'UY|Uruguay|598', 'UZ|Uzbekistan|998',
    'VE|Venezuela|58', 'VN|Vietnam|84', 'YE|Yemen|967', 'ZM|Zambia|260',
    'ZW|Zimbabwe|263',
  ];

  static final List<PhoneCountry> all = () {
    final list = _raw.map((row) {
      final parts = row.split('|');
      return PhoneCountry(parts[0], parts[1], '+${parts[2]}');
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List<PhoneCountry>.unmodifiable(list);
  }();

  /// [priorityIso] entries first, then everything else alphabetically.
  static final List<PhoneCountry> ordered = () {
    final priority = <PhoneCountry>[];
    for (final iso in priorityIso) {
      final match = byIso(iso);
      if (match != null) priority.add(match);
    }
    final rest = all.where((c) => !priorityIso.contains(c.iso));
    return List<PhoneCountry>.unmodifiable([...priority, ...rest]);
  }();

  static PhoneCountry? byIso(String iso) {
    final upper = iso.toUpperCase();
    for (final c in all) {
      if (c.iso == upper) return c;
    }
    return null;
  }

  static PhoneCountry get fallback => byIso(defaultIso) ?? all.first;

  /// Longest-prefix match, so `+1868` (Trinidad) is not swallowed by `+1`.
  ///
  /// Some codes are genuinely shared and cannot be resolved from the dial code
  /// alone — `+1` covers the US, Canada and much of the Caribbean, and `+7`
  /// covers Russia and Kazakhstan. Telling them apart needs the area code,
  /// which we deliberately do not try to parse. On a tie we pick by
  /// [priorityIso] order and let the candidate correct the flag, which is one
  /// tap; guessing from area codes would be a table to maintain forever and
  /// still be wrong for ported numbers.
  static PhoneCountry? byDialCode(String dial) {
    final needle = dial.startsWith('+') ? dial : '+$dial';
    PhoneCountry? best;
    for (final c in all) {
      if (!needle.startsWith(c.dialCode)) continue;
      if (best == null) {
        best = c;
      } else if (c.dialCode.length > best.dialCode.length) {
        best = c;
      } else if (c.dialCode.length == best.dialCode.length &&
          _priorityRank(c) < _priorityRank(best)) {
        best = c;
      }
    }
    return best;
  }

  /// Position in [priorityIso], or a sentinel past the end for anything not
  /// listed — so a listed country always wins a tie against an unlisted one.
  static int _priorityRank(PhoneCountry c) {
    final i = priorityIso.indexOf(c.iso);
    return i < 0 ? priorityIso.length : i;
  }

  /// Splits a stored value like `+971 50 123 4567` back into the country and
  /// the national part, so reopening a saved draft rehydrates both halves of
  /// the control.
  ///
  /// Values that were never entered through this field (a legacy profile, or
  /// a number a CV extractor produced) may have no recognisable dial code. In
  /// that case the whole string is handed back as the national number and the
  /// country falls back to the default, which the candidate can correct.
  static ({PhoneCountry country, String number}) split(String? stored) {
    final raw = (stored ?? '').trim();
    if (raw.isEmpty) return (country: fallback, number: '');

    if (raw.startsWith('+')) {
      final compact = raw.replaceAll(RegExp(r'[\s\-()]'), '');
      final match = byDialCode(compact);
      if (match != null) {
        return (
          country: match,
          number: compact.substring(match.dialCode.length).trim(),
        );
      }
    }
    return (country: fallback, number: raw);
  }

  /// The inverse of [split]. Stored as one string so every existing reader —
  /// the recruiter view, the admin contact fetch, the CV generator — keeps
  /// working without a migration.
  static String join(PhoneCountry country, String number) {
    final national = number.trim();
    if (national.isEmpty) return '';
    return '${country.dialCode} $national';
  }
}
