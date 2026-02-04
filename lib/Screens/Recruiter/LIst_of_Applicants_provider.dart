import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==========================================
// 1. Optimized Applicant Record Model
// ==========================================

class ApplicantRecord {
  final String userId;
  final String jobId;
  final String status;
  final DateTime appliedAt;
  final String docId;
  final DocumentReference reference;

  // Stored Parsed Data (Computed ONCE)
  final String name;
  final String email;
  final String secondaryEmail;
  final String phone;
  final String nationality;
  final String pictureUrl;
  final String location;

  // 🆕 ADDED BACK MISSING FIELDS
  final String dob;
  final String objectives;
  final String summary;

  final String education; // Major/Degree
  final String university;
  final String educationDuration;
  final String cgpa;
  final String currentRole;
  final String company;
  final int experienceYears;
  final String professionalStatus;
  final String retirementDate;

  // Collections
  final List<String> skills;
  final List<String> socialLinks;
  final List<Map<String, dynamic>> experiences;
  final List<Map<String, dynamic>> educations;
  final List<Map<String, String>> certifications;
  final List<String> publications;
  final List<String> awards;
  final List<dynamic> documents;
// Add these fields after line 33 (after documents field):
  final List<Map<String, dynamic>> experienceDocuments;
  final List<Map<String, dynamic>> certificationDocuments;
  // Raw Data (Kept for edge cases/updates)
  final Map<String, dynamic> profileSnapshot;
  final JobData? jobData;
  final Map<String, dynamic> matchScore;

  // Search Optimization
  final String searchIndex;

  ApplicantRecord._({
    required this.userId,
    required this.jobId,
    required this.status,
    required this.appliedAt,
    required this.profileSnapshot,
    required this.docId,
    required this.reference,
    this.jobData,
    required this.name,
    required this.email,
    required this.secondaryEmail,
    required this.phone,
    required this.nationality,
    required this.pictureUrl,
    required this.location,
    // 🆕 Required in constructor
    required this.dob,
    required this.objectives,
    required this.summary,
    required this.education,
    required this.university,
    required this.educationDuration,
    required this.cgpa,
    required this.currentRole,
    required this.company,
    required this.experienceYears,
    required this.professionalStatus,
    required this.retirementDate,
    required this.skills,
    required this.socialLinks,
    required this.experiences,
    required this.educations,
    required this.certifications,
    required this.publications,
    required this.awards,
    required this.documents,
    required this.matchScore,
    required this.searchIndex,

    // Add after documents parameter:
    required this.experienceDocuments,
    required this.certificationDocuments,

  });

  // Getter alias for professional summary if used interchangeably
  String get professionalSummary => summary;

  /// Factory constructor handles all parsing logic ONCE upon instantiation
  factory ApplicantRecord.fromSnapshot(
      DocumentSnapshot doc,
      Map<String, dynamic> data,
      JobData? jobData
      ) {
    final parentDoc = doc.reference.parent.parent;
    final userId = parentDoc?.id ?? 'unknown_user';

    // Parse Date
    DateTime appliedAt;
    final rawDate = data['appliedAt'];
    if (rawDate is Timestamp) appliedAt = rawDate.toDate();
    else if (rawDate is String) appliedAt = DateTime.tryParse(rawDate) ?? DateTime.now();
    else appliedAt = DateTime.now();

    // Normalize Profile Data
    final profileSnapshot = data['profileSnapshot'] is Map ? Map<String, dynamic>.from(data['profileSnapshot']) : <String, dynamic>{};
    final userData = profileSnapshot['user_data'] ?? profileSnapshot['user_Account_Data'] ?? <String, dynamic>{};

    final personal = userData['personalProfile'] ?? <String, dynamic>{};
    final professional = userData['professionalProfile'] ?? userData['professional_profile'] ?? <String, dynamic>{};

    // -- Extract Simple Fields --
    final name = (personal['name'] ?? personal['fullName'] ?? 'Unknown').toString();
    final email = (personal['email'] ?? '').toString();
    final phone = (personal['contactNumber'] ?? '').toString();
    final location = (personal['location'] ?? '').toString();
    final nationality = (personal['nationality'] ?? '').toString();

    // 🆕 Extract Missing Fields
    final dob = (personal['dob'] ?? '').toString();
    final objectives = (personal['objectives'] ?? '').toString();
    // Try personal summary, then professional summary
    final summary = (personal['summary'] ?? professional['summary'] ?? '').toString();

    // -- Extract Lists --
    // Skills
    final rawSkills = personal['skills'] ?? personal['skillset'];
    final List<String> skills = (rawSkills is List) ? rawSkills.map((e) => e.toString()).toList() : [];

    // Experience
    final rawExp = userData['professionalExperience'] ?? userData['professional_experience'] ?? userData['experiences'];
    List<Map<String, dynamic>> experiences = [];
    if (rawExp is List) {
      experiences = rawExp.map((item) {
        if (item is! Map) return <String, dynamic>{};
        final m = item;
        return {
          'organization': m['organization'] ?? m['company'] ?? '',
          'role': m['role'] ?? '',
          'duration': m['duration'] ?? '',
          'startDate': m['startDate'] ?? '',
          'endDate': m['endDate'] ?? '',
          'duties': m['duties'] ?? m['text'] ?? '',
          'text': m['text'] ?? m['duties'] ?? '', // Preserve for legacy compatibility
        };
      }).toList();
    }

    // Education
    final rawEdu = userData['educationalProfile'] ?? userData['educational_profile'];
    List<Map<String, dynamic>> educations = [];
    if (rawEdu is List) {
      educations = rawEdu.map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{}).toList();
    }

