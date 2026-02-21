import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Your existing imports
import 'Constant/Forget Password.dart';
import 'Constant/cv_analysis.dart';
import 'Constant/pricing.dart';
import 'Screens/Admin/admin_wrapper.dart';
import 'Screens/Admin/admin_dashbaord2.dart';
import 'Screens/Admin/admin_login.dart';
import 'Screens/Job_Seeker/JS_Profile/JS_Profile.dart';
import 'Login.dart';
import 'Screens/Job_Seeker/job_hub.dart';
import 'Screens/Job_Seeker/job_seeker_dashboard.dart';
import 'Screens/Recruiter/Job_Applicant_Tracker.dart';
import 'Screens/Recruiter/LIst_of_Applicants.dart';
import 'Constant/Splash.dart';
import 'Screens/Recruiter/Recruiter_Dashbaord.dart';
import 'Screens/Recruiter/Recruiter_Shortlisting.dart';
import 'SignUp /profile_builder.dart';
import 'SignUp /signup_screen_auth.dart';

// ========== 1. ROBUST DATA SERVICE (Logic from Code A) ==========
class RoleService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> fetchUserData(String uid) async {
    try {
      // 1. Run parallel checks
      final List<dynamic> results = await Future.wait([
        _firestore.collection('Job_Seeker').doc(uid).get(const GetOptions(source: Source.serverAndCache)),
        _firestore.collection('recruiter').doc(uid).get(const GetOptions(source: Source.serverAndCache)),
        _firestore.collection('admin').doc(uid).get(const GetOptions(source: Source.serverAndCache)),
        _firestore.collection('users').doc(uid).get(),
      ]);

      final jsDoc = results[0] as DocumentSnapshot;
      final recDoc = results[1] as DocumentSnapshot;
      final adminDoc = results[2] as DocumentSnapshot;
      final userDoc = results[3] as DocumentSnapshot;

      String? role;
      bool isNew = false;

      // 3. Resolve Role from specific collections
      if (jsDoc.exists) {
        role = 'Job Seeker';
      } else if (recDoc.exists) {
        role = 'recruiter';
      } else if (adminDoc.exists) {
        role = 'admin';
      }

      // 4. Resolve isNew and Backup Role from 'users' collection
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Resolve isNew status
        final rawIsNew = userData['isNew'];
        if (rawIsNew is String) {
          isNew = rawIsNew.toLowerCase().trim() == 'yes';
        } else if (rawIsNew is bool) {
          isNew = rawIsNew;
        } else {
          isNew = true; // Default
        }

        // Backup role resolution if not found in specific collections
        role ??= _normalizeRole(userData['role']?.toString());
      }

      debugPrint('✅ RoleService: UID=$uid, Role=$role, isNew=$isNew');
      return {'role': role, 'isNew': isNew};
    } catch (e) {
      debugPrint('❌ RoleService Error: $e');
      return {'role': null, 'isNew': true};
    }
  }

  static String? _normalizeRole(String? role) {
    if (role == null) return null;
    final r = role.toLowerCase().trim();
    if (['recruiter', 'employer'].contains(r)) return 'recruiter';
    if (['Job Seeker', 'jobseeker', 'candidate'].contains(r)) return 'Job Seeker';
    if (['admin', 'superadmin'].contains(r)) return 'admin';
    return null;
  }
}

// ========== 2. AUTH STATE PROVIDER (Architecture from Code B) ==========
class AuthNotifier extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  User? user;
  String? role;
  bool isNewUser = false;
  bool isInitialized = false;
  bool _isFetching = false; // ✅ NEW: Track if we're currently fetching data

  AuthNotifier() {
    _auth.authStateChanges().listen(_handleAuthChange);
  }

  Future<void> initialize() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _handleAuthChange(currentUser);
    } else {
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _handleAuthChange(User? newUser) async {
    // ✅ CRITICAL FIX: Don't reset isInitialized during fetch
    _isFetching = true;

    if (newUser == null) {
      user = null;
      role = null;
      isNewUser = false;
      isInitialized = true;
      _isFetching = false;
    } else {
      user = newUser;
      debugPrint('🔄 Fetching role data for: ${newUser.uid}');

      final data = await RoleService.fetchUserData(newUser.uid);
      role = data['role'];
      isNewUser = data['isNew'];
      isInitialized = true;
      _isFetching = false;

      debugPrint('✅ Auth State Updated: role=$role, isNew=$isNewUser');
    }
    notifyListeners();
  }

  void markProfileComplete() {
    isNewUser = false;
    notifyListeners();
  }

  // ✅ NEW: Helper to check if we should wait
  bool get shouldWait => _isFetching || !isInitialized;
}

