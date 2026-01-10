// cv_generator.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Adjust this import path if your provider file is elsewhere
import '../Screens/Job_Seeker/JS_Profile/JS_Profile_Provider.dart';

class CVGeneratorButton extends StatelessWidget {
  const CVGeneratorButton({super.key});

  int computeTotalScore(ProfileProvider_NEW p) {
    const int segments = 5;
    int filled = 0;

    final personalComplete = p.name.trim().isNotEmpty && p.personalSummary.trim().isNotEmpty;
    if (personalComplete) filled++;

    if (p.educationalProfile.isNotEmpty) filled++;
    if (p.professionalExperience.isNotEmpty) filled++;
    if (p.certifications.isNotEmpty) filled++;
    if (p.skillsList.isNotEmpty) filled++;

    final percent = (filled / segments * 100).round();
    return percent;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider_NEW>(
      builder: (context, provider, _) {
        final totalScore = computeTotalScore(provider);

        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              totalScore >= 65 ? const Color(0xFF1E3A8A) : const Color(0xFF9CA3AF),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: totalScore >= 65
                ? () => showDialog(
              context: context,
              builder: (_) => CVPreviewDialog(provider: provider),
            )
                : null,
            icon: const FaIcon(FontAwesomeIcons.download, size: 18, color: Colors.white),
            label: const Text(
              'Download CV',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CVPreviewDialog extends StatelessWidget {
  final ProfileProvider_NEW provider;
  const CVPreviewDialog({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 850),
        child: Column(
          children: [
            // Header with avatar & name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:  Color(0xff5C738A),
                    backgroundImage: provider.profilePicUrl.isNotEmpty
                        ? NetworkImage(provider.profilePicUrl)
                        : null,
                    child: provider.profilePicUrl.isEmpty
                        ? Text(
                      _initials(provider.fullName),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.fullName.isNotEmpty ? provider.fullName : 'Unnamed',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.professionalExperience.isNotEmpty
                              ? (provider.professionalExperience.first['role'] ?? '')
                              : (provider.professionalProfileSummary.isNotEmpty
                              ? provider.professionalProfileSummary
                              : ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // PDF preview area - Increased height
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: PdfPreview(
                  allowPrinting: true,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  maxPageWidth: 700,
                  canChangePageFormat: false,
                  useActions: false, // Remove the purple ribbon with icons
                  actions: const [], // Remove all default actions
                  build: (format) => _generatePdf(provider),
                ),
              ),
            ),

            // Footer - Only Print button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Printing.layoutPdf(
                        onLayout: (format) => _generatePdf(provider),
                      );
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // Helper function to mask contact information
  String _maskContact(String contact) {
    if (contact.isEmpty) return '';
    if (contact.length <= 4) return contact;

    final start = contact.substring(0, 2);
    final end = contact.substring(contact.length - 2);
    final middle = '*' * (contact.length - 4);
    return '$start$middle$end';
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return '';
    if (!email.contains('@')) return _maskContact(email);

    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 3) {
      return '${username[0]}${'*' * (username.length - 1)}@$domain';
    }

    final start = username.substring(0, 2);
    final end = username.substring(username.length - 1);
    final middle = '*' * (username.length - 3);
    return '$start$middle$end@$domain';
  }

  /// Builds professional PDF with modern design
  Future<Uint8List> _generatePdf(ProfileProvider_NEW p) async {
    final doc = pw.Document();

    // Load fonts - Using Poppins
    final pw.Font regular = await PdfGoogleFonts.poppinsRegular();
    final pw.Font bold = await PdfGoogleFonts.poppinsBold();
    final pw.Font semiBold = await PdfGoogleFonts.poppinsSemiBold();
    final pw.Font medium = await PdfGoogleFonts.poppinsMedium();

    // Fetch avatar
    pw.ImageProvider? avatarImage;
    if (p.profilePicUrl.isNotEmpty) {
      try {
        avatarImage = await networkImage(p.profilePicUrl);
      } catch (_) {
        avatarImage = null;
      }
    }

    // Load logo watermark
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    // Define colors
    final primaryColor = PdfColor.fromHex('#1E3A8A');
    final accentColor = PdfColor.fromHex('#3B82F6');
    final textColor = PdfColor.fromHex('#111827');
    final lightGray = PdfColor.fromHex('#F3F4F6');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Modern header with gradient effect
            pw.Container(
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [
                    PdfColor.fromHex('#1E3A8A'),
                    PdfColor.fromHex('#2563EB'),
                  ],
                ),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              padding: const pw.EdgeInsets.all(15),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Avatar
                  if (avatarImage != null)
                    pw.Container(
                      width: 80,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: PdfColors.white, width: 3),
                      ),
                      child: pw.ClipOval(
                        child: pw.Image(avatarImage, fit: pw.BoxFit.cover),
                      ),
                    )
                  else
                    pw.Container(
                      width: 80,
                      height: 80,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.white,
                      ),
                      child: pw.Text(
                        _initialsForPdf(p.fullName),
                        style: pw.TextStyle(font: bold, fontSize: 28, color: primaryColor),
                      ),
                    ),
                  pw.SizedBox(width: 20),

                  // Name and title
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          p.fullName.isNotEmpty ? p.fullName.toUpperCase() : 'UNNAMED',
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 24,
                            color: PdfColors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          p.professionalExperience.isNotEmpty
                              ? (p.professionalExperience.first['role'] ?? 'Professional')
                              : (p.professionalProfileSummary.isNotEmpty
                              ? p.professionalProfileSummary
                              : 'Professional'),
                          style: pw.TextStyle(
                            font: regular,
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        // Contact information
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (p.email.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 3),
                                child: pw.Text(
                                  'Email: ${_maskEmail(p.email)}',
                                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.white),
                                ),
                              ),
                            if (p.contactNumber.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 3),
                                child: pw.Text(
                                  'Phone: ${_maskContact(p.contactNumber)}',
                                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.white),
                                ),
                              ),
                            if (p.secondaryEmail.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 3),
                                child: pw.Text(
                                  'Alt Email: ${_maskEmail(p.secondaryEmail)}',
                                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.white),
                                ),
                              ),
                            if (p.socialLinks.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 3),
                                child: pw.Text(
                                  'Social: ${_maskContact(p.socialLinks as String)}',
                                  style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColors.white),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Professional Summary
            _buildSection(
              title: 'Professional Summary',
              bold: bold,
              semiBold: semiBold,
              regular: regular,
              primaryColor: primaryColor,
              child: pw.Text(
                p.personalSummary.isNotEmpty
                    ? p.personalSummary
                    : (p.professionalProfileSummary.isNotEmpty
                    ? p.professionalProfileSummary
                    : 'No summary provided.'),
                style: pw.TextStyle(font: regular, fontSize: 10, height: 1.5, color: textColor),
                textAlign: pw.TextAlign.justify,
              ),
            ),

            // Professional Experience
            _buildSection(
              title: 'Professional Experience',
              bold: bold,
              semiBold: semiBold,
              regular: regular,
              primaryColor: primaryColor,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: _buildExperience(p, regular, semiBold, accentColor, textColor),
              ),
            ),

            // Education
            _buildSection(
              title: 'Education',
              bold: bold,
              semiBold: semiBold,
              regular: regular,
              primaryColor: primaryColor,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: _buildEducation(p, regular, semiBold, accentColor, textColor),
              ),
            ),

            // Skills
            if (p.skillsList.isNotEmpty)
              _buildSection(
                title: 'Skills',
                bold: bold,
                semiBold: semiBold,
                regular: regular,
                primaryColor: primaryColor,
                child: pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: p.skillsList.map((skill) {
                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: lightGray,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: accentColor.shade(0.3)),
                      ),
                      child: pw.Text(
                        skill,
                        style: pw.TextStyle(font: medium, fontSize: 9, color: textColor),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Certifications
            if (p.certifications.isNotEmpty)
              _buildSection(
                title: 'Certifications',
                bold: bold,
                semiBold: semiBold,
                regular: regular,
                primaryColor: primaryColor,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: p.certifications.map((cert) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 4,
                            height: 4,
                            margin: const pw.EdgeInsets.only(top: 4, right: 8),
                            decoration: pw.BoxDecoration(
                              color: accentColor,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              cert.toString(),
                              style: pw.TextStyle(font: regular, fontSize: 10, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Publications
            if (p.publications.isNotEmpty)
              _buildSection(
                title: 'Publications',
                bold: bold,
                semiBold: semiBold,
                regular: regular,
                primaryColor: primaryColor,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: p.publications.map((pub) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 4,
                            height: 4,
                            margin: const pw.EdgeInsets.only(top: 4, right: 8),
                            decoration: pw.BoxDecoration(
                              color: accentColor,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              pub.toString(),
                              style: pw.TextStyle(font: regular, fontSize: 10, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Awards
            if (p.awards.isNotEmpty)
              _buildSection(
                title: 'Awards & Achievements',
                bold: bold,
                semiBold: semiBold,
                regular: regular,
                primaryColor: primaryColor,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: p.awards.map((award) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 4,
                            height: 4,
                            margin: const pw.EdgeInsets.only(top: 4, right: 8),
                            decoration: pw.BoxDecoration(
                              color: accentColor,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              award.toString(),
                              style: pw.TextStyle(font: regular, fontSize: 10, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // References
            if (p.references.isNotEmpty)
              _buildSection(
                title: 'References',
                bold: bold,
                semiBold: semiBold,
                regular: regular,
                primaryColor: primaryColor,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: p.references.map((ref) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 4,
                            height: 4,
                            margin: const pw.EdgeInsets.only(top: 4, right: 8),
                            decoration: pw.BoxDecoration(
                              color: accentColor,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              ref.toString(),
                              style: pw.TextStyle(font: regular, fontSize: 10, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ];
        },
        header: (context) {
          // Logo in top right corner on every page (original without opacity)
          if (logoImage != null) {
            return pw.Container(
              alignment: pw.Alignment.topRight,
              margin: const pw.EdgeInsets.only(right: 0, top: 0,bottom: 10),
              child: pw.Image(logoImage, width: 90, height: 80),
            );
          }
          return pw.SizedBox();
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 12),
            child: pw.Text(
              'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())} | Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildSection({
    required String title,
    required pw.Font bold,
    required pw.Font semiBold,
    required pw.Font regular,
    required PdfColor primaryColor,
    required pw.Widget child,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 18),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: bold,
              fontSize: 14,
              color: primaryColor,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: 60,
            height: 3,
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  List<pw.Widget> _buildEducation(
      ProfileProvider_NEW p,
      pw.Font regular,
      pw.Font semiBold,
      PdfColor accentColor,
      PdfColor textColor,
      ) {
    if (p.educationalProfile.isEmpty) {
      return [
        pw.Text(
          'No education entries provided',
          style: pw.TextStyle(font: regular, fontSize: 10, fontStyle: pw.FontStyle.italic, color: textColor),
        ),
      ];
    }

    return p.educationalProfile.map((e) {
      final school = (e['institutionName'] ?? e['school'] ?? '').toString();
      final degree = (e['marksOrCgpa'] ?? e['degree'] ?? '').toString();
      final field = (e['majorSubjects'] ?? e['fieldOfStudy'] ?? '').toString();
      final start = (e['eduStart'] ?? '').toString();
      final end = (e['eduEnd'] ?? e['duration'] ?? '').toString();

      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 6,
              height: 6,
              margin: const pw.EdgeInsets.only(top: 4, right: 10),
              decoration: pw.BoxDecoration(
                color: accentColor,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    degree,
                    style: pw.TextStyle(font: semiBold, fontSize: 11, color: textColor),
                  ),
                  if (field.isNotEmpty)
                    pw.Text(
                      field,
                      style: pw.TextStyle(font: regular, fontSize: 10, color: textColor),
                    ),
                  if (school.isNotEmpty)
                    pw.Text(
                      school,
                      style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey800),
                    ),
                  if (start.isNotEmpty || end.isNotEmpty)
                    pw.Text(
                      '$start${start.isNotEmpty && end.isNotEmpty ? ' - ' : ''}$end',
                      style: pw.TextStyle(font: regular, fontSize: 9, color: accentColor),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<pw.Widget> _buildExperience(
      ProfileProvider_NEW p,
      pw.Font regular,
      pw.Font semiBold,
      PdfColor accentColor,
      PdfColor textColor,
      ) {
    if (p.professionalExperience.isEmpty) {
      return [
        pw.Text(
          'No professional experience listed',
          style: pw.TextStyle(font: regular, fontSize: 10, fontStyle: pw.FontStyle.italic, color: textColor),
        ),
      ];
    }

    return p.professionalExperience.map((exp) {
      final role = (exp['role'] ?? exp['title'] ?? '').toString();
      final company = (exp['company'] ?? '').toString();
      final start = (exp['expStart'] ?? '').toString();
      final end = (exp['expEnd'] ?? '').toString();
      final text = (exp['expDescription'] ?? exp['text'] ?? '').toString();

      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 14),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 6,
              height: 6,
              margin: const pw.EdgeInsets.only(top: 4, right: 10),
              decoration: pw.BoxDecoration(
                color: accentColor,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    role,
                    style: pw.TextStyle(font: semiBold, fontSize: 11, color: textColor),
                  ),
                  if (company.isNotEmpty)
                    pw.Text(
                      company,
                      style: pw.TextStyle(font: regular, fontSize: 10, color: textColor),
                    ),
                  if (start.isNotEmpty || end.isNotEmpty)
                    pw.Text(
                      '$start${start.isNotEmpty && end.isNotEmpty ? ' - ' : ''}$end',
                      style: pw.TextStyle(font: regular, fontSize: 9, color: accentColor),
                    ),
                  if (text.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 6),
                      child: pw.Text(
                        text,
                        style: pw.TextStyle(font: regular, fontSize: 10, height: 1.4, color: textColor),
                        textAlign: pw.TextAlign.justify,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _initialsForPdf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}