    // Replace the certifications parsing section with this enhanced version:
    final rawCerts = userData['certifications'];
    List<Map<String, String>> certifications = [];
    if (rawCerts is List) {
      for (var item in rawCerts) {
        if (item is Map) {
          final n = (item['name'] ?? item['certName'] ?? '').toString();
          if (n.isNotEmpty) {
            certifications.add({
              'organization': (item['organization'] ?? '').toString(),
              'name': n,
              'issueDate': (item['issueDate'] ?? '').toString(),
              'expiryDate': (item['expiryDate'] ?? '').toString(),
            });
          }
        } else if (item is String && item.isNotEmpty) {
          certifications.add({'organization': '', 'name': item, 'issueDate': '', 'expiryDate': ''});
        }
      }
    }

// Add this AFTER certifications parsing (around line 195):
// Experience Documents
    final rawExpDocs = userData['experienceDocuments'];
    List<Map<String, dynamic>> experienceDocuments = [];
    if (rawExpDocs is List) {
      experienceDocuments = rawExpDocs.map((item) {
        if (item is! Map) return <String, dynamic>{};
        return {
          'name': (item['name'] ?? '').toString(),
          'url': (item['url'] ?? '').toString(),
          'type': (item['type'] ?? item['contentType'] ?? '').toString(),
          'uploadedAt': (item['uploadedAt'] ?? '').toString(),
        };
      }).toList();
    }

// Certification Documents
    final rawCertDocs = userData['certificationDocuments'];
    List<Map<String, dynamic>> certificationDocuments = [];
    if (rawCertDocs is List) {
      certificationDocuments = rawCertDocs.map((item) {
        if (item is! Map) return <String, dynamic>{};
        return {
          'name': (item['name'] ?? '').toString(),
          'url': (item['url'] ?? '').toString(),
          'type': (item['type'] ?? item['contentType'] ?? '').toString(),
          'uploadedAt': (item['uploadedAt'] ?? '').toString(),
        };
      }).toList();
    }
    // -- Derived Fields --
    final firstEdu = educations.isNotEmpty ? educations.first : <String, dynamic>{};
    final firstExp = experiences.isNotEmpty ? experiences.first : <String, dynamic>{};

    // Pre-compute Search Index for O(1) filtering
    final searchStr = '$name $email $phone $location ${skills.join(" ")} ${firstExp['organization'] ?? ''} ${firstExp['role'] ?? ''}'.toLowerCase();

