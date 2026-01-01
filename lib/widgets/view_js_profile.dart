// lib/widgets/view_applicant_details.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Screens/Recruiter/LIst_of_Applicants_provider.dart';

class ViewApplicantDetails extends StatelessWidget {
  final ApplicantRecord applicant;
  const ViewApplicantDetails({super.key, required this.applicant});

  // Mask sensitive data
  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 3) return '***@$domain';
    return '${username.substring(0, 2)}****${username.substring(username.length - 1)}@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return '';
    if (phone.length <= 4) return '****';
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 2)}';
  }

  String _maskUrl(String url) {
    if (url.isEmpty) return '';
    if (url.length <= 15) return '****';
    return '${url.substring(0, 8)}****${url.substring(url.length - 4)}';
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, {bool masked = false, String? originalValue}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.isNotEmpty ? value : 'Not provided',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: value.isNotEmpty ? Colors.grey.shade800 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    if (masked && originalValue != null && originalValue.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.visibility_outlined, size: 18, color: Colors.grey.shade600),
                        tooltip: 'Click to reveal',
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipList(List<String> items, Color color) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'None listed',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            item,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExperienceItem(Map<String, dynamic> exp) {
    final text = exp['text']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.work_outline, size: 20, color: Color(0xFF0284C7)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text.isNotEmpty ? text : 'Experience details',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(Map<String, dynamic> edu) {
    final institution = edu['institutionName']?.toString() ?? 'Institution';
    final duration = edu['duration']?.toString() ?? '';
    final major = edu['majorSubjects']?.toString() ?? '';
    final marks = edu['marksOrCgpa']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_outlined, size: 20, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institution,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (major.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    major,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                if (duration.isNotEmpty || marks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (duration.isNotEmpty) ...[
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          duration,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (duration.isNotEmpty && marks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('•', style: TextStyle(color: Colors.grey.shade400)),
                        ),
                      if (marks.isNotEmpty) ...[
                        Icon(Icons.star_outline, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(
                          marks,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check for missing mandatory fields
    final mandatory = {
      'email': applicant.email.isNotEmpty,
      'phone': applicant.phone.isNotEmpty,
      'nationality': applicant.nationality.isNotEmpty,
      'dob': applicant.dob.isNotEmpty,
    };
    final missingCount = mandatory.values.where((v) => !v).length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Profile Picture
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: applicant.pictureUrl.isNotEmpty
                              ? NetworkImage(applicant.pictureUrl)
                              : null,
                          child: applicant.pictureUrl.isEmpty
                              ? Text(
                            applicant.name.isNotEmpty ? applicant.name[0].toUpperCase() : 'U',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6366F1),
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Name and Email
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              applicant.name,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.work_outline, size: 16, color: Colors.white70),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    applicant.jobData?.title ?? 'Position Applied',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        applicant.status == 'accepted'
                                            ? Icons.check_circle
                                            : applicant.status == 'rejected'
                                            ? Icons.cancel
                                            : Icons.schedule,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        applicant.status.toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (missingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade700),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$missingCount field${missingCount > 1 ? 's' : ''} missing',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (applicant.documents.isNotEmpty) {
                                // Download CV logic
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Buy Pro to Download CV...')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('CV not available')),
                                );
                              }
                            },
                            icon: const Icon(Icons.download_outlined, size: 18),
                            label: Text(
                              'Download CV',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        'Experience',
                        '${applicant.experienceYears}+ yrs',
                        Icons.work_history_outlined,
                        Colors.white,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Skills',
                        '${applicant.skills.length}',
                        Icons.stars_outlined,
                        Colors.white,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Certifications',
                        '${applicant.certifications.length}',
                        Icons.workspace_premium_outlined,
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information
                    _buildSectionHeader('Personal Information', Icons.person_outline, const Color(0xFF334155)),
                    const SizedBox(height: 16),
                    _buildInfoCard('Full Name', applicant.name, Icons.badge_outlined),
                    _buildInfoCard(
                      'Email',
                      _maskEmail(applicant.email),
                      Icons.email_outlined,
                      masked: true,
                      originalValue: applicant.email,
                    ),
                    _buildInfoCard(
                      'Phone',
                      _maskPhone(applicant.phone),
                      Icons.phone_outlined,
                      masked: true,
                      originalValue: applicant.phone,
                    ),
                    _buildInfoCard('Nationality', applicant.nationality, Icons.flag_outlined),
                    _buildInfoCard('Date of Birth', applicant.dob, Icons.cake_outlined),

                    const SizedBox(height: 24),

                    // Professional Summary
                    if (applicant.summary.isNotEmpty || applicant.objectives.isNotEmpty) ...[
                      _buildSectionHeader('Professional Summary', Icons.description_outlined, const Color(0xFF7C3AED)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          applicant.summary.isNotEmpty ? applicant.summary : applicant.objectives,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.6,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Education
                    _buildSectionHeader('Education', Icons.school_outlined, const Color(0xFF10B981)),
                    const SizedBox(height: 16),
                    if (applicant.educations.isNotEmpty)
                      Column(
                        children: applicant.educations.map((edu) => _buildEducationItem(edu)).toList(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No education information provided',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Professional Experience
                    _buildSectionHeader('Professional Experience', Icons.work_outline, const Color(0xFF0284C7)),
                    const SizedBox(height: 16),
                    if (applicant.experiences.isNotEmpty)
                      Column(
                        children: applicant.experiences.map((exp) => _buildExperienceItem(exp)).toList(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No work experience listed',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Skills
                    _buildSectionHeader('Skills', Icons.psychology_outlined, const Color(0xFF0284C7)),
                    const SizedBox(height: 16),
                    _buildChipList(applicant.skills, const Color(0xFF0284C7)),

                    const SizedBox(height: 24),

                    // Certifications
                    _buildSectionHeader('Certifications', Icons.workspace_premium_outlined, const Color(0xFF7C3AED)),
                    const SizedBox(height: 16),
                    _buildChipList(applicant.certifications, const Color(0xFF7C3AED)),

                    const SizedBox(height: 24),

                    // Publications
                    if (applicant.publications.isNotEmpty) ...[
                      _buildSectionHeader('Publications', Icons.article_outlined, const Color(0xFFEA580C)),
                      const SizedBox(height: 16),
                      _buildChipList(applicant.publications, const Color(0xFFEA580C)),
                      const SizedBox(height: 24),
                    ],

                    // Awards
                    if (applicant.awards.isNotEmpty) ...[
                      _buildSectionHeader('Awards & Achievements', Icons.emoji_events_outlined, const Color(0xFFD97706)),
                      const SizedBox(height: 16),
                      _buildChipList(applicant.awards, const Color(0xFFD97706)),
                      const SizedBox(height: 24),
                    ],

                    // Social Links
                    if (applicant.socialLinks.isNotEmpty) ...[
                      _buildSectionHeader('Social Links', Icons.link_outlined, const Color(0xFF059669)),
                      const SizedBox(height: 16),
                      Column(
                        children: applicant.socialLinks.map((link) {
                          return _buildInfoCard(
                            'Link',
                            _maskUrl(link),
                            Icons.link,
                            masked: true,
                            originalValue: link,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // References
                    if (applicant.references.isNotEmpty) ...[
                      _buildSectionHeader('References', Icons.contact_mail_outlined, const Color(0xFF059669)),
                      const SizedBox(height: 16),
                      Column(
                        children: applicant.references.map((ref) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF059669).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.person_pin, size: 20, color: Color(0xFF059669)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _maskUrl(ref),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}