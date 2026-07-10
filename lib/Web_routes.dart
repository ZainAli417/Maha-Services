import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Your existing imports
import 'core/rbac/user_role.dart';
import 'Constant/Forget Password.dart';
import 'Constant/cv_analysis.dart';
import 'Constant/pricing.dart';
import 'Screens/Admin/admin_wrapper.dart';
import 'Screens/Admin/admin_login.dart';
import 'Screens/Job_Seeker/JS_Profile/JS_Profile.dart';
import 'Login.dart';
import 'Screens/Job_Seeker/job_hub.dart';
import 'Screens/Job_Seeker/job_seeker_dashboard.dart';
import 'Screens/Job_Seeker/saved_jobs_screen.dart';
import 'Screens/Recruiter/Job_Applicant_Tracker.dart';
import 'Constant/Splash.dart';
import 'Screens/Recruiter/Recruiter_Dashbaord.dart';
import 'Screens/Recruiter/Recruiter_Shortlisting.dart';
import 'Screens/Recruiter/Request_Box.dart';
import 'Screens/Recruiter/archived_jobs_screen.dart';
import 'SignUp /profile_builder.dart';
import 'SignUp /signup_screen_auth.dart';
import 'Screens/Recruiter/post_a_job_form.dart';
import 'Screens/Job_Seeker/js_settings_screen.dart';

// ========== 1. ROBUST DATA SERVICE (Logic from Code A) ==========
class RoleService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> fetchUserData(String uid) async {
    try {
      // OPTIMIZATION: Run all 4 collection lookups in parallel instead of
      // sequentially — cuts latency by ~75% on cold starts.
      final results = await Future.wait([
        _firestore.collection('Job_Seeker').doc(uid).get(),
        _firestore.collection('recruiter').doc(uid).get(),
        _firestore.collection('admin').doc(uid).get(),
        _firestore.collection('users').doc(uid).get(),
      ]);

      final jsDoc = results[0];
      final recDoc = results[1];
      final adminDoc = results[2];
      final userDoc = results[3];

      String? role;
      bool isNew = false;
      String? rawRole; // exact users.role string, for precise UserRole parsing

      // 3. Resolve Role from specific collections
      if (jsDoc.exists) {
        role = 'Job Seeker';
      } else if (recDoc.exists) {
        role = 'recruiter';
      } else if (adminDoc.exists) {
        role = 'admin';
      }

      String? status;
      // 4. Resolve isNew and Backup Role from 'users' collection
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        rawRole = userData['role']?.toString();
        status = (userData['account_status'] ?? 'active')
            .toString()
            .toLowerCase()
            .trim();

        // Resolve isNew status
        final rawIsNew = userData['isNew'];
        if (rawIsNew is String) {
          isNew = rawIsNew.toLowerCase().trim() == 'yes';
        } else if (rawIsNew is bool) {
          isNew = rawIsNew;
        } else {
          isNew =
              false; // Legacy users without the flag are treated as existing.
        }

        // Backup role resolution if not found in specific collections
        role ??= _normalizeRole(userData['role']?.toString());
      }
      // Fall back to the collection-derived runtime string when users.role
      // is absent (both are parseable by UserRole.fromFirestore).
      rawRole ??= role;

      debugPrint(
        '✅ RoleService: UID=$uid, Role=$role, isNew=$isNew, Status=$status',
      );
      return {'role': role, 'rawRole': rawRole, 'isNew': isNew, 'status': status};
    } catch (e) {
      debugPrint('❌ RoleService Error: $e');
      return {'role': null, 'rawRole': null, 'isNew': false, 'status': 'error'};
    }
  }

  // Delegates to the centralized RBAC parser. Returns the legacy runtime
  // string the router branches on ('recruiter' / 'Job Seeker' / 'admin'), or
  // null for unknown input. Recruitment-agent aliases now collapse into the
  // recruiter runtime string; super-admin into 'admin'.
  static String? _normalizeRole(String? role) =>
      UserRole.fromFirestore(role)?.legacyRuntimeString;
}

