// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Constant/Forget Password Provider.dart';
import 'Constant/cv_analysis_provider.dart';
import 'Screens/Admin/admin_analytics_dashboard_Provider.dart';
import 'Screens/Admin/admin_login_provider.dart';
import 'Screens/Admin/admin_recruiter_request_provider.dart';
import 'Screens/Job_Seeker/JS_Profile/JS_Profile_Provider.dart';
import 'Screens/Job_Seeker/List_applied_jobs_provider.dart';
import 'Screens/Job_Seeker/job_seeker_provider.dart';
import 'Screens/Job_Seeker/jobs_application_provider.dart';
import 'Screens/Job_Seeker/saved_jobs_provider.dart';
import 'Screens/Recruiter/AI Candidate Matching_Provider.dart';
import 'Screens/Recruiter/LIst_of_Applicants_provider.dart';
import 'Screens/Recruiter/Recruiter_provider_Job_listing.dart';
import 'Screens/Recruiter/login_provider_Recruiter.dart';
import 'Screens/Recruiter/R_Initials_provider.dart';
import 'SignUp /signup_provider.dart';
import 'Screens/Job_Seeker/JS_Initials_provider.dart';
import 'Web_routes.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'login_provider.dart';

/// ---------------------------
/// Main + App (providers & JobPortalApp)
/// ---------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before anything else

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // If targeting web, make pretty URLs
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  // ── Pre-load Google Fonts BEFORE runApp to avoid lazy_path.dart crash ──
  // Trigger font downloads so the engine never measures text with a missing font.
  GoogleFonts.plusJakartaSans(); // enqueues the plusJakartaSans download
  try {
    await GoogleFonts.pendingFonts();
  } catch (_) {
    // If font fetch fails (offline, etc.) we fall back to system fonts.
    debugPrint('⚠️ Google Fonts pre-load failed – using fallback fonts.');
  }

  if (kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('═══ Flutter Error ═══');
      debugPrint('${details.exception}');
      if (details.stack != null) {
        debugPrint(details.stack.toString().split('\n').take(8).join('\n'));
      }
      debugPrint('═══════════════════');
    };
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider_Recruiter()),
        ChangeNotifierProvider(create: (_) => JS_TopNavProvider()),

        ChangeNotifierProvider(create: (_) => ProfileProvider_NEW()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => CVAnalyzerBackendProvider()),
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => AdminAnalyticsProvider()),

        ChangeNotifierProvider(create: (_) => R_TopNavProvider()),
        ChangeNotifierProvider(create: (_) => job_listing_provider()),
        ChangeNotifierProvider(create: (_) => JobSeekerProvider()),
        ChangeNotifierProvider(create: (_) => JobApplicationsProvider()),
        ChangeNotifierProvider(create: (_) => ListAppliedJobsProvider()),
        ChangeNotifierProvider(create: (_) => SavedJobsProvider()),
        ChangeNotifierProvider(create: (_) => ApplicantsProvider()),
        ChangeNotifierProvider(create: (_) => AIMatchProvider()),

        ChangeNotifierProvider(create: (_) => SignupProvider()),
      ],
      child: const JobPortalApp(),
    ),
  );
}

class JobPortalApp extends StatelessWidget {
  const JobPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Maha Services',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate, // ⭐ REQUIRED
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en'), // Add more if needed
      ],

      routerConfig: router,
      theme: AppTheme.light,
    );
  }
}

/// RoleProvider: holds the selected role (job seeker / recruiter)
class RoleProvider extends ChangeNotifier {
  /// Either "Job Seeker" or "Recruiter"
  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  void setRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }
}

/// Environment configuration — reads from .env at runtime
class Env {
  static String get backendUrl => 'https://backend.taasgrid.com';
}
