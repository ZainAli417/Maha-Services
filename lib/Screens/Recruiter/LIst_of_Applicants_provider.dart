import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ==========================================
// 1. Applicant Record Model
// ==========================================

class ApplicantRecord {
  final String userId;
  final String jobId;
  final String status;
  final DateTime appliedAt;
  final Map<String, dynamic> profileSnapshot;
  final String docId;
  final JobData? jobData;
  final DocumentReference reference; // Store reference for easy updates

  ApplicantRecord({
    required this.userId,
    required this.jobId,
    required this.status,
    required this.appliedAt,
    required this.profileSnapshot,
    required this.docId,
    required this.reference,
    this.jobData,
  });

  // --- Profile Helpers ---

  Map<String, dynamic> get _acct {
    final m = profileSnapshot['user_Account_Data'] ?? <String, dynamic>{};
    return (m is Map) ? Map<String, dynamic>.from(m) : <String, dynamic>{};
  }

  Map<String, dynamic> get _personal {
    final p = _acct['personalProfile'] ?? <String, dynamic>{};
    return (p is Map) ? Map<String, dynamic>.from(p) : <String, dynamic>{};
  }

  Map<String, dynamic> get _professional {
    final p = _acct['professionalProfile'] ?? <String, dynamic>{};
    return (p is Map) ? Map<String, dynamic>.from(p) : <String, dynamic>{};
  }

