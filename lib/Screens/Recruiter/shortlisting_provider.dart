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
  Map<String, dynamic>? matchScore; // ✅ ADD THIS LINE
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
    this.matchScore, // ✅ ADD THIS LINE
    this.profile,
    this.hideContact = true,
  });

  /// Build from the canonical `user_data` map (preferred)
  factory Candidate.fromUserData(String uid, Map<String, dynamic> userData, {bool hideContact = true, Map<String, dynamic>? matchScore}) {
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
      matchScore: matchScore, // ✅ ADD THIS LINE
      hideContact: hideContact,
    );
  }

  /// Legacy / fallback builder: data may be flat at doc root
  factory Candidate.fromMapFlat(String uid, Map<String, dynamic> data, {bool hideContact = true, Map<String, dynamic>? matchScore}) {
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
      matchScore: matchScore, // ✅ ADD THIS LINE
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
class Shortlisting_provider extends ChangeNotifier {
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

  // -- Job Filtering --
  String? selectedJobId;
  Set<String> availableJobIds = {};
  // Map to track which jobs a candidate is shortlisted for: UID -> Set<JobId>
  final Map<String, Set<String>> _candidateJobsMap = {};
// Map to store match scores: UID -> JobId -> MatchScore
  final Map<String, Map<String, Map<String, dynamic>>> _candidateMatchScores = {}; // ✅ ADD THIS LINE
  // Selections
  final Set<String> selectedUids = {};

  // Profile cache to avoid repeated reads
  final Map<String, Map<String, dynamic>> _profileCache = {};

  StreamSubscription<QuerySnapshot>? _subscription;

  /// Whether contact info should be hidden for the current viewer (recruiter).
  /// Default true (we hide email/phone and show masked versions)
  bool hideContactForViewer = true;

  Shortlisting_provider() {
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

  // ---------------------------------------------------------------------------
  // ✅ OPTIMIZED: Loads ONLY "Shortlist" Candidates via Collection Group Query
  // ---------------------------------------------------------------------------
  Future<void> subscribeCandidates() async {
    if (_isDisposed) return;
    loading = true;
    _safeNotify();

    // Cancel existing subscription if any
    _subscription?.cancel();

    try {
      debugPrint('📥 Listening for Shortlisted candidates...');

      // ⚡ Query for 'Shortlist' status across all applications
      // Path: applications/{userId}/applied_jobs/{docId}
      final query = _firestore
          .collectionGroup('applied_jobs')
          .where('status', isEqualTo: 'Shortlist');

      _subscription = query.snapshots().listen((snapshot) async {
        if (_isDisposed) return;

        debugPrint('📊 Received ${snapshot.docs.length} shortlist applications');

        final Set<String> uidsToFetch = {};
        _candidateJobsMap.clear();
        availableJobIds.clear();

        // 1. Collect UIDs and JobIDs from the applications
// 1. Collect UIDs, JobIDs, and Match Scores from the applications
        for (final doc in snapshot.docs) {
          try {
            // Get parent document reference (userId)
            final parentDoc = doc.reference.parent.parent;
            if (parentDoc == null) {
              debugPrint('⚠️ No parent for doc ${doc.id}');
              continue;
            }

            final uid = parentDoc.id;
            final data = doc.data();
            final jobId = (data['jobId'] ?? '').toString();

            debugPrint('✅ Found shortlist: UID=$uid, JobID=$jobId');

            if (uid.isNotEmpty) {
              uidsToFetch.add(uid);

              // Map Candidate -> Jobs
              if (!_candidateJobsMap.containsKey(uid)) {
                _candidateJobsMap[uid] = {};
              }
              if (jobId.isNotEmpty) {
                _candidateJobsMap[uid]!.add(jobId);
                availableJobIds.add(jobId);
              }

              // ✅ EXTRACT MATCH SCORE - ADD THIS BLOCK
              if (data['match_score'] is Map) {
                if (!_candidateMatchScores.containsKey(uid)) {
                  _candidateMatchScores[uid] = {};
                }
                _candidateMatchScores[uid]![jobId] = Map<String, dynamic>.from(data['match_score']);
                debugPrint('📊 Match score for $uid in job $jobId: ${data['match_score']}');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error processing application doc: $e');
          }
        }
        debugPrint('📌 Total unique UIDs to fetch: ${uidsToFetch.length}');

        if (uidsToFetch.isEmpty) {
          _candidates = [];
          _populateOptions();
          _applyFilter();
          loading = false;
          debugPrint('⚠️ No shortlisted candidates found');
          _safeNotify();
          return;
        }

        // 2. Fetch Profiles for these UIDs (Chunked for performance)
        final List<Candidate> list = await _fetchProfilesInChunks(uidsToFetch.toList());

        _candidates = list;
        _populateOptions();
        _applyFilter();

        loading = false;
        debugPrint('✅ Loaded ${_candidates.length} shortlisted candidates.');
        _safeNotify();
      }, onError: (error) {
        debugPrint('❌ Stream error: $error');
        _candidates = [];
        loading = false;
        _safeNotify();
      });

    } catch (e) {
      debugPrint('❌ subscribeCandidates error: $e');
      _candidates = [];
      loading = false;
      _safeNotify();
    }
  }

  // ⚡ Helper: Fetches profiles in batches of 10 (Firestore 'whereIn' limit)
  Future<List<Candidate>> _fetchProfilesInChunks(List<String> uids) async {
    final List<Candidate> results = [];
    // Deduplicate UIDs
    final uniqueUids = uids.toSet().toList();

    debugPrint('🔄 Fetching profiles for ${uniqueUids.length} candidates...');

    // Process in chunks of 10
    for (var i = 0; i < uniqueUids.length; i += 10) {
      final end = (i + 10 < uniqueUids.length) ? i + 10 : uniqueUids.length;
      final batch = uniqueUids.sublist(i, end);

      if (batch.isEmpty) continue;

      try {
        debugPrint('🔍 Fetching batch ${i ~/ 10 + 1}: ${batch.length} profiles');

        // Fetch users where FieldPath.documentId is in the batch
        final q = await _firestore
            .collection('job_seeker')
            .where(FieldPath.documentId, whereIn: batch)
            .get(const GetOptions(source: Source.serverAndCache));

        debugPrint('📥 Got ${q.docs.length} documents from job_seeker collection');

        for (final doc in q.docs) {
          final data = doc.data();
          final uid = doc.id;

          // ✅ Get match score for this candidate (use first job's score if multiple)
          Map<String, dynamic>? matchScore;
          if (_candidateMatchScores.containsKey(uid)) {
            final scores = _candidateMatchScores[uid]!;
            if (scores.isNotEmpty) {
              matchScore = scores.values.first; // Use first job's score
            }
          }

          // Re-use existing parsing logic
          if (data.containsKey('user_data') && data['user_data'] is Map<String, dynamic>) {
            final userData = Map<String, dynamic>.from(data['user_data'] as Map);
            if (_hasMinimumCandidateInfo(userData)) {
              results.add(Candidate.fromUserData(uid, userData, hideContact: hideContactForViewer, matchScore: matchScore)); // ✅ PASS matchScore
              debugPrint('✅ Added candidate: ${userData['personalProfile']?['name'] ?? 'Unknown'} with score: $matchScore');
              continue;
            }
          }
          if (_hasMinimumCandidateInfo(data)) {
            results.add(Candidate.fromMapFlat(uid, data, hideContact: hideContactForViewer, matchScore: matchScore)); // ✅ PASS matchScore
            debugPrint('✅ Added candidate (flat): ${data['name'] ?? 'Unknown'} with score: $matchScore');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching batch profiles: $e');
      }
    }

    debugPrint('✅ Successfully fetched ${results.length} candidate profiles');
    return results;
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
  }

  // ---------------------------------------------------------------------------
  // Filter Logic Updated for Job ID
  // ---------------------------------------------------------------------------
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

  void setJobFilter(String? jobId) {
    selectedJobId = (jobId == null || jobId.isEmpty || jobId == 'All') ? null : jobId;
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

    // 1. Filter by Job ID (Shortlisted for this specific job)
    if (selectedJobId != null) {
      tmp = tmp.where((c) {
        final candidateJobs = _candidateJobsMap[c.uid];
        return candidateJobs != null && candidateJobs.contains(selectedJobId);
      }).toList();
    }

    // 2. Search Query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      tmp = tmp.where((c) {
        final searchable = '${c.name} ${c.email} ${c.phone} ${c.nationality}'.toLowerCase();
        return searchable.contains(q);
      }).toList();
    }

    // 3. Nationality
    if (selectedNationality != null && selectedNationality!.isNotEmpty) {
      tmp = tmp.where((c) => c.nationality.trim().toLowerCase() == selectedNationality!.trim().toLowerCase()).toList();
    }

    // 4. Sort
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

      Map<String, dynamic> userData = {};
      if (raw.containsKey('user_data') && raw['user_data'] is Map<String, dynamic>) {
        userData = Map<String, dynamic>.from(raw['user_data'] as Map<String, dynamic>);
      } else {
        userData = Map<String, dynamic>.from(raw);
      }

      // Normalize documents
      final docsObj = userData['documents']
          ?? userData['documentsList']
          ?? userData['documentsArray']
          ?? userData['docuemnts']
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

      // Normalize arrays
      userData['professionalExperience'] = _ensureListOfMaps(userData['professionalExperience'] ?? userData['experiences'] ?? userData['experience'] ?? userData['work_experience']);
      userData['educationalProfile'] = _ensureListOfMaps(userData['educationalProfile'] ?? userData['education'] ?? userData['educations'] ?? userData['qualifications']);
      userData['certifications'] = _ensureCertifications(userData['certifications'] ?? userData['certs'] ?? userData['training']);
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
      debugPrint('❌ Error fetching profile for $uid: $e');
      return null;
    }
  }

  List<Map<String, String>> _ensureCertifications(dynamic v) {
    final out = <Map<String, String>>[];

    if (v is List) {
      for (final e in v) {
        if (e is Map) {
          out.add({
            'organization': (e['organization'] ?? '').toString(),
            'name': (e['name'] ?? e['certName'] ?? '').toString(),
          });
        } else if (e is String && e.isNotEmpty) {
          out.add({
            'organization': '',
            'name': e,
          });
        }
      }
    } else if (v is String && v.isNotEmpty) {
      out.add({
        'organization': '',
        'name': v,
      });
    }

    return out.where((cert) => cert['name']!.isNotEmpty).toList();
  }

  List<String> _ensureListOfStrings(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) return [v];
    return [];
  }

  List<Map<String, dynamic>> _ensureListOfMaps(dynamic v) {
    final out = <Map<String, dynamic>>[];
    if (v is List) {
      for (final e in v) {
        if (e is Map) {
          final mapped = Map<String, dynamic>.from(e);
          final result = {
            'organization': mapped['organization'] ?? mapped['company'] ?? '',
            'duration': mapped['duration'] ?? '',
            'role': mapped['role'] ?? mapped['title'] ?? mapped['position'] ?? '',
            'duties': mapped['duties'] ?? mapped['description'] ?? mapped['text'] ?? '',
            'text': mapped['text'] ?? mapped['duties'] ?? '',
          };
          out.add(result);
        } else {
          out.add({'text': e?.toString() ?? ''});
        }
      }
    } else if (v is Map) {
      for (final val in v.values) {
        if (val is Map) {
          final mapped = Map<String, dynamic>.from(val);
          out.add({
            'organization': mapped['organization'] ?? mapped['company'] ?? '',
            'duration': mapped['duration'] ?? '',
            'role': mapped['role'] ?? '',
            'duties': mapped['duties'] ?? mapped['text'] ?? '',
            'text': mapped['text'] ?? mapped['duties'] ?? '',
          });
        } else {
          out.add({'text': val?.toString() ?? ''});
        }
      }
    } else if (v != null) {
      out.add({'text': v.toString()});
    }
    return out;
  }

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
    } else if (value == false) {
      selectedUids.remove(uid);
    } else {
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
    searchQuery = '';
    selectedNationality = null;
    sortOption = 'None';
    selectedJobId = null;
    _applyFilter();
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