// lib/SignUp/signup_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../Parser_CV/cv_parser.dart';
import '../core/onboarding/candidate_profile_service.dart';
import '../core/onboarding/models/candidate_profile.dart';
import 'web_image_picker.dart';

class SignupProvider extends ChangeNotifier {
  // ─── State ────────────────────────────────────────────────────────────────────
  String role = 'Job Seeker';
  int personalVisibleIndex = 0;
  int currentStep = 0;
  bool showCvUploadSection = false;
  bool isLoading = false;

  // ─── Controllers ──────────────────────────────────────────────────────────────
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final contactNumberController = TextEditingController();
  final nationalityController = TextEditingController();
  final summaryController = TextEditingController();
  final objectivesController = TextEditingController();
  final skillInputController = TextEditingController();
  final socialInputController = TextEditingController();

  // ─── Data ─────────────────────────────────────────────────────────────────────
  final skills = <String>[];
  final socialLinks = <String>[];
  final educationalProfile = <Map<String, dynamic>>[];
  DateTime? dob;
  Uint8List? profilePicBytes;
  String? imageDataUrl;
  String? profilePicUrl;
  String? secondaryEmail;

  // ─── Errors ───────────────────────────────────────────────────────────────────
  String? emailError;
  String? passwordError;
  String? generalError;

  // ─── Captcha ──────────────────────────────────────────────────────────────────
  bool isCaptchaVerified = false;
  String? captchaToken;

  // ─── Job Alerts / Newsletter ──────────────────────────────────────────────────
  bool jobAlertsEnabled = true;

  final _picker = ImagePicker();
  final _candidateProfiles = CandidateProfileService();

