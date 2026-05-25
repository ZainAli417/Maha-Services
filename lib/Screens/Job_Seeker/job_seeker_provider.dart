import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class JobSeekerProvider extends ChangeNotifier {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _activeJobs = [];
  final List<Map<String, dynamic>> _allJobs = [];
  final List<Map<String, dynamic>> _filteredJobs = [];

  Stream<List<Map<String, dynamic>>> get activeJobsStream =>
      _activeJobsController.stream;
  Stream<List<Map<String, dynamic>>> get allJobsStream =>
      _allJobsController.stream;

  bool _isLoadingActiveJobs = true;
  bool _isLoadingAllJobs = true;

  String _searchQuery = '';
  Map<String, dynamic> _activeFilters = {};
  String _sortBy = 'newest';

  StreamSubscription<QuerySnapshot>? _activeJobsSubscription;
  StreamSubscription<QuerySnapshot>? _allJobsSubscription;
  StreamSubscription<User?>? _authSubscription;

  final BehaviorSubject<List<Map<String, dynamic>>> _activeJobsController =
      BehaviorSubject();
  final BehaviorSubject<List<Map<String, dynamic>>> _allJobsController =
      BehaviorSubject();

  Timer? _activeDebounce;
  Timer? _allDebounce;
  Timer? _filterDebounce;

  // Track if we're currently applying filters to prevent duplicate calls
  bool _isApplyingFilters = false;

  JobSeekerProvider() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _activeJobsSubscription?.cancel();
        _allJobsSubscription?.cancel();
        _activeJobs.clear();
        _allJobs.clear();
        _filteredJobs.clear();
        _isLoadingActiveJobs = false;
        _isLoadingAllJobs = false;
        notifyListeners();
        return;
      }
      _isLoadingActiveJobs = true;
      _isLoadingAllJobs = true;
      notifyListeners();
      _initializeRealtimeListeners();
    });

    if (_auth.currentUser != null) {
      _initializeRealtimeListeners();
    } else {
      _isLoadingActiveJobs = false;
      _isLoadingAllJobs = false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _activeJobsSubscription?.cancel();
    _allJobsSubscription?.cancel();
    _activeDebounce?.cancel();
    _allDebounce?.cancel();
    _filterDebounce?.cancel();
    _activeJobsController.close();
    _allJobsController.close();
    super.dispose();
  }

  // Getters
  List<Map<String, dynamic>> get activeJobs => List.unmodifiable(_activeJobs);
  List<Map<String, dynamic>> get allJobs => List.unmodifiable(_allJobs);
  List<Map<String, dynamic>> get filteredJobs =>
      List.unmodifiable(_filteredJobs);
  bool get isLoadingActiveJobs => _isLoadingActiveJobs;
  bool get isLoadingAllJobs => _isLoadingAllJobs;
  bool get isLoading => _isLoadingActiveJobs || _isLoadingAllJobs;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get activeFilters => Map.from(_activeFilters);
  String get sortBy => _sortBy;

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
        .snapshots(includeMetadataChanges: true)
        .listen(
          _handleActiveJobsUpdate,
          onError: (error) {
            debugPrint('Error in active jobs listener: $error');
            _isLoadingActiveJobs = false;
            notifyListeners();
          },
        );
  }

  void _setupAllJobsListener() {
    _allJobsSubscription?.cancel();
    _allJobsSubscription = _firestore
        .collection('Posted_jobs_public')
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true)
        .listen(
          _handleAllJobsUpdate,
          onError: (error) {
            debugPrint('Error in all jobs listener: $error');
            _isLoadingAllJobs = false;
            notifyListeners();
          },
        );
  }

  void _handleActiveJobsUpdate(QuerySnapshot snapshot) {
    _activeDebounce?.cancel();
    _activeDebounce = Timer(const Duration(milliseconds: 200), () {
      final processed = _processJobSnapshot(snapshot);
      _activeJobs
        ..clear()
        ..addAll(processed);
      _isLoadingActiveJobs = false;

      if (!_activeJobsController.isClosed) _activeJobsController.add(processed);

      _applyFiltersAndSearch();
    });
  }

  void _handleAllJobsUpdate(QuerySnapshot snapshot) {
    _allDebounce?.cancel();
    _allDebounce = Timer(const Duration(milliseconds: 300), () {
      final processed = _processJobSnapshot(snapshot);
      _allJobs
        ..clear()
        ..addAll(processed);
      _isLoadingAllJobs = false;

      if (!_allJobsController.isClosed) _allJobsController.add(processed);
      notifyListeners();
    });
  }

  List<Map<String, dynamic>> _processJobSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final String docId = doc.id;
      final rawData = doc.data() as Map<String, dynamic>;
      final timestamp = rawData['timestamp'];
      final applicationCount = rawData['applicationCount'] ?? 0;

      // Normalization Logic (Optimized structure)
      final Map<String, dynamic> data = {
        'id': docId,
        'title': rawData['title']?.toString() ?? 'Untitled Position',
        'company': rawData['company']?.toString() ?? 'Unknown Company',
        'location': rawData['location']?.toString() ?? 'Not specified',
        'salary': rawData['salary']?.toString() ?? 'Not disclosed',
        'experience': rawData['experience']?.toString() ?? 'Not specified',
        'department': rawData['department']?.toString() ?? 'General',
        'description': rawData['description']?.toString() ?? '',
        'status': rawData['status']?.toString() ?? 'active',
        'nature': rawData['nature']?.toString() ?? 'Full-time',
        'logoUrl': rawData['logoUrl']?.toString(),
        'skills': List<String>.from(rawData['skills'] ?? []),
        'benefits': List<String>.from(rawData['benefits'] ?? []),
        'workModes': List<String>.from(rawData['workModes'] ?? []),
        'applicationCount': applicationCount is int
            ? applicationCount
            : (int.tryParse(applicationCount.toString()) ?? 0),
        'viewCount': _asInt(rawData['viewCount']),
        'timestamp': rawData['timestamp'],
      };

      // Date Handling
      if (timestamp is Timestamp) {
        data['createdAt'] = timestamp.toDate().toIso8601String();
      } else {
        data['createdAt'] = DateTime.now().toIso8601String();
      }

      // OPTIMIZATION: Pre-calculate search string to avoid repetitive joining
      data['_searchContent'] =
          '${data['title']} ${data['company']} ${data['location']} ${data['department']} ${data['skills'].join(' ')}'
              .toLowerCase();

      return data;
    }).toList();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void searchJobs(String query) {
    _searchQuery = query.trim().toLowerCase();
    _debouncedFilterAndSearch();
  }

  void applyFilters(Map<String, dynamic> filters) {
    _activeFilters = Map.from(filters);
    _debouncedFilterAndSearch();
  }

  void setSortBy(String sortOption) {
    _sortBy = sortOption;
    _debouncedFilterAndSearch();
  }

  void clearFilters() {
    _searchQuery = '';
    _activeFilters.clear();
    _sortBy = 'newest';
    _debouncedFilterAndSearch();
  }

  // OPTIMIZATION: Debounce filter and search operations to prevent multiple rapid calls
  void _debouncedFilterAndSearch() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 150), () {
      _applyFiltersAndSearch();
    });
  }

  void _applyFiltersAndSearch() {
    // Prevent duplicate calls
    if (_isApplyingFilters) return;
    _isApplyingFilters = true;

    try {
      // Start with reference for speed
      Iterable<Map<String, dynamic>> jobs = _activeJobs;

      // Filter by search (Using optimized pre-calculated content)
      if (_searchQuery.isNotEmpty) {
        final searchTerms = _searchQuery
            .split(' ')
            .where((t) => t.isNotEmpty)
            .toList();
        jobs = jobs.where((job) {
          final content = job['_searchContent'] as String;
          return searchTerms.every((term) => content.contains(term));
        });
      }

      // Advanced Filters
      if (_activeFilters.isNotEmpty) {
        jobs = jobs.where((job) {
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
              !(job['workModes'] as List).contains(
                _activeFilters['workMode'],
              )) {
            return false;
          }

          if (_activeFilters['requiredSkills'] != null &&
              (_activeFilters['requiredSkills'] as List).isNotEmpty) {
            final jobSkills = job['skills'] as List<String>;
            final required = _activeFilters['requiredSkills'] as List<String>;
            if (!required.any((skill) => jobSkills.contains(skill))) {
              return false;
            }
          }

          if (_activeFilters['postedAfter'] != null) {
            final jobDate = DateTime.tryParse(job['createdAt'].toString());
            if (jobDate == null ||
                jobDate.isBefore(_activeFilters['postedAfter'])) {
              return false;
            }
          }

          return true;
        });
      }

      // Convert to list for sorting
      final resultList = jobs.toList();
      _applySorting(resultList);

      _filteredJobs
        ..clear()
        ..addAll(resultList);

      // Only notify listeners once after all operations
      notifyListeners();
    } finally {
      _isApplyingFilters = false;
    }
  }

  void _applySorting(List<Map<String, dynamic>> jobs) {
    if (jobs.isEmpty) return;

    switch (_sortBy) {
      case 'newest':
        jobs.sort(
          (a, b) =>
              b['createdAt'].toString().compareTo(a['createdAt'].toString()),
        );
        break;
      case 'oldest':
        jobs.sort(
          (a, b) =>
              a['createdAt'].toString().compareTo(b['createdAt'].toString()),
        );
        break;
      case 'salary_high':
        jobs.sort(
          (a, b) => (_extractSalaryNumber(b['salary']) ?? 0).compareTo(
            _extractSalaryNumber(a['salary']) ?? 0,
          ),
        );
        break;
      case 'salary_low':
        jobs.sort(
          (a, b) => (_extractSalaryNumber(a['salary']) ?? 0).compareTo(
            _extractSalaryNumber(b['salary']) ?? 0,
          ),
        );
        break;
      case 'company':
        jobs.sort(
          (a, b) => a['company'].toString().compareTo(b['company'].toString()),
        );
        break;
      case 'applicants_high':
        jobs.sort(
          (a, b) => (b['applicationCount'] as int).compareTo(
            a['applicationCount'] as int,
          ),
        );
        break;
      case 'applicants_low':
        jobs.sort(
          (a, b) => (a['applicationCount'] as int).compareTo(
            b['applicationCount'] as int,
          ),
        );
        break;
    }
  }

  // OPTIMIZATION: Memoize salary extraction
  final Map<String, double?> _salaryCache = {};
  double? _extractSalaryNumber(String salary) {
    if (_salaryCache.containsKey(salary)) return _salaryCache[salary];

    final regex = RegExp(r'[\d,]+');
    final match = regex.firstMatch(salary);
    double? result;
    if (match != null) {
      result = double.tryParse(match.group(0)!.replaceAll(',', ''));
    }

    // Clear cache if it grows too large
    if (_salaryCache.length > 500) {
      _salaryCache.clear();
    }

    _salaryCache[salary] = result;
    return result;
  }

  Future<void> refreshJobs() async {
    _isLoadingActiveJobs = true;
    _isLoadingAllJobs = true;
    _salaryCache.clear();
    notifyListeners();

    await _activeJobsSubscription?.cancel();
    await _allJobsSubscription?.cancel();

    _initializeRealtimeListeners();
  }

  // Get a specific job by ID with real-time applicationCount
  Future<Map<String, dynamic>?> getJobById(String jobId) async {
    try {
      final doc = await _firestore
          .collection('Posted_jobs_public')
          .doc(jobId)
          .get();
      if (!doc.exists) return null;

      final rawData = doc.data() as Map<String, dynamic>;
      final data = {
        'id': doc.id,
        'title': rawData['title']?.toString() ?? 'Untitled Position',
        'company': rawData['company']?.toString() ?? 'Unknown Company',
        'location': rawData['location']?.toString() ?? 'Not specified',
        'salary': rawData['salary']?.toString() ?? 'Not disclosed',
        'experience': rawData['experience']?.toString() ?? 'Not specified',
        'department': rawData['department']?.toString() ?? 'General',
        'description': rawData['description']?.toString() ?? '',
        'status': rawData['status']?.toString() ?? 'active',
        'nature': rawData['nature']?.toString() ?? 'Full-time',
        'logoUrl': rawData['logoUrl']?.toString(),
        'skills': List<String>.from(rawData['skills'] ?? []),
        'benefits': List<String>.from(rawData['benefits'] ?? []),
        'workModes': List<String>.from(rawData['workModes'] ?? []),
        'applicationCount': rawData['applicationCount'] ?? 0,
        'timestamp': rawData['timestamp'],
      };

      if (rawData['timestamp'] is Timestamp) {
        data['createdAt'] = (rawData['timestamp'] as Timestamp)
            .toDate()
            .toIso8601String();
      }

      return data;
    } catch (e) {
      debugPrint('Error fetching job by ID: $e');
      return null;
    }
  }

  // Stream a specific job for real-time updates
  Stream<Map<String, dynamic>?> streamJobById(String jobId) {
    return _firestore
        .collection('Posted_jobs_public')
        .doc(jobId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;

          final rawData = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'title': rawData['title']?.toString() ?? 'Untitled Position',
            'company': rawData['company']?.toString() ?? 'Unknown Company',
            'location': rawData['location']?.toString() ?? 'Not specified',
            'salary': rawData['salary']?.toString() ?? 'Not disclosed',
            'experience': rawData['experience']?.toString() ?? 'Not specified',
            'department': rawData['department']?.toString() ?? 'General',
            'description': rawData['description']?.toString() ?? '',
            'status': rawData['status']?.toString() ?? 'active',
            'nature': rawData['nature']?.toString() ?? 'Full-time',
            'logoUrl': rawData['logoUrl']?.toString(),
            'skills': List<String>.from(rawData['skills'] ?? []),
            'benefits': List<String>.from(rawData['benefits'] ?? []),
            'workModes': List<String>.from(rawData['workModes'] ?? []),
            'applicationCount': rawData['applicationCount'] ?? 0,
            'timestamp': rawData['timestamp'],
            'createdAt': rawData['timestamp'] is Timestamp
                ? (rawData['timestamp'] as Timestamp).toDate().toIso8601String()
                : DateTime.now().toIso8601String(),
          };
        });
  }

  // Simplified logic for statistics
  Map<String, int> getJobStatistics() {
    return {
      'totalActive': _activeJobs.length,
      'totalAll': _allJobs.length,
      'filtered': _filteredJobs.length,
      'departments': _activeJobs.map((j) => j['department']).toSet().length,
      'locations': _activeJobs.map((j) => j['location']).toSet().length,
      'companies': _activeJobs.map((j) => j['company']).toSet().length,
      'totalApplications': _activeJobs.fold<int>(
        0,
        (acc, job) => acc + (job['applicationCount'] as int),
      ),
    };
  }

  // Get jobs with high application counts
  List<Map<String, dynamic>> getTrendingJobs({int limit = 10}) {
    final sortedJobs = List<Map<String, dynamic>>.from(_activeJobs);
    sortedJobs.sort(
      (a, b) => (b['applicationCount'] as int).compareTo(
        a['applicationCount'] as int,
      ),
    );
    return sortedJobs.take(limit).toList();
  }
}

// // }
