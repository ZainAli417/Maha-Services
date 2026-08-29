import 'models/aviation_role.dart';
import 'models/candidate_profile.dart';
import 'models/question.dart';

/// Projects a raw answer map (keyed by question id) onto the structured
/// [CandidateProfile] sections, following each question's `mapsTo` path.
///
/// Answers with no `mapsTo` still survive: they land in
/// `roleSpecificData.attributes` keyed by question id, so a template can grow
/// fields without a schema migration and the profile UI can still render them
/// with their question label.
abstract final class ProfileProjector {
  static const _pFullName = 'personalInfo.fullName';
  static const _pEmail = 'personalInfo.email';
  static const _pPhone = 'personalInfo.phone';
  static const _pSummary = 'personalInfo.summary';
  static const _pPicture = 'personalInfo.profilePicUrl';
  static const _pCity = 'personalInfo.location.city';
  static const _pCountry = 'personalInfo.location.country';
  static const _pCitizenship = 'personalInfo.citizenship';
  static const _pWorkAuth = 'personalInfo.workAuthorization';
  static const _pDob = 'personalInfo.dateOfBirth';
  static const _pSecondaryEmail = 'personalInfo.secondaryEmail';
  static const _pSocialLinks = 'personalInfo.socialLinks';

  static const _rLicenses = 'roleSpecificData.licensesAndRatings';
  static const _rAuthority = 'roleSpecificData.licenseAuthority';
  static const _rLicenseNo = 'roleSpecificData.licenseNumber';
  static const _rExpiry = 'roleSpecificData.licenseExpiry';
  static const _rAircraft = 'roleSpecificData.typeRatingsOrAircraftTypes';
  static const _rCompetencies = 'roleSpecificData.technicalCompetencies';
  static const _rTools = 'roleSpecificData.toolsAndSystems';
  static const _rMetricsPrefix =
      'roleSpecificData.flightHoursOrExperienceMetrics.';

  /// Builds the personal + role-specific sections for [template] from
  /// [answers]. [base] supplies values the form never asks for (avatar URL,
  /// auth email) so they survive a re-projection.
  static ({PersonalInfo personal, RoleSpecificData roleData}) project(
    RoleTemplate template,
    Map<String, dynamic> answers, {
    PersonalInfo? base,
  }) {
    var personal = base ?? const PersonalInfo();
    var city = personal.location.city;
    var country = personal.location.country;

    final licenseTitles = <String>[];
    final authorities = <String>[];
    String? licenseNumber;
    String? licenseExpiry;
    final aircraft = <String>[];
    final competencies = <String>[];
    final tools = <String>[];
    final metrics = <String, num>{};
    final attributes = <String, dynamic>{};

    for (final q in template.questions) {
      if (!answers.containsKey(q.id)) continue;
      final value = answers[q.id];
      if (_isBlank(value)) continue;

      final path = q.mapsTo;
      if (path == null) {
        attributes[q.id] = value;
        continue;
      }

      switch (path) {
        case _pFullName:
          personal = personal.copyWith(fullName: _str(value));
        case _pEmail:
          personal = personal.copyWith(email: _str(value));
        case _pPhone:
          personal = personal.copyWith(phone: _str(value));
        case _pSummary:
          personal = personal.copyWith(summary: _str(value));
        case _pPicture:
          personal = personal.copyWith(profilePicUrl: _str(value));
        case _pCity:
          city = _str(value);
        case _pCountry:
          country = _str(value);
        case _pCitizenship:
          personal = personal.copyWith(citizenship: _list(value));
        case _pWorkAuth:
          personal = personal.copyWith(workAuthorization: _list(value));
        case _pDob:
          personal = personal.copyWith(dateOfBirth: _str(value));
        case _pSecondaryEmail:
          personal = personal.copyWith(secondaryEmail: _str(value));
        case _pSocialLinks:
          personal = personal.copyWith(socialLinks: _list(value));
        case _rLicenses:
          licenseTitles.addAll(_list(value).where((v) => v != 'None'));
        case _rAuthority:
          authorities.addAll(_list(value));
        case _rLicenseNo:
          licenseNumber = _str(value);
        case _rExpiry:
          licenseExpiry = _str(value);
        case _rAircraft:
          _addAll(aircraft, _list(value));
        case _rCompetencies:
          _addAll(competencies, _list(value));
        case _rTools:
          _addAll(tools, _list(value));
        default:
          if (path.startsWith(_rMetricsPrefix)) {
            final key = path.substring(_rMetricsPrefix.length);
            final n = _num(value);
            if (n != null) metrics[key] = n;
          } else {
            attributes[q.id] = value;
          }
      }
    }

    personal = personal.copyWith(
      location: CandidateLocation(city: city, country: country),
    );

    final authority = authorities.isEmpty ? '' : authorities.join(', ');
    final licenses = [
      for (final title in licenseTitles)
        LicenseEntry(
          title: title,
          issuingAuthority: authority,
          licenseNumber: licenseNumber,
          expiryDate: licenseExpiry,
        ),
    ];

    return (
      personal: personal,
      roleData: RoleSpecificData(
        licensesAndRatings: licenses,
        experienceMetrics: metrics,
        aircraftTypes: aircraft,
        technicalCompetencies: competencies,
        toolsAndSystems: tools,
        attributes: attributes,
      ),
    );
  }

