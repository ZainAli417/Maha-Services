// web_routes.dart - WITH isNew CHECK FOR /dashboard
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Constant/Forget Password.dart';
import 'Constant/cv_analysis.dart';
import 'Constant/pricing.dart';
import 'Screens/Admin/admin_dashbaord.dart';
import 'Screens/Admin/admin_dashbaord2.dart';
import 'Screens/Admin/admin_login.dart';
import 'Screens/Job_Seeker/JS_Profile/JS_Profile.dart';
import 'Login.dart';
import 'Screens/Job_Seeker/job_hub.dart';
import 'Screens/Job_Seeker/job_seeker_dashboard.dart';
import 'Screens/Recruiter/LIst_of_Applicants.dart';
import 'Constant/Splash.dart';
import 'Screens/Recruiter/Recruiter_Dashbaord.dart';
import 'Screens/Recruiter/Recruiter_Shortlisting.dart';
import 'SignUp /profile_builder.dart';
import 'SignUp /signup_screen_auth.dart';

// ========== OPTIMIZED ROLE SERVICE ==========
class RoleService {
  static final _firestore = FirebaseFirestore.instance;
  static final _roleCache = <String, _CachedRole>{};
  static const _cacheExpiry = Duration(minutes: 10);

  // Deduplicate concurrent requests
  static final _pendingRequests = <String, Future<String?>>{};

  static void clearCache() {
    _roleCache.clear();
    _pendingRequests.clear();
  }

  static Future<String?> getUserRole(String uid) async {
    final cached = _roleCache[uid];
    if (cached != null && !cached.isExpired) return cached.role;

    if (_pendingRequests.containsKey(uid)) return _pendingRequests[uid];

    final future = _fetchRole(uid);
    _pendingRequests[uid] = future;

    try {
      final role = await future;
      if (role != null) _roleCache[uid] = _CachedRole(role);
      return role;
    } finally {
      _pendingRequests.remove(uid);
    }
  }

  static Future<String?> _fetchRole(String uid) async {
    try {
      final jsDoc = await _firestore.collection('job_seeker').doc(uid).get();
      if (jsDoc.exists) return 'job_seeker';

      final recDoc = await _firestore.collection('recruiter').doc(uid).get();
      if (recDoc.exists) return 'recruiter';

      final adminDoc = await _firestore.collection('admin').doc(uid).get();
      if (adminDoc.exists) return 'admin';

      final userQuery = await _firestore
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return _normalizeRole(userQuery.docs.first.data()['role']?.toString());
      }

      return null;
    } catch (e) {
      debugPrint('RoleService: error fetching role: $e');
      return null;
    }
  }

  static String? _normalizeRole(String? role) {
    if (role == null || role.isEmpty) return null;
    switch (role.toLowerCase().trim()) {
      case 'recruiter':
      case 'employer':
        return 'recruiter';
      case 'job_seeker':
      case 'jobseeker':
      case 'job seeker':
      case 'candidate':
        return 'job_seeker';
      case 'admin':
      case 'administrator':
      case 'superadmin':
        return 'admin';
      default:
        return null;
    }
  }

  // ========== NEW: CHECK isNew FIELD ==========
// ========== NEW: CHECK isNew FIELD ==========
  static Future<bool> isNewUser(String uid) async {
    try {
      // ✅ FIXED: Query by uid field, not document ID
      final userQuery = await _firestore
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        debugPrint('⚠️ isNewUser: User document not found for uid: $uid');
        return true; // Assume new if doc doesn't exist
      }

      final data = userQuery.docs.first.data();
      final isNew = data['isNew'];

      debugPrint('🔍 isNewUser check for $uid: isNew = $isNew');

      // Check if isNew is "yes" (case-insensitive)
      if (isNew is String) {
        return isNew.toLowerCase().trim() == 'yes';
      }

      // If it's a boolean
      if (isNew is bool) {
        return isNew;
      }

      // Default to true if field doesn't exist or is null
      return true;
    } catch (e) {
      debugPrint('❌ isNewUser error: $e');
      return true; // Safe default: treat as new user on error
    }
  }

}

class _CachedRole {
  final String role;
  final DateTime timestamp;

  _CachedRole(this.role) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > RoleService._cacheExpiry;
}

