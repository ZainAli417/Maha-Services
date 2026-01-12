// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'Constant/Forget Password Provider.dart';
import 'Constant/cv_analysis_provider.dart';
import 'Screens/Admin/admin_login_provider.dart';
import 'Screens/Admin/admin_provider.dart';
import 'Screens/Job_Seeker/JS_Profile/JS_Profile_Provider.dart';
import 'Screens/Job_Seeker/List_applied_jobs_provider.dart';
import 'Screens/Job_Seeker/job_seeker_provider.dart';
import 'Screens/Job_Seeker/jobs_application_provider.dart';
import 'Screens/Recruiter/AI Candidate Matching_Provider.dart';
import 'Screens/Recruiter/LIst_of_Applicants_provider.dart';
import 'Screens/Recruiter/Recruiter_provider_Job_listing.dart';
import 'Screens/Recruiter/Signup_Provider_Recruiter.dart';
import 'Screens/Recruiter/login_provider_Recruiter.dart';
import 'Screens/Recruiter/R_Initials_provider.dart';
import 'SignUp /signup_provider.dart';
import 'Screens/Job_Seeker/JS_Initials_provider.dart';
import 'Web_routes.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';

import 'login_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: 'env/.env'); // loads .env
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ─── If targeting web, you can reintroduce URL strategy here:
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Precache a dummy inter text so it’s ready immediately
    TextPainter(
      text: TextSpan(text: " ", style: GoogleFonts.poppins()),
      textDirection: TextDirection.ltr,
    ).layout();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoleProvider()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
        ChangeNotifierProvider(create: (_) => SignUpProvider_Recruiter()),
        ChangeNotifierProvider(create: (_) => LoginProvider_Recruiter()),
        ChangeNotifierProvider(create: (_) => JS_TopNavProvider()),
        ChangeNotifierProvider(create: (_) => JS_TopNavProvider()..refresh()),

        ChangeNotifierProvider(create: (_) => ProfileProvider_NEW()),
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
        ChangeNotifierProvider(create: (_) => CVAnalyzerBackendProvider()),
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),

        ChangeNotifierProvider(create: (_) => R_TopNavProvider()),
        ChangeNotifierProvider(create: (_) => job_listing_provider()),
        ChangeNotifierProvider(create: (_) => JobSeekerProvider()),
        ChangeNotifierProvider(create: (_) => JobApplicationsProvider()),
        ChangeNotifierProvider(create: (_) => ListAppliedJobsProvider()),
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
      routerConfig: router,
      theme: ThemeData(
        primaryColor: const Color(0xFF6366F1),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF6366F1),
        ),
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: GoogleFonts.interTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFFAFAFA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          buttonColor: const Color(0xFF6366F1),
          textTheme: ButtonTextTheme.primary,
        ),
      ),
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

class Env {
  static String get geminiApiKey => '';
  static String get groqApiKey => '';

  // Optional helper to check presence
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
