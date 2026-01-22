// lib/providers/list_applied_jobs_provider.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ListAppliedJobsProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Real‑time subscription to the user's applied_jobs collection
  StreamSubscription<QuerySnapshot>? _appsSub;

  /// One subscription per jobId to its Posted_jobs_public/{jobId} doc
  final Map<String, StreamSubscription<DocumentSnapshot>> _jobDocSubs = {};

  /// Raw snapshots of applied_docs
  List<QueryDocumentSnapshot> _appliedDocs = [];

  /// Latest jobData cache
  final Map<String, Map<String, dynamic>> _jobDataMap = {};

  bool _isLoading = true;
  String? _error;

  List<_AppRecord> _applications = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<_AppRecord> get applications => List.unmodifiable(_applications);

  ListAppliedJobsProvider() {
    _startListeners();
  }

  void _startListeners() {
    final user = _auth.currentUser;
    if (user == null) {
      _error = 'Not authenticated';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _appsSub = _firestore
        .collection('applications')
        .doc(user.uid)
        .collection('applied_jobs')
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .listen((snap) {
      _appliedDocs = snap.docs;
      _subscribeToJobDocs(_extractJobIds());
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  List<String> _extractJobIds() {
    return _appliedDocs
        .map((d) => (d.data() as Map<String, dynamic>)['jobId'] as String)
        .toSet()
        .toList();
  }

  void _subscribeToJobDocs(List<String> jobIds) {
    // 1) Cancel listeners for jobs no longer in the list
    final removed = _jobDocSubs.keys.where((id) => !jobIds.contains(id));
    for (var id in removed) {
      _jobDocSubs[id]!.cancel();
      _jobDocSubs.remove(id);
      _jobDataMap.remove(id);
    }

    // 2) Add listeners for new jobIds
    for (var id in jobIds) {
      if (_jobDocSubs.containsKey(id)) continue;
      final sub = _firestore
          .collection('Posted_jobs_public')
          .doc(id)
          .snapshots()
          .listen((docSnap) {
        if (docSnap.exists) {
          _jobDataMap[id] = docSnap.data() as Map<String, dynamic>;
        } else {
          _jobDataMap.remove(id);
        }
        _rebuildRecords();
      }, onError: (e) {
        debugPrint('Job doc listener error for $id: $e');
      });
      _jobDocSubs[id] = sub;
    }

    // 3) Build initial records
    _rebuildRecords();
  }

  void _rebuildRecords() {
    final List<_AppRecord> recs = [];

    for (var doc in _appliedDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final jid = data['jobId'] as String;
      final jobData = _jobDataMap[jid];
      if (jobData == null) continue;

      // parse dates robustly
      DateTime parseDate(String s) {
        try {
          return DateTime.parse(s);
        } catch (_) {}
        try {
          return DateFormat('MM/dd/yy').parse(s);
        } catch (_) {}
        try {
          return DateFormat('MM/dd/yyyy').parse(s);
        } catch (_) {
          return DateTime.now();
        }
      }

      DateTime parseAppliedAt(dynamic v) {
        if (v is Timestamp) return v.toDate();
        if (v is String) return DateTime.parse(v);
        throw Exception('Invalid appliedAt type');
      }

      // Parse responseDate if available
      DateTime? responseDate;
      if (data['responseDate'] != null) {
        if (data['responseDate'] is Timestamp) {
          responseDate = (data['responseDate'] as Timestamp).toDate();
        } else if (data['responseDate'] is String) {
          try {
            responseDate = DateTime.parse(data['responseDate']);
          } catch (_) {}
        }
      }

      recs.add(_AppRecord(
        jobId: jid,
        title: jobData['title'] ?? '—',
        company: jobData['company'] ?? '—',
        contactEmail: jobData['contactEmail'] ?? '—',
        department: jobData['department'] ?? 'General',
        createdAt: parseDate(jobData['createdAt'] ?? ''),
        deadline: parseDate(jobData['deadline'] ?? ''),
        appliedAt: parseAppliedAt(data['appliedAt']),
        status: data['status'] ?? 'pending',
        responseDate: responseDate,
      ));
    }

    // Sort by appliedAt descending
    recs.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

    _applications = recs;
    _isLoading = false;
    notifyListeners();
  }

  /// Analytics computation based on filtered applications
  Map<String, dynamic> getAnalytics(List<dynamic> filteredApps) {
    // Cast to _AppRecord
    final apps = filteredApps.cast<_AppRecord>();

    if (apps.isEmpty) {
      return {
        'totalApplications': 0,
        'statusBreakdown': {'pending': 0, 'shortlist': 0, 'accepted': 0, 'rejected': 0},
        'responseRate': 0.0,
        'averageResponseTime': 0,
        'topCompanies': <Map<String, dynamic>>[],
        'applicationTrend': <Map<String, dynamic>>[],
        'departmentDistribution': <Map<String, dynamic>>[],
        'successRateByDepartment': <Map<String, dynamic>>[],
        'weeklyActivity': <Map<String, dynamic>>[],
        'monthlyTrend': <Map<String, dynamic>>[],
      };
    }

    final total = apps.length;
    final pending = apps.where((a) => a.status == 'pending').length;
    final shortlisted = apps.where((a) => a.status == 'shortlist').length;
    final accepted = apps.where((a) => a.status == 'accepted').length;
    final rejected = apps.where((a) => a.status == 'rejected').length;
    final responded = shortlisted + accepted + rejected;

    // Response Rate
    final responseRate = total > 0 ? (responded / total * 100) : 0.0;

    // Average Response Time (days)
    int totalResponseDays = 0;
    int respondedCount = 0;
    for (var app in apps) {
      if (app.status != 'pending' && app.responseDate != null) {
        totalResponseDays += app.responseDate!.difference(app.appliedAt).inDays;
        respondedCount++;
      }
    }
    final avgResponseTime = respondedCount > 0 ? (totalResponseDays / respondedCount).round() : 0;

    // Top Companies by Application Count
    final companyCount = <String, int>{};
    for (var app in apps) {
      if (app.company != '—') {
        companyCount[app.company] = (companyCount[app.company] ?? 0) + 1;
      }
    }
    final topCompanies = companyCount.entries
        .map((e) => {'company': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // Application Trend (Last 30 days)
    final now = DateTime.now();
    final last30Days = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
    final trendData = last30Days.map((date) {
      final count = apps.where((app) {
        return app.appliedAt.year == date.year &&
            app.appliedAt.month == date.month &&
            app.appliedAt.day == date.day;
      }).length;
      return {
        'date': date,
        'count': count,
      };
    }).toList();

    // Department Distribution
    final deptCount = <String, int>{};
    for (var app in apps) {
      if (app.department != '—') {
        deptCount[app.department] = (deptCount[app.department] ?? 0) + 1;
      }
    }
    final deptDistribution = deptCount.entries
        .map((e) => {'department': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // Success Rate by Department
    final deptSuccess = <String, Map<String, int>>{};
    for (var app in apps) {
      if (app.department == '—') continue;
      if (!deptSuccess.containsKey(app.department)) {
        deptSuccess[app.department] = {'total': 0, 'accepted': 0};
      }
      deptSuccess[app.department]!['total'] = deptSuccess[app.department]!['total']! + 1;
      if (app.status == 'accepted') {
        deptSuccess[app.department]!['accepted'] = deptSuccess[app.department]!['accepted']! + 1;
      }
    }
    final successByDept = deptSuccess.entries
        .map((e) {
      final total = e.value['total']!;
      final accepted = e.value['accepted']!;
      final rate = total > 0 ? (accepted / total * 100) : 0.0;
      return {
        'department': e.key,
        'rate': rate,
        'accepted': accepted,
        'total': total,
      };
    })
        .toList()
      ..sort((a, b) => (b['rate'] as double).compareTo(a['rate'] as double));

    // Weekly Activity (Last 12 weeks)
    final last12Weeks = List.generate(12, (i) {
      final weekStart = now.subtract(Duration(days: (11 - i) * 7));
      return weekStart.subtract(Duration(days: weekStart.weekday - 1));
    });
    final weeklyActivity = last12Weeks.map((weekStart) {
      final weekEnd = weekStart.add(const Duration(days: 6));
      final count = apps.where((app) {
        return app.appliedAt.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            app.appliedAt.isBefore(weekEnd.add(const Duration(days: 1)));
      }).length;
      return {
        'week': 'W${weekStart.day}/${weekStart.month}',
        'count': count,
      };
    }).toList();

    // Monthly Trend (Last 6 months)
    final last6Months = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - (5 - i), 1);
      return date;
    });
    final monthlyTrend = last6Months.map((month) {
      final count = apps.where((app) {
        return app.appliedAt.year == month.year && app.appliedAt.month == month.month;
      }).length;
      return {
        'month': '${_getMonthName(month.month)} ${month.year}',
        'count': count,
      };
    }).toList();

    return {
      'totalApplications': total,
      'statusBreakdown': {
        'pending': pending,
        'shortlist': shortlisted,
        'accepted': accepted,
        'rejected': rejected,
      },
      'responseRate': responseRate,
      'averageResponseTime': avgResponseTime,
      'topCompanies': topCompanies.take(5).toList(),
      'applicationTrend': trendData,
      'departmentDistribution': deptDistribution,
      'successRateByDepartment': successByDept,
      'weeklyActivity': weeklyActivity,
      'monthlyTrend': monthlyTrend,
    };
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  void dispose() {
    _appsSub?.cancel();
    for (var sub in _jobDocSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }

  /// Cancel all existing listeners and restart them from scratch.
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // 1) cancel the user's applied‐jobs listener
    await _appsSub?.cancel();

    // 2) cancel all per‐job listeners
    for (var sub in _jobDocSubs.values) {
      await sub.cancel();
    }
    _jobDocSubs.clear();
    _jobDataMap.clear();
    _appliedDocs = [];

    // 3) restart
    _startListeners();
  }
}

/// Internal model for displaying in the UI
class _AppRecord {
  final String jobId;
  final String title;
  final String company;
  final String contactEmail;
  final String department;
  final DateTime createdAt;
  final DateTime deadline;
  final DateTime appliedAt;
  final String status;
  final DateTime? responseDate;

  _AppRecord({
    required this.jobId,
    required this.title,
    required this.company,
    required this.contactEmail,
    required this.department,
    required this.createdAt,
    required this.deadline,
    required this.appliedAt,
    required this.status,
    this.responseDate,
  });
}