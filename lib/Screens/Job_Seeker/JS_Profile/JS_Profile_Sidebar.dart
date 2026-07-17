import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Constant/CV_Generator.dart';
import '../../../core/utils/profile_completeness.dart';
import 'JS_Profile_Provider.dart';

class JSProfileSidebar extends StatefulWidget {
  final ProfileProvider_NEW provider;
  const JSProfileSidebar({super.key, required this.provider});

  @override
  State<JSProfileSidebar> createState() => _JSProfileSidebarState();
}

class _JSProfileSidebarState extends State<JSProfileSidebar> {
  // ---------------- Configuration ----------------
  // Section weights delegate to the single source of truth.
  static const int _wPersonal = ProfileCompleteness.wPersonal;
  static const int _wEducation = ProfileCompleteness.wEducation;
  static const int _wProfessionalProfile = ProfileCompleteness.wProfessionalProfile;
  static const int _wExperience = ProfileCompleteness.wExperience;
  static const int _wCertifications = ProfileCompleteness.wCertifications;

  bool _isExpanded = false;

  // ---------------- Logic (delegates to ProfileCompleteness) ----------------
  ProfileCompleteness get _score =>
      ProfileCompleteness.fromProvider(widget.provider);

  int _scorePersonal() => _score.personal;
  int _scoreEducation() => _score.education;
  int _scoreProfessionalProfile() => _score.professionalProfile;
  int _scoreExperience() => _score.experience;
  int _scoreCertifications() => _score.certifications;

