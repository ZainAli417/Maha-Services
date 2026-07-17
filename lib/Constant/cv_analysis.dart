// file: cv_analysis_screen.dart
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/blocks/leaf/paragraph.dart';
import 'package:markdown_widget/widget/markdown.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Screens/Job_Seeker/JS_Top_Bar.dart';
import '../Screens/Job_Seeker/job_seeker_provider.dart';
import 'brand_snackbar.dart';
import 'cv_analysis_provider.dart';
import 'js_header.dart';

// ─── Colours (navy + teal brand system) ─────────────────────────────────────
const Color kPrimaryBlue = Color(0xFF14507F); // brand navy (primary actions)
const Color kAccentBlue = Color(0xFF2EC4B6); // brand teal (accents)
const Color kTextPrimary = Color(0xFF0B2239); // ink
const Color kTextSecondary = Color(0xFF5E7A8E); // muted
const Color kBorderLight = Color(0xFFDCE7EF); // border
const Color kBackgroundGray = Color(0xFFF4F9FB); // bgSoft
const Color kSuccessGreen = Color(0xFF10B981);
const Color kWarningOrange = Color(0xFFF59E0B);
const Color kErrorRed = Color(0xFFEF4444);

// Brand gradient (teal → navy) for icon badges & the primary action.
const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
);

// ─── Breakpoints ────────────────────────────────────────────────────────────
class _BP {
  static const mobile = 600.0;
  static const desktop = 1100.0;

