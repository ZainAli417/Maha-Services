import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/onboarding/candidate_profile_service.dart';
import '../../../core/onboarding/models/aviation_role.dart';
import '../../../core/onboarding/models/candidate_profile.dart';
import '../../../core/onboarding/models/question.dart';
import '../../../core/onboarding/profile_projector.dart';
import '../../../core/onboarding/role_template_service.dart';

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
  String professionalStatus = '';
  String expectedRetirementDate = '';

  /// The Personal and Professional panels each show a summary box. They were
  /// two stored fields saying the same thing, so they are now one: whichever
  /// box the candidate edits, the other reflects it.
  String get professionalProfileSummary => personalSummary;
  set professionalProfileSummary(String v) {
    personalSummary = v;
    professionalProfileDirty = true;
    _safeNotifyListeners();
  }

  /// "Expected retirement" (while serving) and "date of retirement" (once
  /// retired) are the same date under two labels — the form shows one or the
  /// other, never both.
  String get retirementDate => expectedRetirementDate;
  set retirementDate(String v) => expectedRetirementDate = v;

  // LISTS
  List<String> publications = [];
  List<String> awards = [];
  List<String> references = [];
  List<Map<String, dynamic>> documents = [];

  // ── The candidate document ───────────────────────────────────────────────
  /// The whole profile, and the only thing stored. Null until the first load
  /// completes or when the account has no profile yet; the flat fields above
  /// are a view of it, rebuilt by [_populateFrom] and folded back by
  /// [_composeProfile].
  CandidateProfile? candidateProfile;

  /// The template [candidateProfile.targetRole] points at, resolved from the
  /// live role-template config so admin edits show up without a release.
  RoleTemplate? roleTemplate;

  bool roleProfileSaving = false;

  final _templates = RoleTemplateService();
  final _candidateProfiles = CandidateProfileService();

  /// Section names of the active role template, in template order.
  List<String> get roleSections => roleTemplate?.sections ?? const [];

  bool get hasRoleProfile =>
      roleTemplate != null && candidateProfile != null;

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
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidity) {
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
    _parseRoleProfile(rawData);
    _populateFrom(candidateProfile);
  }

  void _parseRoleProfile(Map<String, dynamic> rawData) {
    candidateProfile = CandidateProfileService.parse(uid, rawData);
    if (candidateProfile == null) {
      roleTemplate = null;
      return;
    }
    // Resolving the template is a network read; do it without blocking the
    // rest of the parse and notify when it lands.
    unawaited(_resolveRoleTemplate());
  }

  Future<void> _resolveRoleTemplate() async {
    final roleId = candidateProfile?.targetRole.roleId;
    if (roleId == null || roleId.isEmpty) {
      roleTemplate = null;
      return;
    }
    try {
      roleTemplate = await _templates.roleById(roleId);
    } catch (e) {
      debugPrint('⚠️ ProfileProvider: could not resolve role template: $e');
      roleTemplate = null;
    }
    _safeNotifyListeners();
  }

  /// Visible questions in [section] for the active template, honouring the
  /// same conditional rules the onboarding form applies.
  List<OnboardingQuestion> visibleQuestionsIn(String section) {
    final template = roleTemplate;
    if (template == null) return const [];
    final answers = candidateProfile?.answers ?? const <String, dynamic>{};
    return template
        .questionsIn(section)
        .where((q) => _isVisible(q, answers))
        .toList();
  }

  static bool _isVisible(OnboardingQuestion q, Map<String, dynamic> answers) {
    final depId = q.dependsOnId;
    if (depId == null) return true;
    final dep = answers[depId];
    if (dep == null) return false;
    final values = q.dependsOnValues.isNotEmpty
        ? q.dependsOnValues
        : (q.dependsOnValue == null
            ? const <String>[]
            : <String>[q.dependsOnValue!]);
    if (values.isEmpty) return true;
    if (dep is List) {
      return dep.any((v) => values.contains(v.toString()));
    }
    return values.contains(dep.toString());
  }

  /// Persists edited template answers, re-projecting the structured sections
  /// so the profile, the timeline and recruiter search all stay in step.
  Future<bool> saveRoleAnswers(Map<String, dynamic> updated) async {
    final template = roleTemplate;
    final current = candidateProfile;
    if (template == null || current == null) return false;

    roleProfileSaving = true;
    _safeNotifyListeners();
    try {
      final answers = Map<String, dynamic>.from(current.answers)
        ..addAll(updated);
      // Explicit nulls mean "cleared", not "unchanged".
      updated.forEach((k, v) {
        if (v == null) answers.remove(k);
      });

      final projected = ProfileProjector.project(
        template,
        answers,
        base: current.personalInfo,
      );
      final next = current.copyWith(
        answers: answers,
        personalInfo: projected.personal,
        roleSpecificData: projected.roleData,
        // Template attachments are re-projected with the answers so replacing
        // a document here also updates the list the admin panel reads.
        documents: [
          ...ProfileProjector.documents(template, answers),
          ...current.documents
              .where((d) => d.category != DocumentCategory.general),
        ],
      );

      await _candidateProfiles.save(next);
      candidateProfile = next;
      // Re-fan the flat editor fields, or the next section save would compose
      // from a stale view and undo what was just written.
      _populateFrom(next);
      _lastFetchTime = null; // force a fresh read on the next load
      roleProfileSaving = false;
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('⚠️ saveRoleAnswers failed: $e');
      roleProfileSaving = false;
      errorMessage = 'Could not save: $e';
      _safeNotifyListeners();
      return false;
    }
  }

  /// Fans the profile out onto the flat fields the editor widgets bind to.
  ///
  /// The widgets stay string- and list-shaped because that is what text
  /// controllers and list editors want; [_persist] folds them back into a
  /// [CandidateProfile] on save, so the document on disk only ever has one
  /// shape.
  void _populateFrom(CandidateProfile? p) {
    if (p == null) {
      _clearLocal();
      return;
    }

    final personal = p.personalInfo;
    name = personal.fullName;
    email = personal.email;
    secondaryEmail = personal.secondaryEmail;
    contactNumber = personal.phone;
    nationality = personal.nationality;
    profilePicUrl = personal.profilePicUrl;
    objectives = personal.objectives;
    personalSummary = personal.summary;
    dob = personal.dateOfBirth;
    socialLinks = List<String>.from(personal.socialLinks);
    skillsList = List<String>.from(personal.skills);

    professionalStatus = p.professionalStatus;
    expectedRetirementDate = p.expectedRetirementDate;

    professionalExperience = [
      for (final x in p.experience)
        {
          'id': x.id,
          'organization': x.company,
          'role': x.title,
          'location': x.location,
          'startDate': x.startDate,
          'endDate': x.endDate ?? '',
          'isCurrent': x.isCurrent,
          'duties': x.responsibilities.join('\n'),
        },
    ];

    educationalProfile = [
      for (final e in p.education)
        {
          'id': e.id,
          'institutionName': e.institution,
          'degree': e.degree,
          'majorSubjects': e.fieldOfStudy,
          'duration': e.graduationYear?.toString() ?? '',
          'marksOrCgpa': e.grade,
        },
    ];

    certifications = [
      for (final c in p.certifications)
        {'name': c.name, 'organization': c.issuer},
    ];

    publications = List<String>.from(p.publications);
    awards = List<String>.from(p.awards);
    references = List<String>.from(p.references);

    documents = _docMaps(p, DocumentCategory.general);
    experienceDocuments = _docMaps(p, DocumentCategory.experience);
    certificationDocuments = _docMaps(p, DocumentCategory.certification);
  }

  static List<Map<String, dynamic>> _docMaps(
    CandidateProfile p,
    DocumentCategory category,
  ) =>
      [
        for (final d in p.documentsIn(category))
          {
            'name': d.name,
            'url': d.url,
            'contentType': d.contentType,
            if (d.uploadedAt != null)
              'uploadedAt': Timestamp.fromDate(d.uploadedAt!),
          },
      ];

  /// Folds the flat editor fields back into a [CandidateProfile].
  ///
  /// Built from [candidateProfile] so anything the editor does not surface —
  /// the raw template answers, the projected role data, the target role —
  /// survives a section save untouched.
  CandidateProfile _composeProfile() {
    final base = candidateProfile ?? CandidateProfile(uid: uid);

    return base.copyWith(
      personalInfo: base.personalInfo.copyWith(
        fullName: name.trim(),
        email: email.trim(),
        secondaryEmail: secondaryEmail.trim(),
        phone: contactNumber.trim(),
        nationality: nationality.trim(),
        profilePicUrl: profilePicUrl.trim(),
        objectives: objectives.trim(),
        summary: personalSummary.trim(),
        dateOfBirth: dob.trim(),
        socialLinks: socialLinks,
        skills: skillsList,
      ),
      professionalStatus: professionalStatus.trim(),
      expectedRetirementDate: expectedRetirementDate.trim(),
      experience: [
        for (final (i, e) in professionalExperience.indexed)
          ExperienceEntry(
            id: _entryId(e['id'], 'exp', i),
            title: _s(e['role']),
            company: _s(e['organization']),
            location: _s(e['location']),
            startDate: _s(e['startDate']),
            endDate: _s(e['endDate']),
            isCurrent: e['isCurrent'] == true,
            responsibilities: _toStringList(e['duties']),
          ),
      ],
      education: [
        for (final (i, e) in educationalProfile.indexed)
          EducationEntry(
            id: _entryId(e['id'], 'edu', i),
            institution: _s(e['institutionName']),
            degree: _s(e['degree']),
            fieldOfStudy: _s(e['majorSubjects']),
            graduationYear: _yearOf(e['duration']),
            grade: _s(e['marksOrCgpa']),
          ),
      ],
      certifications: [
        for (final (i, c) in certifications.indexed)
          CertificationEntry(
            id: _entryId(c['id'], 'cert', i),
            name: _s(c['name']),
            issuer: _s(c['organization']),
          ),
      ],
      publications: publications,
      awards: awards,
      references: references,
      documents: [
        ..._toDocuments(documents, DocumentCategory.general),
        ..._toDocuments(experienceDocuments, DocumentCategory.experience),
        ..._toDocuments(
            certificationDocuments, DocumentCategory.certification),
      ],
    );
  }

  static String _s(dynamic v) => v?.toString().trim() ?? '';

  /// Keeps an entry's existing id, or mints a stable one. Ids matter because
  /// the CV generator and the recruiter view key off them.
  static String _entryId(dynamic existing, String prefix, int index) {
    final id = _s(existing);
    return id.isEmpty ? '${prefix}_$index' : id;
  }

  static int? _yearOf(dynamic v) {
    final matches = RegExp(r'(19|20)\d{2}').allMatches(_s(v));
    return matches.isEmpty ? null : int.tryParse(matches.last.group(0)!);
  }

  static List<ProfileDocument> _toDocuments(
    List<Map<String, dynamic>> src,
    DocumentCategory category,
  ) =>
      [
        for (final d in src)
          if (_s(d['url']).isNotEmpty)
            ProfileDocument(
              name: _s(d['name']),
              url: _s(d['url']),
              contentType: _s(d['contentType'] ?? d['type']),
              category: category,
              uploadedAt: d['uploadedAt'] is Timestamp
                  ? (d['uploadedAt'] as Timestamp).toDate()
                  : DateTime.tryParse(_s(d['uploadedAt'])),
            ),
      ];

  // ---------------- Save Logic (Optimized) ----------------

  /// Writes the whole profile.
  ///
  /// Section savers used to send just their own slice, which meant the write
  /// path had to know how each slice nested. Composing the full profile and
  /// writing it once is both simpler and safer: Firestore replaces arrays
  /// wholesale on a merge, so a slice write was never the partial update it
  /// looked like.
  Future<void> _persist() async {
    if (uid.isEmpty) {
      debugPrint('[_persist] ERROR: UID is empty!');
      return;
    }

    try {
      final next = _composeProfile();
      await _candidateProfiles.save(next).timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Save operation timed out'),
          );
      candidateProfile = next;
      _lastFetchTime = DateTime.now();
    } catch (e, st) {
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
  //
  // Every one of these writes the whole profile — see [_persist]. They differ
  // only in which dirty flag they clear and what the confirmation says.

  Future<void> savePersonalSection(BuildContext ctx) => _saveSection(
        ctx,
        'Personal profile saved',
        () => personalDirty = false,
      );

  Future<void> saveEducationSection(BuildContext ctx) => _saveSection(
        ctx,
        'Education saved',
        () => educationDirty = false,
      );

  Future<void> saveProfessionalProfileSection(BuildContext ctx) => _saveSection(
        ctx,
        'Professional profile saved',
        () => professionalProfileDirty = false,
      );

  Future<void> saveExperienceSection(BuildContext ctx) => _saveSection(
        ctx,
        'Experience saved',
        () => experienceDirty = false,
      );

  Future<void> saveCertificationsSection(BuildContext ctx) => _saveSection(
        ctx,
        'Certifications saved',
        () => certificationsDirty = false,
      );

  Future<void> savePublicationsSection(BuildContext ctx) => _saveSection(
        ctx,
        'Publications saved',
        () => publicationsDirty = false,
      );

  Future<void> saveAwardsSection(BuildContext ctx) => _saveSection(
        ctx,
        'Awards saved',
        () => awardsDirty = false,
      );

  Future<void> saveReferencesSection(BuildContext ctx) => _saveSection(
        ctx,
        'References saved',
        () => referencesDirty = false,
      );

  Future<void> saveDocumentsSection(BuildContext ctx) => _saveSection(
        ctx,
        'Documents saved',
        () => documentsDirty = false,
      );

  Future<void> _saveSection(
    BuildContext ctx,
    String successMessage,
    VoidCallback markClean,
  ) =>
      _executeSave(ctx, _persist, () => _markClean(markClean), successMessage);

  void _markClean(VoidCallback cleanAction) {
    cleanAction();
    _safeNotifyListeners();
  }

  // ---------------- File Uploads (Optimized) ----------------

  Future<Map<String, dynamic>?> _genericUpload(
    Uint8List bytes,
    String path,
    String filename, {
    String? mimeType,
  }) async {
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
      final metadata = SettableMetadata(
        contentType: mimeType ?? 'application/octet-stream',
      );

      final task = await ref
          .putData(bytes, metadata)
          .timeout(
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

  Future<Map<String, dynamic>?> uploadDocument(
    Uint8List bytes,
    String filename, {
    String? mimeType,
  }) async {
    isLoading = true;
    _safeNotifyListeners();
    final res = await _genericUpload(
      bytes,
      'documents',
      filename,
      mimeType: mimeType,
    );
    if (res != null) {
      documents.add(res);
      await saveDocumentsList();
    }
    isLoading = false;
    _safeNotifyListeners();
    return res;
  }

  Future<Map<String, dynamic>?> uploadExperienceDocument(
    Uint8List bytes,
    String filename, {
    String? mimeType,
  }) async {
    final res = await _genericUpload(
      bytes,
      'experience_docs',
      filename,
      mimeType: mimeType,
    );
    if (res != null) {
      experienceDocuments.add(res);
      experienceDirty = true;
      _safeNotifyListeners();
    }
    return res;
  }

  Future<Map<String, dynamic>?> uploadCertificationDocument(
    Uint8List bytes,
    String filename, {
    String? mimeType,
  }) async {
    final res = await _genericUpload(
      bytes,
      'certification_docs',
      filename,
      mimeType: mimeType,
    );
    if (res != null) {
      certificationDocuments.add(res);
      certificationsDirty = true;
      _safeNotifyListeners();
    }
    return res;
  }

  Future<void> uploadProfilePicture(
    Uint8List bytes,
    String filename, {
    String? mimeType,
  }) async {
    isLoading = true;
    _safeNotifyListeners();
    final res = await _genericUpload(
      bytes,
      'profile',
      filename,
      mimeType: mimeType ?? 'image/jpeg',
    );
    if (res != null) {
      profilePicUrl = res['url'];
      await _persist();
    }
    isLoading = false;
    _safeNotifyListeners();
  }

  Future<void> saveDocumentsList() => _persist();

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B), // Dark green
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white,
                            ),
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
  void updateName(String v) {
    name = v;
    personalDirty = true;
    _safeNotifyListeners();
  }

  void updateEmail(String v) {
    email = v;
    personalDirty = true;
    _safeNotifyListeners();
  }

  void updateSecondaryEmail(String v) {
    secondaryEmail = v;
    personalDirty = true;
    _safeNotifyListeners();
  }

  void updateContactNumber(String v) {
    contactNumber = v;
    personalDirty = true;
    _safeNotifyListeners();
  }

  void updateNationality(String v) {
    nationality = v;
    personalDirty = true;
    _safeNotifyListeners();
  }

  void updateObjectives(String v) {
    objectives = v;
    personalDirty = true;
    _safeNotifyListeners();
  }

  void updatePersonalSummary(String v) {
    personalSummary = v;
    personalDirty = true;
    _safeNotifyListeners();
  }

  void updateDob(String v) {
    debugPrint('[updateDob] Called with value: "$v"');
    debugPrint('[updateDob] Previous dob: "$dob"');
    dob = v;
    personalDirty = true;
    debugPrint('[updateDob] New dob: "$dob", personalDirty: $personalDirty');
    _safeNotifyListeners();
  }

  // Professional Status Updates
  void updateProfessionalStatus(String v) {
    professionalStatus = v;
    professionalProfileDirty = true;
    _safeNotifyListeners();
  }

  void updateExpectedRetirementDate(String v) {
    expectedRetirementDate = v;
    professionalProfileDirty = true;
    _safeNotifyListeners();
  }

  void updateRetirementDate(String v) {
    retirementDate = v;
    professionalProfileDirty = true;
    _safeNotifyListeners();
  }

  // Temp Updates — mark the owning section dirty on ANY input, so the Save
  // button reflects unsaved changes the moment the user edits an input area.
  void updateTempSchool(String v) {
    tempSchool = v;
    educationDirty = true;
    _safeNotifyListeners();
  }

  void updateTempDegree(String v) {
    tempDegree = v;
    educationDirty = true;
    _safeNotifyListeners();
  }

  void updateTempFieldOfStudy(String v) {
    tempFieldOfStudy = v;
    educationDirty = true;
    _safeNotifyListeners();
  }

  void updateTempEduStart(String v) {
    tempEduStart = v;
    educationDirty = true;
    _safeNotifyListeners();
  }

  void updateTempEduEnd(String v) {
    tempEduEnd = v;
    educationDirty = true;
    _safeNotifyListeners();
  }

  void updateTempCompany(String v) {
    tempCompany = v;
    experienceDirty = true;
    _safeNotifyListeners();
  }

  void updateTempRole(String v) {
    tempRole = v;
    experienceDirty = true;
    _safeNotifyListeners();
  }

  void updateTempExpStart(String v) {
    tempExpStart = v;
    experienceDirty = true;
    _safeNotifyListeners();
  }

  void updateTempExpEnd(String v) {
    tempExpEnd = v;
    experienceDirty = true;
    _safeNotifyListeners();
  }

  void updateTempExpDescription(String v) {
    tempExpDescription = v;
    experienceDirty = true;
    _safeNotifyListeners();
  }

  void updateTempCertName(String v) {
    tempCertName = v;
    certificationsDirty = true;
    _safeNotifyListeners();
  }

  void updateTempCertInstitution(String v) {
    tempCertInstitution = v;
    certificationsDirty = true;
    _safeNotifyListeners();
  }

  void updateTempCertYear(String v) {
    tempCertYear = v;
    certificationsDirty = true;
    _safeNotifyListeners();
  }

  // List Management
  void addEducationEntry(BuildContext ctx) {
    if (tempSchool.trim().isEmpty && tempDegree.trim().isEmpty) {
      _showSnackBar(ctx, 'Please enter institution or degree');
      return;
    }
    educationalProfile.add({
      'institutionName': tempSchool.trim(),
      'duration':
          tempEduStart.trim() +
          (tempEduEnd.trim().isNotEmpty ? ' - ${tempEduEnd.trim()}' : ''),
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
      'duration':
          tempExpStart.trim() +
          (tempExpEnd.trim().isNotEmpty ? ' - ${tempExpEnd.trim()}' : ''),
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
  void addPublication(String v) {
    if (v.trim().isEmpty) return;
    publications.add(v.trim());
    publicationsDirty = true;
    _safeNotifyListeners();
  }

  void removePublicationAt(int idx) {
    if (_isValidIndex(idx, publications.length)) {
      publications.removeAt(idx);
      publicationsDirty = true;
      _safeNotifyListeners();
    }
  }

  void addAward(String v) {
    if (v.trim().isEmpty) return;
    awards.add(v.trim());
    awardsDirty = true;
    _safeNotifyListeners();
  }

  void removeAwardAt(int idx) {
    if (_isValidIndex(idx, awards.length)) {
      awards.removeAt(idx);
      awardsDirty = true;
      _safeNotifyListeners();
    }
  }

  void addReference(String v) {
    if (v.trim().isEmpty) return;
    references.add(v.trim());
    referencesDirty = true;
    _safeNotifyListeners();
  }

  void removeReferenceAt(int idx) {
    if (_isValidIndex(idx, references.length)) {
      references.removeAt(idx);
      referencesDirty = true;
      _safeNotifyListeners();
    }
  }

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
      case 'personal':
        return personalDirty ? Colors.red : Colors.green;
      case 'education':
        return educationDirty ? Colors.red : Colors.green;
      case 'experience':
        return experienceDirty ? Colors.red : Colors.green;
      case 'certifications':
        return certificationsDirty ? Colors.red : Colors.green;
      case 'publications':
        return publicationsDirty ? Colors.red : Colors.green;
      case 'awards':
        return awardsDirty ? Colors.red : Colors.green;
      case 'references':
        return referencesDirty ? Colors.red : Colors.green;
      default:
        return Colors.blue;
    }
  }

  String get debugInfo =>
      'uid:$uid isLoading:$isLoading error:$errorMessage cached:${_lastFetchTime != null}';

  List<String> get skills => skillsList;
  String get professionalSummary => professionalProfileSummary;
  set professionalSummary(String v) {
    professionalProfileSummary = v;
    professionalProfileDirty = true;
    _safeNotifyListeners();
  }

  bool _isValidIndex(int idx, int length) => idx >= 0 && idx < length;

  List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (v is String) {
      return v
          .split(RegExp(r'[,;\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }



  void _handleError(String context, dynamic error, [StackTrace? stackTrace]) {
    errorMessage = '$context: $error';
    lastDebug = '[ERROR] $context: $error';
    debugPrint(lastDebug);
    isLoading = false;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  void _resetAllDirtyFlags() {
    personalDirty = educationDirty = professionalProfileDirty =
        experienceDirty = certificationsDirty = publicationsDirty =
            awardsDirty = referencesDirty = documentsDirty = false;
  }

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
    tempRank = '';
    tempUnit = '';
    tempLocation = '';
    tempCommand = '';
    tempAircraftType = '';
    tempFlightHours = '';
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
    professionalExperience = [];
    certifications = [];
    publications = [];
    awards = [];
    references = [];
    documents = [];
    professionalStatus = '';
    expectedRetirementDate = '';
    experienceDocuments = [];
    certificationDocuments = [];
    candidateProfile = null;
    roleTemplate = null;
    _resetAllDirtyFlags();
  }

  @override
  void dispose() {
    _isDisposed = true;
    skillController.dispose();
    super.dispose();
  }
}
