// admin_recruiter_request_provider.dart  — FIXED
// ─── Summary of fixes ────────────────────────────────────────────────────────
// FIX 1: fetchRequestDetails now tries ALL common candidate field names:
//         candidates, candidate_ids, matched_candidates, seekers, job_seekers,
//         assignedCandidates, matched_seekers, seeker_ids, candidate_list
// FIX 2: Per-candidate UID extraction now tries all common key names.
// FIX 3: Candidates are NEVER silently dropped — if uid is missing, a
//         stable fallback key (email or generated index) is used so the
//         candidate still appears in the UI as "Unknown User".
// FIX 4: _batchFetchCandidates falls back to 'users' collection when a uid
//         is not found in Job_Seeker, instead of only creating a blank card.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AdminProvider extends ChangeNotifier {
  // ── Form controllers (unchanged) ─────────────────────────────────────────
  final _formKey         = GlobalKey<FormState>();
  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roleController  = TextEditingController();
  final _userLevelController = TextEditingController();

  String? _editingUserId;
  bool    _isLoading = false;
  String  _message   = '';

  GlobalKey<FormState> get formKey           => _formKey;
  TextEditingController get nameController   => _nameController;
  TextEditingController get emailController  => _emailController;
  TextEditingController get passwordController => _passwordController;
  TextEditingController get roleController   => _roleController;
  TextEditingController get userLevelController => _userLevelController;
  String? get editingUserId => _editingUserId;
  bool    get isLoading     => _isLoading;
  String  get message       => _message;

  // ── User management (unchanged) ─────────────────────────────────────────
  Future<bool> addOrEditUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      _isLoading = true;
      _message   = '';
      _safeNotify();
      try {
        String uid;
        DocumentReference userDocRef;
        if (_editingUserId == null) {
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
          final cred = await tempAuth.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          uid = cred.user!.uid;
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
          userDocRef = _firestore.collection('users').doc(_editingUserId);
          await userDocRef.update({
            'name': _nameController.text.trim(),
            'role': _roleController.text.trim(),
            'user_lvl': _userLevelController.text.trim(),
          });
          uid = _editingUserId!;
        }
        _message = _editingUserId == null ? 'User added successfully' : 'User updated successfully';
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
      await _firestore.collection('users').doc(firestoreDocId)
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
    _nameController.text  = resolvedName ?? userData['name'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _roleController.text  = userData['role'] ?? '';
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

  // =========================================================================
  // DASHBOARD STATE
  // =========================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool loading   = false;
  bool _disposed = false;

  List<Map<String, dynamic>> requests = [];

  final Map<String, _CacheEntry> _recruiterCache      = {};
  final Map<String, _CacheEntry> _candidateCache      = {};
  final Map<String, _CacheEntry> _requestDetailsCache = {};
  final Map<String, String>      _emailToUidCache     = {};

  static const Duration _cacheTTL = Duration(minutes: 10);

  StreamSubscription<QuerySnapshot>? _requestsSub;
  final Map<String, Completer<Map<String, dynamic>?>> _pendingFetches = {};
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

  // =========================================================================
  // HELPERS
  // =========================================================================

  Map<String, dynamic> _normalizeMap(dynamic m) {
    if (m == null) return <String, dynamic>{};
    if (m is Map<String, dynamic>) return m;
    if (m is Map) {
      final out = <String, dynamic>{};
      m.forEach((k, v) => out[k?.toString() ?? ''] = v);
      return out;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _normalizeList(dynamic list) {
    if (list == null) return [];
    if (list is List) return List<dynamic>.from(list);
    return [];
  }

  String _lastSegment(String s) {
    final str = s.trim();
    if (!str.contains('/')) return str;
    final parts = str.split('/');
    return parts.isNotEmpty ? parts.last : str;
  }

  // =========================================================================
  // FIX 1 — extractCandidateEntries
  // Tries every common field name a recruiter app might use when creating a
  // request. This is the root cause of "0 candidates shown."
  // =========================================================================
  List<dynamic> _extractCandidateEntries(Map<String, dynamic> data) {
    // All field names ever used across the recruiter app
    const candidateFields = [
      'candidates',
      'candidate_ids',
      'matched_candidates',
      'matched_seekers',
      'seekers',
      'seeker_ids',
      'job_seekers',
      'jobSeekers',
      'assignedCandidates',
      'assigned_candidates',
      'candidate_list',
      'candidateList',
      'users',
      'applicants',
    ];

    final merged = <dynamic>[];
    for (final field in candidateFields) {
      final val = data[field];
      if (val != null) {
        final list = _normalizeList(val);
        if (list.isNotEmpty) {
          debugPrint('✅ Found ${list.length} candidates under field "$field"');
          merged.addAll(list);
        }
      }
    }
    if (merged.isEmpty) {
      // Last resort: log ALL keys so the developer can see exactly what's in the doc
      debugPrint(
          '⚠️ No candidate entries found. Document keys: ${data.keys.toList()}');
    }
    return merged;
  }

  // =========================================================================
  // FIX 2 — extractCandidateUid
  // Tries every common key name for the UID inside a candidate map.
  // NEVER returns empty — falls back to email, then a generated key.
  // =========================================================================
  String _extractCandidateUid(Map<String, dynamic> n, int fallbackIndex) {
    const uidKeys = [
      'uid',
      'user_id',
      'userId',
      'id',
      'jobSeekerId',
      'job_seeker_id',
      'seekerUid',
      'seeker_uid',
      'candidate_uid',
      'candidateUid',
      'user_uid',
      'userUid',
      'docId',
      'doc_id',
    ];

    for (final key in uidKeys) {
      final v = n[key]?.toString().trim() ?? '';
      if (v.isNotEmpty && v.toLowerCase() != 'null') {
        return _lastSegment(v);
      }
    }

    // Fallback 1: email (used as key, resolved to uid later if needed)
    final email = n['email']?.toString().trim() ?? '';
    if (email.isNotEmpty && email.contains('@')) {
      debugPrint('⚠️ Using email as uid fallback for candidate $fallbackIndex');
      return email;
    }

    // Fallback 2: stable index key (guarantees this candidate is NOT silently dropped)
    final generated = '__candidate_$fallbackIndex';
    debugPrint('⚠️ No uid/email found for candidate $fallbackIndex, using "$generated". '
        'Available keys: ${n.keys.toList()}');
    return generated;
  }

  // =========================================================================
  // FETCH ALL REQUESTS (unchanged logic, just cleaner)
  // =========================================================================

  Future<void> fetchAllRequests({bool realtime = false}) async {
    if (loading) return;
    loading = true;
    _safeNotify();
    debugPrint('🔍 Admin: fetchAllRequests(realtime=$realtime)');

    try {
      final snap = await _firestore
          .collection('recruiter_requests')
          .orderBy('created_at', descending: true)
          .get(const GetOptions(source: Source.cache))
          .catchError((_) => _firestore
          .collection('recruiter_requests')
          .orderBy('created_at', descending: true)
          .get(const GetOptions(source: Source.server)));

      debugPrint('🔎 Found ${snap.docs.length} request docs');

      final List<Map<String, dynamic>> tmp = [];
      final Set<String> recruiterIds = {};

      for (final d in snap.docs) {
        final data = _normalizeMap(d.data());
        final recruiterId =
        (data['recruiter_id'] ?? data['recruiter'] ?? data['recruiter_uid'] ?? '')
            .toString();
        final recruiterEmail =
        (data['recruiter_email'] ?? data['recruiterEmail'] ?? '').toString();

        // Count using stored field OR fallback to counting the actual array
        int totalCandidates = 0;
        if (data['total_candidates'] != null) {
          totalCandidates = int.tryParse(data['total_candidates'].toString()) ?? 0;
        } else {
          final entries = _extractCandidateEntries(data);
          totalCandidates = entries.length;
        }

        tmp.add({
          'id': d.id,
          'recruiter_id': recruiterId,
          'recruiter_email': recruiterEmail,
          'total_candidates': totalCandidates,
          'status': (data['status'] ?? 'pending').toString(),
          'created_at': data['created_at'],
          'notes': data['notes'] ?? '',
          'raw': data,
        });

        if (recruiterId.isNotEmpty) recruiterIds.add(recruiterId);
      }

      requests = tmp;
      debugPrint('✅ Admin: loaded ${requests.length} request(s)');
      if (recruiterIds.isNotEmpty) _batchPrefetchRecruiters(recruiterIds.toList());
    } catch (e, st) {
      debugPrint('❌ fetchAllRequests failed: $e\n$st');
      requests = [];
    } finally {
      loading = false;
      _safeNotify();
    }

    if (realtime) _startRealtimeListener();
  }

  // =========================================================================
  // FETCH REQUEST DETAILS — FIXED
  // =========================================================================

  Future<Map<String, dynamic>?> fetchRequestDetails({
    required String requestId,
  }) async {
    debugPrint('🔍 fetchRequestDetails: $requestId');

    // Cache check
    if (_requestDetailsCache.containsKey(requestId)) {
      final cached = _requestDetailsCache[requestId]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheTTL) {
        debugPrint('💾 Cache HIT: $requestId');
        return cached.data;
      }
      _requestDetailsCache.remove(requestId);
    }

    // Dedup in-flight
    if (_pendingFetches.containsKey(requestId)) {
      debugPrint('⏳ Already fetching $requestId, waiting…');
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
          .catchError((_) => _firestore
          .collection('recruiter_requests')
          .doc(requestId)
          .get(const GetOptions(source: Source.server)));

      if (_disposed) { completer.complete(null); return null; }

      if (!snap.exists) {
        debugPrint('⚠️ Request doc $requestId does not exist');
        completer.complete(null);
        return null;
      }

      final data = _normalizeMap(snap.data());
      debugPrint('📄 Request doc keys: ${data.keys.toList()}');

      final recruiterId =
      (data['recruiter_id'] ?? data['recruiter'] ?? '').toString();

      // ── FIX 1: use the exhaustive field scanner ───────────────────────────
      final rawEntries = _extractCandidateEntries(data);
      debugPrint('📋 Raw candidate entries found: ${rawEntries.length}');

      // ── Build unique candidates map ───────────────────────────────────────
      final uniqueCandidates = <String, String>{}; // key → uid
      final candidateHints   = <String, Map<String, dynamic>>{};

      for (int i = 0; i < rawEntries.length; i++) {
        final entry = rawEntries[i];
        String rawUid = '';
        Map<String, dynamic> hint = {};

        try {
          if (entry is Map) {
            hint   = _normalizeMap(entry);
            // ── FIX 2: exhaustive uid key search, never returns empty ──────
            rawUid = _extractCandidateUid(hint, i);
          } else if (entry is String) {
            rawUid = entry.trim();
          } else if (entry is DocumentReference) {
            rawUid = entry.id;
            debugPrint(
                '📎 DocumentReference candidate: path=${entry.path} id=${entry.id}');
          }
        } catch (e) {
          debugPrint('⚠️ Error reading candidate entry $i: $e');
          rawUid = '__candidate_$i'; // never discard
        }

        if (rawUid.isEmpty) rawUid = '__candidate_$i';

        final uid = _lastSegment(rawUid);
        final key = uid.toLowerCase();
        if (!uniqueCandidates.containsKey(key)) {
          uniqueCandidates[key] = uid;
          if (hint.isNotEmpty) candidateHints[uid] = hint;
        }
      }

      debugPrint('👥 Unique candidate UIDs to fetch: ${uniqueCandidates.values.toList()}');

      final recruiterInfo    = await _fetchRecruiterInfo(recruiterId);
      if (_disposed) { completer.complete(null); return null; }

      final candidateDetails = await _batchFetchCandidates(
        uniqueCandidates.values.toList(),
        hints: candidateHints,
      );
      if (_disposed) { completer.complete(null); return null; }

      debugPrint('✅ Candidates resolved: ${candidateDetails.length}');

      final result = <String, dynamic>{
        'request_doc': {'id': snap.id, 'data': data},
        'recruiter':   {'id': recruiterId, 'data': recruiterInfo ?? {}},
        'candidates':  candidateDetails,
      };

      _requestDetailsCache[requestId] = _CacheEntry(result, DateTime.now());
      completer.complete(result);
      loading = false;
      _safeNotify();
      return result;
    } catch (e, st) {
      debugPrint('❌ fetchRequestDetails error: $e\n$st');
      if (!completer.isCompleted) completer.completeError(e);
      loading = false;
      _safeNotify();
      return null;
    } finally {
      _pendingFetches.remove(requestId);
    }
  }

  // =========================================================================
  // BATCH FETCH CANDIDATES — FIXED
  // FIX 3: also tries 'users' collection when uid not found in Job_Seeker.
  // FIX 4: never discards candidates — always produces at minimum a fallback card.
  // =========================================================================

  Future<List<Map<String, dynamic>>> _batchFetchCandidates(
      List<String> candidateIds, {
        Map<String, Map<String, dynamic>>? hints,
        int batchSize = 10,
      }) async {
    if (candidateIds.isEmpty) return [];

    // Separate real IDs from generated fallback keys
    final realIds     = candidateIds.where((id) => !id.startsWith('__candidate_')).toList();
    final fallbackIds = candidateIds.where((id) => id.startsWith('__candidate_')).toList();

    // Build fallback cards immediately for generated-key entries (no Firestore needed)
    final fallbackCards = fallbackIds.map((id) {
      final hint = _normalizeMap(hints?[id]);
      return _buildFallbackCard(id, hint);
    }).toList();

    if (realIds.isEmpty) return fallbackCards;

    // Cache split
    final uncachedIds    = <String>[];
    final cachedResults  = <Map<String, dynamic>>[];

    for (final id in realIds) {
      if (_candidateCache.containsKey(id)) {
        final cached = _candidateCache[id]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheTTL) {
          cachedResults.add(cached.data);
          continue;
        }
        _candidateCache.remove(id);
      }
      uncachedIds.add(id);
    }

    if (uncachedIds.isEmpty) return [...cachedResults, ...fallbackCards];

    debugPrint('📥 Fetching ${uncachedIds.length} candidates from Firestore');
    final fetchedResults = <Map<String, dynamic>>[];

    final batches = <List<String>>[];
    for (var i = 0; i < uncachedIds.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, uncachedIds.length);
      batches.add(uncachedIds.sublist(i, end));
    }

    try {
      // ── Step A: query Job_Seeker by document ID ───────────────────────────
      final jobSeekerResults = await Future.wait(batches.map((batch) async {
        try {
          final snap = await _firestore
              .collection('Job_Seeker')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          return _parseJobSeekerDocs(snap.docs, hints);
        } catch (e) {
          debugPrint('⚠️ Job_Seeker batch query error: $e');
          return <Map<String, dynamic>>[];
        }
      }));

      for (final batch in jobSeekerResults) {
        fetchedResults.addAll(batch);
      }

      // ── Step B: for IDs not found by docId, try querying by uid field ────
      final foundInJobSeekerDocId =
          fetchedResults.map((c) => c['uid'].toString()).toSet();
      final missingAfterDocId =
          uncachedIds.where((id) => !foundInJobSeekerDocId.contains(id)).toList();

      if (missingAfterDocId.isNotEmpty) {
        debugPrint('🔍 ${missingAfterDocId.length} IDs not found by docId, trying uid field query');
        final uidFieldBatches = <List<String>>[];
        for (var i = 0; i < missingAfterDocId.length; i += batchSize) {
          final end = (i + batchSize).clamp(0, missingAfterDocId.length);
          uidFieldBatches.add(missingAfterDocId.sublist(i, end));
        }
        final uidFieldResults = await Future.wait(uidFieldBatches.map((batch) async {
          try {
            final snap = await _firestore
                .collection('Job_Seeker')
                .where('uid', whereIn: batch)
                .get();
            return _parseJobSeekerDocs(snap.docs, hints);
          } catch (e) {
            debugPrint('⚠️ Job_Seeker uid-field query error: $e');
            return <Map<String, dynamic>>[];
          }
        }));
        for (final batch in uidFieldResults) {
          fetchedResults.addAll(batch);
        }
      }

      // ── Step C: for any IDs not found in Job_Seeker at all, try 'users' ──
      final foundInJobSeeker =
          fetchedResults.map((c) => c['uid'].toString()).toSet();
      final stillMissing =
          uncachedIds.where((id) => !foundInJobSeeker.contains(id)).toList();

      if (stillMissing.isNotEmpty) {
        debugPrint(
            '🔍 ${stillMissing.length} IDs not in Job_Seeker, trying "users" collection by docId');

        final userBatches = <List<String>>[];
        for (var i = 0; i < stillMissing.length; i += batchSize) {
          final end = (i + batchSize).clamp(0, stillMissing.length);
          userBatches.add(stillMissing.sublist(i, end));
        }

        final usersResults = await Future.wait(userBatches.map((batch) async {
          try {
            final snap = await _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: batch)
                .get();
            return _parseUsersDocs(snap.docs, hints);
          } catch (e) {
            debugPrint('⚠️ users batch query error: $e');
            return <Map<String, dynamic>>[];
          }
        }));

        for (final batch in usersResults) {
          fetchedResults.addAll(batch);
        }

        // Also try users collection by uid field
        final foundInUsers = fetchedResults.map((c) => c['uid'].toString()).toSet();
        final missingFromUsers = stillMissing.where((id) => !foundInUsers.contains(id)).toList();
        if (missingFromUsers.isNotEmpty) {
          final userUidBatches = <List<String>>[];
          for (var i = 0; i < missingFromUsers.length; i += batchSize) {
            final end = (i + batchSize).clamp(0, missingFromUsers.length);
            userUidBatches.add(missingFromUsers.sublist(i, end));
          }
          final userUidResults = await Future.wait(userUidBatches.map((batch) async {
            try {
              final snap = await _firestore
                  .collection('users')
                  .where('uid', whereIn: batch)
                  .get();
              return _parseUsersDocs(snap.docs, hints);
            } catch (e) {
              debugPrint('⚠️ users uid-field query error: $e');
              return <Map<String, dynamic>>[];
            }
          }));
          for (final batch in userUidResults) {
            fetchedResults.addAll(batch);
          }
        }
      }

      // ── Step D: anything still missing → build from hint or show fallback ─
      final foundAll =
          fetchedResults.map((c) => c['uid'].toString()).toSet();
      for (final id in uncachedIds) {
        if (!foundAll.contains(id)) {
          // Also try email-based lookup if the id looks like an email
          if (id.contains('@')) {
            debugPrint('🔍 "$id" looks like email, trying email lookup');
            try {
              final emailSnap = await _firestore
                  .collection('Job_Seeker')
                  .where('email', isEqualTo: id)
                  .limit(1)
                  .get();
              if (emailSnap.docs.isNotEmpty) {
                final parsed = _parseJobSeekerDocs(emailSnap.docs, hints);
                if (parsed.isNotEmpty) {
                  fetchedResults.addAll(parsed);
                  continue;
                }
              }
            } catch (e) {
              debugPrint('⚠️ email lookup error: $e');
            }
          }
          debugPrint('⚠️ "$id" not found in any collection — using hint fallback');
          final hint = _normalizeMap(hints?[id]);
          final card = _buildFallbackCard(id, hint);
          fetchedResults.add(card);
          _candidateCache[id] = _CacheEntry(card, DateTime.now());
        }
      }
    } catch (e) {
      debugPrint('❌ _batchFetchCandidates outer error: $e');
    }

    final all = [...cachedResults, ...fetchedResults, ...fallbackCards];
    debugPrint('✅ Total candidates resolved: ${all.length}');
    return all;
  }

  // ── Parse helpers ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _parseJobSeekerDocs(
      List<QueryDocumentSnapshot> docs,
      Map<String, Map<String, dynamic>>? hints) {
    final results = <Map<String, dynamic>>[];
    for (final doc in docs) {
      final jsData = _normalizeMap(doc.data());
      final userData = _normalizeMap(jsData['user_data'] ?? {});

      // Try multiple paths for personalProfile (nested or flat)
      final personalProfile = _normalizeMap(
        jsData['personalProfile'] ??
            jsData['personal_profile'] ??
            userData['personalProfile'] ??
            userData['personal_profile'] ??
            {},
      );

      // The actual uid may be stored as a field, not just the doc id
      final storedUid = jsData['uid']?.toString() ??
          jsData['user_id']?.toString() ??
          userData['uid']?.toString() ??
          doc.id;

      // Exhaustive name resolution: check personalProfile, professionalProfile, flat, userData
      final professionalProfile = _normalizeMap(
          jsData['professionalProfile'] ?? jsData['professional_profile'] ?? {});
      final name = personalProfile['name']?.toString()?.trim().isNotEmpty == true
          ? personalProfile['name'].toString().trim()
          : personalProfile['fullName']?.toString()?.trim().isNotEmpty == true
              ? personalProfile['fullName'].toString().trim()
              : personalProfile['firstName']?.toString()?.trim().isNotEmpty == true
                  ? '${personalProfile['firstName']} ${personalProfile['lastName'] ?? ''}'.trim()
                  : jsData['name']?.toString()?.trim().isNotEmpty == true
                      ? jsData['name'].toString().trim()
                      : userData['name']?.toString()?.trim().isNotEmpty == true
                          ? userData['name'].toString().trim()
                          : professionalProfile['name']?.toString()?.trim().isNotEmpty == true
                              ? professionalProfile['name'].toString().trim()
                              : doc.id;

      final email = personalProfile['email']?.toString() ??
          personalProfile['emailAddress']?.toString() ??
          jsData['email']?.toString() ??
          userData['email']?.toString() ??
          '';
      final phone = personalProfile['contactNumber']?.toString() ??
          personalProfile['phone']?.toString() ??
          personalProfile['contact_number']?.toString() ??
          personalProfile['phoneNumber']?.toString() ??
          jsData['phone']?.toString() ??
          userData['phone']?.toString() ??
          '';

      final hint = _normalizeMap(hints?[doc.id] ?? hints?[storedUid] ?? {});
      final result = {
        'uid': storedUid,
        'doc_id': doc.id,
        'name': name,
        'email': email,
        'phone': phone,
        'user_data': {...hint, ...jsData},
      };
      // Cache by both doc.id and storedUid so either lookup hits
      _candidateCache[doc.id] = _CacheEntry(result, DateTime.now());
      if (storedUid != doc.id) {
        _candidateCache[storedUid] = _CacheEntry(result, DateTime.now());
      }
      results.add(result);
    }
    return results;
  }

  List<Map<String, dynamic>> _parseUsersDocs(
      List<QueryDocumentSnapshot> docs,
      Map<String, Map<String, dynamic>>? hints) {
    final results = <Map<String, dynamic>>[];
    for (final doc in docs) {
      final data = _normalizeMap(doc.data());
      final hint = _normalizeMap(hints?[doc.id]);
      final result = {
        'uid':   doc.id,
        'name':  data['name']?.toString() ?? data['displayName']?.toString() ?? doc.id,
        'email': data['email']?.toString() ?? '',
        'phone': data['phone']?.toString() ?? '',
        'user_data': {...hint, ...data},
      };
      _candidateCache[doc.id] = _CacheEntry(result, DateTime.now());
      results.add(result);
    }
    return results;
  }

  Map<String, dynamic> _buildFallbackCard(
      String uid, Map<String, dynamic> hint) {
    // Deep-search for name in nested structures
    final pp = _normalizeMap(
        hint['personalProfile'] ?? hint['personal_profile'] ?? {});
    final prof = _normalizeMap(
        hint['professionalProfile'] ?? hint['professional_profile'] ?? {});
    final ud = _normalizeMap(hint['user_data'] ?? {});
    final udPp = _normalizeMap(
        ud['personalProfile'] ?? ud['personal_profile'] ?? {});

    String resolveName() {
      for (final src in [pp, udPp, hint, ud, prof]) {
        for (final key in ['name', 'fullName', 'full_name', 'displayName']) {
          final v = src[key]?.toString().trim() ?? '';
          if (v.isNotEmpty && v.toLowerCase() != 'null') return v;
        }
        // Try firstName + lastName combo
        final fn = src['firstName']?.toString().trim() ?? '';
        final ln = src['lastName']?.toString().trim() ?? '';
        if (fn.isNotEmpty) return '$fn $ln'.trim();
      }
      // Last resort: use email prefix
      final email = hint['email']?.toString().trim() ??
          pp['email']?.toString().trim() ?? '';
      if (email.contains('@')) return email.split('@').first;
      return uid.startsWith('__') ? 'Unknown Candidate' : uid;
    }

    final resolvedName = resolveName();
    return {
      'uid':   uid,
      'name':  resolvedName,
      'email': hint['email']?.toString() ??
          pp['email']?.toString() ??
          ud['email']?.toString() ?? '',
      'phone': hint['phone']?.toString() ??
          hint['contactNumber']?.toString() ??
          pp['phone']?.toString() ??
          pp['contactNumber']?.toString() ?? '',
      'user_data': hint,
    };
  }

  // =========================================================================
  // FETCH RECRUITER INFO (unchanged)
  // =========================================================================

  Future<Map<String, dynamic>?> _fetchRecruiterInfo(String recruiterId) async {
    if (recruiterId.isEmpty) return null;
    if (_recruiterCache.containsKey(recruiterId)) {
      final cached = _recruiterCache[recruiterId]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheTTL) return cached.data;
      _recruiterCache.remove(recruiterId);
    }
    try {
      final snap = await _firestore
          .collection('recruiter')
          .doc(recruiterId)
          .get(const GetOptions(source: Source.cache))
          .catchError((_) => _firestore
          .collection('recruiter')
          .doc(recruiterId)
          .get(const GetOptions(source: Source.server)));
      if (!snap.exists) return null;
      final data     = _normalizeMap(snap.data());
      final userData = data.containsKey('user_data') && data['user_data'] != null
          ? _normalizeMap(data['user_data'])
          : {
        'name':    data['name']    ?? data['displayName'] ?? '',
        'email':   data['email']   ?? '',
        'company': data['company'] ?? data['org'] ?? '',
      };
      _recruiterCache[recruiterId] = _CacheEntry(userData, DateTime.now());
      return userData;
    } catch (e) {
      debugPrint('❌ _fetchRecruiterInfo error: $e');
      return null;
    }
  }

  // =========================================================================
  // BATCH PREFETCH RECRUITERS (unchanged)
  // =========================================================================

  Future<void> _batchPrefetchRecruiters(List<String> recruiterIds) async {
    const batchSize = 10;
    final batches = <List<String>>[];
    for (var i = 0; i < recruiterIds.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, recruiterIds.length);
      batches.add(recruiterIds.sublist(i, end));
    }
    try {
      await Future.wait(batches.map((batch) async {
        final snap = await _firestore
            .collection('recruiter')
            .where(FieldPath.documentId, whereIn: batch)
            .get(const GetOptions(source: Source.cache))
            .catchError((_) => _firestore
            .collection('recruiter')
            .where(FieldPath.documentId, whereIn: batch)
            .get(const GetOptions(source: Source.server)));
        for (final doc in snap.docs) {
          final data     = _normalizeMap(doc.data());
          final userData = data.containsKey('user_data') && data['user_data'] != null
              ? _normalizeMap(data['user_data'])
              : {'name': data['name'] ?? '', 'email': data['email'] ?? ''};
          _recruiterCache[doc.id] = _CacheEntry(userData, DateTime.now());
        }
      }));
      _safeNotify();
    } catch (e) {
      debugPrint('⚠️ Batch prefetch error: $e');
    }
  }

  // =========================================================================
  // REALTIME LISTENER (unchanged)
  // =========================================================================

  void _startRealtimeListener() {
    _requestsSub?.cancel();
    _requestsSub = _firestore
        .collection('recruiter_requests')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen(
          (snap) {
        bool hasChanges = false;
        for (final change in snap.docChanges) {
          final data        = _normalizeMap(change.doc.data());
          final recruiterId = (data['recruiter_id'] ?? data['recruiter'] ?? '').toString();
          int totalCandidates = 0;
          if (data['total_candidates'] != null) {
            totalCandidates = int.tryParse(data['total_candidates'].toString()) ?? 0;
          } else {
            totalCandidates = _extractCandidateEntries(data).length;
          }
          final entry = {
            'id': change.doc.id,
            'recruiter_id': recruiterId,
            'recruiter_email':
            (data['recruiter_email'] ?? data['recruiterEmail'] ?? '').toString(),
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
              _requestDetailsCache.remove(change.doc.id);
              if (_selectedRequestId == change.doc.id) {
                fetchRequestDetails(requestId: change.doc.id);
              }
            }
          } else if (change.type == DocumentChangeType.removed) {
            requests.removeWhere((r) => r['id'] == change.doc.id);
            _requestDetailsCache.remove(change.doc.id);
            hasChanges = true;
          }
        }
        if (hasChanges) _safeNotify();
      },
      onError: (e) => debugPrint('❌ Realtime listener error: $e'),
    );
  }

  // =========================================================================
  // UPDATE OPERATIONS (unchanged)
  // =========================================================================

  Future<bool> updateRequestStatus({
    required String requestId,
    required String newStatus,
    String? note,
    String? performedBy,
  }) async {
    if (_disposed) return false;
    try {
      final now = FieldValue.serverTimestamp();
      final ref = _firestore.collection('recruiter_requests').doc(requestId);
      final batch = _firestore.batch();
      batch.update(ref, {
        'status': newStatus,
        'last_updated_at': now,
        'last_updated_by': performedBy ?? 'admin',
      });
      batch.set(ref.collection('audit').doc(), {
        'action': 'update_status',
        'status': newStatus,
        'note': note ?? '',
        'performed_by': performedBy ?? 'admin',
        'created_at': now,
      });
      await batch.commit();
      if (_disposed) return true;
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
    if (_disposed) return false;
    try {
      final now = FieldValue.serverTimestamp();
      final ref = _firestore.collection('recruiter_requests').doc(requestId);
      final snap = await ref.get();
      if (_disposed || !snap.exists) return false;
      final data       = snap.data() as Map<String, dynamic>;
      final candidates = List.from(data['candidates'] ?? []);
      final normalized = status.toLowerCase() == 'shortlisted' ? 'shortlist' : status.toLowerCase();
      for (int i = 0; i < candidates.length; i++) {
        final c = _normalizeMap(candidates[i]);
        if (c['uid'] == candidateUid) {
          candidates[i] = {...c, 'status': normalized};
          break;
        }
      }
      final batch = _firestore.batch();
      batch.update(ref, {
        'candidate_statuses.$candidateUid': normalized,
        'candidates': candidates,
        'last_updated_at': now,
        'last_updated_by': performedBy ?? 'admin',
      });
      batch.set(ref.collection('audit').doc(), {
        'action': 'update_candidate_status',
        'candidate_uid': candidateUid,
        'status': status,
        'note': note ?? '',
        'performed_by': performedBy ?? 'admin',
        'created_at': now,
      });
      await batch.commit();
      if (_disposed) return true;
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

  // =========================================================================
  // CACHE MANAGEMENT (unchanged)
  // =========================================================================

  void clearCaches() {
    _recruiterCache.clear();
    _candidateCache.clear();
    _requestDetailsCache.clear();
    _emailToUidCache.clear();
    _safeNotify();
  }

  Future<void> refresh() async {
    clearCaches();
    await fetchAllRequests();
  }

  // =========================================================================
  // STATIC HELPERS
  // =========================================================================

  static Map<String, dynamic> normalizeMapStatic(dynamic m) {
    if (m == null) return <String, dynamic>{};
    if (m is Map<String, dynamic>) return m;
    if (m is Map) {
      final out = <String, dynamic>{};
      m.forEach((k, v) => out[k?.toString() ?? ''] = v);
      return out;
    }
    return <String, dynamic>{};
  }

  Future<String> fetchUnifiedName(String uid, String role) async {
    final r = role.toLowerCase().trim();
    try {
      if (r == 'admin' || r == 'superadmin') {
        if (_candidateCache.containsKey(uid)) return _candidateCache[uid]!.data['name'] ?? 'Unknown Admin';
        final doc = await _firestore.collection('users').doc(uid).get();
        final name = doc.data()?['name'] ?? 'Unknown Admin';
        _candidateCache[uid] = _CacheEntry({'name': name}, DateTime.now());
        return name;
      }
      if (r == 'recruiter') {
        if (_recruiterCache.containsKey(uid)) return _recruiterCache[uid]!.data['name'] ?? 'Unknown Recruiter';
        final doc = await _firestore.collection('recruiter').doc(uid).get();
        if (doc.exists) {
          final data = _normalizeMap(doc.data());
          final name = _normalizeMap(data['user_data'])['name']?.toString() ?? data['name']?.toString() ?? 'Unknown Recruiter';
          _recruiterCache[uid] = _CacheEntry({'name': name}, DateTime.now());
          return name;
        }
      }
      if (r == 'job seeker' || r == 'job_seeker') {
        if (_candidateCache.containsKey(uid)) return _candidateCache[uid]!.data['name'] ?? 'Unknown Job Seeker';
        final doc = await _firestore.collection('Job_Seeker').doc(uid).get();
        if (doc.exists) {
          final data = _normalizeMap(doc.data());
          final pp   = _normalizeMap(data['personalProfile'] ?? data['personal_profile'] ?? {});
          final name = pp['name']?.toString() ?? data['name']?.toString() ?? 'Unknown Job Seeker';
          _candidateCache[uid] = _CacheEntry({'name': name}, DateTime.now());
          return name;
        }
      }
    } catch (e) {
      debugPrint('⚠️ fetchUnifiedName error for $uid: $e');
    }
    return 'Unknown User';
  }

  // =========================================================================
  // DISPOSE
  // =========================================================================

  @override
  void dispose() {
    _disposed = true;
    _notifyTimer?.cancel();
    _requestsSub?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    _userLevelController.dispose();
    _recruiterCache.clear();
    _candidateCache.clear();
    _requestDetailsCache.clear();
    _emailToUidCache.clear();
    _pendingFetches.clear();
    debugPrint('🧹 AdminProvider disposed');
    super.dispose();
  }
}

// ─── Cache entry ──────────────────────────────────────────────────────────────
class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  _CacheEntry(this.data, this.timestamp);
}