    return ApplicantRecord._(
      userId: userId,
      jobId: data['jobId'] ?? '',
      status: (data['status'] as String?) ?? 'pending',
      appliedAt: appliedAt,
      profileSnapshot: profileSnapshot,
      docId: doc.id,
      reference: doc.reference,
      jobData: jobData,
      matchScore: data['match_score'] is Map ? Map<String, dynamic>.from(data['match_score']) : {},
      // Fields
      name: name,
      email: email,
      secondaryEmail: (personal['secondary_email'] ?? '').toString(),
      phone: phone,
      nationality: nationality,
      pictureUrl: (personal['profilePicUrl'] ?? personal['pic_url'] ?? '').toString(),
      location: location,
      // 🆕 Pass new fields to constructor
      dob: dob,
      objectives: objectives,
      summary: summary,

      education: (firstEdu['majorSubjects'] ?? '').toString(),
      university: (firstEdu['institutionName'] ?? '').toString(),
      educationDuration: (firstEdu['duration'] ?? '').toString(),
      cgpa: (firstEdu['marksOrCgpa'] ?? '').toString(),
      currentRole: (firstExp['role'] ?? '').toString(),
      company: (firstExp['organization'] ?? '').toString(),
      experienceYears: experiences.length,
      professionalStatus: (professional['status'] ?? professional['professionalStatus'] ?? '').toString(),
      retirementDate: (professional['expectedRetirementDate'] ?? professional['retirementDate'] ?? '').toString(),
      skills: skills,
      socialLinks: (personal['socialLinks'] is List) ? (personal['socialLinks'] as List).map((e) => e.toString()).toList() : [],
      experiences: experiences,
      educations: educations,
      certifications: certifications,
      publications: (userData['publications'] is List) ? (userData['publications'] as List).map((e) => e.toString()).toList() : [],
      awards: (userData['awards'] is List) ? (userData['awards'] as List).map((e) => e.toString()).toList() : [],
      documents: (userData['documents'] is List) ? userData['documents'] : [],
      searchIndex: searchStr,
      // Add these two lines before the closing parenthesis:
      experienceDocuments: experienceDocuments,
      certificationDocuments: certificationDocuments,
    );
  }

  // Helper CopyWith (simplified for status updates)
  ApplicantRecord copyWith({String? status, JobData? jobData}) {
    return ApplicantRecord._(
      userId: userId,
      jobId: jobId,
      status: status ?? this.status,
      appliedAt: appliedAt,
      profileSnapshot: profileSnapshot,
      docId: docId,
      reference: reference,
      jobData: jobData ?? this.jobData,
      // Pass through existing pre-parsed data
      name: name,
      email: email,
      secondaryEmail: secondaryEmail,
      phone: phone,
      nationality: nationality,
      pictureUrl: pictureUrl,
      location: location,
      // 🆕 Persist new fields in copyWith
      dob: dob,
      objectives: objectives,
      summary: summary,
      education: education,
      university: university,
      educationDuration: educationDuration,
      cgpa: cgpa,
      currentRole: currentRole,
      company: company,
      experienceYears: experienceYears,
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
      matchScore: matchScore,
      searchIndex: searchIndex,
      // Add these two lines before the closing parenthesis:
      experienceDocuments: experienceDocuments,
      certificationDocuments: certificationDocuments,
    );
  }
}

// ==========================================
// 2. Job Data Model
// ==========================================

class JobData {
  final String jobId;
  final String title;
  final String company;
  final String location;
  final String jobType;
  final String workType;
  final double? salary;
  final dynamic experience;
  final List<String> requiredSkills;

