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

  Future<void> fetchDashboardData() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // Fetch all stats in parallel for better performance
      await Future.wait([
        _fetchJobSeekerStats(),
        _fetchRecruiterStats(),
        _fetchJobsStats(),
        _fetchRecruiterRequests(),
      ]);

      totalUsers = totalJobSeekers + totalRecruiters;

      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error loading dashboard: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      debugPrint('Dashboard Error: $e');
    }
  }

  Future<void> _fetchJobSeekerStats() async {
    try {
      // Get total job seekers
      final jobSeekerSnapshot = await _firestore.collection('job_seeker').get();
      totalJobSeekers = jobSeekerSnapshot.docs.length;

      // Calculate growth (compare with last week)
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final recentJobSeekers = jobSeekerSnapshot.docs.where((doc) {
        final data = doc.data();
        if (data['created_at'] != null) {
          final createdAt = (data['created_at'] as Timestamp).toDate();
          return createdAt.isAfter(lastWeek);
        }
        return false;
      }).length;

      if (totalJobSeekers > 0) {
        jobSeekerGrowth = (recentJobSeekers / totalJobSeekers) * 100;
      }

      // Generate weekly data for graph
      weeklyJobSeekers = _generateWeeklyData(jobSeekerSnapshot.docs);
    } catch (e) {
      debugPrint('Error fetching job seeker stats: $e');
    }
  }

  Future<void> _fetchRecruiterStats() async {
    try {
      // Get total recruiters
      final recruiterSnapshot = await _firestore.collection('recruiter').get();
      totalRecruiters = recruiterSnapshot.docs.length;

      // Calculate growth
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final recentRecruiters = recruiterSnapshot.docs.where((doc) {
        final data = doc.data();
        if (data['created_at'] != null) {
          final createdAt = (data['created_at'] as Timestamp).toDate();
          return createdAt.isAfter(lastWeek);
        }
        return false;
      }).length;

      if (totalRecruiters > 0) {
        recruiterGrowth = (recentRecruiters / totalRecruiters) * 100;
      }

      // Generate weekly data
      weeklyRecruiters = _generateWeeklyData(recruiterSnapshot.docs);
    } catch (e) {
      debugPrint('Error fetching recruiter stats: $e');
    }
  }

  Future<void> _fetchJobsStats() async {
    try {
      // Get total jobs posted
      final jobsSnapshot = await _firestore.collection('Posted_jobs_public').get();
      totalJobsPosted = jobsSnapshot.docs.length;

      // Calculate growth
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final recentJobs = jobsSnapshot.docs.where((doc) {
        final data = doc.data();
        if (data['posted_date'] != null) {
          final postedDate = (data['posted_date'] as Timestamp).toDate();
          return postedDate.isAfter(lastWeek);
        }
        return false;
      }).length;

      if (totalJobsPosted > 0) {
        jobsGrowth = (recentJobs / totalJobsPosted) * 100;
      }

      // Generate weekly data
      weeklyJobs = _generateWeeklyData(jobsSnapshot.docs, dateField: 'posted_date');
    } catch (e) {
      debugPrint('Error fetching jobs stats: $e');
    }
  }

  Future<void> _fetchRecruiterRequests() async {
    try {
      final requestsSnapshot = await _firestore.collection('recruiter_requests').get();
      totalRecruiterRequests = requestsSnapshot.docs.length;
    } catch (e) {
      debugPrint('Error fetching recruiter requests: $e');
    }
  }

  List<Map<String, dynamic>> _generateWeeklyData(
      List<QueryDocumentSnapshot> docs, {
        String dateField = 'created_at',
      }) {
    final weeklyData = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final count = docs.where((doc) {
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
}