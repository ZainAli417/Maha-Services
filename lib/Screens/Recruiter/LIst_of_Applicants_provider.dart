import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _str(dynamic v, [String fb = '']) => v?.toString() ?? fb;
List<String> _strList(dynamic v) =>
    v is List ? v.map(_str).toList() : const [];
List<Map<String, dynamic>> _mapList(dynamic v) => v is List
    ? v.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList()
    : const [];
DateTime _parseTs(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}
Map<String, dynamic> _digMap(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is Map) return Map<String, dynamic>.from(v);
  }
  return {};
}

dynamic _digVal(Map m, List<String> keys, [dynamic fallback]) {
  for (final k in keys) {
    if (m.containsKey(k) && m[k] != null) return m[k];
  }
  return fallback;
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
    required this.experienceYears,
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
  });

  // Identity
  final String userId, jobId, docId, status, searchIndex;
  final DateTime appliedAt;
  final DocumentReference reference;
  final Map<String, dynamic> profileSnapshot, matchScore;
  final bool sentToAdmin;
  final JobData? jobData;

  // Personal
  final String name, email, secondaryEmail, phone, nationality,
      pictureUrl, location, dob, objectives, summary;

  // Professional
  final String education, university, educationDuration, cgpa,
      currentRole, company, professionalStatus, retirementDate;
  final int experienceYears;

  // Collections
  final List<String> skills, socialLinks, publications, awards;
  final List<dynamic> documents;
  final List<Map<String, dynamic>> experiences, educations,
      experienceDocuments, certificationDocuments;
  final List<Map<String, String>> certifications;

  String get professionalSummary => summary;

  factory ApplicantRecord.fromSnapshot(
      DocumentSnapshot doc, Map<String, dynamic> data, JobData? jobData) {
    final userId = doc.reference.parent.parent?.id ?? 'unknown_user';

    final ps = data['profileSnapshot'] is Map
        ? Map<String, dynamic>.from(data['profileSnapshot'] as Map)
        : <String, dynamic>{};

    final ud           = _digMap(ps, ['user_data', 'user_Account_Data']);
    final personal     = _digMap(ud, ['personalProfile']);
    final professional = _digMap(ud, ['professionalProfile', 'professional_profile']);

    // ✅ FIX: name lives in personal, not ud
    final name  = _str(personal['name'] ?? personal['fullName'], 'Unknown');
    final email = _str(personal['email']);
    final phone = _str(personal['contactNumber']);

    // ✅ FIX: summary merged from personal + professional without _dig
    final summary = _str(personal['summary'] ?? professional['summary']);

    // ✅ FIX: use _digVal (returns dynamic) for list fields
    final rawExp = _digVal(ud, ['professionalExperience', 'professional_experience', 'experiences']);
    final rawEdu = _digVal(ud, ['educationalProfile', 'educational_profile']);

    // Experience
    final experiences = rawExp is List
        ? rawExp.map<Map<String, dynamic>>((e) {
      if (e is! Map) return <String, dynamic>{};
      return {
        'organization': e['organization'] ?? e['company'] ?? '',
        'role':         e['role']         ?? '',
        'duration':     e['duration']     ?? '',
        'startDate':    e['startDate']    ?? '',
        'endDate':      e['endDate']      ?? '',
        'duties':       e['duties']       ?? e['text'] ?? '',
        'text':         e['text']         ?? e['duties'] ?? '',
      };
    }).toList()
        : <Map<String, dynamic>>[];

    // Education
    final educations = _mapList(rawEdu);

    // Certifications
    final certifications = <Map<String, String>>[];
    final rawCerts = ud['certifications'];
    if (rawCerts is List) {
      for (final item in rawCerts) {
        if (item is Map) {
          final n = _str(item['name'] ?? item['certName']);
          if (n.isNotEmpty) {
            certifications.add({
              'organization': _str(item['organization']),
              'name':         n,
              'issueDate':    _str(item['issueDate']),
              'expiryDate':   _str(item['expiryDate']),
            });
          }
        } else if (item is String && item.isNotEmpty) {
          certifications.add({'organization': '', 'name': item, 'issueDate': '', 'expiryDate': ''});
        }
      }
    }

    // ✅ FIX: explicit return type List<Map<String,dynamic>> on local function
    List<Map<String, dynamic>> parseDocs(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map<Map<String, dynamic>>((e) {
        if (e is! Map) return <String, dynamic>{};
        return {
          'name':       _str(e['name']),
          'url':        _str(e['url']),
          'type':       _str(e['type'] ?? e['contentType']),
          'uploadedAt': _str(e['uploadedAt']),
        };
      }).toList();
    }

    final firstEdu = educations.isNotEmpty ? educations.first : <String, dynamic>{};
    final firstExp = experiences.isNotEmpty ? experiences.first : <String, dynamic>{};

    // ✅ FIX: skills live in personal, not ud — _digMap on personal
    final skills = _strList(_digVal(personal, ['skills', 'skillset']));

    // ✅ FIX: pictureUrl lives in personal, not ud
    final pictureUrl = _str(personal['profilePicUrl'] ?? personal['pic_url']);

    // ✅ FIX: professionalStatus and retirementDate use _digVal on professional Map
    final professionalStatus = _str(
      _digVal(professional, ['status', 'professionalStatus']),
    );
    final retirementDate = _str(
      _digVal(professional, ['expectedRetirementDate', 'retirementDate']),
    );

    return ApplicantRecord._(
      userId:               userId,
      jobId:                _str(data['jobId']),
      status:               _str(data['status'], 'pending'),
      appliedAt:            _parseTs(data['appliedAt']),
      profileSnapshot:      ps,
      docId:                doc.id,
      reference:            doc.reference,
      jobData:              jobData,
      matchScore:           data['match_score'] is Map
          ? Map<String, dynamic>.from(data['match_score'] as Map)
          : {},
      sentToAdmin:          data['sentToAdmin'] == true,
      name:                 name,
      email:                email,
      secondaryEmail:       _str(personal['secondary_email']),
      phone:                phone,
      nationality:          _str(personal['nationality']),
      pictureUrl:           pictureUrl,
      location:             _str(personal['location']),
      dob:                  _str(personal['dob']),
      objectives:           _str(personal['objectives']),
      summary:              summary,
      education:            _str(firstEdu['majorSubjects']),
      university:           _str(firstEdu['institutionName']),
      educationDuration:    _str(firstEdu['duration']),
      cgpa:                 _str(firstEdu['marksOrCgpa']),
      currentRole:          _str(firstExp['role']),
      company:              _str(firstExp['organization']),
      experienceYears:      experiences.length,
      professionalStatus:   professionalStatus,
      retirementDate:       retirementDate,
      skills:               skills,
      socialLinks:          _strList(personal['socialLinks']),
      experiences:          experiences,
      educations:           educations,
      certifications:       certifications,
      publications:         _strList(ud['publications']),
      awards:               _strList(ud['awards']),
      documents:            ud['documents'] is List ? ud['documents'] as List : const [],
      experienceDocuments:  parseDocs(ud['experienceDocuments']),
      certificationDocuments: parseDocs(ud['certificationDocuments']),
      searchIndex: '$name $email $phone ${_str(personal['location'])} '
          '${skills.join(' ')} ${firstExp['organization'] ?? ''} '
          '${firstExp['role'] ?? ''}'.toLowerCase(),
    );
  }
  ApplicantRecord copyWith({String? status, JobData? jobData, bool? sentToAdmin}) =>
      ApplicantRecord._(
        userId: userId, jobId: jobId, status: status ?? this.status,
        appliedAt: appliedAt, profileSnapshot: profileSnapshot,
        docId: docId, reference: reference,
        jobData: jobData ?? this.jobData,
        matchScore: matchScore, sentToAdmin: sentToAdmin ?? this.sentToAdmin,
        searchIndex: searchIndex, name: name, email: email,
        secondaryEmail: secondaryEmail, phone: phone, nationality: nationality,
        pictureUrl: pictureUrl, location: location, dob: dob,
        objectives: objectives, summary: summary, education: education,
        university: university, educationDuration: educationDuration,
        cgpa: cgpa, currentRole: currentRole, company: company,
        experienceYears: experienceYears, professionalStatus: professionalStatus,
        retirementDate: retirementDate, skills: skills, socialLinks: socialLinks,
        experiences: experiences, educations: educations,
        certifications: certifications, publications: publications,
        awards: awards, documents: documents,
        experienceDocuments: experienceDocuments,
        certificationDocuments: certificationDocuments,
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

class ApplicantsProvider with ChangeNotifier {
  final _db   = FirebaseFirestore.instance;
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
  RangeValues experienceYearsRange = const RangeValues(0, 30);
  bool hasCertifications = false;
  bool hasPublications = false;
  bool hasAwards = false;
  String sortBy = 'applied_desc';

  // ── Available filter options ──
  final Set<String> availableExperiences  = {};
  final Set<String> availableLocations    = {};
  final Set<String> availableEducations   = {};
  final Set<String> availableJobs         = {};
  final Set<String> availableSkills       = {};
  final Set<String> availableNationalities = {};

  // ── Getters ──
  List<ApplicantRecord> get applicants       => _filtered;
  List<ApplicantRecord> get allApplicants    => _all;
  List<Map<String, dynamic>> get recruiterRequests => _recruiterRequests;

  int get totalApplicants  => _all.length;
  int get filteredCount    => _filtered.length;
  int get pendingCount     => _all.where((a) => a.status == 'pending').length;
  int get acceptedCount    => _all.where((a) => a.status == 'accepted').length;
  int get rejectedCount    => _all.where((a) => a.status == 'rejected').length;
  int get shortlistCount   => _all.where((a) => a.status == 'shortlist').length;

  List<ApplicantRecord> get shortlistApplicants =>
      _all.where((a) => a.status.toLowerCase() == 'shortlist').toList();

  List<ApplicantRecord> getShortlistForJob(String? jobId) =>
      (jobId == null || jobId.isEmpty)
          ? shortlistApplicants
          : _all.where((a) => a.status.toLowerCase() == 'shortlist' && a.jobId == jobId).toList();

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

    if (_isInitializing || (_initializedUid == user.uid && _subscription != null)) return;

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
          _hashCache[doc.id]   = hash;
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
      _hashCache.removeWhere((k, _)   => !live.contains(k));
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
      final doc  = await _db.collection('Posted_jobs_public').doc(jobId).get();
      if (!doc.exists) { _jobCache[jobId] = null; return; }
      final data = doc.data()!;

      double? salary;
      final rawSalary = data['salary'];
      if (rawSalary is num) {
        salary = rawSalary.toDouble();
      } else if (rawSalary is String) {
        final m = RegExp(r'[\d,]+').firstMatch(rawSalary);
        salary = m != null ? double.tryParse(m.group(0)!.replaceAll(',', '')) : null;
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
    availableExperiences.clear();
    availableLocations.clear();
    availableEducations.clear();
    availableJobs.clear();
    availableSkills.clear();
    availableNationalities.clear();

    for (final a in _all) {
      if (a.jobData != null)        availableJobs.add(a.jobData!.title);
      if (a.location.isNotEmpty)    availableLocations.add(a.location);
      if (a.education.isNotEmpty)   availableEducations.add(a.education);
      if (a.nationality.isNotEmpty) availableNationalities.add(a.nationality);
      availableSkills.addAll(a.skills);

      final y = a.experienceYears;
      availableExperiences.add(
        y == 0 ? 'Entry Level' : y <= 2 ? '1-2 years' : y <= 5
            ? '3-5 years' : y <= 10 ? '6-10 years' : '10+ years',
      );
    }
  }

  void _applyFilters() {
    final q        = searchQuery.toLowerCase();
    final hasQ     = q.isNotEmpty;
    final chkStat  = statusFilter != 'All';
    final chkJob   = jobFilter != 'All';
    final chkLoc   = locationFilter != 'All';
    final chkEdu   = educationFilter != 'All';
    final chkNat   = nationalityFilter != 'All';
    final chkProf  = professionalStatusFilter != 'All';
    final chkSkill = skillsFilter.isNotEmpty;
    final chkDate  = appliedDateRange != null;

    _filtered = _all.where((a) {
      if (hasQ   && !a.searchIndex.contains(q))                                                   return false;
      if (chkStat && a.status.toLowerCase() != statusFilter.toLowerCase())                         return false;
      if (chkJob  && a.jobData?.title != jobFilter)                                                return false;
      if (chkLoc  && a.location != locationFilter)                                                 return false;
      if (chkEdu  && a.education != educationFilter)                                               return false;
      if (chkNat  && a.nationality != nationalityFilter)                                           return false;
      if (chkProf && a.professionalStatus.toLowerCase() != professionalStatusFilter.toLowerCase()) return false;

      if (a.experienceYears < experienceYearsRange.start ||
          a.experienceYears > experienceYearsRange.end)                                           return false;
      if (hasCertifications && a.certifications.isEmpty)                                          return false;
      if (hasPublications   && a.publications.isEmpty)                                            return false;
      if (hasAwards         && a.awards.isEmpty)                                                  return false;

      if (experienceFilter != 'All') {
        final y = a.experienceYears;
        final lv = y == 0 ? 'Entry Level' : y <= 2 ? '1-2 years' : y <= 5
            ? '3-5 years' : y <= 10 ? '6-10 years' : '10+ years';
        if (lv != experienceFilter) return false;
      }

      if (retirementStatusFilter != 'All') {
        if (a.retirementDate.isEmpty) return false;
        try {
          final diff = DateTime.parse(a.retirementDate).difference(DateTime.now()).inDays / 365;
          final ok = retirementStatusFilter == 'Within 1 Year' ? (diff <= 1 && diff >= 0)
              : retirementStatusFilter == '1-3 Years' ? (diff > 1 && diff <= 3)
              : retirementStatusFilter == '3-5 Years' ? (diff > 3 && diff <= 5)
              : retirementStatusFilter == '5+ Years'  ? diff > 5
              : false;
          if (!ok) return false;
        } catch (_) { return false; }
      }

      if (chkSkill && skillsFilter.any((s) => !a.skills.contains(s))) return false;

      if (chkDate) {
        if (a.appliedAt.isBefore(appliedDateRange!.start) ||
            a.appliedAt.isAfter(appliedDateRange!.end.add(const Duration(days: 1)))) return false;
      }

      return true;
    }).toList();

    _sort();
  }

  void _sort() {
    if (_filtered.isEmpty) return;
    switch (sortBy) {
      case 'applied_desc':   _filtered.sort((a, b) => b.appliedAt.compareTo(a.appliedAt)); break;
      case 'applied_asc':    _filtered.sort((a, b) => a.appliedAt.compareTo(b.appliedAt)); break;
      case 'name_asc':       _filtered.sort((a, b) => a.name.compareTo(b.name));           break;
      case 'name_desc':      _filtered.sort((a, b) => b.name.compareTo(a.name));           break;
      case 'experience_desc': _filtered.sort((a, b) => b.experienceYears.compareTo(a.experienceYears)); break;
    }
  }

  // ─── Public Filter API ────────────────────────────────────────────────────

  void _set(VoidCallback fn) { fn(); _applyFilters(); notifyListeners(); }

  void updateSearchQuery(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) { searchQuery = ''; _set(() {}); return; }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      searchQuery = query;
      _applyFilters();
      notifyListeners();
    });
  }

  void updateStatusFilter(String v)            => _set(() => statusFilter = v);
  void updateJobFilter(String v)               => _set(() => jobFilter = v);
  void updateExperienceFilter(String v)        => _set(() => experienceFilter = v);
  void updateLocationFilter(String v)          => _set(() => locationFilter = v);
  void updateEducationFilter(String v)         => _set(() => educationFilter = v);
  void updateNationalityFilter(String v)       => _set(() => nationalityFilter = v);
  void updateProfessionalStatusFilter(String v)=> _set(() => professionalStatusFilter = v);
  void updateRetirementStatusFilter(String v)  => _set(() => retirementStatusFilter = v);
  void updateSkillsFilter(List<String> v)      => _set(() => skillsFilter = v);
  void updateAppliedDateRange(DateTimeRange? v)=> _set(() => appliedDateRange = v);
  void updateExperienceYearsRange(RangeValues v)=> _set(() => experienceYearsRange = v);
  void updateHasCertifications(bool v)         => _set(() => hasCertifications = v);
  void updateHasPublications(bool v)           => _set(() => hasPublications = v);
  void updateHasAwards(bool v)                 => _set(() => hasAwards = v);
  void updateSorting(String v)                 => _set(() => sortBy = v);

  void clearAllFilters() => _set(() {
    searchQuery = ''; statusFilter = 'All'; jobFilter = 'All';
    experienceFilter = 'All'; locationFilter = 'All'; educationFilter = 'All';
    nationalityFilter = 'All'; professionalStatusFilter = 'All';
    retirementStatusFilter = 'All'; skillsFilter = []; appliedDateRange = null;
    experienceYearsRange = const RangeValues(0, 30);
    hasCertifications = false; hasPublications = false; hasAwards = false;
    sortBy = 'applied_desc';
  });

  // ─── Selection ────────────────────────────────────────────────────────────

  // ✅ Deferred notifyListeners via microtask — prevents "widget tree locked" error
  // when clearSelection() is called from dispose() or didUpdateWidget()
  void clearSelection() {
    if (selectedApplicantIds.isEmpty) return;
    selectedApplicantIds.clear();
    // Check if we're in a build frame; if so, defer
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
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
      String userId, String docId, String newStatus) async {
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

    final selected = _all
        .where((a) => selectedApplicantIds.contains(a.userId) && !a.sentToAdmin)
        .toList();

    if (selected.isEmpty) {
      error = 'Selected candidates have already been sent to admin';
      notifyListeners();
      return null;
    }

    // ✅ Build payload in single pass
    final candidateMaps = selected.map((a) => {
      'uid': a.userId, 'name': a.name, 'email': a.email, 'phone': a.phone,
      'nationality': a.nationality, 'picture_url': a.pictureUrl,
      'location': a.location, 'dob': a.dob, 'secondary_email': a.secondaryEmail,
      'job_id': a.jobId, 'job_title': a.jobData?.title ?? '',
      'applied_at': a.appliedAt.toIso8601String(), 'status': a.status,
      'match_score': a.matchScore, 'professional_status': a.professionalStatus,
      'retirement_date': a.retirementDate, 'summary': a.summary,
      'objectives': a.objectives, 'experience_years': a.experienceYears,
      'current_role': a.currentRole, 'company': a.company,
      'education': a.education, 'university': a.university,
      'education_duration': a.educationDuration, 'cgpa': a.cgpa,
      'skills': a.skills, 'social_links': a.socialLinks,
      'certifications': a.certifications, 'publications': a.publications,
      'awards': a.awards, 'professionalExperience': a.experiences,
      'educationalProfile': a.educations, 'documents': a.documents,
      'experienceDocuments': a.experienceDocuments,
      'certificationDocuments': a.certificationDocuments,
    }).toList();

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
        'candidate_ids': selected.map((a) => a.userId).toList(),
        'candidates': candidateMaps,
        'source': 'shortlist_view',
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
      final ref  = _db.collection('recruiter_requests').doc(requestId);
      final snap = await ref.get();
      if (!snap.exists) return false;

      final candidates = List<dynamic>.from(
          (snap.data() as Map<String, dynamic>)['candidates'] ?? []);

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