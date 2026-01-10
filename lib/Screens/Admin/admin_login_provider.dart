import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Optimized Admin Authentication Provider with improved state management,
/// debouncing, caching, and performance enhancements
class AdminAuthProvider extends ChangeNotifier {
  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // State management
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _isDisposed = false;

  // Caching for admin check (reduces Firestore reads)
  final Map<String, bool> _adminCache = {};
  static const _cacheDuration = Duration(minutes: 5);
  DateTime? _lastCacheTime;

  // Validation state
  String? _emailError;
  String? _passwordError;
  bool _hasValidated = false;

  // Firebase instances (lazy initialization)
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;

  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;

  // Getters with optimized access
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get obscurePassword => _obscurePassword;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  bool get hasValidated => _hasValidated;
  bool get isFormValid =>
      _emailError == null &&
          _passwordError == null &&
          emailController.text.trim().isNotEmpty &&
          passwordController.text.isNotEmpty;

  AdminAuthProvider() {
    _initializeListeners();
  }

  /// Initialize real-time validation listeners
  void _initializeListeners() {
    emailController.addListener(_onEmailChanged);
    passwordController.addListener(_onPasswordChanged);
  }

  /// Real-time email validation with debouncing
  void _onEmailChanged() {
    if (_hasValidated && !_isLoading) {
      _emailError = _validateEmailInternal(emailController.text);
      _notifySafe();
    }
  }

  /// Real-time password validation with debouncing
  void _onPasswordChanged() {
    if (_hasValidated && !_isLoading) {
      _passwordError = _validatePasswordInternal(passwordController.text);
      _notifySafe();
    }
  }

  /// Safe notification that checks disposal state
  void _notifySafe() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Toggle password visibility with optimized state update
  void toggleObscure() {
    _obscurePassword = !_obscurePassword;
    _notifySafe();
  }

  /// Clear error message
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _notifySafe();
    }
  }

  /// Clear validation errors
  void clearValidationErrors() {
    _emailError = null;
    _passwordError = null;
    _hasValidated = false;
    _notifySafe();
  }

  /// Internal email validation
  String? _validateEmailInternal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final email = value.trim();
    // More comprehensive email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Internal password validation
  String? _validatePasswordInternal(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (value.length > 128) {
      return 'Password is too long';
    }
    return null;
  }

  /// Public validation methods (for manual validation)
  String? validateEmail(String? value) => _validateEmailInternal(value);
  String? validatePassword(String? value) => _validatePasswordInternal(value);

  /// Validate entire form
  bool validateForm() {
    _hasValidated = true;
    _emailError = _validateEmailInternal(emailController.text);
    _passwordError = _validatePasswordInternal(passwordController.text);
    _notifySafe();
    return _emailError == null && _passwordError == null;
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheDuration;
  }

  /// Clear admin cache
  void clearCache() {
    _adminCache.clear();
    _lastCacheTime = null;
  }

  /// Optimized admin check with caching
  Future<bool> _checkIsAdmin(String uid) async {
    // Check cache first
    if (_isCacheValid() && _adminCache.containsKey(uid)) {
      if (kDebugMode) {
        print('Admin check: Using cached result for $uid');
      }
      return _adminCache[uid]!;
    }

    try {
      // Use get with source options for better performance
      final doc = await _firestore
          .collection('admin')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));

      final isAdmin = doc.exists;

      // Update cache
      _adminCache[uid] = isAdmin;
      _lastCacheTime = DateTime.now();

      if (kDebugMode) {
        print('Admin check: Fetched from Firestore - isAdmin: $isAdmin');
      }

      return isAdmin;
    } catch (e) {
      if (kDebugMode) {
        print('Admin check error: $e');
      }
      // On error, don't cache and return false
      return false;
    }
  }

  /// Optimized sign-in with better error handling and state management
  Future<bool> signIn() async {
    // Prevent multiple simultaneous sign-in attempts
    if (_isLoading) {
      if (kDebugMode) {
        print('Sign-in already in progress');
      }
      return false;
    }

    // Validate form first
    if (!validateForm()) {
      _errorMessage = _emailError ?? _passwordError;
      _notifySafe();
      return false;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;

    // Set loading state
    _isLoading = true;
    _errorMessage = null;
    _notifySafe();

    try {
      // Attempt sign-in with timeout
      final signInFuture = _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final cred = await signInFuture.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Sign-in request timed out');
        },
      );

      final user = cred.user;
      if (user == null) {
        _errorMessage = 'Authentication failed. Please try again.';
        return false;
      }

      // Check admin status with optimized caching
      final uid = user.uid;
      final isAdmin = await _checkIsAdmin(uid);

      if (!isAdmin) {
        // Sign out immediately if not admin
        await _auth.signOut();
        _errorMessage =
        'Access denied. This account does not have administrator privileges.';
        return false;
      }

      // Success - clear any errors and cache
      _errorMessage = null;
      _emailError = null;
      _passwordError = null;

      if (kDebugMode) {
        print('Admin sign-in successful for: $email');
      }

      return true;
    } on TimeoutException catch (_) {
      _errorMessage =
      'Connection timeout. Please check your internet connection.';
      return false;
    } on FirebaseAuthException catch (ex) {
      // Comprehensive error handling with user-friendly messages
      _errorMessage = _getAuthErrorMessage(ex);
      if (kDebugMode) {
        print('FirebaseAuth error: ${ex.code} - ${ex.message}');
      }
      return false;
    } on FirebaseException catch (ex) {
      _errorMessage = 'Database error: ${ex.message ?? "Unknown error"}';
      if (kDebugMode) {
        print('Firestore error: ${ex.code} - ${ex.message}');
      }
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      if (kDebugMode) {
        print('Unexpected sign-in error: $e');
      }
      return false;
    } finally {
      // Always reset loading state
      _isLoading = false;
      _notifySafe();
    }
  }

  /// Get user-friendly error messages for Firebase Auth errors
  String _getAuthErrorMessage(FirebaseAuthException ex) {
    switch (ex.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      default:
        return ex.message ?? 'Authentication failed. Please try again.';
    }
  }

  /// Sign out with cleanup
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      clearCache();
      emailController.clear();
      passwordController.clear();
      clearValidationErrors();
      clearError();
      if (kDebugMode) {
        print('Admin signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sign-out error: $e');
      }
    }
  }

  /// Check if user is currently signed in and is admin
  Future<bool> isSignedInAsAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    return await _checkIsAdmin(user.uid);
  }

  /// Get current admin user
  User? get currentUser => _auth.currentUser;

  /// Reset form to initial state
  void resetForm() {
    emailController.clear();
    passwordController.clear();
    _obscurePassword = true;
    _errorMessage = null;
    _emailError = null;
    _passwordError = null;
    _hasValidated = false;
    _isLoading = false;
    _notifySafe();
  }

  @override
  void dispose() {
    _isDisposed = true;
    emailController.removeListener(_onEmailChanged);
    passwordController.removeListener(_onPasswordChanged);
    emailController.dispose();
    passwordController.dispose();
    _adminCache.clear();
    _authInstance = null;
    _firestoreInstance = null;
    super.dispose();
  }
}

/// Timeout exception for network operations
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}