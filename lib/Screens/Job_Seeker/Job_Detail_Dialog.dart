// Job_Detail_Dialog.dart — Premium Job Detail Modal
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/quill_editor.dart';

class JobDetailModal extends StatelessWidget {
  final String jobId;
  const JobDetailModal({super.key, required this.jobId});

  // ── Design tokens ──────────────────────────────────────────────────────
  static const _navy = Color(0xFF0F172A);
  static const _navyLight = Color(0xFF1E293B);
  static const _slate500 = Color(0xFF64748B);
  static const _slate400 = Color(0xFF94A3B8);
  static const _slate200 = Color(0xFFE2E8F0);
  static const _slate50 = Color(0xFFFAFAFA);
  static const _indigo = Color(0xFF14507F);
  static const _indigoSoft = Color(0xFFE8F1F8);
  static const _emerald = Color(0xFF059669);
  static const _emeraldBg = Color(0xFFECFDF5);
  static const _amber = Color(0xFFD97706);
  static const _amberBg = Color(0xFFFFFBEB);
  static const _red500 = Color(0xFFEF4444);
  static const _white = Colors.white;

  // ── Date helper ────────────────────────────────────────────────────────
  String _fmtDate(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${_monthName(d.month)} ${d.day}, ${d.year}';
    }
    if (ts is String) {
      try {
        final d = DateTime.parse(ts);
        return '${_monthName(d.month)} ${d.day}, ${d.year}';
      } catch (_) {
        return ts;
      }
    }
    if (ts is DateTime) return '${_monthName(ts.month)} ${ts.day}, ${ts.year}';
    return ts.toString();
  }

  String _monthName(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    DateTime date;
    if (ts is Timestamp) {
      date = ts.toDate();
    } else if (ts is DateTime) {
      date = ts;
    } else {
      return '';
    }
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  Stream<Map<String, dynamic>?> _jobStream() {
    return FirebaseFirestore.instance
        .collection('Posted_jobs_public')
        .doc(jobId)
        .snapshots(includeMetadataChanges: true)
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data()!;
          final status = (data['status'] ?? 'active')
              .toString()
              .toLowerCase()
              .trim();
          if (status != 'active') return null;
          return {...data, 'id': doc.id};
        });
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isMobile = screenW < 700;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _jobStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoading(isMobile);
        }
        if (snap.hasError || snap.data == null) {
          return _buildError(context, isMobile);
        }
        return _buildContent(context, snap.data!, isMobile);
      },
    );
  }

  // ── Loading state ──────────────────────────────────────────────────────
  Widget _buildLoading(bool isMobile) {
    final body = Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(_indigo),
              backgroundColor: _slate200,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading job details…',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _slate500,
            ),
          ),
        ],
      ),
    );

    if (isMobile) return body;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: body,
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, bool isMobile) {
    final body = Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.work_off_outlined,
              size: 32,
              color: _red500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Position Unavailable',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This job may have been filled or removed by the recruiter.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: _slate500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: _slate200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Go Back',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: _navy,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isMobile) return body;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: body,
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────
  Widget _buildContent(
    BuildContext ctx,
    Map<String, dynamic> job,
    bool isMobile,
  ) {
    final title = job['title'] as String? ?? 'Untitled Position';
    final company = job['company'] as String? ?? 'Unknown Company';
    final logoUrl = job['logoUrl'] as String? ?? '';
    final description =
        job['description'] as String? ?? 'No description provided.';
    final responsibilities =
        job['responsibilities'] as String? ?? job['responsibilitiesHtml'] ?? '';
    final qualifications = job['qualifications'] as String? ?? '';
    final skills =
        (job['skills'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final workModes =
        (job['workModes'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final benefits =
        (job['benefits'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final department = job['department'] as String? ?? '';
    final experience = job['experience'] as String? ?? '';
    final deadline = _fmtDate(job['deadline'] ?? job['applicationDeadline']);
    final salary = job['salary'] ?? job['pay'] ?? 'Not disclosed';
    final nature = job['nature'] ?? job['type'] ?? 'Full-time';
    final location = job['location']?.toString() ?? 'Remote';
    final tsRaw = job['timestamp'];
    final viewCount = job['viewCount'] ?? 0;
    final appCount = job['applicationCount'] ?? 0;

    final body = Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : BorderRadius.circular(16),
        boxShadow: isMobile
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // ── Drag handle (mobile) ──
          if (isMobile) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Premium Header ──
          Container(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 20 : 28,
              isMobile ? 16 : 24,
              isMobile ? 12 : 20,
              isMobile ? 16 : 24,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFAFAFA), Color(0xFFF1F5F9)],
              ),
              borderRadius: isMobile
                  ? BorderRadius.zero
                  : const BorderRadius.vertical(top: Radius.circular(16)),
              border: const Border(
                bottom: BorderSide(color: _slate200, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company logo
                    Container(
                      width: isMobile ? 52 : 60,
                      height: isMobile ? 52 : 60,
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _slate200, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: logoUrl.isNotEmpty
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _logoPlaceholder(),
                              )
                            : _logoPlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title / Company
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 18 : 22,
                              fontWeight: FontWeight.w700,
                              color: _navy,
                              height: 1.25,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.business_rounded,
                                size: 14,
                                color: _slate400,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  company,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _slate500,
                                  ),
                                ),
                              ),
                              if (tsRaw != null) ...[
                                const SizedBox(width: 10),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: _slate400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _timeAgo(tsRaw),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _slate400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Close
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _slate200),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: _slate500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Quick-info pills ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _quickPill(
                        Icons.payments_outlined,
                        salary.toString(),
                        _indigo,
                        _indigoSoft,
                      ),
                      const SizedBox(width: 8),
                      _quickPill(
                        Icons.schedule_rounded,
                        nature.toString(),
                        _amber,
                        _amberBg,
                      ),
                      const SizedBox(width: 8),
                      _quickPill(
                        Icons.location_on_outlined,
                        location,
                        _emerald,
                        _emeraldBg,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Stats row ──
                Row(
                  children: [
                    _statBadge(
                      Icons.visibility_outlined,
                      '$viewCount views',
                      _slate500,
                    ),
                    const Spacer(),
                    if (department.isNotEmpty) _tagChip(department, _navyLight),
                  ],
                ),
              ],
            ),
          ),

          // ── Scrollable body ──
          Expanded(
            child: Container(
              color: _slate50,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 28,
                  vertical: isMobile ? 20 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline badges
                    if (deadline.isNotEmpty || experience.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            if (experience.isNotEmpty)
                              _timelineBadge(
                                Icons.trending_up_rounded,
                                'Experience',
                                experience,
                              ),
                            if (deadline.isNotEmpty)
                              _timelineBadge(
                                Icons.event_rounded,
                                'Deadline',
                                deadline,
                              ),
                            if (tsRaw != null)
                              _timelineBadge(
                                Icons.calendar_today_rounded,
                                'Posted',
                                _fmtDate(tsRaw),
                              ),
                          ],
                        ),
                      ),

                    // About
                    if (description.isNotEmpty) ...[
                      _sectionHeader(Icons.article_outlined, 'About the Role'),
                      const SizedBox(height: 10),
                      AppRichTextViewer(
                        deltaOrPlainText: description,
                        isMobile: isMobile,
                        fontSize: isMobile ? 14 : 15,
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Responsibilities
                    if (responsibilities.isNotEmpty) ...[
                      _sectionHeader(
                        Icons.checklist_rounded,
                        'Key Responsibilities',
                      ),
                      const SizedBox(height: 10),
                      AppRichTextViewer(
                        deltaOrPlainText: responsibilities,
                        isMobile: isMobile,
                        fontSize: isMobile ? 14 : 15,
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Qualifications
                    if (qualifications.isNotEmpty) ...[
                      _sectionHeader(Icons.school_outlined, 'Qualifications'),
                      const SizedBox(height: 10),
                      AppRichTextViewer(
                        deltaOrPlainText: qualifications,
                        isMobile: isMobile,
                        fontSize: isMobile ? 14 : 15,
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Skills
                    if (skills.isNotEmpty) ...[
                      _detailCard(
                        icon: Icons.code_rounded,
                        title: 'Required Skills',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills.map((s) => _skillChip(s)).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Work modes
                    if (workModes.isNotEmpty) ...[
                      _detailCard(
                        icon: Icons.devices_rounded,
                        title: 'Work Mode',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: workModes.map((w) => _modeChip(w)).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Benefits
                    if (benefits.isNotEmpty) ...[
                      _detailCard(
                        icon: Icons.card_giftcard_rounded,
                        title: 'Perks & Benefits',
                        child: Column(
                          children: benefits
                              .map(
                                (b) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: _emeraldBg,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          size: 12,
                                          color: _emerald,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          b,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            color: _navyLight,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // ── Return ──
    if (isMobile) return body;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: body,
      ),
    );
  }

  // ── Reusable components ────────────────────────────────────────────────

  Widget _logoPlaceholder() {
    return Container(
      color: _indigoSoft,
      child: const Center(
        child: Icon(Icons.business_rounded, color: _indigo, size: 26),
      ),
    );
  }

  Widget _quickPill(IconData icon, String text, Color accent, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _tagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _timelineBadge(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _slate400),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _slate400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _navyLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _indigoSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _indigo),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _navy,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _bodyText(String text, bool isMobile) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: isMobile ? 14 : 15,
        height: 1.7,
        color: const Color(0xFF475569),
        letterSpacing: -0.1,
      ),
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _slate400),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _slate400,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _skillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_indigoSoft, _indigoSoft.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _indigo.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _indigo,
        ),
      ),
    );
  }

  Widget _modeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _amberBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _amber.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.laptop_mac_rounded, size: 13, color: _amber),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _amber,
            ),
          ),
        ],
      ),
    );
  }
}
