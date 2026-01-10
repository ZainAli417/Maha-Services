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

// ========== 1. ROBUST DATA SERVICE (Logic from Code A) ==========
class RoleService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> fetchUserData(String uid) async {
    try {
      // 1. Run parallel checks
      // We cast the Future.wait to List<dynamic> to handle different return types
      final List<dynamic> results = await Future.wait([
        _firestore.collection('job_seeker').doc(uid).get(const GetOptions(source: Source.serverAndCache)),
        _firestore.collection('recruiter').doc(uid).get(const GetOptions(source: Source.serverAndCache)),
        _firestore.collection('admin').doc(uid).get(const GetOptions(source: Source.serverAndCache)),
        _firestore.collection('users').where('uid', isEqualTo: uid).limit(1).get(),
      ]);

      // 2. Explicitly cast the snapshots so Dart recognizes '.exists'
      final jsDoc = results[0] as DocumentSnapshot;
      final recDoc = results[1] as DocumentSnapshot;
      final adminDoc = results[2] as DocumentSnapshot;
      final userQuery = results[3] as QuerySnapshot;

      String? role;
      bool isNew = false;

      // 3. Resolve Role from specific collections
      if (jsDoc.exists) {
        role = 'job_seeker';
      } else if (recDoc.exists) {
        role = 'recruiter';
      } else if (adminDoc.exists) {
        role = 'admin';
      }

      // 4. Resolve isNew and Backup Role from 'users' collection
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data() as Map<String, dynamic>;

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
    if (['job_seeker', 'jobseeker', 'candidate'].contains(r)) return 'job_seeker';
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
  bool isInitialized = false; // Prevents routing until data is ready

  AuthNotifier() {
    _auth.authStateChanges().listen(_handleAuthChange);
  }

  // Use this to wait for the user on App Start (fixes Refresh issue)
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
    if (newUser == null) {
      user = null;
      role = null;
      isNewUser = false;
      isInitialized = true;
    } else {
      user = newUser;
      final data = await RoleService.fetchUserData(newUser.uid);
      role = data['role'];
      isNewUser = data['isNew'];
      isInitialized = true;
    }
    notifyListeners();
  }

  void markProfileComplete() {
    isNewUser = false;
    notifyListeners();
  }
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

    // 1. Wait for initialization (Prevents redirecting to Login before data is fetched)
    if (!authProvider.isInitialized) return null;

    final isLoggedIn = authProvider.user != null;
    final isPublic = RouteConfig.publicPaths.contains(location);

    // 2. Unauthenticated Flow
    if (!isLoggedIn) {
      if (location == '/admin') return null; // Allow admin login page
      return isPublic ? null : '/login';
    }

    // 3. Authenticated Flow
    final role = authProvider.role;

    // Safety: If logged in but no role found (Firebase error or doc missing)
    if (role == null && !isPublic) {
      FirebaseAuth.instance.signOut();
      return '/login';
    }

    // A. New User Logic (Job Seeker ONLY)
    if (role == 'job_seeker' && authProvider.isNewUser) {
      if (location != '/profile-builder') return '/profile-builder';
      return null;
    }

    // B. Prevent New Users going to Dashboard
    if (role == 'job_seeker' && !authProvider.isNewUser && location == '/profile-builder') {
      return '/dashboard';
    }

    // C. Logged in users trying to hit Login/Register
    if (isPublic && location != '/pricing' && location != '/') {
      return RouteConfig.getHome(role);
    }

    // D. Admin Guard
    if (location.startsWith('/admin_') && role != 'admin') {
      return RouteConfig.getHome(role);
    }

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
    GoRoute(path: '/view-applications', pageBuilder: (c, s) => _fadePage(const ApplicantsScreen(), s)),
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