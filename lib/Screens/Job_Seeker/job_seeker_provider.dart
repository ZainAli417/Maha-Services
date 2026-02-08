import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class JobSeekerProvider extends ChangeNotifier {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _activeJobs = [];
  final List<Map<String, dynamic>> _allJobs = [];
  final List<Map<String, dynamic>> _filteredJobs = [];

  // OPTIMIZATION: Memoization cache to prevent re-processing unchanged jobs
  final Map<String, Map<String, dynamic>> _jobProcessingCache = {};

  Stream<List<Map<String, dynamic>>> get activeJobsStream => _activeJobsController.stream;
  Stream<List<Map<String, dynamic>>> get allJobsStream => _allJobsController.stream;

  bool _isLoadingActiveJobs = true;
  bool _isLoadingAllJobs = true;

  String _searchQuery = '';
  Map<String, dynamic> _activeFilters = {};
  String _sortBy = 'newest';

  StreamSubscription<QuerySnapshot>? _activeJobsSubscription;
  StreamSubscription<QuerySnapshot>? _allJobsSubscription;

  final BehaviorSubject<List<Map<String, dynamic>>> _activeJobsController = BehaviorSubject();
  final BehaviorSubject<List<Map<String, dynamic>>> _allJobsController = BehaviorSubject();

  Timer? _activeDebounce;
  Timer? _allDebounce;
  Timer? _filterDebounce;

  // Track if we're currently applying filters to prevent duplicate calls
  bool _isApplyingFilters = false;

  JobSeekerProvider() {
    _initializeRealtimeListeners();
  }

  @override
  void dispose() {
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
  List<Map<String, dynamic>> get filteredJobs => List.unmodifiable(_filteredJobs);
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
        .snapshots()
        .listen(_handleActiveJobsUpdate, onError: (error) {
      debugPrint('Error in active jobs listener: $error');
      _isLoadingActiveJobs = false;
      notifyListeners();
    });
  }

  void _setupAllJobsListener() {
    _allJobsSubscription?.cancel();
    _allJobsSubscription = _firestore
        .collection('Posted_jobs_public')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(_handleAllJobsUpdate, onError: (error) {
      debugPrint('Error in all jobs listener: $error');
      _isLoadingAllJobs = false;
      notifyListeners();
    });
  }

  void _handleActiveJobsUpdate(QuerySnapshot snapshot) {
    _activeDebounce?.cancel();
    _activeDebounce = Timer(const Duration(milliseconds: 200), () {
      final processed = _processJobSnapshot(snapshot);
      _activeJobs..clear()..addAll(processed);
      _isLoadingActiveJobs = false;

      if (!_activeJobsController.isClosed) _activeJobsController.add(processed);

      _applyFiltersAndSearch();
    });
  }

  void _handleAllJobsUpdate(QuerySnapshot snapshot) {
    _allDebounce?.cancel();
    _allDebounce = Timer(const Duration(milliseconds: 300), () {
      final processed = _processJobSnapshot(snapshot);
      _allJobs..clear()..addAll(processed);
      _isLoadingAllJobs = false;

      if (!_allJobsController.isClosed) _allJobsController.add(processed);
      notifyListeners();
    });
  }

  List<Map<String, dynamic>> _processJobSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final String docId = doc.id;
      final rawData = doc.data() as Map<String, dynamic>;

      // OPTIMIZATION: Check if job version is already in cache
      final timestamp = rawData['timestamp'];
      final applicationCount = rawData['applicationCount'] ?? 0;
      final cacheKey = '${docId}_${timestamp}_$applicationCount';

      if (_jobProcessingCache.containsKey(cacheKey)) {
        return _jobProcessingCache[cacheKey]!;
      }

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
        // FIX: Extract applicationCount from the document
        'applicationCount': applicationCount is int ? applicationCount : (int.tryParse(applicationCount.toString()) ?? 0),
        'timestamp': rawData['timestamp'],
      };

      // Date Handling
      if (timestamp is Timestamp) {
        data['createdAt'] = timestamp.toDate().toIso8601String();
      } else {
        data['createdAt'] = DateTime.now().toIso8601String();
      }

      // OPTIMIZATION: Pre-calculate search string to avoid repetitive joining
      data['_searchContent'] = '${data['title']} ${data['company']} ${data['location']} ${data['department']} ${data['skills'].join(' ')}'.toLowerCase();

      // Clear old cache entries if it grows too large
      if (_jobProcessingCache.length > 1000) {
        _jobProcessingCache.clear();
      }

      // Store in cache and return
      _jobProcessingCache[cacheKey] = data;
      return data;
    }).toList();
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
        final searchTerms = _searchQuery.split(' ').where((t) => t.isNotEmpty).toList();
        jobs = jobs.where((job) {
          final content = job['_searchContent'] as String;
          return searchTerms.every((term) => content.contains(term));
        });
      }

      // Advanced Filters
      if (_activeFilters.isNotEmpty) {
        jobs = jobs.where((job) {
          if (_activeFilters['location'] != null &&
              !job['location'].toString().toLowerCase().contains(_activeFilters['location'].toString().toLowerCase())) {
            return false;
          }

          if (_activeFilters['department'] != null && job['department'] != _activeFilters['department']) {
            return false;
          }

          if (_activeFilters['experience'] != null && job['experience'] != _activeFilters['experience']) {
            return false;
          }

          if (_activeFilters['minSalary'] != null) {
            final jobSalary = _extractSalaryNumber(job['salary'].toString());
            if (jobSalary != null && jobSalary < _activeFilters['minSalary']) return false;
          }

          if (_activeFilters['workMode'] != null &&
              !(job['workModes'] as List).contains(_activeFilters['workMode'])) {
            return false;
          }

          if (_activeFilters['requiredSkills'] != null &&
              (_activeFilters['requiredSkills'] as List).isNotEmpty) {
            final jobSkills = job['skills'] as List<String>;
            final required = _activeFilters['requiredSkills'] as List<String>;
            if (!required.any((skill) => jobSkills.contains(skill))) return false;
          }

          if (_activeFilters['postedAfter'] != null) {
            final jobDate = DateTime.tryParse(job['createdAt'].toString());
            if (jobDate == null || jobDate.isBefore(_activeFilters['postedAfter'])) return false;
          }

          return true;
        });
      }

      // Convert to list for sorting
      final resultList = jobs.toList();
      _applySorting(resultList);

      _filteredJobs..clear()..addAll(resultList);

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
        jobs.sort((a, b) => b['createdAt'].toString().compareTo(a['createdAt'].toString()));
        break;
      case 'oldest':
        jobs.sort((a, b) => a['createdAt'].toString().compareTo(b['createdAt'].toString()));
        break;
      case 'salary_high':
        jobs.sort((a, b) => (_extractSalaryNumber(b['salary']) ?? 0).compareTo(_extractSalaryNumber(a['salary']) ?? 0));
        break;
      case 'salary_low':
        jobs.sort((a, b) => (_extractSalaryNumber(a['salary']) ?? 0).compareTo(_extractSalaryNumber(b['salary']) ?? 0));
        break;
      case 'company':
        jobs.sort((a, b) => a['company'].toString().compareTo(b['company'].toString()));
        break;
      case 'applicants_high':
        jobs.sort((a, b) => (b['applicationCount'] as int).compareTo(a['applicationCount'] as int));
        break;
      case 'applicants_low':
        jobs.sort((a, b) => (a['applicationCount'] as int).compareTo(b['applicationCount'] as int));
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
    _jobProcessingCache.clear();
    _salaryCache.clear();
    notifyListeners();

    await _activeJobsSubscription?.cancel();
    await _allJobsSubscription?.cancel();

    _initializeRealtimeListeners();
  }

  // Get a specific job by ID with real-time applicationCount
  Future<Map<String, dynamic>?> getJobById(String jobId) async {
    try {
      final doc = await _firestore.collection('Posted_jobs_public').doc(jobId).get();
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
        data['createdAt'] = (rawData['timestamp'] as Timestamp).toDate().toIso8601String();
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
      'totalApplications': _activeJobs.fold<int>(0, (sum, job) => sum + (job['applicationCount'] as int)),
    };
  }

  // Get jobs with high application counts
  List<Map<String, dynamic>> getTrendingJobs({int limit = 10}) {
    final sortedJobs = List<Map<String, dynamic>>.from(_activeJobs);
    sortedJobs.sort((a, b) => (b['applicationCount'] as int).compareTo(a['applicationCount'] as int));
    return sortedJobs.take(limit).toList();
  }
}
//
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/foundation.dart';
// import 'package:rxdart/rxdart.dart';
//
// class JobSeekerProvider extends ChangeNotifier {
//   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   final List<Map<String, dynamic>> _activeJobs = [];
//   final List<Map<String, dynamic>> _allJobs = [];
//   final List<Map<String, dynamic>> _filteredJobs = [];
//
//   // OPTIMIZATION: Memoization cache to prevent re-processing unchanged jobs
//   final Map<String, Map<String, dynamic>> _jobProcessingCache = {};
//   Stream<List<Map<String, dynamic>>> get activeJobsStream => _activeJobsController.stream;
//   Stream<List<Map<String, dynamic>>> get allJobsStream => _allJobsController.stream;
//   bool _isLoadingActiveJobs = true;
//   bool _isLoadingAllJobs = true;
//
//   String _searchQuery = '';
//   Map<String, dynamic> _activeFilters = {};
//   String _sortBy = 'newest';
//
//   StreamSubscription<QuerySnapshot>? _activeJobsSubscription;
//   StreamSubscription<QuerySnapshot>? _allJobsSubscription;
//
//   final BehaviorSubject<List<Map<String, dynamic>>> _activeJobsController = BehaviorSubject();
//   final BehaviorSubject<List<Map<String, dynamic>>> _allJobsController = BehaviorSubject();
//
//   Timer? _activeDebounce;
//   Timer? _allDebounce;
//
//   JobSeekerProvider() {
//     _initializeRealtimeListeners();
//   }
//
//   @override
//   void dispose() {
//     _activeJobsSubscription?.cancel();
//     _allJobsSubscription?.cancel();
//     _activeDebounce?.cancel();
//     _allDebounce?.cancel();
//     _activeJobsController.close();
//     _allJobsController.close();
//     super.dispose();
//   }
//
//   // Getters
//   List<Map<String, dynamic>> get activeJobs => List.unmodifiable(_activeJobs);
//   List<Map<String, dynamic>> get allJobs => List.unmodifiable(_allJobs);
//   List<Map<String, dynamic>> get filteredJobs => List.unmodifiable(_filteredJobs);
//   bool get isLoadingActiveJobs => _isLoadingActiveJobs;
//   bool get isLoadingAllJobs => _isLoadingAllJobs;
//   bool get isLoading => _isLoadingActiveJobs || _isLoadingAllJobs;
//   String get searchQuery => _searchQuery;
//   Map<String, dynamic> get activeFilters => Map.from(_activeFilters);
//   String get sortBy => _sortBy;
//
//   void _initializeRealtimeListeners() {
//     _setupActiveJobsListener();
//     _setupAllJobsListener();
//   }
//
//   void _setupActiveJobsListener() {
//     _activeJobsSubscription?.cancel();
//     _activeJobsSubscription = _firestore
//         .collection('Posted_jobs_public')
//         .where('status', isEqualTo: 'active')
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .listen(_handleActiveJobsUpdate);
//   }
//
//   void _setupAllJobsListener() {
//     _allJobsSubscription?.cancel();
//     _allJobsSubscription = _firestore
//         .collection('Posted_jobs_public')
//         .orderBy('timestamp', descending: true)
//         .snapshots()
//         .listen(_handleAllJobsUpdate);
//   }
//
//   void _handleActiveJobsUpdate(QuerySnapshot snapshot) {
//     _activeDebounce?.cancel();
//     _activeDebounce = Timer(const Duration(milliseconds: 200), () {
//       final processed = _processJobSnapshot(snapshot);
//       _activeJobs..clear()..addAll(processed);
//       _isLoadingActiveJobs = false;
//
//       if (!_activeJobsController.isClosed) _activeJobsController.add(processed);
//
//       _applyFiltersAndSearch();
//       notifyListeners();
//     });
//   }
//
//   void _handleAllJobsUpdate(QuerySnapshot snapshot) {
//     _allDebounce?.cancel();
//     _allDebounce = Timer(const Duration(milliseconds: 300), () {
//       final processed = _processJobSnapshot(snapshot);
//       _allJobs..clear()..addAll(processed);
//       _isLoadingAllJobs = false;
//
//       if (!_allJobsController.isClosed) _allJobsController.add(processed);
//       notifyListeners();
//     });
//   }
//
//   List<Map<String, dynamic>> _processJobSnapshot(QuerySnapshot snapshot) {
//     return snapshot.docs.map((doc) {
//       final String docId = doc.id;
//       final rawData = doc.data() as Map<String, dynamic>;
//
//       // OPTIMIZATION: Check if job version is already in cache
//       final timestamp = rawData['timestamp'];
//       final cacheKey = '${docId}_$timestamp';
//
//       if (_jobProcessingCache.containsKey(cacheKey)) {
//         return _jobProcessingCache[cacheKey]!;
//       }
//
//       // Normalization Logic (Optimized structure)
//       final Map<String, dynamic> data = {
//         'id': docId,
//         'title': rawData['title']?.toString() ?? 'Untitled Position',
//         'company': rawData['company']?.toString() ?? 'Unknown Company',
//         'location': rawData['location']?.toString() ?? 'Not specified',
//         'salary': rawData['salary']?.toString() ?? 'Not disclosed',
//         'experience': rawData['experience']?.toString() ?? 'Not specified',
//         'department': rawData['department']?.toString() ?? 'General',
//         'description': rawData['description']?.toString() ?? '',
//         'status': rawData['status']?.toString() ?? 'active',
//         'skills': List<String>.from(rawData['skills'] ?? []),
//         'benefits': List<String>.from(rawData['benefits'] ?? []),
//         'workModes': List<String>.from(rawData['workModes'] ?? []),
//       };
//
//       // Date Handling
//       if (timestamp is Timestamp) {
//         data['createdAt'] = timestamp.toDate().toIso8601String();
//       } else {
//         data['createdAt'] = DateTime.now().toIso8601String();
//       }
//
//       // OPTIMIZATION: Pre-calculate search string to avoid repetitive joining
//       data['_searchContent'] = '${data['title']} ${data['company']} ${data['location']} ${data['department']} ${data['skills'].join(' ')}'.toLowerCase();
//
//       // Store in cache and return
//       _jobProcessingCache[cacheKey] = data;
//       return data;
//     }).toList();
//   }
//
//   void searchJobs(String query) {
//     _searchQuery = query.trim().toLowerCase();
//     _applyFiltersAndSearch();
//     notifyListeners();
//   }
//
//   void applyFilters(Map<String, dynamic> filters) {
//     _activeFilters = Map.from(filters);
//     _applyFiltersAndSearch();
//     notifyListeners();
//   }
//
//   void setSortBy(String sortOption) {
//     _sortBy = sortOption;
//     _applyFiltersAndSearch();
//     notifyListeners();
//   }
//
//   void clearFilters() {
//     _searchQuery = '';
//     _activeFilters.clear();
//     _sortBy = 'newest';
//     _applyFiltersAndSearch();
//     notifyListeners();
//   }
//
//   void _applyFiltersAndSearch() {
//     // Start with reference for speed
//     Iterable<Map<String, dynamic>> jobs = _activeJobs;
//
//     // Filter by search (Using optimized pre-calculated content)
//     if (_searchQuery.isNotEmpty) {
//       final searchTerms = _searchQuery.split(' ').where((t) => t.isNotEmpty).toList();
//       jobs = jobs.where((job) {
//         final content = job['_searchContent'] as String;
//         return searchTerms.every((term) => content.contains(term));
//       });
//     }
//
//     // Advanced Filters
//     if (_activeFilters.isNotEmpty) {
//       jobs = jobs.where((job) {
//         if (_activeFilters['location'] != null && !job['location'].toString().toLowerCase().contains(_activeFilters['location'].toString().toLowerCase())) return false;
//         if (_activeFilters['department'] != null && job['department'] != _activeFilters['department']) return false;
//         if (_activeFilters['experience'] != null && job['experience'] != _activeFilters['experience']) return false;
//
//         if (_activeFilters['minSalary'] != null) {
//           final jobSalary = _extractSalaryNumber(job['salary'].toString());
//           if (jobSalary != null && jobSalary < _activeFilters['minSalary']) return false;
//         }
//
//         if (_activeFilters['workMode'] != null && !(job['workModes'] as List).contains(_activeFilters['workMode'])) return false;
//
//         if (_activeFilters['requiredSkills'] != null && (_activeFilters['requiredSkills'] as List).isNotEmpty) {
//           final jobSkills = job['skills'] as List<String>;
//           final required = _activeFilters['requiredSkills'] as List<String>;
//           if (!required.any((skill) => jobSkills.contains(skill))) return false;
//         }
//
//         if (_activeFilters['postedAfter'] != null) {
//           final jobDate = DateTime.tryParse(job['createdAt'].toString());
//           if (jobDate == null || jobDate.isBefore(_activeFilters['postedAfter'])) return false;
//         }
//         return true;
//       });
//     }
//
//     // Convert to list for sorting
//     final resultList = jobs.toList();
//     _applySorting(resultList);
//
//     _filteredJobs..clear()..addAll(resultList);
//   }
//
//   void _applySorting(List<Map<String, dynamic>> jobs) {
//     if (jobs.isEmpty) return;
//
//     switch (_sortBy) {
//       case 'newest':
//         jobs.sort((a, b) => b['createdAt'].toString().compareTo(a['createdAt'].toString()));
//         break;
//       case 'oldest':
//         jobs.sort((a, b) => a['createdAt'].toString().compareTo(b['createdAt'].toString()));
//         break;
//       case 'salary_high':
//         jobs.sort((a, b) => (_extractSalaryNumber(b['salary']) ?? 0).compareTo(_extractSalaryNumber(a['salary']) ?? 0));
//         break;
//       case 'salary_low':
//         jobs.sort((a, b) => (_extractSalaryNumber(a['salary']) ?? 0).compareTo(_extractSalaryNumber(b['salary']) ?? 0));
//         break;
//       case 'company':
//         jobs.sort((a, b) => a['company'].compareTo(b['company']));
//         break;
//     }
//   }
//
//   // OPTIMIZATION: Memoize salary extraction
//   final Map<String, double?> _salaryCache = {};
//   double? _extractSalaryNumber(String salary) {
//     if (_salaryCache.containsKey(salary)) return _salaryCache[salary];
//
//     final regex = RegExp(r'[\d,]+');
//     final match = regex.firstMatch(salary);
//     double? result;
//     if (match != null) {
//       result = double.tryParse(match.group(0)!.replaceAll(',', ''));
//     }
//     _salaryCache[salary] = result;
//     return result;
//   }
//
//   // Rest of the methods remain same but utilize the lists efficiently...
//   Future<void> refreshJobs() async {
//     _isLoadingActiveJobs = true;
//     _isLoadingAllJobs = true;
//     _jobProcessingCache.clear();
//     _salaryCache.clear();
//     notifyListeners();
//     await _activeJobsSubscription?.cancel();
//     await _allJobsSubscription?.cancel();
//     _initializeRealtimeListeners();
//   }
//
//   // Simplified logic for statistics
//   Map<String, int> getJobStatistics() {
//     return {
//       'totalActive': _activeJobs.length,
//       'totalAll': _allJobs.length,
//       'filtered': _filteredJobs.length,
//       'departments': _activeJobs.map((j) => j['department']).toSet().length,
//       'locations': _activeJobs.map((j) => j['location']).toSet().length,
//       'companies': _activeJobs.map((j) => j['company']).toSet().length,
//     };
//   }
// }
//
// // // lib/providers/job_seeker_provider.dart
// // import 'dart:async';
// //
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:fl_chart/fl_chart.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:rxdart/rxdart.dart';
// //
// // class JobSeekerProvider extends ChangeNotifier {
// //   static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// //
// //   final List<Map<String, dynamic>> _activeJobs = [];
// //   final List<Map<String, dynamic>> _allJobs = [];
// //   final List<Map<String, dynamic>> _filteredJobs = [];
// //
// //   bool _isLoadingActiveJobs = true;
// //   bool _isLoadingAllJobs = true;
// //   bool _filtersDirty = false;
// //
// //   String _searchQuery = '';
// //   Map<String, dynamic> _activeFilters = {};
// //   String _sortBy = 'newest';
// //
// //   StreamSubscription<QuerySnapshot>? _activeJobsSubscription;
// //   StreamSubscription<QuerySnapshot>? _allJobsSubscription;
// //
// //   final BehaviorSubject<List<Map<String, dynamic>>> _activeJobsController =
// //   BehaviorSubject<List<Map<String, dynamic>>>();
// //   final BehaviorSubject<List<Map<String, dynamic>>> _allJobsController =
// //   BehaviorSubject<List<Map<String, dynamic>>>();
// //
// //   JobSeekerProvider() {
// //     _initializeRealtimeListeners();
// //   }
// //
// //   @override
// //   void dispose() {
// //     _activeJobsSubscription?.cancel();
// //     _allJobsSubscription?.cancel();
// //
// //     _activeJobsController.close();
// //     _allJobsController.close();
// //
// //     super.dispose();
// //   }
// //
// //   List<Map<String, dynamic>> get activeJobs => List.unmodifiable(_activeJobs);
// //   List<Map<String, dynamic>> get allJobs => List.unmodifiable(_allJobs);
// //   List<Map<String, dynamic>> get filteredJobs => List.unmodifiable(_filteredJobs);
// //
// //   bool get isLoadingActiveJobs => _isLoadingActiveJobs;
// //   bool get isLoadingAllJobs => _isLoadingAllJobs;
// //   bool get isLoading => _isLoadingActiveJobs || _isLoadingAllJobs;
// //
// //   String get searchQuery => _searchQuery;
// //   Map<String, dynamic> get activeFilters => Map.from(_activeFilters);
// //   String get sortBy => _sortBy;
// //
// //   int get activeJobCount => _activeJobs.length;
// //   int get totalJobCount => _allJobs.length;
// //   int get filteredJobCount => _filteredJobs.length;
// //
// //   void _initializeRealtimeListeners() {
// //     _setupActiveJobsListener();
// //     _setupAllJobsListener();
// //   }
// //
// //   void _setupActiveJobsListener() {
// //     _activeJobsSubscription?.cancel();
// //     _activeJobsSubscription = _firestore
// //         .collection('Posted_jobs_public')
// //         .where('status', isEqualTo: 'active')
// //         .orderBy('timestamp', descending: true)
// //         .snapshots()
// //         .listen(
// //       _handleActiveJobsUpdate,
// //       onError: (error, stack) {
// //         debugPrint('Error listening to active jobs: $error\n$stack');
// //         _isLoadingActiveJobs = false;
// //         notifyListeners();
// //       },
// //     );
// //   }
// //   Timer? _realtimeDebounce;
// //
// //   void _setupAllJobsListener() {
// //     _allJobsSubscription?.cancel();
// //     _allJobsSubscription = _firestore
// //         .collection('Posted_jobs_public')
// //         .orderBy('timestamp', descending: true)
// //         .snapshots()
// //         .listen(
// //       _handleAllJobsUpdate,
// //       onError: (error, stack) {
// //         debugPrint('Error listening to all jobs: $error\n$stack');
// //         _isLoadingAllJobs = false;
// //         notifyListeners();
// //       },
// //     );
// //   }
// //
// //   void _handleActiveJobsUpdate(QuerySnapshot snapshot) {
// //     _realtimeDebounce?.cancel();
// //
// //     _realtimeDebounce = Timer(const Duration(milliseconds: 200), () {
// //       try {
// //         final processed = _processJobSnapshot(snapshot);
// //
// //         _activeJobs
// //           ..clear()
// //           ..addAll(processed);
// //
// //         _isLoadingActiveJobs = false;
// //         _applyFiltersAndSearch();
// //         notifyListeners();
// //       } catch (e, st) {
// //         debugPrint('Error processing active jobs snapshot: $e\n$st');
// //       }
// //     });
// //   }
// //
// //   void _handleAllJobsUpdate(QuerySnapshot snapshot) {
// //     try {
// //       final processed = _processJobSnapshot(snapshot);
// //       _allJobs
// //         ..clear()
// //         ..addAll(processed);
// //
// //       _isLoadingAllJobs = false;
// //       notifyListeners();
// //
// //       if (!_allJobsController.isClosed) {
// //         _allJobsController.add(List<Map<String, dynamic>>.from(_allJobs));
// //       }
// //
// //       debugPrint('All jobs updated: ${_allJobs.length} jobs');
// //     } catch (e, st) {
// //       debugPrint('Error processing all jobs snapshot: $e\n$st');
// //       _isLoadingAllJobs = false;
// //       notifyListeners();
// //     }
// //   }
// //
// //   List<Map<String, dynamic>> _processJobSnapshot(QuerySnapshot snapshot) {
// //     return snapshot.docs.map((doc) {
// //       final raw = doc.data();
// //       final Map<dynamic, dynamic> normalizedMap =
// //       (raw is Map) ? Map.from(raw) : <dynamic, dynamic>{};
// //
// //       final Map<String, dynamic> data = <String, dynamic>{};
// //       normalizedMap.forEach((k, v) {
// //         data[k.toString()] = v;
// //       });
// //
// //       data['id'] = doc.id;
// //
// //       data['title'] = data['title']?.toString() ?? 'Untitled Position';
// //       data['company'] = data['company']?.toString() ?? 'Unknown Company';
// //       data['location'] = data['location']?.toString() ?? 'Not specified';
// //       data['salary'] = data['salary']?.toString() ?? 'Not disclosed';
// //       data['experience'] = data['experience']?.toString() ?? 'Not specified';
// //       data['department'] = data['department']?.toString() ?? 'General';
// //       data['description'] = data['description']?.toString() ?? '';
// //       data['status'] = data['status']?.toString() ?? 'active';
// //
// //       if (data['skills'] is Iterable) {
// //         data['skills'] =
// //             (data['skills'] as Iterable).map((e) => e?.toString() ?? '').toList();
// //       } else {
// //         data['skills'] = <String>[];
// //       }
// //
// //       if (data['benefits'] is Iterable) {
// //         data['benefits'] =
// //             (data['benefits'] as Iterable).map((e) => e?.toString() ?? '').toList();
// //       } else {
// //         data['benefits'] = <String>[];
// //       }
// //
// //       if (data['workModes'] is Iterable) {
// //         data['workModes'] =
// //             (data['workModes'] as Iterable).map((e) => e?.toString() ?? '').toList();
// //       } else {
// //         data['workModes'] = <String>[];
// //       }
// //
// //       try {
// //         final ts = data['timestamp'];
// //         if (ts is Timestamp) {
// //           data['createdAt'] = ts.toDate().toIso8601String();
// //         } else if (ts is int) {
// //           data['createdAt'] = DateTime.fromMillisecondsSinceEpoch(ts).toIso8601String();
// //         } else if (data['createdAt'] != null) {
// //           data['createdAt'] = data['createdAt'].toString();
// //         } else {
// //           data['createdAt'] = DateTime.now().toIso8601String();
// //         }
// //       } catch (_) {
// //         data['createdAt'] = DateTime.now().toIso8601String();
// //       }
// //
// //       return data;
// //     }).toList();
// //   }
// //
// //   Stream<List<Map<String, dynamic>>> publicJobsStream() {
// //     return _activeJobsController.stream;
// //   }
// //
// //   Stream<List<Map<String, dynamic>>> allJobsStream() {
// //     return _allJobsController.stream;
// //   }
// //   void searchJobs(String query) {
// //     _filtersDirty = true;
// //     _searchQuery = query.trim().toLowerCase();
// //     _applyFiltersAndSearch();
// //     notifyListeners();
// //   }
// //
// //   void applyFilters(Map<String, dynamic> filters) {
// //     _filtersDirty = true;
// //     _activeFilters = Map.from(filters);
// //     _applyFiltersAndSearch();
// //     notifyListeners();
// //   }
// //
// //   void setSortBy(String sortOption) {
// //     _filtersDirty = true;
// //     _sortBy = sortOption;
// //     _applyFiltersAndSearch();
// //     notifyListeners();
// //   }
// //
// //
// //   void clearFilters() {
// //     _searchQuery = '';
// //     _activeFilters.clear();
// //     _sortBy = 'newest';
// //     _applyFiltersAndSearch();
// //     notifyListeners();
// //   }
// //
// //   void _applyFiltersAndSearch() {
// //     List<Map<String, dynamic>> jobs = List<Map<String, dynamic>>.from(_activeJobs);
// //
// //     if (_searchQuery.isNotEmpty) {
// //       jobs = jobs.where(_matchesSearch).toList();
// //     }
// //
// //     jobs = _applyAdvancedFilters(jobs);
// //
// //     jobs = _applySorting(jobs);
// //
// //     _filteredJobs
// //       ..clear()
// //       ..addAll(jobs);
// //   }
// //
// //   bool _matchesSearch(Map<String, dynamic> job) {
// //     if (_searchQuery.isEmpty) return true;
// //
// //     final searchTerms = _searchQuery.split(' ').where((t) => t.isNotEmpty);
// //     final searchableContent = [
// //       job['title']?.toString() ?? '',
// //       job['company']?.toString() ?? '',
// //       job['location']?.toString() ?? '',
// //       job['department']?.toString() ?? '',
// //       job['description']?.toString() ?? '',
// //       ...(job['skills'] as List<String>? ?? <String>[]),
// //     ].join(' ').toLowerCase();
// //
// //     return searchTerms.every((term) => searchableContent.contains(term));
// //   }
// //
// //   List<Map<String, dynamic>> _applyAdvancedFilters(List<Map<String, dynamic>> jobs) {
// //     if (_activeFilters.isEmpty) return jobs;
// //
// //     return jobs.where((job) {
// //       if (_activeFilters['location'] != null &&
// //           !job['location'].toString().toLowerCase().contains(
// //             _activeFilters['location'].toString().toLowerCase(),
// //           )) {
// //         return false;
// //       }
// //
// //       if (_activeFilters['department'] != null &&
// //           job['department'] != _activeFilters['department']) {
// //         return false;
// //       }
// //
// //       if (_activeFilters['experience'] != null &&
// //           job['experience'] != _activeFilters['experience']) {
// //         return false;
// //       }
// //
// //       if (_activeFilters['minSalary'] != null) {
// //         final jobSalary = _extractSalaryNumber(job['salary'].toString());
// //         if (jobSalary != null && jobSalary < _activeFilters['minSalary']) {
// //           return false;
// //         }
// //       }
// //
// //       if (_activeFilters['workMode'] != null &&
// //           !(job['workModes'] as List).contains(_activeFilters['workMode'])) {
// //         return false;
// //       }
// //
// //       if (_activeFilters['requiredSkills'] != null &&
// //           (_activeFilters['requiredSkills'] as List).isNotEmpty) {
// //         final jobSkills = job['skills'] as List<String>;
// //         final requiredSkills = _activeFilters['requiredSkills'] as List<String>;
// //         if (!requiredSkills.any((skill) => jobSkills.contains(skill))) {
// //           return false;
// //         }
// //       }
// //
// //       if (_activeFilters['postedAfter'] != null) {
// //         final jobDate = DateTime.tryParse(job['createdAt'].toString());
// //         if (jobDate == null || jobDate.isBefore(_activeFilters['postedAfter'])) {
// //           return false;
// //         }
// //       }
// //
// //       return true;
// //     }).toList();
// //   }
// //
// //   List<Map<String, dynamic>> _applySorting(List<Map<String, dynamic>> jobs) {
// //     switch (_sortBy) {
// //       case 'newest':
// //         jobs.sort((a, b) {
// //           final dateA = DateTime.tryParse(a['createdAt'].toString()) ?? DateTime.now();
// //           final dateB = DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now();
// //           return dateB.compareTo(dateA);
// //         });
// //         break;
// //       case 'oldest':
// //         jobs.sort((a, b) {
// //           final dateA = DateTime.tryParse(a['createdAt'].toString()) ?? DateTime.now();
// //           final dateB = DateTime.tryParse(b['createdAt'].toString()) ?? DateTime.now();
// //           return dateA.compareTo(dateB);
// //         });
// //         break;
// //       case 'salary_high':
// //         jobs.sort((a, b) {
// //           final salaryA = _extractSalaryNumber(a['salary'].toString()) ?? 0;
// //           final salaryB = _extractSalaryNumber(b['salary'].toString()) ?? 0;
// //           return salaryB.compareTo(salaryA);
// //         });
// //         break;
// //       case 'salary_low':
// //         jobs.sort((a, b) {
// //           final salaryA = _extractSalaryNumber(a['salary'].toString()) ?? 0;
// //           final salaryB = _extractSalaryNumber(b['salary'].toString()) ?? 0;
// //           return salaryA.compareTo(salaryB);
// //         });
// //         break;
// //       case 'company':
// //         jobs.sort((a, b) => a['company'].toString().compareTo(b['company'].toString()));
// //         break;
// //       case 'location':
// //         jobs.sort((a, b) => a['location'].toString().compareTo(b['location'].toString()));
// //         break;
// //       default:
// //         break;
// //     }
// //     return jobs;
// //   }
// //
// //   double? _extractSalaryNumber(String salary) {
// //     final regex = RegExp(r'[\d,]+');
// //     final match = regex.firstMatch(salary);
// //     if (match != null) {
// //       final numberString = match.group(0)?.replaceAll(',', '');
// //       return double.tryParse(numberString ?? '');
// //     }
// //     return null;
// //   }
// //
// //   Map<String, dynamic>? getJobById(String jobId) {
// //     try {
// //       return _activeJobs.firstWhere((job) => job['id'] == jobId);
// //     } catch (e) {
// //       return null;
// //     }
// //   }
// //
// //   List<Map<String, dynamic>> getJobsByCompany(String company) {
// //     return _activeJobs
// //         .where((job) => job['company'].toString().toLowerCase() == company.toLowerCase())
// //         .toList();
// //   }
// //
// //   List<Map<String, dynamic>> getJobsByLocation(String location) {
// //     return _activeJobs
// //         .where((job) => job['location'].toString().toLowerCase().contains(location.toLowerCase()))
// //         .toList();
// //   }
// //
// //   List<String> getAllCompanies() {
// //     return _activeJobs.map((job) => job['company'].toString()).toSet().toList()..sort();
// //   }
// //
// //   List<String> getAllLocations() {
// //     return _activeJobs.map((job) => job['location'].toString()).toSet().toList()..sort();
// //   }
// //
// //   List<String> getAllDepartments() {
// //     return _activeJobs.map((job) => job['department'].toString()).toSet().toList()..sort();
// //   }
// //
// //   List<String> getAllSkills() {
// //     final allSkills = <String>{};
// //     for (final job in _activeJobs) {
// //       allSkills.addAll((job['skills'] as List<String>? ?? <String>[]));
// //     }
// //     return allSkills.toList()..sort();
// //   }
// //
// //   Future<void> refreshJobs() async {
// //     _isLoadingActiveJobs = true;
// //     _isLoadingAllJobs = true;
// //     notifyListeners();
// //
// //     await _activeJobsSubscription?.cancel();
// //     await _allJobsSubscription?.cancel();
// //
// //     _initializeRealtimeListeners();
// //   }
// //
// //   void retryConnection() {
// //     debugPrint('Retrying job data connection...');
// //     refreshJobs();
// //   }
// //
// //   Map<String, int> getJobStatistics() {
// //     final stats = <String, int>{
// //       'totalActive': _activeJobs.length,
// //       'totalAll': _allJobs.length,
// //       'filtered': _filteredJobs.length,
// //     };
// //
// //     final departmentCounts = <String, int>{};
// //     final locationCounts = <String, int>{};
// //
// //     for (final job in _activeJobs) {
// //       final department = job['department'].toString();
// //       departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;
// //
// //       final location = job['location'].toString();
// //       locationCounts[location] = (locationCounts[location] ?? 0) + 1;
// //     }
// //
// //     stats['departments'] = departmentCounts.length;
// //     stats['locations'] = locationCounts.length;
// //     stats['companies'] = getAllCompanies().length;
// //
// //     return stats;
// //   }
// //   Future<Map<String, dynamic>> _getJobStatistics(String jobId) async {
// //     // Fetch applicants for this job from Firestore
// //     final applicantsSnapshot = await FirebaseFirestore.instance
// //         .collection('Posted_jobs_public')
// //         .doc(jobId)
// //         .collection('applicants')
// //         .get();
// //
// //     int totalApplicants = applicantsSnapshot.docs.length;
// //     int pending = 0;
// //     int accepted = 0;
// //     int rejected = 0;
// //     int underReview = 0;
// //
// //     // Group by date for trend
// //     Map<DateTime, int> dailyApplicants = {};
// //
// //     for (var doc in applicantsSnapshot.docs) {
// //       final data = doc.data();
// //       final status = data['status']?.toString().toLowerCase() ?? 'pending';
// //
// //       // Count by status
// //       switch (status) {
// //         case 'accepted':
// //         case 'approved':
// //           accepted++;
// //           break;
// //         case 'rejected':
// //         case 'declined':
// //           rejected++;
// //           break;
// //         case 'under review':
// //         case 'reviewing':
// //           underReview++;
// //           break;
// //         default:
// //           pending++;
// //       }
// //
// //       // Count by date for trend
// //       final timestamp = data['appliedAt'] as Timestamp?;
// //       if (timestamp != null) {
// //         final date = DateTime(
// //           timestamp.toDate().year,
// //           timestamp.toDate().month,
// //           timestamp.toDate().day,
// //         );
// //         dailyApplicants[date] = (dailyApplicants[date] ?? 0) + 1;
// //       }
// //     }
// //
// //     // Sort dates and create cumulative trend
// //     final sortedDates = dailyApplicants.keys.toList()..sort();
// //     List<FlSpot> trendData = [];
// //     int cumulative = 0;
// //
// //     for (int i = 0; i < sortedDates.length; i++) {
// //       cumulative += dailyApplicants[sortedDates[i]] ?? 0;
// //       trendData.add(FlSpot(i.toDouble(), cumulative.toDouble()));
// //     }
// //
// //     return {
// //       'total': totalApplicants,
// //       'pending': pending,
// //       'accepted': accepted,
// //       'rejected': rejected,
// //       'underReview': underReview,
// //       'trendData': trendData,
// //       'dates': sortedDates,
// //     };
// //   }
// //
// // }