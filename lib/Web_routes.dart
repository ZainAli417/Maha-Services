// web_routes.dart - OPTIMIZED VERSION
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
import 'Screens/Recruiter/Post_A_Job_Dashboard.dart';
import 'Screens/Recruiter/Recruiter_dashboard.dart';
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
      // Same user, skip resolution
      return;
    }

    _currentUser = user;
    roleResolved = false;

    if (user == null) {
      userRole = null;
      roleResolved = true;
      RoleService.clearCache();
    } else {
      await _resolveRole(user.uid);
    }

    notifyListeners();
  }

  Future<void> _resolveRole(String uid) async {
    try {
      userRole = await RoleService.getUserRole(uid);

      // Single retry with small backoff
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
    '/admin',  // ← Keep /admin as public
  };

  static const _roleRoutes = {
    'admin': {'/admin_dashboard', '/admin_dashboard2'},  // ← Do NOT include /admin here
    'recruiter': {
      '/recruiter-dashboard',
      '/job-posting',
      '/view-applications',
      '/recruiter-job-listing'
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
    'admin': '/admin_dashboard',  // ← First dashboard after admin login
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

// ========== ROUTER WITH SPECIAL ADMIN HANDLING ==========
final GoRouter router = GoRouter(
  initialLocation: '/',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final role = _authNotifier.userRole;
    final roleResolved = _authNotifier.roleResolved;
    final location = state.uri.path;

    debugPrint('🔀 Redirect: $location | User: ${user?.uid} | Role: $role | Resolved: $roleResolved');

    // SPECIAL CASE: /admin route
    if (location == '/admin') {
      if (!isLoggedIn) {
        // Not logged in → show admin login page
        debugPrint('   ✓ /admin - showing login (not authenticated)');
        return null;
      }

      if (!roleResolved) {
        // Logged in but role not resolved yet → wait
        debugPrint('   ⏳ /admin - waiting for role resolution');
        return null;
      }

      if (role == 'admin') {
        // Admin user → redirect to dashboard
        debugPrint('   ↪ /admin - redirecting admin to dashboard');
        return '/admin_dashboard';
      }

      // Non-admin logged in user → redirect to their dashboard
      debugPrint('   ↪ /admin - non-admin user, redirecting to their dashboard');
      return RouteConfig.getDashboard(role ?? 'job_seeker');
    }

    // Handle other public paths
    if (RouteConfig.isPublicPath(location)) {
      if (isLoggedIn && roleResolved && role != null) {
        debugPrint('   ↪ Public path but authenticated - redirecting to dashboard');
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

    // ADMIN - Login page (public) and dashboards (protected)
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

    // JOB SEEKER SHELL (reactive to Firestore profile)
    ShellRoute(
      builder: (context, state, child) {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Authentication error')),
          );
        }

        final uid = user.uid;

        return _JobSeekerShell(
          uid: uid,
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
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
      ],
    ),

    // RECRUITER
    GoRoute(
      path: '/recruiter-dashboard',
      pageBuilder: (c, s) => _buildPage(
        child: const RecruiterDashboard(),
        context: c,
        state: s,
      ),
    ),
    GoRoute(
      path: '/recruiter-job-listing',
      pageBuilder: (c, s) => _buildPage(
        child: const JobPostingScreen(),
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
// ========== OPTIMIZED PAGE TRANSITIONS ==========
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

// ========== ROUTER ==========
final _authNotifier = AuthNotifier();


class _JobSeekerShell extends StatefulWidget {
  final String uid;
  final Widget child;
  final String currentPath;

  const _JobSeekerShell({
    required this.uid,
    required this.child,
    required this.currentPath,
    Key? key,
  }) : super(key: key);

  @override
  State<_JobSeekerShell> createState() => _JobSeekerShellState();
}

class _JobSeekerShellState extends State<_JobSeekerShell> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  bool _hasProfile = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    if (_authNotifier.userRole != 'job_seeker') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(RouteConfig.getDashboard(_authNotifier.userRole ?? '/'));
      });
      return;
    }

    _listenToProfile();
  }

  void _listenToProfile() {
    final docRef =
    FirebaseFirestore.instance.collection('job_seeker').doc(widget.uid);

    _sub = docRef.snapshots().listen((snap) {
      if (!mounted) return;

      final exists =
          snap.exists && snap.data()?.containsKey('user_data') == true;

      setState(() {
        _hasProfile = exists;
        _initialized = true;
      });

      // Use path passed from ShellRoute (state.uri.path)
      if (exists && widget.currentPath == '/profile-builder') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/dashboard');
        });
      }

      if (!exists && widget.currentPath != '/profile-builder') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/profile-builder');
        });
      }
    }, onError: (e) {
      debugPrint('Profile stream error: $e');
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return widget.child;
  }
}
