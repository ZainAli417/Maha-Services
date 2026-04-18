import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../Screens/Job_Seeker/JS_Profile/JS_Profile_Provider.dart';

class CVGeneratorButton extends StatefulWidget {
  const CVGeneratorButton({super.key});

  @override
  State<CVGeneratorButton> createState() => _CVGeneratorButtonState();
}

class _CVGeneratorButtonState extends State<CVGeneratorButton> {
  bool _isGenerating = false;

  Future<void> _generateCV() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    final provider = Provider.of<ProfileProvider_NEW>(context, listen: false);

    try {
      final pdfData = await ProfessionalCVGenerator.generateCVBytes(
        name: provider.name,
        email: provider.email,
        secondaryEmail: provider.secondaryEmail,
        contactNumber: provider.contactNumber,
        nationality: provider.nationality,
        dob: provider.dob,
        profilePicUrl: provider.profilePicUrl,
        skillsList: provider.skillsList,
        objectives: provider.objectives,
        personalSummary: provider.personalSummary,
        socialLinks: provider.socialLinks,
        educationalProfile: provider.educationalProfile,
        professionalExperience: provider.professionalExperience,
        professionalProfileSummary: provider.professionalProfileSummary,
        professionalStatus: provider.professionalStatus,
        expectedRetirementDate: provider.expectedRetirementDate,
        retirementDate: provider.retirementDate,
        certifications: provider.certifications,
        certificationDocuments: provider.certificationDocuments,
        experienceDocuments: provider.experienceDocuments,
        publications: provider.publications,
        awards: provider.awards,
        references: provider.references,
        documents: provider.documents,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: '${provider.name.replaceAll(' ', '_')}_Professional_CV.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating CV: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isGenerating ? null : _generateCV,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isGenerating
                    ? [Colors.grey.shade400, Colors.grey.shade500]
                    : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                const SizedBox(width: 12),
                Text(
                  _isGenerating ? 'Preparing...' : 'Download CV',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfessionalCVGenerator {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF6366F1);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF868AF2);
  static const PdfColor textColor = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor lightGray = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor darkGray = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor primaryText = PdfColor.fromInt(0xFF1a1a1a);
  static const PdfColor secondaryText = PdfColor.fromInt(0xFF4a5568);
  static const PdfColor accentBlue = PdfColor.fromInt(0xFF2563eb);
  static const PdfColor lightAccent = PdfColor.fromInt(0xFFe0e7ff);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFd1d5db);
  static const PdfColor sectionBg = PdfColor.fromInt(0xFFf8fafc);

  static String _maskContact(String contact) {
    if (contact.isEmpty || contact.length < 4) return '***-***-****';
    final len = contact.length;
    if (len <= 6) return '***-***';
    return '${contact.substring(0, 3)}${'*' * (len - 6)}${contact.substring(len - 3)}';
  }

  static String _maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return '***@***.***';
    final parts = email.split('@');
    if (parts[0].length <= 2) return '***@${parts[1]}';
    return '${parts[0].substring(0, 2)}${'*' * (parts[0].length - 2)}@${parts[1]}';
  }

