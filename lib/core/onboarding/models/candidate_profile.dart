import 'package:cloud_firestore/cloud_firestore.dart';

/// Onboarding lifecycle state for a candidate document.
enum OnboardingStatus {
  draft,
  completed;

  String toJson() => name;

  static OnboardingStatus fromJson(dynamic v) =>
      v?.toString() == 'completed' ? OnboardingStatus.completed : OnboardingStatus.draft;
}

/// The role template a candidate is onboarding against.
class TargetRole {
  const TargetRole({
    required this.industry,
    required this.roleId,
    required this.roleTitle,
  });

  final String industry;
  final String roleId;
  final String roleTitle;

  static const empty = TargetRole(industry: '', roleId: '', roleTitle: '');

  bool get isEmpty => roleId.isEmpty;

  Map<String, dynamic> toJson() => {
        'industry': industry,
        'roleId': roleId,
        'roleTitle': roleTitle,
      };

  factory TargetRole.fromJson(Map<String, dynamic>? j) {
    if (j == null) return empty;
    return TargetRole(
      industry: (j['industry'] ?? '').toString(),
      roleId: (j['roleId'] ?? '').toString(),
      roleTitle: (j['roleTitle'] ?? '').toString(),
    );
  }
}

class CandidateLocation {
  const CandidateLocation({this.city = '', this.country = ''});

  final String city;
  final String country;

  bool get isEmpty => city.isEmpty && country.isEmpty;

  String get display => [city, country].where((s) => s.isNotEmpty).join(', ');

  Map<String, dynamic> toJson() => {'city': city, 'country': country};

  factory CandidateLocation.fromJson(Map<String, dynamic>? j) =>
      CandidateLocation(
        city: (j?['city'] ?? '').toString(),
        country: (j?['country'] ?? '').toString(),
      );
}

class PersonalInfo {
  const PersonalInfo({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.location = const CandidateLocation(),
    this.citizenship = const [],
    this.workAuthorization = const [],
    this.profilePicUrl = '',
    this.summary = '',
    this.dateOfBirth = '',
    this.secondaryEmail = '',
    this.socialLinks = const [],
    this.nationality = '',
    this.objectives = '',
    this.skills = const [],
  });

  final String fullName;
  final String email;
  final String phone;
  final CandidateLocation location;
  final List<String> citizenship;
  final List<String> workAuthorization;

  /// Beyond the base contract, but carried because the profile header, the
  /// recruiter applicant list and the generated CV all read them.
  final String profilePicUrl;
  final String summary;

  /// ISO-8601 date. Surfaced to recruiters and printed on the generated CV.
  final String dateOfBirth;
  final String secondaryEmail;
  final List<String> socialLinks;

  /// Single nationality as the candidate states it. [citizenship] is the
  /// templated multi-select (dual nationals, right-to-work checks); this is
  /// the one line a recruiter card and a printed CV show.
  final String nationality;

  /// Career objective. Distinct from [summary], which is the professional
  /// history in prose — the profile editor asks for both and the CV prints
  /// them in different places.
  final String objectives;

  /// Free-form skills the candidate claims, on top of whatever the role
  /// template captured as competencies and tools.
  final List<String> skills;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'location': location.toJson(),
        'citizenship': citizenship,
        'workAuthorization': workAuthorization,
        if (profilePicUrl.isNotEmpty) 'profilePicUrl': profilePicUrl,
        if (summary.isNotEmpty) 'summary': summary,
        if (dateOfBirth.isNotEmpty) 'dateOfBirth': dateOfBirth,
        if (secondaryEmail.isNotEmpty) 'secondaryEmail': secondaryEmail,
        if (socialLinks.isNotEmpty) 'socialLinks': socialLinks,
        if (nationality.isNotEmpty) 'nationality': nationality,
        if (objectives.isNotEmpty) 'objectives': objectives,
        if (skills.isNotEmpty) 'skills': skills,
      };

  factory PersonalInfo.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const PersonalInfo();
    return PersonalInfo(
      fullName: (j['fullName'] ?? j['name'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      phone: (j['phone'] ?? j['contactNumber'] ?? '').toString(),
      location: CandidateLocation.fromJson(
          j['location'] is Map ? Map<String, dynamic>.from(j['location']) : null),
      citizenship: _stringList(j['citizenship']),
      workAuthorization: _stringList(j['workAuthorization']),
      profilePicUrl: (j['profilePicUrl'] ?? '').toString(),
      summary: (j['summary'] ?? '').toString(),
      dateOfBirth: (j['dateOfBirth'] ?? j['dob'] ?? '').toString(),
      secondaryEmail:
          (j['secondaryEmail'] ?? j['secondary_email'] ?? '').toString(),
      socialLinks: _stringList(j['socialLinks']),
      nationality: (j['nationality'] ?? '').toString(),
      objectives: (j['objectives'] ?? '').toString(),
      skills: _stringList(j['skills']),
    );
  }

  PersonalInfo copyWith({
    String? fullName,
    String? email,
    String? phone,
    CandidateLocation? location,
    List<String>? citizenship,
    List<String>? workAuthorization,
    String? profilePicUrl,
    String? summary,
    String? dateOfBirth,
    String? secondaryEmail,
    List<String>? socialLinks,
    String? nationality,
    String? objectives,
    List<String>? skills,
  }) =>
      PersonalInfo(
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        location: location ?? this.location,
        citizenship: citizenship ?? this.citizenship,
        workAuthorization: workAuthorization ?? this.workAuthorization,
        profilePicUrl: profilePicUrl ?? this.profilePicUrl,
        summary: summary ?? this.summary,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        secondaryEmail: secondaryEmail ?? this.secondaryEmail,
        socialLinks: socialLinks ?? this.socialLinks,
        nationality: nationality ?? this.nationality,
        objectives: objectives ?? this.objectives,
        skills: skills ?? this.skills,
      );
}

