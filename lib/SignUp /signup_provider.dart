// lib/SignUp/signup_provider.dart - UPDATED WITH RELAXED VALIDATION
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../extractor_CV/cv_extractor.dart';
import 'package:web/web.dart';

class SignupProvider extends ChangeNotifier {
  // ========== STATE ==========
  String role = 'job_seeker';
  int personalVisibleIndex = 0;
  int currentStep = 0;
  bool showCvUploadSection = false;
  bool isLoading = false;

  // ========== CONTROLLERS ==========
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

  // ========== DATA ==========
  final skills = <String>[];
  final socialLinks = <String>[];
  final educationalProfile = <Map<String, dynamic>>[];
  DateTime? dob;
  Uint8List? profilePicBytes;
  String? imageDataUrl;
  String? profilePicUrl;
  String? secondaryEmail;

  // ========== ERRORS ==========
  String? emailError;
  String? passwordError;
  String? generalError;

  final _picker = ImagePicker();

  // ========== ROLE & NAVIGATION ==========
  void setRole(String newRole) {
    if (!['job_seeker', 'recruiter'].contains(newRole)) return;
    role = newRole;
    if (newRole == 'recruiter') showCvUploadSection = false;
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

  void revealNextPersonalField() => _updatePersonalIndex(personalVisibleIndex + 1);
  void revealPreviousPersonalField() => _updatePersonalIndex(personalVisibleIndex - 1);

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

  // ========== IMAGE HANDLING ==========
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
        final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (picked == null) return;
        profilePicBytes = await picked.readAsBytes();
        imageDataUrl = 'data:${picked.mimeType ?? 'image/jpeg'};base64,${base64Encode(profilePicBytes!)}';
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
      final ref = FirebaseStorage.instance.ref('$role/$uid/profilePic.jpg');
      await ref.putData(profilePicBytes!, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // ========== SKILLS & SOCIAL LINKS ==========
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

  // ========== EDUCATION ==========
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

  // ========== VALIDATION ==========
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
    final p = passwordController.text;
    final cp = confirmPasswordController.text;

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

  bool _isValidPhone(String s) => s.isNotEmpty && RegExp(r'^[\d\+\-\s]{5,20}$').hasMatch(s);

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

  bool personalSectionIsComplete() {
    return [0, 1, 2, 3, 4, 5, 6].every((i) => validatePersonalFieldAtIndex(i));
  }

  bool _isNotEmpty(dynamic value) => (value as String?)?.trim().isNotEmpty ?? false;

  double computeProgress() {
    final personalDone = [0, 1, 2, 3, 4, 5, 6].where((i) => validatePersonalFieldAtIndex(i)).length;
    final educationDone = educationSectionIsComplete() ? 1 : 0;
    return (personalDone + educationDone) / 8;
  }

  bool educationSectionIsComplete() {
    if (educationalProfile.isEmpty) return false;
    return educationalProfile.every((e) =>
    _isNotEmpty(e['institutionName']) &&
        _isNotEmpty(e['duration']) &&
        _isNotEmpty(e['majorSubjects']) &&
        _isNotEmpty(e['marksOrCgpa']));
  }

  // ========== FIREBASE OPERATIONS ==========

  /// 1. RECRUITER: Single-step registration (creates auth + saves full data)
  Future<bool> registerRecruiter() async {
    // Validate required fields for recruiter
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
        password: passwordController.text,
      );

      final uid = cred.user?.uid;
      if (uid == null) throw Exception('Failed to obtain user id');

      await _saveUserData(uid, _buildRecruiterData(uid));
      return true;
    });
  }

  /// 2. JOB SEEKER: Create Firebase Auth account only (NO validation of profile fields)
  Future<bool> createJobSeekerAccount() async {
    // Only validate email and password for account creation
    if (!validateEmail() || !validatePasswords()) {
      generalError = emailError ?? passwordError;
      notifyListeners();
      return false;
    }

    return _executeWithLoading(() async {
      final uc = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final uid = uc.user?.uid;
      if (uid == null) throw Exception('Unable to obtain user id');

      // Upload profile picture if it was selected during account creation
      if (profilePicBytes != null) {
        profilePicUrl = await _uploadProfilePic(uid);
      }

      // Write to Firestore: /users/{uid}
      await FirebaseFirestore.instance.collection('users').add({
        'role': role,  // 'job_seeker'
        'email': emailController.text.trim(),
        'uid': uid,  // Store the auth UID as a field
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }
  /// 3. JOB SEEKER: Save full profile data (RELAXED validation - allows partial data)
  Future<bool> createJobSeekerProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      generalError = 'No authenticated user found';
      notifyListeners();
      return false;
    }

    // RELAXED VALIDATION: Don't block if fields are missing
    // User can save partial profile and complete it later

    return _executeWithLoading(() async {
      // Upload profile picture if not already uploaded
      if (profilePicBytes != null && profilePicUrl == null) {
        profilePicUrl = await _uploadProfilePic(user.uid);
      }

      await _saveUserData(user.uid, _buildManualUserData(user.uid));
      return true;
    });
  }

  /// 4. CV UPLOAD: Single-step registration (creates auth + saves all extracted data)
  // Only saves the extracted CV profile data to Firestore
// Assumes the user is already authenticated and logged in
  Future<bool> submitExtractedCvAndCreateAccount(CvExtractionResult result) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      generalError = 'No authenticated user found. Please log in first.';
      notifyListeners();
      return false;
    }

    final uid = user.uid;

    return _executeWithLoading(() async {
      // 1. Populate provider from CV result
      _populateFromCvResult(result);

      // 2. Handle profile picture if present in CV
      await _handleCvProfilePic(result.personalProfile);

      // 3. Upload profile picture (if any) and get URL
      profilePicUrl = await _uploadProfilePic(uid);

      // 4. Save full profile data using the existing authenticated user
      await _saveUserData(uid, _buildCvUserData(uid, result, user.email ?? ''));

      return true;
    });
  }
  // ========== PRIVATE HELPERS ==========
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

  Future<void> _saveUserData(String uid, Map<String, dynamic> userData) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection(role).doc(uid).set(
      {'user_data': userData},
      SetOptions(merge: true),
    );

    try {
      await firestore.collection('users').add(_buildShadowData(uid, userData));
    } catch (_) {}
  }

  Map<String, dynamic> _buildRecruiterData(String uid) => {
    'uid': uid,
    'name': nameController.text.trim(),
    'email': emailController.text.trim(),
    'role': role,
    'createdAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> _buildManualUserData(String uid) {
    // Build profile data with what's available (RELAXED - allows empty fields)
    return {
      'personalProfile': {
        'fullName': nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
        'email': emailController.text.trim(),
        'contactNumber': contactNumberController.text.trim().isNotEmpty ? contactNumberController.text.trim() : null,
        'nationality': nationalityController.text.trim().isNotEmpty ? nationalityController.text.trim() : null,
        'summary': summaryController.text.trim().isNotEmpty ? summaryController.text.trim() : null,
        'profilePicUrl': profilePicUrl,
        'skills': skills.isNotEmpty ? skills : null,
        'objectives': objectivesController.text.trim().isNotEmpty ? objectivesController.text.trim() : null,
        'socialLinks': socialLinks.isNotEmpty ? socialLinks : null,
        'dob': dob != null ? DateFormat('yyyy-MM-dd').format(dob!) : null,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'educationalProfile': educationalProfile.isNotEmpty ? educationalProfile : null,
    };
  }

  Map<String, dynamic> _buildCvUserData(String uid, CvExtractionResult result, String authEmail) => {
    'personalProfile': {
      'name': nameController.text.trim(),
      'email': authEmail,
      'secondary_email': secondaryEmail ?? '',
      'contactNumber': contactNumberController.text.trim(),
      'nationality': nationalityController.text.trim(),
      'profilePicUrl': profilePicUrl,
      'skills': skills,
      'objectives': objectivesController.text.trim(),
      'socialLinks': socialLinks,
      'summary': summaryController.text.trim(),
      'dob': dob != null ? DateFormat('yyyy-MM-dd').format(dob!) : null,
    },
    'educationalProfile': educationalProfile,
    'professionalProfile': {'summary': result.professionalSummary},
    'professionalExperience': result.experiences,
    'certifications': result.certifications,
    'publications': result.publications,
    'awards': result.awards,
    'references': result.references,
    'createdAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> _buildShadowData(String uid, Map<String, dynamic> userData) {
    final personalProfile = userData['personalProfile'] as Map<String, dynamic>?;
    return {
      'fullName': personalProfile?['name'] ?? personalProfile?['fullName'] ?? nameController.text.trim(),
      'email': personalProfile?['email'] ?? emailController.text.trim(),
      'secondary_email': personalProfile?['secondary_email'] ?? secondaryEmail ?? '',
      'uid': uid,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  void _populateFromCvResult(CvExtractionResult result) {
    final personal = result.personalProfile;

    nameController.text = _getStringValue(personal['name'], nameController.text);
    contactNumberController.text = _getStringValue(personal['contactNumber'], contactNumberController.text);
    nationalityController.text = _getStringValue(personal['nationality'], nationalityController.text);
    summaryController.text = _getStringValue(personal['summary'] ?? result.professionalSummary, summaryController.text);
    secondaryEmail = _getStringValue(personal['email'], '');

    _populateListFromDynamic(socialLinks, personal['socialLinks']);
    _populateListFromDynamic(skills, personal['skills']);

    educationalProfile.clear();
    educationalProfile.addAll(result.educationalProfile.map((edu) => {
      'institutionName': _getStringValue(edu['institutionName'], ''),
      'duration': _getStringValue(edu['duration'], ''),
      'majorSubjects': _getStringValue(edu['majorSubjects'], ''),
      'marksOrCgpa': _getStringValue(edu['marksOrCgpa'], ''),
    }));

    notifyListeners();
  }

  String _getStringValue(dynamic value, String fallback) =>
      (value?.toString().trim().isNotEmpty ?? false) ? value.toString() : fallback;

  void _populateListFromDynamic(List<String> target, dynamic source) {
    target.clear();
    if (source is List) {
      target.addAll(source.map((e) => e.toString()));
    } else if (source is String && source.isNotEmpty) {
      target.addAll(source.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty));
    }
  }

  String _determineAuthEmail(String? override) {
    if (override?.trim().isNotEmpty ?? false) return override!.trim();
    if (emailController.text.trim().isNotEmpty) return emailController.text.trim();
    return secondaryEmail ?? '';
  }

  String _determineAuthPassword(String? override) {
    return (override?.isNotEmpty ?? false) ? override! : passwordController.text;
  }

  void _updateControllersWithOverrides(String? email, String? password) {
    if (email?.trim().isNotEmpty ?? false) emailController.text = email!.trim();
    if (password?.isNotEmpty ?? false) {
      passwordController.text = password!;
      confirmPasswordController.text = password;
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

  Future<Map<String, dynamic>?> pickImageWebImpl({int maxBytes = 2 * 1024 * 1024}) async {
    try {
      final uploadInput = HTMLInputElement();
      uploadInput.type = 'file';
      uploadInput.accept = 'image/*';
      uploadInput.multiple = false;
      uploadInput.style.display = 'none';
      document.body?.appendChild(uploadInput);

      final completer = Completer<void>();

      uploadInput.addEventListener(
          'change',
              (Event e) {
            completer.complete();
          }.toJS);

      uploadInput.click();

      await completer.future;

      final files = uploadInput.files;
      if (files == null || files.length == 0) {
        uploadInput.remove();
        return null;
      }

      final file = files.item(0);
      if (file == null) {
        uploadInput.remove();
        return null;
      }

      if (file.size > maxBytes) {
        uploadInput.remove();
        final maxMb = (maxBytes / (1024 * 1024)).toStringAsFixed(1);
        return {'error': 'Selected image exceeds $maxMb MB'};
      }

      final dataUrlCompleter = Completer<String?>();
      final readerDataUrl = FileReader();

      readerDataUrl.addEventListener(
          'load',
              (Event e) {
            dataUrlCompleter.complete(readerDataUrl.result as String?);
          }.toJS);

      readerDataUrl.addEventListener(
          'error',
              (Event e) {
            dataUrlCompleter.completeError('Error reading file as DataURL');
          }.toJS);

      readerDataUrl.readAsDataURL(file);
      final dataUrl = await dataUrlCompleter.future;

      final bytesCompleter = Completer<dynamic>();
      final readerBinary = FileReader();

      readerBinary.addEventListener(
          'load',
              (Event e) {
            bytesCompleter.complete(readerBinary.result);
          }.toJS);

      readerBinary.addEventListener(
          'error',
              (Event e) {
            bytesCompleter.completeError('Error reading file as ArrayBuffer');
          }.toJS);

      readerBinary.readAsArrayBuffer(file);
      final resultBuffer = await bytesCompleter.future;

      Uint8List bytes;
      if (resultBuffer is ByteBuffer) {
        bytes = resultBuffer.asUint8List();
      } else {
        uploadInput.remove();
        return {'error': 'Unable to read file bytes (unsupported result type)'};
      }

      uploadInput.remove();

      return {
        'dataUrl': dataUrl,
        'bytes': bytes,
        'fileName': file.name,
        'size': file.size,
      };
    } catch (e) {
      return {'error': 'Image pick failed: $e'};
    }
  }

  // ========== CLEANUP ==========
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
      socialInputController
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
      socialInputController
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}