// ========== OPTIMIZED AUTH NOTIFIER ==========
class AuthNotifier extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;

  String? userRole;
  bool roleResolved = false;
  User? _currentUser;

  // NEW: Track if we should check isNew on next auth
  bool _shouldCheckIsNew = false;

  AuthNotifier() {
    _currentUser = _auth.currentUser;
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);

    if (_currentUser != null) {
      _resolveRole(_currentUser!.uid);
    } else {
      roleResolved = true;
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (_currentUser?.uid == user?.uid && roleResolved) {
      return;
    }

    _currentUser = user;
    roleResolved = false;

    if (user == null) {
      userRole = null;
      roleResolved = true;
      RoleService.clearCache();
      _shouldCheckIsNew = false;
    } else {
      await _resolveRole(user.uid);
    }

    notifyListeners();
  }

  Future<void> _resolveRole(String uid) async {
    try {
      userRole = await RoleService.getUserRole(uid);

      if (userRole == null) {
        await Future.delayed(const Duration(milliseconds: 800));
        userRole = await RoleService.getUserRole(uid);
      }

      if (userRole == null) {
        debugPrint('AuthNotifier: role resolution failed → signing out');
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint('AuthNotifier: error resolving role: $e');
      userRole = null;
    } finally {
      roleResolved = true;
    }
  }

  // NEW: Method to trigger isNew check after login/signup
  void markForIsNewCheck() {
    _shouldCheckIsNew = true;
  }

  bool get shouldCheckIsNew => _shouldCheckIsNew;

  void clearIsNewCheck() {
    _shouldCheckIsNew = false;
  }

  Future<void> refreshRole() async {
    final user = _auth.currentUser;
    if (user == null) return;

    RoleService.clearCache();
    roleResolved = false;
    notifyListeners();

    await _resolveRole(user.uid);
    notifyListeners();
  }

  bool get isLoggedIn => _currentUser != null;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ========== ROUTE CONFIGURATION ==========
class RouteConfig {
  static const _publicPaths = {
    '/',
    '/login',
    '/register',
    '/recover-password',
    '/pricing',
    '/admin',
  };

  static const _roleRoutes = {
    'admin': {'/admin_dashboard', '/admin_dashboard2'},
    'recruiter': {
      '/recruiter-dashboard',
      '/job-posting',
      '/view-applications',
      '/shortlisting'
    },
    'job_seeker': {
      '/dashboard',
      '/profile',
      '/download-cv',
      '/ai-tools',
      '/applied-jobs',
      '/job-hub',
      '/profile-builder'
    },
  };

  static const _roleDashboards = {
    'admin': '/admin_dashboard',
    'recruiter': '/recruiter-dashboard',
    'job_seeker': '/dashboard',
  };

  static bool isPublicPath(String? location) {
    if (location == null) return false;
    final path = _extractPath(location);
    return _publicPaths.contains(path);
  }

  static bool isAllowedForRole(String? location, String role) {
    if (location == null) return false;
    final path = _extractPath(location);
    final allowedPaths = _roleRoutes[role];
    if (allowedPaths == null) return false;

    if (allowedPaths.contains(path)) return true;
    return allowedPaths.any((allowed) => path.startsWith(allowed));
  }

  static String getDashboard(String role) => _roleDashboards[role] ?? '/';

  static String _extractPath(String location) {
    final uri = Uri.tryParse(location);
    if (uri == null) return location;
    final path = uri.path;
    return (path.length > 1 && path.endsWith('/'))
        ? path.substring(0, path.length - 1)
        : path;
  }
}

// ========== ROUTER WITH isNew CHECK ==========
final GoRouter router = GoRouter(
  initialLocation: '/',
  refreshListenable: _authNotifier,
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final role = _authNotifier.userRole;
    final roleResolved = _authNotifier.roleResolved;
    final location = state.uri.path;

    debugPrint('🔀 Redirect: $location | User: ${user?.uid} | Role: $role | Resolved: $roleResolved');

    // ========== NEW: CHECK isNew IMMEDIATELY AFTER LOGIN/SIGNUP ==========
    if (isLoggedIn && roleResolved && role == 'job_seeker' && _authNotifier.shouldCheckIsNew) {
      debugPrint('🎯 Post-auth isNew check triggered...');

      final isNew = await RoleService.isNewUser(user.uid);
      _authNotifier.clearIsNewCheck(); // Clear the flag

      if (isNew) {
        debugPrint('   ✅ NEW user detected → routing to /profile-builder');
        return '/profile-builder';
      } else {
        debugPrint('   ✅ EXISTING user detected → routing to /dashboard');
        return '/dashboard';
      }
    }

    // ========== SPECIAL CHECK FOR /dashboard ==========
    if (location == '/dashboard' && isLoggedIn && roleResolved && role == 'job_seeker') {
      debugPrint('🎯 /dashboard accessed - checking isNew field...');

      final isNew = await RoleService.isNewUser(user.uid);

      if (isNew) {
        debugPrint('   ✅ User is NEW (isNew=yes) → redirecting to /profile-builder');
        return '/profile-builder';
      } else {
        debugPrint('   ✅ User is EXISTING (isNew=no) → allowing /dashboard access');
        return null; // Allow access to dashboard
      }
    }

    // SPECIAL CASE: /admin route
    if (location == '/admin') {
      if (!isLoggedIn) {
        debugPrint('   ✓ /admin - showing login (not authenticated)');
        return null;
      }

      if (!roleResolved) {
        debugPrint('   ⏳ /admin - waiting for role resolution');
        return null;
      }

      if (role == 'admin') {
        debugPrint('   ↪ /admin - redirecting admin to dashboard');
        return '/admin_dashboard';
      }

      debugPrint('   ↪ /admin - non-admin user, redirecting to their dashboard');
      return RouteConfig.getDashboard(role ?? 'job_seeker');
    }

    // Handle other public paths
// Handle other public paths
    if (RouteConfig.isPublicPath(location)) {
      if (isLoggedIn && roleResolved && role != null) {
        debugPrint(
            '   ↪ Public path but authenticated - checking isNew before redirect');

        // ✅ Check isNew for job_seekers before redirecting
        if (role == 'job_seeker') {
          final isNew = await RoleService.isNewUser(user.uid);

          if (isNew) {
            debugPrint('   ✅ NEW user → redirecting to /profile-builder');
            return '/profile-builder';
          } else {
            debugPrint('   ✅ EXISTING user → redirecting to /dashboard');
            return '/dashboard';
          }
        }

        // For other roles (recruiter, admin), use default dashboard
        return RouteConfig.getDashboard(role);
      }
      return null;
    }
    // Require authentication for protected routes
    if (!isLoggedIn) {
      debugPrint('   ↪ Protected route, not authenticated - redirecting to /');
      return '/';
    }

    // Wait for role resolution
    if (!roleResolved) {
      debugPrint('   ⏳ Waiting for role resolution');
      return null;
    }

    // Handle null role
    if (role == null) {
      debugPrint('   ⚠ Null role detected - forcing logout');
      FirebaseAuth.instance.signOut();
      return '/';
    }

    // Enforce role-based access
    if (!RouteConfig.isAllowedForRole(location, role)) {
      debugPrint('   ↪ Unauthorized access - redirecting to dashboard');
      return RouteConfig.getDashboard(role);
    }

    return null;
  },
  routes: [
    // PUBLIC
    GoRoute(
      path: '/',
      pageBuilder: (c, s) => _buildPage(
        child: const SplashScreen(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (c, s) => _buildPage(
        child: const JobSeekerLoginScreen(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (c, s) => _buildPage(
        child: const SignUp_Screen(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/recover-password',
      pageBuilder: (c, s) => _buildPage(
        child: const ForgotPasswordScreen(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/pricing',
      pageBuilder: (c, s) => _buildPage(
        child: const PremiumPricingPage(),
        context: c,
        state: s,
      ),
    ),

    // ADMIN
    GoRoute(
      path: '/admin',
      pageBuilder: (c, s) => _buildPage(
        child: const AdminLoginScreen(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/admin_dashboard',
      pageBuilder: (c, s) => _buildPage(
        child: const AdminDashboardScreen(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/admin_dashboard2',
      pageBuilder: (c, s) => _buildPage(
        child: const AdminDashboardScreen2(),
        context: c,
        state: s,
      ),
    ),

    // JOB SEEKER ROUTES (removed ShellRoute for simpler flow)
    GoRoute(
      path: '/dashboard',
      pageBuilder: (c, s) => _buildPage(
        child: const job_seeker_dashboard(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/profile-builder',
      pageBuilder: (c, s) => _buildPage(
        child: const ProfileBuilderScreen(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (c, s) => _buildPage(
        child: const ProfileScreen_NEW(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/ai-tools',
      pageBuilder: (c, s) => _buildPage(
        child: CVAnalysisScreen(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/job-hub',
      pageBuilder: (c, s) => _buildPage(
        child: job_hub(),
        context: c,
        state: s,
      ),
    ),

    // RECRUITER
    GoRoute(
      path: '/recruiter-dashboard',
      pageBuilder: (c, s) => _buildPage(
        child: const Dashboard_Recruiter(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/shortlisting',
      pageBuilder: (c, s) => _buildPage(
        child: const Shortlisting(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/view-applications',
      pageBuilder: (c, s) => _buildPage(
        child: const ApplicantsScreen(),
        context: c,
        state: s,
      ),
    ),
  ],
);

// ========== PAGE TRANSITIONS ==========
CustomTransitionPage<T> _buildPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

// ========== AUTH NOTIFIER INSTANCE ==========
final _authNotifier = AuthNotifier();