  JobData({
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
}

// ==========================================
// 3. Optimized Provider
// ==========================================

class ApplicantsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State Management
  bool isLoading = true;
  String? error;
  String? _currentJobId;
  StreamSubscription<QuerySnapshot>? _subscription;
  Timer? _searchDebounce;

  // Data Containers
  List<ApplicantRecord> _allApplicants = [];
  List<ApplicantRecord> _filteredApplicants = [];

  // Selection
  final Set<String> selectedApplicantIds = {};

  // Caches
  final Map<String, JobData?> _jobDataCache = {};
  final Map<String, ApplicantRecord> _recordCache = {};
  final Map<String, int> _docHashCache = {};

  // Filters
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

  // Available options (Cached Sets)
  final Set<String> availableExperiences = {};
  final Set<String> availableLocations = {};
  final Set<String> availableEducations = {};
  final Set<String> availableJobs = {};
  final Set<String> availableSkills = {};
  final Set<String> availableNationalities = {};

  ApplicantsProvider() {
    _initRealtimeUpdates();
  }

  // Getters
  List<ApplicantRecord> get applicants => _filteredApplicants;
  List<ApplicantRecord> get allApplicants => _allApplicants;
  int get totalApplicants => _allApplicants.length;
  int get filteredCount => _filteredApplicants.length;

  int get pendingCount => _allApplicants.where((a) => a.status.toLowerCase() == 'pending').length;
  int get acceptedCount => _allApplicants.where((a) => a.status.toLowerCase() == 'accepted').length;
  int get rejectedCount => _allApplicants.where((a) => a.status.toLowerCase() == 'rejected').length;
  int get shortlistCount => _allApplicants.where((a) => a.status.toLowerCase() == 'shortlist').length;

  // Shortlist Getters
  List<ApplicantRecord> get shortlistedApplicants =>
      _allApplicants.where((a) => a.status.toLowerCase() == 'shortlist').toList();

  List<ApplicantRecord> getShortlistedForJob(String? jobId) {
    if (jobId == null || jobId.isEmpty) return shortlistedApplicants;
    return _allApplicants.where((a) => a.status.toLowerCase() == 'shortlist' && a.jobId == jobId).toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ==========================================
  // Core Logic: Realtime Updates
  // ==========================================

  void _initRealtimeUpdates() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      error = 'No user logged in';
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    _subscription?.cancel();

    Query query = _firestore.collectionGroup('applied_jobs');

    // Query-level optimization
    if (_currentJobId != null && _currentJobId!.isNotEmpty) {
      query = query.where('jobId', isEqualTo: _currentJobId);
    }
    query = query.orderBy('appliedAt', descending: true);

    _subscription = query.snapshots().listen((snapshot) async {
      // 1. Identify missing job data first
      final Set<String> neededJobIds = {};
      for (final doc in snapshot.docs) {
        final jId = doc.get('jobId') as String?;
        if (jId != null && !_jobDataCache.containsKey(jId)) {
          neededJobIds.add(jId);
        }
      }

      // 2. Batch fetch job data
      if (neededJobIds.isNotEmpty) {
        await _ensureJobDataCached(neededJobIds);
      }

      // 3. Process records with Hash Caching
      final List<ApplicantRecord> newRecordList = [];
      bool filtersNeedUpdate = false;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final currentHash = data.toString().hashCode;

        if (_recordCache.containsKey(doc.id) && _docHashCache[doc.id] == currentHash) {
          // No changes, use cache
          newRecordList.add(_recordCache[doc.id]!);
        } else {
          // Data changed or new, parse
          final jobId = data['jobId'] as String?;
          if (jobId != null && jobId.isNotEmpty) {
            final record = ApplicantRecord.fromSnapshot(doc, data, _jobDataCache[jobId]);
            _recordCache[doc.id] = record;
            _docHashCache[doc.id] = currentHash;
            newRecordList.add(record);
            filtersNeedUpdate = true;
          }
        }
      }

      _allApplicants = newRecordList;

      // 4. Garbage Collection
      if (_recordCache.length > _allApplicants.length) {
        final activeIds = _allApplicants.map((e) => e.docId).toSet();
        _recordCache.removeWhere((key, _) => !activeIds.contains(key));
        _docHashCache.removeWhere((key, _) => !activeIds.contains(key));
        filtersNeedUpdate = true;
      }

      if (filtersNeedUpdate || _filteredApplicants.isEmpty) {
        _populateFilterOptions();
        _applyFilters();
      } else {
        // If data didn't change structurally, just re-apply sorting/filtering to be safe
        _applyFilters();
      }

      isLoading = false;
      notifyListeners();

    }, onError: (e) {
      debugPrint('Stream Error: $e');
      error = e.toString();
      isLoading = false;
      notifyListeners();
    });
  }

  // ==========================================
  // Filtering Logic (Optimized)
  // ==========================================

  void _populateFilterOptions() {
    availableExperiences.clear();
    availableLocations.clear();
    availableEducations.clear();
    availableJobs.clear();
    availableSkills.clear();
    availableNationalities.clear();

    for (final applicant in _allApplicants) {
      if (applicant.jobData != null) availableJobs.add(applicant.jobData!.title);
      if (applicant.location.isNotEmpty) availableLocations.add(applicant.location);
      if (applicant.education.isNotEmpty) availableEducations.add(applicant.education);
      if (applicant.nationality.isNotEmpty) availableNationalities.add(applicant.nationality);
      availableSkills.addAll(applicant.skills);

      // Calculate experience bucket once
      final y = applicant.experienceYears;
      if (y == 0) availableExperiences.add('Entry Level');
      else if (y <= 2) availableExperiences.add('1-2 years');
      else if (y <= 5) availableExperiences.add('3-5 years');
      else if (y <= 10) availableExperiences.add('6-10 years');
      else availableExperiences.add('10+ years');
    }
  }

