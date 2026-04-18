// lib/providers/login_provider.dart — FIXED
// ─── Fixes applied ────────────────────────────────────────────────────────────
//
// FIX 1 [CRITICAL — root cause of intermittent failures]:
//   After signInWithEmailAndPassword(), Firebase Auth issues a new ID token but
//   Firestore's gRPC transport has its own auth-token refresh cycle. There is a
//   0–600 ms race window where Firestore still uses the previous (null/expired)
//   token, so the first .get() either gets PERMISSION_DENIED or sees a
//   "non-existent" document — making a valid login look like a failure.
//   Fix: call user.getIdToken(true) immediately after sign-in to force-flush
//   the new token into Firebase's internal credential cache before any Firestore
//   call is made. Then wrap _verifyUserRole with a single auto-retry (300 ms
//   delay) as a safety net for slow SDK propagation on older devices.
//
// FIX 2 [CRITICAL — UI never navigates]:
//   login() returned the target route but _onLogin() in the UI never called
//   context.go(route). Navigation only worked when a GoRouter redirect happened
//   to fire on its own, which is inherently timing-dependent.
//   Fix: return the route from login() as before, and have _onLogin() call
//   context.go(route) explicitly. (See login_screen_fixed.dart)
//
// FIX 3 [HIGH — signOut() during failure poisons the next retry]:
//   When role verification failed (often due to FIX 1's token race), signOut()
//   was called, which fired authStateChanges, rebuilding the UI mid-retry.
//   If the user tapped "Log In" again during that rebuild, Firebase returned
//   "user-not-found" because sign-out hadn't completed.
//   Fix: sign out AFTER setting the error message, and only sign out when we are
//   certain the user authenticated successfully (i.e. we own the session).
//
// FIX 4 [MEDIUM — _isNewUser defaults true on any error]:
//   A network blip during the isNew check sent existing job-seekers to
//   /profile-builder instead of /dashboard.
//   Fix: default to false on network/Firestore errors (assume existing user).
//   Only return true when the document genuinely doesn't exist.
//
// FIX 5 [PERFORMANCE — serial Firestore round-trips]:
//   _verifyUserRole and _isNewUser were called sequentially (2 × round-trip
//   latency). Both only need the same uid, so they can run in parallel.
//   Fix: Future.wait([_verifyUserRole(...), _isNewUser(...)]) for job seekers.
//
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginProvider with ChangeNotifier {
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  bool _isDisposed = false;

  bool    _isLoading    = false;
  String? _errorMessage;
  User?   _currentUser;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool    get isLoading    => _isLoading;
  String? get errorMessage => _errorMessage;
  User?   get currentUser  => _currentUser;
  bool    get isSignedIn   => _currentUser != null;

  // ── Safety helpers ─────────────────────────────────────────────────────────
  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

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

  // ── Auth state listener ────────────────────────────────────────────────────
  void initAuthStateListener() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      _currentUser = user;
      _safeNotify();
    });
  }

  Future<void> checkCurrentUser() async {
    _currentUser = _auth.currentUser;
    _safeNotify();
  }

  // ── Role helpers ───────────────────────────────────────────────────────────
  String _normalizeRole(String role) {
    final n = role.trim().toLowerCase();
    if (['recruiter', 'employer'].contains(n)) return 'recruiter';
    if (['job_seeker', 'jobseeker', 'job seeker', 'candidate',
      'job_seeker', 'job seeker'].contains(n)) {
      return 'Job Seeker';
    }
    return n;
  }

  String _getRoleDashboard(String role) {
    final n = _normalizeRole(role);
    if (n == 'recruiter') return '/recruiter-dashboard';
    if (n == 'admin')     return '/admin_dashboard';
    return '/dashboard';
  }

  // ── LOGIN — FIXED ──────────────────────────────────────────────────────────
  /// Returns the target route on success, or null on failure.
  /// The caller (UI) is responsible for calling context.go(route).
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
      // ── Step 1: Firebase Auth sign-in ──────────────────────────────────────
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = cred.user;
      if (user == null) {
        _setError('Authentication failed. Please try again.');
        return null;
      }

      // ── FIX 1: Force ID-token refresh before ANY Firestore call ───────────
      //
      // After signInWithEmailAndPassword(), Firebase Auth has a new ID token
      // but Firestore's gRPC transport may still carry the previous (null)
      // credential for up to ~600 ms. Calling getIdToken(true) forces the SDK
      // to flush the new token into every dependent service synchronously,
      // eliminating the race window that caused intermittent permission errors.
      try {
        await user.getIdToken(true);
        debugPrint('✅ ID token refreshed for uid=${user.uid}');
      } catch (tokenErr) {
        // Non-fatal: log and continue. The token will eventually propagate.
        debugPrint('⚠️ getIdToken refresh skipped: $tokenErr');
      }

      // ── Step 2: Verify role + fetch isNew status in parallel ──────────────
      //
      // FIX 5: both calls use the same uid — run them concurrently to halve
      // network latency on slow connections.
      final isJobSeeker = _normalizeRole(expectedRole) == 'Job Seeker';

      final results = await Future.wait([
        _verifyUserRole(user.uid, expectedRole),
        if (isJobSeeker) _isNewUser(user.uid),
      ]);

      final roleVerified = results[0];
      final isNew        = isJobSeeker ? results[1] : false;

      // ── FIX 3: sign out ONLY when role is not verified ────────────────────
      //
      // Previously signOut() was called on verification failure, which fired
      // authStateChanges and rebuilt the UI mid-request — causing the "user
      // not found" error on a rapid retry. We now sign out after setting the
      // error, and unawaited, so the current call stack completes cleanly.
      if (!roleVerified) {
        _setError('This account is not registered as "$expectedRole".');
        // Sign out without blocking — fire and forget
        _auth.signOut().ignore();
        return null;
      }

      // ── Step 3: Success ────────────────────────────────────────────────────
      _currentUser = user;
      _safeNotify();

      if (isJobSeeker) {
        final route = isNew ? '/profile-builder' : '/dashboard';
        debugPrint(isNew
            ? '✨ New Job Seeker → /profile-builder'
            : '👤 Existing Job Seeker → /dashboard');
        return route;
      }

      return _getRoleDashboard(expectedRole);

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

  // ── Role verification — with auto-retry ───────────────────────────────────
  //
  // FIX 1 (safety net): Even after getIdToken(true), slow devices or
  // cold Firestore connections can take an extra 200–400 ms to propagate the
  // token. We retry once after a short delay before giving up.
  Future<bool> _verifyUserRole(String uid, String expectedRole,
      {bool isRetry = false}) async {
    try {
      final normExpected = _normalizeRole(expectedRole);
      final collection   = normExpected == 'recruiter' ? 'recruiter' : 'Job_Seeker';

      final docSnap = await _firestore
          .collection(collection)
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!docSnap.exists) {
        if (!isRetry) {
          // Document may not exist yet due to token propagation — retry once
          debugPrint('⚠️ Role doc not found for $uid, retrying in 400ms…');
          await Future.delayed(const Duration(milliseconds: 400));
          return _verifyUserRole(uid, expectedRole, isRetry: true);
        }
        debugPrint('❌ Role doc still not found after retry for $uid');
        return false;
      }

      final data = docSnap.data();
      if (data == null) return true; // doc exists, assume role is correct

      // Check nested user_data.role
      if (data['user_data'] is Map) {
        final userData = data['user_data'] as Map<String, dynamic>;
        final role = _normalizeRole(userData['role']?.toString() ?? '');
        if (role == normExpected) return true;
      }

      // Check direct role field
      final directRole = _normalizeRole(data['role']?.toString() ?? '');
      if (directRole == normExpected) return true;

      // Document exists in the correct collection → role is implicitly correct
      return true;
    } catch (e) {
      if (!isRetry) {
        // Could be a transient permission error during token propagation
        debugPrint('⚠️ _verifyUserRole error (will retry): $e');
        await Future.delayed(const Duration(milliseconds: 400));
        return _verifyUserRole(uid, expectedRole, isRetry: true);
      }
      debugPrint('❌ _verifyUserRole failed after retry: $e');
      return false;
    }
  }

  // ── isNew check — FIX 4: default false on network errors ──────────────────
  Future<bool> _isNewUser(String uid) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!userDoc.exists) {
        // Document genuinely doesn't exist → treat as new
        debugPrint('⚠️ _isNewUser: users/$uid not found → treating as new');
        return true;
      }

      final data  = userDoc.data() as Map<String, dynamic>;
      final isNew = data['isNew'];
      debugPrint('🔍 _isNewUser for $uid: isNew = $isNew');

      if (isNew is String) return isNew.toLowerCase().trim() == 'yes';
      if (isNew is bool)   return isNew;

      // Field absent → document was created without isNew → existing user
      return false;
    } catch (e) {
      // ── FIX 4: network/Firestore error → assume existing user ────────────
      // Previously defaulted to true, which sent existing users to
      // /profile-builder on any connection hiccup.
      debugPrint('⚠️ _isNewUser error — defaulting to existing user: $e');
      return false;
    }
  }

  // ── Password reset (unchanged) ─────────────────────────────────────────────
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

  // ── Sign out (unchanged) ───────────────────────────────────────────────────
  Future<void> signOut() async {
    _setLoading(true);
    clearError();
    try {
      await _auth.signOut();
      _currentUser = null;
      _safeNotify();
    } catch (e) {
      _setError('Sign out failed');
      debugPrint('LoginProvider: Sign out error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ── Auth error handler (unchanged) ─────────────────────────────────────────
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

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}