final authProvider = AuthNotifier();

// ========== 3. CLEAN ROUTE CONFIG ==========
class RouteConfig {
  static const publicPaths = {'/', '/login', '/register', '/recover-password', '/pricing', '/admin'};

  static String getHome(String? role) {
    if (role == 'admin') return '/admin_dashboard';
    if (role == 'recruiter') return '/recruiter-dashboard';
    return '/dashboard';
  }
}

// ========== 4. THE ULTIMATE ROUTER ==========
final GoRouter router = GoRouter(
  initialLocation: '/',
  refreshListenable: authProvider,
  redirect: (context, state) {
    final location = state.uri.path;

    debugPrint('🔀 Router Check: $location | Init: ${authProvider.isInitialized} | User: ${authProvider.user?.uid} | Role: ${authProvider.role}');

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
    if (role == 'Job Seeker' && !authProvider.isNewUser && location == '/profile-builder') {
      debugPrint('➡️ Completed profile, going to dashboard');
      return '/dashboard';
    }

    // C. Logged in users trying to hit Login/Register
    if (isPublic && location != '/pricing' && location != '/') {
      debugPrint('➡️ Already logged in, redirecting to home');
      return RouteConfig.getHome(role);
    }

    // D. Admin Guard
    if (location.startsWith('/admin_') && role != 'admin') {
      debugPrint('🚫 Non-admin trying to access admin route');
      return RouteConfig.getHome(role);
    }

    // E. ✅ NEW: Redirect admin from /admin (login page) to dashboard if already logged in
    if (location == '/admin' && role == 'admin') {
      debugPrint('➡️ Admin already logged in, going to dashboard');
      return '/admin_dashboard';
    }

    debugPrint('✅ Staying at: $location');
    return null; // Stay where you are
  },
  routes: [
    GoRoute(path: '/', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/login', pageBuilder: (c, s) => _fadePage(const JobSeekerLoginScreen(), s)),
    GoRoute(path: '/register', pageBuilder: (c, s) => _fadePage(const SignUp_Screen(), s)),
    GoRoute(path: '/recover-password', pageBuilder: (c, s) => _fadePage(const ForgotPasswordScreen(), s)),
    GoRoute(path: '/pricing', pageBuilder: (c, s) => _fadePage(const PremiumPricingPage(), s)),

    // Admin
    GoRoute(path: '/admin', pageBuilder: (c, s) => _fadePage(const AdminLoginScreen(), s)),
    GoRoute(path: '/admin_dashboard', pageBuilder: (c, s) => _fadePage(const AdminDashboardScreen(), s)),
    GoRoute(path: '/admin_dashboard2', pageBuilder: (c, s) => _fadePage(const AdminDashboardScreen2(), s)),

    // Job Seeker
    GoRoute(path: '/dashboard', pageBuilder: (c, s) => _fadePage(const job_seeker_dashboard(), s)),
    GoRoute(path: '/profile-builder', pageBuilder: (c, s) => _fadePage(const ProfileBuilderScreen(), s)),
    GoRoute(path: '/profile', pageBuilder: (c, s) => _fadePage(const ProfileScreen_NEW(), s)),
    GoRoute(path: '/ai-tools', pageBuilder: (c, s) => _fadePage(CVAnalysisScreen(), s)),
    GoRoute(path: '/job-hub', pageBuilder: (c, s) => _fadePage(job_hub(), s)),

    // Recruiter
    GoRoute(path: '/recruiter-dashboard', pageBuilder: (c, s) => _fadePage(const Dashboard_Recruiter(), s)),
    GoRoute(path: '/shortlisting', pageBuilder: (c, s) => _fadePage(const Shortlisting(), s)),
    GoRoute(path: '/job-application-tracker', pageBuilder: (c, s) => _fadePage(const Job_Applicant_Tracker(), s)),

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