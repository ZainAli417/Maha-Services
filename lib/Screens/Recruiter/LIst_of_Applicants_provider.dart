import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/onboarding/models/candidate_profile.dart';
import '../../core/onboarding/role_profile_snapshot.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _str(dynamic v, [String fb = '']) => v?.toString() ?? fb;
List<String> _strList(dynamic v) => v is List ? v.map(_str).toList() : const [];
DateTime _parseTs(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

// ─── JobData ──────────────────────────────────────────────────────────────────

class JobData {
  const JobData({
    required this.jobId,
    required this.title,
    required this.company,
    required this.location,
    required this.jobType,
    required this.workType,
    this.salary,
    this.experience,
    required this.requiredSkills,
  });

  final String jobId, title, company, location, jobType, workType;
  final double? salary;
  final dynamic experience;
  final List<String> requiredSkills;
}

/// A candidate's online assessment, as the recruiter is allowed to see it.
///
/// Two documents feed this. `assessment` is written the moment an invitation
/// goes out and tracks where the candidate is; `test_score` appears only when
/// an admin releases the batch. Until then the recruiter sees progress and no
/// number, which is the point — a half-finished score is not a score.
class AssessmentSummary {
  const AssessmentSummary({
    this.status = '',
    this.percentage,
    this.correct,
    this.total = 0,
    this.verdict = '',
    this.passMark = 0,
    this.rank,
    this.rankOf = 0,
    this.perTopic = const {},
    this.tabSwitches = 0,
    this.resumes = 0,
    this.submittedAt,
    this.released = false,
  });

  /// invited | accepted | in_progress | submitted | expired, or empty when the
  /// candidate has never been invited.
  final String status;

  final int? percentage;
  final int? correct;
  final int total;

  /// pass | fail | not_taken, set by the admin's pass mark at release time.
  final String verdict;
  final int passMark;

  /// Position within this batch. Ties share a rank.
  final int? rank;
  final int rankOf;

  final Map<String, ({int correct, int total})> perTopic;
  final int tabSwitches;
  final int resumes;
  final DateTime? submittedAt;

  /// True once an admin has sent the batch's scores back to the recruiter.
  final bool released;

  static const none = AssessmentSummary();

  bool get invited => status.isNotEmpty;
  bool get hasScore => released && percentage != null;
  bool get inProgress => status == 'in_progress' || status == 'accepted';
  bool get expired => status == 'expired';

  /// One short line for a table cell.
  String get label {
    if (hasScore) return '$correct/$total';
    return switch (status) {
      '' => 'Not invited',
      'invited' => 'Invited',
      'accepted' => 'Accepted',
      'in_progress' => 'In progress',
      'submitted' => 'Awaiting release',
      'expired' => 'Expired',
      _ => status,
    };
  }

  factory AssessmentSummary.fromApplication(Map<String, dynamic> data) {
    final live = data['assessment'];
    final released = data['test_score'];

    if (released is Map) {
      final r = Map<String, dynamic>.from(released);
      return AssessmentSummary(
        status: (r['status'] ?? '').toString(),
        percentage: (r['percentage'] as num?)?.toInt(),
        correct: (r['correct'] as num?)?.toInt(),
        total: (r['total'] as num?)?.toInt() ?? 0,
        verdict: (r['verdict'] ?? '').toString(),
        passMark: (r['passMark'] as num?)?.toInt() ?? 0,
        rank: (r['rank'] as num?)?.toInt(),
        rankOf: (r['rankOf'] as num?)?.toInt() ?? 0,
        perTopic: _topics(r['perTopic']),
        tabSwitches: _intIn(r['integrity'], 'tabSwitches'),
        resumes: _intIn(r['integrity'], 'resumes'),
        submittedAt: (r['submittedAt'] as num?) == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((r['submittedAt'] as num).toInt()),
        released: true,
      );
    }

    if (live is Map) {
      final l = Map<String, dynamic>.from(live);
      return AssessmentSummary(status: (l['status'] ?? '').toString());
    }
    return AssessmentSummary.none;
  }

  static Map<String, ({int correct, int total})> _topics(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, ({int correct, int total})>{};
    raw.forEach((key, value) {
      if (value is Map) {
        out[key.toString()] = (
          correct: (value['correct'] as num?)?.toInt() ?? 0,
          total: (value['total'] as num?)?.toInt() ?? 0,
        );
      }
    });
    return out;
  }

  static int _intIn(dynamic map, String key) =>
      map is Map ? ((map[key] as num?)?.toInt() ?? 0) : 0;
}

/// Which measurement a candidate's headline experience figure comes from.
///
/// Carried alongside the number so a screen can say what it is showing. The
/// bug this exists to prevent printed a count of previous jobs as "2y exp".
enum ExperienceBasis {
  /// Logged flight time. Aircrew only.
  flightHours,

  /// Years the candidate entered on a role template that asked for them.
  declaredYears,

  /// Years worked out from the dated roles on file.
  serviceHistory,

  /// Nothing but a number of positions — a count, not a duration.
  roleCount,
}

// ─── ApplicantRecord ──────────────────────────────────────────────────────────

class ApplicantRecord {
  ApplicantRecord._({
    required this.userId,
    required this.jobId,
    required this.status,
    required this.appliedAt,
    required this.profileSnapshot,
    required this.docId,
    required this.reference,
    required this.matchScore,
    required this.assessment,
    required this.sentToAdmin,
    required this.searchIndex,
    this.jobData,
    // Personal
    required this.name,
    required this.email,
    required this.secondaryEmail,
    required this.phone,
    required this.nationality,
    required this.pictureUrl,
    required this.location,
    required this.dob,
    required this.objectives,
    required this.summary,
    // Professional
    required this.education,
    required this.university,
    required this.educationDuration,
    required this.cgpa,
    required this.currentRole,
    required this.company,
    required this.professionalStatus,
    required this.retirementDate,
    // Collections
    required this.skills,
    required this.socialLinks,
    required this.experiences,
    required this.educations,
    required this.certifications,
    required this.publications,
    required this.awards,
    required this.documents,
    required this.experienceDocuments,
    required this.certificationDocuments,
    required this.roleProfile,
  });

  // Identity
  final String userId, jobId, docId, status, searchIndex;
  final DateTime appliedAt;
  final DocumentReference reference;
  final Map<String, dynamic> profileSnapshot, matchScore;
  final AssessmentSummary assessment;
  final bool sentToAdmin;
  final JobData? jobData;

  // Personal
  final String name,
      email,
      secondaryEmail,
      phone,
      nationality,
      pictureUrl,
      location,
      dob,
      objectives,
      summary;

  // Professional
  final String education,
      university,
      educationDuration,
      cgpa,
      currentRole,
      company,
      professionalStatus,
      retirementDate;

  // Collections
  final List<String> skills, socialLinks, publications, awards;
  final List<dynamic> documents;
  final List<Map<String, dynamic>> experiences,
      educations,
      experienceDocuments,
      certificationDocuments;
  final List<Map<String, String>> certifications;

  /// Role-template answers captured when the candidate applied. Empty for
  /// applications made before the template engine shipped.
  final RoleProfileSnapshot roleProfile;

  String get professionalSummary => summary;

  /// The role the candidate applied as, for list rows and filters.
  String get targetRole => roleProfile.roleTitle;

  /// Aircraft the candidate has flown or maintained.
  List<String> get aircraftTypes => roleProfile.aircraftTypes;

  /// Licence and rating titles — ATPL, Part-66 B1.1, military wings.
  List<String> get licences =>
      roleProfile.licences.map((l) => l.title).where((t) => t.isNotEmpty).toList();

  /// Numeric metrics keyed by id: totalTime, pic, tradeYears, and so on.
  Map<String, num> get metrics => roleProfile.metrics;

  /// Total flight hours, or null when this candidate does not fly.
  ///
  /// Null and zero mean different things here. A loadmaster has no hours
  /// because hours are not part of the job; showing "0 hours" would read as a
  /// pilot who has never flown.
  num? get flightHours => MetricLabels.flightHours(metrics);

  /// Years the candidate stated themselves, on a role template that asked.
  num? get declaredYears => MetricLabels.years(metrics);

  /// Years covered by the dated roles on file.
  ///
  /// Read off the employment history rather than asked for, because most role
  /// templates never ask: a technician with postings from 2008 to 2016 has
  /// eight years of service whether or not any form had a box for it.
  num? get serviceYears => serviceYearsFrom(experiences);

  /// Years of experience, from whichever source has it.
  ///
  /// The candidate's own figure wins — it is their statement about their own
  /// career, and it may cover service this list does not. The dated history
  /// fills in when nobody asked them. Both are years, so the filters and the
  /// sort treat them alike; [experienceBasis] says which one a given number
  /// came from, for the places that need to show their working.
  num? get yearsOfExperience => declaredYears ?? serviceYears;

  /// What the headline experience figure is actually measuring.
  ExperienceBasis get experienceBasis {
    if (flightHours != null) return ExperienceBasis.flightHours;
    if (declaredYears != null) return ExperienceBasis.declaredYears;
    if (serviceYears != null) return ExperienceBasis.serviceHistory;
    return ExperienceBasis.roleCount;
  }

  /// Total years spanned by dated roles, counting overlapping postings once.
  ///
  /// Two concurrent appointments are two lines on a CV and one stretch of a
  /// career; adding them would hand a recruiter sixteen years for eight.
  /// Returns null when nothing is dated, rather than 0 — "no dates on file"
  /// and "no experience" are not the same claim.
  static num? serviceYearsFrom(List<Map<String, dynamic>> experiences) {
    final now = DateTime.now();
    final spans = <({DateTime start, DateTime end})>[];

    for (final e in experiences) {
      final start = _month(e['startDate']);
      if (start == null) continue;
      final isCurrent = e['isCurrent'] == true;
      final end = isCurrent ? now : (_month(e['endDate']) ?? now);
      if (end.isBefore(start)) continue;
      spans.add((start: start, end: end));
    }
    if (spans.isEmpty) return null;

    spans.sort((a, b) => a.start.compareTo(b.start));
    var total = Duration.zero;
    var blockStart = spans.first.start;
    var blockEnd = spans.first.end;

    for (final span in spans.skip(1)) {
      if (span.start.isAfter(blockEnd)) {
        total += blockEnd.difference(blockStart);
        blockStart = span.start;
        blockEnd = span.end;
      } else if (span.end.isAfter(blockEnd)) {
        blockEnd = span.end;
      }
    }
    total += blockEnd.difference(blockStart);

    final years = total.inDays / 365.25;
    // Under six months is a posting, not "years of experience"; rounding it up
    // to 1 would overstate the candidate.
    return years < 0.5 ? null : years;
  }

  /// Parses the month formats this data actually contains.
  ///
  /// The onboarding form writes MM/YYYY, the CV extractor and the imported
  /// profiles write YYYY-MM, and a few carry a bare year. One field, several
  /// spellings — so the parser reads all of them and refuses anything else
  /// rather than guessing.
  static DateTime? _month(dynamic raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return null;

    final iso = RegExp(r'^(\d{4})-(\d{1,2})').firstMatch(text);
    if (iso != null) {
      final month = int.parse(iso.group(2)!);
      if (month < 1 || month > 12) return null;
      return DateTime(int.parse(iso.group(1)!), month);
    }

    final slash = RegExp(r'^(\d{1,2})[/-](\d{4})$').firstMatch(text);
    if (slash != null) {
      final month = int.parse(slash.group(1)!);
      if (month < 1 || month > 12) return null;
      return DateTime(int.parse(slash.group(2)!), month);
    }

    final year = RegExp(r'^(\d{4})$').firstMatch(text);
    if (year != null) return DateTime(int.parse(year.group(1)!));

    return null;
  }

  /// How many previous positions the candidate listed.
  ///
  /// A count of jobs, not a duration.
  ///
  /// This replaced a field called `experienceYears` that held exactly this
  /// number, so two jobs rendered as "2y exp" everywhere it was shown.
  int get roleCount => experiences.length;

  /// Country alone, split out of the "City, Country" display string so a
  /// region filter does not fragment into one entry per city.
  String get country {
    final parts = location.split(',');
    return parts.isEmpty ? '' : parts.last.trim();
  }

  /// Degrees held, for an education filter that means "level" rather than the
  /// subject the old one actually matched on.
  List<String> get degrees => [
        for (final e in educations)
          if ((e['degree'] ?? '').toString().trim().isNotEmpty)
            (e['degree'] as String).trim(),
      ];

  /// The AI match score, or null when nobody has run the analysis.
  int? get aiScore {
    final v = matchScore['overallScore'];
    return v is num ? v.toInt() : null;
  }

  /// This candidate as the filter sees them.
  FilterableCandidate get filterView => (
        searchIndex: searchIndex,
        status: status,
        jobTitle: jobData?.title ?? '',
        location: location,
        country: country,
        education: education,
        nationality: nationality,
        professionalStatus: professionalStatus,
        targetRole: targetRole,
        retirementDate: retirementDate,
        sentToAdmin: sentToAdmin,
        aircraftTypes: aircraftTypes,
        licences: licences,
        degrees: degrees,
        skills: skills,
        flightHours: flightHours,
        yearsOfExperience: yearsOfExperience,
        hasCertifications: certifications.isNotEmpty,
        hasPublications: publications.isNotEmpty,
        hasAwards: awards.isNotEmpty,
        appliedAt: appliedAt,
        aiScore: aiScore,
        testStatus: assessment.status,
        testPercentage: assessment.hasScore ? assessment.percentage : null,
        testVerdict: assessment.hasScore ? assessment.verdict : '',
      );

  /// Headline metric for the list row — total flight hours for aircrew, years
  /// of experience otherwise.
  ({String label, String value})? get headlineMetric {
    final metrics = roleProfile.metrics;
    for (final key in MetricLabels.priority) {
      final v = metrics[key];
      if (v != null) {
        return (label: MetricLabels.of(key), value: MetricLabels.format(v));
      }
    }
    return null;
  }

  factory ApplicantRecord.fromSnapshot(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    JobData? jobData,
  ) {
    final userId = doc.reference.parent.parent?.id ?? 'unknown_user';

    final ps = data['profileSnapshot'] is Map
        ? Map<String, dynamic>.from(data['profileSnapshot'] as Map)
        : <String, dynamic>{};

    // The snapshot carries a redacted copy of the candidate's profile — see
    // JobApplicationsProvider.withoutContactDetails. Contact fields are absent
    // by construction, so the empty strings below are the truth, not a parse
    // failure.
    final profile = CandidateProfile.fromJson(
      userId,
      ps['candidate_profile'] is Map
          ? Map<String, dynamic>.from(ps['candidate_profile'] as Map)
          : const {},
    );
    final personal = profile.personalInfo;

    final experiences = [
      for (final x in profile.experience)
        {
          'organization': x.company,
          'role': x.title,
          'location': x.location,
          'duration': _range(x.startDate, x.endDate, x.isCurrent),
          'startDate': x.startDate,
          'endDate': x.endDate ?? '',
          'isCurrent': x.isCurrent,
          'duties': x.responsibilities.join('\n'),
          'text': x.responsibilities.join('\n'),
        },
    ];

    final educations = [
      for (final e in profile.education)
        {
          'institutionName': e.institution,
          'degree': e.degree,
          'majorSubjects': e.fieldOfStudy,
          'duration': e.graduationYear?.toString() ?? '',
          'marksOrCgpa': e.grade,
        },
    ];

    // Licences and ratings sit beside certifications for a recruiter: both
    // answer "what is this person qualified to do".
    final certifications = <Map<String, String>>[
      for (final c in profile.certifications)
        if (c.name.isNotEmpty)
          {
            'organization': c.issuer,
            'name': c.name,
            'issueDate': c.issueDate,
            'expiryDate': c.expiryDate ?? '',
          },
      for (final l in profile.roleSpecificData.licensesAndRatings)
        if (l.title.isNotEmpty)
          {
            'organization': l.issuingAuthority,
            'name': l.title,
            'issueDate': '',
            'expiryDate': l.expiryDate ?? '',
          },
    ];

    List<Map<String, dynamic>> docsIn(DocumentCategory category) => [
          for (final d in profile.documentsIn(category))
            {
              'name': d.name,
              'url': d.url,
              'type': d.contentType,
              'uploadedAt': d.uploadedAt?.toIso8601String() ?? '',
            },
        ];

    final firstEdu = educations.isNotEmpty ? educations.first : const {};
    final firstExp = experiences.isNotEmpty ? experiences.first : const {};

    // Free-form skills plus whatever the role template captured — a recruiter
    // searching "A320" should hit it whichever field it landed in.
    final skills = <String>{
      ...personal.skills,
      ...profile.roleSpecificData.technicalCompetencies,
      ...profile.roleSpecificData.toolsAndSystems,
    }.toList();

    final roleProfile = RoleProfileSnapshot.fromJson(
      ps['role_profile'] is Map
          ? Map<String, dynamic>.from(ps['role_profile'] as Map)
          : null,
    );

    final name = personal.fullName.isEmpty ? 'Unknown' : personal.fullName;

    return ApplicantRecord._(
      userId: userId,
      jobId: _str(data['jobId']),
      status: _str(data['status'], 'pending'),
      appliedAt: _parseTs(data['appliedAt']),
      profileSnapshot: ps,
      docId: doc.id,
      reference: doc.reference,
      jobData: jobData,
      matchScore: data['match_score'] is Map
          ? Map<String, dynamic>.from(data['match_score'] as Map)
          : {},
      assessment: AssessmentSummary.fromApplication(data),
      sentToAdmin: data['sentToAdmin'] == true,
      name: name,
      email: personal.email,
      secondaryEmail: personal.secondaryEmail,
      phone: personal.phone,
      nationality: personal.nationality,
      pictureUrl: personal.profilePicUrl,
      location: personal.location.display,
      dob: personal.dateOfBirth,
      objectives: personal.objectives,
      summary: personal.summary,
      education: _str(firstEdu['majorSubjects']),
      university: _str(firstEdu['institutionName']),
      educationDuration: _str(firstEdu['duration']),
      cgpa: _str(firstEdu['marksOrCgpa']),
      currentRole: _str(firstExp['role']),
      company: _str(firstExp['organization']),
      professionalStatus: profile.professionalStatus,
      retirementDate: profile.expectedRetirementDate,
      skills: skills,
      socialLinks: personal.socialLinks,
      experiences: experiences,
      educations: educations,
      certifications: certifications,
      publications: profile.publications,
      awards: profile.awards,
      documents: docsIn(DocumentCategory.general),
      experienceDocuments: docsIn(DocumentCategory.experience),
      certificationDocuments: docsIn(DocumentCategory.certification),
      roleProfile: roleProfile,
      // Role title, aircraft types and licences join the search index so a
      // recruiter can find "A320" or "ATPL" from the applicant list. Contact
      // fields are deliberately absent — they are empty here anyway, and an
      // index is a copy like any other.
      searchIndex:
          '$name ${personal.location.display} ${skills.join(' ')} '
                  '${_str(firstExp['organization'])} ${_str(firstExp['role'])} '
                  '${roleProfile.roleTitle} '
                  '${roleProfile.aircraftTypes.join(' ')} '
                  '${roleProfile.licences.map((l) => l.title).join(' ')} '
                  '${roleProfile.competencies.join(' ')}'
              .toLowerCase(),
    );
  }

  static String _range(String start, String? end, bool isCurrent) {
    final finish = isCurrent ? 'Present' : (end ?? '');
    if (start.isEmpty && finish.isEmpty) return '';
    return '$start - $finish';
  }

  ApplicantRecord copyWith({
    String? status,
    JobData? jobData,
    bool? sentToAdmin,
  }) => ApplicantRecord._(
    userId: userId,
    jobId: jobId,
    status: status ?? this.status,
    appliedAt: appliedAt,
    profileSnapshot: profileSnapshot,
    docId: docId,
    reference: reference,
    jobData: jobData ?? this.jobData,
    matchScore: matchScore,
    assessment: assessment,
    sentToAdmin: sentToAdmin ?? this.sentToAdmin,
    searchIndex: searchIndex,
    name: name,
    email: email,
    secondaryEmail: secondaryEmail,
    phone: phone,
    nationality: nationality,
    pictureUrl: pictureUrl,
    location: location,
    dob: dob,
    objectives: objectives,
    summary: summary,
    education: education,
    university: university,
    educationDuration: educationDuration,
    cgpa: cgpa,
    currentRole: currentRole,
    company: company,
    professionalStatus: professionalStatus,
    retirementDate: retirementDate,
    skills: skills,
    socialLinks: socialLinks,
    experiences: experiences,
    educations: educations,
    certifications: certifications,
    publications: publications,
    awards: awards,
    documents: documents,
    experienceDocuments: experienceDocuments,
    certificationDocuments: certificationDocuments,
    roleProfile: roleProfile,
  );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

class ApplicantsProvider with ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── State ──
  bool isLoading = true;
  String? error;
  String? _currentJobId;
  String? _initializedUid;
  bool _isInitializing = false;

  StreamSubscription<QuerySnapshot>? _subscription;
  StreamSubscription<QuerySnapshot>? _requestsSubscription;
  Timer? _searchDebounce;

  // ── Data ──
  List<ApplicantRecord> _all = [];
  List<ApplicantRecord> _filtered = [];
  List<Map<String, dynamic>> _recruiterRequests = [];

  // ── Caches ──
  final Map<String, JobData?> _jobCache = {};
  final Map<String, ApplicantRecord> _recordCache = {};
  final Map<String, int> _hashCache = {};

  // ── Selection ──
  final Set<String> selectedApplicantIds = {};

  // ── Filters ──
  String searchQuery = '';
  String statusFilter = 'All';
  String experienceFilter = 'All';
  String locationFilter = 'All';
  String educationFilter = 'All';
  String jobFilter = 'All';
  String nationalityFilter = 'All';
  String professionalStatusFilter = 'All';
  String retirementStatusFilter = 'All';
  List<String> skillsFilter = [];
  DateTimeRange? appliedDateRange;
  bool hasCertifications = false;
  bool hasPublications = false;
  bool hasAwards = false;
  String sortBy = 'applied_desc';

  // -- Role-profile filters --
  //
  // Where the substance now lives. Licences, aircraft and hours are what a
  // recruiter actually screens on; skills are self-declared and a job title is
  // just a label.
  Set<String> roleFilter = {};
  Set<String> aircraftFilter = {};
  Set<String> licenceFilter = {};
  Set<String> degreeFilter = {};
  String countryFilter = 'All';

  /// Minimum total flight hours. Zero means no lower bound.
  ///
  /// Separate from [minYears] on purpose: pooling them meant "at least 500"
  /// matched 500 hours and 500 years alike.
  num minFlightHours = 0;
  /// 'All' | 'Not invited' | 'Invited' | 'In progress' | 'Completed' |
  /// 'Passed' | 'Failed'
  String testStage = 'All';
  num minAiScore = 0;
  num minTestScore = 0;

  /// Minimum years of service or trade experience. Zero means no lower bound.
  num minYears = 0;

  /// Whether a multi-select must match every chosen value or just one of them.
  ///
  /// "Any" is the right default: a recruiter picking A320 and B737 usually
  /// means either, not both. "All" exists for when they do mean both, which is
  /// why it is a toggle rather than a hardcoded choice.
  bool matchAll = false;

  /// Only candidates not yet sent to the admin.
  bool unreviewedOnly = false;

  // -- Available filter options --
  final Set<String> availableLocations = {};
  final Set<String> availableEducations = {};
  final Set<String> availableJobs = {};
  final Set<String> availableSkills = {};
  final Set<String> availableNationalities = {};
  final Set<String> availableRoles = {};
  final Set<String> availableAircraft = {};
  final Set<String> availableLicences = {};
  final Set<String> availableDegrees = {};
  final Set<String> availableCountries = {};

  /// Largest values across the pool, so each slider has a real ceiling rather
  /// than a guessed one.
  num maxFlightHoursSeen = 0;
  num maxYearsSeen = 0;

  // ── Getters ──
  List<ApplicantRecord> get applicants => _filtered;
  List<ApplicantRecord> get allApplicants => _all;
  List<Map<String, dynamic>> get recruiterRequests => _recruiterRequests;

  /// The resend rules, over whatever requests are currently loaded.
  ResendPolicy get resendPolicy => ResendPolicy(_recruiterRequests);

  Set<String> get resendableCandidateIds => resendPolicy.reopenedCandidateIds;

  Map<String, dynamic>? releasedRequestFor(String candidateUid) =>
      resendPolicy.releasedRequestFor(candidateUid);

  /// True when this candidate can be included in a follow-up request.
  bool canResend(ApplicantRecord a) =>
      a.sentToAdmin && resendableCandidateIds.contains(a.userId);

  /// True when the checkbox should be live for this candidate.
  bool isSelectable(ApplicantRecord a) => !a.sentToAdmin || canResend(a);

  /// The round the next request from the current selection would be.
  int get pendingRound => resendPolicy.roundFor(selectedApplicantIds);

  /// True once the recruiter has advanced this candidate past the assessment,
  /// which is the point an interview becomes theirs to arrange.
  bool canArrangeInterview(ApplicantRecord a) =>
      resendPolicy.interviewReadyCandidateIds.contains(a.userId);

  /// The request a candidate was advanced in, for the interview to hang off.
  Map<String, dynamic>? advancedRequestFor(String uid) =>
      resendPolicy.advancedRequestFor(uid);

  /// Selected candidates who can be given an interview slot right now.
  List<ApplicantRecord> get selectedForInterview => _all
      .where((a) =>
          selectedApplicantIds.contains(a.userId) && canArrangeInterview(a))
      .toList();

  int get totalApplicants => _all.length;
  int get filteredCount => _filtered.length;
  int get pendingCount => _all.where((a) => a.status == 'pending').length;
  int get acceptedCount => _all.where((a) => a.status == 'accepted').length;
  int get rejectedCount => _all.where((a) => a.status == 'rejected').length;
  int get shortlistCount => _all.where((a) => a.status == 'shortlist').length;

  List<ApplicantRecord> get shortlistApplicants =>
      _all.where((a) => a.status.toLowerCase() == 'shortlist').toList();

  /// Everyone shortlisted for [jobId], before filters.
  List<ApplicantRecord> getShortlistForJob(String? jobId) =>
      (jobId == null || jobId.isEmpty)
      ? shortlistApplicants
      : _all
            .where(
              (a) => a.status.toLowerCase() == 'shortlist' && a.jobId == jobId,
            )
            .toList();

  /// Runs the active filters over an arbitrary list.
  ///
  /// The shortlist screen shows a subset — the people already shortlisted for
  /// one job — and filtering there has to narrow that subset, not the whole
  /// pool. Passing the base list in keeps one filter definition serving both
  /// screens instead of each growing its own.
  List<ApplicantRecord> applyFiltersTo(List<ApplicantRecord> base) {
    final spec = _currentSpec();
    final out = base.where((a) => spec.matches(a.filterView)).toList();
    return _sortList(out);
  }

  /// How many of [base] would survive a draft filter set, without applying it.
  int previewCountIn(
    List<ApplicantRecord> base, {
    Set<String>? roles,
    Set<String>? aircraft,
    Set<String>? licences,
    Set<String>? degrees,
    List<String>? skills,
    String? status,
    String? job,
    String? country,
    String? location,
    String? education,
    String? nationality,
    String? professionalStatus,
    String? retirement,
    num? minHours,
    num? minYearsValue,
    String? testStageValue,
    num? minAi,
    num? minTest,
    bool? certs,
    bool? pubs,
    bool? awards,
    bool? unreviewed,
    bool? all,
    DateTimeRange? dateRange,
  }) {
    final spec = _draftSpec(
      roles: roles,
      aircraft: aircraft,
      licences: licences,
      degrees: degrees,
      skills: skills,
      status: status,
      job: job,
      country: country,
      location: location,
      education: education,
      nationality: nationality,
      professionalStatus: professionalStatus,
      retirement: retirement,
      minHours: minHours,
      minYearsValue: minYearsValue,
      testStageValue: testStageValue,
      minAi: minAi,
      minTest: minTest,
      certs: certs,
      pubs: pubs,
      awards: awards,
      unreviewed: unreviewed,
      all: all,
      dateRange: dateRange,
    );
    return base.where((a) => spec.matches(a.filterView)).length;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _requestsSubscription?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ─── Realtime Stream ──────────────────────────────────────────────────────

  void refresh({String? jobId}) {
    if (_currentJobId != jobId) {
      _currentJobId = jobId;
      _jobCache.clear();
      _recordCache.clear();
      _hashCache.clear();
      _isInitializing = false; // Allow re-init on job change
    }
    _initStreams();
  }

  void _initStreams() {
    final user = _auth.currentUser;
    if (user == null) {
      error = 'No user logged in';
      isLoading = false;
      notifyListeners();
      return;
    }

    // ✅ Request stream: restart only if user changed
    if (_initializedUid != user.uid) {
      _requestsSubscription?.cancel();
      _requestsSubscription = _db
          .collection('recruiter_requests')
          .where('recruiter_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .snapshots()
          .listen((snap) {
            _recruiterRequests = snap.docs
                .map((d) => Map<String, dynamic>.from(d.data() as Map))
                .toList();
            notifyListeners();
          });
    }

    if (_isInitializing ||
        (_initializedUid == user.uid && _subscription != null)) {
      return;
    }

    _isInitializing = true;
    _initializedUid = user.uid;
    isLoading = true;
    notifyListeners();

    _subscription?.cancel();

    // ✅ Web-friendly: limit collectionGroup query fields to avoid composite index issues
    Query query = _db
        .collectionGroup('applied_jobs')
        .where('recruiterUid', isEqualTo: user.uid);

    if (_currentJobId != null && _currentJobId!.isNotEmpty) {
      query = query.where('jobId', isEqualTo: _currentJobId);
    }
    query = query.orderBy('appliedAt', descending: true);

    _subscription = query.snapshots().listen(
      _onApplicantsSnapshot,
      onError: (e) {
        error = e.toString();
        isLoading = false;
        _isInitializing = false;
        notifyListeners();
      },
    );
  }

  Future<void> _onApplicantsSnapshot(QuerySnapshot snap) async {
    // 1. Collect uncached job IDs in one pass
    final needed = <String>{};
    for (final doc in snap.docs) {
      final jId = (doc.data() as Map)['jobId'] as String?;
      if (jId != null && !_jobCache.containsKey(jId)) needed.add(jId);
    }

    // 2. Batch-fetch jobs — parallel, web-safe
    if (needed.isNotEmpty) {
      await Future.wait(needed.map(_fetchJob));
    }

    // 3. Process docs with hash-diff caching
    bool structureChanged = false;
    final newList = <ApplicantRecord>[];

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final hash = Object.hash(doc.id, data.toString());

      if (_recordCache.containsKey(doc.id) && _hashCache[doc.id] == hash) {
        newList.add(_recordCache[doc.id]!);
      } else {
        final jId = data['jobId'] as String?;
        if (jId != null && jId.isNotEmpty) {
          final rec = ApplicantRecord.fromSnapshot(doc, data, _jobCache[jId]);
          _recordCache[doc.id] = rec;
          _hashCache[doc.id] = hash;
          newList.add(rec);
          structureChanged = true;
        }
      }
    }

    _all = newList;

    // 4. GC stale cache entries
    if (_recordCache.length > _all.length) {
      final live = _all.map((a) => a.docId).toSet();
      _recordCache.removeWhere((k, _) => !live.contains(k));
      _hashCache.removeWhere((k, _) => !live.contains(k));
      structureChanged = true;
    }

    if (structureChanged) _populateFilterOptions();
    _applyFilters(); // Always re-apply (handles sort/filter changes)

    isLoading = false;
    _isInitializing = false;
    notifyListeners();
  }

  // ─── Job Fetching ─────────────────────────────────────────────────────────

  Future<void> _fetchJob(String jobId) async {
    if (_jobCache.containsKey(jobId)) return;
    try {
      final doc = await _db.collection('Posted_jobs_public').doc(jobId).get();
      if (!doc.exists) {
        _jobCache[jobId] = null;
        return;
      }
      final data = doc.data()!;

      double? salary;
      final rawSalary = data['salary'];
      if (rawSalary is num) {
        salary = rawSalary.toDouble();
      } else if (rawSalary is String) {
        final m = RegExp(r'[\d,]+').firstMatch(rawSalary);
        salary = m != null
            ? double.tryParse(m.group(0)!.replaceAll(',', ''))
            : null;
      }

      _jobCache[jobId] = JobData(
        jobId: jobId,
        title: _str(data['title'], 'Unknown'),
        company: _str(data['company']),
        location: _str(data['location']),
        jobType: _str(data['job_type']),
        workType: _str(data['workModes']),
        salary: salary,
        experience: data['experience'],
        requiredSkills: _strList(data['required_skills']),
      );
    } catch (_) {
      _jobCache[jobId] = null;
    }
  }

  // ─── Filtering ────────────────────────────────────────────────────────────

  void _populateFilterOptions() {
    for (final set in [
      availableLocations, availableEducations, availableJobs,
      availableSkills, availableNationalities, availableRoles,
      availableAircraft, availableLicences, availableDegrees,
      availableCountries,
    ]) {
      set.clear();
    }
    maxFlightHoursSeen = 0;
    maxYearsSeen = 0;

    for (final a in _all) {
      if (a.jobData != null) availableJobs.add(a.jobData!.title);
      if (a.location.isNotEmpty) availableLocations.add(a.location);
      if (a.country.isNotEmpty) availableCountries.add(a.country);
      if (a.education.isNotEmpty) availableEducations.add(a.education);
      if (a.nationality.isNotEmpty) availableNationalities.add(a.nationality);
      if (a.targetRole.isNotEmpty) availableRoles.add(a.targetRole);
      availableSkills.addAll(a.skills);
      availableAircraft.addAll(a.aircraftTypes);
      availableLicences.addAll(a.licences);
      availableDegrees.addAll(a.degrees);
      final h = a.flightHours;
      if (h != null && h > maxFlightHoursSeen) maxFlightHoursSeen = h;
      final y = a.yearsOfExperience;
      if (y != null && y > maxYearsSeen) maxYearsSeen = y;
    }
  }

  /// The filters currently in force, as label/remove pairs.
  ///
  /// Rendered as a strip above the list. Without it a recruiter who set a
  /// filter three screens ago sees a short list and assumes that is all there
  /// is — the commonest way filtering goes wrong is silently.
  List<({String label, VoidCallback remove})> get activeFilterChips {
    final out = <({String label, VoidCallback remove})>[];

    void single(String label, String value, void Function(String) reset) {
      if (value != 'All') {
        out.add((label: '$label: $value', remove: () => reset('All')));
      }
    }

    void multi(
      String label,
      Set<String> values,
      void Function(Set<String>) set,
    ) {
      for (final v in values) {
        out.add((
          label: '$label: $v',
          remove: () => set({...values}..remove(v)),
        ));
      }
    }

    single('Status', statusFilter, updateStatusFilter);
    single('Job', jobFilter, updateJobFilter);
    single('Country', countryFilter, updateCountryFilter);
    single('Location', locationFilter, updateLocationFilter);
    single('Field', educationFilter, updateEducationFilter);
    single('Nationality', nationalityFilter, updateNationalityFilter);
    single('Service', professionalStatusFilter, updateProfessionalStatusFilter);
    single('Retiring', retirementStatusFilter, updateRetirementStatusFilter);
    single('Test', testStage, updateTestStage);

    multi('Role', roleFilter, updateRoleFilter);
    multi('Aircraft', aircraftFilter, updateAircraftFilter);
    multi('Licence', licenceFilter, updateLicenceFilter);
    multi('Degree', degreeFilter, updateDegreeFilter);

    for (final skill in skillsFilter) {
      out.add((
        label: 'Skill: $skill',
        remove: () => updateSkillsFilter([...skillsFilter]..remove(skill)),
      ));
    }

    if (minFlightHours > 0) {
      out.add((
        label: 'Min ${minFlightHours.round()} flight hrs',
        remove: () => updateMinFlightHours(0),
      ));
    }
    if (minAiScore > 0) {
      out.add((
        label: 'AI score ≥ ${minAiScore.round()}',
        remove: () => updateMinAiScore(0),
      ));
    }
    if (minTestScore > 0) {
      out.add((
        label: 'Test score ≥ ${minTestScore.round()}%',
        remove: () => updateMinTestScore(0),
      ));
    }
    if (minYears > 0) {
      out.add((
        label: 'Min ${minYears.round()} yrs experience',
        remove: () => updateMinYears(0),
      ));
    }
    if (unreviewedOnly) {
      out.add((
        label: 'Not sent to admin',
        remove: () => updateUnreviewedOnly(false),
      ));
    }
    if (hasCertifications) {
      out.add((
        label: 'Has certifications',
        remove: () => updateHasCertifications(false),
      ));
    }
    if (hasPublications) {
      out.add((
        label: 'Has publications',
        remove: () => updateHasPublications(false),
      ));
    }
    if (hasAwards) {
      out.add((label: 'Has awards', remove: () => updateHasAwards(false)));
    }
    if (appliedDateRange != null) {
      out.add((
        label: 'Date range',
        remove: () => updateAppliedDateRange(null),
      ));
    }
    return out;
  }

  /// Whether anything is narrowing the list right now.
  bool get hasActiveFilters => activeFilterChips.isNotEmpty;

  void _applyFilters() {
    final spec = _currentSpec();
    _filtered = _all.where((a) => spec.matches(a.filterView)).toList();
    _sort();
  }

  ApplicantFilterSpec _currentSpec() => _draftSpec();

  /// How many candidates a filter set would return across the whole pool.
  int previewCount({
    Set<String>? roles,
    Set<String>? aircraft,
    Set<String>? licences,
    Set<String>? degrees,
    List<String>? skills,
    String? status,
    String? job,
    String? country,
    String? location,
    String? education,
    String? nationality,
    String? professionalStatus,
    String? retirement,
    num? minHours,
    num? minYearsValue,
    String? testStageValue,
    num? minAi,
    num? minTest,
    bool? certs,
    bool? pubs,
    bool? awards,
    bool? unreviewed,
    bool? all,
    DateTimeRange? dateRange,
  }) =>
      previewCountIn(
        _all,
        roles: roles,
        aircraft: aircraft,
        licences: licences,
        degrees: degrees,
        skills: skills,
        status: status,
        job: job,
        country: country,
        location: location,
        education: education,
        nationality: nationality,
        professionalStatus: professionalStatus,
        retirement: retirement,
        minHours: minHours,
      minYearsValue: minYearsValue,
      testStageValue: testStageValue,
      minAi: minAi,
      minTest: minTest,
        certs: certs,
        pubs: pubs,
        awards: awards,
        unreviewed: unreviewed,
        all: all,
        dateRange: dateRange,
      );

  /// Builds a spec from a draft, falling back to whatever is currently set.
  ///
  /// Pure, and the only place a draft turns into a spec — the live list and
  /// every preview go through the same rules.
  ApplicantFilterSpec _draftSpec({
    Set<String>? roles,
    Set<String>? aircraft,
    Set<String>? licences,
    Set<String>? degrees,
    List<String>? skills,
    String? status,
    String? job,
    String? country,
    String? location,
    String? education,
    String? nationality,
    String? professionalStatus,
    String? retirement,
    num? minHours,
    num? minYearsValue,
    String? testStageValue,
    num? minAi,
    num? minTest,
    bool? certs,
    bool? pubs,
    bool? awards,
    bool? unreviewed,
    bool? all,
    DateTimeRange? dateRange,
  }) =>
      ApplicantFilterSpec(
        query: searchQuery.toLowerCase(),
        status: status ?? statusFilter,
        job: job ?? jobFilter,
        location: location ?? locationFilter,
        country: country ?? countryFilter,
        education: education ?? educationFilter,
        nationality: nationality ?? nationalityFilter,
        professionalStatus: professionalStatus ?? professionalStatusFilter,
        retirement: retirement ?? retirementStatusFilter,
        roles: roles ?? roleFilter,
        aircraft: aircraft ?? aircraftFilter,
        licences: licences ?? licenceFilter,
        degrees: degrees ?? degreeFilter,
        skills: (skills ?? skillsFilter).toSet(),
        minFlightHours: minHours ?? minFlightHours,
        testStage: testStageValue ?? testStage,
        minAiScore: minAi ?? minAiScore,
        minTestScore: minTest ?? minTestScore,
        minYears: minYearsValue ?? minYears,
        matchAll: all ?? matchAll,
        unreviewedOnly: unreviewed ?? unreviewedOnly,
        certs: certs ?? hasCertifications,
        pubs: pubs ?? hasPublications,
        awards: awards ?? hasAwards,
        dateRange: dateRange ?? appliedDateRange,
      );

  void _sort() => _filtered = _sortList(_filtered);

  /// A single number to order by, for a mixed pool.
  ///
  /// Hours and years are different units, so this ranks flying candidates
  /// among themselves and non-flying ones among themselves rather than
  /// pretending 3,000 hours and 30 years sit on one scale.
  static num _rank(ApplicantRecord a) =>
      a.flightHours ?? (a.yearsOfExperience ?? 0);

  /// Sorts a copy by the active [sortBy], so the scoped list and the main list
  /// order the same way.
  List<ApplicantRecord> _sortList(List<ApplicantRecord> src) {
    final out = [...src];
    if (out.isEmpty) return out;
    switch (sortBy) {
      case 'applied_desc':
        out.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
        break;
      case 'applied_asc':
        out.sort((a, b) => a.appliedAt.compareTo(b.appliedAt));
        break;
      case 'name_asc':
        out.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        out.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'experience_desc':
        out.sort((a, b) => b.roleCount.compareTo(a.roleCount));
        break;
      // Sorting on the headline metric is what a recruiter reaches for first:
      // most flight hours, most years in trade.
      case 'metric_desc':
        out.sort((a, b) => _rank(b).compareTo(_rank(a)));
        break;
      case 'metric_asc':
        out.sort((a, b) => _rank(a).compareTo(_rank(b)));
        break;
      case 'score_desc':
        // Unscored candidates sink rather than tying at zero: they have not
        // been judged, and putting them level with a genuine 0 would be a
        // judgement.
        out.sort((a, b) => (b.aiScore ?? -1).compareTo(a.aiScore ?? -1));
        break;
      case 'test_desc':
        out.sort((a, b) => (b.assessment.percentage ?? -1)
            .compareTo(a.assessment.percentage ?? -1));
        break;
    }
    return out;
  }

  // ─── Public Filter API ────────────────────────────────────────────────────

  void _set(VoidCallback fn) {
    fn();
    _applyFilters();
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      searchQuery = '';
      _set(() {});
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      searchQuery = query;
      _applyFilters();
      notifyListeners();
    });
  }

  void updateStatusFilter(String v) => _set(() => statusFilter = v);
  void updateJobFilter(String v) => _set(() => jobFilter = v);
  void updateLocationFilter(String v) => _set(() => locationFilter = v);
  void updateCountryFilter(String v) => _set(() => countryFilter = v);
  void updateEducationFilter(String v) => _set(() => educationFilter = v);
  void updateNationalityFilter(String v) => _set(() => nationalityFilter = v);
  void updateProfessionalStatusFilter(String v) =>
      _set(() => professionalStatusFilter = v);
  void updateRetirementStatusFilter(String v) =>
      _set(() => retirementStatusFilter = v);
  void updateSkillsFilter(List<String> v) => _set(() => skillsFilter = v);
  void updateAppliedDateRange(DateTimeRange? v) =>
      _set(() => appliedDateRange = v);
  void updateRoleFilter(Set<String> v) => _set(() => roleFilter = v);
  void updateAircraftFilter(Set<String> v) => _set(() => aircraftFilter = v);
  void updateLicenceFilter(Set<String> v) => _set(() => licenceFilter = v);
  void updateDegreeFilter(Set<String> v) => _set(() => degreeFilter = v);
  void updateMinFlightHours(num v) => _set(() => minFlightHours = v);
  void updateTestStage(String v) => _set(() => testStage = v);
  void updateMinAiScore(num v) => _set(() => minAiScore = v);
  void updateMinTestScore(num v) => _set(() => minTestScore = v);
  void updateMinYears(num v) => _set(() => minYears = v);
  void updateMatchAll(bool v) => _set(() => matchAll = v);
  void updateUnreviewedOnly(bool v) => _set(() => unreviewedOnly = v);
  void updateHasCertifications(bool v) => _set(() => hasCertifications = v);
  void updateHasPublications(bool v) => _set(() => hasPublications = v);
  void updateHasAwards(bool v) => _set(() => hasAwards = v);
  void updateSorting(String v) => _set(() => sortBy = v);

  void clearAllFilters() => _set(() {
    searchQuery = '';
    statusFilter = 'All';
    jobFilter = 'All';
    locationFilter = 'All';
    countryFilter = 'All';
    educationFilter = 'All';
    nationalityFilter = 'All';
    professionalStatusFilter = 'All';
    retirementStatusFilter = 'All';
    skillsFilter = [];
    appliedDateRange = null;
    roleFilter = {};
    aircraftFilter = {};
    licenceFilter = {};
    degreeFilter = {};
    minFlightHours = 0;
    testStage = 'All';
    minAiScore = 0;
    minTestScore = 0;
    minYears = 0;
    matchAll = false;
    unreviewedOnly = false;
    hasCertifications = false;
    hasPublications = false;
    hasAwards = false;
    sortBy = 'applied_desc';
  });

  // ─── Selection ────────────────────────────────────────────────────────────

  // ✅ Deferred notifyListeners via microtask — prevents "widget tree locked" error
  // when clearSelection() is called from dispose() or didUpdateWidget()
  void clearSelection() {
    if (selectedApplicantIds.isEmpty) return;
    selectedApplicantIds.clear();
    // Check if we're in a build frame; if so, defer
    Future.microtask(() => notifyListeners());
  }

  void toggleSelection(String id) {
    selectedApplicantIds.contains(id)
        ? selectedApplicantIds.remove(id)
        : selectedApplicantIds.add(id);
    notifyListeners();
  }

  void selectAll(List<ApplicantRecord> list) {
    selectedApplicantIds
      ..clear()
      ..addAll(list.map((a) => a.userId));
    notifyListeners();
  }

  bool isSelected(String id) => selectedApplicantIds.contains(id);

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> updateApplicationStatus(
    String userId,
    String docId,
    String newStatus,
  ) async {
    final idx = _all.indexWhere((a) => a.userId == userId && a.docId == docId);
    if (idx == -1) return;

    final updated = _all[idx].copyWith(status: newStatus);
    _all[idx] = updated;
    _recordCache[docId] = updated;
    _applyFilters();
    notifyListeners();

    try {
      await updated.reference.update({'status': newStatus});
    } catch (e) {
      error = 'Failed to update status: $e';
      notifyListeners();
    }
  }

  Future<String?> sendSelectedCandidatesToAdmin({String? notes}) async {
    if (selectedApplicantIds.isEmpty) return null;

    final recruiter = _auth.currentUser;
    if (recruiter == null) {
      error = 'Not authenticated';
      notifyListeners();
      return null;
    }

    // Already advanced candidates are excluded rather than refused: the admin
    // has them, and the recruiter's remaining action for those is booking the
    // interview, not sending them a second time. A mixed selection therefore
    // sends only the people who still need sending.
    final selected = _all
        .where((a) =>
            selectedApplicantIds.contains(a.userId) &&
            isSelectable(a) &&
            !canArrangeInterview(a))
        .toList();

    if (selected.isEmpty) {
      error = 'These candidates have already been sent, and their assessment '
          'results have not come back yet.';
      notifyListeners();
      return null;
    }

    // Round two revises a decision made on round one. It is written as its own
    // document rather than as an edit to the first: the recruiter's original
    // shortlist, and the scores it was revised on, have to stay readable
    // afterwards. Overwriting them would erase the reason for the change.
    final round = pendingRound;
    final previous =
        round > 1 ? releasedRequestFor(selected.first.userId) : null;
    final parent = previous == null
        ? null
        : (previous['request_id'] ?? '').toString();

    // ✅ Build payload in single pass
    final candidateMaps = selected
        .map(
          (a) => {
            // No contact details here by design: the recruiter's client never
            // receives them (they are stripped when the application snapshot is
            // written), and the admin reads them straight from Job_Seeker/{uid}
            // using this uid. Sending them through the recruiter would put a
            // second, staler copy of the candidate's PII in a document the
            // recruiter can write.
            'uid': a.userId,
            'name': a.name,
            'nationality': a.nationality,
            'picture_url': a.pictureUrl,
            'location': a.location,
            'job_id': a.jobId,
            'job_title': a.jobData?.title ?? '',
            'applied_at': a.appliedAt.toIso8601String(),
            'status': a.status,
            'match_score': a.matchScore,
            'professional_status': a.professionalStatus,
            'retirement_date': a.retirementDate,
            'summary': a.summary,
            'objectives': a.objectives,
            // Named for what it is. The admin sheet reads these keys, and a
            // count of jobs under a "years" name is how the recruiter view
            // ended up claiming two jobs was two years.
            'roles_listed': a.roleCount,
            'flight_hours': a.flightHours,
            'years_experience': a.yearsOfExperience,
            'current_role': a.currentRole,
            'company': a.company,
            'education': a.education,
            'university': a.university,
            'education_duration': a.educationDuration,
            'cgpa': a.cgpa,
            'skills': a.skills,
            'certifications': a.certifications,
            'publications': a.publications,
            'awards': a.awards,
            'professionalExperience': a.experiences,
            'educationalProfile': a.educations,
            'documents': a.documents,
            'experienceDocuments': a.experienceDocuments,
            'certificationDocuments': a.certificationDocuments,
            // Carried through verbatim so the admin sheet renders exactly what
            // the recruiter reviewed — same keys, same values.
            'role_profile': a.roleProfile.toJson(),
            'target_role': a.roleProfile.roleTitle,
          },
        )
        .toList();

    try {
      final reqRef = _db.collection('recruiter_requests').doc();

      // ✅ Single batch for both the new doc and all sentToAdmin updates
      final batch = _db.batch();

      batch.set(reqRef, {
        'request_id': reqRef.id,
        'recruiter_id': recruiter.uid,
        'recruiter_email': recruiter.email ?? '',
        'created_at': FieldValue.serverTimestamp(),
        'notes': (notes ?? '').trim(),
        'total_candidates': selected.length,
        'status': 'pending',
        'round': round,
        if (parent != null && parent.isNotEmpty)
          'parent_request_id': parent,
        'candidate_ids': selected.map((a) => a.userId).toList(),
        'candidates': candidateMaps,
        'source': round > 1 ? 'reshortlist_after_assessment' : 'shortlist_view',
      });

      for (final a in selected) {
        batch.update(a.reference, {'sentToAdmin': true});
      }

      await batch.commit(); // ✅ One round-trip instead of two
      clearSelection();
      return reqRef.id;
    } catch (e) {
      debugPrint('sendSelectedCandidatesToAdmin error: $e');
      return null;
    }
  }

  Future<bool> updateCandidateStatus({
    required String requestId,
    required String candidateUid,
    required String status,
  }) async {
    try {
      final ref = _db.collection('recruiter_requests').doc(requestId);
      final snap = await ref.get();
      if (!snap.exists) return false;

      final candidates = List<dynamic>.from(
        (snap.data() as Map<String, dynamic>)['candidates'] ?? [],
      );

      for (int i = 0; i < candidates.length; i++) {
        final c = Map<String, dynamic>.from(candidates[i] as Map);
        if (c['uid'] == candidateUid) {
          candidates[i] = {...c, 'status': status};
          break;
        }
      }

      await ref.update({
        'candidates': candidates,
        'candidate_statuses.$candidateUid': status,
        'last_updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('updateCandidateStatus error: $e');
      return false;
    }
  }
}

/// When a candidate who has already been sent to the admin may be sent again.
///
/// Sending someone normally locks them: the decision is made, and re-sending
/// it would only create duplicates. Assessment results coming back is the one
/// thing that legitimately reopens it — the recruiter now knows something they
/// did not know when they chose, and letting them choose again is the entire
/// point of running the test.
///
/// Pure, and separate from the provider, so the rule can be tested without a
/// Firestore connection. The provider holds a live database handle from the
/// moment it is constructed; a rule about who may be re-sent should not need
/// one to be checked.
class ResendPolicy {
  const ResendPolicy(this.requests);

  /// Recruiter request documents, newest first.
  final List<Map<String, dynamic>> requests;

  static bool _isReleased(Map<String, dynamic> request) =>
      request['assessment_released_at'] != null;

  static List<String> _idsIn(Map<String, dynamic> request) => [
        for (final id in (request['candidate_ids'] as List? ?? const []))
          id.toString(),
      ];

  /// Only the candidates whose own score has come back.
  ///
  /// A released batch is not a released candidate. Somebody who was never
  /// invited, or who is still sitting the test, has produced nothing new for
  /// the recruiter to decide on — reopening them would be offering a second
  /// decision on the same evidence as the first.
  ///
  /// Read from `assessment_summary`, which the admin writes at release time
  /// and which holds one entry per candidate who actually has a score.
  Set<String> get reopenedCandidateIds => {
        for (final request in requests)
          if (_isReleased(request))
            ...(request['assessment_summary'] as Map? ?? const {})
                .keys
                .map((k) => k.toString()),
      };

  /// The released request this candidate has a score in, or null.
  Map<String, dynamic>? releasedRequestFor(String candidateUid) {
    for (final request in requests) {
      if (!_isReleased(request)) continue;
      final summary = request['assessment_summary'] as Map? ?? const {};
      if (summary.containsKey(candidateUid)) return request;
    }
    return null;
  }

  /// Candidates the recruiter has already advanced past the assessment.
  ///
  /// Membership of a round-two-or-later request is what earns an interview: it
  /// is the recruiter saying, with the scores in front of them, that this
  /// person goes forward. Round one is a shortlist, which is a different and
  /// weaker claim.
  Set<String> get interviewReadyCandidateIds => {
        for (final request in requests)
          if (((request['round'] as num?)?.toInt() ?? 1) >= 2)
            ..._idsIn(request),
      };

  /// The later request a candidate was advanced in, or null.
  Map<String, dynamic>? advancedRequestFor(String candidateUid) {
    for (final request in requests) {
      if (((request['round'] as num?)?.toInt() ?? 1) < 2) continue;
      if (_idsIn(request).contains(candidateUid)) return request;
    }
    return null;
  }

  /// The round a request built from [selectedIds] would be.
  ///
  /// The highest round among the selection wins, not the first one found: a
  /// selection that mixes a fresh candidate with two being revised must not
  /// fall back to round one and overwrite the history it is revising.
  int roundFor(Iterable<String> selectedIds) {
    var round = 1;
    for (final id in selectedIds) {
      final request = releasedRequestFor(id);
      if (request == null) continue;
      final previous = (request['round'] as num?)?.toInt() ?? 1;
      if (previous + 1 > round) round = previous + 1;
    }
    return round;
  }
}

/// The fields the filter reads, and nothing else.
///
/// [ApplicantFilterSpec] works on this rather than on [ApplicantRecord] so the
/// filtering rules can be tested without a Firestore document — the record
/// carries a live DocumentReference, which is not something a unit test should
/// have to fake.
typedef FilterableCandidate = ({
  String searchIndex,
  String status,
  String jobTitle,
  String location,
  String country,
  String education,
  String nationality,
  String professionalStatus,
  String targetRole,
  String retirementDate,
  bool sentToAdmin,
  List<String> aircraftTypes,
  List<String> licences,
  List<String> degrees,
  List<String> skills,
  num? flightHours,
  num? yearsOfExperience,
  bool hasCertifications,
  bool hasPublications,
  bool hasAwards,
  DateTime appliedAt,
  int? aiScore,
  String testStatus,
  int? testPercentage,
  String testVerdict,
});

/// One immutable set of filter values, and the rule for whether a candidate
/// passes them.
///
/// Pulling the predicate out of the provider is what lets the filter sheet
/// count a draft without applying it: there is exactly one definition of
/// "matches", used by both the live list and the preview.
class ApplicantFilterSpec {
  const ApplicantFilterSpec({
    required this.query,
    required this.status,
    required this.job,
    required this.location,
    required this.country,
    required this.education,
    required this.nationality,
    required this.professionalStatus,
    required this.retirement,
    required this.roles,
    required this.aircraft,
    required this.licences,
    required this.degrees,
    required this.skills,
    required this.minFlightHours,
    required this.testStage,
    required this.minAiScore,
    required this.minTestScore,
    required this.minYears,
    required this.matchAll,
    required this.unreviewedOnly,
    required this.certs,
    required this.pubs,
    required this.awards,
    required this.dateRange,
  });

  final String query;
  final String status;
  final String job;
  final String location;
  final String country;
  final String education;
  final String nationality;
  final String professionalStatus;
  final String retirement;
  final Set<String> roles;
  final Set<String> aircraft;
  final Set<String> licences;
  final Set<String> degrees;
  final Set<String> skills;
  final num minFlightHours;
  final String testStage;
  final num minAiScore;
  final num minTestScore;
  final num minYears;
  final bool matchAll;
  final bool unreviewedOnly;
  final bool certs;
  final bool pubs;
  final bool awards;
  final DateTimeRange? dateRange;

  /// An empty selection always passes: a filter nobody set must not exclude
  /// anyone.
  bool _multi(Set<String> selected, List<String> values) {
    if (selected.isEmpty) return true;
    return matchAll
        ? selected.every(values.contains)
        : selected.any(values.contains);
  }

  bool _single(String value, String actual) =>
      value == 'All' || actual.toLowerCase() == value.toLowerCase();

  bool matches(FilterableCandidate a) {
    if (query.isNotEmpty && !a.searchIndex.contains(query)) return false;
    if (unreviewedOnly && a.sentToAdmin) return false;

    if (!_single(status, a.status)) return false;
    if (job != 'All' && a.jobTitle != job) return false;
    if (!_single(location, a.location)) return false;
    if (!_single(country, a.country)) return false;
    if (!_single(education, a.education)) return false;
    if (!_single(nationality, a.nationality)) return false;
    if (!_single(professionalStatus, a.professionalStatus)) return false;

    if (roles.isNotEmpty && !roles.contains(a.targetRole)) return false;
    if (!_multi(aircraft, a.aircraftTypes)) return false;
    if (!_multi(licences, a.licences)) return false;
    if (!_multi(degrees, a.degrees)) return false;
    if (!_multi(skills, a.skills)) return false;
    // Null means the role has no such measure at all, so a threshold on it
    // excludes the candidate rather than treating them as zero.
    if (minFlightHours > 0 &&
        (a.flightHours == null || a.flightHours! < minFlightHours)) {
      return false;
    }
    if (minYears > 0 &&
        (a.yearsOfExperience == null || a.yearsOfExperience! < minYears)) {
      return false;
    }

    // Assessment stage. "Completed" means the candidate sat it; whether the
    // score has reached the recruiter yet is a separate question, which is why
    // pass and fail are their own options and only match a released score.
    if (testStage != 'All') {
      final ok = switch (testStage) {
        'Not invited' => a.testStatus.isEmpty,
        'Invited' => a.testStatus == 'invited',
        'In progress' => a.testStatus == 'accepted' || a.testStatus == 'in_progress',
        'Completed' => a.testStatus == 'submitted',
        'Expired' => a.testStatus == 'expired',
        'Passed' => a.testVerdict == 'pass',
        'Failed' => a.testVerdict == 'fail',
        _ => true,
      };
      if (!ok) return false;
    }

    // A threshold on a score nobody has produced yet excludes the candidate
    // rather than reading as zero — "not analysed" is not "scored nothing".
    if (minAiScore > 0 && (a.aiScore == null || a.aiScore! < minAiScore)) {
      return false;
    }
    if (minTestScore > 0 &&
        (a.testPercentage == null || a.testPercentage! < minTestScore)) {
      return false;
    }

    if (certs && !a.hasCertifications) return false;
    if (pubs && !a.hasPublications) return false;
    if (awards && !a.hasAwards) return false;

    if (retirement != 'All') {
      if (a.retirementDate.isEmpty) return false;
      final parsed = DateTime.tryParse(a.retirementDate);
      if (parsed == null) return false;
      final years = parsed.difference(DateTime.now()).inDays / 365;
      final ok = switch (retirement) {
        'Within 1 Year' => years >= 0 && years <= 1,
        '1-3 Years' => years > 1 && years <= 3,
        '3-5 Years' => years > 3 && years <= 5,
        '5+ Years' => years > 5,
        _ => false,
      };
      if (!ok) return false;
    }

    final range = dateRange;
    if (range != null) {
      if (a.appliedAt.isBefore(range.start) ||
          a.appliedAt.isAfter(range.end.add(const Duration(days: 1)))) {
        return false;
      }
    }

    return true;
  }
}
