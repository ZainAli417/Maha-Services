// lib/providers/login_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginProvider with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  StreamSubscription<User?>? _authSubscription;
  bool _isDisposed = false;

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  // ========== GETTERS ==========
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // ========== SAFETY HELPERS ==========
  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  // ========== STATE MANAGEMENT ==========
  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotify();
  }

  void _setError(String message) {
    _errorMessage = message;
    _safeNotify();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }

  void initAuthStateListener() {
    // Save subscription so we can cancel it in dispose()
    _authSubscription = _auth.authStateChanges().listen((user) {
      _currentUser = user;
      _safeNotify();
    });
  }

  Future<void> checkCurrentUser() async {
    _currentUser = _auth.currentUser;
    _safeNotify();
  }

  // ========== ROLE HELPERS ==========
  String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (['recruiter', 'employer'].contains(normalized)) return 'recruiter';
    if (['job_seeker', 'jobseeker', 'job seeker', 'candidate'].contains(normalized)) return 'job_seeker';
    return normalized;
  }

  String _getRoleDashboard(String role) {
    return _normalizeRole(role) == 'recruiter' ? '/recruiter-dashboard' : '/dashboard';
  }

  // ========== UID LOOKUP ==========
  Future<String?> _findUidForEmailAndRole(String email, String expectedRole) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normExpected = _normalizeRole(expectedRole);

    try {
      // 1) Query users collection (fastest, single query)
      final usersSnap = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (usersSnap.docs.isNotEmpty) {
        final userDoc = usersSnap.docs.first;
        final data = userDoc.data();
        final roleField = _normalizeRole(data['role']?.toString() ?? '');

        if (roleField == normExpected) {
          return data['uid']?.toString() ?? userDoc.id;
        }
      }

      // 2) Fallback: Query role-specific collection
      final collection = normExpected == 'recruiter' ? 'recruiter' : 'job_seeker';
      final emailPath = normExpected == 'recruiter'
          ? 'user_data.email'
          : 'user_data.personalProfile.email';

      final roleSnap = await _firestore
          .collection(collection)
          .where(emailPath, isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (roleSnap.docs.isNotEmpty) {
        return roleSnap.docs.first.id;
      }

      return null;
    } catch (e) {
      debugPrint('LoginProvider: UID lookup error: $e');
      return null;
    }
  }

  // ========== ROLE VERIFICATION ==========
  Future<bool> _verifyUserRole(String uid, String expectedRole) async {
    try {
      final normExpected = _normalizeRole(expectedRole);

      // Query the specific role collection
      final collection = normExpected == 'recruiter' ? 'recruiter' : 'job_seeker';
      final docSnap = await _firestore.collection(collection).doc(uid).get();

      if (!docSnap.exists) return false;

      final data = docSnap.data();
      if (data == null) return false;

      // Check nested user_data.role
      if (data['user_data'] is Map) {
        final userData = data['user_data'] as Map<String, dynamic>;
        final role = _normalizeRole(userData['role']?.toString() ?? '');
        if (role == normExpected) return true;
      }

      // Check direct role field
      final directRole = _normalizeRole(data['role']?.toString() ?? '');
      if (directRole == normExpected) return true;

      // If doc exists in collection, assume role is correct (last resort)
      return true;
    } catch (e) {
      debugPrint('LoginProvider: Role verification error: $e');
      return false;
    }
  }

  // ========== EMAIL/PASSWORD LOGIN ==========
  /// NOTE: This method **does not** accept BuildContext or perform navigation.
  /// It returns the target route on success (e.g. '/dashboard') or `null` on failure.
  Future<String?> login({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      _setError('Email and password are required');
      return null;
    }

    _setLoading(true);
    clearError();

    try {
      // 1) Find UID for email and role
      final foundUid = await _findUidForEmailAndRole(email.trim(), expectedRole);
      if (foundUid == null) {
        _setError('No account found as "$expectedRole". Please register or check your role selection.');
        return null;
      }

      // 2) Sign in with Firebase Auth
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        _setError('Authentication failed');
        await _auth.signOut();
        return null;
      }

      // 3) Verify UID matches
      if (user.uid != foundUid) {
        await _auth.signOut();
        _setError('Account mismatch. Please contact support.');
        return null;
      }

      // 4) Verify role
      final roleVerified = await _verifyUserRole(user.uid, expectedRole);
      if (!roleVerified) {
        await _auth.signOut();
        _setError('This account is not registered as "$expectedRole".');
        return null;
      }

      // 5) Update last login
      await _updateLastLogin(user.uid, expectedRole);

      // 6) Success — set local state and return route for UI to navigate safely
      _currentUser = user;
      _safeNotify();
      final route = _getRoleDashboard(expectedRole);
      return route;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } catch (e) {
      _setError('Login failed. Please try again.');
      debugPrint('LoginProvider: Login error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ========== GOOGLE SIGN-IN ==========
  /// NOTE: returns the route to navigate on success (or null on failure).
  Future<String?> signInWithGoogle() async {
    _setLoading(true);
    clearError();

    try {
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        _setError('Google sign-in failed');
        return null;
      }

      // Create profile for new users
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createGoogleUserProfile(user);
      }

      _currentUser = user;
      _safeNotify();

      // return route for UI to navigate (UI should call context.go(route))
      return _getRoleDashboard('job_seeker');
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return null;
    } catch (e) {
      _setError('Google sign-in failed');
      debugPrint('LoginProvider: Google sign-in error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _createGoogleUserProfile(User user) async {
    try {
      final userData = {
        'personalProfile': {
          'name': user.displayName ?? '',
          'email': (user.email ?? '').trim().toLowerCase(),
          'profilePicUrl': user.photoURL ?? '',
        },
        'role': 'job_seeker',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'loginMethod': 'google',
      };

      await _firestore.collection('job_seeker').doc(user.uid).set(
        {'user_data': userData},
        SetOptions(merge: true),
      );

      // Shadow copy in users collection using the uid as doc id (avoid random duplicates)
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': (user.email ?? '').trim().toLowerCase(),
        'name': user.displayName ?? '',
        'role': 'job_seeker',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('LoginProvider: Failed to create Google user profile: $e');
    }
  }

  // ========== PASSWORD RESET ==========
  Future<bool> resetPassword(String email) async {
    if (email.trim().isEmpty) {
      _setError('Email address is required');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Failed to send reset email');
      debugPrint('LoginProvider: Password reset error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== SIGN OUT ==========
  Future<void> signOut() async {
    _setLoading(true);
    clearError();

    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _currentUser = null;
      _safeNotify();
    } catch (e) {
      _setError('Sign out failed');
      debugPrint('LoginProvider: Sign out error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ========== HELPERS ==========
  Future<void> _updateLastLogin(String uid, String role) async {
    try {
      final collection = _normalizeRole(role) == 'recruiter' ? 'recruiter' : 'job_seeker';
      // Use nested field update safe path
      await _firestore.collection(collection).doc(uid).set({
        'user_data': {
          'lastLoginAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('LoginProvider: Failed to update last login: $e');
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        _setError('No account found. Please register first.');
        break;
      case 'wrong-password':
        _setError('Incorrect password. Please try again.');
        break;
      case 'invalid-email':
        _setError('Invalid email format.');
        break;
      case 'user-disabled':
        _setError('This account has been disabled.');
        break;
      case 'too-many-requests':
        _setError('Too many attempts. Please try again later.');
        break;
      case 'network-request-failed':
        _setError('Network error. Check your connection.');
        break;
      case 'invalid-credential':
        _setError('Invalid credentials. Please check your email and password.');
        break;
      default:
        _setError(e.message ?? 'Authentication failed.');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