/// A licence, rating, type rating or regulatory authorisation.
class LicenseEntry {
  const LicenseEntry({
    required this.title,
    this.issuingAuthority = '',
    this.licenseNumber,
    this.expiryDate,
    this.verified = false,
  });

  final String title;
  final String issuingAuthority;
  final String? licenseNumber;

  /// ISO-8601 date or `MM/YYYY`, whichever the source field produced.
  final String? expiryDate;
  final bool verified;

  Map<String, dynamic> toJson() => {
        'title': title,
        'issuingAuthority': issuingAuthority,
        if (licenseNumber != null && licenseNumber!.isNotEmpty)
          'licenseNumber': licenseNumber,
        if (expiryDate != null && expiryDate!.isNotEmpty) 'expiryDate': expiryDate,
        'verified': verified,
      };

  factory LicenseEntry.fromJson(Map<String, dynamic> j) => LicenseEntry(
        title: (j['title'] ?? j['name'] ?? '').toString(),
        issuingAuthority:
            (j['issuingAuthority'] ?? j['issuer'] ?? j['organization'] ?? '')
                .toString(),
        licenseNumber: j['licenseNumber']?.toString(),
        expiryDate: j['expiryDate']?.toString(),
        verified: j['verified'] == true,
      );
}

class ExperienceEntry {
  const ExperienceEntry({
    required this.id,
    this.title = '',
    this.company = '',
    this.location = '',
    this.startDate = '',
    this.endDate,
    this.isCurrent = false,
    this.responsibilities = const [],
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final List<String> responsibilities;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'company': company,
        'location': location,
        'startDate': startDate,
        'endDate': endDate,
        'isCurrent': isCurrent,
        'responsibilities': responsibilities,
      };

  factory ExperienceEntry.fromJson(Map<String, dynamic> j) => ExperienceEntry(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? j['role'] ?? '').toString(),
        company: (j['company'] ?? j['organization'] ?? '').toString(),
        location: (j['location'] ?? '').toString(),
        startDate: (j['startDate'] ?? '').toString(),
        endDate: j['endDate']?.toString(),
        isCurrent: j['isCurrent'] == true,
        responsibilities: _stringList(j['responsibilities'] ?? j['duties']),
      );

  ExperienceEntry copyWith({
    String? title,
    String? company,
    String? location,
    String? startDate,
    String? endDate,
    bool? isCurrent,
    List<String>? responsibilities,
  }) =>
      ExperienceEntry(
        id: id,
        title: title ?? this.title,
        company: company ?? this.company,
        location: location ?? this.location,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        isCurrent: isCurrent ?? this.isCurrent,
        responsibilities: responsibilities ?? this.responsibilities,
      );
}

class EducationEntry {
  const EducationEntry({
    required this.id,
    this.institution = '',
    this.degree = '',
    this.fieldOfStudy = '',
    this.graduationYear,
    this.grade = '',
  });

  final String id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final int? graduationYear;

  /// Marks, CGPA or classification, exactly as the candidate wrote it —
  /// grading scales differ too much between countries to normalise.
  final String grade;

  Map<String, dynamic> toJson() => {
        'id': id,
        'institution': institution,
        'degree': degree,
        'fieldOfStudy': fieldOfStudy,
        'graduationYear': graduationYear,
        'grade': grade,
      };

