import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:job_portal/Screens/Recruiter/shortlisting_provider.dart';

class CandidateDetailsDialog extends StatelessWidget {
  final Candidate candidate;
  final Map<String, dynamic>? profile;

  const CandidateDetailsDialog({
    required this.candidate,
    required this.profile,
    super.key,
  });

  // --- Theme Constants ---
  static const Color _brandPrimary = Color(0xFF4F46E5); // Indigo 600
  static const Color _textMain = Color(0xFF0F172A);    // Slate 900
  static const Color _textMuted = Color(0xFF64748B);   // Slate 500
  static const Color _bgSurface = Colors.white;
  static const Color _bgSubtle = Color(0xFFF8FAFC);    // Slate 50
  static const Color _borderColor = Color(0xFFE2E8F0); // Slate 200

  // Helper: fetch nested canonical personal map if exists
  Map<String, dynamic> _personal(Map<String, dynamic> p) {
    if (p.containsKey('personalProfile') && p['personalProfile'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(p['personalProfile'] as Map<String, dynamic>);
    }
    if (p.containsKey('personal') && p['personal'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(p['personal'] as Map<String, dynamic>);
    }
    return p;
  }

  // Safely read list fields with multiple fallback keys
  List<Map<String, dynamic>> _readList(Map<String, dynamic> p, List<String> keys) {
    for (final k in keys) {
      final v = p[k];
      if (v == null) continue;

      if (v is List) {
        return v.map<Map<String, dynamic>>((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return {'text': e?.toString() ?? ''};
        }).toList();
      }

      if (v is Map) {
        final out = <Map<String, dynamic>>[];
        for (final val in v.values) {
          if (val is Map) {
            out.add(Map<String, dynamic>.from(val));
          } else {
            out.add({'text': val?.toString() ?? ''});
          }
        }
        return out;
      }

      if (v is String && v.isNotEmpty) {
        return [{'text': v}];
      }
    }
    return [];
  }

  // Read and normalize documents from various keys
  List<Map<String, dynamic>> _readDocuments(Map<String, dynamic> p) {
    final keys = ['documents', 'docuemnts', 'documentsList', 'documentsArray', 'docs', 'files'];
    for (final k in keys) {
      final v = p[k];
      if (v == null) continue;

      List<Map<String, dynamic>> toList = [];
      if (v is List) {
        toList = v.map((e) {
          if (e is Map) return Map<String, dynamic>.from(e);
          return {'name': e?.toString() ?? '', 'url': ''};
        }).toList();
      } else if (v is Map) {
        for (final val in v.values) {
          if (val is Map) {
            toList.add(Map<String, dynamic>.from(val));
          } else {
            toList.add({'name': val?.toString() ?? '', 'url': ''});
          }
        }
      } else if (v is String && v.isNotEmpty) {
        toList = [{'name': v}];
      }

      return toList.map((doc) {
        final name = doc['name'] ?? doc['fileName'] ?? doc['title'] ?? '';
        final url = doc['url'] ?? doc['link'] ?? doc['downloadUrl'] ?? '';
        return {
          ...doc,
          'name': name,
          'url': url,
        };
      }).toList();
    }
    return [];
  }

  String _maskIfHiddenValue(String? val, {required bool isEmail, required bool isPhone}) {
    if (val == null || val.trim().isEmpty) return '-';
    if (!candidate.hideContact) return val;

    if (isEmail) {
      final parts = val.split('@');
      if (parts.length != 2) return val;
      final local = parts[0];
      final first = local.isNotEmpty ? local[0] : '';
      return '$first***@${parts[1]}';
    }

    if (isPhone) {
      final s = val.replaceAll(' ', '');
      if (s.isEmpty) return '-';
      if (s.length <= 5) {
        if (s.length <= 2) return s;
        final first = s.substring(0, 1);
        final last = s.substring(s.length - 1);
        return '$first***$last';
      }
      final first = s.substring(0, 3);
      final last = s.substring(s.length - 2);
      final midLen = s.length - 5;
      final mid = 'x' * (midLen > 0 ? midLen : 1);
      return '$first$mid$last';
    }

    return '****';
  }

  @override
  Widget build(BuildContext context) {
    final p = profile ?? <String, dynamic>{};
    final personal = _personal(p);
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 900;

    // Extract data
    final fullName = candidate.name.isNotEmpty ? candidate.name : (personal['name'] ?? personal['fullName'] ?? '-').toString();
    final rawEmail = (personal['email'] ?? personal['secondary_email'] ?? candidate.email ?? '').toString();
    final rawPhone = (personal['contactNumber'] ?? personal['phone'] ?? candidate.phone ?? '').toString();
    final nationality = (personal['nationality'] ?? candidate.nationality ?? 'Not Specified').toString();

    final emailDisplay = _maskIfHiddenValue(rawEmail, isEmail: true, isPhone: false);
    final phoneDisplay = _maskIfHiddenValue(rawPhone, isEmail: false, isPhone: true);

    // Lists
    final educationList = _readList(p, ['educationalProfile', 'education', 'educations', 'qualifications']);
    final experienceList = _readList(p, ['professionalExperience', 'experiences', 'experience', 'work_experience']);
    final documentsList = _readDocuments(p);

    // Summary
    final summary = (p['professionalProfile'] is Map && (p['professionalProfile']['summary'] ?? '').toString().isNotEmpty)
        ? p['professionalProfile']['summary'].toString()
        : (p['professionalSummary'] ?? personal['summary'] ?? 'No summary provided by the candidate.').toString();

    // CV URL
    final cvLinkLegacy = (p['Cv/Resume'] ?? p['cv'] ?? p['cv_url'] ?? p['resume'] ?? p['cvUrl'])?.toString();
    final firstDocUrl = documentsList.isNotEmpty ? (documentsList.first['url']?.toString() ?? '') : '';
    final cvUrlToShow = firstDocUrl.isNotEmpty ? firstDocUrl : (cvLinkLegacy ?? '');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? size.width * 0.1 : 16,
        vertical: 24,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 900),
        decoration: BoxDecoration(
          color: _bgSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildModernHeader(context, fullName),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isWide) _buildProfileSidebar(emailDisplay, phoneDisplay, nationality),
                    Expanded(
                      child: Container(
                        color: isWide ? Colors.white : _bgSubtle,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isWide) ...[
                                _buildProfileSidebar(emailDisplay, phoneDisplay, nationality),
                                const Divider(height: 48),
                              ],
                              _buildSectionHeader("Professional Summary", Icons.notes_rounded),
                              const SizedBox(height: 16),
                              _buildSummaryText(summary),
                              const SizedBox(height: 40),
                              _buildSectionHeader("Experience History", Icons.work_history_outlined),
                              const SizedBox(height: 20),
                              _buildExperienceTimeline(experienceList),
                              const SizedBox(height: 40),
                              _buildSectionHeader("Academic Background", Icons.school_outlined),
                              const SizedBox(height: 20),
                              _buildEducationList(educationList),
                              const SizedBox(height: 40),
                              _buildSectionHeader("Skills & Expertise", Icons.emoji_objects_outlined),
                              const SizedBox(height: 16),
                              _buildSkillsSection(personal, p),
                              const SizedBox(height: 40),
                              _buildSectionHeader("Certifications & Training", Icons.verified_outlined),
                              const SizedBox(height: 16),
                              _buildCertificationsSection(p),
                              const SizedBox(height: 40),
                              _buildSectionHeader("Attachments", Icons.attachment_outlined),
                              const SizedBox(height: 16),
                              _buildAttachmentsSection(documentsList, cvUrlToShow),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Components ---

  Widget _buildModernHeader(BuildContext context, String fullName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: _bgSurface,
        border: Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _brandPrimary.withOpacity(0.1),
            backgroundImage: candidate.pictureUrl.isNotEmpty ? NetworkImage(candidate.pictureUrl) : null,
            child: candidate.pictureUrl.isEmpty
                ? Text(
              fullName.substring(0, 1).toUpperCase(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _brandPrimary, fontSize: 20),
            )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _textMain),
                ),
                Text(
                  "Candidate ID: ${candidate.uid.toUpperCase().substring(0, 8)}",
                  style: GoogleFonts.poppins(fontSize: 12, color: _textMuted, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          _buildStatusBadge("Shortlisted"),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: _textMuted),
            style: IconButton.styleFrom(backgroundColor: _bgSubtle),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSidebar(String emailDisplay, String phoneDisplay, String nationality) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: _bgSubtle,
        border: Border(right: BorderSide(color: _borderColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sidebarInfoBlock("Email Address", emailDisplay, Icons.email_outlined),
            const SizedBox(height: 24),
            _sidebarInfoBlock("Phone Number", phoneDisplay, Icons.phone_android_outlined),
            const SizedBox(height: 24),
            _sidebarInfoBlock("Location", nationality, Icons.location_on_outlined),
            const Spacer()

          ],
        ),
      ),
    );
  }