  static bool isMobile(double w) => w < mobile;
  static bool isDesktop(double w) => w >= desktop;

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
  final _jdController = TextEditingController();
  late AnimationController _animController;
  bool _isAiDialogVisible = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _resetTrigger = 0;

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
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _pickedFile = res.files.single);
    }
  }

  void _startAnalysis(BuildContext ctx) {
    if (_pickedFile == null) {
      _showSnackBar(ctx, 'Please select a CV/Resume first', isError: true);
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
    if (isError) {
      BrandSnack.error(ctx, msg);
    } else {
      BrandSnack.success(ctx, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = _BP.isMobile(w);

    return ScrollConfiguration(
      behavior: _SmoothScrollBehavior(),
      child: ChangeNotifierProvider(
        create: (_) => CVAnalyzerBackendProvider(),
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: kBackgroundGray, // matches JobSeekerHeader canvas (0xFFF4F9FB)
          drawer: isMobile
              ? const Drawer(child: JobSeekerSidebar(activeIndex: 2, isDrawer: true))
              : null,
          body: Row(
            children: [
              if (!isMobile) const JobSeekerSidebar(activeIndex: 2),
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
            if (!mounted) return;
            _showAIProcessingDialog(context, prov);
          });
        }

        return SafeArea(
          child: Column(
            children: [
              _CompactHeader(provider: prov, scaffoldKey: _scaffoldKey),
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
                              _resetTrigger++;
                            });
                            prov.reset();
                          },
                          resetKey: ValueKey(_resetTrigger),
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

  void _showAIProcessingDialog(
    BuildContext context,
    CVAnalyzerBackendProvider prov,
  ) {
    if (!prov.isLoading || _isAiDialogVisible) return;
    _isAiDialogVisible = true;

    void listener() {
      if (!prov.isLoading &&
          _isAiDialogVisible &&
          Navigator.of(context).canPop()) {
        try {
          Navigator.of(context).pop();
        } catch (_) {}
      }
    }

    prov.addListener(listener);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => _AIProcessingDialog(provider: prov),
    ).then((_) {
      try {
        prov.removeListener(listener);
      } catch (_) {}
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
    return JobSeekerHeader(
      icon: Icons.document_scanner_rounded,
      title: 'CV Analyzer',
      subtitle: 'ATS Analysis & Scoring',
      onMenu: () => scaffoldKey.currentState?.openDrawer(),
      trailing: provider.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : null,
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
  final Key? resetKey;

  const _ContentLayout({
    required this.pickedFile,
    required this.roleController,
    required this.jdController,
    required this.onPickFile,
    required this.onAnalyze,
    required this.onReset,
    required this.provider,
    this.resetKey,
  });

  @override
  Widget build(BuildContext context) {
    final hasResults =
        provider.score != null ||
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
                  resetKey: resetKey,
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
              resetKey: resetKey,
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
  final Key? resetKey;

  const _InputPanel({
    required this.pickedFile,
    required this.roleController,
    required this.jdController,
    required this.onPickFile,
    required this.onAnalyze,
    required this.onReset,
    required this.isLoading,
    this.resetKey,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = _BP.isMobile(w);
    final pad = isMobile ? 14.0 : 20.0;

    return Container(
      padding: EdgeInsets.all(pad),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionLabel(text: 'Upload CV', icon: Icons.upload_file),
          SizedBox(height: isMobile ? 8 : 12),
          _FileUploadZone(pickedFile: pickedFile, onPickFile: onPickFile),

          SizedBox(height: isMobile ? 16 : 22),
          const _SectionLabel(
            text: 'Select Job from Hub (Optional)',
            icon: Icons.hub_outlined,
          ),
          SizedBox(height: isMobile ? 8 : 10),
          _JobSelector(
            key: resetKey,
            onJobSelected: (job) {
              roleController.text = job['title'] ?? '';
              jdController.text = job['description'] ?? '';
            },
            isMobile: isMobile,
          ),

          SizedBox(height: isMobile ? 16 : 22),
          const _SectionLabel(text: 'Target Role', icon: Icons.work_outline),
          SizedBox(height: isMobile ? 8 : 10),
          _buildTextField(
            roleController,
            'e.g., Senior Flutter Developer',
            isMobile: isMobile,
          ),

          SizedBox(height: isMobile ? 14 : 20),
          const _SectionLabel(
            text: 'Job Description (Optional)',
            icon: Icons.description_outlined,
          ),
          SizedBox(height: isMobile ? 8 : 10),
          _buildTextField(
            jdController,
            'Paste job requirements here...',
            maxLines: isMobile ? 4 : 6,
            isMobile: isMobile,
          ),

          SizedBox(height: isMobile ? 18 : 24),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isLoading ? null : onAnalyze,
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: isLoading ? null : kBrandGradient,
                        color: isLoading
                            ? kTextSecondary.withValues(alpha: 0.35)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color: kAccentBlue.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 14 : 18,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isLoading
                                  ? Icons.hourglass_empty_rounded
                                  : Icons.auto_awesome_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isLoading ? 'Analyzing…' : 'Analyze CV',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: isMobile ? 13 : 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onReset,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  'Reset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kTextSecondary,
                  side: const BorderSide(color: kBorderLight),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 14 : 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool isMobile = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(
        fontSize: isMobile ? 14 : 15,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: kTextSecondary.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        filled: true,
        fillColor: kBackgroundGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorderLight, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorderLight, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryBlue, width: 1.6),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isMobile ? 12 : 13,
        ),
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
            style: GoogleFonts.plusJakartaSans(
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
          color: kAccentBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kAccentBlue.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kAccentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getFileIcon(pickedFile!),
                color: kAccentBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pickedFile!.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (pickedFile!.size > 0)
                    Text(
                      _formatSize(pickedFile!.size),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: kTextSecondary,
                      ),
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
            color: kAccentBlue.withValues(alpha: 0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 34, color: kAccentBlue),
            const SizedBox(height: 8),
            Text(
              'Tap to browse CVs/Resumes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kAccentBlue,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'PDF files only',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(PlatformFile file) {
    switch (file.extension?.toLowerCase() ?? '') {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  JOB SELECTOR
// ════════════════════════════════════════════════════════════════════════════
class _JobSelector extends StatefulWidget {
  final Function(Map<String, dynamic>) onJobSelected;
  final bool isMobile;

  const _JobSelector({
    super.key,
    required this.onJobSelected,
    this.isMobile = false,
  });

  @override
  State<_JobSelector> createState() => _JobSelectorState();
}

class _JobSelectorState extends State<_JobSelector> {
  String? _selectedJobId;

  @override
  Widget build(BuildContext context) {
    return Consumer<JobSeekerProvider>(
      builder: (context, provider, _) {
        final jobs = provider.activeJobs;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kBackgroundGray,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedJobId,
              hint: Text(
                'Browse public jobs to auto-fill...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: widget.isMobile ? 12 : 14,
                  color: kTextSecondary.withValues(alpha: 0.6),
                ),
              ),
              items: jobs.map((job) {
                return DropdownMenuItem<String>(
                  value: job['id'],
                  child: Text(
                    '${job['title']} @ ${job['company']}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: widget.isMobile ? 13 : 14,
                      color: kTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedJobId = val);
                  final selectedJob = jobs.firstWhere((j) => j['id'] == val);
                  widget.onJobSelected(selectedJob);
                }
              },
              icon: const Icon(Icons.arrow_drop_down, color: kTextSecondary),
            ),
          ),
        );
      },
    );
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
    final w = MediaQuery.sizeOf(context).width;
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
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
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
                style: GoogleFonts.plusJakartaSans(
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
          const Divider(color: kBorderLight, height: 1),
          const SizedBox(height: 16),

          if (provider.advisory != null) ...[
            _InsightsSection(advisory: provider.advisory!, isMobile: isMobile),
            if (provider.highlights.isNotEmpty)
              SizedBox(height: isMobile ? 18 : 24),
          ],

          if (provider.highlights.isNotEmpty)
            _HighlightsSection(
              highlights: provider.highlights,
              isMobile: isMobile,
            ),
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
    final color = score >= 80
        ? kSuccessGreen
        : score >= 60
        ? kWarningOrange
        : kErrorRed;
    final label = score >= 80
        ? 'Excellent'
        : score >= 60
        ? 'Good'
        : 'Needs Work';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${score.toStringAsFixed(0)}%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
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
            const Icon(Icons.lightbulb_outline, size: 16, color: kAccentBlue),
            const SizedBox(width: 7),
            Text(
              'AI Insights',
              style: GoogleFonts.plusJakartaSans(
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
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w600,
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
      RegExp(
        r'\b(Strengths?|Weaknesses?|Recommendations?):',
        caseSensitive: false,
      ),
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

  const _HighlightsSection({required this.highlights, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stars_outlined, size: 16, color: kWarningOrange),
            const SizedBox(width: 7),
            Text(
              'Key Highlights',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: kBackgroundGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${highlights.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kTextSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...highlights.map(
          (h) => _HighlightRow(highlight: h, isMobile: isMobile),
        ),
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
    final type = highlight['type']?.toString().toLowerCase() ?? 'info';
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
              color: config['bgColor'],
              shape: BoxShape.circle,
            ),
            child: Icon(
              config['icon'],
              color: config['iconColor'],
              size: isMobile ? 12 : 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight['text'] ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                    height: 1.4,
                  ),
                ),
                if (highlight['detail'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    highlight['detail'],
                    style: GoogleFonts.plusJakartaSans(
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
          'bgColor': kSuccessGreen.withValues(alpha: 0.1),
        };
      case 'weakness':
        return {
          'icon': Icons.warning_amber_rounded,
          'iconColor': kWarningOrange,
          'bgColor': kWarningOrange.withValues(alpha: 0.1),
        };
      default:
        return {
          'icon': Icons.info,
          'iconColor': kAccentBlue,
          'bgColor': kAccentBlue.withValues(alpha: 0.1),
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
    final isMobile = _BP.isMobile(MediaQuery.sizeOf(context).width);
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
            Icon(
              Icons.analytics_outlined,
              size: isMobile ? 38 : 48,
              color: kTextSecondary.withValues(alpha: 0.4),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'No analysis yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Upload a CV and tap Analyze',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 12 : 13,
                color: kTextSecondary.withValues(alpha: 0.7),
              ),
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
    final isMobile = _BP.isMobile(MediaQuery.sizeOf(context).width);
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: kErrorRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kErrorRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: kErrorRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Failed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kErrorRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: kTextSecondary,
                  ),
                ),
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
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = _BP.isMobile(w);

    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final progress = provider.progress.clamp(0.0, 1.0);
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
                  horizontal: isMobile ? 20 : 40,
                ),
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
                          color: kPrimaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_outlined,
                          size: 32,
                          color: kPrimaryBlue,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        stageText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
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
                          valueColor: const AlwaysStoppedAnimation(kPrimaryBlue),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kTextSecondary,
                        ),
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
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}