  factory EducationEntry.fromJson(Map<String, dynamic> j) => EducationEntry(
        id: (j['id'] ?? '').toString(),
        institution: (j['institution'] ?? j['institutionName'] ?? '').toString(),
        degree: (j['degree'] ?? '').toString(),
        fieldOfStudy: (j['fieldOfStudy'] ?? j['majorSubjects'] ?? '').toString(),
        graduationYear: _year(j['graduationYear'] ?? j['duration']),
        grade: (j['grade'] ?? j['marksOrCgpa'] ?? '').toString(),
      );

  EducationEntry copyWith({
    String? institution,
    String? degree,
    String? fieldOfStudy,
    int? graduationYear,
    String? grade,
  }) =>
      EducationEntry(
        id: id,
        institution: institution ?? this.institution,
        degree: degree ?? this.degree,
        fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
        graduationYear: graduationYear ?? this.graduationYear,
        grade: grade ?? this.grade,
      );
}

class CertificationEntry {
  const CertificationEntry({
    required this.id,
    this.name = '',
    this.issuer = '',
    this.issueDate = '',
    this.expiryDate,
  });

  final String id;
  final String name;
  final String issuer;
  final String issueDate;
  final String? expiryDate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'issuer': issuer,
        'issueDate': issueDate,
        if (expiryDate != null && expiryDate!.isNotEmpty) 'expiryDate': expiryDate,
      };

  factory CertificationEntry.fromJson(Map<String, dynamic> j) =>
      CertificationEntry(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        issuer: (j['issuer'] ?? j['organization'] ?? '').toString(),
        issueDate: (j['issueDate'] ?? '').toString(),
        expiryDate: j['expiryDate']?.toString(),
      );

  CertificationEntry copyWith({
    String? name,
    String? issuer,
    String? issueDate,
    String? expiryDate,
  }) =>
      CertificationEntry(
        id: id,
        name: name ?? this.name,
        issuer: issuer ?? this.issuer,
        issueDate: issueDate ?? this.issueDate,
        expiryDate: expiryDate ?? this.expiryDate,
      );
}

/// Where an uploaded file belongs on the profile.
///
/// One document list with a category beats three parallel lists: every screen
/// that showed "documents", "experience documents" and "certification
/// documents" was really filtering the same pile, and three lists meant three
/// chances for one of them to be forgotten in a merge.
enum DocumentCategory {
  general,
  experience,
  certification;

  String toJson() => name;

  static DocumentCategory fromJson(dynamic v) => DocumentCategory.values
      .firstWhere((e) => e.name == v?.toString(),
          orElse: () => DocumentCategory.general);
}

/// A file the candidate attached to their profile.
class ProfileDocument {
  const ProfileDocument({
    required this.name,
    required this.url,
    this.contentType = '',
    this.category = DocumentCategory.general,
    this.uploadedAt,
  });

  final String name;
  final String url;
  final String contentType;
  final DocumentCategory category;
  final DateTime? uploadedAt;

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'contentType': contentType,
        'category': category.toJson(),
        'uploadedAt':
            uploadedAt == null ? null : Timestamp.fromDate(uploadedAt!),
      };

  factory ProfileDocument.fromJson(Map<String, dynamic> j) {
    final ts = j['uploadedAt'];
    return ProfileDocument(
      name: (j['name'] ?? '').toString(),
      url: (j['url'] ?? '').toString(),
      contentType: (j['contentType'] ?? j['type'] ?? '').toString(),
      category: DocumentCategory.fromJson(j['category']),
      uploadedAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.tryParse(ts?.toString() ?? ''),
    );
  }

  ProfileDocument copyWith({DocumentCategory? category}) => ProfileDocument(
        name: name,
        url: url,
        contentType: contentType,
        category: category ?? this.category,
        uploadedAt: uploadedAt,
      );
}

/// Role-specific attributes, projected from the active template's `mapsTo`
/// paths. Everything is optional: a software-engineering template fills
/// [technicalCompetencies] and [toolsAndSystems] and leaves the aviation keys
/// untouched, and vice versa.
class RoleSpecificData {
  const RoleSpecificData({
    this.licensesAndRatings = const [],
    this.experienceMetrics = const {},
    this.aircraftTypes = const [],
    this.technicalCompetencies = const [],
    this.toolsAndSystems = const [],
    this.attributes = const {},
  });

  final List<LicenseEntry> licensesAndRatings;

  /// `flightHoursOrExperienceMetrics` — numeric metrics keyed by field id
  /// (total time, PIC hours, years in trade, …).
  final Map<String, num> experienceMetrics;