  Widget _buildExperienceTimeline(List<Map<String, dynamic>> experienceList) {
    if (experienceList.isEmpty) return _emptyState("No professional experience recorded.");

    return Column(
      children: experienceList.map((item) {
        final organization = (item['organization'] ?? item['company'] ?? item['employer'] ?? '').toString();
        final role = (item['role'] ?? item['title'] ?? item['position'] ?? '').toString();
        final duration = (item['duration'] ?? item['start'] ?? item['from'] ?? '').toString();
        final duties = (item['duties'] ?? item['description'] ?? item['roleDescription'] ?? item['text'] ?? '').toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, size: 12, color: _brandPrimary),
                  Container(width: 2, height: 60, color: _borderColor),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (role.isNotEmpty)
                      Text(role, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: _textMain)),
                    if (organization.isNotEmpty)
                      Text(organization, style: GoogleFonts.poppins(color: _brandPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(duration, style: GoogleFonts.poppins(color: _textMuted, fontSize: 12)),
                    ],
                    if (duties.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(duties, style: GoogleFonts.poppins(height: 1.5, fontSize: 14, color: _textMain.withOpacity(0.8))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEducationList(List<Map<String, dynamic>> educationList) {
    // --- CONSOLE LOGGING ---
    debugPrint('═══ EDUCATION LIST DEBUG ═══');
    debugPrint('Count: ${educationList.length}');
    for (var i = 0; i < educationList.length; i++) {
      debugPrint('Index [$i]: ${jsonEncode(educationList[i])}');
    }
    debugPrint('═══════════════════════════');

    if (educationList.isEmpty) return _emptyState("Academic data unavailable.");

    return Column(
      children: educationList.map((e) {
        // ✅ FIXED: Use correct field names from your data structure
        final institutionName = (
            e['institutionName'] ??      // ✅ Primary field
                e['institute'] ??
                e['company'] ??
                e['organization'] ??
                ''
        ).toString();

        final major = (
            e['majorSubjects'] ??        // ✅ Primary field for degree/major
                e['degree'] ??
                e['title'] ??
                e['name'] ??
                ''
        ).toString();

        final duration = (
            e['duration'] ??             // ✅ Duration field
                e['from'] ??
                e['start'] ??
                ''
        ).toString();

        final marksOrCgpa = (
            e['marksOrCgpa'] ??          // ✅ Marks/CGPA field
                e['marks'] ??
                e['cgpa'] ??
                e['grade'] ??
                ''
        ).toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
            color: institutionName.isEmpty && major.isEmpty
                ? Colors.red.withOpacity(0.05)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.school_outlined,
                color: institutionName.isEmpty ? Colors.orange : _textMuted,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Institution Name
                    Text(
                      institutionName.isNotEmpty
                          ? institutionName
                          : 'Unknown Institution',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: institutionName.isNotEmpty
                            ? _textMain
                            : Colors.orange,
                      ),
                    ),

                    // Major/Degree
                    if (major.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        major,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _brandPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    // Duration and Marks in a row
                    if (duration.isNotEmpty || marksOrCgpa.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (duration.isNotEmpty) ...[
                            Icon(Icons.calendar_today_outlined,
                                size: 12,
                                color: _textMuted),
                            const SizedBox(width: 4),
                            Text(
                              duration,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _textMuted,
                              ),
                            ),
                          ],
                          if (duration.isNotEmpty && marksOrCgpa.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('•',
                                  style: TextStyle(color: _textMuted)),
                            ),
                          if (marksOrCgpa.isNotEmpty) ...[
                            Icon(Icons.grade_outlined,
                                size: 12,
                                color: _textMuted),
                            const SizedBox(width: 4),
                            Text(
                              marksOrCgpa,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _textMuted,
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
      }).toList(),
    );
  }  Widget _buildAttachmentsSection(List<Map<String, dynamic>> documentsList, String cvUrlToShow) {
    if (documentsList.isEmpty && cvUrlToShow.isEmpty) {
      return _emptyState("No digital copies attached.");
    }

    return Column(
      children: [
        if (documentsList.isNotEmpty)
          ...documentsList.map((doc) {
            final name = doc['name']?.toString() ?? 'Document';
            final url = doc['url']?.toString() ?? '';

            return InkWell(
              onTap: url.isNotEmpty ? () => _openUrl(url) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _bgSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(child: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
                    if (url.isNotEmpty) const Icon(Icons.file_download_outlined, color: _textMuted),
                  ],
                ),
              ),
            );
          }),
        if (documentsList.isEmpty && cvUrlToShow.isNotEmpty)
          InkWell(
            onTap: () => _openUrl(cvUrlToShow),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bgSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(child: Text("Curriculum_Vitae_${candidate.name}.pdf", style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
                  const Icon(Icons.file_download_outlined, color: _textMuted),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillsSection(Map<String, dynamic> personal, Map<String, dynamic> p) {
    final skillsList = (personal['skills'] ?? p['skills']);

    if (skillsList == null || (skillsList is List && skillsList.isEmpty)) {
      return _emptyState("No skills listed.");
    }

    if (skillsList is! List) {
      return _emptyState("No skills listed.");
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skillsList.map<Widget>((skill) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _brandPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _brandPrimary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 14, color: _brandPrimary),
              const SizedBox(width: 6),
              Text(
                skill.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _brandPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCertificationsSection(Map<String, dynamic> p) {
    final certsRaw = p['certifications'] ?? p['certiicaitons'] ?? p['certs'] ?? p['training'];

    if (certsRaw == null) {
      return _emptyState("No certifications available.");
    }

    List<dynamic> certsList = [];
    if (certsRaw is List) {
      certsList = certsRaw;
    } else if (certsRaw is Map) {
      certsList = certsRaw.values.toList();
    }

    if (certsList.isEmpty) {
      return _emptyState("No certifications available.");
    }

    return Column(
      children: certsList.map((cert) {
        String organization = '';
        String name = '';

        // Handle new structure: {organization, name}
        if (cert is Map) {
          organization = (cert['organization'] ?? '').toString();
          name = (cert['name'] ?? cert['certName'] ?? '').toString();
        }
        // Handle old structure: simple string
        else if (cert is String) {
          name = cert;
        }

        if (name.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified, size: 20, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textMain,
                      ),
                    ),
                    if (organization.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business_outlined, size: 12, color: _textMuted),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              organization,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _textMuted,
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
      }).toList(),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      if (!await canLaunchUrl(uri)) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // ignore
    }
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: _bgSurface,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      // child: Row(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   children: [
      //     OutlinedButton(
      //       onPressed: () => Navigator.pop(context),
      //       style: OutlinedButton.styleFrom(
      //         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      //         side: const BorderSide(color: _borderColor),
      //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      //       ),
      //       child: Text("Close", style: GoogleFonts.poppins(color: _textMain, fontWeight: FontWeight.w600)),
      //     ),
      //     // const SizedBox(width: 12),
      //     // ElevatedButton(
      //     //   onPressed: () {}, // Action to hire/next stage
      //     //   style: ElevatedButton.styleFrom(
      //     //     backgroundColor: _brandPrimary,
      //     //     foregroundColor: Colors.white,
      //     //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      //     //     elevation: 0,
      //     //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      //     //   ),
      //     //   child: Text("Move to Interview", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      //     // ),
      //   ],
      // ),
    );
  }

  // --- Helper Methods ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _textMuted),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: _textMuted, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _sidebarInfoBlock(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: _textMuted),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textMain)),
      ],
    );
  }

  Widget _buildStatusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0369A1)),
      ),
    );
  }

  Widget _buildSummaryText(String summary) {
    return Text(
      summary,
      style: GoogleFonts.poppins(fontSize: 15, height: 1.6, color: _textMain.withOpacity(0.8)),
    );
  }

  Widget _emptyState(String msg) => Text(msg, style: GoogleFonts.poppins(fontStyle: FontStyle.italic, color: _textMuted, fontSize: 13));
}