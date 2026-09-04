import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/onboarding/candidate_profile_service.dart';
import '../../core/rbac/user_role.dart';

class AdminAnalyticsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool loading = true;
  bool _disposed = false;

  // KPIs
  int totalUsers = 0;
  int activeUsers = 0;
  int totalJobSeekers = 0;
  int totalRecruiters = 0;
  int totalRecruitmentAgents = 0;
  int totalAdmins = 0;
  int totalJobs = 0;
  int totalRequests = 0;
  int candidatesProcessed = 0;

  // Chart Data
  final Map<String, int> _rawSkillFreqs = {};
  Map<String, int> skillFrequencies = {};
  Map<String, int> jobsByStatus = {'Open': 0, 'Closed': 0};
  Map<String, int> requestsByStatus = {
    'Pending': 0,
    'Approved': 0,
    'Rejected': 0,
  };
  Map<String, int> topRecruiters = {};
  Map<String, int> jobsByLocation = {};
  Map<String, int> applicantsByLocation = {};

  /// Which role templates candidates are actually onboarding against, most
  /// popular first. The single most useful thing an admin can see about the
  /// candidate pool: it says what kind of platform this is becoming.
  Map<String, int> roleFrequencies = {};

  /// Licences, ratings and aircraft types held across the pool. Skills are
  /// self-declared; these are the credentials recruiters screen on.
  Map<String, int> credentialFrequencies = {};

  /// Profiles that finished onboarding versus ones still in draft — the
  /// drop-off number, and the only funnel metric available here.
  int completedProfiles = 0;
  int draftProfiles = 0;

  int get totalProfiles => completedProfiles + draftProfiles;
  double get completionRate =>
      totalProfiles == 0 ? 0 : completedProfiles / totalProfiles;
  List<Map<String, dynamic>> recentRequests = [];
  List<Map<String, dynamic>> allJobs = [];

  // Skill filter
  Set<String> selectedSkills = {};

  // Realtime listeners
  StreamSubscription? _requestsSub;
  StreamSubscription? _jobsSub;
  StreamSubscription? _skillsSub;

  AdminAnalyticsProvider() {
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    loading = true;
    _safeNotify();

    await _fetchAggregateKPIs();
    _startContinuousRealtimeListeners();

    loading = false;
    _safeNotify();
  }

  Future<void> refresh() async {
    await _fetchAggregateKPIs();
  }

  void toggleSkill(String skill) {
    if (selectedSkills.contains(skill)) {
      selectedSkills.remove(skill);
    } else {
      selectedSkills.add(skill);
    }
    _updateSkillFrequencies();
  }

  void clearSkills() {
    selectedSkills.clear();
    _updateSkillFrequencies();
  }

  List<String> getAllRawSkills() {
    final list = _rawSkillFreqs.keys.toList();
    list.sort();
    return list;
  }

  Future<void> _fetchAggregateKPIs() async {
    try {
      final usersCol = _firestore.collection('users');

      // Server-side aggregate counts — no document reads. Each role counts via
      // its exact-case whereIn aliases (Firestore equality is case-sensitive).
      Future<int> countRole(UserRole r) async =>
          (await usersCol.where('role', whereIn: r.queryAliases).count().get())
              .count ??
          0;

      final results = await Future.wait([
        countRole(UserRole.jobSeeker), // 0
        countRole(UserRole.recruiter), // 1
        countRole(UserRole.recruitmentAgent), // 2
        countRole(UserRole.admin), // 3
        countRole(UserRole.superAdmin), // 4
        usersCol.count().get().then((s) => s.count ?? 0), // 5 total
        usersCol
            .where('account_status', isEqualTo: 'active')
            .count()
            .get()
            .then((s) => s.count ?? 0), // 6 active
        _firestore
            .collection('Posted_jobs_public')
            .count()
            .get()
            .then((s) => s.count ?? 0), // 7 jobs
        _firestore
            .collection('recruiter_requests')
            .count()
            .get()
            .then((s) => s.count ?? 0), // 8 requests
      ]);

      totalJobSeekers = results[0];
      totalRecruiters = results[1];
      totalRecruitmentAgents = results[2];
      totalAdmins = results[3] + results[4]; // admin + super admin
      totalUsers = results[5];
      activeUsers = results[6];
      totalJobs = results[7];
      totalRequests = results[8];

      _safeNotify();
    } catch (e) {
      debugPrint('❌ _fetchAggregateKPIs error: $e');
    }
  }

  void _startContinuousRealtimeListeners() {
    // 1. SKILLS
    _skillsSub?.cancel();
    _skillsSub = _firestore
        .collection('Job_Seeker')
        .limit(200)
        .snapshots()
        .listen((snap) {
          if (_disposed) return;
          _rawSkillFreqs.clear();
          final Map<String, int> applicantLocCounts = {};
          final Map<String, int> roleCounts = {};
          final Map<String, int> credentialCounts = {};
          var completed = 0;
          var draft = 0;
          for (var doc in snap.docs) {
            final profile = CandidateProfileService.parse(doc.id, doc.data());
            if (profile == null) continue;
            final personal = profile.personalInfo;

            // Geographical aggregation — count applicants per country/region.
            final region = (personal.nationality.isNotEmpty
                    ? personal.nationality
                    : personal.location.country)
                .trim();
            if (region.isNotEmpty && region.toLowerCase() != 'not specified') {
              final cap = region[0].toUpperCase() + region.substring(1);
              applicantLocCounts[cap] = (applicantLocCounts[cap] ?? 0) + 1;
            }

            // What the candidate typed plus what their role template
            // captured — the chart is about the pool's capabilities, and for a
            // templated role most of that lives in the role data.
            final skills = <String>{
              ...personal.skills,
              ...profile.roleSpecificData.technicalCompetencies,
              ...profile.roleSpecificData.toolsAndSystems,
            };

            final role = profile.targetRole.roleTitle.trim();
            if (role.isNotEmpty) {
              roleCounts[role] = (roleCounts[role] ?? 0) + 1;
            }

            if (profile.isComplete) {
              completed++;
            } else {
              draft++;
            }

            // Licences and aircraft, deduped per candidate so one pilot with
            // six type ratings does not outweigh six pilots.
            final credentials = <String>{
              ...profile.roleSpecificData.licensesAndRatings
                  .map((l) => l.title.trim())
                  .where((t) => t.isNotEmpty),
              ...profile.roleSpecificData.aircraftTypes,
            };
            for (final c in credentials) {
              credentialCounts[c] = (credentialCounts[c] ?? 0) + 1;
            }

            for (final s in skills) {
              final skillStr = s.toString().trim();
              if (skillStr.isNotEmpty) {
                final capSkill =
                    skillStr[0].toUpperCase() +
                    skillStr.substring(1).toLowerCase();
                _rawSkillFreqs[capSkill] = (_rawSkillFreqs[capSkill] ?? 0) + 1;
              }
            }
          }

          // Every region, not the top eight. This now feeds a map, and a map
          // that silently drops the ninth country is a map that lies about the
          // pool — the ranked-bar card that needed a top-N is gone.
          //
          // Ties break by name so two reads put the same countries in the same
          // order rather than reshuffling the legend on every snapshot.
          final sortedRegions = applicantLocCounts.keys.toList()
            ..sort((a, b) {
              final byCount =
                  applicantLocCounts[b]!.compareTo(applicantLocCounts[a]!);
              return byCount != 0 ? byCount : a.compareTo(b);
            });
          applicantsByLocation = {
            for (var k in sortedRegions) k: applicantLocCounts[k]!,
          };

          roleFrequencies = _topBy(roleCounts, 8);
          credentialFrequencies = _topBy(credentialCounts, 10);
          completedProfiles = completed;
          draftProfiles = draft;

          _updateSkillFrequencies();
        });

    // 2. JOBS BY STATUS & LIST
    _jobsSub?.cancel();
    _jobsSub = _firestore
        .collection('Posted_jobs_public')
        .orderBy('timestamp', descending: true) // Fixed field name
        .limit(100)
        .snapshots()
        .listen((snap) {
          if (_disposed) return;
          int open = 0, closed = 0;
          List<Map<String, dynamic>> tempJobs = [];
          final Map<String, int> locCounts = {};
          for (var doc in snap.docs) {
            final data = doc.data();
            final status = (data['status'] ?? 'open').toString().toLowerCase();
            if (status == 'closed') {
              closed++;
            } else {
              open++;
            }

            // Geographical aggregation — count jobs per location.
            final loc = (data['location'] ?? '').toString().trim();
            if (loc.isNotEmpty && loc.toLowerCase() != 'not specified') {
              locCounts[loc] = (locCounts[loc] ?? 0) + 1;
            }

            tempJobs.add({
              'id': doc.id,
              ...data,
              'createdStr': _formatDate(data['timestamp'] ?? data['createdAt']),
            });
          }
          allJobs = tempJobs;
          jobsByStatus = {'Open': open, 'Closed': closed};

          // Sort locations descending by count and keep the top 8.
          final sortedLocations = locCounts.keys.toList()
            ..sort((a, b) => locCounts[b]!.compareTo(locCounts[a]!));
          jobsByLocation = {
            for (var k in sortedLocations.take(8)) k: locCounts[k]!,
          };

          _safeNotify();
        });

    // 3. REQUESTS & RECENT REQUESTS LIST & TOP RECRUITERS
    _requestsSub?.cancel();
    _requestsSub = _firestore
        .collection('recruiter_requests')
        .orderBy('created_at', descending: true)
        .limit(200)
        .snapshots()
        .listen((snap) {
          if (_disposed) return;
          int pending = 0, approved = 0, rejected = 0;
          int processed = 0;

          Map<String, int> recruiterReqCount = {};
          List<Map<String, dynamic>> requestsList = [];

          int limitList = 0;

          for (var doc in snap.docs) {
            final data = doc.data();
            final status = (data['status'] ?? 'pending')
                .toString()
                .toLowerCase();
            String recruiterEmail =
                (data['recruiter_email'] ?? data['recruiterEmail'] ?? 'Unknown')
                    .toString();
            if (recruiterEmail.isEmpty) recruiterEmail = 'Unknown';

            recruiterReqCount[recruiterEmail] =
                (recruiterReqCount[recruiterEmail] ?? 0) + 1;

            if (status == 'approved' ||
                status == 'open' ||
                status == 'active') {
              approved++;
            } else if (status == 'rejected' || status == 'closed') {
              rejected++;
            } else {
              pending++;
            }

            final cands = data['candidates'] as List<dynamic>? ?? [];
            for (var c in cands) {
              if (c is Map &&
                  (c['status'] ?? '').toString().toLowerCase() == 'handover') {
                processed++;
              }
            }

            if (limitList < 15) {
              limitList++;
              requestsList.add({
                'id': doc.id,
                'recruiterEmail': recruiterEmail,
                'status': status,
                'candidatesCount': cands.length,
                'createdStr': _formatDate(data['created_at']),
              });
            }
          }

          final sortedRecruiters = recruiterReqCount.keys.toList()
            ..sort(
              (a, b) => recruiterReqCount[b]!.compareTo(recruiterReqCount[a]!),
            );
          topRecruiters = {
            for (var k in sortedRecruiters.take(5))
              if (k != 'Unknown') k: recruiterReqCount[k]!,
          };

          recentRequests = requestsList;
          requestsByStatus = {
            'Pending': pending,
            'Approved': approved,
            'Rejected': rejected,
          };
          candidatesProcessed = processed;
          _safeNotify();
        });
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(date.toDate());
    } else if (date is DateTime) {
      return DateFormat('MMM dd, yyyy').format(date);
    } else if (date != null) {
      return date.toString();
    }
    return '';
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Highest counts first, capped — every one of these feeds a card with a
  /// fixed height, and an uncapped map is what makes a chart unreadable.
  static Map<String, int> _topBy(Map<String, int> src, int limit) {
    final keys = src.keys.toList()..sort((a, b) => src[b]!.compareTo(src[a]!));
    return {for (final k in keys.take(limit)) k: src[k]!};
  }

  /// How many skills the chart shows when nothing is filtered.
  ///
  /// Templated roles contribute competencies and tools as well as free-form
  /// skills, so an unfiltered pool of twenty candidates easily produces a
  /// hundred distinct values. Rendering all of them in one fixed-height card
  /// is what made the chart unreadable; the long tail is one-per-candidate
  /// noise anyway, and the filter is still there for anyone who wants it.
  static const defaultSkillLimit = 12;

  /// True when the chart is showing a capped view rather than everything.
  bool get skillsAreCapped =>
      selectedSkills.isEmpty && _rawSkillFreqs.length > defaultSkillLimit;

  /// Every skill seen, for the filter dialog.
  int get totalSkillCount => _rawSkillFreqs.length;

  void _updateSkillFrequencies() {
    Map<String, int> filtered = {};
    if (selectedSkills.isEmpty) {
      filtered = _topBy(_rawSkillFreqs, defaultSkillLimit);
    } else {
      _rawSkillFreqs.forEach((key, value) {
        if (selectedSkills.contains(key)) {
          filtered[key] = value;
        }
      });
    }

    final sortedKeys = filtered.keys.toList()
      ..sort((a, b) => filtered[b]!.compareTo(filtered[a]!));
    skillFrequencies = {for (var k in sortedKeys) k: filtered[k]!};
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestsSub?.cancel();
    _jobsSub?.cancel();
    _skillsSub?.cancel();
    super.dispose();
  }
}