  void _applyFilters() {
    final searchLower = searchQuery.toLowerCase();

    // Using simple boolean flags for checks is faster than string comparison in loop
    final bool checkStatus = statusFilter != 'All';
    final bool checkJob = jobFilter != 'All';
    final bool checkLoc = locationFilter != 'All';
    final bool checkEdu = educationFilter != 'All';
    final bool checkNat = nationalityFilter != 'All';
    final bool checkProf = professionalStatusFilter != 'All';
    final bool checkSkills = skillsFilter.isNotEmpty;
    final bool checkDate = appliedDateRange != null;
    final bool checkSearch = searchLower.isNotEmpty;

    _filteredApplicants = _allApplicants.where((applicant) {
      // 1. Search (Fastest fail check via pre-computed index)
      if (checkSearch && !applicant.searchIndex.contains(searchLower)) return false;

      // 2. Direct Equality Checks (Fast)
      if (checkStatus && applicant.status.toLowerCase() != statusFilter.toLowerCase()) return false;
      if (checkJob && applicant.jobData?.title != jobFilter) return false;
      if (checkLoc && applicant.location != locationFilter) return false;
      if (checkEdu && applicant.education != educationFilter) return false;
      if (checkNat && applicant.nationality != nationalityFilter) return false;
      if (checkProf && applicant.professionalStatus.toLowerCase() != professionalStatusFilter.toLowerCase()) return false;

      // 3. Range & Boolean Checks
      if (applicant.experienceYears < experienceYearsRange.start || applicant.experienceYears > experienceYearsRange.end) return false;
      if (hasCertifications && applicant.certifications.isEmpty) return false;
      if (hasPublications && applicant.publications.isEmpty) return false;
      if (hasAwards && applicant.awards.isEmpty) return false;

      // 4. Experience Category Check
      if (experienceFilter != 'All') {
        final y = applicant.experienceYears;
        String level = y == 0 ? 'Entry Level' : y <= 2 ? '1-2 years' : y <= 5 ? '3-5 years' : y <= 10 ? '6-10 years' : '10+ years';
        if (level != experienceFilter) return false;
      }

      // 5. Retirement Check (Complex Calculation)
      if (retirementStatusFilter != 'All') {
        if (applicant.retirementDate.isEmpty) return false;
        try {
          final diff = DateTime.parse(applicant.retirementDate).difference(DateTime.now()).inDays / 365;
          bool match = false;
          if (retirementStatusFilter == 'Within 1 Year') match = diff <= 1 && diff >= 0;
          else if (retirementStatusFilter == '1-3 Years') match = diff > 1 && diff <= 3;
          else if (retirementStatusFilter == '3-5 Years') match = diff > 3 && diff <= 5;
          else if (retirementStatusFilter == '5+ Years') match = diff > 5;
          if (!match) return false;
        } catch (_) { return false; }
      }

      // 6. Skills (Array intersection - costliest check, do last)
      if (checkSkills) {
        for (final skill in skillsFilter) {
          if (!applicant.skills.contains(skill)) return false;
        }
      }

      // 7. Date Range
      if (checkDate) {
        if (applicant.appliedAt.isBefore(appliedDateRange!.start) ||
            applicant.appliedAt.isAfter(appliedDateRange!.end.add(const Duration(days: 1)))) return false;
      }

      return true;
    }).toList();

    _applySorting();
  }

  void _applySorting() {
    if (_filteredApplicants.isEmpty) return;

    // Sort in place is more memory efficient
    switch (sortBy) {
      case 'applied_desc': _filteredApplicants.sort((a, b) => b.appliedAt.compareTo(a.appliedAt)); break;
      case 'applied_asc': _filteredApplicants.sort((a, b) => a.appliedAt.compareTo(b.appliedAt)); break;
      case 'name_asc': _filteredApplicants.sort((a, b) => a.name.compareTo(b.name)); break;
      case 'name_desc': _filteredApplicants.sort((a, b) => b.name.compareTo(a.name)); break;
      case 'experience_desc': _filteredApplicants.sort((a, b) => b.experienceYears.compareTo(a.experienceYears)); break;
    }
  }

