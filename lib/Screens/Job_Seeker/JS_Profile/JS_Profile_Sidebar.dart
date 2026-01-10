// js_profile_sidebar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../Constant/CV_Generator.dart';
import 'JS_Profile_Provider.dart';

class JSProfileSidebar extends StatefulWidget {
  final ProfileProvider_NEW provider;
  const JSProfileSidebar({super.key, required this.provider});

  @override
  _JSProfileSidebarState createState() => _JSProfileSidebarState();
}

class _JSProfileSidebarState extends State<JSProfileSidebar> {
  // Section weights (must sum to 100)
  static const int _wPersonal = 25;
  static const int _wEducation = 15;
  static const int _wProfessionalProfile = 15;
  static const int _wExperience = 20;
  static const int _wCertifications = 8;
  static const int _wPublications = 5;
  static const int _wAwards = 4;
  static const int _wReferences = 4;
  static const int _wDocuments = 4;

  bool _isExpanded = false; // now part of State

  int _scorePersonal() {
    final provider = widget.provider;
    var s = 0;
    if (provider.name.trim().isNotEmpty) s += 8;
    if (provider.email.trim().isNotEmpty) s += 6;
    if (provider.contactNumber.trim().isNotEmpty) s += 5;
    if (provider.profilePicUrl.trim().isNotEmpty) s += 3;
    if (provider.skillsList.isNotEmpty) s += 2;
    if (provider.personalSummary.trim().isNotEmpty) s += 1;
    return s.clamp(0, _wPersonal);
  }

  int _scoreEducation() => widget.provider.educationalProfile.isNotEmpty ? _wEducation : 0;
  int _scoreProfessionalProfile() => widget.provider.professionalProfileSummary.trim().isNotEmpty ? _wProfessionalProfile : 0;
  int _scoreExperience() => widget.provider.professionalExperience.isNotEmpty ? _wExperience : 0;
  int _scoreCertifications() => widget.provider.certifications.isNotEmpty ? _wCertifications : 0;
  int _scorePublications() => widget.provider.publications.isNotEmpty ? _wPublications : 0;
  int _scoreAwards() => widget.provider.awards.isNotEmpty ? _wAwards : 0;
  int _scoreReferences() => widget.provider.references.isNotEmpty ? _wReferences : 0;
  int _scoreDocuments() => widget.provider.documents.isNotEmpty ? _wDocuments : 0;

  int computeTotalScore() {
    return (_scorePersonal() +
        _scoreEducation() +
        _scoreProfessionalProfile() +
        _scoreExperience() +
        _scoreCertifications() +
        _scorePublications() +
        _scoreAwards() +
        _scoreReferences() +
        _scoreDocuments())
        .clamp(0, 100);
  }

  String _displayName() {
    final provider = widget.provider;
    if (provider.name.trim().isNotEmpty) return provider.name.trim();
    if (provider.email.trim().isNotEmpty) {
      final parts = provider.email.split('@');
      return parts.isNotEmpty ? parts.first : 'Job Seeker';
    }
    return 'Job Seeker';
  }

