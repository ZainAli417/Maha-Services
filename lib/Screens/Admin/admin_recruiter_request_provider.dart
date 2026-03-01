// admin_recruiter_request_provider.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_snackbars.dart';

class AdminProvider extends ChangeNotifier {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roleController = TextEditingController();
  final _userLevelController = TextEditingController();

  String? _editingUserId;
  bool _isLoading = false;
  String _message = '';

  // Getters
  GlobalKey<FormState> get formKey => _formKey;

  TextEditingController get nameController => _nameController;

  TextEditingController get emailController => _emailController;

  TextEditingController get passwordController => _passwordController;

  TextEditingController get roleController => _roleController;

  TextEditingController get userLevelController => _userLevelController;

  String? get editingUserId => _editingUserId;

  bool get isLoading => _isLoading;

  String get message => _message;

  Future<bool> addOrEditUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      _isLoading = true;
      _message = '';
      _safeNotify();

      try {
        String uid;
        DocumentReference userDocRef;

        if (_editingUserId == null) {
          // CREATE NEW USER WITHOUT SIGNING OUT THE ADMIN
          FirebaseApp tempApp;
          try {
            tempApp = Firebase.app('TemporaryUserCreator');
          } catch (_) {
            tempApp = await Firebase.initializeApp(
              name: 'TemporaryUserCreator',
              options: Firebase.app().options,
            );
          }

          final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
          final userCredential = await tempAuth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          uid = userCredential.user!.uid;
          await tempAuth.signOut();

          userDocRef = _firestore.collection('users').doc(uid);

          await userDocRef.set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'uid': uid,
            'role': _roleController.text.trim(),
            'isNew': 'yes',
            'account_status': 'active',
            'user_lvl': _userLevelController.text.trim(),
            'created_at': FieldValue.serverTimestamp(),
          });
        } else {
          // EDIT EXISTING USER
          userDocRef = _firestore.collection('users').doc(_editingUserId);

          await userDocRef.update({
            'name': _nameController.text.trim(),
            'role': _roleController.text.trim(),
            'user_lvl': _userLevelController.text.trim(),
          });
          uid = _editingUserId!;
        }

        _message = _editingUserId == null
            ? 'User added successfully'
            : 'User updated successfully';

        // Remove from cache if edited
        _candidateCache.remove(uid);
        _recruiterCache.remove(uid);
        _emailToUidCache.remove(_emailController.text.trim());

        clearForm();
        return true;
      } catch (e) {
        _message = 'Error: $e';
        debugPrint('❌ addOrEditUser error: $e');
        return false;
      } finally {
        _isLoading = false;
        _safeNotify();
      }
    }
    return false;
  }

  Future<void> suspendUser(String firestoreDocId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firestoreDocId)
          .update({'account_status': newStatus});
    } catch (e) {
      debugPrint('❌ Error suspending user: $e');
    }
    _safeNotify();
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('❌ Error resetting password: $e');
    }
  }

  void editUser(Map<String, dynamic> userData, String firestoreDocId,
      {String? resolvedName}) {
    _nameController.text = resolvedName ?? userData['name'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _roleController.text = userData['role'] ?? '';
    _userLevelController.text = userData['user_lvl'] ?? '';
    _passwordController.clear();
    _editingUserId = firestoreDocId;
    _safeNotify();
  }

  void clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _roleController.clear();
    _userLevelController.clear();
    _editingUserId = null;
    _message = '';
    _safeNotify();
  }

  // ============================================================================
  // OPTIMIZED ADMIN DASHBOARD PROVIDER
  // ============================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool loading = false;
  bool _disposed = false;

  /// Top-level list of request documents
  List<Map<String, dynamic>> requests = [];

  /// MULTI-LEVEL CACHING SYSTEM
  // Cache with TTL (Time To Live)
  final Map<String, _CacheEntry> _recruiterCache = {};
  final Map<String, _CacheEntry> _candidateCache = {};
  final Map<String, _CacheEntry> _requestDetailsCache = {};
  final Map<String, String> _emailToUidCache = {};

  static const Duration _cacheTTL = Duration(minutes: 10);

  /// Realtime subscription
  StreamSubscription<QuerySnapshot>? _requestsSub;

  /// Batch fetch queue to reduce multiple simultaneous calls
  final Map<String, Completer<Map<String, dynamic>?>> _pendingFetches = {};

  /// Debounce timer for notifications
  Timer? _notifyTimer;

  String? _selectedRequestId;

  String? get selectedRequestId => _selectedRequestId;

  Map<String, dynamic>? get selectedRequestDetails {
    if (_selectedRequestId == null) return null;
    return _requestDetailsCache[_selectedRequestId]?.data;
  }

  Future<void> selectRequest(String requestId) async {
    if (_selectedRequestId == requestId) return;
    _selectedRequestId = requestId;
    _safeNotify();
    if (!_requestDetailsCache.containsKey(requestId)) {
      await fetchRequestDetails(requestId: requestId);
    }
  }

  void _safeNotify() {
    if (_disposed) return;
    Future.microtask(() {
      if (!_disposed) notifyListeners();
    });
  }


  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Map<String, dynamic> _normalizeMap(dynamic m) {
    if (m == null) return <String, dynamic>{};
    if (m is Map<String, dynamic>) return m;
    if (m is Map) {
      final out = <String, dynamic>{};
      m.forEach((k, v) {
        final key = k?.toString() ?? '';
        out[key] = v;
      });
      return out;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _normalizeList(dynamic list) {
    if (list == null) return [];
    if (list is List) return List<dynamic>.from(list);
    return [];
  }

  String _canon(String s) => s.trim().toLowerCase();

  String _lastSegment(String s) {
    final str = s.trim();
    if (str.contains('/')) {
      final parts = str.split('/');
      return parts.isNotEmpty ? parts.last : str;
    }
    return str;
  }

  // ============================================================================
  // OPTIMIZED FETCH ALL REQUESTS
  // ============================================================================

  Future<void> fetchAllRequests({bool realtime = false}) async {
    if (loading) {
      debugPrint('⏭️ Already loading, skipping duplicate call');
      return;
    }

    loading = true;
    _safeNotify();
    debugPrint('🔍 Admin: fetchAllRequests(realtime=$realtime)');

    try {
      // Use cache-first strategy for web
      final snap = await _firestore
          .collection('recruiter_requests')
          .orderBy('created_at', descending: true)
          .get(const GetOptions(source: Source.cache))
          .catchError((_) =>
          _firestore
              .collection('recruiter_requests')
              .orderBy('created_at', descending: true)
              .get(const GetOptions(source: Source.server)));

      debugPrint('🔎 Found ${snap.docs.length} request docs');

      final List<Map<String, dynamic>> tmp = [];
      final Set<String> recruiterIds = {};

      for (final d in snap.docs) {
        final data = _normalizeMap(d.data());

        final recruiterId = (data['recruiter_id'] ??
            data['recruiter'] ??
            data['recruiter_uid'] ??
            '')
            .toString();
        final recruiterEmail =
        (data['recruiter_email'] ?? data['recruiterEmail'] ?? '')
            .toString();

        // Calculate total_candidates efficiently
        int totalCandidates = 0;
        if (data['total_candidates'] != null) {
          totalCandidates =
              int.tryParse(data['total_candidates'].toString()) ?? 0;
        } else {
          final candidateIds = _normalizeList(data['candidate_ids']);
          final candidates = _normalizeList(data['candidates']);
          totalCandidates = candidateIds.isNotEmpty
              ? candidateIds.length
              : candidates.length;
        }

        final status = (data['status'] ?? 'pending').toString();
        final createdAt = data['created_at'];

        tmp.add({
          'id': d.id,
          'recruiter_id': recruiterId,
          'recruiter_email': recruiterEmail,
          'total_candidates': totalCandidates,
          'status': status,
          'created_at': createdAt,
          'notes': data['notes'] ?? '',
          'raw': data,
        });

        if (recruiterId.isNotEmpty) recruiterIds.add(recruiterId);
      }

      requests = tmp;
      debugPrint('✅ Admin: loaded ${requests.length} request(s)');

      // Prefetch recruiters in parallel batches
      if (recruiterIds.isNotEmpty) {
        _batchPrefetchRecruiters(recruiterIds.toList());
      }
    } catch (e, st) {
      debugPrint('❌ fetchAllRequests failed: $e\n$st');
      requests = [];
    } finally {
      loading = false;
      _safeNotify();
    }

    if (realtime) {
      debugPrint('🔁 Admin: enabling realtime listener');
      _startRealtimeListener();
    }
  }

  // ============================================================================
  // BATCH PREFETCH RECRUITERS (Parallel Processing)
  // ============================================================================

  Future<void> _batchPrefetchRecruiters(List<String> recruiterIds) async {
    const batchSize = 10; // Firestore allows 10 'in' queries
    final batches = <List<String>>[];

    for (var i = 0; i < recruiterIds.length; i += batchSize) {
      batches.add(recruiterIds.sublist(
          i, i + batchSize > recruiterIds.length ? recruiterIds.length : i +
          batchSize));
    }

    debugPrint('📦 Prefetching ${recruiterIds.length} recruiters in ${batches
        .length} batches');

    try {
      await Future.wait(batches.map((batch) async {
        final snap = await _firestore
            .collection('recruiter')
            .where(FieldPath.documentId, whereIn: batch)
            .get(const GetOptions(source: Source.cache))
            .catchError((_) =>
            _firestore
                .collection('recruiter')
                .where(FieldPath.documentId, whereIn: batch)
                .get(const GetOptions(source: Source.server)));

        for (final doc in snap.docs) {
          final data = _normalizeMap(doc.data());
          final userData = data.containsKey('user_data') &&
              data['user_data'] != null
              ? _normalizeMap(data['user_data'])
              : {
            'name': data['name'] ?? data['displayName'] ?? '',
            'email': data['email'] ?? '',
            'company': data['company'] ?? data['org'] ?? '',
          };

          _recruiterCache[doc.id] = _CacheEntry(userData, DateTime.now());
        }
      }));

      debugPrint('✅ Prefetched ${_recruiterCache.length} recruiters');
      _safeNotify();
    } catch (e) {
      debugPrint('⚠️ Batch prefetch error: $e');
    }
  }

  // ============================================================================
  // REALTIME LISTENER (Optimized)
  // ============================================================================

  void _startRealtimeListener() {
    _requestsSub?.cancel();
    _requestsSub = _firestore
        .collection('recruiter_requests')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen(
          (snap) {
        debugPrint('🔔 Realtime update: ${snap.docChanges.length} changes');

        // Only update changed documents, not full refetch
        bool hasChanges = false;

        for (final change in snap.docChanges) {
          final data = _normalizeMap(change.doc.data());
          final recruiterId = (data['recruiter_id'] ??
              data['recruiter'] ??
              data['recruiter_uid'] ??
              '')
              .toString();

          int totalCandidates = 0;
          if (data['total_candidates'] != null) {
            totalCandidates =
                int.tryParse(data['total_candidates'].toString()) ?? 0;
          } else {
            final candidateIds = _normalizeList(data['candidate_ids']);
            final candidates = _normalizeList(data['candidates']);
            totalCandidates = candidateIds.isNotEmpty
                ? candidateIds.length
                : candidates.length;
          }

          final entry = {
            'id': change.doc.id,
            'recruiter_id': recruiterId,
            'recruiter_email':
            (data['recruiter_email'] ?? data['recruiterEmail'] ?? '')
                .toString(),
            'total_candidates': totalCandidates,
            'status': (data['status'] ?? 'pending').toString(),
            'created_at': data['created_at'],
            'notes': data['notes'] ?? '',
            'raw': data,
          };

          if (change.type == DocumentChangeType.added) {
            if (!requests.any((r) => r['id'] == change.doc.id)) {
              requests.insert(0, entry);
              hasChanges = true;
            }
          } else if (change.type == DocumentChangeType.modified) {
            final idx = requests.indexWhere((r) => r['id'] == change.doc.id);
            if (idx != -1) {
              requests[idx] = entry;
              hasChanges = true;

              // Invalidate detail cache for this request
              _requestDetailsCache.remove(change.doc.id);
              if (_selectedRequestId == change.doc.id) {
                // Fetch in background, listeners will be notified
                fetchRequestDetails(requestId: change.doc.id);
              }
            }
          } else if (change.type == DocumentChangeType.removed) {
            requests.removeWhere((r) => r['id'] == change.doc.id);
            hasChanges = true;

            // Clean up caches
            _requestDetailsCache.remove(change.doc.id);
          }
        }

        if (hasChanges) {
          _safeNotify();
        }
      },
      onError: (e) {
        debugPrint('❌ Realtime listener error: $e');
      },
    );
  }

  // ============================================================================
  // OPTIMIZED FETCH REQUEST DETAILS (With Aggressive Caching)
  // ============================================================================

  Future<Map<String, dynamic>?> fetchRequestDetails({
    required String requestId,
  }) async {
    debugPrint('🔍 Admin: fetchRequestDetails requestId=$requestId');

    // Check cache first
    if (_requestDetailsCache.containsKey(requestId)) {
      final cached = _requestDetailsCache[requestId]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheTTL) {
        debugPrint('💾 Cache HIT for request details: $requestId');
        return cached.data;
      } else {
        debugPrint('⏰ Cache EXPIRED for request details: $requestId');
        _requestDetailsCache.remove(requestId);
      }
    }

    // Prevent duplicate fetches
    if (_pendingFetches.containsKey(requestId)) {
      debugPrint('⏳ Already fetching $requestId, waiting...');
      return _pendingFetches[requestId]!.future;
    }

    final completer = Completer<Map<String, dynamic>?>();
    _pendingFetches[requestId] = completer;

    loading = true;
    _safeNotify();


    try {
      final snap = await _firestore
          .collection('recruiter_requests')
          .doc(requestId)
          .get(const GetOptions(source: Source.cache))
          .catchError((_) =>
          _firestore
              .collection('recruiter_requests')
              .doc(requestId)
              .get(const GetOptions(source: Source.server)));

      // ← guard after first await
      if (_disposed) {
        completer.complete(null);
        _pendingFetches.remove(requestId);
        loading = false;
        return null;
      }

      if (!snap.exists) {
        completer.complete(null);
        _pendingFetches.remove(requestId);
        loading = false;
        _safeNotify();
        return null;
      }

      final data = _normalizeMap(snap.data());
      final recruiterId = (data['recruiter_id'] ?? data['recruiter'] ?? '')
          .toString();

      final candidatesFromCandidates = _normalizeList(data['candidates']);
      final candidatesFromIds = _normalizeList(data['candidate_ids']);
      final rawEntries = [...candidatesFromCandidates, ...candidatesFromIds];

      final Map<String, String> uniqueCandidates = {};
      final Map<String, Map<String, dynamic>> candidateHints = {};

      for (final entry in rawEntries) {
        try {
          String rawUid = '';
          Map<String, dynamic> hint = {};
          if (entry is Map) {
            final n = _normalizeMap(entry);
            hint = n;
            rawUid = (n['uid'] ?? n['user_id'] ?? n['id'] ?? '').toString().trim();
            if (rawUid.isEmpty && n['email'] != null) {
              rawUid = n['email'].toString().trim();
            }
          } else if (entry is String) {
            rawUid = entry.trim();
          } else if (entry is DocumentReference) {
            rawUid = entry.id;
          }

          if (rawUid.isEmpty || rawUid.toLowerCase() == 'null') continue;

          // Normalize ID to extract UID from paths like "Job_Seeker/XYZ"
          final uid = _lastSegment(rawUid);
          if (uid.isEmpty || uid.toLowerCase() == 'null') continue;

          final key = uid.toLowerCase();
          if (!uniqueCandidates.containsKey(key)) {
            uniqueCandidates[key] = uid;
            if (hint.isNotEmpty) candidateHints[uid] = hint;
          }
        } catch (e) {
          debugPrint('⚠️ Error processing candidate entry: $e');
        }
      }

      final recruiterInfo = await _fetchRecruiterInfo(recruiterId);

      // ← guard after second await
      if (_disposed) {
        completer.complete(null);
        _pendingFetches.remove(requestId);
        loading = false;
        return null;
      }

      final candidateDetails = await _batchFetchCandidates(
        uniqueCandidates.values.toList(),
        hints: candidateHints,
      );

      // ← guard after third await
      if (_disposed) {
        completer.complete(null);
        _pendingFetches.remove(requestId);
        loading = false;
        return null;
      }

      final result = <String, dynamic>{
        'request_doc': {'id': snap.id, 'data': data},
        'recruiter': {'id': recruiterId, 'data': recruiterInfo ?? {}},
        'candidates': candidateDetails,
      };

      _requestDetailsCache[requestId] = _CacheEntry(result, DateTime.now());
      debugPrint('📥 Admin: Details fetched successfully for $requestId (Candidates: ${candidateDetails.length})');
      completer.complete(result);
      _pendingFetches.remove(requestId);
      loading = false;
      _safeNotify();
      return result;
    } catch (e, st) {
      debugPrint('❌ fetchRequestDetails error: $e\n$st');
      if (!completer.isCompleted) completer.completeError(e);
      _pendingFetches.remove(requestId);
      loading = false;
      _safeNotify();
      return null;
    }
  }




  // ============================================================================
  // BATCH FETCH CANDIDATES (Parallel + Cached)
  // ============================================================================

  Future<List<Map<String, dynamic>>> _batchFetchCandidates(
      List<String> candidateIds, {
        Map<String, Map<String, dynamic>>? hints,
        int batchSize = 10,
      }) async {
    if (candidateIds.isEmpty) return [];

    final uncachedIds = <String>[];
    final cachedResults = <Map<String, dynamic>>[];

    for (final id in candidateIds) {
      if (_candidateCache.containsKey(id)) {
        final cached = _candidateCache[id]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheTTL) {
          debugPrint('💾 Cache HIT for candidate: $id');
          cachedResults.add(cached.data);
          continue;
        } else {
          debugPrint('⏰ Cache EXPIRED for candidate: $id');
          _candidateCache.remove(id);
        }
      }
      uncachedIds.add(id);
    }

    if (uncachedIds.isEmpty) {
      debugPrint('✅ All candidates loaded from cache');
      return cachedResults;
    }

    debugPrint('📥 Fetching ${uncachedIds.length} uncached candidates');
    final fetchedResults = <Map<String, dynamic>>[];
    final batches = <List<String>>[];

    for (var i = 0; i < uncachedIds.length; i += batchSize) {
      final currentBatch = uncachedIds.sublist(
        i,
        i + batchSize > uncachedIds.length ? uncachedIds.length : i + batchSize,
      );
      // Only filter out obvious non-ID strings like empty or purely null values
      final validIds = currentBatch.where((id) => id.isNotEmpty && id.toLowerCase() != 'null').toList();
      if (validIds.isNotEmpty) {
        batches.add(validIds);
      } else {
        debugPrint('⚠️ Skipping batch with only invalid IDs: $currentBatch');
      }
    }

    try {
      final results = await Future.wait(batches.map((batch) async {
        final snap = await _firestore
            .collection('Job_Seeker')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        final batchResults = <Map<String, dynamic>>[];
        for (final doc in snap.docs) {
          final jobSeekerData = _normalizeMap(doc.data());
          final userData = _normalizeMap(jobSeekerData['user_data'] ?? {});

          final personalProfile = _normalizeMap(
              jobSeekerData['personalProfile'] ??
                  jobSeekerData['personal_profile'] ??
                  userData['personalProfile'] ??
                  userData['personal_profile'] ??
                  {}
          );

          final name = personalProfile['name']?.toString() ??
              personalProfile['fullName']?.toString() ??
              jobSeekerData['name']?.toString() ??
              userData['name']?.toString() ??
              doc.id;

          final email = personalProfile['email']?.toString() ??
              jobSeekerData['email']?.toString() ??
              userData['email']?.toString() ??
              '';

          final phone = personalProfile['contactNumber']?.toString() ??
              personalProfile['phone']?.toString() ??
              personalProfile['contact_number']?.toString() ??
              userData['phone']?.toString() ??
              '';

          final hintData = _normalizeMap(hints?[doc.id]);

          final result = {
            'uid': doc.id,
            'name': name,
            'email': email,
            'phone': phone,
            'user_data': {
              ...hintData,
              ...jobSeekerData,
            },
          };

          _candidateCache[doc.id] = _CacheEntry(result, DateTime.now());
          batchResults.add(result);
        }
        return batchResults;
      }));

      for (final batchResult in results) {
        fetchedResults.addAll(batchResult);
      }

      // Handle orphans (IDs that exist in request but not in Job_Seeker collection)
      final foundIds = fetchedResults.map((c) => c['uid'] as String).toSet();
      for (final id in uncachedIds) {
        if (!foundIds.contains(id)) {
          debugPrint('⚠️ Candidate $id not found in Job_Seeker collection. Creating fallback.');
          final hint = _normalizeMap(hints?[id]);
          final phone = (hint['phone'] ?? hint['contactNumber'] ?? hint['contact_number'] ?? '').toString();

          final fallback = {
            'uid': id,
            'name': hint['name'] ?? hint['fullName'] ?? 'Unknown User',
            'email': hint['email'] ?? '',
            'phone': phone,
            'user_data': hint,
          };
          fetchedResults.add(fallback);
          _candidateCache[id] = _CacheEntry(fallback, DateTime.now());
        }
      }
    } catch (e) {
      debugPrint('❌ _batchFetchCandidates error: $e');
    }

    final finalResults = [...cachedResults, ...fetchedResults];
    debugPrint('✅ Admin: batch fetched ${finalResults.length} candidates (cached: ${cachedResults.length}, new: ${fetchedResults.length})');
    return finalResults;
  }

  // ============================================================================
  // OPTIMIZED FETCH RECRUITER INFO (Cached)
  // ============================================================================

  Future<Map<String, dynamic>?> _fetchRecruiterInfo(String recruiterId) async {
    if (recruiterId.isEmpty) return null;

    // Check cache
    if (_recruiterCache.containsKey(recruiterId)) {
      final cached = _recruiterCache[recruiterId]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheTTL) {
        debugPrint('💾 Cache HIT for recruiter: $recruiterId');
        return cached.data;
      } else {
        debugPrint('⏰ Cache EXPIRED for recruiter: $recruiterId');
        _recruiterCache.remove(recruiterId);
      }
    }

    try {
      debugPrint('📥 Fetching recruiter/$recruiterId');
      final snap = await _firestore
          .collection('recruiter')
          .doc(recruiterId)
          .get(const GetOptions(source: Source.cache))
          .catchError((_) => _firestore
          .collection('recruiter')
          .doc(recruiterId)
          .get(const GetOptions(source: Source.server)));

      if (!snap.exists) {
        debugPrint('⚠️ Recruiter/$recruiterId not found');
        return null;
      }

      final data = _normalizeMap(snap.data());

      final userData = data.containsKey('user_data') && data['user_data'] != null
          ? _normalizeMap(data['user_data'])
          : {
        'name': data['name'] ?? data['displayName'] ?? '',
        'email': data['email'] ?? '',
        'company': data['company'] ?? data['org'] ?? '',
      };

      _recruiterCache[recruiterId] = _CacheEntry(userData, DateTime.now());
      debugPrint('✅ Cached recruiter $recruiterId');
      return userData;
    } catch (e) {
      debugPrint('❌ _fetchRecruiterInfo error: $e');
      return null;
    }
  }

  // ============================================================================
  // UPDATE OPERATIONS (Optimized with Cache Invalidation)
  // ============================================================================


  Future<bool> updateRequestStatus({
    required String requestId,
    required String newStatus,
    String? note,
    String? performedBy,
  }) async {
    if (_disposed) return false;   // ← guard before network call
    try {
      final now = FieldValue.serverTimestamp();
      final ref = _firestore.collection('recruiter_requests').doc(requestId);

      final batch = _firestore.batch();
      batch.update(ref, {
        'status': newStatus,
        'last_updated_at': now,
        'last_updated_by': performedBy ?? 'admin',
      });
      final auditRef = ref.collection('audit').doc();
      batch.set(auditRef, {
        'action': 'update_status',
        'status': newStatus,
        'note': note ?? '',
        'performed_by': performedBy ?? 'admin',
        'created_at': now,
      });

      await batch.commit();
      if (_disposed) return true;  // ← committed OK but skip local state updates

      debugPrint('✅ Request $requestId status updated to $newStatus');
      final idx = requests.indexWhere((r) => r['id'] == requestId);
      if (idx != -1) {
        requests[idx]['status'] = newStatus;
        requests[idx]['last_updated_at'] = DateTime.now();
      }
      _requestDetailsCache.remove(requestId);
      if (_selectedRequestId == requestId) {
        await fetchRequestDetails(requestId: requestId);
      }
      _safeNotify();
      return true;
    } catch (e) {
      debugPrint('❌ updateRequestStatus error: $e');
      return false;
    }
  }



  Future<bool> updateCandidateStatus({
    required String requestId,
    required String candidateUid,
    required String status,
    String? note,
    String? performedBy,
  }) async {
    if (_disposed) return false;   // ← guard before first network call
    try {
      final now = FieldValue.serverTimestamp();
      final ref = _firestore.collection('recruiter_requests').doc(requestId);

      final snap = await ref.get();
      if (_disposed) return false;  // ← guard after first await
      if (!snap.exists) return false;

      final data = snap.data() as Map<String, dynamic>;
      final List<dynamic> candidates = List.from(data['candidates'] ?? []);
      final normalizedStatus =
      status.toLowerCase() == 'shortlisted' ? 'shortlist' : status.toLowerCase();

      for (int i = 0; i < candidates.length; i++) {
        final c = _normalizeMap(candidates[i]);
        if (c['uid'] == candidateUid) {
          candidates[i] = {...c, 'status': normalizedStatus};
          break;
        }
      }

      final batch = _firestore.batch();
      batch.update(ref, {
        'candidate_statuses.$candidateUid': normalizedStatus,
        'candidates': candidates,
        'last_updated_at': now,
        'last_updated_by': performedBy ?? 'admin',
      });
      final auditRef = ref.collection('audit').doc();
      batch.set(auditRef, {
        'action': 'update_candidate_status',
        'candidate_uid': candidateUid,
        'status': status,
        'note': note ?? '',
        'performed_by': performedBy ?? 'admin',
        'created_at': now,
      });

      await batch.commit();
      if (_disposed) return true;  // ← committed OK, skip cache invalidation

      debugPrint('✅ Candidate $candidateUid status updated to $status');
      _requestDetailsCache.remove(requestId);
      if (_selectedRequestId == requestId) {
        await fetchRequestDetails(requestId: requestId);
      } else {
        _safeNotify();
      }
      return true;
    } catch (e) {
      debugPrint('❌ updateCandidateStatus error: $e');
      return false;
    }
  }



  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  void clearCaches() {
    _recruiterCache.clear();
    _candidateCache.clear();
    _requestDetailsCache.clear();
    _emailToUidCache.clear();
    debugPrint('🧹 All caches cleared');
    _safeNotify();
  }

  void _cleanExpiredCaches() {
    final now = DateTime.now();

    _recruiterCache.removeWhere((key, value) =>
    now.difference(value.timestamp) > _cacheTTL);
    _candidateCache.removeWhere((key, value) =>
    now.difference(value.timestamp) > _cacheTTL);
    _requestDetailsCache.removeWhere((key, value) =>
    now.difference(value.timestamp) > _cacheTTL);

    debugPrint('🧹 Cleaned expired caches');
  }

  Future<void> refresh() async {
    debugPrint('🔄 Manual refresh');
    clearCaches();
    await fetchAllRequests();
  }

  // ============================================================================
  // STATIC HELPER
  // ============================================================================

  static Map<String, dynamic> normalizeMapStatic(dynamic m) {
    if (m == null) return <String, dynamic>{};
    if (m is Map<String, dynamic>) return m;
    if (m is Map) {
      final out = <String, dynamic>{};
      m.forEach((k, v) {
        final key = k?.toString() ?? '';
        out[key] = v;
      });
      return out;
    }
    return <String, dynamic>{};
  }

  // ============================================================================
  // UNIFIED NAME RESOLUTION
  // ============================================================================

  /// Fetches the name of a user based on their role and specific collection structure
  Future<String> fetchUnifiedName(String uid, String role) async {
    final normalizedRole = role.toLowerCase().trim();

    try {
      // 1. ADMIN - Fetch from 'users' collection directly (this is usually already in data)
      if (normalizedRole == 'admin' || normalizedRole == 'superadmin') {
        if (_candidateCache.containsKey(uid)) {
          return _candidateCache[uid]!.data['name'] ?? 'Unknown Admin';
        }
        final doc = await _firestore.collection('users').doc(uid).get();
        final name = doc.data()?['name'] ?? 'Unknown Admin';
        _candidateCache[uid] = _CacheEntry({'name': name}, DateTime.now());
        return name;
      }

      // 2. RECRUITER - recruiter/{uid} -> user_data -> name
      if (normalizedRole == 'recruiter') {
        // Check cache first
        if (_recruiterCache.containsKey(uid)) {
          final cached = _recruiterCache[uid]!;
          return cached.data['name'] ?? 'Unknown Recruiter';
        }

        final doc = await _firestore.collection('recruiter').doc(uid).get();
        if (doc.exists) {
          final data = _normalizeMap(doc.data());
          final userData = _normalizeMap(data['user_data']);
          final name = userData['name']?.toString() ?? data['name']?.toString() ?? 'Unknown Recruiter';

          // Cache it for future use
          _recruiterCache[uid] = _CacheEntry({'name': name}, DateTime.now());
          return name;
        }
      }

      // 3. JOB SEEKER - Job_Seeker/{uid} -> user_data -> personalProfile -> name
      if (normalizedRole == 'job seeker' || normalizedRole == 'job_seeker') {
        // Check cache first
        if (_candidateCache.containsKey(uid)) {
          return _candidateCache[uid]!.data['name'] ?? 'Unknown Job Seeker';
        }

        final doc = await _firestore.collection('Job_Seeker').doc(uid).get();
        if (doc.exists) {
          final data = _normalizeMap(doc.data());
          final userData = _normalizeMap(data['user_data']);

          final personalProfile = _normalizeMap(
              data['personalProfile'] ??
                  data['personal_profile'] ??
                  userData['personalProfile'] ??
                  userData['personal_profile'] ??
                  _normalizeMap(data['user_Account_Data'] ?? {})['personalProfile'] ??
                  {}
          );

          final name = personalProfile['name']?.toString() ??
              data['name']?.toString() ??
              userData['name']?.toString() ??
              'Unknown Job Seeker';

          // Cache it
          _candidateCache[uid] = _CacheEntry({'name': name}, DateTime.now());
          return name;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching unified name for $uid ($role): $e');
    }

    return 'Unknown User';
  }

  @override
  void dispose() {
    _disposed = true;           // ← FIRST: blocks all _safeNotify calls immediately
    _notifyTimer?.cancel();
    _requestsSub?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    _userLevelController.dispose();
    // ✅ Inline clears — avoids calling _safeNotify() from clearCaches() during dispose
    _recruiterCache.clear();
    _candidateCache.clear();
    _requestDetailsCache.clear();
    _emailToUidCache.clear();
    _pendingFetches.clear();
    debugPrint('🧹 AdminProvider disposed');
    super.dispose();
  }


}

// ============================================================================
// CACHE ENTRY CLASS (with TTL support)
// ============================================================================

class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);
}