// ========== 2. AUTH STATE PROVIDER (Architecture from Code B) ==========
class AuthNotifier extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? user;
  String? role;
  String? _rawRole;
  bool isNewUser = false;
  bool isInitialized = false;

  /// The precise role enum (distinguishes super-admin and recruitment-agent),
  /// parsed from the raw stored role. Prefer this over the legacy [role]
  /// string for RBAC/permission checks.
  UserRole? get roleEnum => UserRole.fromFirestore(_rawRole);
  bool _isFetching = false;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  int _authVersion = 0;

  AuthNotifier() {
    _authSub = _auth.authStateChanges().listen(_handleAuthChange);
  }

  Future<void> _handleAuthChange(User? newUser) async {
    final version = ++_authVersion;
    _isFetching = true;
    await _userDocSub?.cancel();
    _userDocSub = null;

    if (newUser == null) {
      user = null;
      role = null;
      _rawRole = null;
      isNewUser = false;
      isInitialized = true;
      _isFetching = false;
    } else {
      debugPrint('🔄 Fetching role data for: ${newUser.uid}');

      final data = await RoleService.fetchUserData(newUser.uid);
      if (version != _authVersion) return;

      _applyUserData(newUser, data);

      _userDocSub = _firestore
          .collection('users')
          .doc(newUser.uid)
          .snapshots(includeMetadataChanges: true)
          .listen(
            (snapshot) async {
              if (version != _authVersion) return;
              if (!snapshot.exists) {
                final fallback = await RoleService.fetchUserData(newUser.uid);
                if (version == _authVersion) _applyUserData(newUser, fallback);
                return;
              }

              final userData = snapshot.data()!;
              _applyUserData(newUser, {
                'role': RoleService._normalizeRole(
                  userData['role']?.toString(),
                ),
                'rawRole': userData['role']?.toString(),
                'isNew': _parseIsNew(userData['isNew']),
                'status': (userData['account_status'] ?? 'active')
                    .toString()
                    .toLowerCase()
                    .trim(),
              });
            },
            onError: (e) {
              debugPrint('❌ AuthNotifier user stream error: $e');
            },
          );
    }
    notifyListeners();
  }

  bool _parseIsNew(dynamic raw) {
    if (raw is String) return raw.toLowerCase().trim() == 'yes';
    if (raw is bool) return raw;
    return false;
  }

  void _applyUserData(User newUser, Map<String, dynamic> data) {
    final status = data['status']?.toString().toLowerCase() ?? 'active';

    if (status != 'active' && status != 'error') {
      debugPrint(
        '🚫 Suspended account detected in AuthNotifier, signing out...',
      );
      user = null;
      role = null;
      _rawRole = null;
      isNewUser = false;
      isInitialized = true;
      _isFetching = false;
      _auth.signOut().ignore();
    } else {
      user = newUser;
      role = data['role'];
      _rawRole = data['rawRole'] as String? ?? data['role'] as String?;
      isNewUser = data['isNew'] == true;
      isInitialized = true;
      _isFetching = false;
      debugPrint('✅ Auth State Updated: role=$role, isNew=$isNewUser');
    }
    notifyListeners();
  }

  // ✅ NEW: Helper to check if we should wait
  bool get shouldWait => _isFetching || !isInitialized;

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}

final authProvider = AuthNotifier();

// ========== 3. CLEAN ROUTE CONFIG ==========
class RouteConfig {
  static const publicPaths = {
    '/',
    '/login',
    '/register',
    '/recover-password',
    '/pricing',
    '/admin',
  };
  static const jobSeekerPaths = {
    '/dashboard',
    '/profile-builder',
    '/profile',
    '/ai-tools',
    '/job-hub',
    '/saved-jobs',
    '/js-settings',
  };
  static const recruiterPaths = {
    '/recruiter-dashboard',
    '/shortlisting',
    '/job-application-tracker',
    '/request-box',
    '/archived-jobs',
    '/post-job',
  };
  static const loggedInRedirectPaths = {
    '/',
    '/login',
    '/register',
    '/recover-password',
    '/admin',
  };

  static String getHome(String? role) {
    if (role == 'admin') return '/admin_dashboard';
    if (role == 'recruiter') return '/recruiter-dashboard';
    return '/dashboard';
  }
}