  // ==========================================
  // Public Actions
  // ==========================================

  void toggleSelection(String applicantId) {
    if (selectedApplicantIds.contains(applicantId)) selectedApplicantIds.remove(applicantId);
    else selectedApplicantIds.add(applicantId);
    notifyListeners();
  }

  void selectAll(List<ApplicantRecord> applicants) {
    selectedApplicantIds.clear();
    selectedApplicantIds.addAll(applicants.map((a) => a.userId));
    notifyListeners();
  }

  void clearSelection() {
    selectedApplicantIds.clear();
    notifyListeners();
  }

  bool isSelected(String applicantId) => selectedApplicantIds.contains(applicantId);

  // Filter Updates
  void updateSearchQuery(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    if (query.isEmpty) {
      searchQuery = '';
      _applyFilters();
      notifyListeners();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      searchQuery = query;
      _applyFilters();
      notifyListeners();
    });
  }

  // Setter helpers to reduce boilerplate
  void _updateFilter(VoidCallback update) {
    update();
    _applyFilters();
    notifyListeners();
  }

  void updateStatusFilter(String s) => _updateFilter(() => statusFilter = s);
  void updateJobFilter(String j) => _updateFilter(() => jobFilter = j);
  void updateExperienceFilter(String e) => _updateFilter(() => experienceFilter = e);
  void updateLocationFilter(String l) => _updateFilter(() => locationFilter = l);
  void updateEducationFilter(String e) => _updateFilter(() => educationFilter = e);
  void updateNationalityFilter(String n) => _updateFilter(() => nationalityFilter = n);
  void updateProfessionalStatusFilter(String s) => _updateFilter(() => professionalStatusFilter = s);
  void updateRetirementStatusFilter(String s) => _updateFilter(() => retirementStatusFilter = s);
  void updateSkillsFilter(List<String> s) => _updateFilter(() => skillsFilter = s);
  void updateAppliedDateRange(DateTimeRange? r) => _updateFilter(() => appliedDateRange = r);
  void updateExperienceYearsRange(RangeValues r) => _updateFilter(() => experienceYearsRange = r);
  void updateHasCertifications(bool b) => _updateFilter(() => hasCertifications = b);
  void updateHasPublications(bool b) => _updateFilter(() => hasPublications = b);
  void updateHasAwards(bool b) => _updateFilter(() => hasAwards = b);
  void updateSorting(String s) => _updateFilter(() => sortBy = s);

  void clearAllFilters() {
    searchQuery = '';
    statusFilter = 'All';
    jobFilter = 'All';
    experienceFilter = 'All';
    locationFilter = 'All';
    educationFilter = 'All';
    nationalityFilter = 'All';
    professionalStatusFilter = 'All';
    retirementStatusFilter = 'All';
    skillsFilter.clear();
    appliedDateRange = null;
    experienceYearsRange = const RangeValues(0, 30);
    hasCertifications = false;
    hasPublications = false;
    hasAwards = false;
    sortBy = 'applied_desc';
    _applyFilters();
    notifyListeners();
  }

  Future<void> updateApplicationStatus(String applicantUserId, String docId, String newStatus) async {
    try {
      final index = _allApplicants.indexWhere((a) => a.userId == applicantUserId && a.docId == docId);
      if (index != -1) {
        final original = _allApplicants[index];
        // Only update the status field using copyWith
        final updated = original.copyWith(status: newStatus);

        _allApplicants[index] = updated;
        _recordCache[docId] = updated;

        _applyFilters();
        notifyListeners();

        await original.reference.update({'status': newStatus});
      }
    } catch (e) {
      error = 'Failed to update status: $e';
      notifyListeners();
    }
  }

  // 🆕 Sending Logic (Optimized for safe access)
  Future<String?> sendSelectedCandidatesToAdmin({String? notes}) async {
    if (selectedApplicantIds.isEmpty) return null;

    final recruiter = _auth.currentUser;
    if (recruiter == null) {
      error = 'Not authenticated';
      notifyListeners();
      return null;
    }

    final selectedApplicants = _allApplicants
        .where((a) => selectedApplicantIds.contains(a.userId))
        .toList();

    if (selectedApplicants.isEmpty) return null;

    final List<String> candidateIds = [];
    final List<Map<String, dynamic>> candidateMaps = [];

    for (final app in selectedApplicants) {
      candidateIds.add(app.userId);

      // Build complete candidate data map
      candidateMaps.add({
        // Basic Info
        'uid': app.userId,
        'name': app.name,
        'email': app.email,
        'phone': app.phone,
        'nationality': app.nationality,
        'picture_url': app.pictureUrl,
        'location': app.location,
        'dob': app.dob,
        'secondary_email': app.secondaryEmail,

        // Job Application Info
        'job_id': app.jobId,
        'job_title': app.jobData?.title ?? '',
        'applied_at': app.appliedAt.toIso8601String(),
        'status': app.status,
        'match_score': app.matchScore,

        // Professional Info
        'professional_status': app.professionalStatus,
        'retirement_date': app.retirementDate,
        'summary': app.summary,
        'objectives': app.objectives,

        // Experience & Education
        'experience_years': app.experienceYears,
        'current_role': app.currentRole,
        'company': app.company,
        'education': app.education,
        'university': app.university,
        'education_duration': app.educationDuration,
        'cgpa': app.cgpa,

        // Collections
        'skills': app.skills,
        'social_links': app.socialLinks,
        'certifications': app.certifications,
        'publications': app.publications,
        'awards': app.awards,

        // Detailed Profiles (Full Arrays)
        'professionalExperience': app.experiences,
        'educationalProfile': app.educations,

        // Documents
        'documents': app.documents,
        'experienceDocuments': app.experienceDocuments,
        'certificationDocuments': app.certificationDocuments,

        // Full Profile Snapshot (for admin to access raw data)
        'profileSnapshot': app.profileSnapshot,
      });
    }

    try {
      final reqDoc = _firestore.collection('recruiter_requests').doc();
      await reqDoc.set({
        'request_id': reqDoc.id,
        'recruiter_id': recruiter.uid,
        'recruiter_email': recruiter.email ?? '',
        'created_at': FieldValue.serverTimestamp(),
        'notes': (notes ?? '').trim(),
        'total_candidates': candidateIds.length,
        'status': 'pending',
        'candidate_ids': candidateIds,
        'candidates': candidateMaps,
        'request_type': 'candidate_submission',
        'source': 'shortlist_view',
      });

      clearSelection();
      return reqDoc.id;
    } catch (e) {
      error = 'Failed to send: $e';
      notifyListeners();
      return null;
    }
  }
  void refresh({String? jobId}) {
    if (_currentJobId != jobId) {
      _currentJobId = jobId;
      _jobDataCache.clear();
      _recordCache.clear();
      _docHashCache.clear();
    }
    _initRealtimeUpdates();
  }

  // ==========================================
  // Private Helpers
  // ==========================================

  Future<void> _ensureJobDataCached(Set<String> jobIds) async {
    final futures = jobIds.map((id) => _fetchAndCacheJob(id));
    await Future.wait(futures);
  }

  Future<void> _fetchAndCacheJob(String jobId) async {
    if (_jobDataCache.containsKey(jobId)) return;
    try {
      final doc = await _firestore.collection('Posted_jobs_public').doc(jobId).get();
      if (!doc.exists) {
        _jobDataCache[jobId] = null;
        return;
      }
      final data = doc.data() ?? {};

      // Parse Salary
      double? salary;
      if (data['salary'] is num) salary = (data['salary'] as num).toDouble();
      else if (data['salary'] is String) {
        final match = RegExp(r'[\d,]+').firstMatch(data['salary']);
        if (match != null) salary = double.tryParse(match.group(0)?.replaceAll(',', '') ?? '');
      }

      _jobDataCache[jobId] = JobData(
        jobId: jobId,
        title: data['title']?.toString() ?? 'Unknown',
        company: data['company']?.toString() ?? '',
        location: data['location']?.toString() ?? '',
        jobType: data['job_type']?.toString() ?? '',
        workType: data['workModes']?.toString() ?? '',
        salary: salary,
        experience: data['experience'],
        requiredSkills: (data['required_skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );
    } catch (_) {
      _jobDataCache[jobId] = null;
    }
  }
}