  /// `typeRatingsOrAircraftTypes`.
  final List<String> aircraftTypes;
  final List<String> technicalCompetencies;
  final List<String> toolsAndSystems;

  /// Every other templated answer, keyed by question id. Kept so a template can
  /// grow new fields without a schema migration.
  final Map<String, dynamic> attributes;

  bool get isEmpty =>
      licensesAndRatings.isEmpty &&
      experienceMetrics.isEmpty &&
      aircraftTypes.isEmpty &&
      technicalCompetencies.isEmpty &&
      toolsAndSystems.isEmpty &&
      attributes.isEmpty;

  Map<String, dynamic> toJson() => {
        'licensesAndRatings':
            licensesAndRatings.map((e) => e.toJson()).toList(),
        'flightHoursOrExperienceMetrics': experienceMetrics,
        'typeRatingsOrAircraftTypes': aircraftTypes,
        'technicalCompetencies': technicalCompetencies,
        'toolsAndSystems': toolsAndSystems,
        'attributes': attributes,
      };

  factory RoleSpecificData.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const RoleSpecificData();
    return RoleSpecificData(
      licensesAndRatings: (j['licensesAndRatings'] as List?)
              ?.whereType<Map>()
              .map((m) => LicenseEntry.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      experienceMetrics: _numMap(j['flightHoursOrExperienceMetrics']),
      aircraftTypes: _stringList(j['typeRatingsOrAircraftTypes']),
      technicalCompetencies: _stringList(j['technicalCompetencies']),
      toolsAndSystems: _stringList(j['toolsAndSystems']),
      attributes: j['attributes'] is Map
          ? Map<String, dynamic>.from(j['attributes'])
          : const {},
    );
  }
}

/// The candidate document written by onboarding and read by the profile
/// manager, the dashboard timeline and recruiter search.
class CandidateProfile {
  const CandidateProfile({
    required this.uid,
    this.targetRole = TargetRole.empty,
    this.onboardingStatus = OnboardingStatus.draft,
    this.lastUpdated,
    this.personalInfo = const PersonalInfo(),
    this.roleSpecificData = const RoleSpecificData(),
    this.experience = const [],
    this.education = const [],
    this.certifications = const [],
    this.answers = const {},
    this.completedSections = const [],
    this.cvSourceFile,
    this.extractionConfidence,
    this.professionalStatus = '',
    this.expectedRetirementDate = '',
    this.publications = const [],
    this.awards = const [],
    this.references = const [],
    this.documents = const [],
  });

  final String uid;
  final TargetRole targetRole;
  final OnboardingStatus onboardingStatus;
  final DateTime? lastUpdated;
  final PersonalInfo personalInfo;
  final RoleSpecificData roleSpecificData;
  final List<ExperienceEntry> experience;
  final List<EducationEntry> education;
  final List<CertificationEntry> certifications;

  /// Raw answer map keyed by question id — the form's own source of truth,
  /// kept alongside the projected sections so a resumed draft rehydrates
  /// every control exactly as the candidate left it.
  final Map<String, dynamic> answers;

  /// Section names the candidate has visited and validated.
  final List<String> completedSections;

  /// Filename of the CV the draft was pre-filled from, if any.
  final String? cvSourceFile;

  /// 0–1 confidence the extractor reported for the prefill.
  final double? extractionConfidence;

  /// Serving / retired / civilian, and when service ends. Both matter to
  /// recruiters screening ex-military aircrew, and neither is a template
  /// question — every role asks them.
  final String professionalStatus;
  final String expectedRetirementDate;

  final List<String> publications;
  final List<String> awards;
  final List<String> references;

  /// Every uploaded file, tagged by [DocumentCategory].
  final List<ProfileDocument> documents;

  bool get isComplete => onboardingStatus == OnboardingStatus.completed;