// ========== 4. THE ULTIMATE ROUTER ==========
final GoRouter router = GoRouter(
  initialLocation: kIsWeb ? '/' : '/login',
  refreshListenable: authProvider,
  redirect: (context, state) {
    final location = state.uri.path;

    debugPrint(
      '🔀 Router Check: $location | Init: ${authProvider.isInitialized} | User: ${authProvider.user?.uid} | Role: ${authProvider.role}',
    );

    // ✅ CRITICAL FIX: Wait for BOTH initialization AND data fetching
    if (authProvider.shouldWait) {
      debugPrint('⏳ Waiting for auth state to settle...');
      return null; // Don't redirect while fetching
    }

    final isLoggedIn = authProvider.user != null;
    final isPublic = RouteConfig.publicPaths.contains(location);

    // 2. Unauthenticated Flow
    if (!isLoggedIn) {
      debugPrint('🚫 Not logged in, location: $location');
      if (location == '/admin') return null; // Allow admin login page
      return isPublic ? null : '/login';
    }

    // 3. Authenticated Flow
    final role = authProvider.role;

    debugPrint('✅ Logged in: role=$role, location=$location');

    // ✅ IMPORTANT: Give role data a moment to settle after login
    if (role == null) {
      debugPrint('⚠️ No role found yet, staying put...');
      return null; // Wait for role to be fetched
    }

    // A. New User Logic (Job Seeker ONLY)
    if (role == 'Job Seeker' && authProvider.isNewUser) {
      if (location != '/profile-builder') {
        debugPrint('➡️ Redirecting new job seeker to profile builder');
        return '/profile-builder';
      }
      return null;
    }

    // B. Prevent New Users going to Dashboard
    if (role == 'Job Seeker' &&
        !authProvider.isNewUser &&
        location == '/profile-builder') {
      debugPrint('➡️ Completed profile, going to dashboard');
      return '/dashboard';
    }

    // C. Logged in users trying to hit auth/landing routes
    if (RouteConfig.loggedInRedirectPaths.contains(location)) {
      debugPrint('➡️ Already logged in, redirecting to home');
      return RouteConfig.getHome(role);
    }

    // D. Admin Guard
    if (location.startsWith('/admin_') && role != 'admin') {
      debugPrint('🚫 Non-admin trying to access admin route');
      return RouteConfig.getHome(role);
    }

    if (RouteConfig.recruiterPaths.contains(location) && role != 'recruiter') {
      debugPrint('🚫 Non-recruiter trying to access recruiter route');
      return RouteConfig.getHome(role);
    }

    if (RouteConfig.jobSeekerPaths.contains(location) && role != 'Job Seeker') {
      debugPrint('🚫 Non-job seeker trying to access job seeker route');
      return RouteConfig.getHome(role);
    }

    debugPrint('✅ Staying at: $location');
    return null; // Stay where you are
  },
  routes: [
    GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
    GoRoute(
      path: '/login',
      pageBuilder: (c, s) => _fadePage(const JobSeekerLoginScreen(), s),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (c, s) => _fadePage(const SignUp_Screen(), s),
    ),
    GoRoute(
      path: '/recover-password',
      pageBuilder: (c, s) => _fadePage(const ForgotPasswordScreen(), s),
    ),
    GoRoute(
      path: '/pricing',
      pageBuilder: (c, s) => _fadePage(const PremiumPricingPage(), s),
    ),

    // Admin
    GoRoute(
      path: '/admin',
      pageBuilder: (c, s) => _fadePage(const AdminLoginScreen(), s),
    ),
    GoRoute(
      path: '/admin_dashboard',
      pageBuilder: (c, s) => _fadePage(const AdminDashboardScreen(), s),
    ),

    // Job Seeker
    GoRoute(
      path: '/dashboard',
      pageBuilder: (c, s) => _fadePage(const job_seeker_dashboard(), s),
    ),
    GoRoute(
      path: '/profile-builder',
      pageBuilder: (c, s) => _fadePage(const ProfileBuilderScreen(), s),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (c, s) => _fadePage(const ProfileScreen_NEW(), s),
    ),
    GoRoute(
      path: '/ai-tools',
      pageBuilder: (c, s) => _fadePage(CVAnalysisScreen(), s),
    ),
    GoRoute(path: '/job-hub', pageBuilder: (c, s) => _fadePage(job_hub(), s)),
    GoRoute(
      path: '/saved-jobs',
      pageBuilder: (c, s) => _fadePage(const SavedJobsScreen(), s),
    ),
    GoRoute(
      path: '/js-settings',
      pageBuilder: (c, s) => _fadePage(const JSSettingsScreen(), s),
    ),

    // Recruiter
    GoRoute(
      path: '/recruiter-dashboard',
      pageBuilder: (c, s) => _fadePage(const Dashboard_Recruiter(), s),
    ),

    GoRoute(
      path: '/shortlisting',
      pageBuilder: (c, s) => _fadePage(const Shortlisting(), s),
    ),
    GoRoute(
      path: '/job-application-tracker',
      pageBuilder: (c, s) => _fadePage(const Job_Applicant_Tracker(), s),
    ),
    GoRoute(
      path: '/request-box',
      pageBuilder: (c, s) => _fadePage(const RequestBoxScreen(), s),
    ),
    GoRoute(
      path: '/archived-jobs',
      pageBuilder: (c, s) => _fadePage(const ArchivedJobsScreen(), s),
    ),
    GoRoute(
      path: '/post-job',
      pageBuilder: (c, s) => _fadePage(const PostJobScreen(), s),
    ),
  ],
);

CustomTransitionPage _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
