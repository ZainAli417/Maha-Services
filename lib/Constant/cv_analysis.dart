// file: cv_analysis_screen.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/blocks/leaf/paragraph.dart';
import 'package:markdown_widget/widget/markdown.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Screens/Job_Seeker/job_hub.dart';
import '../Screens/Job_Seeker/JS_Top_Bar.dart';
import '../main.dart';
import 'cv_analysis_provider.dart';

// Professional color scheme
const Color kPrimaryBlue = Color(0xFF1E40AF);
const Color kAccentBlue = Color(0xFF3B82F6);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF475569);
const Color kBorderLight = Color(0xFFE2E8F0);
const Color kBackgroundGray = Color(0xFFF8FAFC);
const Color kSuccessGreen = Color(0xFF059669);
const Color kWarningOrange = Color(0xFFEA580C);
const Color kErrorRed = Color(0xFFDC2626);

class CVAnalysisScreen extends StatefulWidget {
  final String geminiApiKey;

  CVAnalysisScreen({super.key, String? geminiApiKey})
      : geminiApiKey = geminiApiKey ?? Env.geminiApiKey;

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
    return ScrollConfiguration(
      behavior: SmoothScrollBehavior(),
      child: ChangeNotifierProvider(
        create: (_) => CVAnalyzerBackendProvider(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Row(
            children: [
              JobSeekerSidebar(activeIndex: 2),
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
              // Compact header bar
              _CompactHeader(provider: prov),

              // Main content area - maximized
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
        try {
          Navigator.of(context).pop();
        } catch (_) {}
      }
    }

    prov.addListener(listener);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) => _AIProcessingDialog(provider: prov),
    ).then((_) {
      try {
        prov.removeListener(listener);
      } catch (_) {}
      _isAiDialogVisible = false;
    });
  }
}

// ============= COMPONENTS =============

class _CompactHeader extends StatelessWidget {
  final CVAnalyzerBackendProvider provider;