  /// Documents filed under [category] — what the experience and certification
  /// panels render.
  List<ProfileDocument> documentsIn(DocumentCategory category) =>
      documents.where((d) => d.category == category).toList();

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'targetRole': targetRole.toJson(),
        'onboardingStatus': onboardingStatus.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'personalInfo': personalInfo.toJson(),
        'roleSpecificData': roleSpecificData.toJson(),
        'experience': experience.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'certifications': certifications.map((e) => e.toJson()).toList(),
        'answers': answers,
        'completedSections': completedSections,
        if (cvSourceFile != null) 'cvSourceFile': cvSourceFile,
        if (extractionConfidence != null)
          'extractionConfidence': extractionConfidence,
        'professionalStatus': professionalStatus,
        'expectedRetirementDate': expectedRetirementDate,
        'publications': publications,
        'awards': awards,
        'references': references,
        'documents': documents.map((d) => d.toJson()).toList(),
      };

  factory CandidateProfile.fromJson(String uid, Map<String, dynamic> j) {
    return CandidateProfile(
      uid: uid,
      targetRole: TargetRole.fromJson(
          j['targetRole'] is Map ? Map<String, dynamic>.from(j['targetRole']) : null),
      onboardingStatus: OnboardingStatus.fromJson(j['onboardingStatus']),
      lastUpdated: j['lastUpdated'] is Timestamp
          ? (j['lastUpdated'] as Timestamp).toDate()
          : DateTime.tryParse(j['lastUpdated']?.toString() ?? ''),
      personalInfo: PersonalInfo.fromJson(j['personalInfo'] is Map
          ? Map<String, dynamic>.from(j['personalInfo'])
          : null),
      roleSpecificData: RoleSpecificData.fromJson(j['roleSpecificData'] is Map
          ? Map<String, dynamic>.from(j['roleSpecificData'])
          : null),
      experience: (j['experience'] as List?)
              ?.whereType<Map>()
              .map((m) => ExperienceEntry.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      education: (j['education'] as List?)
              ?.whereType<Map>()
              .map((m) => EducationEntry.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      certifications: (j['certifications'] as List?)
              ?.whereType<Map>()
              .map((m) =>
                  CertificationEntry.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      answers:
          j['answers'] is Map ? Map<String, dynamic>.from(j['answers']) : const {},
      completedSections: _stringList(j['completedSections']),
      cvSourceFile: j['cvSourceFile']?.toString(),
      extractionConfidence: j['extractionConfidence'] is num
          ? (j['extractionConfidence'] as num).toDouble()
          : null,
      professionalStatus: (j['professionalStatus'] ?? '').toString(),
      expectedRetirementDate: (j['expectedRetirementDate'] ?? '').toString(),
      publications: _stringList(j['publications']),
      awards: _stringList(j['awards']),
      references: _stringList(j['references']),
      documents: (j['documents'] as List?)
              ?.whereType<Map>()
              .map((m) => ProfileDocument.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
    );
  }

  CandidateProfile copyWith({
    TargetRole? targetRole,
    OnboardingStatus? onboardingStatus,
    PersonalInfo? personalInfo,
    RoleSpecificData? roleSpecificData,
    List<ExperienceEntry>? experience,
    List<EducationEntry>? education,
    List<CertificationEntry>? certifications,
    Map<String, dynamic>? answers,
    List<String>? completedSections,
    String? cvSourceFile,
    double? extractionConfidence,
    String? professionalStatus,
    String? expectedRetirementDate,
    List<String>? publications,
    List<String>? awards,
    List<String>? references,
    List<ProfileDocument>? documents,
  }) =>
      CandidateProfile(
        uid: uid,
        targetRole: targetRole ?? this.targetRole,
        onboardingStatus: onboardingStatus ?? this.onboardingStatus,
        lastUpdated: lastUpdated,
        personalInfo: personalInfo ?? this.personalInfo,
        roleSpecificData: roleSpecificData ?? this.roleSpecificData,
        experience: experience ?? this.experience,
        education: education ?? this.education,
        certifications: certifications ?? this.certifications,
        answers: answers ?? this.answers,
        completedSections: completedSections ?? this.completedSections,
        cvSourceFile: cvSourceFile ?? this.cvSourceFile,
        extractionConfidence: extractionConfidence ?? this.extractionConfidence,
        professionalStatus: professionalStatus ?? this.professionalStatus,
        expectedRetirementDate:
            expectedRetirementDate ?? this.expectedRetirementDate,
        publications: publications ?? this.publications,
        awards: awards ?? this.awards,
        references: references ?? this.references,
        documents: documents ?? this.documents,
      );
}

// ── Shared coercion helpers ─────────────────────────────────────────────────

List<String> _stringList(dynamic v) {
  if (v is List) {
    return v
        .map((e) => e?.toString() ?? '')
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }
  if (v is String && v.trim().isNotEmpty) {
    return v
        .split(RegExp(r'[\n,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return const [];
}

Map<String, num> _numMap(dynamic v) {
  if (v is! Map) return const {};
  final out = <String, num>{};
  v.forEach((k, value) {
    final n = value is num ? value : num.tryParse(value?.toString() ?? '');
    if (n != null) out[k.toString()] = n;
  });
  return out;
}

int? _year(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  final match = RegExp(r'(19|20)\d{2}').allMatches(v?.toString() ?? '');
  if (match.isEmpty) return null;
  return int.tryParse(match.last.group(0)!);
}
