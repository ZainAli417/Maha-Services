import '../../Screens/Job_Seeker/JS_Profile/JS_Profile_Provider.dart';

/// Single source of truth for job-seeker profile-completeness scoring.
///
/// Previously duplicated in `Constant/profile_Completeness.dart` and
/// `JS_Profile/JS_Profile_Sidebar.dart`. Weights sum to 100.
class ProfileCompleteness {
  // Section weights (must sum to 100).
  static const int wPersonal = 25;
  static const int wEducation = 15;
  static const int wProfessionalProfile = 15;
  static const int wExperience = 20;
  static const int wCertifications = 8;
  static const int wPublications = 5;
  static const int wAwards = 4;
  static const int wReferences = 4;
  static const int wDocuments = 4;

  final int personal;
  final int education;
  final int professionalProfile;
  final int experience;
  final int certifications;
  final int publications;
  final int awards;
  final int references;
  final int documents;

  const ProfileCompleteness._({
    required this.personal,
    required this.education,
    required this.professionalProfile,
    required this.experience,
    required this.certifications,
    required this.publications,
    required this.awards,
    required this.references,
    required this.documents,
  });

  /// Total score, clamped to 0..100.
  int get total => (personal +
          education +
          professionalProfile +
          experience +
          certifications +
          publications +
          awards +
          references +
          documents)
      .clamp(0, 100);

  factory ProfileCompleteness.fromProvider(ProfileProvider_NEW p) {
    var personal = 0;
    if (p.name.trim().isNotEmpty) personal += 8;
    if (p.email.trim().isNotEmpty) personal += 6;
    if (p.contactNumber.trim().isNotEmpty) personal += 5;
    if (p.profilePicUrl.trim().isNotEmpty) personal += 3;
    if (p.skillsList.isNotEmpty) personal += 2;
    if (p.personalSummary.trim().isNotEmpty) personal += 1;
    personal = personal.clamp(0, wPersonal);

    return ProfileCompleteness._(
      personal: personal,
      education: p.educationalProfile.isNotEmpty ? wEducation : 0,
      professionalProfile:
          p.professionalProfileSummary.trim().isNotEmpty ? wProfessionalProfile : 0,
      experience: p.professionalExperience.isNotEmpty ? wExperience : 0,
      certifications: p.certifications.isNotEmpty ? wCertifications : 0,
      publications: p.publications.isNotEmpty ? wPublications : 0,
      awards: p.awards.isNotEmpty ? wAwards : 0,
      references: p.references.isNotEmpty ? wReferences : 0,
      documents: p.documents.isNotEmpty ? wDocuments : 0,
    );
  }
}
