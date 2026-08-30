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
import 'SignUp/profile_builder.dart';
import 'Screens/Onboarding/onboarding_screen.dart';
import 'SignUp/signup_screen_auth.dart';
import 'Screens/Recruiter/post_a_job_form.dart';
import 'Screens/Job_Seeker/js_settings_screen.dart';
import 'Screens/Job_Seeker/assessment/assessment_screen.dart';

// ========== 1. ROBUST DATA SERVICE (Logic from Code A) ==========
class RoleService {
  static final _firestore = FirebaseFirestore.instance;

  /// Parses the `users/{uid}.is_verified` flag, which historically has been
  /// written as both a bool and the string "true". Anything else — including a
  /// missing flag — counts as unverified.
  static bool parseVerified(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase().trim() == 'true';
    return false;
  }

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

      bool isNew = false;
      String? rawRole; // exact users.role string, for precise UserRole parsing
      String? status;
      // Admin verification flag. Only meaningful for recruiters; everyone else
      // is implicitly verified. Absent flag ⇒ unverified (fail closed).
      bool isVerified = false;

      // Role derived from the master users.role field (authoritative).
      String? roleFromUsers;
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        rawRole = userData['role']?.toString();
        roleFromUsers = _normalizeRole(rawRole);
        status = (userData['account_status'] ?? 'active')
            .toString()
            .toLowerCase()
            .trim();
        isVerified = parseVerified(userData['is_verified']);

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
      }

      // Role implied by which per-role collection holds a doc (legacy fallback).
      String? roleFromCollections;
      if (jsDoc.exists) {
        roleFromCollections = 'Job Seeker';
      } else if (recDoc.exists) {
        roleFromCollections = 'recruiter';
      } else if (adminDoc.exists) {
        roleFromCollections = 'admin';
      }

      // PRECEDENCE FLIP: users.role is now the source of truth; collection
      // existence is only a fallback for docs that never got a users.role.
      // (The live users/{uid} snapshot listener already applies users.role
      // seconds after login, so this only removes a transient inconsistency.)
      final role = roleFromUsers ?? roleFromCollections;

      if (roleFromUsers != null &&
          roleFromCollections != null &&
          roleFromUsers != roleFromCollections) {
        debugPrint(
          '⚠️ RoleService divergence for $uid: users.role="$roleFromUsers" '
          'vs collection="$roleFromCollections" — using users.role.',
        );
      }

      // Fall back to the collection-derived runtime string when users.role
      // is absent (both are parseable by UserRole.fromFirestore).
      rawRole ??= role;

      debugPrint(
        '✅ RoleService: UID=$uid, Role=$role, isNew=$isNew, Status=$status',
      );
      return {
        'role': role,
        'rawRole': rawRole,
        'isNew': isNew,
        'status': status,
        // Only recruiters are gated on admin verification.
        'isVerified': role == 'recruiter' ? isVerified : true,
      };
    } catch (e) {
      debugPrint('❌ RoleService Error: $e');
      // status 'error' is treated as non-blocking below, so don't let a failed
      // read masquerade as "unverified" and lock the user out of a live session.
      return {
        'role': null,
        'rawRole': null,
        'isNew': false,
        'status': 'error',
        'isVerified': true,
      };
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

  /// Why the last session was rejected (suspended / unverified recruiter).
  /// The login screen reads this to explain a sign-out it did not initiate —
  /// e.g. an unverified recruiter restoring a persisted session on reload.
  String? blockedReason;

  // ── Interactive-login gate ────────────────────────────────────────────────
  //
  // signInWithEmailAndPassword() fires authStateChanges immediately, but the
  // session is not yet *approved*: LoginProvider still has to read the role,
  // account_status and is_verified flags out of Firestore before it knows
  // whether to keep the session or sign it back out. Those reads require an
  // authenticated user, so they cannot happen before sign-in.
  //
  // While that gate is open the router must not act on the half-formed session,
  // otherwise a slow connection lets the redirect reach the dashboard before
  // the checks finish — which is what produced the "dashboard flashes, then
  // logs out" behaviour.
  int _loginGateDepth = 0;
  bool get isLoginGatePending => _loginGateDepth > 0;

  void beginLoginGate() {
    _loginGateDepth++;
  }

  void endLoginGate() {
    if (_loginGateDepth == 0) return;
    _loginGateDepth--;
    // Re-run the redirect now that the session's verdict is known: any
    // notifyListeners() that fired while the gate was open was ignored.
    if (_loginGateDepth == 0) notifyListeners();
  }

  /// Revokes a session that failed its post-sign-in checks.
  ///
  /// Login providers must call this rather than `signOut()` alone. `signOut()`
  /// clears the session asynchronously — authStateChanges(null) is delivered on
  /// a later turn of the event loop — but [endLoginGate] notifies the router
  /// immediately afterwards in the same `finally`. Without clearing the local
  /// state here and now, that redirect would run against a session that is
  /// already revoked and hand the user the dashboard anyway.
  void rejectSession(String reason) {
    debugPrint('🚫 Session rejected: $reason');
    // Not surfaced via [blockedReason]: the caller is a login screen that is
    // already showing this message itself. Setting it here would leave a stale
    // reason behind to be replayed the next time a login screen is built.
    blockedReason = null;
    user = null;
    role = null;
    _rawRole = null;
    isNewUser = false;
    isInitialized = true;
    _isFetching = false;
    _auth.signOut().ignore();
    // Deliberately no notifyListeners(): endLoginGate() fires it once the
    // caller's finally block runs, so the router sees a single settled state.
  }

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
                // Must be supplied here too: _applyUserData treats a missing
                // flag as unverified, so omitting it would sign out every
                // verified recruiter on the next users/{uid} write.
                'isVerified': RoleService.parseVerified(userData['is_verified']),
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
    final isSuspended = status != 'active' && status != 'error';

    // A recruiter is only allowed a session once an admin has verified them.
    // LoginProvider enforces this at sign-in; enforcing it here as well covers
    // the paths it never sees — a persisted session restored on page reload,
    // and verification being revoked while the user is signed in (the live
    // users/{uid} listener re-runs this).
    final isUnverifiedRecruiter =
        data['role'] == 'recruiter' && data['isVerified'] != true;

    if (isSuspended || isUnverifiedRecruiter) {
      blockedReason = isSuspended
          ? 'Your account is suspended. Contact Customer support.'
          : 'Your verification process has been started. Once verified by '
                'our admin team, you will be able to log in and use the system.';
      debugPrint(
        isSuspended
            ? '🚫 Suspended account detected in AuthNotifier, signing out...'
            : '🚫 Unverified recruiter detected in AuthNotifier, signing out...',
      );
      user = null;
      role = null;
      _rawRole = null;
      isNewUser = false;
      isInitialized = true;
      _isFetching = false;
      _auth.signOut().ignore();
    } else {
      blockedReason = null;
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
  // Also holds while an interactive login is still deciding whether to keep
  // the session it just created — see [beginLoginGate].
  bool get shouldWait => _isFetching || !isInitialized || isLoginGatePending;

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
    '/onboarding',
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

  /// Validates a `?next=` destination before redirecting to it.
  ///
  /// Only same-site absolute paths are honoured. Without this the parameter is
  /// an open redirect: a link to our own /login carrying next=https://evil.example
  /// would bounce a signed-in user straight off the product.
  static String? safeNext(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final decoded = Uri.decodeComponent(raw);
    if (!decoded.startsWith('/') || decoded.startsWith('//')) return null;
    if (loggedInRedirectPaths.contains(Uri.parse(decoded).path)) return null;
    return decoded;
  }

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
      if (isPublic) return null;
      // An assessment link arrives by email, so the candidate is usually
      // signed out when they click it. Sending them to /login and forgetting
      // where they were headed would drop them on the dashboard with no way
      // back to a link that expires in 24 hours.
      if (location.startsWith('/assessment/')) {
        return '/login?next=${Uri.encodeComponent(state.uri.toString())}';
      }
      return '/login';
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
    // Onboarding is now self-contained: role template → CV or manual entry →
    // dynamic form → submit. It writes the candidate profile itself, so a new
    // job seeker never passes through the legacy profile builder.
    if (role == 'Job Seeker' && authProvider.isNewUser) {
      if (location != '/onboarding') {
        debugPrint('➡️ Redirecting new job seeker to onboarding');
        return '/onboarding';
      }
      return null;
    }

    // B. Completed job seekers should not sit on onboarding / profile builder.
    if (role == 'Job Seeker' &&
        !authProvider.isNewUser &&
        (location == '/profile-builder' || location == '/onboarding')) {
      debugPrint('➡️ Completed profile, going to dashboard');
      return '/dashboard';
    }

    // C. Logged in users trying to hit auth/landing routes
    if (RouteConfig.loggedInRedirectPaths.contains(location)) {
      final next = RouteConfig.safeNext(state.uri.queryParameters['next']);
      if (next != null) {
        debugPrint('➡️ Resuming intended destination: $next');
        return next;
      }
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

    // Path-prefixed, so it cannot be listed in jobSeekerPaths with the rest.
    // The backend enforces the same rule; this only saves a wasted round trip.
    if (location.startsWith('/assessment/') && role != 'Job Seeker') {
      debugPrint('🚫 Non-candidate trying to open an assessment');
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
      pageBuilder: (c, s) {
        // Role is chosen by navigation context via ?role=recruiter|candidate.
        // Anything else (including a direct visit) defaults to Job Seeker.
        final roleParam = s.uri.queryParameters['role']?.toLowerCase();
        final initialRole = roleParam == 'recruiter'
            ? 'Recruiter'
            : 'Job Seeker';
        return _fadePage(SignUp_Screen(initialRole: initialRole), s);
      },
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
      path: '/onboarding',
      pageBuilder: (c, s) => _fadePage(const OnboardingScreen(), s),
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
    // Outside the app shell on purpose: a timed assessment with a navigation
    // rail beside it is an invitation to wander off mid-question.
    GoRoute(
      path: '/assessment/:token',
      pageBuilder: (c, s) => _fadePage(
        AssessmentScreen(token: s.pathParameters['token'] ?? ''),
        s,
      ),
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
