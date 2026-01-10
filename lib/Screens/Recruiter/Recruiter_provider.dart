// recruiter_dashboard_provider.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Candidate model mapped from /job_seeker/{uid}/user_data (or legacy)
class Candidate {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final String nationality;
  final String pictureUrl;
  Map<String, dynamic>? profile;

  /// When true, contact info should be hidden (recruiter view)
  final bool hideContact;

  Candidate({
    required this.uid,
    required this.email,
    required this.name,
    required this.phone,
    required this.nationality,
    required this.pictureUrl,
    this.profile,
    this.hideContact = true,
  });

  /// Build from the canonical `user_data` map (preferred)
  factory Candidate.fromUserData(String uid, Map<String, dynamic> userData, {bool hideContact = true}) {
    final personal = (userData['personalProfile'] is Map) ? Map<String, dynamic>.from(userData['personalProfile'] as Map) : userData;
    final name = (personal['name'] ?? personal['fullName'] ?? '') as String;
    final email = (personal['email'] ?? personal['secondary_email'] ?? '') as String;
    final phone = (personal['contactNumber'] ?? personal['phone'] ?? personal['phone number'] ?? '') as String;
    final nationality = (personal['nationality'] ?? '') as String;
    final pictureUrl = (personal['profilePicUrl'] ?? personal['pictureUrl'] ?? personal['picture'] ?? '') as String;

    return Candidate(
      uid: uid,
      email: email,
      name: name,
      phone: phone,
      nationality: nationality,
      pictureUrl: pictureUrl,
      profile: userData,
      hideContact: hideContact,
    );
  }

  /// Legacy / fallback builder: data may be flat at doc root
  factory Candidate.fromMapFlat(String uid, Map<String, dynamic> data, {bool hideContact = true}) {
    final name = (data['name'] ?? data['fullName'] ?? '') as String;
    final email = (data['email'] ?? '') as String;
    final phone = (data['phone'] ?? data['phone number'] ?? data['contactNumber'] ?? '') as String;
    final nationality = (data['nationality'] ?? '') as String;
    final pictureUrl = (data['pictureUrl'] ?? data['picture_url'] ?? data['profilePicUrl'] ?? '') as String;

    return Candidate(
      uid: uid,
      email: email,
      name: name,
      phone: phone,
      nationality: nationality,
      pictureUrl: pictureUrl,
      profile: data,
      hideContact: hideContact,
    );
  }

  String get nameLower => name.toLowerCase().trim();

  String get displayEmail {
    if (!hideContact) return email;
    if (email.isEmpty) return '****';
    final parts = email.split('@');
    if (parts.length != 2) return '****';
    final local = parts[0];
    final shownLocal = local.length <= 1 ? '*' : '${local[0]}${'*' * (maxLocalShown(local.length) - 1)}';
    return '$shownLocal@****';
  }

  String get displayPhone {
    if (!hideContact) return phone;
    if (phone.isEmpty) return '****';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 2) return '****';
    final last = digits.substring(digits.length - 2);
    return '****$last';
  }

  int maxLocalShown(int len) => (len <= 2) ? 1 : 2;
}