  String _initials() {
    final provider = widget.provider;
    final name = provider.name.trim();
    if (name.isEmpty) {
      if (provider.email.isNotEmpty) return provider.email[0].toUpperCase();
      return 'JS';
    }
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF3B82F6);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Work';
  }

  @override
  Widget build(BuildContext context) {
    final totalScore = computeTotalScore();
    final scoreColor = _getScoreColor(totalScore);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildScoreCard(totalScore, scoreColor),
          const SizedBox(height: 20),
          _buildQuickStats(),
          const SizedBox(height: 20),
          _buildSectionBreakdown(),
          const SizedBox(height: 20),
          CVGeneratorButton(),
          const SizedBox(height: 20),
          _buildSkillsOverview(),
          const SizedBox(height: 20),
          _buildDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final provider = widget.provider;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage: provider.profilePicUrl.isNotEmpty
                      ? NetworkImage(provider.profilePicUrl)
                      : null,
                  child: provider.profilePicUrl.isEmpty
                      ? Text(
                    _initials(),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A),
                    ),
                  )
                      : null,
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Name + subtitles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        provider.email.isNotEmpty ? provider.email : 'No email provided',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (provider.contactNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        provider.contactNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(int totalScore, Color scoreColor) {
    final provider = widget.provider;
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(FontAwesomeIcons.barChart, color: scoreColor, size: 22),
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
                      _getScoreLabel(totalScore),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  '$totalScore%',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalScore / 100,
              minHeight: 12,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final provider = widget.provider;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildStatChip(
          icon: Icons.book_rounded,
          label: 'Education',
          value: provider.educationalProfile.length.toString(),
          color: const Color(0xFF3B82F6),
        ),
        _buildStatChip(
          icon: Icons.cases_rounded,
          label: 'Experience',
          value: provider.professionalExperience.length.toString(),
          color: const Color(0xFF8B5CF6),
        ),
        _buildStatChip(
          icon: Icons.checklist_rounded,
          label: 'Certifications',
          value: provider.certifications.length.toString(),
          color: const Color(0xFF10B981),
        ),
        _buildStatChip(
          icon: Icons.star_rounded,
          label: 'Awards',
          value: provider.awards.length.toString(),
          color: const Color(0xFFF59E0B),
        ),
        _buildStatChip(
          icon: Icons.document_scanner_rounded,
          label: 'Publications',
          value: provider.publications.length.toString(),
          color: const Color(0xFFEC4899),
        ),
        _buildStatChip(
          icon: Icons.folder_rounded,
          label: 'Documents',
          value: provider.documents.length.toString(),
          color: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBreakdown() {
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
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.list, color: Color(0xFF1E3A8A), size: 18),
              const SizedBox(width: 8),
              Text(
                'Section Breakdown',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressRow('Personal Info', _scorePersonal(), _wPersonal, Icons.person_rounded, const Color(0xFF3B82F6)),
          _buildProgressRow('Education', _scoreEducation(), _wEducation, Icons.book_rounded, const Color(0xFF8B5CF6)),
          _buildProgressRow('Prof. Profile', _scoreProfessionalProfile(), _wProfessionalProfile, Icons.cases_rounded, const Color(0xFF10B981)),
          _buildProgressRow('Experience', _scoreExperience(), _wExperience, Icons.timer, const Color(0xFFF59E0B)),
          _buildProgressRow('Certifications', _scoreCertifications(), _wCertifications, Icons.checklist_rounded, const Color(0xFFEC4899)),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int got, int max, IconData icon, Color color) {
    final percent = max == 0 ? 0.0 : (got / max);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              Text(
                '$got/$max',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSkillsOverview() {
    final provider = widget.provider;
    if (provider.skillsList.isEmpty) return const SizedBox();

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
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.layerGroup, color: Color(0xFF1E3A8A), size: 18),
              const SizedBox(width: 8),
              Text(
                'Your Skills',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.provider.skillsList.take(10).map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.1),
                      const Color(0xFF1E3A8A).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                ),
                child: Text(
                  skill,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              );
            }).toList(),
          ),
          if (widget.provider.skillsList.length > 10) ...[
            const SizedBox(height: 8),
            Text(
              '+${widget.provider.skillsList.length - 10} more skills',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final provider = widget.provider;
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
          // Header
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.personCirclePlus,
                  color: Color(0xFF1E3A8A), size: 18),
              const SizedBox(width: 8),
              Text(
                'Personal Details',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Details
          _buildDetailRow(FontAwesomeIcons.person, 'Name', _displayName()),
          _buildDetailRow(FontAwesomeIcons.envelopeCircleCheck, 'Email', provider.email.isNotEmpty ? provider.email : '—'),
          _buildDetailRow(FontAwesomeIcons.phone, 'Contact', provider.contactNumber.isNotEmpty ? provider.contactNumber : '—'),
          _buildDetailRow(FontAwesomeIcons.passport, 'Nationality', provider.nationality.isNotEmpty ? provider.nationality : '—'),
          _buildDetailRow(FontAwesomeIcons.calendarDays, 'DOB', provider.dob.isNotEmpty ? provider.dob : '—'),

          // Summary section
          if (provider.personalSummary.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              'Summary',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),

            // Animated summary expansion
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: Text(
                provider.personalSummary,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                provider.personalSummary,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            ),

            const SizedBox(height: 8),

            // Read More / Less Button
            GestureDetector(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Text(
                _isExpanded ? 'Read less' : 'Read more',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3B82F6),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          FaIcon(icon, color: const Color(0xFF6B7280), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
