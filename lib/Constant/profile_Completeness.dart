import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../Screens/Job_Seeker/JS_Profile/JS_Profile_Provider.dart';

class ProfileCompletenessCard extends StatelessWidget {
  const ProfileCompletenessCard({
    super.key,
    required this.totalScore,
  });

  factory ProfileCompletenessCard.fromProvider(ProfileProvider_NEW provider) {
    final int score =
    _ScoreCalculator.computeFromProvider(provider).clamp(0, 100);
    return ProfileCompletenessCard(totalScore: score);
  }

  final int totalScore;

  static Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF3B82F6);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  static String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Work';
  }

  @override
  Widget build(BuildContext context) {
    final int score = totalScore.clamp(0, 100);
    final Color scoreColor = _getScoreColor(score);
    final String label = _getScoreLabel(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(FontAwesomeIcons.chartSimple,
                    color: scoreColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Completeness',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: scoreColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: scoreColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$score%',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// --- Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 12,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),

          const SizedBox(height: 20),

          /// --- Go to Profile Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                elevation: 4,
              ),
              icon: const FaIcon(
                FontAwesomeIcons.userPen,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                'View / Edit Profile',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SCORE CALCULATOR (same logic as before)
class _ScoreCalculator {
  static int computeFromProvider(ProfileProvider_NEW provider) {
    const int wPersonal = 25;
    const int wEducation = 15;
    const int wProfessionalProfile = 15;
    const int wExperience = 20;
    const int wCertifications = 8;
    const int wPublications = 5;
    const int wAwards = 4;
    const int wReferences = 4;
    const int wDocuments = 4;

    int scorePersonal = 0;
    if (provider.name.trim().isNotEmpty) scorePersonal += 8;
    if (provider.email.trim().isNotEmpty) scorePersonal += 6;
    if (provider.contactNumber.trim().isNotEmpty) scorePersonal += 5;
    if (provider.profilePicUrl.trim().isNotEmpty) scorePersonal += 3;
    if (provider.skillsList.isNotEmpty) scorePersonal += 2;
    if (provider.personalSummary.trim().isNotEmpty) scorePersonal += 1;
    scorePersonal = scorePersonal.clamp(0, wPersonal);

    final int scoreEducation =
    provider.educationalProfile.isNotEmpty ? wEducation : 0;
    final int scoreProfessional =
    provider.professionalProfileSummary.trim().isNotEmpty
        ? wProfessionalProfile
        : 0;
    final int scoreExperience =
    provider.professionalExperience.isNotEmpty ? wExperience : 0;
    final int scoreCerts =
    provider.certifications.isNotEmpty ? wCertifications : 0;
    final int scorePubs =
    provider.publications.isNotEmpty ? wPublications : 0;
    final int scoreAwards = provider.awards.isNotEmpty ? wAwards : 0;
    final int scoreRefs = provider.references.isNotEmpty ? wReferences : 0;
    final int scoreDocs = provider.documents.isNotEmpty ? wDocuments : 0;

    return (scorePersonal +
        scoreEducation +
        scoreProfessional +
        scoreExperience +
        scoreCerts +
        scorePubs +
        scoreAwards +
        scoreRefs +
        scoreDocs)
        .clamp(0, 100);
  }
}
