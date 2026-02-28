// file: cv_analysis_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/blocks/leaf/paragraph.dart';
import 'package:markdown_widget/widget/markdown.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Screens/Job_Seeker/job_hub.dart';
import '../Screens/Job_Seeker/JS_Top_Bar.dart';
import 'cv_analysis_provider.dart';

// ─── Colours ────────────────────────────────────────────────────────────────
const Color kPrimaryBlue    = Color(0xFF1E40AF);
const Color kAccentBlue     = Color(0xFF3B82F6);
const Color kTextPrimary    = Color(0xFF0F172A);
const Color kTextSecondary  = Color(0xFF475569);
const Color kBorderLight    = Color(0xFFE2E8F0);
const Color kBackgroundGray = Color(0xFFF8FAFC);
const Color kSuccessGreen   = Color(0xFF059669);
const Color kWarningOrange  = Color(0xFFEA580C);
const Color kErrorRed       = Color(0xFFDC2626);

// ─── Breakpoints ────────────────────────────────────────────────────────────
class _BP {
  static const mobile  = 600.0;
  static const desktop = 1100.0;

  static bool isMobile(double w)  => w < mobile;
  static bool isDesktop(double w) => w >= desktop;

  static EdgeInsets hPad(double w) => EdgeInsets.symmetric(
    horizontal: w < mobile ? 12 : w < desktop ? 20 : 28,
    vertical:   w < mobile ? 10 : 14,
  );

  static double contentPad(double w) => w < mobile ? 14 : 20;
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ════════════════════════════════════════════════════════════════════════════
class CVAnalysisScreen extends StatefulWidget {
  const CVAnalysisScreen({super.key});

