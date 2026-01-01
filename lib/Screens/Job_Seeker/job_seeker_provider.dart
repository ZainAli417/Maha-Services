// lib/providers/job_seeker_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class JobSeekerProvider extends ChangeNotifier {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _activeJobs = [];
  final List<Map<String, dynamic>> _allJobs = [];
  final List<Map<String, dynamic>> _filteredJobs = [];

  bool _isLoadingActiveJobs = true;
  bool _isLoadingAllJobs = true;
  bool _filtersDirty = false;

  String _searchQuery = '';
  Map<String, dynamic> _activeFilters = {};
  String _sortBy = 'newest';

  StreamSubscription<QuerySnapshot>? _activeJobsSubscription;
  StreamSubscription<QuerySnapshot>? _allJobsSubscription;

  final BehaviorSubject<List<Map<String, dynamic>>> _activeJobsController =
  BehaviorSubject<List<Map<String, dynamic>>>();
  final BehaviorSubject<List<Map<String, dynamic>>> _allJobsController =
  BehaviorSubject<List<Map<String, dynamic>>>();

  JobSeekerProvider() {
    _initializeRealtimeListeners();
  }

  @override
  void dispose() {
    _activeJobsSubscription?.cancel();
    _allJobsSubscription?.cancel();

    _activeJobsController.close();
    _allJobsController.close();

    super.dispose();
  }

  List<Map<String, dynamic>> get activeJobs => List.unmodifiable(_activeJobs);
  List<Map<String, dynamic>> get allJobs => List.unmodifiable(_allJobs);
  List<Map<String, dynamic>> get filteredJobs => List.unmodifiable(_filteredJobs);

  bool get isLoadingActiveJobs => _isLoadingActiveJobs;
  bool get isLoadingAllJobs => _isLoadingAllJobs;
  bool get isLoading => _isLoadingActiveJobs || _isLoadingAllJobs;

  String get searchQuery => _searchQuery;
  Map<String, dynamic> get activeFilters => Map.from(_activeFilters);
  String get sortBy => _sortBy;

  int get activeJobCount => _activeJobs.length;
  int get totalJobCount => _allJobs.length;
  int get filteredJobCount => _filteredJobs.length;

  void _initializeRealtimeListeners() {
    _setupActiveJobsListener();
    _setupAllJobsListener();
  }

  void _setupActiveJobsListener() {
    _activeJobsSubscription?.cancel();
    _activeJobsSubscription = _firestore
        .collection('Posted_jobs_public')
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      _handleActiveJobsUpdate,
      onError: (error, stack) {
        debugPrint('Error listening to active jobs: $error\n$stack');
        _isLoadingActiveJobs = false;
        notifyListeners();
      },
    );
  }
  Timer? _realtimeDebounce;

  void _setupAllJobsListener() {
    _allJobsSubscription?.cancel();
    _allJobsSubscription = _firestore
        .collection('Posted_jobs_public')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      _handleAllJobsUpdate,
      onError: (error, stack) {
        debugPrint('Error listening to all jobs: $error\n$stack');
        _isLoadingAllJobs = false;
        notifyListeners();
      },
    );
  }

  void _handleActiveJobsUpdate(QuerySnapshot snapshot) {
    _realtimeDebounce?.cancel();

    _realtimeDebounce = Timer(const Duration(milliseconds: 200), () {
      try {
        final processed = _processJobSnapshot(snapshot);

        _activeJobs
          ..clear()
          ..addAll(processed);

        _isLoadingActiveJobs = false;
        _applyFiltersAndSearch();
        notifyListeners();
      } catch (e, st) {
        debugPrint('Error processing active jobs snapshot: $e\n$st');
      }
    });
  }

  void _handleAllJobsUpdate(QuerySnapshot snapshot) {
    try {
      final processed = _processJobSnapshot(snapshot);
      _allJobs
        ..clear()
        ..addAll(processed);

      _isLoadingAllJobs = false;
      notifyListeners();

      if (!_allJobsController.isClosed) {
        _allJobsController.add(List<Map<String, dynamic>>.from(_allJobs));
      }

      debugPrint('All jobs updated: ${_allJobs.length} jobs');
    } catch (e, st) {
      debugPrint('Error processing all jobs snapshot: $e\n$st');
      _isLoadingAllJobs = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _processJobSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final raw = doc.data();
      final Map<dynamic, dynamic> normalizedMap =
      (raw is Map) ? Map.from(raw) : <dynamic, dynamic>{};

      final Map<String, dynamic> data = <String, dynamic>{};
      normalizedMap.forEach((k, v) {
        data[k.toString()] = v;
      });

      data['id'] = doc.id;

      data['title'] = data['title']?.toString() ?? 'Untitled Position';
      data['company'] = data['company']?.toString() ?? 'Unknown Company';
      data['location'] = data['location']?.toString() ?? 'Not specified';
      data['salary'] = data['salary']?.toString() ?? 'Not disclosed';
      data['experience'] = data['experience']?.toString() ?? 'Not specified';
      data['department'] = data['department']?.toString() ?? 'General';
      data['description'] = data['description']?.toString() ?? '';
      data['status'] = data['status']?.toString() ?? 'active';

      if (data['skills'] is Iterable) {
        data['skills'] =
            (data['skills'] as Iterable).map((e) => e?.toString() ?? '').toList();
      } else {
        data['skills'] = <String>[];
      }

      if (data['benefits'] is Iterable) {
        data['benefits'] =
            (data['benefits'] as Iterable).map((e) => e?.toString() ?? '').toList();
      } else {
        data['benefits'] = <String>[];
      }

      if (data['workModes'] is Iterable) {
        data['workModes'] =
            (data['workModes'] as Iterable).map((e) => e?.toString() ?? '').toList();
      } else {
        data['workModes'] = <String>[];
      }

      try {
        final ts = data['timestamp'];
        if (ts is Timestamp) {
          data['createdAt'] = ts.toDate().toIso8601String();
        } else if (ts is int) {
          data['createdAt'] = DateTime.fromMillisecondsSinceEpoch(ts).toIso8601String();
        } else if (data['createdAt'] != null) {
          data['createdAt'] = data['createdAt'].toString();
        } else {
          data['createdAt'] = DateTime.now().toIso8601String();
        }
      } catch (_) {
        data['createdAt'] = DateTime.now().toIso8601String();
      }

      return data;
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> publicJobsStream() {
    return _activeJobsController.stream;
  }

  Stream<List<Map<String, dynamic>>> allJobsStream() {
    return _allJobsController.stream;
  }
  void searchJobs(String query) {
    _filtersDirty = true;
    _searchQuery = query.trim().toLowerCase();
    _applyFiltersAndSearch();
    notifyListeners();
  }

  void applyFilters(Map<String, dynamic> filters) {
    _filtersDirty = true;
    _activeFilters = Map.from(filters);
    _applyFiltersAndSearch();
    notifyListeners();
  }

  void setSortBy(String sortOption) {
    _filtersDirty = true;
    _sortBy = sortOption;
    _applyFiltersAndSearch();
    notifyListeners();
  }


  void clearFilters() {
    _searchQuery = '';
    _activeFilters.clear();
    _sortBy = 'newest';
    _applyFiltersAndSearch();
    notifyListeners();
  }

  void _applyFiltersAndSearch() {
    List<Map<String, dynamic>> jobs = List<Map<String, dynamic>>.from(_activeJobs);

    if (_searchQuery.isNotEmpty) {
      jobs = jobs.where(_matchesSearch).toList();
    }

    jobs = _applyAdvancedFilters(jobs);

    jobs = _applySorting(jobs);

    _filteredJobs
      ..clear()
      ..addAll(jobs);
  }

  bool _matchesSearch(Map<String, dynamic> job) {
    if (_searchQuery.isEmpty) return true;

    final searchTerms = _searchQuery.split(' ').where((t) => t.isNotEmpty);
    final searchableContent = [
      job['title']?.toString() ?? '',
      job['company']?.toString() ?? '',
      job['location']?.toString() ?? '',
      job['department']?.toString() ?? '',
      job['description']?.toString() ?? '',
      ...(job['skills'] as List<String>? ?? <String>[]),
    ].join(' ').toLowerCase();

    return searchTerms.every((term) => searchableContent.contains(term));
  }

  List<Map<String, dynamic>> _applyAdvancedFilters(List<Map<String, dynamic>> jobs) {
    if (_activeFilters.isEmpty) return jobs;

    return jobs.where((job) {
      if (_activeFilters['location'] != null &&
          !job['location'].toString().toLowerCase().contains(
            _activeFilters['location'].toString().toLowerCase(),
          )) {
        return false;
      }

      if (_activeFilters['department'] != null &&
          job['department'] != _activeFilters['department']) {
        return false;
      }

      if (_activeFilters['experience'] != null &&
          job['experience'] != _activeFilters['experience']) {
        return false;
      }

      if (_activeFilters['minSalary'] != null) {
        final jobSalary = _extractSalaryNumber(job['salary'].toString());
        if (jobSalary != null && jobSalary < _activeFilters['minSalary']) {
          return false;
        }
      }

      if (_activeFilters['workMode'] != null &&
          !(job['workModes'] as List).contains(_activeFilters['workMode'])) {
        return false;
      }

      if (_activeFilters['requiredSkills'] != null &&
          (_activeFilters['requiredSkills'] as List).isNotEmpty) {
        final jobSkills = job['skills'] as List<String>;
        final requiredSkills = _activeFilters['requiredSkills'] as List<String>;
        if (!requiredSkills.any((skill) => jobSkills.contains(skill))) {
          return false;
        }
      }

      if (_activeFilters['postedAfter'] != null) {
        final jobDate = DateTime.tryParse(job['createdAt'].toString());
        if (jobDate == null || jobDate.isBefore(_activeFilters['postedAfter'])) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _applySorting(List<Map<String, dynamic>> jobs) {
    switch (_sortBy) {
      case 'newest':
        jobs.sort((a, b) {
          final dateA = DateTime.tryParse(a['createdAt'].toString()) ?? DateTime.now();
          final dateB = DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        break;
      case 'oldest':
        jobs.sort((a, b) {
          final dateA = DateTime.tryParse(a['createdAt'].toString()) ?? DateTime.now();
          final dateB = DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
        break;
      case 'salary_high':
        jobs.sort((a, b) {
          final salaryA = _extractSalaryNumber(a['salary'].toString()) ?? 0;
          final salaryB = _extractSalaryNumber(b['salary'].toString()) ?? 0;
          return salaryB.compareTo(salaryA);
        });
        break;
      case 'salary_low':
        jobs.sort((a, b) {
          final salaryA = _extractSalaryNumber(a['salary'].toString()) ?? 0;
          final salaryB = _extractSalaryNumber(b['salary'].toString()) ?? 0;
          return salaryA.compareTo(salaryB);
        });
        break;
      case 'company':
        jobs.sort((a, b) => a['company'].toString().compareTo(b['company'].toString()));
        break;
      case 'location':
        jobs.sort((a, b) => a['location'].toString().compareTo(b['location'].toString()));
        break;
      default:
        break;
    }
    return jobs;
  }

  double? _extractSalaryNumber(String salary) {
    final regex = RegExp(r'[\d,]+');
    final match = regex.firstMatch(salary);
    if (match != null) {
      final numberString = match.group(0)?.replaceAll(',', '');
      return double.tryParse(numberString ?? '');
    }
    return null;
  }

  Map<String, dynamic>? getJobById(String jobId) {
    try {
      return _activeJobs.firstWhere((job) => job['id'] == jobId);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> getJobsByCompany(String company) {
    return _activeJobs
        .where((job) => job['company'].toString().toLowerCase() == company.toLowerCase())
        .toList();
  }

  List<Map<String, dynamic>> getJobsByLocation(String location) {
    return _activeJobs
        .where((job) => job['location'].toString().toLowerCase().contains(location.toLowerCase()))
        .toList();
  }

  List<String> getAllCompanies() {
    return _activeJobs.map((job) => job['company'].toString()).toSet().toList()..sort();
  }

  List<String> getAllLocations() {
    return _activeJobs.map((job) => job['location'].toString()).toSet().toList()..sort();
  }

  List<String> getAllDepartments() {
    return _activeJobs.map((job) => job['department'].toString()).toSet().toList()..sort();
  }

  List<String> getAllSkills() {
    final allSkills = <String>{};
    for (final job in _activeJobs) {
      allSkills.addAll((job['skills'] as List<String>? ?? <String>[]));
    }
    return allSkills.toList()..sort();
  }

  Future<void> refreshJobs() async {
    _isLoadingActiveJobs = true;
    _isLoadingAllJobs = true;
    notifyListeners();

    await _activeJobsSubscription?.cancel();
    await _allJobsSubscription?.cancel();

    _initializeRealtimeListeners();
  }

  void retryConnection() {
    debugPrint('Retrying job data connection...');
    refreshJobs();
  }

  Map<String, int> getJobStatistics() {
    final stats = <String, int>{
      'totalActive': _activeJobs.length,
      'totalAll': _allJobs.length,
      'filtered': _filteredJobs.length,
    };

    final departmentCounts = <String, int>{};
    final locationCounts = <String, int>{};

    for (final job in _activeJobs) {
      final department = job['department'].toString();
      departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;

      final location = job['location'].toString();
      locationCounts[location] = (locationCounts[location] ?? 0) + 1;
    }

    stats['departments'] = departmentCounts.length;
    stats['locations'] = locationCounts.length;
    stats['companies'] = getAllCompanies().length;

    return stats;
  }
}