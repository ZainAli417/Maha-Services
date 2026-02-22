import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stats
  int totalUsers = 0;
  int totalJobSeekers = 0;
  int totalRecruiters = 0;
  int totalJobsPosted = 0;
  int totalRecruiterRequests = 0;

  // Loading states
  bool isLoading = true;
  String? errorMessage;
  bool _disposed = false;

  // Historical data for graphs (last 7 days)
  List<Map<String, dynamic>> weeklyJobSeekers = [];
  List<Map<String, dynamic>> weeklyRecruiters = [];
  List<Map<String, dynamic>> weeklyJobs = [];

  // Growth percentages
  double jobSeekerGrowth = 0.0;
  double recruiterGrowth = 0.0;
  double jobsGrowth = 0.0;

  DashboardProvider() {
    fetchDashboardData();
  }

  Future<void> _safeNotify() async {
    if (_disposed) return;
    // Defer to next microtask to avoid building/notifying conflicts
    Future.microtask(() {
      if (!_disposed) notifyListeners();
    });
  }

  Future<void> fetchDashboardData() async {
    try {
      if (_disposed) return;
      isLoading = true;
      errorMessage = null;
      _safeNotify();

      // Fetch all stats in parallel for better performance
      await Future.wait([
        _fetchJobSeekerStats(),
        _fetchRecruiterStats(),
        _fetchJobsStats(),
        _fetchRecruiterRequests(),
      ]);

      if (_disposed) return;
      totalUsers = totalJobSeekers + totalRecruiters;

      isLoading = false;
      _safeNotify();
    } catch (e) {
      if (_disposed) return;
      errorMessage = 'Error loading dashboard: ${e.toString()}';
      isLoading = false;
      _safeNotify();
      debugPrint('Dashboard Error: $e');
    }
  }

  Future<void> _fetchJobSeekerStats() async {
    try {
      // 1. Get total job seekers using Count Query (O(1) cost vs O(N))
      final totalSnap = await _firestore.collection('Job_Seeker').count().get();
      totalJobSeekers = totalSnap.count ?? 0;

      // 2. Fetch only recent job seekers for growth and graph (Last 7 days)
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final recentSnap = await _firestore
          .collection('Job_Seeker')
          .where('created_at', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      final recentDocs = recentSnap.docs;
      
      if (totalJobSeekers > 0) {
        jobSeekerGrowth = (recentDocs.length / totalJobSeekers) * 100;
      }

      // Generate weekly data for graph using only recent docs
      weeklyJobSeekers = _generateWeeklyData(recentDocs, lastWeek);
    } catch (e) {
      debugPrint('Error fetching job seeker stats: $e');
    }
  }

  Future<void> _fetchRecruiterStats() async {
    try {
      // 1. Get total recruiters using Count Query
      final totalSnap = await _firestore.collection('recruiter').count().get();
      totalRecruiters = totalSnap.count ?? 0;

      // 2. Fetch only recent recruiters
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final recentSnap = await _firestore
          .collection('recruiter')
          .where('created_at', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      final recentDocs = recentSnap.docs;
      
      if (totalRecruiters > 0) {
        recruiterGrowth = (recentDocs.length / totalRecruiters) * 100;
      }

      // Generate weekly data
      weeklyRecruiters = _generateWeeklyData(recentDocs, lastWeek);
    } catch (e) {
      debugPrint('Error fetching recruiter stats: $e');
    }
  }

  Future<void> _fetchJobsStats() async {
    try {
      // 1. Get total jobs posted using Count Query
      final totalSnap = await _firestore.collection('Posted_jobs_public').count().get();
      totalJobsPosted = totalSnap.count ?? 0;

      // 2. Fetch only recent jobs
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final recentSnap = await _firestore
          .collection('Posted_jobs_public')
          .where('posted_date', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      final recentDocs = recentSnap.docs;
      
      if (totalJobsPosted > 0) {
        jobsGrowth = (recentDocs.length / totalJobsPosted) * 100;
      }

      // Generate weekly data
      weeklyJobs = _generateWeeklyData(recentDocs, lastWeek, dateField: 'posted_date');
    } catch (e) {
      debugPrint('Error fetching jobs stats: $e');
    }
  }

  Future<void> _fetchRecruiterRequests() async {
    try {
      final totalSnap = await _firestore.collection('recruiter_requests').count().get();
      totalRecruiterRequests = totalSnap.count ?? 0;
    } catch (e) {
      debugPrint('Error fetching recruiter requests: $e');
    }
  }

  List<Map<String, dynamic>> _generateWeeklyData(
      List<QueryDocumentSnapshot> recentDocs,
      DateTime startDate, {
        String dateField = 'created_at',
      }) {
    final weeklyData = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final count = recentDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data[dateField] != null) {
          final docDate = (data[dateField] as Timestamp).toDate();
          return docDate.isAfter(dayStart) && docDate.isBefore(dayEnd);
        }
        return false;
      }).length;

      weeklyData.add({
        'day': _getDayName(date.weekday),
        'date': date,
        'count': count,
      });
    }

    return weeklyData;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  Future<void> refreshData() async {
    await fetchDashboardData();
  }

  // Get activity summary
  Map<String, dynamic> getActivitySummary() {
    return {
      'total_registrations': totalUsers,
      'active_jobs': totalJobsPosted,
      'pending_requests': totalRecruiterRequests,
      'job_seeker_percentage': totalUsers > 0
          ? ((totalJobSeekers / totalUsers) * 100).toStringAsFixed(1)
          : '0.0',
      'recruiter_percentage': totalUsers > 0
          ? ((totalRecruiters / totalUsers) * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  // Get top stats for quick view
  List<Map<String, dynamic>> getTopStats() {
    return [
      {
        'title': 'Total Users',
        'value': totalUsers,
        'growth': ((jobSeekerGrowth + recruiterGrowth) / 2).toStringAsFixed(1),
        'icon': Icons.people_rounded,
        'color': const Color(0xFF6366F1),
        'isPositive': true,
      },
      {
        'title': 'Job Seekers',
        'value': totalJobSeekers,
        'growth': jobSeekerGrowth.toStringAsFixed(1),
        'icon': Icons.person_search_rounded,
        'color': const Color(0xFF10B981),
        'isPositive': jobSeekerGrowth > 0,
      },
      {
        'title': 'Recruiters',
        'value': totalRecruiters,
        'growth': recruiterGrowth.toStringAsFixed(1),
        'icon': Icons.business_center_rounded,
        'color': const Color(0xFF8B5CF6),
        'isPositive': recruiterGrowth > 0,
      },
      {
        'title': 'Jobs Posted',
        'value': totalJobsPosted,
        'growth': jobsGrowth.toStringAsFixed(1),
        'icon': Icons.work_rounded,
        'color': const Color(0xFFFBBF24),
        'isPositive': jobsGrowth > 0,
      },
    ];
  }
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}