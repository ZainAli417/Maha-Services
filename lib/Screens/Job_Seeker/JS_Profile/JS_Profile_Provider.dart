// profile_provider.dart - OPTIMIZED VERSION
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileProvider_NEW extends ChangeNotifier {
  // Firestore collection/document
  final String role = 'job_seeker';
  String uid = '';

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoading = true;
  String errorMessage = '';

  // Debug
  Map<String, dynamic>? lastFetchedRaw;
  String lastDebug = '';

  // PERSONAL (public fields used by UI)
  String name = '';
  String email = '';
  String secondaryEmail = '';
  String contactNumber = '';
  String nationality = '';
  String profilePicUrl = '';
  List<String> skillsList = [];
  String objectives = '';
  List<String> socialLinks = [];
  String personalSummary = '';
  String dob = '';

  // EDUCATION temps + list
  String tempSchool = '';
  String tempDegree = '';
  String tempFieldOfStudy = '';
  String tempEduStart = '';
  String tempEduEnd = '';
  List<Map<String, dynamic>> educationalProfile = [];

  // PROFESSIONAL PROFILE
  String professionalProfileSummary = '';

  // PROFESSIONAL EXPERIENCE temps + list
  String tempCompany = '';
  String tempRole = '';
  String tempExpStart = '';
  String tempExpEnd = '';
  String tempExpDescription = '';
  List<Map<String, dynamic>> professionalExperience = [];
  String tempCertName = '';
  String tempCertInstitution = '';
  String tempCertYear = '';

  // CERTIFICATIONS / PUBLICATIONS / AWARDS / REFERENCES
  List<String> certifications = [];
  List<String> publications = [];
  List<String> awards = [];
  List<String> references = [];

  // DOCUMENTS: list of {name, url, contentType, uploadedAt}
  List<Map<String, dynamic>> documents = [];

  // controllers used by UI
  final TextEditingController skillController = TextEditingController();

  // Dirty flags
  bool personalDirty = false;
  bool educationDirty = false;
  bool professionalProfileDirty = false;
  bool experienceDirty = false;
  bool certificationsDirty = false;
  bool publicationsDirty = false;
  bool awardsDirty = false;
  bool referencesDirty = false;
  bool documentsDirty = false;

  // OPTIMIZATION: Cache for Firestore instances
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;
  DocumentReference? _cachedDocRef;

  // OPTIMIZATION: Debounce timer for batch updates
  Timer? _saveDebounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  // OPTIMIZATION: Prevent duplicate network calls
  bool _isFetching = false;
  Completer<void>? _fetchCompleter;

  ProfileProvider_NEW() {
    // Initialize Firebase instances once
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
    _init();
  }

  // ---------------- init / load ----------------
  Future<void> _init() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        isLoading = false;
        errorMessage = 'Not authenticated';
        notifyListeners();
        return;
      }
      uid = user.uid;
      _cachedDocRef = _firestore.collection(role).doc(uid);
      await loadAll();
    } catch (e) {
      _handleError('Initialization failed', e);
    }
  }

  /// OPTIMIZATION: Cached document reference
  DocumentReference get _docRef {
    _cachedDocRef ??= _firestore.collection(role).doc(uid);
    return _cachedDocRef!;
  }

  /// Public alias used in some UI files
  Future<void> loadAllSectionsOnce() => loadAll();

  /// OPTIMIZATION: Prevent concurrent fetches
  Future<void> loadAll() async {
    // If already fetching, return existing operation
    if (_isFetching && _fetchCompleter != null) {
      return _fetchCompleter!.future;
    }

    _isFetching = true;
    _fetchCompleter = Completer<void>();

    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      if (uid.isEmpty) {
        lastDebug = '[loadAll] uid empty';
        isLoading = false;
        notifyListeners();
        _fetchCompleter!.complete();
        return;
      }

      // OPTIMIZATION: Use cached reference and get with timeout
      final snap = await _docRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Database fetch timed out'),
      );

      if (!snap.exists) {
        lastDebug = '[loadAll] doc not exists - clearing';
        _clearLocal();
        isLoading = false;
        notifyListeners();
        _fetchCompleter!.complete();
        return;
      }

      // OPTIMIZATION: Direct cast without intermediate Map
      lastFetchedRaw = snap.data() as Map<String, dynamic>?;
      if (lastFetchedRaw == null) {
        _clearLocal();
        isLoading = false;
        notifyListeners();
        _fetchCompleter!.complete();
        return;
      }

      print('[ProfileProvider_NEW] top-level keys: ${lastFetchedRaw!.keys.toList()}');

      // prefer user_data
      Map<String, dynamic> data = lastFetchedRaw!;
      String branch = 'top-level';

      if (data.containsKey('user_data') && data['user_data'] is Map) {
        data = data['user_data'] as Map<String, dynamic>;
        branch = 'user_data';
      } else if (data.containsKey('userData') && data['userData'] is Map) {
        data = data['userData'] as Map<String, dynamic>;
        branch = 'userData';
      }

      lastDebug = '[loadAll] using branch: $branch; keys: ${data.keys.toList()}';
      print(lastDebug);

      // OPTIMIZATION: Batch all parsing operations
      _parseAndSetData(data);

      // reset temps & flags
      _clearTemps();
      _resetAllDirtyFlags();

      isLoading = false;
      notifyListeners();
      _fetchCompleter!.complete();
    } catch (e, st) {
      _handleError('Failed to load profile data', e, st);
      _fetchCompleter!.completeError(e);
    } finally {
      _isFetching = false;
      _fetchCompleter = null;
    }
  }

  /// OPTIMIZATION: Batch data parsing to reduce redundant operations
  void _parseAndSetData(Map<String, dynamic> data) {
    // personal
    final personal = data['personalProfile'] ?? data['personal_profile'] ?? {};
    if (personal is Map) {
      final p = personal as Map<String, dynamic>;
      name = _getString(p, ['name', 'fullName']);
      email = _getString(p, ['email']);
      secondaryEmail = _getString(p, ['secondary_email', 'secondaryEmail']);
      contactNumber = _getString(p, ['contactNumber', 'contact_number']);
      nationality = _getString(p, ['nationality']);
      profilePicUrl = _getString(p, ['profilePicUrl', 'pic_url']);
      objectives = _getString(p, ['objectives']);
      personalSummary = _getString(p, ['summary']);
      dob = _getString(p, ['dob']);
      socialLinks = _toStringList(p['socialLinks'] ?? p['social_links']);
      skillsList = _toStringList(p['skills'] ?? p['skillset']);
    }

    // rest sections
    educationalProfile = _mapListOfMap(data['educationalProfile'] ?? data['educational_profile']);

    final profProfile = data['professionalProfile'] ?? data['professional_profile'];
    professionalProfileSummary = profProfile is Map ? _getString(profProfile as Map<String, dynamic>, ['summary']) : '';

    professionalExperience = _mapListOfMap(data['professionalExperience'] ?? data['professional_experience']);
    certifications = _mapListStrings(data['certifications']);
    publications = _mapListStrings(data['publications']);
    awards = _mapListStrings(data['awards']);
    references = _mapListStrings(data['references']);
    documents = _mapListOfMap(data['documents']);
  }

  /// OPTIMIZATION: Generic string getter with fallback keys
  String _getString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) return value.toString();
    }
    return '';
  }

  /// Force reload alias used by UI
  Future<void> forceReload() async {
    _isFetching = false; // Reset fetch lock for force reload
    _fetchCompleter = null;
    await loadAll();
  }

  // ---------------- mapping helpers ----------------
  List<Map<String, dynamic>> _mapListOfMap(dynamic v) {
    if (v is! List) return [];
    try {
      return v.map((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      print('[_mapListOfMap] ERROR: $e');
      return [];
    }
  }

  List<String> _mapListStrings(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }

  List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    if (v is String) {
      return v.split(RegExp(r'[,;\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  // ---------------- getters expected by UI ----------------
  List<String> get skills => skillsList;
  String get professionalSummary => professionalProfileSummary;

  set professionalSummary(String v) {
    professionalProfileSummary = v;
    professionalProfileDirty = true;
    notifyListeners();
  }

  String get debugInfo {
    return 'uid:$uid isLoading:$isLoading error:$errorMessage\nlastDebug:$lastDebug\nname:$name email:$email skills:${skillsList.length} edu:${educationalProfile.length}';
  }

  // ---------------- Update helpers (UI-friendly names) ----------------
  void updateName(String v) { name = v; personalDirty = true; notifyListeners(); }
  void updateEmail(String v) { email = v; personalDirty = true; notifyListeners(); }
  void updateSecondaryEmail(String v) { secondaryEmail = v; personalDirty = true; notifyListeners(); }
  void updateContactNumber(String v) { contactNumber = v; personalDirty = true; notifyListeners(); }
  void updateNationality(String v) { nationality = v; personalDirty = true; notifyListeners(); }
  void updateObjectives(String v) { objectives = v; personalDirty = true; notifyListeners(); }
  void updatePersonalSummary(String v) { personalSummary = v; personalDirty = true; notifyListeners(); }
  void updateDob(String v) { dob = v; personalDirty = true; notifyListeners(); }

  void updateTempSchool(String v) { tempSchool = v; notifyListeners(); }
  void updateTempDegree(String v) { tempDegree = v; notifyListeners(); }
  void updateTempFieldOfStudy(String v) { tempFieldOfStudy = v; notifyListeners(); }
  void updateTempEduStart(String v) { tempEduStart = v; notifyListeners(); }
  void updateTempEduEnd(String v) { tempEduEnd = v; notifyListeners(); }

  void updateTempCompany(String v) { tempCompany = v; notifyListeners(); }
  void updateTempRole(String v) { tempRole = v; notifyListeners(); }
  void updateTempExpStart(String v) { tempExpStart = v; notifyListeners(); }
  void updateTempExpEnd(String v) { tempExpEnd = v; notifyListeners(); }
  void updateTempExpDescription(String v) { tempExpDescription = v; notifyListeners(); }

  void updateTempCertName(String v) { tempCertName = v; notifyListeners(); }
  void updateTempCertInstitution(String v) { tempCertInstitution = v; notifyListeners(); }
  void updateTempCertYear(String v) { tempCertYear = v; notifyListeners(); }

  // ---------------- Dirty markers ----------------
  void markPersonalDirty() { personalDirty = true; notifyListeners(); }
  void markEducationDirty() { educationDirty = true; notifyListeners(); }
  void markExperienceDirty() { experienceDirty = true; notifyListeners(); }
  void markCertificationsDirty() { certificationsDirty = true; notifyListeners(); }
  void markPublicationsDirty() { publicationsDirty = true; notifyListeners(); }
  void markAwardsDirty() { awardsDirty = true; notifyListeners(); }
  void markReferencesDirty() { referencesDirty = true; notifyListeners(); }

  /// OPTIMIZATION: Reset all dirty flags in one operation
  void _resetAllDirtyFlags() {
    personalDirty = educationDirty = professionalProfileDirty = experienceDirty =
        certificationsDirty = publicationsDirty = awardsDirty = referencesDirty = documentsDirty = false;
  }

  Color getButtonColorForSection(String section) {
    switch (section) {
      case 'personal': return personalDirty ? Colors.red : Colors.green;
      case 'education': return educationDirty ? Colors.red : Colors.green;
      case 'experience': return experienceDirty ? Colors.red : Colors.green;
      case 'certifications': return certificationsDirty ? Colors.red : Colors.green;
      case 'publications': return publicationsDirty ? Colors.red : Colors.green;
      case 'awards': return awardsDirty ? Colors.red : Colors.green;
      case 'references': return referencesDirty ? Colors.red : Colors.green;
      default: return Colors.blue;
    }
  }

  // ---------------- Add / Remove helpers used by UI ----------------
  // Education
  void addEducation(Map<String, dynamic> entry) {
    educationalProfile.add(entry);
    educationDirty = true;
    notifyListeners();
  }

  void addEducationEntry(BuildContext ctx) {
    if (tempSchool.trim().isEmpty && tempDegree.trim().isEmpty) {
      _showSnackBar(ctx, 'Please enter institution or degree');
      return;
    }
    educationalProfile.add({
      'institutionName': tempSchool.trim(),
      'duration': tempEduStart.trim() + (tempEduEnd.trim().isNotEmpty ? ' - ${tempEduEnd.trim()}' : ''),
      'majorSubjects': tempFieldOfStudy.trim(),
      'marksOrCgpa': tempDegree.trim(),
      'eduStart': tempEduStart.trim(),
      'eduEnd': tempEduEnd.trim(),
    });
    _clearTempEdu();
    educationDirty = true;
    notifyListeners();
  }

  void updateEducationAt(int idx, Map<String, dynamic> entry) {
    if (_isValidIndex(idx, educationalProfile.length)) {
      educationalProfile[idx] = entry;
      educationDirty = true;
      notifyListeners();
    }
  }

  void removeEducationAt(int idx) {
    if (_isValidIndex(idx, educationalProfile.length)) {
      educationalProfile.removeAt(idx);
      educationDirty = true;
      notifyListeners();
    }
  }

  // Experience
  void addExperience(Map<String, dynamic> entry) {
    professionalExperience.add(entry);
    experienceDirty = true;
    notifyListeners();
  }

  void addExperienceEntry(BuildContext ctx) {
    if (tempCompany.trim().isEmpty && tempExpDescription.trim().isEmpty) {
      _showSnackBar(ctx, 'Enter experience before adding');
      return;
    }
    professionalExperience.add({
      'company': tempCompany.trim(),
      'role': tempRole.trim(),
      'expStart': tempExpStart.trim(),
      'expEnd': tempExpEnd.trim(),
      'text': tempExpDescription.trim(),
    });
    _clearTempExp();
    experienceDirty = true;
    notifyListeners();
  }

  void updateExperienceAt(int idx, Map<String, dynamic> entry) {
    if (_isValidIndex(idx, professionalExperience.length)) {
      professionalExperience[idx] = entry;
      experienceDirty = true;
      notifyListeners();
    }
  }

  void removeExperienceAt(int idx) {
    if (_isValidIndex(idx, professionalExperience.length)) {
      professionalExperience.removeAt(idx);
      experienceDirty = true;
      notifyListeners();
    }
  }

  // Certifications
  void addCertification(String v) {
    if (v.trim().isEmpty) return;
    certifications.add(v.trim());
    certificationsDirty = true;
    notifyListeners();
  }

  void addCertificationEntry(BuildContext ctx) {
    if (tempCertName.trim().isEmpty) {
      _showSnackBar(ctx, 'Enter certification name');
      return;
    }
    certifications.add(tempCertName.trim());
    _clearTempCert();
    certificationsDirty = true;
    notifyListeners();
  }

  void removeCertificationAt(int idx) {
    if (_isValidIndex(idx, certifications.length)) {
      certifications.removeAt(idx);
      certificationsDirty = true;
      notifyListeners();
    }
  }

  // Publications
  void addPublication(String v) {
    if (v.trim().isEmpty) return;
    publications.add(v.trim());
    publicationsDirty = true;
    notifyListeners();
  }

  void removePublicationAt(int idx) {
    if (_isValidIndex(idx, publications.length)) {
      publications.removeAt(idx);
      publicationsDirty = true;
      notifyListeners();
    }
  }

  // Awards
  void addAward(String v) {
    if (v.trim().isEmpty) return;
    awards.add(v.trim());
    awardsDirty = true;
    notifyListeners();
  }

  void removeAwardAt(int idx) {
    if (_isValidIndex(idx, awards.length)) {
      awards.removeAt(idx);
      awardsDirty = true;
      notifyListeners();
    }
  }

  // References
  void addReference(String v) {
    if (v.trim().isEmpty) return;
    references.add(v.trim());
    referencesDirty = true;
    notifyListeners();
  }

  void removeReferenceAt(int idx) {
    if (_isValidIndex(idx, references.length)) {
      references.removeAt(idx);
      referencesDirty = true;
      notifyListeners();
    }
  }

  // Skills helpers
  void addSkill(String s) {
    final v = s.trim();
    if (v.isEmpty || skillsList.contains(v)) return;
    skillsList.add(v);
    skillController.clear();
    personalDirty = true;
    notifyListeners();
  }

  void addSkillEntry(BuildContext ctx) {
    final val = skillController.text.trim();
    if (val.isEmpty) return;
    if (!skillsList.contains(val)) {
      skillsList.add(val);
      skillController.clear();
      personalDirty = true;
      notifyListeners();
    } else {
      _showSnackBar(ctx, 'Skill already exists');
    }
  }

  void removeSkillAt(int idx) {
    if (_isValidIndex(idx, skillsList.length)) {
      skillsList.removeAt(idx);
      personalDirty = true;
      notifyListeners();
    }
  }

  void removeSkill(String skill) {
    if (skillsList.remove(skill)) {
      personalDirty = true;
      notifyListeners();
    }
  }

  void updateSkillAt(int idx, String v) {
    if (_isValidIndex(idx, skillsList.length)) {
      skillsList[idx] = v.trim();
      personalDirty = true;
      notifyListeners();
    }
  }

  // Documents
  void addDocumentEntry(Map<String, dynamic> entry) {
    documents.add(entry);
    documentsDirty = true;
    notifyListeners();
  }

  void removeDocumentAt(int idx) {
    if (_isValidIndex(idx, documents.length)) {
      documents.removeAt(idx);
      documentsDirty = true;
      notifyListeners();
    }
  }

  // ---------------- OPTIMIZATION: Helper methods ----------------

  /// Check if index is valid
  bool _isValidIndex(int idx, int length) => idx >= 0 && idx < length;

  /// Centralized snackbar display
  void _showSnackBar(BuildContext ctx, String message) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Centralized error handler
  void _handleError(String context, dynamic error, [StackTrace? stackTrace]) {
    errorMessage = '$context: ${error.toString()}';
    lastDebug = '[ERROR] $context: $error${stackTrace != null ? '\n$stackTrace' : ''}';
    print(lastDebug);
    isLoading = false;
    notifyListeners();
  }

  // ---------------- Save methods (section-aware) ----------------

  Future<void> savePersonal() async => savePersonalSectionSilent();

  Future<void> savePersonalSection(BuildContext ctx) async {
    await _executeSave(
      ctx,
          () => savePersonalSectionSilent(),
          () => personalDirty = false,
      'Personal saved',
    );
  }

  Future<void> saveEducation() async => _writeSection({'educationalProfile': educationalProfile});

  Future<void> saveEducationSection(BuildContext ctx) async {
    await _executeSave(
      ctx,
          () => saveEducation(),
          () => educationDirty = false,
      'Education saved',
    );
  }

  Future<void> saveProfessionalProfile() async => _writeSection({
    'professionalProfile': {'summary': professionalProfileSummary}
  });

  Future<void> saveProfessionalProfileSection(BuildContext ctx) async {
    await _executeSave(
      ctx,
          () => saveProfessionalProfile(),
          () => professionalProfileDirty = false,
      'Professional profile saved',
    );
  }

  Future<void> saveExperience() async => _writeSection({
    'professionalExperience': professionalExperience
  });

  Future<void> saveExperienceSection(BuildContext ctx) async {
    await _executeSave(
      ctx,
          () => saveExperience(),
          () => experienceDirty = false,
      'Experience saved',
    );
  }

  Future<void> saveCertifications() async => _writeSection({'certifications': certifications});

  Future<void> saveCertificationsSection(BuildContext ctx) async {
    await _executeSave(
      ctx,
          () => saveCertifications(),
          () => certificationsDirty = false,
      'Certifications saved',
    );
  }

  Future<void> savePublications() async => _writeSection({'publications': publications});

  Future<void> savePublicationsSection(BuildContext ctx) async {
    await _executeSave(
      ctx,
          () => savePublications(),
          () => publicationsDirty = false,
      'Publications saved',
    );
  }

  Future<void> saveAwards() async => _writeSection({'awards': awards});

  Future<void> saveAwardsSection(BuildContext ctx) async {
    await _executeSave(
      ctx,
          () => saveAwards(),
          () => awardsDirty = false,
      'Awards saved',
    );
  }

  Future<void> saveReferences() async => _writeSection({'references': references});

  Future<void> saveReferencesSection(BuildContext ctx) async {
    await _executeSave(
      ctx,
          () => saveReferences(),
          () => referencesDirty = false,
      'References saved',
    );
  }

  Future<void> saveDocumentsSection(BuildContext ctx) async {
    await _executeSave(
      ctx,
          () => saveDocumentsList(),
          () => documentsDirty = false,
      'Documents saved',
    );
  }

  /// OPTIMIZATION: Generic save executor with error handling
  Future<void> _executeSave(
      BuildContext ctx,
      Future<void> Function() saveFunc,
      void Function() onSuccess,
      String successMessage,
      ) async {
    isLoading = true;
    notifyListeners();

    try {
      await saveFunc().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Save operation timed out'),
      );
      onSuccess();
      _showSnackBar(ctx, successMessage);
    } catch (e) {
      _showSnackBar(ctx, 'Save failed: ${e.toString()}');
      _handleError('Save operation failed', e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> savePersonalSectionSilent() async {
    final payload = {
      'personalProfile': {
        'name': name.trim(),
        'email': email.trim(),
        'secondary_email': secondaryEmail.trim(),
        'contactNumber': contactNumber.trim(),
        'nationality': nationality.trim(),
        'profilePicUrl': profilePicUrl.trim(),
        'skills': skillsList,
        'objectives': objectives.trim(),
        'socialLinks': socialLinks,
        'summary': personalSummary.trim(),
        'dob': dob.trim(),
      }
    };
    await _sectionAwareWrite(payload);
    personalDirty = false;
    notifyListeners();
  }

  /// OPTIMIZATION: Streamlined write with cached reference and single check
  Future<void> _writeSection(Map<String, dynamic> payload) async {
    try {
      final snap = await _docRef.get().timeout(const Duration(seconds: 10));

      if (snap.exists) {
        final raw = snap.data();
        if (raw is Map && (raw.containsKey('user_data') || raw.containsKey('userData'))) {
          await _docRef.set({'user_data': payload}, SetOptions(merge: true));
          return;
        }
      }

      await _docRef.set(payload, SetOptions(merge: true));
    } catch (e, st) {
      _handleError('Write section failed', e, st);
      rethrow;
    }
  }

  /// lower-level writer used by savePersonalSectionSilent
  Future<void> _sectionAwareWrite(Map<String, dynamic> payload) async {
    await _writeSection(payload);
  }

  // ---------------- Storage helpers ----------------

  Future<void> uploadProfilePicture(
      Uint8List bytes,
      String filename,
      {String? mimeType}
      ) async {
    if (uid.isEmpty) return;

    isLoading = true;
    notifyListeners();

    try {
      final ref = _storage.ref().child('users/$uid/profile/$filename');
      final metadata = SettableMetadata(contentType: mimeType ?? 'image/jpeg');

      final task = await ref.putData(bytes, metadata).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Upload timed out'),
      );

      final url = await task.ref.getDownloadURL();
      profilePicUrl = url;
      await savePersonalSectionSilent();
      print('[uploadProfilePicture] -> $url');
    } catch (e, st) {
      _handleError('Profile picture upload failed', e, st);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// OPTIMIZATION: Streamlined sanitization
  List<Map<String, dynamic>> _sanitizeDocumentsForSave(List<Map<String, dynamic>> src) {
    return src.map((doc) {
      final copied = Map<String, dynamic>.from(doc);
      final uploadedAt = copied['uploadedAt'];

      if (uploadedAt is Timestamp) {
        // Already valid
      } else if (uploadedAt is DateTime) {
        copied['uploadedAt'] = Timestamp.fromDate(uploadedAt);
      } else if (uploadedAt is int) {
        copied['uploadedAt'] = Timestamp.fromMillisecondsSinceEpoch(uploadedAt);
      } else if (uploadedAt is String) {
        try {
          copied['uploadedAt'] = Timestamp.fromDate(DateTime.parse(uploadedAt));
        } catch (_) {
          copied['uploadedAt'] = Timestamp.now();
        }
      } else {
        copied['uploadedAt'] = Timestamp.now();
      }

      return copied;
    }).toList();
  }

  /// Save documents list (sanitized)
  Future<void> saveDocumentsList() async {
    isLoading = true;
    notifyListeners();

    try {
      final sanitized = _sanitizeDocumentsForSave(documents);
      await _writeSection({'documents': sanitized});
      documentsDirty = false;
      notifyListeners();
    } catch (e, st) {
      _handleError('Save documents failed', e, st);
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// OPTIMIZATION: Upload with better error handling and timeout
  Future<Map<String, dynamic>?> uploadDocument(
      Uint8List bytes,
      String filename,
      {String? mimeType}
      ) async {
    if (uid.isEmpty) return null;

    isLoading = true;
    notifyListeners();

    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final storageRef = _storage.ref().child('users/$uid/documents/${ts}_$filename');
      final metadata = SettableMetadata(contentType: mimeType ?? 'application/octet-stream');

      final uploadTask = await storageRef.putData(bytes, metadata).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException('Document upload timed out'),
      );

      final url = await uploadTask.ref.getDownloadURL();

      final entry = <String, dynamic>{
        'name': filename,
        'url': url,
        'contentType': metadata.contentType ?? '',
        'uploadedAt': Timestamp.now(),
      };

      documents.add(entry);
      await saveDocumentsList();
      print('[uploadDocument] -> $url');
      return entry;
    } catch (e, st) {
      _handleError('Document upload failed', e, st);
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- Clear helpers ----------------

  void _clearTemps() {
    _clearTempEdu();
    _clearTempExp();
    _clearTempCert();
  }

  void _clearTempEdu() {
    tempSchool = '';
    tempDegree = '';
    tempFieldOfStudy = '';
    tempEduStart = '';
    tempEduEnd = '';
  }

  void _clearTempExp() {
    tempCompany = '';
    tempRole = '';
    tempExpStart = '';
    tempExpEnd = '';
    tempExpDescription = '';
  }

  void _clearTempCert() {
    tempCertName = '';
    tempCertInstitution = '';
    tempCertYear = '';
  }

  void _clearLocal() {
    name = '';
    email = '';
    secondaryEmail = '';
    contactNumber = '';
    nationality = '';
    profilePicUrl = '';
    skillsList = [];
    objectives = '';
    socialLinks = [];
    personalSummary = '';
    dob = '';

    educationalProfile = [];
    professionalProfileSummary = '';
    professionalExperience = [];
    certifications = [];
    publications = [];
    awards = [];
    references = [];
    documents = [];

    _resetAllDirtyFlags();
  }

  // Convenience getter
  String get fullName {
    final parts = [name.trim()];
    return parts.where((s) => s.isNotEmpty).join(' ');
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    skillController.dispose();
    super.dispose();
  }
}