  int computeTotalScore() => _score.total;

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
    if (score >= 80) return const Color(0xFF10B981); // Emerald
    if (score >= 60) return const Color(0xFF14507F); // Blue
    if (score >= 40) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent Profile';
    if (score >= 60) return 'Good Profile';
    if (score >= 40) return 'Fair Profile';
    return 'Incomplete Profile';
  }

  // ---------------- UI Build ----------------
  @override
  Widget build(BuildContext context) {
    final totalScore = computeTotalScore();
    final scoreColor = _getScoreColor(totalScore);
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Container(
      color: const Color(0xFFFAFAFA),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20,
          vertical: isMobile ? 12 : 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //_buildModernHeader(),
            SizedBox(height: isMobile ? 12 : 24),

            _buildCompletionCard(totalScore, scoreColor),
            SizedBox(height: isMobile ? 14 : 24),

            _buildGridStats(),
            SizedBox(height: isMobile ? 14 : 24),

            _buildSectionBreakdown(),
            SizedBox(height: isMobile ? 14 : 24),

            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14507F).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const CVGeneratorButton(),
            ),
            SizedBox(height: isMobile ? 14 : 24),

            _buildSkillsOverview(),
            SizedBox(height: isMobile ? 14 : 24),

            _buildPersonalDetailsCard(),
            SizedBox(height: isMobile ? 20 : 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCard(int totalScore, Color scoreColor) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    final provider = widget.provider;
    final avatarSize = isMobile ? 46.0 : 56.0;
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
        border: Border.all(color: const Color(0xFFDCE7EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2239).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with teal ring — decode small for web perf.
              Container(
                width: avatarSize,
                height: avatarSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2EC4B6), width: 2),
                  gradient: provider.profilePicUrl.isEmpty
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF14507F), Color(0xFF2EC4B6)],
                        )
                      : null,
                  image: provider.profilePicUrl.isNotEmpty
                      ? DecorationImage(
                          image: ResizeImage(
                            NetworkImage(provider.profilePicUrl),
                            width: 160,
                            height: 160,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: provider.profilePicUrl.isEmpty
                    ? Text(
                        _initials(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 15 : 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: isMobile ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B2239),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getScoreLabel(totalScore),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: isMobile ? 42 : 52,
                height: isMobile ? 42 : 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2EC4B6).withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '$totalScore%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 11 : 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          // Gradient completeness bar (teal→navy).
          Stack(
            children: [
              Container(
                height: isMobile ? 8 : 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F9FB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (totalScore / 100).clamp(0.0, 1.0),
                child: Container(
                  height: isMobile ? 8 : 10,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridStats() {
    final provider = widget.provider;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    final stats = [
      {
        'icon': Icons.school_rounded,
        'val': provider.educationalProfile.length.toString(),
        'label': 'Education',
        'col': const Color(0xFF14507F),
      },
      {
        'icon': Icons.work_rounded,
        'val': provider.professionalExperience.length.toString(),
        'label': 'Experience',
        'col': const Color(0xFF2EC4B6),
      },
      {
        'icon': Icons.verified_rounded,
        'val': provider.certifications.length.toString(),
        'label': 'Certificates',
        'col': const Color(0xFF10B981),
      },
      {
        'icon': Icons.star_rounded,
        'val': provider.awards.length.toString(),
        'label': 'Awards',
        'col': const Color(0xFFF59E0B),
      },
      {
        'icon': Icons.article_rounded,
        'val': provider.publications.length.toString(),
        'label': 'Publications',
        'col': const Color(0xFF43E0D2),
      },
      {
        'icon': Icons.folder_copy_rounded,
        'val': provider.documents.length.toString(),
        'label': 'Documents',
        'col': const Color(0xFFEF4444),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0B2239),
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 3 : 2,
            crossAxisSpacing: isMobile ? 8 : 12,
            mainAxisSpacing: isMobile ? 8 : 12,
            childAspectRatio: isMobile ? 3 : 2.5,
          ),
          itemCount: stats.length,
          itemBuilder: (ctx, i) {
            final s = stats[i];
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 6 : 12,
                vertical: isMobile ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
                border: Border.all(color: const Color(0xFFDCE7EF)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B2239).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(
                    s['icon'] as IconData,
                    color: s['col'] as Color,
                    size: isMobile ? 16 : 18,
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  Text(
                    s['val'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 13 : 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B2239),
                    ),
                  ),
                  Text(
                    s['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 8 : 10,
                      color: const Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionBreakdown() {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
        border: Border.all(color: const Color(0xFFDCE7EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2239).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist_rtl_rounded,
                color: const Color(0xFF14507F),
                size: isMobile ? 13 : 16,
              ),
              SizedBox(width: isMobile ? 6 : 10),
              Text(
                'Completeness Breakdown',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B2239),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 20),
          _buildProgressRow(
            'Personal Info',
            _scorePersonal(),
            _wPersonal,
            const Color(0xFF14507F),
          ),
          _buildProgressRow(
            'Education',
            _scoreEducation(),
            _wEducation,
            const Color(0xFF2EC4B6),
          ),
          _buildProgressRow(
            'Prof. Profile',
            _scoreProfessionalProfile(),
            _wProfessionalProfile,
            const Color(0xFF10B981),
          ),
          _buildProgressRow(
            'Experience',
            _scoreExperience(),
            _wExperience,
            const Color(0xFFF59E0B),
          ),
          _buildProgressRow(
            'Certifications',
            _scoreCertifications(),
            _wCertifications,
            const Color(0xFF43E0D2),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int got, int max, Color color) {
    final percent = max == 0 ? 0.0 : (got / max);
    final isComplete = got == max && max > 0;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 10 : 16),
      child: Row(
        children: [
          Container(
            width: isMobile ? 6 : 8,
            height: isMobile ? 6 : 8,
            decoration: BoxDecoration(
              color: isComplete ? color : Colors.grey.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    Text(
                      '${(percent * 100).toInt()}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 9 : 11,
                        fontWeight: FontWeight.w600,
                        color: isComplete ? color : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 4 : 6),
                Stack(
                  children: [
                    Container(
                      height: isMobile ? 4 : 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percent.clamp(0.0, 1.0),
                      child: Container(
                        height: isMobile ? 4 : 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
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

  Widget _buildSkillsOverview() {
    final provider = widget.provider;
    if (provider.skillsList.isEmpty) return const SizedBox();
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
        border: Border.all(color: const Color(0xFFDCE7EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2239).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.diamond_rounded,
                color: const Color(0xFF14507F),
                size: isMobile ? 13 : 16,
              ),
              SizedBox(width: isMobile ? 6 : 10),
              Text(
                'Top Skills',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B2239),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 16),
          Wrap(
            spacing: isMobile ? 6 : 8,
            runSpacing: isMobile ? 6 : 8,
            children: widget.provider.skillsList.take(8).map((skill) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 4 : 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F6F4),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF2EC4B6).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  skill,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 9 : 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF14507F),
                  ),
                ),
              );
            }).toList(),
          ),
          if (widget.provider.skillsList.length > 8)
            Padding(
              padding: EdgeInsets.only(top: isMobile ? 8 : 12),
              child: Text(
                '+ ${widget.provider.skillsList.length - 8} more skills hidden',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 9 : 11,
                  color: const Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard() {
    final provider = widget.provider;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
        border: Border.all(color: const Color(0xFFDCE7EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2239).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.contact_mail_rounded,
                color: const Color(0xFF14507F),
                size: isMobile ? 13 : 16,
              ),
              SizedBox(width: isMobile ? 6 : 10),
              Text(
                'Contact Info',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0B2239),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 20),

          _buildInfoRow(
            Icons.mail_rounded,
            'Email',
            provider.email.isNotEmpty ? provider.email : '—',
          ),
          _buildInfoRow(
            Icons.phone_iphone_rounded,
            'Phone',
            provider.contactNumber.isNotEmpty ? provider.contactNumber : '—',
          ),
          _buildInfoRow(
            Icons.public_rounded,
            'Nationality',
            provider.nationality.isNotEmpty ? provider.nationality : '—',
          ),
          _buildInfoRow(
            Icons.cake_rounded,
            'DOB',
            provider.dob.isNotEmpty ? provider.dob : '—',
          ),

          // Summary Accordion
          if (provider.personalSummary.isNotEmpty) ...[
            const Divider(height: 30),
            Text(
              'About Me',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 11 : 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: Text(
                provider.personalSummary,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 10 : 12,
                  color: const Color(0xFF6B7280),
                  height: 1.6,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                provider.personalSummary,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 10 : 12,
                  color: const Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      _isExpanded ? 'Show Less' : 'Read Full Bio',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF14507F),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: isMobile ? 14 : 16,
                      color: const Color(0xFF14507F),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 10 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1F8),
              borderRadius: BorderRadius.circular(isMobile ? 7 : 9),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF14507F),
              size: isMobile ? 10 : 12,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 9 : 10,
                    color: const Color(0xFF9CA3AF),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
