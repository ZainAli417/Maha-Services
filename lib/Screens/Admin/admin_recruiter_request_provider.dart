// admin_recruiter_request_provider.dart
// ─── Fixes in this version ───────────────────────────────────────────────────
// FIX 1: optimisticCandidateStatusUpdate() — instant in-memory cache update so
//         the UI responds immediately with zero lag or rebuild cascade.
// FIX 2: updateCandidateStatus() — fires Firestore write, does NOT re-fetch
//         details afterwards. Cache is only invalidated on failure so the
//         optimistic state is preserved on success and restored on error.
// FIX 3: _safeNotify() guards against calling notifyListeners during build.
// FIX 4: selectRequest() skips re-fetch when details are already cached.
// All prior fixes (exhaustive candidate/field scanning, fallbacks, etc.) kept.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

class AdminProvider extends ChangeNotifier {
  // ── Form controllers ──────────────────────────────────────────────────────
  final _formKey            = GlobalKey<FormState>();
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _roleController     = TextEditingController();
  final _userLevelController = TextEditingController();

  String? _editingUserId;
  bool    _isLoading = false;
  String  _message   = '';

  GlobalKey<FormState> get formKey              => _formKey;
  TextEditingController get nameController      => _nameController;
  TextEditingController get emailController     => _emailController;
  TextEditingController get passwordController  => _passwordController;
  TextEditingController get roleController      => _roleController;
  TextEditingController get userLevelController => _userLevelController;
  String? get editingUserId  => _editingUserId;
  bool    get isLoading      => _isLoading;
  String  get message        => _message;

