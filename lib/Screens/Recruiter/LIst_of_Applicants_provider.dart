import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplicantRecord {
  final String userId;
  final String jobId;
  final String status;
  final DateTime appliedAt;
  final Map<String, dynamic> profileSnapshot;
  final String docId;
  final JobData? jobData;

  ApplicantRecord({
    required this.userId,
    required this.jobId,
    required this.status,
    required this.appliedAt,
    required this.profileSnapshot,
    required this.docId,
    this.jobData,
  });

  // Helper to read user_Account_Data
  Map<String, dynamic> get _acct {
    final m = profileSnapshot['user_Account_Data'] ?? <String, dynamic>{};
    return (m is Map) ? Map<String, dynamic>.from(m) : <String, dynamic>{};
  }

  // Helper to read personalProfile
  Map<String, dynamic> get _personal {
    final p = _acct['personalProfile'] ?? <String, dynamic>{};
    return (p is Map) ? Map<String, dynamic>.from(p) : <String, dynamic>{};
  }

  // Helper to read professionalProfile
  Map<String, dynamic> get _professional {
    final p = _acct['professionalProfile'] ?? <String, dynamic>{};
    return (p is Map) ? Map<String, dynamic>.from(p) : <String, dynamic>{};
  }

  // Helper to read educationalProfile (array)
  List<Map<String, dynamic>> get _educational {
    final e = _acct['educationalProfile'];
    if (e == null) return [];
    if (e is List) {
      return e.map((item) => (item is Map) ? Map<String, dynamic>.from(item) : <String, dynamic>{}).toList();
    }
    return [];
  }

  // Helper to read professionalExperience (array)
  List<Map<String, dynamic>> get _experience {
    final e = _acct['professionalExperience'];
    if (e == null) return [];
    if (e is List) {
      return e.map((item) => (item is Map) ? Map<String, dynamic>.from(item) : <String, dynamic>{}).toList();
    }
    return [];
  }

  String get name {
    try {
      return _personal['name']?.toString() ?? 'Unknown';
    } catch (e) {
      debugPrint('Error getting name: $e');
      return 'Unknown';
    }
  }

  String get email {
    try {
      return _personal['email']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting email: $e');
      return '';
    }
  }

  String get secondaryEmail {
    try {
      return _personal['secondary_email']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting secondary_email: $e');
      return '';
    }
  }

  String get phone {
    try {
      return _personal['contactNumber']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting phone: $e');
      return '';
    }
  }

  String get nationality {
    try {
      return _personal['nationality']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting nationality: $e');
      return '';
    }
  }

  String get pictureUrl {
    try {
      return _personal['profilePicUrl']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting pictureUrl: $e');
      return '';
    }
  }

  String get dob {
    try {
      return _personal['dob']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting dob: $e');
      return '';
    }
  }

  String get objectives {
    try {
      return _personal['objectives']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting objectives: $e');
      return '';
    }
  }

  String get summary {
    try {
      return _personal['summary']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting summary: $e');
      return '';
    }
  }

  String get professionalSummary {
    try {
      return _professional['summary']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting professional summary: $e');
      return '';
    }
  }

  List<String> get skills {
    try {
      final s = _personal['skills'];
      if (s == null) return [];
      if (s is List) return s.map((e) => e.toString()).toList();
      return [];
    } catch (e) {
      debugPrint('Error getting skills: $e');
      return [];
    }
  }

  List<String> get socialLinks {
    try {
      final s = _personal['socialLinks'];
      if (s == null) return [];
      if (s is List) return s.map((e) => e.toString()).toList();
      return [];
    } catch (e) {
      debugPrint('Error getting socialLinks: $e');
      return [];
    }
  }

  // Education getters
  String get education {
    try {
      if (_educational.isEmpty) return '';
      final first = _educational.first;
      return first['majorSubjects']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting education: $e');
      return '';
    }
  }

  String get university {
    try {
      if (_educational.isEmpty) return '';
      final first = _educational.first;
      return first['institutionName']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting university: $e');
      return '';
    }
  }

  String get educationDuration {
    try {
      if (_educational.isEmpty) return '';
      final first = _educational.first;
      return first['duration']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting education duration: $e');
      return '';
    }
  }

  String get cgpa {
    try {
      if (_educational.isEmpty) return '';
      final first = _educational.first;
      return first['marksOrCgpa']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting cgpa: $e');
      return '';
    }
  }

  List<Map<String, dynamic>> get educations {
    return _educational;
  }

  // Professional Experience
  List<Map<String, dynamic>> get experiences {
    return _experience;
  }

  int get experienceYears {
    try {
      return _experience.length;
    } catch (e) {
      debugPrint('Error getting experience years: $e');
      return 0;
    }
  }

  String get company {
    try {
      if (_experience.isEmpty) return '';
      final first = _experience.first;
      return first['text']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting company: $e');
      return '';
    }
  }

  String get location {
    try {
      return _personal['location']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error getting location: $e');
      return '';
    }
  }

  List<String> get certifications {
    try {
      final c = _acct['certifications'];
      if (c == null) return [];
      if (c is List) return c.map((e) => e.toString()).toList();
      return [];
    } catch (e) {
      debugPrint('Error getting certifications: $e');
      return [];
    }
  }

  List<String> get publications {
    try {
      final p = _acct['publications'];
      if (p == null) return [];
      if (p is List) return p.map((e) => e.toString()).toList();
      return [];
    } catch (e) {
      debugPrint('Error getting publications: $e');
      return [];
    }
  }

  List<String> get awards {
    try {
      final a = _acct['awards'];
      if (a == null) return [];
      if (a is List) return a.map((e) => e.toString()).toList();
      return [];
    } catch (e) {
      debugPrint('Error getting awards: $e');
      return [];
    }
  }

  List<String> get references {
    try {
      final r = _acct['references'];
      if (r == null) return [];
      if (r is List) return r.map((e) => e.toString()).toList();
      return [];
    } catch (e) {
      debugPrint('Error getting references: $e');
      return [];
    }
  }

  List<dynamic> get documents {
    try {
      final d = _acct['documents'];
      if (d == null) return [];
      if (d is List) return d;
      return [];
    } catch (e) {
      debugPrint('Error getting documents: $e');
      return [];
    }
  }

  double get expectedSalary {
    try {
      return 0.0;
    } catch (e) {
      debugPrint('Error getting salary: $e');
      return 0.0;
    }
  }

  String get availability {
    try {
      return '';
    } catch (e) {
      debugPrint('Error getting availability: $e');
      return '';
    }
  }

  String get workType {
    try {
      return '';
    } catch (e) {
      debugPrint('Error getting work_type: $e');
      return '';
    }
  }

  String get bio {
    return summary;
  }

  String get linkedIn {
    try {
      final links = socialLinks;
      for (final link in links) {
        if (link.contains('linkedin')) return link;
      }
      return '';
    } catch (e) {
      debugPrint('Error getting linkedin: $e');
      return '';
    }
  }

  String get github {
    try {
      final links = socialLinks;
      for (final link in links) {
        if (link.contains('github')) return link;
      }
      return '';
    } catch (e) {
      debugPrint('Error getting github: $e');
      return '';
    }
  }

  List<String> get languages {
    try {
      return [];
    } catch (e) {
      debugPrint('Error getting languages: $e');
      return [];
    }
  }

  String get cvUrl {
    try {
      if (documents.isNotEmpty) {
        final firstDoc = documents.first;
        if (firstDoc is Map) {
          return firstDoc['url']?.toString() ?? '';
        }
      }
      return '';
    } catch (e) {
      debugPrint('Error getting cvUrl: $e');
      return '';
    }
  }

  ApplicantRecord copyWith({
    String? userId,
    String? jobId,
    String? status,
    DateTime? appliedAt,
    Map<String, dynamic>? profileSnapshot,
    String? docId,
    JobData? jobData,
  }) {
    return ApplicantRecord(
      userId: userId ?? this.userId,
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      profileSnapshot: profileSnapshot ?? this.profileSnapshot,
      docId: docId ?? this.docId,
      jobData: jobData ?? this.jobData,
    );
  }
}

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

class ApplicantsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = true;
  String? error;
  String? _currentJobId;
  List<ApplicantRecord> _allApplicants = [];
  List<ApplicantRecord> _filteredApplicants = [];

  // Job data cache for performance
  final Map<String, JobData?> _jobDataCache = {};

  // Filter options
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

  // Available filter options
  Set<String> availableExperiences = {};
  Set<String> availableLocations = {};
  Set<String> availableEducations = {};
  Set<String> availableAvailabilities = {};
  Set<String> availableWorkTypes = {};
  Set<String> availableSkills = {};
  Set<String> availableLanguages = {};
  Set<String> availableJobs = {};

  ApplicantsProvider() {
    _load();
  }

  List<ApplicantRecord> get applicants => _filteredApplicants;
  List<ApplicantRecord> get allApplicants => _allApplicants;

  // Statistics
  int get totalApplicants => _allApplicants.length;
  int get filteredCount => _filteredApplicants.length;
  int get pendingCount => _allApplicants.where((a) => a.status == 'pending').length;
  int get acceptedCount => _allApplicants.where((a) => a.status == 'accepted').length;
  int get rejectedCount => _allApplicants.where((a) => a.status == 'rejected').length;

  Future<void> _load() async {
    try {
      debugPrint('🔄 ApplicantsProvider: Starting to load data...');

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }
      debugPrint('✅ Current HR user: ${currentUser.uid}');

      await _loadAllJobSeekersApplications();
      _populateFilterOptions();
      debugPrint('✅ Filter options populated');

      _applyFilters();
      debugPrint('✅ Initial filters applied');
      debugPrint('📊 Total applications found: ${_allApplicants.length}');

    } catch (e) {
      error = e.toString();
      debugPrint('❌ ApplicantsProvider load error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
// -- Replace your existing _loadAllJobSeekersApplications with this --
  Future<void> _loadAllJobSeekersApplications() async {
    try {
      debugPrint('🔍 Loading applications...');
      if (_currentJobId != null) {
        debugPrint('🎯 Filtering for specific job: $_currentJobId');
      }

      final jobSeekerUidsQuery = await _firestore.collection('job_seeker').get();
      debugPrint('📋 Found ${jobSeekerUidsQuery.docs.length} job seeker documents');

      if (jobSeekerUidsQuery.docs.isEmpty) {
        debugPrint('⚠️ No job seekers found');
        _allApplicants = [];
        return;
      }

      final futures = jobSeekerUidsQuery.docs.map((doc) async {
        final jobSeekerUid = doc.id;

        try {
          Query applicationsQuery = _firestore
              .collection('applications')
              .doc(jobSeekerUid)
              .collection('applied_jobs')
              .orderBy('appliedAt', descending: true);

          if (_currentJobId != null && _currentJobId!.isNotEmpty) {
            applicationsQuery = applicationsQuery.where('jobId', isEqualTo: _currentJobId);
          }

          final applicationsSnapshot = await applicationsQuery.get();
          debugPrint('📄 Found ${applicationsSnapshot.docs.length} applications for $jobSeekerUid');

          List<ApplicantRecord> userApplications = [];

          for (final appDoc in applicationsSnapshot.docs) {
            // appDoc.data() may be Object? so cast safely
            final raw = appDoc.data();
            final Map<String, dynamic> appData = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};

            // Validate jobId
            final jobIdObj = appData['jobId'];
            if (jobIdObj == null || jobIdObj is! String || jobIdObj.trim().isEmpty) {
              debugPrint('⚠️ application ${appDoc.id} missing or invalid jobId - skipping');
              continue;
            }
            final jobId = jobIdObj;

            // Fetch job data (cached)
            final jobData = await _fetchJobData(jobId);
            if (jobData == null) {
              debugPrint('⚠️ Job data not found for jobId: $jobId, skipping application ${appDoc.id}');
              continue;
            }

            // Parse appliedAt safely
            DateTime appliedAt;
            final appliedAtRaw = appData['appliedAt'];
            if (appliedAtRaw is Timestamp) {
              appliedAt = appliedAtRaw.toDate();
            } else if (appliedAtRaw is int) {
              appliedAt = DateTime.fromMillisecondsSinceEpoch(appliedAtRaw);
            } else if (appliedAtRaw is String) {
              try {
                appliedAt = DateTime.parse(appliedAtRaw);
              } catch (_) {
                appliedAt = DateTime.now();
              }
            } else {
              // fallback
              appliedAt = DateTime.now();
            }

            // profileSnapshot may be missing or not a Map
            final psRaw = appData['profileSnapshot'];
            Map<String, dynamic> profileSnapshot = {};
            if (psRaw is Map<String, dynamic>) {
              profileSnapshot = Map<String, dynamic>.from(psRaw);
            } else if (psRaw is Map) {
              // in case it's a LinkedHashMap<dynamic,dynamic>
              profileSnapshot = psRaw.map((k, v) => MapEntry(k.toString(), v));
            } else {
              // attempt to treat the rest of appData as the snapshot if it's absent
              profileSnapshot = <String, dynamic>{};
            }

            profileSnapshot = _cleanProfileSnapshot(profileSnapshot);

            final applicantRecord = ApplicantRecord(
              userId: jobSeekerUid,
              jobId: jobId,
              status: (appData['status'] as String?) ?? 'pending',
              appliedAt: appliedAt,
              profileSnapshot: profileSnapshot,
              docId: appDoc.id,
              jobData: jobData,
            );

            userApplications.add(applicantRecord);
          }

          return userApplications;
        } catch (e) {
          debugPrint('❌ Error loading applications for $jobSeekerUid: $e');
          return <ApplicantRecord>[];
        }
      });

      final results = await Future.wait(futures);

      final List<ApplicantRecord> allApplications = results.fold<List<ApplicantRecord>>(
        <ApplicantRecord>[],
            (prev, element) {
          prev.addAll(element);
          return prev;
        },
      );

      _allApplicants = allApplications;

      if (_currentJobId != null) {
        debugPrint('🎉 Loaded ${_allApplicants.length} applications for job $_currentJobId');
      } else {
        debugPrint('🎉 Loaded ${_allApplicants.length} total applications');
      }

      if (_allApplicants.isNotEmpty) {
        final sample = _allApplicants.first;
        debugPrint('📋 Sample application: - Applicant: ${sample.name} - Job: ${sample.jobData?.title} - Status: ${sample.status}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _loadAllJobSeekersApplications: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to load job seekers applications: $e');
    }
  }

// -- Slightly safer _fetchJobData (cast jobDoc.data()) --
  Future<JobData?> _fetchJobData(String jobId) async {
    if (_jobDataCache.containsKey(jobId)) {
      debugPrint('📦 Using cached job data for $jobId');
      return _jobDataCache[jobId];
    }

    try {
      debugPrint('🔍 Fetching job data for jobId: $jobId');

      final jobDocSnap = await _firestore.collection('Posted_jobs_public').doc(jobId).get();
      if (!jobDocSnap.exists) {
        debugPrint('❌ Job document not found for jobId: $jobId');
        _jobDataCache[jobId] = null;
        return null;
      }

      final raw = jobDocSnap.data();
      final Map<String, dynamic> data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};

      double? salary;
      final salaryData = data['salary'];
      if (salaryData != null) {
        if (salaryData is num) {
          salary = salaryData.toDouble();
        } else if (salaryData is String) {
          final RegExp numberRegex = RegExp(r'[\d,]+');
          final match = numberRegex.firstMatch(salaryData);
          if (match != null) {
            final numberStr = match.group(0)?.replaceAll(',', '');
            salary = double.tryParse(numberStr ?? '');
          }
        }
      }

      dynamic experience = data['experience'];

      List<String> requiredSkills = [];
      final rs = data['required_skills'];
      if (rs is List) {
        requiredSkills = rs.map((e) => e.toString()).toList();
      }

      final jobData = JobData(
        jobId: jobId,
        title: data['title']?.toString() ?? '',
        company: data['company']?.toString() ?? '',
        location: data['location']?.toString() ?? '',
        jobType: data['job_type']?.toString() ?? '',
        workType: data['workModes']?.toString() ?? '',
        salary: salary,
        experience: experience,
        requiredSkills: requiredSkills,
      );

      _jobDataCache[jobId] = jobData;
      return jobData;
    } catch (e) {
      debugPrint('❌ Error loading job data for $jobId: $e');
      _jobDataCache[jobId] = null;
      return null;
    }
  }

// -- Slightly safer _cleanProfileSnapshot just in case non-Map is passed --
  Map<String, dynamic> _cleanProfileSnapshot(Map<String, dynamic> data) {
    try {
      if (data.containsKey('user_Account_Data')) {
        return data;
      }

      return <String, dynamic>{ 'user_Account_Data': data };
    } catch (e, st) {
      debugPrint('❌ Error cleaning profile snapshot: $e\n$st');
      return data;
    }
  }



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
      try {
        final expYears = applicant.experienceYears;
        if (expYears == 0) {
          availableExperiences.add('Entry Level');
        } else if (expYears <= 2) {
          availableExperiences.add('1-2 years');
        } else if (expYears <= 5) {
          availableExperiences.add('3-5 years');
        } else if (expYears <= 10) {
          availableExperiences.add('6-10 years');
        } else {
          availableExperiences.add('10+ years');
        }

        if (applicant.location.isNotEmpty) {
          availableLocations.add(applicant.location);
        }

        if (applicant.education.isNotEmpty) {
          availableEducations.add(applicant.education);
        }

        if (applicant.availability.isNotEmpty) {
          availableAvailabilities.add(applicant.availability);
        }

        if (applicant.workType.isNotEmpty) {
          availableWorkTypes.add(applicant.workType);
        }

        availableSkills.addAll(applicant.skills);
        availableLanguages.addAll(applicant.languages);

        if (applicant.jobData?.title.isNotEmpty == true) {
          availableJobs.add(applicant.jobData!.title);
        }
      } catch (e) {
        debugPrint('❌ Error populating filter options for applicant ${applicant.userId}: $e');
        continue;
      }
    }
  }

  void _applyFilters() {
    _filteredApplicants = _allApplicants.where((applicant) {
      try {
        if (searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          final searchableText = '${applicant.name} ${applicant.email} ${applicant.company} ${applicant.skills.join(' ')} ${applicant.jobData?.title ?? ''}'.toLowerCase();
          if (!searchableText.contains(query)) return false;
        }

        if (statusFilter != 'All' && applicant.status != statusFilter) {
          return false;
        }

        if (jobFilter != 'All' && applicant.jobData?.title != jobFilter) {
          return false;
        }

        if (experienceFilter != 'All') {
          final expYears = applicant.experienceYears;
          String expLevel;
          if (expYears == 0) {
            expLevel = 'Entry Level';
          } else if (expYears <= 2) {
            expLevel = '1-2 years';
          } else if (expYears <= 5) {
            expLevel = '3-5 years';
          } else if (expYears <= 10) {
            expLevel = '6-10 years';
          } else {
            expLevel = '10+ years';
          }
          if (expLevel != experienceFilter) return false;
        }

        if (locationFilter != 'All' && applicant.location != locationFilter) {
          return false;
        }

        if (educationFilter != 'All' && applicant.education != educationFilter) {
          return false;
        }

        if (availabilityFilter != 'All' && applicant.availability != availabilityFilter) {
          return false;
        }

        if (workTypeFilter != 'All' && applicant.workType != workTypeFilter) {
          return false;
        }

        if (skillsFilter.isNotEmpty) {
          final hasAllSkills = skillsFilter.every((skill) => applicant.skills.contains(skill));
          if (!hasAllSkills) return false;
        }

        if (languagesFilter.isNotEmpty) {
          final hasAllLanguages = languagesFilter.every((lang) => applicant.languages.contains(lang));
          if (!hasAllLanguages) return false;
        }

        if (applicant.expectedSalary < minExpectedSalary || applicant.expectedSalary > maxExpectedSalary) {
          return false;
        }

        if (appliedDateRange != null) {
          final appliedDate = applicant.appliedAt;
          if (appliedDate.isBefore(appliedDateRange!.start) ||
              appliedDate.isAfter(appliedDateRange!.end.add(const Duration(days: 1)))) {
            return false;
          }
        }

        return true;
      } catch (e) {
        debugPrint('❌ Error applying filters for applicant ${applicant.userId}: $e');
        return false;
      }
    }).toList();

    _applySorting();
  }

  void _applySorting() {
    try {
      switch (sortBy) {
        case 'applied_desc':
          _filteredApplicants.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
          break;
        case 'applied_asc':
          _filteredApplicants.sort((a, b) => a.appliedAt.compareTo(b.appliedAt));
          break;
        case 'name_asc':
          _filteredApplicants.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'name_desc':
          _filteredApplicants.sort((a, b) => b.name.compareTo(a.name));
          break;
        case 'experience_desc':
          _filteredApplicants.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
          break;
        case 'experience_asc':
          _filteredApplicants.sort((a, b) => a.experienceYears.compareTo(b.experienceYears));
          break;
        case 'salary_desc':
          _filteredApplicants.sort((a, b) => b.expectedSalary.compareTo(a.expectedSalary));
          break;
        case 'salary_asc':
          _filteredApplicants.sort((a, b) => a.expectedSalary.compareTo(b.expectedSalary));
          break;
        case 'status':
          _filteredApplicants.sort((a, b) => a.status.compareTo(b.status));
          break;
        case 'job_title':
          _filteredApplicants.sort((a, b) => (a.jobData?.title ?? '').compareTo(b.jobData?.title ?? ''));
          break;
      }
    } catch (e) {
      debugPrint('❌ Error applying sorting: $e');
    }
  }

  // Public methods for updating filters
  void updateSearchQuery(String query) {
    searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void updateStatusFilter(String status) {
    statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  void updateJobFilter(String job) {
    jobFilter = job;
    _applyFilters();
    notifyListeners();
  }

  void updateExperienceFilter(String experience) {
    experienceFilter = experience;
    _applyFilters();
    notifyListeners();
  }

  void updateLocationFilter(String location) {
    locationFilter = location;
    _applyFilters();
    notifyListeners();
  }

  void updateEducationFilter(String education) {
    educationFilter = education;
    _applyFilters();
    notifyListeners();
  }

  void updateAvailabilityFilter(String availability) {
    availabilityFilter = availability;
    _applyFilters();
    notifyListeners();
  }

  void updateWorkTypeFilter(String workType) {
    workTypeFilter = workType;
    _applyFilters();
    notifyListeners();
  }

  void updateSkillsFilter(List<String> skills) {
    skillsFilter = skills;
    _applyFilters();
    notifyListeners();
  }

  void updateLanguagesFilter(List<String> languages) {
    languagesFilter = languages;
    _applyFilters();
    notifyListeners();
  }

  void updateSalaryRange(double min, double max) {
    minExpectedSalary = min;
    maxExpectedSalary = max;
    _applyFilters();
    notifyListeners();
  }

  void updateAppliedDateRange(DateTimeRange? range) {
    appliedDateRange = range;
    _applyFilters();
    notifyListeners();
  }



  void updateSorting(String sorting) {
    sortBy = sorting;
    _applySorting();
    notifyListeners();
  }

  void clearAllFilters() {
    searchQuery = '';
    statusFilter = 'All';
    jobFilter = 'All';
    experienceFilter = 'All';
    locationFilter = 'All';
    educationFilter = 'All';
    availabilityFilter = 'All';
    workTypeFilter = 'All';
    skillsFilter.clear();
    languagesFilter.clear();
    minExpectedSalary = 0;
    maxExpectedSalary = 1000000;
    appliedDateRange = null;
    sortBy = 'applied_desc';
    _applyFilters();
    notifyListeners();
  }

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty ||
        statusFilter != 'All' ||
        jobFilter != 'All' ||
        experienceFilter != 'All' ||
        locationFilter != 'All' ||
        educationFilter != 'All' ||
        availabilityFilter != 'All' ||
        workTypeFilter != 'All' ||
        skillsFilter.isNotEmpty ||
        languagesFilter.isNotEmpty ||
        minExpectedSalary > 0 ||
        maxExpectedSalary < 1000000 ||
        appliedDateRange != null;
  }

  // Update application status
  Future<void> updateApplicationStatus(String applicantUserId, String docId, String newStatus) async {
    try {
      await _firestore
          .collection('applications')
          .doc(applicantUserId)
          .collection('applied_jobs')
          .doc(docId)
          .update({'status': newStatus});

      final index = _allApplicants.indexWhere((a) => a.docId == docId && a.userId == applicantUserId);
      if (index != -1) {
        _allApplicants[index] = _allApplicants[index].copyWith(status: newStatus);
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      error = 'Failed to update status: $e';
      notifyListeners();
    }
  }
  Future<void> refresh({String? jobId}) async {
    debugPrint('🔄 Refreshing applicants data for jobId: $jobId');
    _currentJobId = jobId; // Store the jobId
    isLoading = true;
    error = null;
    notifyListeners();
    await _load();
  }
}

