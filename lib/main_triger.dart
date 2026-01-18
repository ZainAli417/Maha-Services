// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

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
import 'login_provider.dart';

/// ---------------------------
/// Top-level test dataset list
/// (single dataset as you requested)
/// ---------------------------
final List<Map<String, dynamic>> _airforceProfiles = [
  {
    "certifications": [
      {"organization": "PAF Academy", "name": "Advanced Flight Systems"},
      {"organization": "NESCOM", "name": "Avionics Maintenance"},
    ],
    "publications": ["Modern Air Combat Tactics – 2022"],
    "educationalProfile": [
      {
        "duration": "2015-2019",
        "majorSubjects": "Aerospace Engineering",
        "institutionName": "NUST Islamabad",
        "marksOrCgpa": "3.6/4",
      },
    ],
    "professionalExperience": [
      {
        "location": "Pakistan",
        "aircraftType": "JF-17 Thunder",
        "organization": "Pakistan Air Force",
        "flightHours": "1450",
        "startDate": "Jan 2020",
        "rank": "Flight Lieutenant",
        "duration": "2020 - 2024",
        "duties": "Combat air patrol, training missions",
        "unit": "No. 26 Squadron",
        "command": "Northern Air Command",
        "endDate": "Dec 2024",
        "role": "Fighter Pilot",
      },
    ],
    "experienceDocuments": ["https://dummy-docs.com/jf17-logbook.pdf"],
    "professionalProfile": {
      "status": "active",
      "retirementDate": null,
      "summary": "PAF fighter pilot with extensive JF-17 experience.",
      "expectedRetirementDate": "2045-01-01",
    },
    "awards": ["Best Combat Pilot 2023", "PAF Excellence Medal"],
    "personalProfile": {
      "profilePicUrl": "https://dummyimage.com/300",
      "nationality": "Pakistani",
      "contactNumber": "+92-300-1234567",
      "name": "Sqn Ldr Hamza Raza",
      // createdAt stored as ISO string
      "createdAt": DateTime.now().toIso8601String(),
      "socialLinks": ["https://linkedin.com/in/hamzaraza"],
      "secondary_email": "hamza.alt@mail.com",
      "skills": [
        "Dogfighting",
        "Night Missions",
        "Radar Systems",
        "Formation Flying",
      ],
      "email": "hamza@mail.com",
      "summary": "Dedicated Pakistan Air Force officer.",
      "dob": "1994-03-21",
      "objectives": "Serve Pakistan with excellence in aerial defense.",
    },
    // top-level createdAt
    "createdAt": DateTime.now().toIso8601String(),
    "references": ["Available upon request"],
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
    await FirebaseFirestore.instance.collection('job_seeker').doc(uid).set({
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

/// ---------------------------
/// Main + App (your providers & JobPortalApp)
/// ---------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Call trigger here (manual UID you provided). This will run once at app start.
  // Replace the UID if you want to test with another user.
  await triggerAirforceTestData("", version: 1);

  // If targeting web, make pretty URLs
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Precache a dummy text style to reduce jank
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

/// NOTE:
/// - The trigger function writes into job_seeker/{uid}.user_data exactly the structure you requested.
/// - To re-run injection for another UID, call:
///     await triggerAirforceTestData("<OTHER_UID>", version: 1);
///
/// Security reminder: avoid calling `triggerAirforceTestData` in production accidentally.
/// Consider gating the call behind a debug flag or an Admin-only UI button when testing.
