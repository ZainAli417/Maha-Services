// lib/main2.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'Screens/Recruiter/AI Candidate Matching_Provider.dart';
import 'Screens/Recruiter/LIst_of_Applicants_provider.dart';
import 'Screens/Recruiter/Recruiter_provider_Job_listing.dart';
import 'Screens/Recruiter/login_provider_Recruiter.dart';
import 'Screens/Recruiter/R_Initials_provider.dart';
import 'SignUp /signup_provider.dart';
import 'Screens/Job_Seeker/JS_Initials_provider.dart';
import 'Web_routes.dart';
import 'firebase_options.dart';
import 'login_provider.dart';

/// ---------------------------
/// Top-level test dataset list
/// (single dataset as you requested)
/// ---------------------------
final List<Map<String, dynamic>> _airforceProfiles = [
  // PROFILE 9
  {
    "certifications": [
      {
        "organization": "PAF Intelligence School",
        "name": "Military Intelligence Fundamentals",
      },
      {"organization": "AASS", "name": "Introduction to Cybersecurity"},
    ],
    "publications": [
      "Air Intelligence Collection Techniques - Defence Insights",
    ],
    "educationalProfile": [
      {
        "duration": "2001-2005",
        "majorSubjects": "BS (Security & Strategic Studies)",
        "institutionName": "National Defence University (NDU)",
        "marksOrCgpa": "3.50/4",
      },
    ],
    "professionalExperience": [
      {
        "location": "PAF Intelligence Directorate, Islamabad",
        "aircraftType": "N/A",
        "organization": "Pakistan Air Force",
        "flightHours": "2000",
        "startDate": "Sep 2006",
        "rank": "Wing Commander",
        "duration": "Sep 2006 - Present",
        "duties":
            "Intelligence analysis, target assessment, strategic reporting",
        "unit": "Intelligence Wing",
        "command": "Headquarters",
        "endDate": "",
        "role": "Intelligence Officer",
      },
    ],
    "experienceDocuments": ["https://example.com/docs/intel_report_zafar.pdf"],
    "professionalProfile": {
      "status": "active",
      "retirementDate": "2026-01-17",
      "summary":
          "Intelligence officer specializing in air operations and targeting.",
      "expectedRetirementDate": "",
    },
    "awards": ["Excellence in Intelligence Award"],
    "personalProfile": {
      "profilePicUrl": "https://example.com/profile/zafar.png",
      "nationality": "Pakistani",
      "contactNumber": "+92-3000000009",
      "name": "Zafar Iqbal",
      "createdAt": "2026-01-18T16:06:37Z",
      "socialLinks": ["https://www.linkedin.com/in/zafariqbal"],
      "secondary_email": "zafar.alt@mail.com",
      "skills": ["Intelligence Analysis", "OSINT", "Targeting"],
      "email": "zafar.iqbal@paf.gov.pk",
      "summary":
          "Seasoned intelligence analyst with focus on air campaign support.",
      "dob": "1980-10-02",
      "objectives": "Improve intel fusion capabilities.",
    },
    "createdAt": TimeOfDay.fromDateTime(DateTime.now()).toString(),
    "references": ["Air Commodore Tariq — Intelligence"],
  },

];

/// ---------------------------
/// Utility: pick profile by version (1-based)
/// ---------------------------
Map<String, dynamic> generateAirforceProfile(int version) {
  final index = (version - 1) % _airforceProfiles.length;
  return Map<String, dynamic>.from(_airforceProfiles[index]);
}

Future<void> triggerAirforceTestData(String uid, {int version = 1}) async {
  try {
    final data = generateAirforceProfile(version);

    // Ensure dates inside nested maps are strings (they already are above).
    // Write to Firestore (merge=true so we don't wipe other fields).
    await FirebaseFirestore.instance.collection('Job_Seeker').doc(uid).set({
      'user_data': data,
      'testInjectedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    // Debug log
    debugPrint(
      '✅ Injected Airforce test profile version $version into job_seeker/$uid',
    );
  } catch (e, st) {
    debugPrint('❌ Failed to inject test data: $e\n$st');
  }
}

Future<void> markAllUsersNotNew() async {
  try {
    final collectionRef = FirebaseFirestore.instance.collection('users');
    final snapshot = await collectionRef.get();

    for (final doc in snapshot.docs) {
      await doc.reference.set({'isNew': 'no'}, SetOptions(merge: true));
    }

    debugPrint("✅ All users marked as isNew = no");
  } catch (e) {
    debugPrint("❌ Error updating users: $e");
  }
}

/// ---------------------------
/// Main + App (your providers & JobPortalApp)
/// ---------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Call trigger here (manual UID you provided). This will run once at app start.
  // Replace the UID if you want to test with another user.
  // await triggerAirforceTestData("kXrYufRrFFbQePipdFeYylZjUEN2", version: 1);
  //await markAllUsersNotNew();

  // If targeting web, make pretty URLs
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  // ── Pre-load Google Fonts BEFORE runApp to avoid lazy_path.dart crash ──
  // Trigger font downloads so the engine never measures text with a missing font.
  GoogleFonts.poppins();       // enqueues the Poppins download
  GoogleFonts.inter();         // enqueues the Inter download
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
        debugPrint('${details.stack.toString().split('\n').take(8).join('\n')}');
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
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
        ChangeNotifierProvider(create: (_) => CVAnalyzerBackendProvider()),
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => AdminAnalyticsProvider()),

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
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,   // ⭐ REQUIRED
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en'),  // Add more if needed
      ],

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
          fillColor: const Color(0xFFFAFAFA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
  static const String backendUrl = 'https://backend.taasgrid.com';
}