  List<Map<String, dynamic>> get _educational {
    final e = _acct['educationalProfile'];
    if (e == null) return [];
    if (e is List) {
      return e.map((item) => (item is Map) ? Map<String, dynamic>.from(item) : <String, dynamic>{}).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> get _experience {
    final e = _acct['professionalExperience'];
    if (e == null) return [];
    if (e is List) {
      return e.map((item) {
        if (item is Map) {
          final mapped = Map<String, dynamic>.from(item);
          return {
            'organization': mapped['organization'] ?? mapped['company'] ?? '',
            'duration': mapped['duration'] ?? '',
            'role': mapped['role'] ?? '',
            'duties': mapped['duties'] ?? mapped['text'] ?? '',
            'text': mapped['text'] ?? mapped['duties'] ?? '',
          };
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  // --- Getters ---

  String get name => _personal['name']?.toString() ?? 'Unknown';
  String get email => _personal['email']?.toString() ?? '';
  String get secondaryEmail => _personal['secondary_email']?.toString() ?? '';
  String get phone => _personal['contactNumber']?.toString() ?? '';
  String get nationality => _personal['nationality']?.toString() ?? '';
  String get pictureUrl => _personal['profilePicUrl']?.toString() ?? '';
  String get dob => _personal['dob']?.toString() ?? '';
  String get objectives => _personal['objectives']?.toString() ?? '';
  String get summary => _personal['summary']?.toString() ?? '';
  String get professionalSummary => _professional['summary']?.toString() ?? '';
  String get location => _personal['location']?.toString() ?? '';

  List<String> get skills {
    final s = _personal['skills'];
    return (s is List) ? s.map((e) => e.toString()).toList() : [];
  }

  List<String> get socialLinks {
    final s = _personal['socialLinks'];
    return (s is List) ? s.map((e) => e.toString()).toList() : [];
  }

  // Education
  String get education => _educational.isNotEmpty ? (_educational.first['majorSubjects']?.toString() ?? '') : '';
  String get university => _educational.isNotEmpty ? (_educational.first['institutionName']?.toString() ?? '') : '';
  String get educationDuration => _educational.isNotEmpty ? (_educational.first['duration']?.toString() ?? '') : '';
  String get cgpa => _educational.isNotEmpty ? (_educational.first['marksOrCgpa']?.toString() ?? '') : '';
  List<Map<String, dynamic>> get educations => _educational;

  // Experience
  List<Map<String, dynamic>> get experiences => _experience;
  int get experienceYears => _experience.length;
  String get company {
    if (_experience.isEmpty) return '';
    final first = _experience.first;
    return first['organization']?.toString() ?? first['text']?.toString() ?? '';
  }
  String get currentRole => _experience.isNotEmpty ? (_experience.first['role']?.toString() ?? '') : '';
  String get experienceDuration => _experience.isNotEmpty ? (_experience.first['duration']?.toString() ?? '') : '';

  // Certifications
  List<Map<String, String>> get certifications {
    final c = _acct['certifications'];
    if (c is! List) return [];
    return c.map((item) {
      if (item is Map) {
        return {
          'organization': (item['organization'] ?? '').toString(),
          'name': (item['name'] ?? item['certName'] ?? '').toString(),
        };
      }
      if (item is String && item.isNotEmpty) return {'organization': '', 'name': item};
      return {'organization': '', 'name': ''};
    }).where((cert) => cert['name']!.isNotEmpty).toList();
  }

  // Other Arrays
  List<String> get publications => (_acct['publications'] is List) ? (_acct['publications'] as List).map((e) => e.toString()).toList() : [];
  List<String> get awards => (_acct['awards'] is List) ? (_acct['awards'] as List).map((e) => e.toString()).toList() : [];
  List<String> get references => (_acct['references'] is List) ? (_acct['references'] as List).map((e) => e.toString()).toList() : [];
  List<dynamic> get documents => (_acct['documents'] is List) ? _acct['documents'] : [];
  List<String> get languages => []; // Placeholder as per original

  // Computed / Logic
  double get expectedSalary => 0.0;
  String get availability => '';
  String get workType => '';
  String get bio => summary;

  String get linkedIn => socialLinks.firstWhere((link) => link.contains('linkedin'), orElse: () => '');
  String get github => socialLinks.firstWhere((link) => link.contains('github'), orElse: () => '');

  String get cvUrl {
    if (documents.isNotEmpty && documents.first is Map) {
      return documents.first['url']?.toString() ?? '';
    }
    return '';
  }

  // CopyWith
  ApplicantRecord copyWith({
    String? userId,
    String? jobId,
    String? status,
    DateTime? appliedAt,
    Map<String, dynamic>? profileSnapshot,
    String? docId,
    JobData? jobData,
    DocumentReference? reference,
  }) {
    return ApplicantRecord(
      userId: userId ?? this.userId,
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      profileSnapshot: profileSnapshot ?? this.profileSnapshot,
      docId: docId ?? this.docId,
      reference: reference ?? this.reference,
      jobData: jobData ?? this.jobData,
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

  // Data Containers
  List<ApplicantRecord> _allApplicants = [];
  List<ApplicantRecord> _filteredApplicants = [];
  final Map<String, JobData?> _jobDataCache = {}; // Cache to prevent redundant job fetches

  // Filters
  String searchQuery = '';
  String statusFilter = 'All';
  String experienceFilter = 'All';
  String locationFilter = 'All';
  String educationFilter = 'All';
  String availabilityFilter = 'All';
  String workTypeFilter = 'All';
  String jobFilter = 'All';
  List<String> skillsFilter = [];
  List<String> languagesFilter = [];
  double minExpectedSalary = 0;
  double maxExpectedSalary = 1000000;
  DateTimeRange? appliedDateRange;
  String sortBy = 'applied_desc';

  // Available options for UI Dropdowns
  Set<String> availableExperiences = {};
  Set<String> availableLocations = {};
  Set<String> availableEducations = {};
  Set<String> availableAvailabilities = {};
  Set<String> availableWorkTypes = {};
  Set<String> availableSkills = {};
  Set<String> availableLanguages = {};
  Set<String> availableJobs = {};

  ApplicantsProvider() {
    _initRealtimeUpdates();
  }

  // Getters
  List<ApplicantRecord> get applicants => _filteredApplicants;
  List<ApplicantRecord> get allApplicants => _allApplicants;

  int get totalApplicants => _allApplicants.length;
  int get filteredCount => _filteredApplicants.length;
  int get pendingCount => _allApplicants.where((a) => a.status == 'pending').length;
  int get acceptedCount => _allApplicants.where((a) => a.status == 'accepted').length;
  int get rejectedCount => _allApplicants.where((a) => a.status == 'rejected').length;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Initialize the Real-time Listener (Optimized Collection Group Query)
  void _initRealtimeUpdates() {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        error = 'No user logged in';
        isLoading = false;
        notifyListeners();
        return;
      }

      isLoading = true;
      notifyListeners();

      // Cancel previous subscription if any
      _subscription?.cancel();

      // ⚡ OPTIMIZATION: Collection Group Query
      // Queries ALL 'applied_jobs' collections across the entire DB at once.
      // NOTE: This may require a Firestore Index. Check debug console for link if it fails.
      Query query = _firestore.collectionGroup('applied_jobs');

      if (_currentJobId != null && _currentJobId!.isNotEmpty) {
        query = query.where('jobId', isEqualTo: _currentJobId);
      }

      // Order by appliedAt for consistent stream results
      query = query.orderBy('appliedAt', descending: true);

      debugPrint('🔌 Subscribing to applications stream... JobId: $_currentJobId');

      _subscription = query.snapshots().listen((snapshot) async {
        debugPrint('⚡ Stream Update: Received ${snapshot.docs.length} applications');

        // 1. Map documents to temporary records (some data might wait for async job fetch)
        final List<ApplicantRecord> tempRecords = [];

        // Collect all unique Job IDs needed for this batch
        final Set<String> neededJobIds = {};

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final jobId = data['jobId'] as String?;
          if (jobId != null) neededJobIds.add(jobId);
        }

        // 2. Pre-fetch unknown JobData in parallel
        await _ensureJobDataCached(neededJobIds);

        // 3. Construct Records
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final jobId = data['jobId'] as String?;

            if (jobId == null || jobId.isEmpty) continue;

            // Extract User ID safely from path structure:
            // Path: applications/{userId}/applied_jobs/{docId}
            // Parent: applied_jobs (Collection) -> Parent: applications/{userId} (Doc)
            final parentDoc = doc.reference.parent.parent;
            final userId = parentDoc?.id ?? 'unknown_user';

            // Parse Dates
            DateTime appliedAt;
            final rawDate = data['appliedAt'];
            if (rawDate is Timestamp) appliedAt = rawDate.toDate();
            else if (rawDate is String) appliedAt = DateTime.tryParse(rawDate) ?? DateTime.now();
            else appliedAt = DateTime.now();

            // Parse Profile
            Map<String, dynamic> profileSnapshot = _cleanProfileSnapshot(data['profileSnapshot']);

            // Add Score if present
            if (data['match_score'] is Map) {
              profileSnapshot['match_score'] = Map<String, dynamic>.from(data['match_score']);
            }

            tempRecords.add(ApplicantRecord(
              userId: userId,
              jobId: jobId,
              status: (data['status'] as String?) ?? 'pending',
              appliedAt: appliedAt,
              profileSnapshot: profileSnapshot,
              docId: doc.id,
              reference: doc.reference, // Store ref for updates
              jobData: _jobDataCache[jobId],
            ));
          } catch (e) {
            debugPrint('❌ Error parsing doc ${doc.id}: $e');
          }
        }

        _allApplicants = tempRecords;
        _populateFilterOptions();
        _applyFilters();

        isLoading = false;
        notifyListeners();

      }, onError: (e) {
        debugPrint('❌ Stream Error: $e');
        error = e.toString();
        isLoading = false;
        notifyListeners();
      });

    } catch (e) {
      debugPrint('❌ Init Error: $e');
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  /// Ensures JobData is available in `_jobDataCache` for the given IDs.
  Future<void> _ensureJobDataCached(Set<String> jobIds) async {
    final List<Future<void>> futures = [];

    for (final id in jobIds) {
      if (!_jobDataCache.containsKey(id)) {
        futures.add(_fetchAndCacheJob(id));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _fetchAndCacheJob(String jobId) async {
    try {
      final doc = await _firestore.collection('Posted_jobs_public').doc(jobId).get();
      if (!doc.exists) {
        _jobDataCache[jobId] = null;
        return;
      }

      final data = doc.data() ?? {};

      // Parse Salary
      double? salary;
      final sRaw = data['salary'];
      if (sRaw is num) salary = sRaw.toDouble();
      else if (sRaw is String) {
        final match = RegExp(r'[\d,]+').firstMatch(sRaw);
        if (match != null) salary = double.tryParse(match.group(0)?.replaceAll(',', '') ?? '');
      }

      final job = JobData(
        jobId: jobId,
        title: data['title']?.toString() ?? 'Unknown Job',
        company: data['company']?.toString() ?? '',
        location: data['location']?.toString() ?? '',
        jobType: data['job_type']?.toString() ?? '',
        workType: data['workModes']?.toString() ?? '',
        salary: salary,
        experience: data['experience'],
        requiredSkills: (data['required_skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

      _jobDataCache[jobId] = job;
    } catch (e) {
      debugPrint('❌ Error fetching job $jobId: $e');
      _jobDataCache[jobId] = null;
    }
  }

  Map<String, dynamic> _cleanProfileSnapshot(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('user_Account_Data')) return data;
      return {'user_Account_Data': data};
    }
    return {'user_Account_Data': {}};
  }

  // ==========================================
  // Filter Logic (Kept largely identical but optimized)
  // ==========================================

  void _populateFilterOptions() {
    availableExperiences.clear();
    availableLocations.clear();
    availableEducations.clear();
    availableAvailabilities.clear();
    availableWorkTypes.clear();
    availableSkills.clear();
    availableLanguages.clear();
    availableJobs.clear();

    for (final applicant in _allApplicants) {
      if (applicant.jobData?.title.isNotEmpty == true) {
        availableJobs.add(applicant.jobData!.title);
      }

      if (applicant.location.isNotEmpty) availableLocations.add(applicant.location);
      if (applicant.education.isNotEmpty) availableEducations.add(applicant.education);

      // Determine exp bucket
      final y = applicant.experienceYears;
      if (y == 0) availableExperiences.add('Entry Level');
      else if (y <= 2) availableExperiences.add('1-2 years');
      else if (y <= 5) availableExperiences.add('3-5 years');
      else if (y <= 10) availableExperiences.add('6-10 years');
      else availableExperiences.add('10+ years');

      availableSkills.addAll(applicant.skills);
    }
  }

  void _applyFilters() {
    _filteredApplicants = _allApplicants.where((applicant) {
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final text = '${applicant.name} ${applicant.email} ${applicant.company} ${applicant.skills.join(' ')}'.toLowerCase();
        if (!text.contains(query)) return false;
      }

      if (statusFilter != 'All' && applicant.status != statusFilter) return false;
      if (jobFilter != 'All' && applicant.jobData?.title != jobFilter) return false;
      if (locationFilter != 'All' && applicant.location != locationFilter) return false;
      if (educationFilter != 'All' && applicant.education != educationFilter) return false;

      // Experience Filter
      if (experienceFilter != 'All') {
        final y = applicant.experienceYears;
        String level;
        if (y == 0) level = 'Entry Level';
        else if (y <= 2) level = '1-2 years';
        else if (y <= 5) level = '3-5 years';
        else if (y <= 10) level = '6-10 years';
        else level = '10+ years';
        if (level != experienceFilter) return false;
      }

      if (skillsFilter.isNotEmpty) {
        if (!skillsFilter.every((s) => applicant.skills.contains(s))) return false;
      }

      if (appliedDateRange != null) {
        if (applicant.appliedAt.isBefore(appliedDateRange!.start) ||
            applicant.appliedAt.isAfter(appliedDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();

    _applySorting();
  }

  void _applySorting() {
    switch (sortBy) {
      case 'applied_desc': _filteredApplicants.sort((a, b) => b.appliedAt.compareTo(a.appliedAt)); break;
      case 'applied_asc': _filteredApplicants.sort((a, b) => a.appliedAt.compareTo(b.appliedAt)); break;
      case 'name_asc': _filteredApplicants.sort((a, b) => a.name.compareTo(b.name)); break;
      case 'name_desc': _filteredApplicants.sort((a, b) => b.name.compareTo(a.name)); break;
      case 'experience_desc': _filteredApplicants.sort((a, b) => b.experienceYears.compareTo(a.experienceYears)); break;
    }
  }

  // ==========================================
  // Public Methods / Actions
  // ==========================================

  void updateSearchQuery(String query) { searchQuery = query; _applyFilters(); notifyListeners(); }
  void updateStatusFilter(String status) { statusFilter = status; _applyFilters(); notifyListeners(); }
  void updateJobFilter(String job) { jobFilter = job; _applyFilters(); notifyListeners(); }
  void updateExperienceFilter(String exp) { experienceFilter = exp; _applyFilters(); notifyListeners(); }
  void updateLocationFilter(String loc) { locationFilter = loc; _applyFilters(); notifyListeners(); }
  void updateEducationFilter(String edu) { educationFilter = edu; _applyFilters(); notifyListeners(); }
  void updateSkillsFilter(List<String> skills) { skillsFilter = skills; _applyFilters(); notifyListeners(); }
  void updateAppliedDateRange(DateTimeRange? range) { appliedDateRange = range; _applyFilters(); notifyListeners(); }
  void updateSorting(String sorting) { sortBy = sorting; _applySorting(); notifyListeners(); }

  void clearAllFilters() {
    searchQuery = '';
    statusFilter = 'All';
    jobFilter = 'All';
    experienceFilter = 'All';
    locationFilter = 'All';
    skillsFilter.clear();
    appliedDateRange = null;
    sortBy = 'applied_desc';
    _applyFilters();
    notifyListeners();
  }

  bool get hasActiveFilters => searchQuery.isNotEmpty || statusFilter != 'All' || jobFilter != 'All' || experienceFilter != 'All' || skillsFilter.isNotEmpty;

  /// Update Application Status (Optimized)
  /// Uses the direct DocumentReference stored in the Record, saving a lookup.
  Future<void> updateApplicationStatus(String applicantUserId, String docId, String newStatus) async {
    try {
      final applicant = _allApplicants.firstWhere(
            (a) => a.userId == applicantUserId && a.docId == docId,
        orElse: () => throw Exception('Applicant not found in local list'),
      );

      // Optimistic Update (Immediate UI reflection)
      // Note: Real update comes via stream, but this makes UI snappy immediately
      // We rely on stream for the source of truth, but we can animate quickly if needed.
      await applicant.reference.update({'status': newStatus});

      debugPrint('✅ Status updated to $newStatus for doc $docId');
    } catch (e) {
      error = 'Failed to update status: $e';
      notifyListeners();
    }
  }

  /// Reload logic with optional Job ID filter
  void refresh({String? jobId}) {
    debugPrint('🔄 Refreshing stream for job: $jobId');
    _currentJobId = jobId;
    _initRealtimeUpdates(); // Re-initializes the stream
  }
}