  static Future<Uint8List> generateCVBytes({
    required String name,
    required String email,
    required String secondaryEmail,
    required String contactNumber,
    required String nationality,
    required String dob,
    required String profilePicUrl,
    required List<String> skillsList,
    required String objectives,
    required String personalSummary,
    required List<String> socialLinks,
    required List<Map<String, dynamic>> educationalProfile,
    required List<Map<String, dynamic>> professionalExperience,
    required String professionalProfileSummary,
    required String professionalStatus,
    required String expectedRetirementDate,
    required String retirementDate,
    required List<Map<String, String>> certifications,
    required List<Map<String, dynamic>> certificationDocuments,
    required List<Map<String, dynamic>> experienceDocuments,
    required List<String> publications,
    required List<String> awards,
    required List<String> references,
    required List<Map<String, dynamic>> documents,
  }) async {
    final pdf = pw.Document();

    // Load fonts
    final ttfRegular = await PdfGoogleFonts.plusJakartaSansRegular();
    final ttfBold = await PdfGoogleFonts.plusJakartaSansBold();
    final ttfItalic = await PdfGoogleFonts.plusJakartaSansItalic();

    // Load Material Icons font for PDF icons
    pw.Font? iconFont;
    try {
      final iconData = await rootBundle.load(
        'images/MaterialIcons-Regular.ttf',
      );
      iconFont = pw.Font.ttf(iconData);
    } catch (e) {
      debugPrint('Icon font not found: $e');
    }

    // Colorful watermark logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    // Profile picture from URL
    pw.MemoryImage? profileImage;
    if (profilePicUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(profilePicUrl));
        if (response.statusCode == 200) {
          profileImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('Failed to load profile image: $e');
      }
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(25),
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: logoImage != null
            ? pw.Opacity(
                opacity: 0.05,
                child: pw.Center(child: pw.Image(logoImage, width: 420)),
              )
            : pw.SizedBox(),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (context) => [
          // Header on first page
          _buildEnhancedHeader(
            name,
            email,
            secondaryEmail,
            contactNumber,
            nationality,
            dob,
            profileImage,
            socialLinks,
            ttfBold,
            ttfRegular,
            iconFont,
          ),

          // Content sections
          ..._buildAllSections(
            professionalProfileSummary: professionalProfileSummary,
            professionalStatus: professionalStatus,
            expectedRetirementDate: expectedRetirementDate,
            retirementDate: retirementDate,
            objectives: objectives,
            personalSummary: personalSummary,
            skillsList: skillsList,
            professionalExperience: professionalExperience,
            experienceDocuments: experienceDocuments,
            educationalProfile: educationalProfile,
            certifications: certifications,
            certificationDocuments: certificationDocuments,
            publications: publications,
            awards: awards,
            references: references,
            documents: documents,
            ttfBold: ttfBold,
            ttfRegular: ttfRegular,
            ttfItalic: ttfItalic,
            iconFont: iconFont,
          ),
        ],
        footer: (context) => _buildFooter(context.pageNumber, ttfRegular),
      ),
    );

    return pdf.save();
  }

  static List<pw.Widget> _buildAllSections({
    required String professionalProfileSummary,
    required String professionalStatus,
    required String expectedRetirementDate,
    required String retirementDate,
    required String objectives,
    required String personalSummary,
    required List<String> skillsList,
    required List<Map<String, dynamic>> professionalExperience,
    required List<Map<String, dynamic>> experienceDocuments,
    required List<Map<String, dynamic>> educationalProfile,
    required List<Map<String, String>> certifications,
    required List<Map<String, dynamic>> certificationDocuments,
    required List<String> publications,
    required List<String> awards,
    required List<String> references,
    required List<Map<String, dynamic>> documents,
    required pw.Font ttfBold,
    required pw.Font ttfRegular,
    required pw.Font ttfItalic,
    required pw.Font? iconFont,
  }) {
    List<pw.Widget> sections = [];

    // PROFESSIONAL PROFILE
    if (professionalProfileSummary.isNotEmpty) {
      sections.addAll([
        buildSectionTitle('Professional Profile', ttfBold),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: lightGray,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            professionalProfileSummary,
            style: pw.TextStyle(
              font: ttfRegular,
              fontSize: 10,
              lineSpacing: 1.5,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        ),
        if (professionalStatus.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Text(
                'Status: ',
                style: pw.TextStyle(font: ttfBold, fontSize: 9.5),
              ),
              pw.Text(
                professionalStatus == 'serving'
                    ? 'Currently Serving'
                    : 'Retired',
                style: pw.TextStyle(
                  font: ttfRegular,
                  fontSize: 9.5,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
        if (professionalStatus == 'serving' &&
            expectedRetirementDate.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Text(
                'Expected Retirement: ',
                style: pw.TextStyle(font: ttfBold, fontSize: 9.5),
              ),
              pw.Text(
                expectedRetirementDate,
                style: pw.TextStyle(font: ttfRegular, fontSize: 9.5),
              ),
            ],
          ),
        ],
        if (professionalStatus == 'retired' && retirementDate.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Text(
                'Retirement Date: ',
                style: pw.TextStyle(font: ttfBold, fontSize: 9.5),
              ),
              pw.Text(
                retirementDate,
                style: pw.TextStyle(font: ttfRegular, fontSize: 9.5),
              ),
            ],
          ),
        ],
        pw.SizedBox(height: 22),
      ]);
    }

    // OBJECTIVES
    if (objectives.isNotEmpty || personalSummary.isNotEmpty) {
      sections.addAll([
        buildSectionTitle('Career Objectives', ttfBold),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: lightGray,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            objectives.isNotEmpty ? objectives : personalSummary,
            style: pw.TextStyle(
              font: ttfRegular,
              fontSize: 10,
              lineSpacing: 1.5,
            ),
            textAlign: pw.TextAlign.justify,
          ),
        ),
        pw.SizedBox(height: 22),
      ]);
    }

    // SKILLS
    if (skillsList.isNotEmpty) {
      sections.addAll([
        buildSectionTitle('Core Competencies', ttfBold),
        pw.SizedBox(height: 12),
        buildSkillsGrid(skillsList, ttfRegular),
        pw.SizedBox(height: 22),
      ]);
    }

    // EXPERIENCE
    if (professionalExperience.isNotEmpty) {
      sections.addAll([
        buildSectionTitle('Professional Experience', ttfBold),
        pw.SizedBox(height: 12),
        ...professionalExperience.map(
          (exp) => buildExperienceItem(exp, ttfBold, ttfRegular, ttfItalic),
        ),
        if (experienceDocuments.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          buildDocumentLinks(
            'Supporting Documents',
            experienceDocuments,
            ttfBold,
            ttfRegular,
          ),
        ],
        pw.SizedBox(height: 22),
      ]);
    }

    // EDUCATION
    if (educationalProfile.isNotEmpty) {
      sections.addAll([
        buildSectionTitle('Education & Qualifications', ttfBold),
        pw.SizedBox(height: 12),
        ...educationalProfile.map(
          (edu) => buildEducationItem(edu, ttfBold, ttfRegular),
        ),
        pw.SizedBox(height: 22),
      ]);
    }

    // CERTIFICATIONS
    if (certifications.isNotEmpty) {
      sections.addAll([
        buildSectionTitle('Professional Certifications', ttfBold),
        pw.SizedBox(height: 12),
        ...certifications.map(
          (cert) => buildCertificationItem(cert, ttfBold, ttfRegular),
        ),
        if (certificationDocuments.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          buildDocumentLinks(
            'Certification Documents',
            certificationDocuments,
            ttfBold,
            ttfRegular,
          ),
        ],
        pw.SizedBox(height: 22),
      ]);
    }

    // PUBLICATIONS
    if (publications.isNotEmpty) {
      sections.addAll([
        buildSectionTitle('Publications & Research', ttfBold),
        pw.SizedBox(height: 12),
        ...publications.map((pub) => buildBulletItem(pub, ttfRegular)),
        pw.SizedBox(height: 22),
      ]);
    }

    // AWARDS
    if (awards.isNotEmpty) {
      sections.addAll([
        buildSectionTitle('Awards & Honors', ttfBold),
        pw.SizedBox(height: 12),
        ...awards.map((award) => buildBulletItem(award, ttfRegular)),
        pw.SizedBox(height: 22),
      ]);
    }

    // REFERENCES
    if (references.isNotEmpty) {
      sections.addAll([
        buildSectionTitle('Professional References', ttfBold),
        pw.SizedBox(height: 12),
        ...references.map((ref) => buildBulletItem(ref, ttfRegular)),
        pw.SizedBox(height: 22),
      ]);
    }

    // ADDITIONAL DOCUMENTS
    if (documents.isNotEmpty) {
      sections.addAll([
        buildSectionTitle('Additional Documents', ttfBold),
        pw.SizedBox(height: 12),
        buildDocumentLinks('Attached Files', documents, ttfBold, ttfRegular),
      ]);
    }

    return sections;
  }

  static pw.Widget _buildEnhancedHeader(
    String name,
    String email,
    String secondaryEmail,
    String phone,
    String nationality,
    String dob,
    pw.MemoryImage? profileImage,
    List<String> socialLinks,
    pw.Font bold,
    pw.Font reg,
    pw.Font? iconFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20, top: 5),
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: borderColor, width: 1.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Profile image - subtle and professional
          if (profileImage != null)
            pw.Container(
              width: 70,
              height: 70,
              margin: const pw.EdgeInsets.only(right: 24),

              child: pw.ClipRRect(
                horizontalRadius: 4,
                verticalRadius: 4,
                child: pw.Image(profileImage, fit: pw.BoxFit.cover),
              ),
            ),

          // Name and contact info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Name with subtle spacing
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 24,
                    letterSpacing: 0.5,
                    color: primaryText,
                  ),
                ),
                pw.SizedBox(height: 12),

                // Contact grid - clean and organized
                pw.Wrap(
                  spacing: 20,
                  runSpacing: 6,
                  children: [
                    _contactChip(email, reg),
                    _contactChip(phone, reg),
                    if (nationality.isNotEmpty) _contactChip(nationality, reg),
                    if (dob.isNotEmpty) _contactChip(dob, reg),
                  ],
                ),

                // Social links if present
                if (socialLinks.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    socialLinks.first
                        .replaceAll('https://', '')
                        .replaceAll('http://', ''),
                    style: pw.TextStyle(
                      font: reg,
                      fontSize: 8.5,
                      color: accentBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _contactChip(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: sectionBg,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 9, color: secondaryText),
      ),
    );
  }

  static pw.Widget buildSectionTitle(String title, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16, bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: accentBlue, width: 2)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: font,
          fontSize: 13,
          color: primaryText,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static pw.Widget buildSkillsGrid(List<String> skills, pw.Font font) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: skills
          .map(
            (s) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderColor, width: 1),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(
                s,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 9,
                  color: primaryText,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget buildExperienceItem(
    Map<String, dynamic> exp,
    pw.Font bold,
    pw.Font reg,
    pw.Font italic,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Timeline marker - subtle visual hierarchy
          pw.Container(
            width: 3,
            height: 16,
            margin: const pw.EdgeInsets.only(right: 14, top: 2),
            color: accentBlue,
          ),

          // Content
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        exp['role']?.toString() ?? 'Position',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 11,
                          color: primaryText,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text(
                      exp['duration']?.toString() ?? '',
                      style: pw.TextStyle(
                        font: reg,
                        fontSize: 9,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),

                // Organization
                if (exp['organization']?.toString().isNotEmpty ?? false) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    exp['organization'].toString(),
                    style: pw.TextStyle(
                      font: italic,
                      fontSize: 10,
                      color: accentBlue,
                    ),
                  ),
                ],

                // Metadata in a clean grid
                pw.SizedBox(height: 6),
                pw.Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (exp['rank']?.toString().isNotEmpty ?? false)
                      _metaItem('Rank', exp['rank'].toString(), reg),
                    if (exp['location']?.toString().isNotEmpty ?? false)
                      _metaItem('Location', exp['location'].toString(), reg),
                    if (exp['command']?.toString().isNotEmpty ?? false)
                      _metaItem('Command', exp['command'].toString(), reg),
                    if (exp['aircraftType']?.toString().isNotEmpty ?? false)
                      _metaItem(
                        'Aircraft',
                        exp['aircraftType'].toString(),
                        reg,
                      ),
                    if (exp['flightHours']?.toString().isNotEmpty ?? false)
                      _metaItem('Hours', exp['flightHours'].toString(), reg),
                  ],
                ),

                // Duties/Description
                if (exp['duties']?.toString().isNotEmpty ?? false) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    exp['duties'].toString(),
                    style: pw.TextStyle(
                      font: reg,
                      fontSize: 9.5,
                      color: secondaryText,
                      lineSpacing: 1.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaItem(String label, String value, pw.Font font) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(
              font: font,
              fontSize: 8.5,
              color: secondaryText,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.TextSpan(
            text: value,
            style: pw.TextStyle(
              font: font,
              fontSize: 8.5,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildEducationItem(
    Map<String, dynamic> edu,
    pw.Font bold,
    pw.Font reg,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: sectionBg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  edu['institutionName']?.toString() ?? 'Institution',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 10.5,
                    color: primaryText,
                  ),
                ),
              ),
              if (edu['duration']?.toString().isNotEmpty ?? false)
                pw.Text(
                  edu['duration'].toString(),
                  style: pw.TextStyle(
                    font: reg,
                    fontSize: 8.5,
                    color: secondaryText,
                  ),
                ),
            ],
          ),

          if (edu['majorSubjects']?.toString().isNotEmpty ?? false) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              edu['majorSubjects'].toString(),
              style: pw.TextStyle(font: reg, fontSize: 9.5, color: accentBlue),
            ),
          ],

          if (edu['marksOrCgpa']?.toString().isNotEmpty ?? false) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Grade: ${edu['marksOrCgpa']}',
              style: pw.TextStyle(font: reg, fontSize: 9, color: secondaryText),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget buildCertificationItem(
    Map<String, String> cert,
    pw.Font bold,
    pw.Font reg,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 5, right: 10),
            decoration: const pw.BoxDecoration(
              color: accentBlue,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  cert['name'] ?? 'Certification',
                  style: pw.TextStyle(
                    font: bold,
                    fontSize: 9.5,
                    color: primaryText,
                  ),
                ),
                if (cert['organization']?.isNotEmpty ?? false) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    cert['organization']!,
                    style: pw.TextStyle(
                      font: reg,
                      fontSize: 8.5,
                      color: secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildBulletItem(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6, left: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 5, right: 10),
            decoration: const pw.BoxDecoration(
              color: accentBlue,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                font: font,
                fontSize: 9.5,
                color: secondaryText,
                lineSpacing: 1.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildDocumentLinks(
    String title,
    List<Map<String, dynamic>> docs,
    pw.Font bold,
    pw.Font reg,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(14),
      margin: const pw.EdgeInsets.only(top: 12),
      decoration: pw.BoxDecoration(
        color: lightAccent,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: accentBlue.flatten(), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: bold, fontSize: 10, color: primaryText),
          ),
          pw.SizedBox(height: 8),
          ...docs.map((doc) {
            final name = doc['name']?.toString() ?? 'Document';
            final url = doc['url']?.toString() ?? '';
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• $name',
                    style: pw.TextStyle(
                      font: reg,
                      fontSize: 9,
                      color: primaryText,
                    ),
                  ),
                  if (url.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 12, top: 1),
                      child: pw.Text(
                        url.length > 70 ? '${url.substring(0, 70)}...' : url,
                        style: pw.TextStyle(
                          font: reg,
                          fontSize: 7.5,
                          color: secondaryText,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(int pageNumber, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: accentColor, width: 1.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated via MAHA Services Portal',
            style: pw.TextStyle(font: font, fontSize: 8, color: darkGray),
          ),
          pw.Text(
            'Page $pageNumber',
            style: pw.TextStyle(font: font, fontSize: 8, color: darkGray),
          ),
        ],
      ),
    );
  }
}
