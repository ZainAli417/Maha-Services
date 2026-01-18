import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Assuming this import exists in your project structure
import '../Screens/Recruiter/LIst_of_Applicants_provider.dart';

class ViewApplicantDetails extends StatelessWidget {
  final ApplicantRecord applicant;

  const ViewApplicantDetails({super.key, required this.applicant});

  // --- Utility Methods ---

  String _maskSensitive(String value, {bool isEmail = false}) {
    if (value.isEmpty) return 'Not provided';
    if (isEmail) {
      final parts = value.split('@');
      if (parts.length != 2) return value;
      return '${parts[0].substring(0, 2)}***@${parts[1]}';
    }
    if (value.length <= 4) return '****';
    return '${value.substring(0, 2)}****${value.substring(value.length - 2)}';
  }

  // --- UI Constants ---
  static const Color _primaryColor = Color(0xFF0F172A); // Slate 900
  static const Color _accentColor = Color(0xFF4F46E5); // Indigo 600
  static const Color _bgSecondary = Color(0xFFF8FAFC); // Slate 50
  static const Color _textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color _textSecondary = Color(0xFF64748B); // Slate 500

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsive layout
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWideScreen ? 60 : 16,
        vertical: 24,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 850),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Sidebar (Personal Info & Stats) - Visible on Wide Screens
                    if (isWideScreen)
                      Container(
                        width: 320,
                        decoration: const BoxDecoration(
                          color: _bgSecondary,
                          border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _buildSidebarContent(),
                        ),
                      ),

                    // Main Content Area
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // On mobile, show sidebar content at top
                            if (!isWideScreen) ...[
                              _buildSidebarContent(),
                              const Divider(height: 48),
                            ],

                            // Professional Summary
                            _buildSectionTitle('Executive Summary', Icons.dashboard_outlined),
                            const SizedBox(height: 16),
                            Text(
                              applicant.summary.isNotEmpty ? applicant.summary : applicant.objectives,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                height: 1.6,
                                color: _textPrimary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Experience Section - ENHANCED
                            _buildSectionTitle('Professional Experience', Icons.work_history_outlined),
                            const SizedBox(height: 20),
                            ...applicant.experiences.map(_buildEnhancedExperienceTile),
                            if(applicant.experiences.isEmpty) _buildEmptyState('No experience listed'),

                            const SizedBox(height: 40),

                            // Education Section
                            _buildSectionTitle('Education', Icons.school_outlined),
                            const SizedBox(height: 20),
                            ...applicant.educations.map(_buildEducationTile),
                            if(applicant.educations.isEmpty) _buildEmptyState('No education listed'),

                            const SizedBox(height: 40),

                            // Certifications Section - ENHANCED
                            _buildSectionTitle('Certifications & Licenses', Icons.verified_user_outlined),
                            const SizedBox(height: 20),
                            if (applicant.certifications.isNotEmpty)
                              _buildCertificationsGrid()
                            else
                              _buildEmptyState('No certifications listed'),

                            // Certification Documents (if available)
                            if (applicant.certifications.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildSectionTitle('Certification Documents', Icons.attach_file_outlined),
                              const SizedBox(height: 16),
                              ...applicant.certifications.map(_buildDocumentTile),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              //_buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header Section ---
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Avatar with Status Ring
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: _bgSecondary,
                  backgroundImage: applicant.pictureUrl.isNotEmpty
                      ? NetworkImage(applicant.pictureUrl)
                      : null,
                  child: applicant.pictureUrl.isEmpty
                      ? Text(
                    applicant.name.isNotEmpty ? applicant.name[0] : '?',
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor),
                  )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(
                    applicant.status == 'accepted' ? Icons.check_circle : Icons.circle,
                    color: applicant.status == 'accepted' ? Colors.green : Colors.amber,
                    size: 20,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 20),
          // Name & Headline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applicant.name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  applicant.jobData?.title ?? 'Applicant Role',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildHeaderBadge(Icons.location_on_outlined, applicant.nationality),
                    const SizedBox(width: 12),
                    _buildHeaderBadge(Icons.cake_outlined, applicant.dob),
                  ],
                )
              ],
            ),
          ),
          // Close Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: _bgSecondary,
              foregroundColor: _textSecondary,
            ),
          )
        ],
      ),
    );
  }

  // --- Sidebar Content ---
  Widget _buildSidebarContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebarSectionTitle('Contact Details'),
        const SizedBox(height: 16),
        _buildContactRow(Icons.email_outlined, _maskSensitive(applicant.email, isEmail: true), 'Email'),
        const SizedBox(height: 12),
        _buildContactRow(Icons.phone_outlined, _maskSensitive(applicant.phone), 'Phone'),

        const SizedBox(height: 32),
        _buildSidebarSectionTitle('Skills'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: applicant.skills.map((skill) => Chip(
            label: Text(skill, style: GoogleFonts.poppins(fontSize: 12, color: _primaryColor)),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )).toList(),
        ),

        const SizedBox(height: 32),
        _buildSidebarSectionTitle('Quick Stats'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatBox('${applicant.experienceYears}+', 'Years Exp.')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatBox('${applicant.certifications.length}', 'Certs')),
          ],
        ),

        if (applicant.socialLinks.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSidebarSectionTitle('Social'),
          const SizedBox(height: 12),
          ...applicant.socialLinks.map((link) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.link, size: 16, color: _accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Link Hidden',
                    style: GoogleFonts.poppins(fontSize: 13, color: _accentColor, decoration: TextDecoration.underline),
                  ),
                )
              ],
            ),
          )),
        ]
      ],
    );
  }

  // --- ENHANCED EXPERIENCE TILE WITH ALL FIELDS ---
  Widget _buildEnhancedExperienceTile(Map<String, dynamic> exp) {
    // Extract all fields from updated structure
    final role = exp['role']?.toString() ?? 'Role Not Specified';
    final organization = exp['organization']?.toString() ?? 'Unknown Organization';
    final duration = exp['duration']?.toString() ?? '';
    final startDate = exp['startDate']?.toString() ?? '';
    final endDate = exp['endDate']?.toString() ?? '';
    final duties = exp['duties']?.toString() ?? exp['text']?.toString() ?? '';

    // Military-specific fields
    final rank = exp['rank']?.toString() ?? '';
    final unit = exp['unit']?.toString() ?? '';
    final location = exp['location']?.toString() ?? '';
    final command = exp['command']?.toString() ?? '';
    final aircraftType = exp['aircraftType']?.toString() ?? '';
    final flightHours = exp['flightHours']?.toString() ?? '';

    // Determine if this is military experience
    final isMilitaryExp = rank.isNotEmpty || unit.isNotEmpty || command.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isMilitaryExp ? Icons.military_tech : Icons.business_center,
                  color: _accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Title & Organization
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      organization,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Duration Badge
              if (duration.isNotEmpty || startDate.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _bgSecondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: _textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        duration.isNotEmpty
                            ? duration
                            : '${startDate}${endDate.isNotEmpty ? ' - $endDate' : ' - Present'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Military-specific details (if applicable)
          if (isMilitaryExp) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  if (rank.isNotEmpty) _buildInfoChip(Icons.stars, 'Rank', rank),
                  if (unit.isNotEmpty) _buildInfoChip(Icons.group, 'Unit', unit),
                  if (command.isNotEmpty) _buildInfoChip(Icons.flag, 'Command', command),
                  if (location.isNotEmpty) _buildInfoChip(Icons.location_on, 'Location', location),
                  if (aircraftType.isNotEmpty) _buildInfoChip(Icons.flight, 'Aircraft', aircraftType),
                  if (flightHours.isNotEmpty) _buildInfoChip(Icons.schedule, 'Flight Hours', flightHours),
                ],
              ),
            ),
          ],

          // Duties/Description
          if (duties.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            Text(
              'Key Responsibilities',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              duties,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _textPrimary,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper widget for military/additional info chips
  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: _primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- ENHANCED CERTIFICATIONS GRID ---
  Widget _buildCertificationsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid columns
        int crossAxisCount = 3;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3.8,
          ),
          itemCount: applicant.certifications.length,
          itemBuilder: (context, index) {
            return _buildEnhancedCertificationCard(applicant.certifications[index]);
          },
        );
      },
    );
  }

  Widget _buildEnhancedCertificationCard(Map<String, String> cert) {
    final certName = cert['name'] ?? 'Certification';
    final organization = cert['organization'] ?? 'Organization Not Specified';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _bgSecondary,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _accentColor.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.verified,
              color: _accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  certName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                    height: 1.3,
                  ),
                ),
                if (organization.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.business, size: 11, color: _textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          organization,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _textSecondary,
                          ),
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

  // --- DOCUMENT TILE (for certification/experience documents) ---
  Widget _buildDocumentTile(Map<String, dynamic> doc) {
    final name = doc['name']?.toString() ?? 'Document';
    final url = doc['url']?.toString() ?? '';
    final contentType = doc['contentType']?.toString() ?? '';

    IconData docIcon = Icons.insert_drive_file;
    if (contentType.contains('pdf')) {
      docIcon = Icons.picture_as_pdf;
    } else if (contentType.contains('image')) {
      docIcon = Icons.image;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(docIcon, size: 18, color: _accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _primaryColor,
                  ),
                ),
                if (contentType.isNotEmpty)
                  Text(
                    contentType.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: _textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download, size: 18),
              color: _accentColor,
              onPressed: () {
                // Download logic here
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEducationTile(Map<String, dynamic> edu) {
    final institution = edu['institutionName']?.toString() ?? 'Institution';
    final major = edu['majorSubjects']?.toString() ?? '';
    final duration = edu['duration']?.toString() ?? '';
    final cgpa = edu['marksOrCgpa']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school, color: _textSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  institution,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: _primaryColor),
                ),
                if(major.isNotEmpty)
                  Text(
                    major,
                    style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
                  ),
                if(cgpa.isNotEmpty)
                  Text(
                    'CGPA: $cgpa',
                    style: GoogleFonts.poppins(fontSize: 12, color: _accentColor, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          if(duration.isNotEmpty)
            Text(
              duration,
              style: GoogleFonts.poppins(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _accentColor),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _textSecondary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF94A3B8), // Slate 400
        textBaseline: TextBaseline.alphabetic,
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bgSecondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF94A3B8)),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _accentColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      // child: Row(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   children: [
      //     TextButton(
      //       onPressed: () => Navigator.pop(context),
      //       style: TextButton.styleFrom(
      //         foregroundColor: _textSecondary,
      //         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      //       ),
      //       child: Text(
      //         'Close',
      //         style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      //       ),
      //     ),
      //     const SizedBox(width: 16),
      //     ElevatedButton.icon(
      //       onPressed: () {
      //         // Your download logic here
      //         ScaffoldMessenger.of(context).showSnackBar(
      //           const SnackBar(content: Text('Downloading CV...')),
      //         );
      //       },
      //       icon: const Icon(Icons.download, size: 18),
      //       label: Text(
      //         'Download Resume',
      //         style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      //       ),
      //       style: ElevatedButton.styleFrom(
      //         backgroundColor: _primaryColor,
      //         foregroundColor: Colors.white,
      //         elevation: 0,
      //         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      //         shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(8),
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}