  @override
  State<CVAnalysisScreen> createState() => _CVAnalysisScreenState();
}

class _CVAnalysisScreenState extends State<CVAnalysisScreen>
    with TickerProviderStateMixin {
  PlatformFile? _pickedFile;
  final _roleController = TextEditingController();
  final _jdController   = TextEditingController();
  late AnimationController _animController;
  bool _isAiDialogVisible = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _roleController.dispose();
    _jdController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf'],
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _pickedFile = res.files.single);
    }
  }

  void _startAnalysis(BuildContext ctx) {
    if (_pickedFile == null) {
      _showSnackBar(ctx, 'Please select a CV file first', isError: true);
      return;
    }
    if (_roleController.text.trim().isEmpty) {
      _showSnackBar(ctx, 'Please enter the target role', isError: true);
      return;
    }
    final provider = Provider.of<CVAnalyzerBackendProvider>(ctx, listen: false);
    provider.reset();
    provider.analyzeCV(
      file: _pickedFile!,
      roleName: _roleController.text.trim(),
      jobDescription: _jdController.text.trim(),
    );
  }

  void _showSnackBar(BuildContext ctx, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? kErrorRed : kSuccessGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = _BP.isMobile(w);

    return ScrollConfiguration(
      behavior: _SmoothScrollBehavior(),
      child: ChangeNotifierProvider(
        create: (_) => CVAnalyzerBackendProvider(),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: isMobile
              ? Drawer(child: JobSeekerSidebar(activeIndex: 2, isDrawer: true))
              : null,
          body: Row(
            children: [
              if (!isMobile) JobSeekerSidebar(activeIndex: 2),
              Expanded(
                child: FadeTransition(
                  opacity: _animController,
                  child: _buildMainContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Consumer<CVAnalyzerBackendProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading && !_isAiDialogVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showAIProcessingDialog(context, prov);
          });
        }

        return SafeArea(
          child: Column(
            children: [
              _CompactHeader(
                provider: prov,
                scaffoldKey: _scaffoldKey,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final pad = _BP.contentPad(constraints.maxWidth);
                      return Padding(
                        padding: EdgeInsets.fromLTRB(pad, pad * 0.8, pad, pad),
                        child: _ContentLayout(
                          pickedFile: _pickedFile,
                          roleController: _roleController,
                          jdController: _jdController,
                          onPickFile: _pickFile,
                          onAnalyze: () => _startAnalysis(context),
                          onReset: () {
                            setState(() {
                              _pickedFile = null;
                              _roleController.clear();
                              _jdController.clear();
                            });
                            prov.reset();
                          },
                          provider: prov,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAIProcessingDialog(BuildContext context, CVAnalyzerBackendProvider prov) {
    if (!prov.isLoading || _isAiDialogVisible) return;
    _isAiDialogVisible = true;

    void listener() {
      if (!prov.isLoading && _isAiDialogVisible && Navigator.of(context).canPop()) {
        try { Navigator.of(context).pop(); } catch (_) {}
      }
    }

    prov.addListener(listener);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) => _AIProcessingDialog(provider: prov),
    ).then((_) {
      try { prov.removeListener(listener); } catch (_) {}
      _isAiDialogVisible = false;
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  COMPACT HEADER
// ════════════════════════════════════════════════════════════════════════════
class _CompactHeader extends StatelessWidget {
  final CVAnalyzerBackendProvider provider;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _CompactHeader({required this.provider, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = _BP.isMobile(w);
    final hPad = isMobile ? 10.0 : 20.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: isMobile ? 10 : 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kBorderLight, width: 1)),
      ),
      child: Row(
        children: [
          // Hamburger on mobile
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, size: 22),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              color: kTextPrimary,
            ),
            const SizedBox(width: 6),
          ],
          // Icon
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.analytics_outlined,
                size: isMobile ? 20 : 24, color: kPrimaryBlue),
          ),
          SizedBox(width: isMobile ? 10 : 14),
          // Title column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CV Analysis',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 15 : 18,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                    height: 1.2,
                  ),
                ),
                if (!isMobile)
                  Text(
                    'AI-powered matching and insights',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: kTextSecondary,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          if (provider.isLoading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(kPrimaryBlue),
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  CONTENT LAYOUT (input + results)
// ════════════════════════════════════════════════════════════════════════════
class _ContentLayout extends StatelessWidget {
  final PlatformFile? pickedFile;
  final TextEditingController roleController;
  final TextEditingController jdController;
  final VoidCallback onPickFile;
  final VoidCallback onAnalyze;
  final VoidCallback onReset;
  final CVAnalyzerBackendProvider provider;

  const _ContentLayout({
    required this.pickedFile,
    required this.roleController,
    required this.jdController,
    required this.onPickFile,
    required this.onAnalyze,
    required this.onReset,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final hasResults = provider.score != null ||
        provider.advisory != null ||
        provider.highlights.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isDesktop = _BP.isDesktop(w);

        // ── DESKTOP: side-by-side ────────────────────────────────────────
        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 360,
                child: _InputPanel(
                  pickedFile: pickedFile,
                  roleController: roleController,
                  jdController: jdController,
                  onPickFile: onPickFile,
                  onAnalyze: onAnalyze,
                  onReset: onReset,
                  isLoading: provider.isLoading,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: _ResultsPanel(provider: provider)),
            ],
          );
        }

        // ── TABLET / MOBILE: stacked ─────────────────────────────────────
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InputPanel(
              pickedFile: pickedFile,
              roleController: roleController,
              jdController: jdController,
              onPickFile: onPickFile,
              onAnalyze: onAnalyze,
              onReset: onReset,
              isLoading: provider.isLoading,
            ),
            if (hasResults || provider.error != null) ...[
              const SizedBox(height: 16),
              _ResultsPanel(provider: provider),
            ],
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  INPUT PANEL
// ════════════════════════════════════════════════════════════════════════════
class _InputPanel extends StatelessWidget {
  final PlatformFile? pickedFile;
  final TextEditingController roleController;
  final TextEditingController jdController;
  final VoidCallback onPickFile;
  final VoidCallback onAnalyze;
  final VoidCallback onReset;
  final bool isLoading;

  const _InputPanel({
    required this.pickedFile,
    required this.roleController,
    required this.jdController,
    required this.onPickFile,
    required this.onAnalyze,
    required this.onReset,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = _BP.isMobile(w);
    final pad = isMobile ? 14.0 : 20.0;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderLight),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionLabel(text: 'Upload CV', icon: Icons.upload_file),
          SizedBox(height: isMobile ? 8 : 12),
          _FileUploadZone(pickedFile: pickedFile, onPickFile: onPickFile),

          SizedBox(height: isMobile ? 16 : 22),
          _SectionLabel(text: 'Target Role', icon: Icons.work_outline),
          SizedBox(height: isMobile ? 8 : 10),
          _buildTextField(roleController, 'e.g., Senior Flutter Developer',
              isMobile: isMobile),

          SizedBox(height: isMobile ? 14 : 20),
          _SectionLabel(
              text: 'Job Description (Optional)',
              icon: Icons.description_outlined),
          SizedBox(height: isMobile ? 8 : 10),
          _buildTextField(jdController, 'Paste job requirements here...',
              maxLines: isMobile ? 4 : 6, isMobile: isMobile),

          SizedBox(height: isMobile ? 18 : 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onAnalyze,
                  icon: Icon(
                    isLoading ? Icons.hourglass_empty : Icons.auto_awesome,
                    size: 16,
                  ),
                  label: Text(
                    isLoading ? 'Analyzing…' : 'Analyze CV',
                    style: GoogleFonts.poppins(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 14 : 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kBorderLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: isLoading ? null : onReset,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  color: kTextSecondary,
                  tooltip: 'Reset',
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {int maxLines = 1, bool isMobile = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
          fontSize: isMobile ? 13 : 14, color: kTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            color: kTextSecondary.withOpacity(0.6),
            fontSize: isMobile ? 12 : 14),
        filled: true,
        fillColor: kBackgroundGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: kAccentBlue, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 12, vertical: isMobile ? 10 : 12),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SECTION LABEL
// ════════════════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SectionLabel({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: kTextSecondary),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  FILE UPLOAD ZONE
// ════════════════════════════════════════════════════════════════════════════
class _FileUploadZone extends StatelessWidget {
  final PlatformFile? pickedFile;
  final VoidCallback onPickFile;

  const _FileUploadZone({required this.pickedFile, required this.onPickFile});

  @override
  Widget build(BuildContext context) {
    // ── File already picked ──────────────────────────────────────────────
    if (pickedFile != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kAccentBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kAccentBlue.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kAccentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(_getFileIcon(pickedFile!),
                  color: kAccentBlue, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pickedFile!.name,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pickedFile!.size > 0)
                    Text(
                      _formatSize(pickedFile!.size),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: kTextSecondary),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: onPickFile,
              color: kTextSecondary,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              tooltip: 'Remove file',
            ),
          ],
        ),
      );
    }

    // ── Drop zone ────────────────────────────────────────────────────────
    return InkWell(
      onTap: onPickFile,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: kBackgroundGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: kAccentBlue.withOpacity(0.3),
              width: 1.5,
              style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 34, color: kAccentBlue),
            const SizedBox(height: 8),
            Text(
              'Tap to browse files',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kAccentBlue,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'PDF, DOC, DOCX, TXT supported',
              style: GoogleFonts.poppins(fontSize: 11, color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(PlatformFile file) {
    switch (file.extension?.toLowerCase() ?? '') {
      case 'pdf':  return Icons.picture_as_pdf;
      case 'doc':
      case 'docx': return Icons.description;
      default:     return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  RESULTS PANEL
// ════════════════════════════════════════════════════════════════════════════
class _ResultsPanel extends StatelessWidget {
  final CVAnalyzerBackendProvider provider;

  const _ResultsPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = _BP.isMobile(w);
    final pad = isMobile ? 14.0 : 20.0;

    if (provider.isLoading) return const SizedBox.shrink();
    if (provider.error != null) return _ErrorDisplay(error: provider.error!);
    if (provider.score == null &&
        provider.advisory == null &&
        provider.highlights.isEmpty) {
      return _EmptyState();
    }

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderLight),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Analysis Results',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              if (provider.score != null)
                _CompactScoreBadge(score: provider.score!),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: kBorderLight, height: 1),
          const SizedBox(height: 16),

          if (provider.advisory != null) ...[
            _InsightsSection(advisory: provider.advisory!,
                isMobile: isMobile),
            if (provider.highlights.isNotEmpty)
              SizedBox(height: isMobile ? 18 : 24),
          ],

          if (provider.highlights.isNotEmpty)
            _HighlightsSection(
                highlights: provider.highlights, isMobile: isMobile),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SCORE BADGE
// ════════════════════════════════════════════════════════════════════════════
class _CompactScoreBadge extends StatelessWidget {
  final double score;
  const _CompactScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? kSuccessGreen : score >= 60 ? kWarningOrange : kErrorRed;
    final label = score >= 80 ? 'Excellent' : score >= 60 ? 'Good' : 'Needs Work';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${score.toStringAsFixed(0)}%',
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(width: 5),
          Container(
              width: 3, height: 3,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  AI INSIGHTS SECTION
// ════════════════════════════════════════════════════════════════════════════
class _InsightsSection extends StatelessWidget {
  final String advisory;
  final bool isMobile;
  const _InsightsSection({required this.advisory, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 16, color: kAccentBlue),
            const SizedBox(width: 7),
            Text(
              'AI Insights',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        MarkdownWidget(
          data: _formatAdvisory(advisory),
          shrinkWrap: true,
          config: MarkdownConfig(
            configs: [
              PConfig(
                textStyle: GoogleFonts.poppins(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w400,
                  color: kTextSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatAdvisory(String text) {
    text = text.trim();
    text = text.replaceAllMapped(
      RegExp(r'\b(Strengths?|Weaknesses?|Recommendations?):', caseSensitive: false),
          (match) => '\n\n**${match.group(0)}**\n',
    );
    return text;
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  HIGHLIGHTS SECTION
// ════════════════════════════════════════════════════════════════════════════
class _HighlightsSection extends StatelessWidget {
  final List<Map<String, dynamic>> highlights;
  final bool isMobile;

  const _HighlightsSection(
      {required this.highlights, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.stars_outlined,
                size: 16, color: kWarningOrange),
            const SizedBox(width: 7),
            Text(
              'Key Highlights',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: kBackgroundGray,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                '${highlights.length}',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kTextSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...highlights.map((h) =>
            _HighlightRow(highlight: h, isMobile: isMobile)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  HIGHLIGHT ROW
// ════════════════════════════════════════════════════════════════════════════
class _HighlightRow extends StatelessWidget {
  final Map<String, dynamic> highlight;
  final bool isMobile;

  const _HighlightRow({required this.highlight, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final type   = highlight['type']?.toString().toLowerCase() ?? 'info';
    final config = _getConfig(type);

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: EdgeInsets.all(isMobile ? 5 : 6),
            decoration: BoxDecoration(
                color: config['bgColor'], shape: BoxShape.circle),
            child: Icon(config['icon'],
                color: config['iconColor'], size: isMobile ? 12 : 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight['text'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: kTextPrimary,
                    height: 1.4,
                  ),
                ),
                if (highlight['detail'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    highlight['detail'],
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 11 : 12,
                      color: kTextSecondary,
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

  Map<String, dynamic> _getConfig(String type) {
    switch (type) {
      case 'strength':
        return {
          'icon': Icons.check_circle,
          'iconColor': kSuccessGreen,
          'bgColor': kSuccessGreen.withOpacity(0.1),
        };
      case 'weakness':
        return {
          'icon': Icons.warning_amber_rounded,
          'iconColor': kWarningOrange,
          'bgColor': kWarningOrange.withOpacity(0.1),
        };
      default:
        return {
          'icon': Icons.info,
          'iconColor': kAccentBlue,
          'bgColor': kAccentBlue.withOpacity(0.1),
        };
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = _BP.isMobile(MediaQuery.of(context).size.width);
    return Container(
      padding: EdgeInsets.all(isMobile ? 28 : 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderLight),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined,
                size: isMobile ? 38 : 48,
                color: kTextSecondary.withOpacity(0.4)),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'No analysis yet',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.w500,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Upload a CV and tap Analyze',
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 12 : 13,
                  color: kTextSecondary.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  ERROR DISPLAY
// ════════════════════════════════════════════════════════════════════════════
class _ErrorDisplay extends StatelessWidget {
  final String error;
  const _ErrorDisplay({required this.error});

  @override
  Widget build(BuildContext context) {
    final isMobile = _BP.isMobile(MediaQuery.of(context).size.width);
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: kErrorRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kErrorRed.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: kErrorRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Failed',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kErrorRed),
                ),
                const SizedBox(height: 4),
                Text(error,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: kTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  AI PROCESSING DIALOG
// ════════════════════════════════════════════════════════════════════════════
class _AIProcessingDialog extends StatelessWidget {
  final CVAnalyzerBackendProvider provider;
  const _AIProcessingDialog({required this.provider});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = _BP.isMobile(w);

    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final progress  = provider.progress.clamp(0.0, 1.0);
        final stageText = _getStageText(progress);

        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                insetPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding: EdgeInsets.all(isMobile ? 22 : 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorderLight),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kPrimaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.auto_awesome_outlined,
                            size: 32, color: kPrimaryBlue),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        stageText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: kBackgroundGray,
                          valueColor: AlwaysStoppedAnimation(kPrimaryBlue),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStageText(double progress) {
    if (progress < 0.15) return 'Initializing analysis…';
    if (progress < 0.35) return 'Reading document…';
    if (progress < 0.60) return 'Extracting information…';
    if (progress < 0.85) return 'Comparing requirements…';
    if (progress < 0.95) return 'Generating insights…';
    return 'Finalizing…';
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SCROLL BEHAVIOUR
// ════════════════════════════════════════════════════════════════════════════
class _SmoothScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}