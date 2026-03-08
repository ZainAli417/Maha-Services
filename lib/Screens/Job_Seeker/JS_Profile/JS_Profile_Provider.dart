import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileProvider_NEW extends ChangeNotifier {
  // ---------------- Configuration ----------------
  final String role = 'Job_Seeker';

  // OPTIMIZATION: Cache Validity Duration
  static const Duration _cacheValidity = Duration(minutes: 5);
  DateTime? _lastFetchTime;

  // ---------------- Core Services ----------------
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;

  // ---------------- State Variables ----------------
  String uid = '';
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoading = true;
  String errorMessage = '';

  // Internal flag to track if this user uses the nested 'user_data' schema
  // This prevents us from reading the DB before every write.
  bool _usesNestedUserData = false;

  // Debug
  Map<String, dynamic>? lastFetchedRaw;
  String lastDebug = '';

  // ---------------- Data Models ----------------
  // PROFESSIONAL EXPERIENCE
  String tempCompany = '';
  String tempRole = '';
  String tempExpStart = '';
  String tempExpEnd = '';
  String tempExpDescription = '';

  // Air Force specific fields
  String tempRank = '';
  String tempUnit = '';
  String tempLocation = '';
  String tempCommand = '';
  String tempAircraftType = '';
  String tempFlightHours = '';

  List<Map<String, dynamic>> professionalExperience = [];
  List<Map<String, dynamic>> experienceDocuments = [];

  // CERTIFICATIONS
  String tempCertName = '';
  String tempCertInstitution = '';
  String tempCertYear = '';
  List<Map<String, String>> certifications = [];
  List<Map<String, dynamic>> certificationDocuments = [];

  // PERSONAL
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

  // EDUCATION
  String tempSchool = '';
  String tempDegree = '';
  String tempFieldOfStudy = '';
  String tempEduStart = '';
  String tempEduEnd = '';
  List<Map<String, dynamic>> educationalProfile = [];

  // PROFESSIONAL PROFILE / RECORD
  String professionalProfileSummary = '';
  String professionalStatus = '';
  String expectedRetirementDate = '';
  String retirementDate = '';

  // LISTS
  List<String> publications = [];
  List<String> awards = [];
  List<String> references = [];
  List<Map<String, dynamic>> documents = [];

  // ---------------- Controllers ----------------
  final TextEditingController skillController = TextEditingController();

  // ---------------- Dirty Flags ----------------
  bool personalDirty = false;
  bool educationDirty = false;
  bool professionalProfileDirty = false;
  bool experienceDirty = false;
  bool certificationsDirty = false;
  bool publicationsDirty = false;
  bool awardsDirty = false;
  bool referencesDirty = false;
  bool documentsDirty = false;

  // ---------------- Internals for Optimization ----------------
  DocumentReference? _cachedDocRef;

  // Prevents concurrent fetches
  bool _isFetching = false;
  Completer<void>? _fetchCompleter;

  // Prevents 'notifyListeners' call on disposed provider
  bool _isDisposed = false;

  ProfileProvider_NEW() {
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
    _init();
  }

  // ---------------- Initialization ----------------
  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isLoading = false;
      errorMessage = 'Not authenticated';
      _safeNotifyListeners();
      return;
    }
    uid = user.uid;
    // Pre-calculate doc ref
    _cachedDocRef = _firestore.collection(role).doc(uid);
    await loadAll();
  }

  DocumentReference get _docRef {
    _cachedDocRef ??= _firestore.collection(role).doc(uid);
    return _cachedDocRef!;
  }

  // ---------------- Data Loading (Optimized) ----------------

  /// Public alias
  Future<void> loadAllSectionsOnce() => loadAll();

  Future<void> forceReload() async {
    _lastFetchTime = null; // Invalidate cache
    await loadAll();
  }

  Future<void> loadAll() async {
    // 1. Concurrency Lock: Return existing future if already loading
    if (_isFetching && _fetchCompleter != null) {
      return _fetchCompleter!.future;
    }

    // 2. Cache Check: If data is fresh (< 5 mins), skip network call
    if (_lastFetchTime != null && DateTime.now().difference(_lastFetchTime!) < _cacheValidity) {
      lastDebug = '[loadAll] Using cached data';
      return;
    }

    _isFetching = true;
    _fetchCompleter = Completer<void>();
    isLoading = true;
    errorMessage = '';
    _safeNotifyListeners();

    try {
      if (uid.isEmpty) throw Exception('UID is empty');

      // 3. Network Call with Timeout
      final snap = await _docRef.get().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Database fetch timed out'),
      );

      if (!snap.exists) {
        _clearLocal();
      } else {
        lastFetchedRaw = snap.data() as Map<String, dynamic>?;
        if (lastFetchedRaw != null) {
          _processRawData(lastFetchedRaw!);
        } else {
          _clearLocal();
        }
      }

      _lastFetchTime = DateTime.now(); // Update cache timestamp
      _clearTemps();
      _resetAllDirtyFlags();

      isLoading = false;
      _safeNotifyListeners();
      _fetchCompleter!.complete();

    } catch (e, st) {
      _handleError('Failed to load profile data', e, st);
      _fetchCompleter!.completeError(e);
    } finally {
      _isFetching = false;
      _fetchCompleter = null;
    }
  }

  void _processRawData(Map<String, dynamic> rawData) {
    Map<String, dynamic> data = rawData;

    // OPTIMIZATION: Detect Schema Structure Once
    if (rawData.containsKey('user_data') && rawData['user_data'] is Map) {
      data = rawData['user_data'] as Map<String, dynamic>;
      _usesNestedUserData = true;
    } else if (rawData.containsKey('userData') && rawData['userData'] is Map) {
      data = rawData['userData'] as Map<String, dynamic>;
      _usesNestedUserData = true;
    } else {
      _usesNestedUserData = false;
    }

    _parseAndSetData(data);
  }

  void _parseAndSetData(Map<String, dynamic> data) {
    // Personal
    final personal = data['personalProfile'] ?? data['personal_profile'] ?? {};
    if (personal is Map) {
      final p = Map<String, dynamic>.from(personal);
      name = _getString(p, ['name', 'fullName']);
      email = _getString(p, ['email']);
      secondaryEmail = _getString(p, ['secondary_email', 'secondaryEmail']);
      contactNumber = _getString(p, ['contactNumber', 'contact_number']);
      nationality = _getString(p, ['nationality']);
      profilePicUrl = _getString(p, ['profilePicUrl', 'pic_url']);
      objectives = _getString(p, ['objectives']);
      personalSummary = _getString(p, ['summary']);
      dob = _getString(p, ['dob']);

      // ✅ ADD THIS DEBUG LOG
      print('[LOAD DATA] DOB loaded from Firestore: "$dob"');

      socialLinks = _toStringList(p['socialLinks'] ?? p['social_links']);
      skillsList = _toStringList(p['skills'] ?? p['skillset']);
    }
    // Professional Profile
    final profProfile = data['professionalProfile'] ?? data['professional_profile'];
    if (profProfile is Map) {
      final prof = profProfile as Map<String, dynamic>;
      professionalProfileSummary = _getString(prof, ['summary']);
      professionalStatus = _getString(prof, ['status', 'professionalStatus']);
      expectedRetirementDate = _getString(prof, ['expectedRetirement', 'expectedRetirementDate']);
      retirementDate = _getString(prof, ['retirement', 'retirementDate']);
    }

    // Lists & Complex Objects
    professionalExperience = _mapListOfMap(data['professionalExperience'] ?? data['professional_experience'] ?? data['experiences']);
    experienceDocuments = _mapListOfMap(data['experienceDocuments'] ?? data['experience_documents']);

    educationalProfile = _mapListOfMap(data['educationalProfile'] ?? data['educational_profile']);

    certifications = _mapCertifications(data['certifications']);
    certificationDocuments = _mapListOfMap(data['certificationDocuments'] ?? data['certification_documents']);

    publications = _mapListStrings(data['publications']);
    awards = _mapListStrings(data['awards']);
    references = _mapListStrings(data['references']);
    documents = _mapListOfMap(data['documents']);
  }

  // ---------------- Save Logic (Optimized) ----------------

  /// OPTIMIZATION: Core Write Function
  /// Does NOT read from DB. Uses cached `_usesNestedUserData` flag.
  Future<void> _writeSection(Map<String, dynamic> payload) async {
    if (uid.isEmpty) {
      print('[_writeSection] ERROR: UID is empty!');
      return;
    }

    print('[_writeSection] Starting write...');
    print('[_writeSection] _usesNestedUserData: $_usesNestedUserData');

    try {
      Map<String, dynamic> finalPayload;

      if (_usesNestedUserData) {
        finalPayload = {'user_data': payload};
        print('[_writeSection] Wrapping in user_data structure');
      } else {
        finalPayload = payload;
        print('[_writeSection] Using flat structure');
      }

      print('[_writeSection] Final payload to Firestore: $finalPayload');

      await _docRef.set(finalPayload, SetOptions(merge: true)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Save operation timed out'),
      );

      print('[_writeSection] Firestore write successful');
      _lastFetchTime = DateTime.now();

    } catch (e, st) {
      print('[_writeSection] ERROR: $e');
      print('[_writeSection] Stack trace: $st');
      _handleError('Write failed', e, st);
      rethrow;
    }
  }
  /// Generic Execution Wrapper
  Future<void> _executeSave(
      BuildContext ctx,
      Future<void> Function() saveFunc,
      void Function() onSuccess,
      String successMessage,
      ) async {

    // Prevent UI locking by not setting isLoading=true for background saves
    // unless strictly necessary. Here we assume optimistic UI.

    try {
      await saveFunc();
      onSuccess();
      if (ctx.mounted) _showSnackBar(ctx, successMessage);
    } catch (e) {
      if (ctx.mounted) _showSnackBar(ctx, 'Save failed: ${e.toString()}');
    }
  }

  // --- Section Specific Savers ---

  Future<void> savePersonalSection(BuildContext ctx) async {
    print('═══════════════════════════════════════');
    print('[SAVE PERSONAL] Starting save...');
    print('[SAVE PERSONAL] Current DOB value: "$dob"');
    print('[SAVE PERSONAL] personalDirty: $personalDirty');

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

    print('[SAVE PERSONAL] Payload DOB: "${payload['personalProfile']!['dob']}"');
    print('[SAVE PERSONAL] Full payload: $payload');

    await _executeSave(ctx, () async {
      print('[SAVE PERSONAL] Calling _writeSection...');
      await _writeSection(payload);
      print('[SAVE PERSONAL] _writeSection completed');
    }, () {
      print('[SAVE PERSONAL] Save successful, clearing dirty flag');
      personalDirty = false;
      _safeNotifyListeners();
    }, 'Personal profile saved');

    print('[SAVE PERSONAL] Save operation completed');
    print('═══════════════════════════════════════');
  }
  Future<void> saveEducationSection(BuildContext ctx) async {
    await _executeSave(ctx, () => _writeSection({
      'educationalProfile': educationalProfile
    }), () {
      educationDirty = false;
      _safeNotifyListeners();
    }, 'Education saved');
  }

  Future<void> saveProfessionalProfileSection(BuildContext ctx) async {
    await _executeSave(ctx, () => _writeSection({
      'professionalProfile': {
        'summary': professionalProfileSummary,
        'status': professionalStatus,
        'expectedRetirementDate': expectedRetirementDate,
        'retirementDate': retirementDate,
      }
    }), () {
      professionalProfileDirty = false;
      _safeNotifyListeners();
    }, 'Professional profile saved');
  }

  Future<void> saveExperienceSection(BuildContext ctx) async {
    await _executeSave(ctx, () => _writeSection({
      'professionalExperience': professionalExperience,
      'experienceDocuments': experienceDocuments,
    }), () {
      experienceDirty = false;
      _safeNotifyListeners();
    }, 'Experience saved');
  }

  Future<void> saveCertificationsSection(BuildContext ctx) async {
    await _executeSave(ctx, () => _writeSection({
      'certifications': certifications,
      'certificationDocuments': certificationDocuments,
    }), () {
      certificationsDirty = false;
      _safeNotifyListeners();
    }, 'Certifications saved');
  }

  Future<void> savePublicationsSection(BuildContext ctx) async {
    await _executeSave(ctx, () => _writeSection({'publications': publications}),
            () => _markClean(() => publicationsDirty = false), 'Publications saved');
  }

  Future<void> saveAwardsSection(BuildContext ctx) async {
    await _executeSave(ctx, () => _writeSection({'awards': awards}),
            () => _markClean(() => awardsDirty = false), 'Awards saved');
  }

  Future<void> saveReferencesSection(BuildContext ctx) async {
    await _executeSave(ctx, () => _writeSection({'references': references}),
            () => _markClean(() => referencesDirty = false), 'References saved');
  }

  Future<void> saveDocumentsSection(BuildContext ctx) async {
    await _executeSave(ctx, () => saveDocumentsList(),
            () => _markClean(() => documentsDirty = false), 'Documents saved');
  }

  void _markClean(VoidCallback cleanAction) {
    cleanAction();
    _safeNotifyListeners();
  }

  // ---------------- File Uploads (Optimized) ----------------

  Future<Map<String, dynamic>?> _genericUpload(
      Uint8List bytes,
      String path,
      String filename,
      {String? mimeType}
      ) async {

    if (uid.isEmpty) return null;
    if (bytes.length > 5 * 1024 * 1024) {
      errorMessage = 'File size exceeds 5MB limit';
      _safeNotifyListeners();
      return null;
    }

    // Notify start
    // isLoading = true; // Optional: depends if you want full screen blocking
    // _safeNotifyListeners();

    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('users/$uid/$path/${ts}_$filename');
      final metadata = SettableMetadata(contentType: mimeType ?? 'application/octet-stream');

      final task = await ref.putData(bytes, metadata).timeout(
        const Duration(seconds: 90), // Generous timeout for uploads
        onTimeout: () => throw TimeoutException('Upload timed out'),
      );

      final url = await task.ref.getDownloadURL();

      return {
        'name': filename,
        'url': url,
        'contentType': metadata.contentType ?? '',
        'uploadedAt': Timestamp.now(),
      };
    } catch (e, st) {
      _handleError('Upload failed: $path', e, st);
      return null;
    }
    // finally {
    //   isLoading = false;
    //   _safeNotifyListeners();
    // }
  }

  Future<Map<String, dynamic>?> uploadDocument(Uint8List bytes, String filename, {String? mimeType}) async {
    isLoading = true;
    _safeNotifyListeners();
    final res = await _genericUpload(bytes, 'documents', filename, mimeType: mimeType);
    if (res != null) {
      documents.add(res);
      await saveDocumentsList();
    }
    isLoading = false;
    _safeNotifyListeners();
    return res;
  }

  Future<Map<String, dynamic>?> uploadExperienceDocument(Uint8List bytes, String filename, {String? mimeType}) async {
    final res = await _genericUpload(bytes, 'experience_docs', filename, mimeType: mimeType);
    if (res != null) {
      experienceDocuments.add(res);
      experienceDirty = true;
      _safeNotifyListeners();
    }
    return res;
  }

  Future<Map<String, dynamic>?> uploadCertificationDocument(Uint8List bytes, String filename, {String? mimeType}) async {
    final res = await _genericUpload(bytes, 'certification_docs', filename, mimeType: mimeType);
    if (res != null) {
      certificationDocuments.add(res);
      certificationsDirty = true;
      _safeNotifyListeners();
    }
    return res;
  }

  Future<void> uploadProfilePicture(Uint8List bytes, String filename, {String? mimeType}) async {
    isLoading = true;
    _safeNotifyListeners();
    final res = await _genericUpload(bytes, 'profile', filename, mimeType: mimeType ?? 'image/jpeg');
    if (res != null) {
      profilePicUrl = res['url'];
      await _writeSection({'personalProfile': {'profilePicUrl': profilePicUrl}});
    }
    isLoading = false;
    _safeNotifyListeners();
  }

  Future<void> saveDocumentsList() async {
    final sanitized = _sanitizeDocumentsForSave(documents);
    await _writeSection({'documents': sanitized});
  }

  // ---------------- UI Helpers ----------------

  void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    // Remove existing snackbars to prevent stacking
    // ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Optional based on preference

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 40,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, val, child) {
              return Opacity(
                opacity: val,
                child: Transform.translate(
                  offset: Offset(0, (1.0 - val) * -20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B), // Dark green
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 4), () => overlayEntry.remove());
  }

  // ---------------- Data Manipulation Helpers ----------------

  // Update Getters & Setters
  void updateName(String v) { name = v; personalDirty = true; _safeNotifyListeners(); }
  void updateEmail(String v) { email = v; personalDirty = true; _safeNotifyListeners(); }
  void updateSecondaryEmail(String v) { secondaryEmail = v; personalDirty = true; _safeNotifyListeners(); }
  void updateContactNumber(String v) { contactNumber = v; personalDirty = true; _safeNotifyListeners(); }
  void updateNationality(String v) { nationality = v; personalDirty = true; _safeNotifyListeners(); }
  void updateObjectives(String v) { objectives = v; personalDirty = true; _safeNotifyListeners(); }
  void updatePersonalSummary(String v) { personalSummary = v; personalDirty = true; _safeNotifyListeners(); }
  void updateDob(String v) {
    print('[updateDob] Called with value: "$v"');
    print('[updateDob] Previous dob: "$dob"');
    dob = v;
    personalDirty = true;
    print('[updateDob] New dob: "$dob", personalDirty: $personalDirty');
    _safeNotifyListeners();
  }
  // Professional Status Updates
  void updateProfessionalStatus(String v) { professionalStatus = v; professionalProfileDirty = true; _safeNotifyListeners(); }
  void updateExpectedRetirementDate(String v) { expectedRetirementDate = v; professionalProfileDirty = true; _safeNotifyListeners(); }
  void updateRetirementDate(String v) { retirementDate = v; professionalProfileDirty = true; _safeNotifyListeners(); }

  // Temp Updates (Only notify, no dirty flag)
  void updateTempSchool(String v) { tempSchool = v; _safeNotifyListeners(); }
  void updateTempDegree(String v) { tempDegree = v; _safeNotifyListeners(); }
  void updateTempFieldOfStudy(String v) { tempFieldOfStudy = v; _safeNotifyListeners(); }
  void updateTempEduStart(String v) { tempEduStart = v; _safeNotifyListeners(); }
  void updateTempEduEnd(String v) { tempEduEnd = v; _safeNotifyListeners(); }

  void updateTempCompany(String v) { tempCompany = v; _safeNotifyListeners(); }
  void updateTempRole(String v) { tempRole = v; _safeNotifyListeners(); }
  void updateTempExpStart(String v) { tempExpStart = v; _safeNotifyListeners(); }
  void updateTempExpEnd(String v) { tempExpEnd = v; _safeNotifyListeners(); }
  void updateTempExpDescription(String v) { tempExpDescription = v; _safeNotifyListeners(); }

  void updateTempCertName(String v) { tempCertName = v; _safeNotifyListeners(); }
  void updateTempCertInstitution(String v) { tempCertInstitution = v; _safeNotifyListeners(); }
  void updateTempCertYear(String v) { tempCertYear = v; _safeNotifyListeners(); }

  // List Management
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
    _safeNotifyListeners();
  }

  void removeEducationAt(int idx) {
    if (_isValidIndex(idx, educationalProfile.length)) {
      educationalProfile.removeAt(idx);
      educationDirty = true;
      _safeNotifyListeners();
    }
  }

  void addExperienceEntry(BuildContext ctx) {
    if (tempCompany.trim().isEmpty && tempExpDescription.trim().isEmpty) {
      _showSnackBar(ctx, 'Enter experience before adding');
      return;
    }
    professionalExperience.add({
      'organization': tempCompany.trim(),
      'role': tempRole.trim(),
      'duration': tempExpStart.trim() + (tempExpEnd.trim().isNotEmpty ? ' - ${tempExpEnd.trim()}' : ''),
      'duties': tempExpDescription.trim(),
      'startDate': tempExpStart.trim(),
      'endDate': tempExpEnd.trim(),
      'rank': tempRank.trim(),
      'location': tempLocation.trim(),
      'command': tempCommand.trim(),
      'aircraftType': tempAircraftType.trim(),
      'flightHours': tempFlightHours.trim(),
    });
    _clearTempExp();
    experienceDirty = true;
    _safeNotifyListeners();
  }

  void removeExperienceAt(int idx) {
    if (_isValidIndex(idx, professionalExperience.length)) {
      professionalExperience.removeAt(idx);
      experienceDirty = true;
      _safeNotifyListeners();
    }
  }

  void addCertificationEntry(BuildContext ctx) {
    if (tempCertName.trim().isEmpty) {
      _showSnackBar(ctx, 'Enter certification name');
      return;
    }
    certifications.add({
      'organization': tempCertInstitution.trim(),
      'name': tempCertName.trim(),
    });
    _clearTempCert();
    certificationsDirty = true;
    _safeNotifyListeners();
  }

  void removeCertificationAt(int idx) {
    if (_isValidIndex(idx, certifications.length)) {
      certifications.removeAt(idx);
      certificationsDirty = true;
      _safeNotifyListeners();
    }
  }

  // Simple Lists
  void addPublication(String v) { if(v.trim().isEmpty) return; publications.add(v.trim()); publicationsDirty = true; _safeNotifyListeners(); }
  void removePublicationAt(int idx) { if(_isValidIndex(idx, publications.length)) { publications.removeAt(idx); publicationsDirty = true; _safeNotifyListeners(); } }

  void addAward(String v) { if(v.trim().isEmpty) return; awards.add(v.trim()); awardsDirty = true; _safeNotifyListeners(); }
  void removeAwardAt(int idx) { if(_isValidIndex(idx, awards.length)) { awards.removeAt(idx); awardsDirty = true; _safeNotifyListeners(); } }

  void addReference(String v) { if(v.trim().isEmpty) return; references.add(v.trim()); referencesDirty = true; _safeNotifyListeners(); }
  void removeReferenceAt(int idx) { if(_isValidIndex(idx, references.length)) { references.removeAt(idx); referencesDirty = true; _safeNotifyListeners(); } }

  // Skills
  void addSkillEntry(BuildContext ctx) {
    final val = skillController.text.trim();
    if (val.isEmpty) return;
    if (!skillsList.contains(val)) {
      skillsList.add(val);
      skillController.clear();
      personalDirty = true;
      _safeNotifyListeners();
    } else {
      _showSnackBar(ctx, 'Skill already exists');
    }
  }

  void removeSkillAt(int idx) {
    if (_isValidIndex(idx, skillsList.length)) {
      skillsList.removeAt(idx);
      personalDirty = true;
      _safeNotifyListeners();
    }
  }

  // Document Lists
  void removeExperienceDocumentAt(int idx) {
    if (_isValidIndex(idx, experienceDocuments.length)) {
      experienceDocuments.removeAt(idx);
      experienceDirty = true;
      _safeNotifyListeners();
    }
  }

  void removeCertificationDocumentAt(int idx) {
    if (_isValidIndex(idx, certificationDocuments.length)) {
      certificationDocuments.removeAt(idx);
      certificationsDirty = true;
      _safeNotifyListeners();
    }
  }

  void removeDocumentAt(int idx) {
    if (_isValidIndex(idx, documents.length)) {
      documents.removeAt(idx);
      documentsDirty = true;
      _safeNotifyListeners();
    }
  }

  // ---------------- Utilities ----------------

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

  String get debugInfo => 'uid:$uid isLoading:$isLoading error:$errorMessage cached:${_lastFetchTime != null}';

  List<String> get skills => skillsList;
  String get professionalSummary => professionalProfileSummary;
  set professionalSummary(String v) {
    professionalProfileSummary = v;
    professionalProfileDirty = true;
    _safeNotifyListeners();
  }

  bool _isValidIndex(int idx, int length) => idx >= 0 && idx < length;

  String _getString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map[key] != null) return map[key].toString();
    }
    return '';
  }

  List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    if (v is String) return v.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return [];
  }

  List<Map<String, dynamic>> _mapListOfMap(dynamic v) {
    if (v is! List) return [];
    return v.fold<List<Map<String, dynamic>>>([], (prev, e) {
      if (e is Map) prev.add(Map<String, dynamic>.from(e));
      return prev;
    });
  }

  List<String> _mapListStrings(dynamic v) => _toStringList(v);

  List<Map<String, String>> _mapCertifications(dynamic v) {
    if (v is! List) return [];
    return v.map((item) {
      if (item is Map) {
        return {
          'organization': (item['organization'] ?? '').toString(),
          'name': (item['name'] ?? item['certName'] ?? '').toString(),
        };
      }
      if (item is String && item.isNotEmpty) {
        return {'organization': '', 'name': item};
      }
      return {'organization': '', 'name': ''};
    }).where((cert) => cert['name']!.isNotEmpty).toList();
  }

  List<Map<String, dynamic>> _sanitizeDocumentsForSave(List<Map<String, dynamic>> src) {
    return src.map((doc) {
      final copied = Map<String, dynamic>.from(doc);
      final uploadedAt = copied['uploadedAt'];
      if (uploadedAt is DateTime) copied['uploadedAt'] = Timestamp.fromDate(uploadedAt);
      else if (uploadedAt is int) copied['uploadedAt'] = Timestamp.fromMillisecondsSinceEpoch(uploadedAt);
      else if (uploadedAt is! Timestamp) copied['uploadedAt'] = Timestamp.now();
      return copied;
    }).toList();
  }

  void _handleError(String context, dynamic error, [StackTrace? stackTrace]) {
    errorMessage = '$context: $error';
    lastDebug = '[ERROR] $context: $error';
    print(lastDebug);
    isLoading = false;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  void _resetAllDirtyFlags() {
    personalDirty = educationDirty = professionalProfileDirty = experienceDirty =
        certificationsDirty = publicationsDirty = awardsDirty = referencesDirty = documentsDirty = false;
  }

  void _clearTemps() {
    _clearTempEdu();
    _clearTempExp();
    _clearTempCert();
  }

  void _clearTempEdu() {
    tempSchool = ''; tempDegree = ''; tempFieldOfStudy = ''; tempEduStart = ''; tempEduEnd = '';
  }

  void _clearTempExp() {
    tempCompany = ''; tempRole = ''; tempExpStart = ''; tempExpEnd = ''; tempExpDescription = '';
    tempRank = ''; tempUnit = ''; tempLocation = ''; tempCommand = ''; tempAircraftType = ''; tempFlightHours = '';
  }

  void _clearTempCert() {
    tempCertName = ''; tempCertInstitution = ''; tempCertYear = '';
  }

  void _clearLocal() {
    name = ''; email = ''; secondaryEmail = ''; contactNumber = ''; nationality = '';
    profilePicUrl = ''; skillsList = []; objectives = ''; socialLinks = [];
    personalSummary = ''; dob = ''; educationalProfile = [];
    professionalProfileSummary = ''; professionalExperience = [];
    certifications = []; publications = []; awards = []; references = []; documents = [];
    professionalStatus = ''; expectedRetirementDate = ''; retirementDate = '';
    experienceDocuments = []; certificationDocuments = [];
    _resetAllDirtyFlags();
  }

  @override
  void dispose() {
    _isDisposed = true;
    skillController.dispose();
    super.dispose();
  }
}