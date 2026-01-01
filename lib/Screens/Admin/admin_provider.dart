// user_management_provider.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  Future<void> addOrEditUser(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      _isLoading = true;
      _message = '';
      notifyListeners();

      try {
        UserCredential? userCredential;
        String uid;
        DocumentReference userDocRef;

        if (_editingUserId == null) {
          // === CREATE NEW USER ===
          // Create user in Firebase Auth
          userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          uid = userCredential.user!.uid;

          // Create a new document with AUTO-GENERATED ID in 'users' collection
          userDocRef = FirebaseFirestore.instance.collection('users').doc(); // Auto ID

          // Save user data with auto-generated Firestore doc ID
          await userDocRef.set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'auth_uid': uid,                    // Store Auth UID separately
            'role': _roleController.text.trim(),
            'account_status': 'active',
            'user_lvl': _userLevelController.text.trim(),
            'created_at': FieldValue.serverTimestamp(),
          });
        } else {
          // === EDIT EXISTING USER ===
          // _editingUserId now holds the Firestore document ID (auto-generated)
          userDocRef = FirebaseFirestore.instance.collection('users').doc(_editingUserId);

          await userDocRef.update({
            'name': _nameController.text.trim(),
            'role': _roleController.text.trim(),
            'user_lvl': _userLevelController.text.trim(),
          });
          uid = ''; // Not needed for edit
        }

        _message = _editingUserId == null ? 'User added successfully' : 'User updated successfully';
        clearForm();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_message)));
      } catch (e) {
        _message = 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_message)));
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> suspendUser(String firestoreDocId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firestoreDocId)
          .update({'account_status': newStatus});
    } catch (e) {
      // Handle error
    }
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      // Handle error
    }
  }

  void editUser(Map<String, dynamic> userData, String firestoreDocId) {
    _nameController.text = userData['name'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _roleController.text = userData['role'] ?? '';
    _userLevelController.text = userData['user_lvl'] ?? '';
    _passwordController.clear();
    _editingUserId = firestoreDocId; // This is now the auto-generated Firestore doc ID
    notifyListeners();
  }

  void clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _roleController.clear();
    _userLevelController.clear();
    _editingUserId = null;
    _message = '';
    notifyListeners();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool loading = false;
  bool _disposed = false;

  /// Top-level list of request documents across recruiters.
  List<Map<String, dynamic>> requests = [];

  /// Cache recruiter info by recruiterId
  final Map<String, Map<String, dynamic>> _recruiterCache = {};

  /// Cache profile by candidate uid (keyed by actual job_seeker doc id)
  final Map<String, Map<String, dynamic>> _profileCache = {};

  /// Cache email -> uid lookups to avoid repeated queries
  final Map<String, String> _emailToUidCache = {};

  /// Optional realtime subscription
  StreamSubscription<QuerySnapshot>? _requestsSub;

  void UserManagementProvider() {
    fetchAllRequests();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ---------- Helper: normalize any Map to Map<String,dynamic> ----------
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

  /// Helper: normalize a list to List<dynamic>
  List<dynamic> _normalizeList(dynamic list) {
    if (list == null) return [];
    if (list is List) return List<dynamic>.from(list);
    return [];
  }

  // canonicalize key used for dedupe/lookups
  String _canon(String s) => s.trim().toLowerCase();

  /// Fetch all top-level request documents
  Future<void> fetchAllRequests({bool realtime = false}) async {
    loading = true;
    _safeNotify();
    debugPrint('🔍 Admin: fetchAllRequests(realtime=$realtime)');

    try {
      final col = _firestore.collection('recruiter_requests');
      final snap = await col.get(const GetOptions(source: Source.serverAndCache));
      debugPrint('🔎 Found ${snap.docs.length} request docs');

      final List<Map<String, dynamic>> tmp = [];
      final Set<String> recruiterIdsToPrefetch = {};

      for (final d in snap.docs) {
        final data = _normalizeMap(d.data());

        final recruiterId = (data['recruiter_id'] ??
            data['recruiter'] ??
            data['recruiter_uid'] ?? '').toString();
        final recruiterEmail = (data['recruiter_email'] ??
            data['recruiterEmail'] ?? '').toString();

        // Calculate total_candidates from various possible fields
        int totalCandidates = 0;
        if (data['total_candidates'] != null) {
          totalCandidates = int.tryParse(data['total_candidates'].toString()) ?? 0;
        } else {
          final candidateIds = _normalizeList(data['candidate_ids']);
          final candidates = _normalizeList(data['candidates']);
          totalCandidates = candidateIds.isNotEmpty ? candidateIds.length : candidates.length;
        }

        final status = (data['status'] ?? 'pending').toString();
        final createdAt = data['created_at'];

        final entry = <String, dynamic>{
          'id': d.id,
          'recruiter_id': recruiterId,
          'recruiter_email': recruiterEmail,
          'total_candidates': totalCandidates,
          'status': status,
          'created_at': createdAt,
          'notes': data['notes'] ?? '',
          'raw': data,
        };

        tmp.add(entry);
        if (recruiterId.isNotEmpty) recruiterIdsToPrefetch.add(recruiterId);
      }

      requests = tmp;
      debugPrint('✅ Admin: loaded ${requests.length} request(s)');

      // Warm up cache for recruiters
      if (recruiterIdsToPrefetch.isNotEmpty) {
        Future.microtask(() async {
          try {
            await Future.wait(
                recruiterIdsToPrefetch.map((id) => _fetchRecruiterInfo(id))
            );
            debugPrint('💾 Recruiter cache warmed for ${recruiterIdsToPrefetch.length} recruiters');
            _safeNotify();
          } catch (e) {
            debugPrint('⚠️ Recruiter warm cache error: $e');
          }
        });
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
      await _startRealtimeListener();
    }
  }

  Future<void> _startRealtimeListener() async {
    _requestsSub?.cancel();
    _requestsSub = _firestore
        .collection('recruiter_requests')
        .snapshots()
        .listen((snap) {
      debugPrint('🔔 realtime requests change: ${snap.docChanges.length} changes');
      fetchAllRequests();
    }, onError: (e) {
      debugPrint('❌ realtime listener error: $e');
    });
  }

  // Helper: if a value looks like a path (collection/doc/...), extract last segment
  String _lastSegment(String s) {
    final str = s.trim();
    if (str.contains('/')) {
      final parts = str.split('/');
      return parts.isNotEmpty ? parts.last : str;
    }
    return str;
  }

  // Resolve an "orig" identifier which may be:
  //  - a direct uid (document id)
  //  - a full path -> last segment is doc id
  //  - an email (contains '@') or 'email:...' fallback
  // When orig is an email, try to find a job_seeker doc with that email and return its id.
  Future<String?> _resolveToDocId(String orig) async {
    final raw = orig.trim();
    if (raw.isEmpty) return null;

    // If already looks like a path, extract last segment
    final byPath = _lastSegment(raw);

    // If it contains '@' or startsWith 'email:', treat as email and query
    String maybeEmail = '';
    if (byPath.startsWith('email:')) {
      maybeEmail = byPath.substring(6); // after "email:"
    } else if (byPath.contains('@')) {
      maybeEmail = byPath;
    }

    if (maybeEmail.isNotEmpty) {
      final emailKey = _canon(maybeEmail);
      if (_emailToUidCache.containsKey(emailKey)) {
        debugPrint('💾 email->uid cache hit for $emailKey -> ${_emailToUidCache[emailKey]}');
        return _emailToUidCache[emailKey];
      }

      try {
        debugPrint('🔎 resolving email to uid: $maybeEmail');
        // Look for job_seeker doc where user_data.email or email equals this email (best-effort)
        final query1 = await _firestore
            .collection('job_seeker')
            .where('user_data.email', isEqualTo: maybeEmail)
            .limit(1)
            .get(const GetOptions(source: Source.serverAndCache));

        if (query1.docs.isNotEmpty) {
          final id = query1.docs.first.id;
          _emailToUidCache[emailKey] = id;
          debugPrint('✅ resolved email->uid via user_data.email: $maybeEmail -> $id');
          return id;
        }

        // fallback: maybe top-level 'email' field exists
        final query2 = await _firestore
            .collection('job_seeker')
            .where('email', isEqualTo: maybeEmail)
            .limit(1)
            .get(const GetOptions(source: Source.serverAndCache));

        if (query2.docs.isNotEmpty) {
          final id = query2.docs.first.id;
          _emailToUidCache[emailKey] = id;
          debugPrint('✅ resolved email->uid via email field: $maybeEmail -> $id');
          return id;
        }

        debugPrint('⚠️ no job_seeker doc found for email $maybeEmail');
        // store negative cache? (optional) — don't cache misses to allow future writes to succeed
        return null;
      } catch (e) {
        debugPrint('❌ error resolving email to uid: $e');
        return null;
      }
    }

    // Otherwise treat byPath as a likely uid; return it.
    return byPath;
  }

  /// Fetch full detail for a single request (updated to avoid duplicate candidates)
  Future<Map<String, dynamic>?> fetchRequestDetails({
    required String requestId,
  }) async {
    debugPrint('🔍 Admin: fetchRequestDetails requestId=$requestId');
    loading = true;
    _safeNotify();

    try {
      final ref = _firestore.collection('recruiter_requests').doc(requestId);
      final snap = await ref.get(const GetOptions(source: Source.serverAndCache));

      if (!snap.exists) {
        debugPrint('⚠️ Request $requestId not found');
        loading = false;
        _safeNotify();
        return null;
      }

      final data = _normalizeMap(snap.data());

      // Get recruiter id
      final recruiterId = (data['recruiter_id'] ?? data['recruiter'] ?? '').toString();

      // Collect candidate entries from possible fields
      final candidatesFromCandidates = _normalizeList(data['candidates']);
      final candidatesFromIds = _normalizeList(data['candidate_ids']);

      // Combine raw entries preserving order (candidates field first, then ids)
      final List<dynamic> rawEntries = [];
      rawEntries.addAll(candidatesFromCandidates);
      rawEntries.addAll(candidatesFromIds);

      debugPrint('🔎 Raw request entries count: ${rawEntries.length}');

      // Normalize & dedupe by canonical key while keeping original raw id for lookups
      // key -> { origId: String, basic: Map<String,dynamic>, firstSeenIndex: int }
      final Map<String, Map<String, dynamic>> uniqueByKey = {};
      final List<String> orderKeys = [];

      int idx = 0;
      for (final entry in rawEntries) {
        idx++;
        try {
          String origId = '';
          Map<String, dynamic> basic = {};

          // DocumentReference -> id
          if (entry is DocumentReference) {
            origId = entry.id ?? '';
          }
          // String: could be uid, doc path, or email
          else if (entry is String) {
            origId = entry.trim();
          }
          // Map-like entry
          else if (entry is Map) {
            final normalized = _normalizeMap(entry);
            basic = Map<String, dynamic>.from(normalized);

            origId = (normalized['uid'] ??
                normalized['user_id'] ??
                normalized['id'] ??
                normalized['candidate_id'] ??
                normalized['candidateUid'] ??
                normalized['uid_str'] ??
                '').toString().trim();

            // fallback to email or ref fields if no uid present
            if (origId.isEmpty) {
              if ((normalized['email'] ?? '').toString().isNotEmpty) {
                origId = 'email:${normalized['email'].toString().trim()}';
              } else if ((normalized['ref'] ?? normalized['doc_ref'] ?? '').toString().isNotEmpty) {
                origId = normalized['ref'].toString().trim();
              }
            }
          } else {
            // last resort
            origId = entry.toString().trim();
          }

          // If still empty, skip this row (prevents empty / blank UI rows)
          if (origId.isEmpty || origId == '-' || origId.toLowerCase() == 'null') {
            debugPrint('⚠️ skipping candidate entry with no meaningful id: $entry');
            continue;
          }

          // canonical dedupe key: prefer canonicalized doc-id; if this looks like an email use 'email:...'
          String key;
          {
            final last = _lastSegment(origId);
            if (last.contains('@') || origId.toLowerCase().startsWith('email:')) {
              final email = origId.toLowerCase().replaceFirst('email:', '').trim();
              key = 'email:${_canon(email)}';
            } else {
              key = _canon(last);
            }
          }

          debugPrint('🔍 candidate raw="$origId" -> key="$key"');

          if (!uniqueByKey.containsKey(key)) {
            uniqueByKey[key] = {
              'origId': origId,
              'basic': basic,
              'firstSeenIndex': idx,
            };
            orderKeys.add(key);
          } else {
            // merge basic info: prefer earlier non-empty values, but fill missing fields from later entries
            final existing = Map<String, dynamic>.from(uniqueByKey[key]!['basic'] as Map<String, dynamic>);
            final incoming = basic;
            incoming.forEach((k, v) {
              if ((existing[k] == null || existing[k].toString().trim().isEmpty) &&
                  v != null &&
                  v.toString().trim().isNotEmpty) {
                existing[k] = v;
              }
            });
            uniqueByKey[key]!['basic'] = existing;
          }
        } catch (e, st) {
          debugPrint('⚠️ error normalizing candidate entry: $e\n$st');
        }
      }

      debugPrint('✅ Resolved ${uniqueByKey.length} unique candidate key(s) after dedupe');

      // Fetch recruiter info (cache-aware)
      final recruiterInfo = await _fetchRecruiterInfo(recruiterId);

      // Now fetch profiles for each unique key in original order
      final List<Map<String, dynamic>> candidateDetails = [];
      for (final key in orderKeys) {
        try {
          final item = uniqueByKey[key]!;
          String origId = (item['origId']?.toString() ?? '').trim();
          final basic = Map<String, dynamic>.from(item['basic'] as Map<String, dynamic>);

          // Resolve origId -> actual document id (if origId is an email fallback or path)
          final resolvedDocId = await _resolveToDocId(origId) ?? '';

          Map<String, dynamic>? profile;
          if (resolvedDocId.isNotEmpty) {
            // fetch profile using actual doc id (cache-aware)
            profile = await _fetchCandidateUserProfile(resolvedDocId);
          } else {
            // If we couldn't resolve to a doc id, still attempt to treat origId as uid
            // (this allows entries that were actual uids but the resolver failed)
            final fallbackId = _lastSegment(origId);
            profile = await _fetchCandidateUserProfile(fallbackId);
          }

          // Attempt to load job_seeker root user_data (best-effort, non-fatal)
          Map<String, dynamic>? userData;
          try {
            final candidateDocId = (resolvedDocId.isNotEmpty ? resolvedDocId : _lastSegment(origId));
            if (candidateDocId.isNotEmpty) {
              final doc = await _firestore
                  .collection('job_seeker')
                  .doc(candidateDocId)
                  .get(const GetOptions(source: Source.serverAndCache));
              if (doc.exists) {
                final d = _normalizeMap(doc.data());
                if (d.containsKey('user_data') && d['user_data'] != null) {
                  userData = _normalizeMap(d['user_data']);
                } else {
                  userData = <String, dynamic>{
                    'name': d['name'] ?? d['displayName'] ?? profile?['name'] ?? '',
                    'email': d['email'] ?? profile?['email'] ?? '',
                  };
                }
              }
            }
          } catch (e) {
            debugPrint('⚠️ user_data fetch failed for orig="$origId": $e');
          }

          // Build display values using priority: basic -> profile -> user_data
          final displayName = basic['name'] ?? profile?['name'] ?? userData?['name'] ?? '';
          final email = basic['email'] ?? profile?['email'] ?? userData?['email'] ?? '';
          final phone = basic['phone'] ?? profile?['phone'] ?? '';

          // For the returned 'uid' field we prefer the resolvedDocId (actual doc id) when available,
          // otherwise fall back to the last segment of origId (best-effort).
          final returnedUid = resolvedDocId.isNotEmpty ? resolvedDocId : _lastSegment(origId);

          candidateDetails.add({
            'uid': returnedUid,
            'orig_id': origId,
            'basic': basic,
            'display': {
              'name': displayName,
              'email': email,
              'phone': phone,
            },
            'profile': profile ?? {},
            'user_data': userData ?? {},
          });

          debugPrint('✅ candidate loaded: returnedUid=$returnedUid (orig="$origId") name="$displayName"');
        } catch (e, st) {
          debugPrint('⚠️ candidate processing failed for key=$key: $e\n$st');
        }
      }

      final result = <String, dynamic>{
        'request_doc': {'id': snap.id, 'data': data},
        'recruiter': {'id': recruiterId, 'data': recruiterInfo ?? {}},
        'candidates': candidateDetails,
      };

      loading = false;
      _safeNotify();
      return result;
    } catch (e, st) {
      debugPrint('❌ fetchRequestDetails error: $e\n$st');
      loading = false;
      _safeNotify();
      return null;
    }
  }

  /// Fetch recruiter info and cache it
  Future<Map<String, dynamic>?> _fetchRecruiterInfo(String recruiterId) async {
    if (recruiterId.isEmpty) return null;
    if (_recruiterCache.containsKey(recruiterId)) {
      debugPrint('💾 recruiter cache hit: $recruiterId');
      return _recruiterCache[recruiterId];
    }

    try {
      debugPrint('📥 fetching recruiter/$recruiterId');
      final snap = await _firestore
          .collection('recruiter')
          .doc(recruiterId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!snap.exists) {
        debugPrint('⚠️ recruiter/$recruiterId not found');
        return null;
      }

      final data = _normalizeMap(snap.data());

      Map<String, dynamic> userData = {};
      if (data.containsKey('user_data') && data['user_data'] != null) {
        userData = _normalizeMap(data['user_data']);
      } else {
        userData = {
          'name': data['name'] ?? data['displayName'] ?? '',
          'email': data['email'] ?? '',
          'company': data['company'] ?? data['org'] ?? '',
        };
      }

      _recruiterCache[recruiterId] = userData;
      debugPrint('✅ cached recruiter $recruiterId (name=${userData['name']})');
      return userData;
    } catch (e) {
      debugPrint('❌ _fetchRecruiterInfo error for $recruiterId: $e');
      return null;
    }
  }

  /// Fetch candidate profile and cache it (expects a real job_seeker doc id)
  Future<Map<String, dynamic>?> _fetchCandidateUserProfile(String uid) async {
    if (uid.isEmpty) return null;

    // Use the uid as stored in job_seeker doc id (not an email)
    if (_profileCache.containsKey(uid)) {
      debugPrint('💾 profile cache hit: $uid');
      return _profileCache[uid];
    }

    try {
      debugPrint('📥 fetching job_seeker/$uid (profile)');

      // Try parent doc first (embedded user_profile)
      final parentSnap = await _firestore
          .collection('job_seeker')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (parentSnap.exists) {
        final parentData = _normalizeMap(parentSnap.data());
        if (parentData.containsKey('user_profile') && parentData['user_profile'] != null) {
          final profile = _normalizeMap(parentData['user_profile']);
          _profileCache[uid] = profile;
          debugPrint('✅ profile loaded from parent doc for $uid');
          return profile;
        }

        // Some older docs may store profile at 'user_profile' differently; if not present,
        // attempt to use top-level fields to create a lightweight profile.
        final fallbackProfile = <String, dynamic>{
          'name': parentData['name'] ?? parentData['user_data'] != null ? _normalizeMap(parentData['user_data'])['name'] : null,
          'email': parentData['email'] ?? parentData['user_data'] != null ? _normalizeMap(parentData['user_data'])['email'] : null,
        };
        _profileCache[uid] = _normalizeMap(fallbackProfile);
        debugPrint('⚠️ profile not found in parent doc; using fallback for $uid');
        return _profileCache[uid];
      }

      // Fallback to subcollection path (older structure)
      debugPrint('🔎 fallback fetching job_seeker/$uid/user_profile/profile');
      final subSnap = await _firestore
          .doc('job_seeker/$uid/user_profile/profile')
          .get(const GetOptions(source: Source.serverAndCache));

      if (subSnap.exists) {
        final profile = _normalizeMap(subSnap.data());
        _profileCache[uid] = profile;
        debugPrint('✅ profile loaded from subcollection for $uid');
        return profile;
      }

      debugPrint('⚠️ no profile found for $uid');
      return null;
    } catch (e) {
      debugPrint('❌ _fetchCandidateUserProfile error for $uid: $e');
      return null;
    }
  }

  /// Update request status
  Future<bool> updateRequestStatus({
    required String requestId,
    required String newStatus,
    String? note,
    String? performedBy,
  }) async {
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
      debugPrint('✅ request $requestId status updated to $newStatus');

      final idx = requests.indexWhere(
              (r) => (r['id'] ?? r['request_doc_id']) == requestId
      );
      if (idx != -1) {
        requests[idx]['status'] = newStatus;
        requests[idx]['last_updated_at'] = DateTime.now();
        _safeNotify();
      } else {
        fetchAllRequests();
      }
      return true;
    } catch (e) {
      debugPrint('❌ updateRequestStatus error: $e');
      return false;
    }
  }

  /// Update candidate-specific status
  /// Note: candidateUid should be a real job_seeker doc id (the provider returns real uid in details).
  Future<bool> updateCandidateStatus({
    required String requestId,
    required String candidateUid,
    required String status,
    String? note,
    String? performedBy,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      final ref = _firestore.collection('recruiter_requests').doc(requestId);

      final key = 'candidate_statuses.$candidateUid';
      final batch = _firestore.batch();
      batch.update(ref, {
        key: status,
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
      debugPrint('✅ candidate $candidateUid status updated to $status');
      return true;
    } catch (e) {
      debugPrint('❌ updateCandidateStatus error: $e');
      return false;
    }
  }

  void clearCaches() {
    _recruiterCache.clear();
    _profileCache.clear();
    _emailToUidCache.clear();
    debugPrint('🧹 Admin caches cleared');
    _safeNotify();
  }

  Future<void> refresh() async {
    debugPrint('🔄 Admin manual refresh');
    clearCaches();
    await fetchAllRequests();
  }

  /// Helper method for UI: safely get a normalized map from dynamic data
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    _userLevelController.dispose();
    _disposed = true;
    _requestsSub?.cancel();
    _recruiterCache.clear();
    _profileCache.clear();
    _emailToUidCache.clear();
    debugPrint('🧹 AdminDashboardProvider disposed');
    super.dispose();
  }
}