  // ─── Safe notify helper ───────────────────────────────────────────────────────
  /// Schedules notifyListeners after the current build frame completes.
  /// Use this whenever a notification might be triggered during a build
  /// (e.g. from event listeners, timers, or callbacks invoked inside build).
  void _safeNotify() {
    // If we're already in a frame, defer until post-frame.
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // Guard: provider might have been disposed by the time the frame ends.
        try {
          notifyListeners();
        } catch (_) {}
      });
    } else {
      notifyListeners();
    }
  }

  // ─── Captcha ──────────────────────────────────────────────────────────────────
  /// Called from web event listeners that fire during the build phase.
  /// Uses [_safeNotify] to avoid "setState during build" assertion.
  void setCaptchaVerified(bool verified, {String? token}) {
    isCaptchaVerified = verified;
    captchaToken = verified ? token : null;
    _safeNotify(); // ← was notifyListeners(), caused the build-phase crash
  }

  // ─── Job Alerts Toggle ────────────────────────────────────────────────────────
  void toggleJobAlerts(bool value) {
    jobAlertsEnabled = value;
    notifyListeners();
  }

  // ─── Role & Navigation ────────────────────────────────────────────────────────
  void setRole(String newRole) {
    if (!['Job Seeker', 'Recruiter'].contains(newRole)) return;
    role = newRole;
    if (newRole == 'Recruiter') {
      showCvUploadSection = false;
      jobAlertsEnabled = false;
    }
    notifyListeners();
  }

  void revealCvUpload({bool reveal = true}) {
    showCvUploadSection = reveal;
    notifyListeners();
  }

  void goToStep(int step) {
    currentStep = step;
    if (step == 1 && personalVisibleIndex == 0) personalVisibleIndex = 0;
    notifyListeners();
  }

  void revealNextPersonalField() =>
      _updatePersonalIndex(personalVisibleIndex + 1);
  void revealPreviousPersonalField() =>
      _updatePersonalIndex(personalVisibleIndex - 1);

  void _updatePersonalIndex(int index) {
    if (index >= 0) {
      personalVisibleIndex = index;
      notifyListeners();
    }
  }

  void onFieldTypedAutoReveal(int index, String value) {
    if (value.trim().isNotEmpty && personalVisibleIndex == index) {
      revealNextPersonalField();
    }
  }

  void setDob(DateTime date) {
    dob = date;
    notifyListeners();
  }

  // ─── Image Handling ───────────────────────────────────────────────────────────
  Future<void> pickProfilePicture() async {
    try {
      if (kIsWeb) {
        final res = await pickImageWebImpl();
        if (res == null) return;
        if (res.containsKey('error')) {
          generalError = res['error'] as String?;
          notifyListeners();
          return;
        }
        profilePicBytes = res['bytes'] as Uint8List?;
        imageDataUrl = res['dataUrl'] as String?;
      } else {
        final picked = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (picked == null) return;
        profilePicBytes = await picked.readAsBytes();
        imageDataUrl =
            'data:${picked.mimeType ?? 'image/jpeg'};base64,${base64Encode(profilePicBytes!)}';
      }
      profilePicUrl = null;
      notifyListeners();
    } catch (e) {
      generalError = 'Failed to pick image: $e';
      notifyListeners();
    }
  }

  void removeProfilePicture() {
    profilePicBytes = null;
    imageDataUrl = null;
    profilePicUrl = null;
    notifyListeners();
  }

  Future<String?> _uploadProfilePic(String uid) async {
    if (profilePicBytes == null || profilePicBytes!.isEmpty) return null;
    try {
      final collectionName = role == 'Recruiter' ? 'recruiter' : 'Job_Seeker';
      final ref = FirebaseStorage.instance.ref(
        '$collectionName/$uid/profilePic.jpg',
      );
      await ref.putData(
        profilePicBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // ─── Skills & Social Links ────────────────────────────────────────────────────
  void addSkill(String raw) => _addToList(skills, raw);
  void removeSkillAt(int idx) => _removeFromList(skills, idx);
  void addSocialLink(String raw) => _addToList(socialLinks, raw);
  void removeSocialLinkAt(int idx) => _removeFromList(socialLinks, idx);

  void _addToList(List<String> list, String raw) {
    final v = raw.trim();
    if (v.isNotEmpty && !list.contains(v)) {
      list.add(v);
      notifyListeners();
    }
  }

  void _removeFromList(List<String> list, int idx) {
    if (idx >= 0 && idx < list.length) {
      list.removeAt(idx);
      notifyListeners();
    }
  }

  // ─── Education ────────────────────────────────────────────────────────────────
  void addEducation({
    required String institutionName,
    required String duration,
    required String majorSubjects,
    required String marksOrCgpa,
  }) {
    educationalProfile.add({
      'institutionName': institutionName.trim(),
      'duration': duration.trim(),
      'majorSubjects': majorSubjects.trim(),
      'marksOrCgpa': marksOrCgpa.trim(),
    });
    notifyListeners();
  }

  void updateEducation(int index, Map<String, dynamic> newEntry) {
    if (index >= 0 && index < educationalProfile.length) {
      educationalProfile[index] = newEntry;
      notifyListeners();
    }
  }

  void removeEducation(int index) {
    if (index >= 0 && index < educationalProfile.length) {
      educationalProfile.removeAt(index);
      notifyListeners();
    }
  }

  // ─── Validation ───────────────────────────────────────────────────────────────
  bool validateEmail() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      emailError = 'Email is required';
    } else if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
      emailError = 'Enter a valid email';
    } else {
      emailError = null;
    }
    notifyListeners();
    return emailError == null;
  }

  bool validatePasswords() {
    final p = passwordController.text.trim();
    final cp = confirmPasswordController.text.trim();
    if (p.isEmpty || cp.isEmpty) {
      passwordError = 'Password and confirm password are required';
    } else if (p.length < 8) {
      passwordError = 'Password must be at least 8 characters';
    } else if (p != cp) {
      passwordError = 'Passwords do not match';
    } else {
      passwordError = null;
    }
    notifyListeners();
    return passwordError == null;
  }

  bool _isValidPhone(String s) =>
      s.isNotEmpty && RegExp(r'^[\d\+\-\s]{5,20}$').hasMatch(s);

  bool validatePersonalFieldAtIndex(int index) {
    switch (index) {
      case 0:
        return nameController.text.trim().isNotEmpty;
      case 1:
        return _isValidPhone(contactNumberController.text.trim());
      case 2:
        return nationalityController.text.trim().isNotEmpty;
      case 3:
        return dob != null;
      case 4:
        return summaryController.text.trim().isNotEmpty;
      case 5:
        return skills.isNotEmpty;
      case 6:
        return objectivesController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  bool personalSectionIsComplete() =>
      [0, 1, 2, 3, 4, 5, 6].every(validatePersonalFieldAtIndex);

  bool _isNotEmpty(dynamic value) =>
      (value as String?)?.trim().isNotEmpty ?? false;

  double computeProgress() {
    final personalDone = [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
    ].where(validatePersonalFieldAtIndex).length;
    final educationDone = educationSectionIsComplete() ? 1 : 0;
    return (personalDone + educationDone) / 8;
  }

  bool educationSectionIsComplete() {
    if (educationalProfile.isEmpty) return false;
    return educationalProfile.every(
      (e) =>
          _isNotEmpty(e['institutionName']) &&
          _isNotEmpty(e['duration']) &&
          _isNotEmpty(e['majorSubjects']) &&
          _isNotEmpty(e['marksOrCgpa']),
    );
  }

  // ─── Firebase Operations ──────────────────────────────────────────────────────

  /// Recruiter: single-step registration
  Future<bool> registerRecruiter() async {
    if (!validateEmail() || !validatePasswords()) {
      generalError = emailError ?? passwordError;
      notifyListeners();
      return false;
    }
    if (nameController.text.trim().isEmpty) {
      generalError = 'Name is required';
      notifyListeners();
      return false;
    }

    return _executeWithLoading(() async {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final uid = cred.user?.uid;
      if (uid == null) throw Exception('Failed to obtain user id');

      await _saveRecruiterData(uid);
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': role,
        'isNew': 'no',
        'account_status': 'active',
        'is_verified': false,
        'job_alerts_enabled': jobAlertsEnabled,
        'created_at': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  /// Job Seeker: create auth account only
  Future<String?> createJobSeekerAccount() async {
    if (!validateEmail() || !validatePasswords()) {
      generalError = emailError ?? passwordError;
      notifyListeners();
      return null;
    }

    String? targetRoute;

    final success = await _executeWithLoading(() async {
      final uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final uid = uc.user?.uid;
      if (uid == null) throw Exception('Unable to obtain user id');

      if (profilePicBytes != null) {
        profilePicUrl = await _uploadProfilePic(uid);
      }

      final hasProfileData =
          nameController.text.trim().isNotEmpty ||
          contactNumberController.text.trim().isNotEmpty ||
          nationalityController.text.trim().isNotEmpty ||
          skills.isNotEmpty ||
          educationalProfile.isNotEmpty;

      const isNewValue = 'yes';

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': role,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'isNew': isNewValue,
        'uid': uid,
        'account_status': 'active',
        'user_lvl': 'basic',
        'job_alerts_enabled': jobAlertsEnabled,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (hasProfileData) {
        await _saveCandidateProfile(_buildManualProfile(uid));
      }

      // The dynamic role-template onboarding owns profile creation now.
      targetRoute = '/onboarding';
      return true;
    });

    return success ? targetRoute : null;
  }

  Future<bool> createJobSeekerProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      generalError = 'No authenticated user found';
      notifyListeners();
      return false;
    }

    return _executeWithLoading(() async {
      if (profilePicBytes != null && profilePicUrl == null) {
        profilePicUrl = await _uploadProfilePic(user.uid);
      }
      await _saveCandidateProfile(_buildManualProfile(user.uid));

      try {
        final updateData = <String, dynamic>{
          'isNew': 'no',
          'profileCompletedAt': FieldValue.serverTimestamp(),
        };
        // Sync name to users collection if available
        final profileName = nameController.text.trim();
        if (profileName.isNotEmpty) {
          updateData['name'] = profileName;
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updateData);
        debugPrint('✅ isNew → "no" for ${user.uid}');
      } catch (e) {
        debugPrint('❌ createJobSeekerProfile update failed: $e');
      }

      return true;
    });
  }

  Future<bool> submitExtractedCvAndCreateAccount(
    CvExtractionResult result,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      generalError = 'No authenticated user found. Please log in first.';
      notifyListeners();
      return false;
    }
    final uid = user.uid;

    return _executeWithLoading(() async {
      _populateFromCvResult(result);
      await _handleCvProfilePic(result.personalProfile);
      profilePicUrl = await _uploadProfilePic(uid);
      await _saveCandidateProfile(
          _buildCvProfile(uid, result, user.email ?? ''));

      try {
        final cvUpdateData = <String, dynamic>{
          'isNew': 'no',
          'profileCompletedAt': FieldValue.serverTimestamp(),
        };
        final cvName = nameController.text.trim();
        if (cvName.isNotEmpty) {
          cvUpdateData['name'] = cvName;
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(cvUpdateData);
        debugPrint('✅ isNew → "no" for $uid');
      } catch (e) {
        debugPrint('⚠️ Falling back to set merge: $e');
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'email': user.email ?? '',
            'role': role,
            'isNew': 'no',
            'account_status': 'active',
            'user_lvl': 'basic',
            'created_at': FieldValue.serverTimestamp(),
            'profileCompletedAt': FieldValue.serverTimestamp(),
            'name': nameController.text.trim(),
          }, SetOptions(merge: true));
        } catch (e2) {
          debugPrint('❌ Final fallback failed: $e2');
        }
      }
      return true;
    });
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────────

  Future<bool> _executeWithLoading(Future<bool> Function() operation) async {
    generalError = null;
    isLoading = true;
    notifyListeners();
    try {
      return await operation();
    } on FirebaseAuthException catch (e) {
      generalError = e.message ?? 'Authentication failed';
      return false;
    } catch (e) {
      generalError = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Recruiters keep their own flat document shape; a job seeker's account is
  /// a [CandidateProfile] and nothing else.
  Future<void> _saveRecruiterData(String uid) async {
    await FirebaseFirestore.instance.collection('recruiter').doc(uid).set({
      'user_data': _buildRecruiterData(uid),
    }, SetOptions(merge: true));
  }

  /// Saved as a draft, not submitted: signup only collects the basics, and the
  /// role-template onboarding is what marks a profile complete. Each caller
  /// writes its own `users/{uid}` flags, so this must not touch them.
  Future<void> _saveCandidateProfile(CandidateProfile profile) =>
      _candidateProfiles.saveDraft(profile);

  Map<String, dynamic> _buildRecruiterData(String uid) => {
    'uid': uid,
    'name': nameController.text.trim(),
    'email': emailController.text.trim(),
    'role': role,
    'createdAt': FieldValue.serverTimestamp(),
  };

  /// The profile a candidate types by hand during signup.
  ///
  /// Signup collects only the basics; the role-template onboarding fills in
  /// everything else and rewrites this same document, so the shape has to be
  /// identical from the first write.
  CandidateProfile _buildManualProfile(String uid) => CandidateProfile(
        uid: uid,
        personalInfo: PersonalInfo(
          fullName: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: contactNumberController.text.trim(),
          nationality: nationalityController.text.trim(),
          summary: summaryController.text.trim(),
          objectives: objectivesController.text.trim(),
          profilePicUrl: profilePicUrl ?? '',
          skills: List<String>.from(skills),
          socialLinks: List<String>.from(socialLinks),
          dateOfBirth: dob == null ? '' : DateFormat('yyyy-MM-dd').format(dob!),
        ),
        education: _educationEntries(),
      );

  /// The profile prefilled from an uploaded CV.
  CandidateProfile _buildCvProfile(
    String uid,
    CvExtractionResult result,
    String authEmail,
  ) =>
      CandidateProfile(
        uid: uid,
        personalInfo: PersonalInfo(
          fullName: nameController.text.trim(),
          email: authEmail,
          secondaryEmail: secondaryEmail ?? '',
          phone: contactNumberController.text.trim(),
          nationality: nationalityController.text.trim(),
          summary: summaryController.text.trim().isNotEmpty
              ? summaryController.text.trim()
              : result.professionalSummary,
          objectives: objectivesController.text.trim(),
          profilePicUrl: profilePicUrl ?? '',
          skills: List<String>.from(skills),
          socialLinks: List<String>.from(socialLinks),
          dateOfBirth: dob == null ? '' : DateFormat('yyyy-MM-dd').format(dob!),
        ),
        education: _educationEntries(),
        experience: [
          for (final (i, e) in result.professionalExperience.indexed)
            ExperienceEntry(
              id: 'exp_$i',
              title: (e['role'] ?? '').toString(),
              company: (e['organization'] ?? '').toString(),
              location: (e['location'] ?? '').toString(),
              startDate: (e['startDate'] ?? '').toString(),
              endDate: (e['endDate'] ?? '').toString(),
              responsibilities: _splitLines(e['duties']),
            ),
        ],
        certifications: [
          for (final (i, c) in result.certifications.indexed)
            CertificationEntry(
              id: 'cert_$i',
              name: (c['name'] ?? '').toString(),
              issuer: (c['organization'] ?? '').toString(),
            ),
        ],
        publications: result.publications,
        awards: result.awards,
        references: result.references,
        cvSourceFile: 'cv-upload',
      );

  List<EducationEntry> _educationEntries() => [
        for (final (i, e) in educationalProfile.indexed)
          EducationEntry(
            id: 'edu_$i',
            institution: (e['institutionName'] ?? '').toString(),
            fieldOfStudy: (e['majorSubjects'] ?? '').toString(),
            graduationYear: _yearOf(e['duration']),
            grade: (e['marksOrCgpa'] ?? '').toString(),
          ),
      ];

  static int? _yearOf(dynamic v) {
    final matches = RegExp(r'(19|20)\d{2}').allMatches(v?.toString() ?? '');
    return matches.isEmpty ? null : int.tryParse(matches.last.group(0)!);
  }

  static List<String> _splitLines(dynamic v) => (v?.toString() ?? '')
      .split(RegExp(r'[\n;]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void _populateFromCvResult(CvExtractionResult result) {
    final personal = result.personalProfile;
    nameController.text = _getStringValue(
      personal['name'],
      nameController.text,
    );
    contactNumberController.text = _getStringValue(
      personal['contactNumber'],
      contactNumberController.text,
    );
    nationalityController.text = _getStringValue(
      personal['nationality'],
      nationalityController.text,
    );
    summaryController.text = _getStringValue(
      personal['summary'] ?? result.professionalSummary,
      summaryController.text,
    );
    secondaryEmail = _getStringValue(personal['email'], '');

    _populateListFromDynamic(socialLinks, personal['socialLinks']);
    _populateListFromDynamic(skills, personal['skills']);

    educationalProfile
      ..clear()
      ..addAll(
        result.educationalProfile.map(
          (edu) => {
            'institutionName': _getStringValue(edu['institutionName'], ''),
            'duration': _getStringValue(edu['duration'], ''),
            'majorSubjects': _getStringValue(edu['majorSubjects'], ''),
            'marksOrCgpa': _getStringValue(edu['marksOrCgpa'], ''),
          },
        ),
      );

    notifyListeners();
  }

  String _getStringValue(dynamic value, String fallback) =>
      (value?.toString().trim().isNotEmpty ?? false)
      ? value.toString()
      : fallback;

  void _populateListFromDynamic(List<String> target, dynamic source) {
    target.clear();
    if (source is List) {
      target.addAll(source.map((e) => e.toString()));
    } else if (source is String && source.isNotEmpty) {
      target.addAll(
        source
            .split(RegExp(r'[,;\n]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      );
    }
  }

  Future<void> _handleCvProfilePic(Map<String, dynamic> personal) async {
    if (profilePicBytes != null || personal['profilePic'] == null) return;
    try {
      final picVal = personal['profilePic'];
      if (picVal is String) {
        if (picVal.startsWith('data:')) {
          final parts = picVal.split(',');
          if (parts.length == 2) {
            profilePicBytes = base64Decode(parts[1]);
            imageDataUrl = picVal;
          }
        } else {
          try {
            profilePicBytes = base64Decode(picVal);
            imageDataUrl = 'data:image/jpeg;base64,$picVal';
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────────
  void clearAll() {
    for (var c in [
      emailController,
      passwordController,
      confirmPasswordController,
      nameController,
      contactNumberController,
      nationalityController,
      summaryController,
      objectivesController,
      skillInputController,
      socialInputController,
    ]) {
      c.clear();
    }

    skills.clear();
    socialLinks.clear();
    educationalProfile.clear();
    profilePicBytes = null;
    imageDataUrl = null;
    profilePicUrl = null;
    dob = null;
    secondaryEmail = null;
    personalVisibleIndex = 0;
    currentStep = 0;
    emailError = null;
    passwordError = null;
    generalError = null;
    isLoading = false;
    isCaptchaVerified = false;
    jobAlertsEnabled = true;
    captchaToken = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (var c in [
      emailController,
      passwordController,
      confirmPasswordController,
      nameController,
      contactNumberController,
      nationalityController,
      summaryController,
      objectivesController,
      skillInputController,
      socialInputController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