/// Provider used in recruiter dashboard
class RecruiterProvider2 extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // All loaded candidates (unfiltered)
  List<Candidate> _candidates = [];
  List<Candidate> get candidates => List.unmodifiable(_candidates);

  // Filtered and sorted list
  List<Candidate> _filtered = [];
  List<Candidate> get filtered => List.unmodifiable(_filtered);

  // UI state
  bool loading = false;
  bool _isDisposed = false;
  String searchQuery = '';

  // Filters & sort
  Set<String> nationalityOptions = {};
  String? selectedNationality;
  String sortOption = 'None'; // 'None','Name A→Z','Name Z→A'

  // Selections
  final Set<String> selectedUids = {};

  // Profile cache to avoid repeated reads
  final Map<String, Map<String, dynamic>> _profileCache = {};

  StreamSubscription<QuerySnapshot>? _subscription;

  /// Whether contact info should be hidden for the current viewer (recruiter).
  /// Default true (we hide email/phone and show masked versions)
  bool hideContactForViewer = true;

  RecruiterProvider2() {
    _init();
  }

  Future<void> _init() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ RecruiterProvider: no authenticated user');
      return;
    }
    await subscribeCandidates();
  }

  /// Loads candidates from /job_seeker collection.
  Future<void> subscribeCandidates() async {
    if (_isDisposed) return;
    loading = true;
    _safeNotify();

    try {
      debugPrint('📥 Loading candidates from job_seeker collection...');
      final snap = await _firestore.collection('job_seeker').get(const GetOptions(source: Source.serverAndCache));
      final List<Candidate> list = [];
      int valid = 0;
      int skipped = 0;

      for (final doc in snap.docs) {
        try {
          final data = doc.data();
          final uid = doc.id;

          if (data.containsKey('user_data') && data['user_data'] is Map<String, dynamic>) {
            final userData = Map<String, dynamic>.from(data['user_data'] as Map);
            if (_hasMinimumCandidateInfo(userData)) {
              list.add(Candidate.fromUserData(uid, userData, hideContact: hideContactForViewer));
              valid++;
              continue;
            }
          }

          if (_hasMinimumCandidateInfo(data)) {
            list.add(Candidate.fromMapFlat(uid, data, hideContact: hideContactForViewer));
            valid++;
            continue;
          }

          skipped++;
        } catch (e) {
          debugPrint('⚠️ Error parsing doc ${doc.id}: $e');
          skipped++;
        }
      }

      _candidates = list;
      debugPrint('✅ Candidates loaded: $valid (skipped $skipped)');
    } catch (e) {
      debugPrint('❌ subscribeCandidates error: $e');
      _candidates = [];
    }

    _populateOptions();
    _applyFilter();
    loading = false;
    _safeNotify();
  }

  bool _hasMinimumCandidateInfo(Map<String, dynamic> m) {
    final personal = (m['personalProfile'] is Map) ? m['personalProfile'] as Map<String, dynamic> : m;
    return (personal['email'] != null && (personal['email'] as String).toString().isNotEmpty) ||
        (personal['name'] != null && (personal['name'] as String).toString().isNotEmpty) ||
        (personal['contactNumber'] != null && (personal['contactNumber'] as String).toString().isNotEmpty) ||
        (personal['phone'] != null && (personal['phone'] as String).toString().isNotEmpty);
  }

  void _populateOptions() {
    nationalityOptions = _candidates.map((c) => c.nationality.trim()).where((s) => s.isNotEmpty).toSet();
    debugPrint('📊 nationality options: ${nationalityOptions.length}');
  }

  void setSearch(String q) {
    searchQuery = q.trim();
    _applyFilter();
    _safeNotify();
  }

  void setNationalityFilter(String? nat) {
    selectedNationality = (nat == null || nat.isEmpty) ? null : nat;
    _applyFilter();
    _safeNotify();
  }

  void setSortOption(String opt) {
    sortOption = opt;
    _applyFilter();
    _safeNotify();
  }

  void _applyFilter() {
    List<Candidate> tmp = List.from(_candidates);

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      tmp = tmp.where((c) {
        final searchable = '${c.name} ${c.email} ${c.phone} ${c.nationality}'.toLowerCase();
        return searchable.contains(q);
      }).toList();
    }

    if (selectedNationality != null && selectedNationality!.isNotEmpty) {
      tmp = tmp.where((c) => c.nationality.trim().toLowerCase() == selectedNationality!.trim().toLowerCase()).toList();
    }

    if (sortOption == 'Name A→Z') {
      tmp.sort((a, b) => a.nameLower.compareTo(b.nameLower));
    } else if (sortOption == 'Name Z→A') {
      tmp.sort((a, b) => b.nameLower.compareTo(a.nameLower));
    }

    _filtered = tmp;
    debugPrint('🔎 Filtered -> ${_filtered.length} candidates');
  }

  /// Fetch full profile from /job_seeker/{uid}/user_data (preferred) or fallback to other shapes
  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    if (_profileCache.containsKey(uid)) return _profileCache[uid];

    try {
      final docSnap = await _firestore.collection('job_seeker').doc(uid).get(const GetOptions(source: Source.serverAndCache));
      if (!docSnap.exists) return null;
      final raw = docSnap.data() ?? {};

      // pick canonical user_data if present
      Map<String, dynamic> userData = {};
      if (raw.containsKey('user_data') && raw['user_data'] is Map<String, dynamic>) {
        userData = Map<String, dynamic>.from(raw['user_data'] as Map<String, dynamic>);
      } else {
        userData = Map<String, dynamic>.from(raw);
      }

      // Normalize documents -> include possible misspelling 'docuemnts' and many aliases
      final docsObj = userData['documents']
          ?? userData['documentsList']
          ?? userData['documentsArray']
          ?? userData['docuemnts'] // handle backend typo
          ?? userData['docs']
          ?? userData['files'];
      List<Map<String, dynamic>> docsNormalized = [];
      if (docsObj is List) {
        for (final e in docsObj) {
          if (e is Map) {
            docsNormalized.add(Map<String, dynamic>.from(e));
          } else {
            docsNormalized.add({'name': e?.toString() ?? ''});
          }
        }
      } else if (docsObj is Map) {
        for (final v in docsObj.values) {
          if (v is Map) {
            docsNormalized.add(Map<String, dynamic>.from(v));
          } else {
            docsNormalized.add({'name': v?.toString() ?? ''});
          }
        }
      }
      userData['documents'] = docsNormalized;

      // Normalize experience, education arrays
      userData['professionalExperience'] = _ensureListOfMaps(userData['professionalExperience'] ?? userData['experiences'] ?? userData['experience'] ?? userData['work_experience']);
      userData['educationalProfile'] = _ensureListOfMaps(userData['educationalProfile'] ?? userData['education'] ?? userData['educations'] ?? userData['qualifications']);
      userData['certifications'] = _ensureListOfStrings(userData['certifications'] ?? userData['certs'] ?? userData['training']);
      userData['publications'] = _ensureListOfStrings(userData['publications'] ?? userData['papers']);
      userData['awards'] = _ensureListOfStrings(userData['awards'] ?? userData['honors']);
      userData['references'] = _ensureListOfStrings(userData['references'] ?? userData['refs']);

      _profileCache[uid] = userData;
      final idx = _candidates.indexWhere((c) => c.uid == uid);
      if (idx != -1) {
        _candidates[idx].profile = userData;
      }
      _safeNotify();
      return userData;
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> _ensureListOfMaps(dynamic v) {
    final out = <Map<String, dynamic>>[];
    if (v is List) {
      for (final e in v) {
        if (e is Map) {
          out.add(Map<String, dynamic>.from(e));
        } else {
          out.add({'text': e?.toString() ?? ''});
        }
      }
    } else if (v is Map) {
      for (final val in v.values) {
        if (val is Map) {
          out.add(Map<String, dynamic>.from(val));
        } else {
          out.add({'text': val?.toString() ?? ''});
        }
      }
    } else if (v != null) {
      out.add({'text': v.toString()});
    }
    return out;
  }

  List<String> _ensureListOfStrings(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) return [v];
    return [];
  }

  /// Extract a CV/Resume URL from normalized profile -> looks in documents[] for url-like fields
  String? getCvUrlFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    if (profile['documents'] is List) {
      for (final d in (profile['documents'] as List)) {
        if (d is Map) {
          final urlCandidates = ['url', 'link', 'cv_url', 'resume_url', 'downloadUrl', 'fileUrl', 'storageUrl'];
          for (final k in urlCandidates) {
            if (d.containsKey(k) && d[k] is String && (d[k] as String).isNotEmpty) {
              return d[k] as String;
            }
          }
        }
      }
    }
    final keys = ['cv', 'cv_url', 'resume', 'resume_url', 'cvUrl', 'resumeUrl'];
    for (final k in keys) {
      if (profile.containsKey(k) && profile[k] is String && (profile[k] as String).isNotEmpty) {
        return profile[k] as String;
      }
    }
    return null;
  }

  void toggleSelection(String uid, {bool? value}) {
    if (value == true) {
      selectedUids.add(uid);
    } else if (value == false) selectedUids.remove(uid);
    else {
      if (selectedUids.contains(uid)) {
        selectedUids.remove(uid);
      } else {
        selectedUids.add(uid);
      }
    }
    debugPrint('✅ selected count: ${selectedUids.length}');
    _safeNotify();
  }

  void clearSelection() {
    selectedUids.clear();
    _safeNotify();
  }

  String? _extractCvUrlFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    const candidates = [
      'Cv/Resume','cv','cv_url','resume','resume_url','cvLink','resumeLink','cv_link','resume_link',
      'cvUrl','resumeUrl','CV','Resume'
    ];
    for (final k in candidates) {
      if (profile.containsKey(k) && profile[k] is String && (profile[k] as String).isNotEmpty) {
        return profile[k] as String;
      }
    }
    if (profile['documents'] is Map<String, dynamic>) {
      final docs = profile['documents'] as Map<String, dynamic>;
      for (final k in candidates) {
        if (docs.containsKey(k) && docs[k] is String && (docs[k] as String).isNotEmpty) {
          return docs[k] as String;
        }
      }
    }
    return null;
  }

  Future<String?> sendSelectedCandidatesToAdmin({String? notes}) async {
    if (selectedUids.isEmpty) {
      debugPrint('⚠️ no candidates selected');
      return null;
    }

    final recruiter = _auth.currentUser;
    if (recruiter == null) {
      debugPrint('❌ no authenticated recruiter');
      return null;
    }

    final selected = _candidates.where((c) => selectedUids.contains(c.uid)).toList();
    if (selected.isEmpty) {
      debugPrint('⚠️ selected UIDs not found');
      return null;
    }

    final List<String> candidateIds = [];
    final List<Map<String, dynamic>> candidateMaps = [];

    for (final c in selected) {
      try {
        Map<String, dynamic>? prof = c.profile ?? await fetchProfile(c.uid);
        final cvUrl = _extractCvUrlFromProfile(prof) ?? '';
        candidateIds.add(c.uid);
        candidateMaps.add({
          'uid': c.uid,
          'name': c.name,
          'email': c.email,
          'phone': c.phone,
          'nationality': c.nationality,
          'picture_url': c.pictureUrl,
          'cv_url': cvUrl,
        });
      } catch (e) {
        debugPrint('⚠️ preparing candidate ${c.uid}: $e');
      }
    }

    if (candidateIds.isEmpty) {
      debugPrint('⚠️ no candidate ready after processing');
      return null;
    }

    try {
      final now = FieldValue.serverTimestamp();
      final requestsCol = _firestore.collection('recruiter_requests');
      final requestDoc = requestsCol.doc();
      final requestData = <String, dynamic>{
        'request_id': requestDoc.id,
        'recruiter_id': recruiter.uid,
        'recruiter_email': recruiter.email ?? '',
        'created_at': now,
        'notes': (notes ?? '').trim(),
        'total_candidates': candidateIds.length,
        'status': 'pending',
        'candidate_ids': candidateIds,
        'candidates': candidateMaps,
      };

      await requestDoc.set(requestData);
      clearSelection();
      debugPrint('✅ created request ${requestDoc.id}');
      return requestDoc.id;
    } catch (e) {
      debugPrint('❌ sendSelectedCandidatesToAdmin error: $e');
      return null;
    }
  }

  Future<void> refresh() async {
    _profileCache.clear();
    await subscribeCandidates();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    _profileCache.clear();
    super.dispose();
  }
}
