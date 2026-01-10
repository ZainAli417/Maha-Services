// lib/utils/downloadcv.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;

import '../Screens/Recruiter/LIst_of_Applicants_provider.dart';

/// Mask sensitive information (email, phone)
String maskSensitiveInfo(String info, {bool isEmail = false}) {
  if (info.isEmpty) return info;

  if (isEmail) {
    final parts = info.split('@');
    if (parts.length != 2) return info;
    final username = parts[0];
    final domain = parts[1].split('.');
    if (username.length <= 2) return info;

    // Mask username and domain
    final maskedUsername = '${username.substring(0, 2)}${'*' * (username.length - 2)}';
    final maskedDomain = domain.length > 1
        ? '${domain[0].substring(0, 1)}${'*' * (domain[0].length - 1)}.${domain.sublist(1).join('.')}'
        : domain.join('.');

    return '$maskedUsername@$maskedDomain';
  } else {
    // Phone masking
    if (info.length <= 4) return info;
    return '${info.substring(0, 4)}${'*' * (info.length - 4)}';
  }
}

/// Generate and download/share a professional A4 CV for the given applicant.
Future<void> downloadCvForUser(BuildContext context, String userId, {ApplicantRecord? applicant}) async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Fetch data from the correct structure
    Map<String, dynamic> userData = {};

    if (applicant == null) {
      // Fetch from ProfileSnapshot/{userId}/user_Account_Data
      final doc = await firestore
          .collection('ProfileSnapshot')
          .doc(userId)
          .collection('user_Account_Data')
          .doc(userId)
          .get();

      if (!doc.exists) throw Exception('User profile not found for $userId');
      userData = doc.data()!;
    } else {
      // Get from applicant's profileSnapshot
      userData = Map<String, dynamic>.from(
          applicant.profileSnapshot['user_Account_Data'] ?? {}
      );
    }

    // Extract personalProfile data
    final personalProfile = Map<String, dynamic>.from(userData['personalProfile'] ?? {});
    final name = (personalProfile['name'] ?? 'Candidate').toString();
    final email = maskSensitiveInfo(
        (personalProfile['email'] ?? personalProfile['secondary_email'] ?? '').toString(),
        isEmail: true
    );
    final phone = maskSensitiveInfo((personalProfile['contactNumber'] ?? '').toString());
    final nationality = (personalProfile['nationality'] ?? '').toString();
    final pictureUrl = (personalProfile['profilePicUrl'] ?? '').toString();
    final dob = (personalProfile['dob'] ?? '').toString();
    final objectives = (personalProfile['objectives'] ?? '').toString();
    final skillsList = personalProfile['skills'] is List
        ? (personalProfile['skills'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final socialLinks = personalProfile['socialLinks'] is List
        ? (personalProfile['socialLinks'] as List).map((e) => e.toString()).toList()
        : <String>[];

    // Extract professionalProfile
    final professionalProfile = Map<String, dynamic>.from(userData['professionalProfile'] ?? {});
    final summary = (professionalProfile['summary'] ?? personalProfile['summary'] ?? objectives).toString();

    // Extract educationalProfile
    final educationList = userData['educationalProfile'] is List
        ? List.from(userData['educationalProfile'])
        : <dynamic>[];

    // Extract professionalExperience
    final experiences = userData['professionalExperience'] is List
        ? List.from(userData['professionalExperience'])
        : <dynamic>[];

    // Extract other sections
    final certifications = userData['certifications'] is List
        ? (userData['certifications'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final publications = userData['publications'] is List
        ? (userData['publications'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final awards = userData['awards'] is List
        ? (userData['awards'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final references = userData['references'] is List
        ? (userData['references'] as List).map((e) => e.toString()).toList()
        : <String>[];

    print('📄 CV Data Debug:');
    print('Name: $name');
    print('Email: $email');
    print('Phone: $phone');
    print('Skills: ${skillsList.length}');
    print('Education: ${educationList.length}');
    print('Experience: ${experiences.length}');
    print('Certifications: ${certifications.length}');
    print('Summary: ${summary.isNotEmpty ? "Yes" : "No"}');

    // Build PDF document
    final doc = pw.Document();

    // Load fonts
    final ttfRegular = await PdfGoogleFonts.poppinsRegular();
    final ttfBold = await PdfGoogleFonts.poppinsBold();
    final ttfMedium = await PdfGoogleFonts.poppinsMedium();

    // Fetch profile image
    pw.MemoryImage? profileImage;
    if (pictureUrl.isNotEmpty) {
      try {
        final resp = await http.get(Uri.parse(pictureUrl));
        if (resp.statusCode == 200) {
          profileImage = pw.MemoryImage(resp.bodyBytes);
        }
      } catch (e) {
        print('Failed to load profile image: $e');
      }
    }

    // Build multi-page PDF
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return [
            // === HEADER SECTION ===
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 2)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: Name & Contact
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          name,
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 28,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 10),

                        // Contact Info Grid
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (email.isNotEmpty)
                              _buildContactRow(ttfRegular, ttfBold, 'Email:', email),
                            if (phone.isNotEmpty)
                              _buildContactRow(ttfRegular, ttfBold, 'Phone:', phone),
                            if (nationality.isNotEmpty)
                              _buildContactRow(ttfRegular, ttfBold, 'Nationality:', nationality),
                            if (dob.isNotEmpty)
                              _buildContactRow(ttfRegular, ttfBold, 'DOB:', dob),
                            if (socialLinks.isNotEmpty)
                              _buildContactRow(ttfRegular, ttfBold, 'LinkedIn:', socialLinks.first, isLink: true),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right: Profile Image
                  if (profileImage != null)
                    pw.Container(
                      width: 100,
                      height: 100,
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: PdfColors.blue800, width: 3),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 12,
                        verticalRadius: 12,
                        child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                      ),
                    ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // === PROFESSIONAL SUMMARY ===
            if (summary.isNotEmpty) ...[
              _buildSectionHeader(ttfBold, 'Professional Summary'),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  summary,
                  style: pw.TextStyle(
                    font: ttfRegular,
                    fontSize: 11,
                    height: 1.5,
                    color: PdfColors.grey800,
                  ),
                  textAlign: pw.TextAlign.justify,
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            // === SKILLS ===
            if (skillsList.isNotEmpty) ...[
              _buildSectionHeader(ttfBold, 'Core Skills'),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skillsList.map((skill) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(20),
                      border: pw.Border.all(color: PdfColors.blue200),
                    ),
                    child: pw.Text(
                      skill,
                      style: pw.TextStyle(
                        font: ttfMedium,
                        fontSize: 10,
                        color: PdfColors.blue900,
                      ),
                    ),
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 20),
            ],

            // === PROFESSIONAL EXPERIENCE ===
            _buildSectionHeader(ttfBold, 'Professional Experience'),
            pw.SizedBox(height: 8),
            if (experiences.isNotEmpty)
              ...experiences.map<pw.Widget>((exp) {
                final text = exp is Map ? (exp['text'] ?? '').toString() : exp.toString();

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(left: pw.BorderSide(color: PdfColors.blue800, width: 3)),
                    color: PdfColors.grey50,
                  ),
                  child: pw.Text(
                    text,
                    style: pw.TextStyle(
                      font: ttfRegular,
                      fontSize: 10,
                      height: 1.5,
                    ),
                  ),
                );
              })
            else
              pw.Text(
                'No professional experience listed',
                style: pw.TextStyle(
                  font: ttfRegular,
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),

            pw.SizedBox(height: 20),

            // === EDUCATION ===
            _buildSectionHeader(ttfBold, 'Education'),
            pw.SizedBox(height: 8),
            if (educationList.isNotEmpty)
              ...educationList.map<pw.Widget>((edu) {
                final item = edu is Map ? Map<String, dynamic>.from(edu) : <String, dynamic>{};
                final institution = (item['institutionName'] ?? '').toString();
                final duration = (item['duration'] ?? '').toString();
                final major = (item['majorSubjects'] ?? '').toString();
                final marks = (item['marksOrCgpa'] ?? '').toString();

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (major.isNotEmpty)
                        pw.Text(
                          major,
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 12,
                            color: PdfColors.blue900,
                          ),
                        ),
                      if (institution.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          institution,
                          style: pw.TextStyle(
                            font: ttfMedium,
                            fontSize: 11,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                      if (duration.isNotEmpty || marks.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            if (duration.isNotEmpty)
                              pw.Text(
                                duration,
                                style: pw.TextStyle(
                                  font: ttfRegular,
                                  fontSize: 9,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            if (marks.isNotEmpty)
                              pw.Text(
                                'Grade: $marks',
                                style: pw.TextStyle(
                                  font: ttfRegular,
                                  fontSize: 9,
                                  color: PdfColors.green700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              })
            else
              pw.Text(
                'Education details not provided',
                style: pw.TextStyle(
                  font: ttfRegular,
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),

            pw.SizedBox(height: 20),

            // === CERTIFICATIONS ===
            if (certifications.isNotEmpty) ...[
              _buildSectionHeader(ttfBold, 'Certifications'),
              pw.SizedBox(height: 8),
              ...certifications.map((cert) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 6,
                        height: 6,
                        margin: const pw.EdgeInsets.only(top: 4, right: 8),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.green700,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          cert,
                          style: pw.TextStyle(font: ttfRegular, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 20),
            ],

            // === AWARDS ===
            if (awards.isNotEmpty) ...[
              _buildSectionHeader(ttfBold, 'Awards & Achievements'),
              pw.SizedBox(height: 8),
              ...awards.map((award) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 8,
                        height: 8,
                        margin: const pw.EdgeInsets.only(top: 3, right: 8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.amber,
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: PdfColors.orange, width: 1),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          award,
                          style: pw.TextStyle(font: ttfRegular, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 20),
            ],

            // === PUBLICATIONS ===
            if (publications.isNotEmpty) ...[
              _buildSectionHeader(ttfBold, 'Publications'),
              pw.SizedBox(height: 8),
              ...publications.map((pub) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    pub,
                    style: pw.TextStyle(font: ttfRegular, fontSize: 9, height: 1.4),
                  ),
                );
              }),
              pw.SizedBox(height: 20),
            ],

            // === REFERENCES ===
            _buildSectionHeader(ttfBold, 'References'),
            pw.SizedBox(height: 8),
            if (references.isNotEmpty)
              ...references.take(3).map((ref) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 4,
                        height: 4,
                        margin: const pw.EdgeInsets.only(top: 5, right: 8),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue800,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          ref,
                          style: pw.TextStyle(font: ttfRegular, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              })
            else
              pw.Text(
                'Available upon request',
                style: pw.TextStyle(
                  font: ttfRegular,
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
          ];
        },
        footer: (pw.Context ctx) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
            ),
            child: pw.Text(
              'Generated via YourApp • ${DateTime.now().toLocal().toString().split(' ').first} • Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(
                font: ttfRegular,
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          );
        },
      ),
    );

    // Save and share PDF
    final pdfBytes = await doc.save();
    final filenameSafe = name.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    final filename = 'CV_$filenameSafe.pdf';

    await Printing.sharePdf(bytes: pdfBytes, filename: filename);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('CV generated successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e, st) {
    debugPrint('❌ CV generation failed: $e\n$st');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Failed to generate CV: ${e.toString()}')),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Helper: Build section header
pw.Widget _buildSectionHeader(pw.Font font, String title) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue800, width: 1.5)),
    ),
    child: pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        font: font,
        fontSize: 14,
        color: PdfColors.blue900,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// Helper: Build contact row
pw.Widget _buildContactRow(pw.Font fontRegular, pw.Font fontBold, String label, String text, {bool isLink = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      children: [
        pw.Container(
          width: 90,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            text,
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 10,
              color: isLink ? PdfColors.blue700 : PdfColors.grey900,
            ),
          ),
        ),
      ],
    ),
  );
}