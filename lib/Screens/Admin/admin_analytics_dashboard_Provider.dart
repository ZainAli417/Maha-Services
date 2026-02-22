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
  Map<String, int> skillFrequencies = {};
  Map<String, int> jobsByStatus = {'Open': 0, 'Closed': 0};
  Map<String, int> requestsByStatus = {'Pending': 0, 'Approved': 0, 'Rejected': 0};
  Map<String, int> topRecruiters = {};
  List<Map<String, dynamic>> recentRequests = [];

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

  Future<void> _fetchAggregateKPIs() async {
    try {
      // Users collection based counting
      final usersSnap = await _firestore.collection('users').get();
      int tempAdmin = 0, tempRec = 0, tempJs = 0;
      
      for (var doc in usersSnap.docs) {
        final role = (doc.data()['role'] ?? '').toString().toLowerCase();
        if (role == 'admin' || role == 'superadmin') {
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
      totalUsers = tempAdmin + tempRec + tempJs;

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
        .limit(100)
        .snapshots()
        .listen((snap) {
      if (_disposed) return;
      final Map<String, int> freqs = {};
      for (var doc in snap.docs) {
        final data = doc.data();
        final userData = data['user_data'] as Map<String, dynamic>? ?? {};
        final personalProfile = userData['personalProfile'] as Map<String, dynamic>? ?? {};
        final profProfile = userData['professionalProfile'] as Map<String, dynamic>? ?? {};

        List<dynamic> skills = [];
        if (data['skills'] is List) skills = data['skills'];
        else if (personalProfile['skills'] is List) skills = personalProfile['skills'];
        else if (profProfile['skills'] is List) skills = profProfile['skills'];
        else if (userData['skills'] is List) skills = userData['skills'];

        for (var s in skills) {
          final skillStr = s.toString().trim();
          if (skillStr.isNotEmpty) {
            final capSkill = skillStr[0].toUpperCase() + skillStr.substring(1).toLowerCase();
            freqs[capSkill] = (freqs[capSkill] ?? 0) + 1;
          }
        }
      }

      final sortedKeys = freqs.keys.toList()..sort((a, b) => freqs[b]!.compareTo(freqs[a]!));
      skillFrequencies = { for (var k in sortedKeys.take(8)) k : freqs[k]! };
      _safeNotify();
    });

    // 2. JOBS BY STATUS
    _jobsSub?.cancel();
    _jobsSub = _firestore
        .collection('Posted_jobs_public')
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .listen((snap) {
      if (_disposed) return;
      int open = 0, closed = 0;
      for (var doc in snap.docs) {
        final status = (doc.data()['status'] ?? 'open').toString().toLowerCase();
        if (status == 'closed') closed++;
        else open++;
      }
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

        if (status == 'approved' || status == 'open' || status == 'active') approved++;
        else if (status == 'rejected' || status == 'closed') rejected++;
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

  @override
  void dispose() {
    _disposed = true;
    _requestsSub?.cancel();
    _jobsSub?.cancel();
    _skillsSub?.cancel();
    super.dispose();
  }
}
