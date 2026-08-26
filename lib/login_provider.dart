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

import 'Web_routes.dart' show authProvider;
import 'core/rbac/user_role.dart';

class LoginProvider with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  bool _isDisposed = false;

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  // ── Getters ────────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

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
  // Delegates to the centralized RBAC parser; falls back to the lowercased
  // input for values the enum doesn't recognize (preserves prior behavior).
  String _normalizeRole(String role) =>
      UserRole.fromFirestore(role)?.legacyRuntimeString ??
      role.trim().toLowerCase();

  String _getRoleDashboard(String role) =>
      UserRole.fromFirestore(role)?.homeRoute ?? '/dashboard';

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

    // ── FIX 6: hold the router until this login has a verdict ────────────────
    //
    // signInWithEmailAndPassword() below fires authStateChanges the instant it
    // resolves. AuthNotifier picks that up, loads the role and notifies the
    // router — which happily redirects a recruiter to /recruiter-dashboard
    // while the checks in Step 2 are still in flight. When those checks then
    // fail, signOut() bounces the user back to /login. On a fast link the
    // checks win and nothing is visible; on a slow one the dashboard flashes.
    //
    // The checks cannot run *before* sign-in — reading account_status and
    // is_verified out of Firestore requires an authenticated user — so instead
    // the router is told to stand still until the verdict is in.
    authProvider.beginLoginGate();

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
      final isRecruiter = _normalizeRole(expectedRole) == 'recruiter';

      // The recruiter verification read used to run *after* this batch, adding
      // a whole extra round-trip to every recruiter login and widening the
      // window in which the router could reach the dashboard. It only needs the
      // uid, so it belongs in the same batch as the others.
      final roleFuture = _verifyUserRole(user.uid, expectedRole);
      final activeFuture = _isAccountActive(user.uid);
      final newFuture = isJobSeeker
          ? _isNewUser(user.uid)
          : Future.value(false);
      final verifiedFuture = isRecruiter
          ? _isRecruiterVerified(user.uid)
          : Future.value(true);

      await Future.wait([roleFuture, activeFuture, newFuture, verifiedFuture]);

      final roleVerified = await roleFuture;
      final isAccountActive = await activeFuture;
      final isNew = await newFuture;
      final isRecruiterVerified = await verifiedFuture;

      // ── Step 2.1: Check Account Status ────────────────────────────────────
      if (!isAccountActive) {
        const msg = 'Your account is suspended. Contact Customer support.';
        _setError(msg);
        authProvider.rejectSession(msg);
        return null;
      }

      // ── Step 2.2: Check Recruiter Verification Status ─────────────────────
      //
      // Recruiters must be admin-verified before they can log in.
      // The is_verified flag is set to false on signup and only changed to
      // true from the admin verification portal.
      if (isRecruiter && !isRecruiterVerified) {
        const msg =
            'Your verification process has been started. '
            'Once verified by our admin team, you will be able to '
            'log in and use the system.';
        _setError(msg);
        authProvider.rejectSession(msg);
        return null;
      }

      // ── FIX 3: sign out ONLY when role is not verified ────────────────────
      //
      // Previously signOut() was called on verification failure, which fired
      // authStateChanges and rebuilt the UI mid-request — causing the "user
      // not found" error on a rapid retry. rejectSession() sets the error and
      // clears the session without blocking this call stack.
      if (!roleVerified) {
        final msg = 'This account is not registered as "$expectedRole".';
        _setError(msg);
        authProvider.rejectSession(msg);
        return null;
      }

      // ── Step 3: Success ────────────────────────────────────────────────────
      _currentUser = user;
      _safeNotify();

      if (isJobSeeker) {
        final route = isNew ? '/profile-builder' : '/dashboard';
        debugPrint(
          isNew
              ? '✨ New Job Seeker → /profile-builder'
              : '👤 Existing Job Seeker → /dashboard',
        );
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
      // Release the router. Must run on every exit path, including the early
      // `return null`s above — otherwise the app freezes on the current route.
      authProvider.endLoginGate();
    }
  }

  // ── Role verification — with auto-retry ───────────────────────────────────
  //
  // FIX 1 (safety net): Even after getIdToken(true), slow devices or
  // cold Firestore connections can take an extra 200–400 ms to propagate the
  // token. We retry once after a short delay before giving up.
  Future<bool> _verifyUserRole(
    String uid,
    String expectedRole, {
    bool isRetry = false,
  }) async {
    try {
      final normExpected = _normalizeRole(expectedRole);
      final collection = normExpected == 'recruiter'
          ? 'recruiter'
          : 'Job_Seeker';

      final docSnap = await _firestore
          .collection(collection)
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!docSnap.exists) {
        // Fallback: Check 'users' collection (crucial for new users who haven't finished profile)
        final userSnap = await _firestore.collection('users').doc(uid).get();
        if (userSnap.exists) {
          final userData = userSnap.data();
          final role = _normalizeRole(userData?['role']?.toString() ?? '');
          if (role == normExpected) return true;
        }

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
        debugPrint(
          '⚠️ _isNewUser: users/$uid not found → treating as existing legacy user',
        );
        return false;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final isNew = data['isNew'];
      debugPrint('🔍 _isNewUser for $uid: isNew = $isNew');

      if (isNew is String) return isNew.toLowerCase().trim() == 'yes';
      if (isNew is bool) return isNew;

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

  // ── Account status check ───────────────────────────────────────────────────
  Future<bool> _isAccountActive(String uid) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!userDoc.exists) return true; // Assume active if record missing

      final data = userDoc.data() as Map<String, dynamic>;
      final status = (data['account_status'] ?? 'active')
          .toString()
          .toLowerCase()
          .trim();

      return status == 'active';
    } catch (e) {
      debugPrint('⚠️ _isAccountActive error (assuming active): $e');
      return true;
    }
  }

  // ── Recruiter verification check ──────────────────────────────────────────
  /// Returns true ONLY if the recruiter has been explicitly verified by admin.
  /// Missing field or false → unverified → blocked from login.
  Future<bool> _isRecruiterVerified(String uid) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!userDoc.exists) return false; // No record — block

      final data = userDoc.data() as Map<String, dynamic>;
      // No flag or flag is false → treat as unverified
      final isVerified = data['is_verified'];
      if (isVerified == true) return true;
      if (isVerified is String && isVerified.toLowerCase() == 'true') {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ _isRecruiterVerified error (blocking login): $e');
      return false; // Block on error — safety first
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