  /// Seeds an answer map from an already-projected profile so a returning
  /// candidate sees their saved values even if the raw answer map was lost
  /// (e.g. the profile came from the legacy CV importer).
  static Map<String, dynamic> hydrate(
    RoleTemplate template,
    CandidateProfile profile,
  ) {
    final out = Map<String, dynamic>.from(profile.answers);
    for (final q in template.questions) {
      if (out.containsKey(q.id)) continue;
      final v = _readBack(q, profile);
      if (v != null) out[q.id] = v;
    }
    return out;
  }

  static dynamic _readBack(OnboardingQuestion q, CandidateProfile p) {
    switch (q.mapsTo) {
      case _pFullName:
        return _orNull(p.personalInfo.fullName);
      case _pEmail:
        return _orNull(p.personalInfo.email);
      case _pPhone:
        return _orNull(p.personalInfo.phone);
      case _pSummary:
        return _orNull(p.personalInfo.summary);
      case _pCity:
        return _orNull(p.personalInfo.location.city);
      case _pCountry:
        return _orNull(p.personalInfo.location.country);
      case _pCitizenship:
        return p.personalInfo.citizenship.isEmpty
            ? null
            : p.personalInfo.citizenship;
      case _pWorkAuth:
        return p.personalInfo.workAuthorization.isEmpty
            ? null
            : p.personalInfo.workAuthorization;
      case _pDob:
        return _orNull(p.personalInfo.dateOfBirth);
      case _pSecondaryEmail:
        return _orNull(p.personalInfo.secondaryEmail);
      case _pSocialLinks:
        return p.personalInfo.socialLinks.isEmpty
            ? null
            : p.personalInfo.socialLinks;
      case _rLicenseNo:
        final n = p.roleSpecificData.licensesAndRatings
            .map((l) => l.licenseNumber)
            .whereType<String>()
            .where((s) => s.isNotEmpty);
        return n.isEmpty ? null : n.first;
      default:
        final path = q.mapsTo;
        if (path != null && path.startsWith(_rMetricsPrefix)) {
          return p.roleSpecificData
              .experienceMetrics[path.substring(_rMetricsPrefix.length)];
        }
        return p.roleSpecificData.attributes[q.id];
    }
  }

  // ── Coercion ─────────────────────────────────────────────────────────────

  static bool _isBlank(dynamic v) {
    if (v == null) return true;
    if (v is String) return v.trim().isEmpty;
    if (v is List) return v.isEmpty;
    if (v is Map) return v.isEmpty;
    return false;
  }

  static String _str(dynamic v) => v?.toString().trim() ?? '';

  static String? _orNull(String v) => v.trim().isEmpty ? null : v;

  static num? _num(dynamic v) =>
      v is num ? v : num.tryParse(v?.toString().trim() ?? '');

  static List<String> _list(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    final s = _str(v);
    return s.isEmpty ? const [] : [s];
  }

  static void _addAll(List<String> target, List<String> values) {
    for (final v in values) {
      if (!target.contains(v)) target.add(v);
    }
  }
}