  const _CompactHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.analytics_outlined, size: 24, color: kPrimaryBlue),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CV Analysis',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                  height: 1.2,
                ),
              ),
              Text(
                'AI-powered matching and insights',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: kTextSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (provider.isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(kPrimaryBlue),
                strokeWidth: 2.5,
              ),
            ),
        ],
      ),
    );
  }
}

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
        final isWide = constraints.maxWidth > 1100;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sidebar - Input controls (fixed width)
            SizedBox(
              width: isWide ? 380 : constraints.maxWidth,
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

            if (isWide) ...[
              const SizedBox(width: 20),
              // Right panel - Results (flexible, takes remaining space)
              Expanded(
                child: _ResultsPanel(provider: provider),
              ),
            ] else if (hasResults) ...[
              const SizedBox(height: 20),
              _ResultsPanel(provider: provider),
            ],
          ],
        );
      },
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionLabel(text: 'Upload CV', icon: Icons.upload_file),
          const SizedBox(height: 12),
          _FileUploadZone(pickedFile: pickedFile, onPickFile: onPickFile),

          const SizedBox(height: 24),
          _SectionLabel(text: 'Target Role', icon: Icons.work_outline),
          const SizedBox(height: 10),
          _buildTextField(roleController, 'e.g., Senior Flutter Developer'),

          const SizedBox(height: 20),
          _SectionLabel(text: 'Job Description (Optional)', icon: Icons.description_outlined),
          const SizedBox(height: 10),
          _buildTextField(jdController, 'Paste job requirements here...', maxLines: 6),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onAnalyze,
                  icon: Icon(isLoading ? Icons.hourglass_empty : Icons.auto_awesome, size: 18),
                  label: Text(
                    isLoading ? 'Analyzing' : 'Analyze',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 30),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kBorderLight),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: isLoading ? null : onReset,
                  icon: const Icon(Icons.refresh, size: 20),
                  color: kTextSecondary,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14, color: kTextPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: kTextSecondary.withOpacity(0.6), fontSize: 14),
        filled: true,
        fillColor: kBackgroundGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: kBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: kBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: kAccentBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SectionLabel({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kTextSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _FileUploadZone extends StatelessWidget {
  final PlatformFile? pickedFile;
  final VoidCallback onPickFile;

  const _FileUploadZone({required this.pickedFile, required this.onPickFile});

  @override
  Widget build(BuildContext context) {
    if (pickedFile != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBackgroundGray,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kBorderLight),
        ),
        child: Row(
          children: [
            Icon(_getFileIcon(pickedFile!), color: kAccentBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pickedFile!.name,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onPickFile,
              color: kTextSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onPickFile,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 80),
        decoration: BoxDecoration(
          color: kBackgroundGray,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kBorderLight, width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, size: 32, color: kAccentBlue),
            const SizedBox(height: 8),
            Text(
              'Click to browse',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kAccentBlue,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'PDF, DOC, DOCX supported',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(PlatformFile file) {
    final ext = file.extension?.toLowerCase() ?? '';
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _ResultsPanel extends StatelessWidget {
  final CVAnalyzerBackendProvider provider;

  const _ResultsPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) return const SizedBox.shrink();

    if (provider.error != null) {
      return _ErrorDisplay(error: provider.error!);
    }

    if (provider.score == null && provider.advisory == null && provider.highlights.isEmpty) {
      return _EmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score badge inline with title
          Row(
            children: [
              Text(
                'Analysis Results',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              if (provider.score != null) ...[
                const SizedBox(width: 12),
                _CompactScoreBadge(score: provider.score!),
              ],
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: kBorderLight, height: 1),
          const SizedBox(height: 20),

          // Insights section
          if (provider.advisory != null) ...[
            _InsightsSection(advisory: provider.advisory!),
            if (provider.highlights.isNotEmpty) const SizedBox(height: 24),
          ],

          // Highlights section
          if (provider.highlights.isNotEmpty)
            _HighlightsSection(highlights: provider.highlights),
        ],
      ),
    );
  }
}

class _CompactScoreBadge extends StatelessWidget {
  final double score;

  const _CompactScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    final label = _getScoreLabel(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return kSuccessGreen;
    if (score >= 60) return kWarningOrange;
    return kErrorRed;
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    return 'Needs Work';
  }
}

class _InsightsSection extends StatelessWidget {
  final String advisory;

  const _InsightsSection({required this.advisory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: kAccentBlue),
            const SizedBox(width: 8),
            Text(
              'AI Insights',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MarkdownWidget(
          data: _formatAdvisory(advisory),
          shrinkWrap: true,
          config: MarkdownConfig(
            configs: [
              PConfig(
                textStyle: GoogleFonts.poppins(
                  fontSize: 13,
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

class _HighlightsSection extends StatelessWidget {
  final List<Map<String, dynamic>> highlights;

  const _HighlightsSection({required this.highlights});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.stars_outlined, size: 18, color: kWarningOrange),
            const SizedBox(width: 8),
            Text(
              'Key Highlights',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kBackgroundGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${highlights.length}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kTextSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...highlights.map((h) => _HighlightRow(highlight: h)),
      ],
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final Map<String, dynamic> highlight;

  const _HighlightRow({required this.highlight});

  @override
  Widget build(BuildContext context) {
    final type = highlight['type']?.toString().toLowerCase() ?? 'info';
    final config = _getConfig(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: config['bgColor'],
              shape: BoxShape.circle,
            ),
            child: Icon(config['icon'], color: config['iconColor'], size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight['text'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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
                      fontSize: 12,
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderLight),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: kTextSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No analysis yet',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Upload a CV and start analyzing',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: kTextSecondary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  final String error;

  const _ErrorDisplay({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kErrorRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kErrorRed.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: kErrorRed, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Failed',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kErrorRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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

class _AIProcessingDialog extends StatelessWidget {
  final CVAnalyzerBackendProvider provider;

  const _AIProcessingDialog({required this.provider});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final progress = provider.progress.clamp(0.0, 1.0);
        final stageText = _getStageText(progress);

        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorderLight),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kPrimaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome_outlined,
                          size: 36,
                          color: kPrimaryBlue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        stageText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: kBackgroundGray,
                          valueColor: AlwaysStoppedAnimation(kPrimaryBlue),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
    if (progress < 0.15) return 'Initializing analysis...';
    if (progress < 0.35) return 'Reading document...';
    if (progress < 0.60) return 'Extracting information...';
    if (progress < 0.85) return 'Comparing requirements...';
    if (progress < 0.95) return 'Generating insights...';
    return 'Finalizing...';
  }
}