  // ── User management ───────────────────────────────────────────────────────
  Future<bool> addOrEditUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    _isLoading = true;
    _message   = '';
    _safeNotify();
    try {
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
        final uid = cred.user!.uid;
        await tempAuth.signOut();
        await _firestore.collection('users').doc(uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'uid': uid,
          'role': _roleController.text.trim(),
          'isNew': 'yes',
          'account_status': 'active',
          'user_lvl': _userLevelController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
        });
        _candidateCache.remove(uid);
        _emailToUidCache.remove(_emailController.text.trim());
      } else {
        await _firestore.collection('users').doc(_editingUserId).update({
          'name': _nameController.text.trim(),
          'role': _roleController.text.trim(),
          'user_lvl': _userLevelController.text.trim(),
        });
        _candidateCache.remove(_editingUserId);
        _recruiterCache.remove(_editingUserId);
      }
      _message = _editingUserId == null ? 'User added successfully' : 'User updated successfully';
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

  Future<void> suspendUser(String docId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    try {
      await _firestore.collection('users').doc(docId).update({'account_status': newStatus});
    } catch (e) {
      debugPrint('❌ suspendUser error: $e');
    }
    _safeNotify();
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('❌ resetPassword error: $e');
    }
  }

  void editUser(Map<String, dynamic> userData, String docId, {String? resolvedName}) {
    _nameController.text      = resolvedName ?? userData['name'] ?? '';
    _emailController.text     = userData['email'] ?? '';
    _roleController.text      = userData['role'] ?? '';
    _userLevelController.text = userData['user_lvl'] ?? '';
    _passwordController.clear();
    _editingUserId = docId;
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

  String? _selectedRequestId;
  String? get selectedRequestId => _selectedRequestId;

  Map<String, dynamic>? get selectedRequestDetails {
    if (_selectedRequestId == null) return null;
    return _requestDetailsCache[_selectedRequestId]?.data;
  }

  /// Selects a request and fetches details only if not already cached.
  Future<void> selectRequest(String requestId) async {
    if (_selectedRequestId == requestId) return;
    _selectedRequestId = requestId;
    _safeNotify();

    final cached = _requestDetailsCache[requestId];
    final isFresh = cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheTTL;
    if (!isFresh) {
      await fetchRequestDetails(requestId: requestId);
    }
  }

  // ── Safe notify: never calls during a build frame ─────────────────────────
  void _safeNotify() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks) {
      // We're mid-frame — defer to post-frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      // Safe to notify now
      Future.microtask(() {
        if (!_disposed) notifyListeners();
      });
    }
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  Map<String, dynamic> _normalizeMap(dynamic m) {
    if (m == null) return {};
    if (m is Map<String, dynamic>) return m;
    if (m is Map) {
      final out = <String, dynamic>{};
      m.forEach((k, v) => out[k?.toString() ?? ''] = v);
      return out;
    }
    return {};
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

  // ── Exhaustive candidate field scanner ───────────────────────────────────
  List<dynamic> _extractCandidateEntries(Map<String, dynamic> data) {
    const candidateFields = [
      'candidates', 'candidate_ids', 'matched_candidates',
      'matched_seekers', 'seekers', 'seeker_ids',
      'job_seekers', 'jobSeekers', 'assignedCandidates',
      'assigned_candidates', 'candidate_list', 'candidateList',
      'users', 'applicants',
    ];
    final merged = <dynamic>[];
    for (final field in candidateFields) {
      final val = data[field];
      if (val != null) {
        final list = _normalizeList(val);
        if (list.isNotEmpty) {
          debugPrint('✅ Found ${list.length} candidates under "$field"');
          merged.addAll(list);
        }
      }
    }
    if (merged.isEmpty) {
      debugPrint('⚠️ No candidate entries found. Keys: ${data.keys.toList()}');
    }
    return merged;
  }

  // ── Exhaustive UID extractor — never returns empty ────────────────────────
  String _extractCandidateUid(Map<String, dynamic> n, int fallbackIndex) {
    const uidKeys = [
      'uid', 'user_id', 'userId', 'id', 'jobSeekerId',
      'job_seeker_id', 'seekerUid', 'seeker_uid',
      'candidate_uid', 'candidateUid', 'user_uid', 'userUid',
      'docId', 'doc_id',
    ];
    for (final key in uidKeys) {
      final v = n[key]?.toString().trim() ?? '';
      if (v.isNotEmpty && v.toLowerCase() != 'null') return _lastSegment(v);
    }
    final email = n['email']?.toString().trim() ?? '';
    if (email.isNotEmpty && email.contains('@')) return email;
    final generated = '__candidate_$fallbackIndex';
    debugPrint('⚠️ No uid/email for candidate $fallbackIndex, '
        'using "$generated". Keys: ${n.keys.toList()}');
    return generated;
  }

  // =========================================================================
  // FETCH ALL REQUESTS
  // =========================================================================

  Future<void> fetchAllRequests({bool realtime = false}) async {
    if (loading) return;
    loading = true;
    _safeNotify();
    debugPrint('🔍 fetchAllRequests(realtime=$realtime)');

    try {
      QuerySnapshot snap;
      try {
        snap = await _firestore
            .collection('recruiter_requests')
            .orderBy('created_at', descending: true)
            .get(const GetOptions(source: Source.cache));
      } catch (_) {
        snap = await _firestore
            .collection('recruiter_requests')
            .orderBy('created_at', descending: true)
            .get(const GetOptions(source: Source.server));
      }

      debugPrint('🔎 Found ${snap.docs.length} request docs');
      final tmp         = <Map<String, dynamic>>[];
      final recruiterIds = <String>{};

      for (final d in snap.docs) {
        final data          = _normalizeMap(d.data());
        final recruiterId   = (data['recruiter_id'] ?? data['recruiter'] ?? data['recruiter_uid'] ?? '').toString();
        final recruiterEmail = (data['recruiter_email'] ?? data['recruiterEmail'] ?? '').toString();
        final total         = data['total_candidates'] != null
            ? int.tryParse(data['total_candidates'].toString()) ?? 0
            : _extractCandidateEntries(data).length;

        tmp.add({
          'id': d.id,
          'recruiter_id': recruiterId,
          'recruiter_email': recruiterEmail,
          'total_candidates': total,
          'status': (data['status'] ?? 'pending').toString(),
          'created_at': data['created_at'],
          'notes': data['notes'] ?? '',
          'raw': data,
        });
        if (recruiterId.isNotEmpty) recruiterIds.add(recruiterId);
      }

      requests = tmp;
      debugPrint('✅ Loaded ${requests.length} request(s)');
      if (recruiterIds.isNotEmpty) _batchPrefetchRecruiters(recruiterIds.toList());
    } catch (e, st) {
      debugPrint('❌ fetchAllRequests error: $e\n$st');
      requests = [];
    } finally {
      loading = false;
      _safeNotify();
    }

    if (realtime) _startRealtimeListener();
  }

  // =========================================================================
  // FETCH REQUEST DETAILS
  // =========================================================================

  Future<Map<String, dynamic>?> fetchRequestDetails({
    required String requestId,
  }) async {
    debugPrint('🔍 fetchRequestDetails: $requestId');

    if (_requestDetailsCache.containsKey(requestId)) {
      final cached = _requestDetailsCache[requestId]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheTTL) {
        debugPrint('💾 Cache HIT: $requestId');
        return cached.data;
      }
      _requestDetailsCache.remove(requestId);
    }

    if (_pendingFetches.containsKey(requestId)) {
      debugPrint('⏳ Already fetching $requestId, waiting…');
      return _pendingFetches[requestId]!.future;
    }

    final completer = Completer<Map<String, dynamic>?>();
    _pendingFetches[requestId] = completer;
    loading = true;
    _safeNotify();

    try {
      DocumentSnapshot snap;
      try {
        snap = await _firestore.collection('recruiter_requests').doc(requestId)
            .get(const GetOptions(source: Source.cache));
      } catch (_) {
        snap = await _firestore.collection('recruiter_requests').doc(requestId)
            .get(const GetOptions(source: Source.server));
      }

      if (_disposed) { completer.complete(null); return null; }
      if (!snap.exists) {
        debugPrint('⚠️ Request doc $requestId does not exist');
        completer.complete(null);
        return null;
      }

      final data        = _normalizeMap(snap.data());
      debugPrint('📄 Request doc keys: ${data.keys.toList()}');
      final recruiterId = (data['recruiter_id'] ?? data['recruiter'] ?? '').toString();
      final rawEntries  = _extractCandidateEntries(data);
      debugPrint('📋 Raw candidate entries: ${rawEntries.length}');

      final uniqueCandidates = <String, String>{};
      final candidateHints   = <String, Map<String, dynamic>>{};

      for (int i = 0; i < rawEntries.length; i++) {
        final entry = rawEntries[i];
        String rawUid = '';
        Map<String, dynamic> hint = {};
        try {
          if (entry is Map) {
            hint   = _normalizeMap(entry);
            rawUid = _extractCandidateUid(hint, i);
          } else if (entry is String) {
            rawUid = entry.trim();
          } else if (entry is DocumentReference) {
            rawUid = entry.id;
          }
        } catch (e) {
          debugPrint('⚠️ Error reading candidate entry $i: $e');
          rawUid = '__candidate_$i';
        }
        if (rawUid.isEmpty) rawUid = '__candidate_$i';
        final uid = _lastSegment(rawUid);
        final key = uid.toLowerCase();
        if (!uniqueCandidates.containsKey(key)) {
          uniqueCandidates[key] = uid;
          if (hint.isNotEmpty) candidateHints[uid] = hint;
        }
      }

      debugPrint('👥 Unique candidate UIDs: ${uniqueCandidates.values.toList()}');

      // ── FIX: If the raw entries are rich Map objects (already contain full
      // profile data from the recruiter_requests/candidates[] array), use them
      // directly instead of fetching thin records from Job_Seeker / users.
      // A "rich" entry is one that has at least 'name' OR 'skills' OR
      // 'professionalExperience' — i.e. it's more than just a UID reference.
      bool allEntriesAreRichObjects = rawEntries.isNotEmpty &&
          rawEntries.every((e) {
            if (e is! Map) return false;
            final m = _normalizeMap(e);
            return m.containsKey('name') ||
                m.containsKey('skills') ||
                m.containsKey('professionalExperience') ||
                m.containsKey('experienceDocuments');
          });

      List<Map<String, dynamic>> candidateDetails;

      if (allEntriesAreRichObjects) {
        debugPrint('✅ candidates[] contains full profile objects — using directly');
        // Use the embedded data as-is; normalise each entry
        final seen = <String>{};
        candidateDetails = [];
        for (final e in rawEntries) {
          final m   = _normalizeMap(e);
          final uid = _extractCandidateUid(m, candidateDetails.length);
          if (seen.contains(uid.toLowerCase())) continue;
          seen.add(uid.toLowerCase());
          // Ensure 'uid' key is present for downstream widgets
          final card = {...m, 'uid': uid};
          candidateDetails.add(card);
          // Cache so _batchFetchCandidates can reuse if needed later
          _candidateCache[uid] = _CacheEntry(card, DateTime.now());
        }
      } else {
        candidateDetails = await _batchFetchCandidates(
            uniqueCandidates.values.toList(), hints: candidateHints);
        if (_disposed) { completer.complete(null); return null; }
      }

      debugPrint('✅ Candidates resolved: ${candidateDetails.length}');

      final recruiterInfo = await _fetchRecruiterInfo(recruiterId);
      if (_disposed) { completer.complete(null); return null; }

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
  // OPTIMISTIC CANDIDATE STATUS UPDATE
  //
  // Updates the in-memory cache IMMEDIATELY so the UI (pipeline bar, status
  // badge, etc.) reflects the new state without any round-trip or rebuild
  // cascade. Call this before firing the Firestore write.
  // =========================================================================

  void optimisticCandidateStatusUpdate(
      String requestId, String candidateUid, String status) {
    if (_disposed) return;
    final cached = _requestDetailsCache[requestId];
    if (cached == null) return;

    try {
      // Deep-copy the nested maps we need to mutate
      final details = Map<String, dynamic>.from(cached.data);
      final reqDoc  = Map<String, dynamic>.from(
          (details['request_doc'] as Map?)?.cast<String, dynamic>() ?? {});
      final reqData = Map<String, dynamic>.from(
          (reqDoc['data'] as Map?)?.cast<String, dynamic>() ?? {});
      final statuses = Map<String, dynamic>.from(
          (reqData['candidate_statuses'] as Map?)?.cast<String, dynamic>() ?? {});

      final normalized =
      status.toLowerCase() == 'shortlisted' ? 'shortlist' : status.toLowerCase();
      statuses[candidateUid.toLowerCase()] = normalized;

      reqData['candidate_statuses'] = statuses;
      reqDoc['data']                = reqData;
      details['request_doc']        = reqDoc;

      _requestDetailsCache[requestId] = _CacheEntry(details, DateTime.now());
      _safeNotify();
      debugPrint('⚡ Optimistic update: $candidateUid → $normalized');
    } catch (e) {
      debugPrint('⚠️ optimisticCandidateStatusUpdate error: $e');
    }
  }

  // =========================================================================
  // BATCH FETCH CANDIDATES
  // =========================================================================

  Future<List<Map<String, dynamic>>> _batchFetchCandidates(
      List<String> candidateIds, {
        Map<String, Map<String, dynamic>>? hints,
        int batchSize = 10,
      }) async {
    if (candidateIds.isEmpty) return [];

    final realIds     = candidateIds.where((id) => !id.startsWith('__candidate_')).toList();
    final fallbackIds = candidateIds.where((id) => id.startsWith('__candidate_')).toList();

    final fallbackCards = fallbackIds.map((id) {
      final hint = _normalizeMap(hints?[id]);
      return _buildFallbackCard(id, hint);
    }).toList();

    if (realIds.isEmpty) return fallbackCards;

    final uncachedIds   = <String>[];
    final cachedResults = <Map<String, dynamic>>[];

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

    Future<List<List<T>>> _batchSplit<T>(List<T> items) async =>
        [for (var i = 0; i < items.length; i += batchSize)
          items.sublist(i, (i + batchSize).clamp(0, items.length))];

    try {
      // Step A: Job_Seeker by docId
      for (final batch in await _batchSplit(uncachedIds)) {
        try {
          final snap = await _firestore
              .collection('Job_Seeker')
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          fetchedResults.addAll(_parseJobSeekerDocs(snap.docs, hints));
        } catch (e) {
          debugPrint('⚠️ Job_Seeker docId batch error: $e');
        }
      }

      // Step B: Job_Seeker by uid field
      final foundB = fetchedResults.map((c) => c['uid'].toString()).toSet();
      final missingB = uncachedIds.where((id) => !foundB.contains(id)).toList();
      if (missingB.isNotEmpty) {
        for (final batch in await _batchSplit(missingB)) {
          try {
            final snap = await _firestore
                .collection('Job_Seeker')
                .where('uid', whereIn: batch)
                .get();
            fetchedResults.addAll(_parseJobSeekerDocs(snap.docs, hints));
          } catch (e) {
            debugPrint('⚠️ Job_Seeker uid-field batch error: $e');
          }
        }
      }

      // Step C: users collection by docId
      final foundC = fetchedResults.map((c) => c['uid'].toString()).toSet();
      final missingC = uncachedIds.where((id) => !foundC.contains(id)).toList();
      if (missingC.isNotEmpty) {
        debugPrint('🔍 ${missingC.length} not in Job_Seeker, trying "users"');
        for (final batch in await _batchSplit(missingC)) {
          try {
            final snap = await _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: batch)
                .get();
            fetchedResults.addAll(_parseUsersDocs(snap.docs, hints));
          } catch (e) {
            debugPrint('⚠️ users docId batch error: $e');
          }
        }

        // Step D: users collection by uid field
        final foundD = fetchedResults.map((c) => c['uid'].toString()).toSet();
        final missingD = missingC.where((id) => !foundD.contains(id)).toList();
        if (missingD.isNotEmpty) {
          for (final batch in await _batchSplit(missingD)) {
            try {
              final snap = await _firestore
                  .collection('users')
                  .where('uid', whereIn: batch)
                  .get();
              fetchedResults.addAll(_parseUsersDocs(snap.docs, hints));
            } catch (e) {
              debugPrint('⚠️ users uid-field batch error: $e');
            }
          }
        }
      }

      // Step E: email-based lookup + fallback cards for anything still missing
      final foundAll = fetchedResults.map((c) => c['uid'].toString()).toSet();
      for (final id in uncachedIds) {
        if (foundAll.contains(id)) continue;
        if (id.contains('@')) {
          debugPrint('🔍 "$id" looks like email, trying email lookup');
          try {
            final snap = await _firestore
                .collection('Job_Seeker')
                .where('email', isEqualTo: id)
                .limit(1)
                .get();
            if (snap.docs.isNotEmpty) {
              final parsed = _parseJobSeekerDocs(snap.docs, hints);
              if (parsed.isNotEmpty) { fetchedResults.addAll(parsed); continue; }
            }
          } catch (e) {
            debugPrint('⚠️ email lookup error: $e');
          }
        }
        debugPrint('⚠️ "$id" not found in any collection — building fallback card');
        final card = _buildFallbackCard(id, _normalizeMap(hints?[id]));
        fetchedResults.add(card);
        _candidateCache[id] = _CacheEntry(card, DateTime.now());
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
      final pp = _normalizeMap(
        jsData['personalProfile'] ?? jsData['personal_profile'] ??
            userData['personalProfile'] ?? userData['personal_profile'] ?? {},
      );
      final prof = _normalizeMap(
          jsData['professionalProfile'] ?? jsData['professional_profile'] ?? {});
      final storedUid = jsData['uid']?.toString() ??
          jsData['user_id']?.toString() ?? userData['uid']?.toString() ?? doc.id;

      String resolveName() {
        for (final src in [pp, jsData, userData, prof]) {
          for (final key in ['name', 'fullName', 'full_name', 'displayName']) {
            final v = src[key]?.toString().trim() ?? '';
            if (v.isNotEmpty && v.toLowerCase() != 'null') return v;
          }
          final fn = src['firstName']?.toString().trim() ?? '';
          final ln = src['lastName']?.toString().trim() ?? '';
          if (fn.isNotEmpty) return '$fn $ln'.trim();
        }
        return doc.id;
      }

      final hint   = _normalizeMap(hints?[doc.id] ?? hints?[storedUid] ?? {});
      final result = {
        'uid':      storedUid,
        'doc_id':   doc.id,
        'name':     resolveName(),
        'email':    pp['email']?.toString() ?? pp['emailAddress']?.toString() ??
            jsData['email']?.toString() ?? userData['email']?.toString() ?? '',
        'phone':    pp['contactNumber']?.toString() ?? pp['phone']?.toString() ??
            pp['phoneNumber']?.toString() ?? jsData['phone']?.toString() ??
            userData['phone']?.toString() ?? '',
        'job_title': prof['job_title']?.toString() ?? prof['jobTitle']?.toString() ??
            jsData['job_title']?.toString() ?? jsData['jobTitle']?.toString() ??
            hint['job_title']?.toString() ?? '',
        'company':   prof['company']?.toString() ?? jsData['company']?.toString() ??
            hint['company']?.toString() ?? '',
        'user_data': {...hint, ...jsData},
      };
      _candidateCache[doc.id]    = _CacheEntry(result, DateTime.now());
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
        'uid':      doc.id,
        'name':     data['name']?.toString() ?? data['displayName']?.toString() ?? doc.id,
        'email':    data['email']?.toString() ?? '',
        'phone':    data['phone']?.toString() ?? '',
        'job_title': data['job_title']?.toString() ?? data['jobTitle']?.toString() ??
            hint['job_title']?.toString() ?? '',
        'company':   data['company']?.toString() ?? data['org']?.toString() ??
            hint['company']?.toString() ?? '',
        'user_data': {...hint, ...data},
      };
      _candidateCache[doc.id] = _CacheEntry(result, DateTime.now());
      results.add(result);
    }
    return results;
  }

  Map<String, dynamic> _buildFallbackCard(String uid, Map<String, dynamic> hint) {
    final pp   = _normalizeMap(hint['personalProfile'] ?? hint['personal_profile'] ?? {});
    final prof = _normalizeMap(hint['professionalProfile'] ?? hint['professional_profile'] ?? {});
    final ud   = _normalizeMap(hint['user_data'] ?? {});
    final udPp = _normalizeMap(ud['personalProfile'] ?? ud['personal_profile'] ?? {});

    String resolveName() {
      for (final src in [pp, udPp, hint, ud, prof]) {
        for (final key in ['name', 'fullName', 'full_name', 'displayName']) {
          final v = src[key]?.toString().trim() ?? '';
          if (v.isNotEmpty && v.toLowerCase() != 'null') return v;
        }
        final fn = src['firstName']?.toString().trim() ?? '';
        final ln = src['lastName']?.toString().trim() ?? '';
        if (fn.isNotEmpty) return '$fn $ln'.trim();
      }
      final email = hint['email']?.toString().trim() ?? pp['email']?.toString().trim() ?? '';
      if (email.contains('@')) return email.split('@').first;
      return uid.startsWith('__') ? 'Unknown Candidate' : uid;
    }

    return {
      'uid':      uid,
      'name':     resolveName(),
      'email':    hint['email']?.toString() ?? pp['email']?.toString() ?? ud['email']?.toString() ?? '',
      'phone':    hint['phone']?.toString() ?? hint['contactNumber']?.toString() ??
          pp['phone']?.toString() ?? pp['contactNumber']?.toString() ?? '',
      'job_title': prof['job_title']?.toString() ?? prof['jobTitle']?.toString() ??
          hint['job_title']?.toString() ?? hint['jobTitle']?.toString() ?? '',
      'company':   prof['company']?.toString() ?? hint['company']?.toString() ??
          hint['org']?.toString() ?? '',
      'user_data': hint,
    };
  }

  // =========================================================================
  // FETCH RECRUITER INFO
  // =========================================================================

  Future<Map<String, dynamic>?> _fetchRecruiterInfo(String recruiterId) async {
    if (recruiterId.isEmpty) return null;
    if (_recruiterCache.containsKey(recruiterId)) {
      final cached = _recruiterCache[recruiterId]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheTTL) return cached.data;
      _recruiterCache.remove(recruiterId);
    }
    try {
      DocumentSnapshot snap;
      try {
        snap = await _firestore.collection('recruiter').doc(recruiterId)
            .get(const GetOptions(source: Source.cache));
      } catch (_) {
        snap = await _firestore.collection('recruiter').doc(recruiterId)
            .get(const GetOptions(source: Source.server));
      }
      if (!snap.exists) return null;
      final data     = _normalizeMap(snap.data());
      final userData = data.containsKey('user_data') && data['user_data'] != null
          ? _normalizeMap(data['user_data'])
          : {'name': data['name'] ?? data['displayName'] ?? '',
        'email': data['email'] ?? '', 'company': data['company'] ?? data['org'] ?? ''};
      _recruiterCache[recruiterId] = _CacheEntry(userData, DateTime.now());
      return userData;
    } catch (e) {
      debugPrint('❌ _fetchRecruiterInfo error: $e');
      return null;
    }
  }

  // =========================================================================
  // BATCH PREFETCH RECRUITERS
  // =========================================================================

  Future<void> _batchPrefetchRecruiters(List<String> recruiterIds) async {
    const batchSize = 10;
    final batches = [for (var i = 0; i < recruiterIds.length; i += batchSize)
      recruiterIds.sublist(i, (i + batchSize).clamp(0, recruiterIds.length))];
    try {
      await Future.wait(batches.map((batch) async {
        QuerySnapshot snap;
        try {
          snap = await _firestore.collection('recruiter')
              .where(FieldPath.documentId, whereIn: batch)
              .get(const GetOptions(source: Source.cache));
        } catch (_) {
          snap = await _firestore.collection('recruiter')
              .where(FieldPath.documentId, whereIn: batch)
              .get(const GetOptions(source: Source.server));
        }
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
  // REALTIME LISTENER
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
          // Skip if we have pending local writes to avoid flickering
          if (change.doc.metadata.hasPendingWrites) continue;

          final data        = _normalizeMap(change.doc.data());
          final recruiterId = (data['recruiter_id'] ?? data['recruiter'] ?? '').toString();
          final total       = data['total_candidates'] != null
              ? int.tryParse(data['total_candidates'].toString()) ?? 0
              : _extractCandidateEntries(data).length;

          final entry = {
            'id': change.doc.id, 'recruiter_id': recruiterId,
            'recruiter_email': (data['recruiter_email'] ?? data['recruiterEmail'] ?? '').toString(),
            'total_candidates': total,
            'status': (data['status'] ?? 'pending').toString(),
            'created_at': data['created_at'],
            'notes': data['notes'] ?? '', 'raw': data,
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

              // ── FIX: If the selected request modified on server, patch the cache
              // instead of just leaving it stale or evicting.
              if (_selectedRequestId == change.doc.id) {
                final cached = _requestDetailsCache[change.doc.id];
                if (cached != null) {
                  try {
                    final details = Map<String, dynamic>.from(cached.data);
                    final reqDoc  = Map<String, dynamic>.from(
                        (details['request_doc'] as Map?)?.cast<String, dynamic>() ?? {});
                    // Update only the document data from the heartbeat
                    reqDoc['data'] = data;
                    details['request_doc'] = reqDoc;
                    _requestDetailsCache[change.doc.id] = _CacheEntry(details, DateTime.now());
                    debugPrint('⚡ Realtime patch for selected request: ${change.doc.id}');
                  } catch (e) {
                    debugPrint('⚠️ Failed to patch selected request cache: $e');
                    _requestDetailsCache.remove(change.doc.id);
                  }
                }
              } else {
                // Not selected? Safe to evict so it re-fetches next time.
                _requestDetailsCache.remove(change.doc.id);
              }
            }
          }
 else if (change.type == DocumentChangeType.removed) {
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
  // UPDATE REQUEST STATUS
  // =========================================================================

  Future<bool> updateRequestStatus({
    required String requestId,
    required String newStatus,
    String? note,
    String? performedBy,
  }) async {
    if (_disposed) return false;

    // ── FIX: Patch the memory and notify IMMEDIATELY for instant UI ───────
    final idx = requests.indexWhere((r) => r['id'] == requestId);
    if (idx != -1) {
      requests[idx]['status'] = newStatus;
      requests[idx]['last_updated_at'] = DateTime.now();
    }

    final cached = _requestDetailsCache[requestId];
    if (cached != null) {
      try {
        final details = Map<String, dynamic>.from(cached.data);
        final reqDoc  = Map<String, dynamic>.from(
            (details['request_doc'] as Map?)?.cast<String, dynamic>() ?? {});
        final reqData = Map<String, dynamic>.from(
            (reqDoc['data'] as Map?)?.cast<String, dynamic>() ?? {});
        reqData['status']          = newStatus;
        reqData['last_updated_at'] = DateTime.now().toIso8601String();
        reqDoc['data']             = reqData;
        details['request_doc']     = reqDoc;
        _requestDetailsCache[requestId] = _CacheEntry(details, DateTime.now());
        debugPrint('⚡ Optimistic request-status patch (pre-write): $requestId → $newStatus');
      } catch (e) {
        debugPrint('⚠️ Failed to patch request-status cache: $e');
      }
    }
    _safeNotify();

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
        'action': 'update_status', 'status': newStatus,
        'note': note ?? '', 'performed_by': performedBy ?? 'admin',
        'created_at': now,
      });
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('❌ updateRequestStatus error: $e');
      // On failure: invalidate cache so next reload restores server state
      _requestDetailsCache.remove(requestId);
      _safeNotify();
      return false;
    }
  }

  // =========================================================================
  // UPDATE CANDIDATE STATUS
  //
  // CHANGED: No longer calls fetchRequestDetails after a successful write.
  // The UI has already been updated via optimisticCandidateStatusUpdate().
  // On failure we invalidate the cache so the next open restores server state.
  // =========================================================================

  Future<bool> updateCandidateStatus({
    required String requestId,
    required String candidateUid,
    required String status,
    String? note,
    String? performedBy,
  }) async {
    if (_disposed) return false;
    final normalized =
    status.toLowerCase() == 'shortlisted' ? 'shortlist' : status.toLowerCase();
    try {
      final now = FieldValue.serverTimestamp();
      final ref = _firestore.collection('recruiter_requests').doc(requestId);

      // Read current candidates array for the Firestore update
      final snap = await ref.get();
      if (_disposed || !snap.exists) return false;

      final data       = snap.data() as Map<String, dynamic>;
      final candidates = List<dynamic>.from(data['candidates'] ?? []);
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
        'status': normalized,
        'note': note ?? '',
        'performed_by': performedBy ?? 'admin',
        'created_at': now,
      });
      await batch.commit();

      // Success: optimistic cache already reflects the new state — do nothing.
      debugPrint('✅ Firestore write confirmed: $candidateUid → $normalized');
      return true;
    } catch (e) {
      debugPrint('❌ updateCandidateStatus error: $e');
      // On failure: invalidate cache so next open restores correct state
      _requestDetailsCache.remove(requestId);
      // If currently viewing this request, quietly re-fetch in background
      if (!_disposed && _selectedRequestId == requestId) {
        fetchRequestDetails(requestId: requestId);
      }
      return false;
    }
  }

  // =========================================================================
  // CACHE MANAGEMENT
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
    if (m == null) return {};
    if (m is Map<String, dynamic>) return m;
    if (m is Map) {
      final out = <String, dynamic>{};
      m.forEach((k, v) => out[k?.toString() ?? ''] = v);
      return out;
    }
    return {};
  }

  static String formatDate(dynamic timestamp, [String fallback = '-']) {
    if (timestamp == null) return fallback;
    if (timestamp is Timestamp) {
      return DateFormat('MMM d, yyyy').format(timestamp.toDate());
    }
    if (timestamp is DateTime) {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
    if (timestamp is String && timestamp.isNotEmpty) {
      final d = DateTime.tryParse(timestamp);
      if (d != null) return DateFormat('MMM d, yyyy').format(d);
    }
    return timestamp.toString().isNotEmpty ? timestamp.toString() : fallback;
  }

  static String formatDateTime(dynamic timestamp, [String fallback = '-']) {
    if (timestamp == null) return fallback;
    if (timestamp is Timestamp) {
      return DateFormat('MMM d, yyyy · h:mm a').format(timestamp.toDate());
    }
    if (timestamp is DateTime) {
      return DateFormat('MMM d, yyyy · h:mm a').format(timestamp);
    }
    if (timestamp is String && timestamp.isNotEmpty) {
      final d = DateTime.tryParse(timestamp);
      if (d != null) return DateFormat('MMM d, yyyy · h:mm a').format(d);
    }
    return timestamp.toString().isNotEmpty ? timestamp.toString() : fallback;
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
          final name = _normalizeMap(data['user_data'])['name']?.toString() ??
              data['name']?.toString() ?? 'Unknown Recruiter';
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

// ── Cache entry ───────────────────────────────────────────────────────────────
class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  _CacheEntry(this.data, this.timestamp);
}