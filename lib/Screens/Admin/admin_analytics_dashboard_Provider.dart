import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool loading = true;
  bool _disposed = false;

  // KPIs
  int totalUsers = 0;
  int totalJobSeekers = 0;
  int totalRecruiters = 0;
  int totalAdmins = 0;
  int totalJobs = 0;
  int totalRequests = 0;
  int candidatesProcessed = 0;

  // Chart Data
  final Map<String, int> _rawSkillFreqs = {};
  Map<String, int> skillFrequencies = {};
  Map<String, int> jobsByStatus = {'Open': 0, 'Closed': 0};
  Map<String, int> requestsByStatus = {'Pending': 0, 'Approved': 0, 'Rejected': 0};
  Map<String, int> topRecruiters = {};
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
      // Users collection based counting
      final usersSnap = await _firestore.collection('users').get();
      int tempAdmin = 0, tempRec = 0, tempJs = 0;
      
      for (var doc in usersSnap.docs) {
        final role = (doc.data()['role'] ?? '').toString().toLowerCase();
        if (role == 'admin' || role == 'superadmin' || role == 'Admin') {
          tempAdmin++;
        } else if (role == 'recruiter') {
          tempRec++;
        } else if (role == 'job seeker' || role == 'job_seeker') {
          tempJs++;
        }
      }

      totalAdmins = tempAdmin;
      totalRecruiters = tempRec;
      totalJobSeekers = tempJs;
      totalUsers = tempRec + tempJs;

      final jobsQuery = await _firestore.collection('Posted_jobs_public').count().get();
      totalJobs = jobsQuery.count ?? 0;

      final reqQuery = await _firestore.collection('recruiter_requests').count().get();
      totalRequests = reqQuery.count ?? 0;
      
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
      for (var doc in snap.docs) {
        final data = doc.data();
        final userData = data['user_data'] as Map<String, dynamic>? ?? {};
        final personalProfile = userData['personalProfile'] as Map<String, dynamic>? ?? {};
        final profProfile = userData['professionalProfile'] as Map<String, dynamic>? ?? {};

        List<dynamic> skills = [];
        if (data['skills'] is List) {
          skills = data['skills'];
        } else if (personalProfile['skills'] is List) skills = personalProfile['skills'];
        else if (profProfile['skills'] is List) skills = profProfile['skills'];
        else if (userData['skills'] is List) skills = userData['skills'];

        for (var s in skills) {
          final skillStr = s.toString().trim();
          if (skillStr.isNotEmpty) {
            final capSkill = skillStr[0].toUpperCase() + skillStr.substring(1).toLowerCase();
            _rawSkillFreqs[capSkill] = (_rawSkillFreqs[capSkill] ?? 0) + 1;
          }
        }
      }

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
      for (var doc in snap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? 'open').toString().toLowerCase();
        if (status == 'closed') {
          closed++;
        } else {
          open++;
        }

        tempJobs.add({
          'id': doc.id,
          ...data,
          'createdStr': _formatDate(data['timestamp'] ?? data['createdAt']),
        });
      }
      allJobs = tempJobs;
      jobsByStatus = {'Open': open, 'Closed': closed};
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
        final status = (data['status'] ?? 'pending').toString().toLowerCase();
        String recruiterEmail = (data['recruiter_email'] ?? data['recruiterEmail'] ?? 'Unknown').toString();
        if (recruiterEmail.isEmpty) recruiterEmail = 'Unknown';
        
        recruiterReqCount[recruiterEmail] = (recruiterReqCount[recruiterEmail] ?? 0) + 1;

        if (status == 'approved' || status == 'open' || status == 'active') {
          approved++;
        } else if (status == 'rejected' || status == 'closed') rejected++;
        else pending++;

        final cands = data['candidates'] as List<dynamic>? ?? [];
        for (var c in cands) {
          if (c is Map && (c['status'] ?? '').toString().toLowerCase() == 'handover') {
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
      
      final sortedRecruiters = recruiterReqCount.keys.toList()..sort((a, b) => recruiterReqCount[b]!.compareTo(recruiterReqCount[a]!));
      topRecruiters = { for (var k in sortedRecruiters.take(5)) if (k != 'Unknown') k : recruiterReqCount[k]! };

      recentRequests = requestsList;
      requestsByStatus = {'Pending': pending, 'Approved': approved, 'Rejected': rejected};
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

  void _updateSkillFrequencies() {
    Map<String, int> filtered = {};
    if (selectedSkills.isEmpty) {
      filtered = Map.from(_rawSkillFreqs);
    } else {
      _rawSkillFreqs.forEach((key, value) {
        if (selectedSkills.contains(key)) {
          filtered[key] = value;
        }
      });
    }

    final sortedKeys = filtered.keys.toList()
      ..sort((a, b) => filtered[b]!.compareTo(filtered[a]!));
    skillFrequencies = {
      for (var k in sortedKeys) k: filtered[k]!
    };
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
