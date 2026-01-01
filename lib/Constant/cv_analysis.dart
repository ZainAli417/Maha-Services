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

// Main Screen
class CVAnalysisScreen extends StatefulWidget {
  final String geminiApiKey;

  CVAnalysisScreen({super.key, String? geminiApiKey})
     : geminiApiKey = geminiApiKey ?? Env.geminiApiKey;
  //: geminiApiKey = geminiApiKey ?? '';

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
      duration: const Duration(milliseconds: 300),
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
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: SmoothScrollBehavior(),
      child: ChangeNotifierProvider(
        create: (_) => CVAnalyzerBackendProvider(
          useDirectGemini: true,
          geminiApiKey: widget.geminiApiKey,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
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

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFAFAFC), Color(0xFFF5F3FF)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CVHeader(provider: prov),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 1100;
                      return isWide
                          ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _InputSection(
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
                              isLoading: prov.isLoading,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: _ResultsSection(provider: prov),
                          ),
                        ],
                      )
                          : Column(
                        children: [
                          _InputSection(
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
                            isLoading: prov.isLoading,
                          ),
                          const SizedBox(height: 24),
                          _ResultsSection(provider: prov),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
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
      barrierColor: Colors.black.withOpacity(0.15),
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

class _CVHeader extends StatelessWidget {
  final CVAnalyzerBackendProvider provider;

  const _CVHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics_outlined, size: 32, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI CV Analyzer',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get instant insights and match scores',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          if (provider.isLoading)
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
                strokeWidth: 3,
              ),
            ),
        ],
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  final PlatformFile? pickedFile;
  final TextEditingController roleController;
  final TextEditingController jdController;
  final VoidCallback onPickFile;
  final VoidCallback onAnalyze;
  final VoidCallback onReset;
  final bool isLoading;

  const _InputSection({
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FileUploadCard(pickedFile: pickedFile, onPickFile: onPickFile),
          const SizedBox(height: 20),
          _buildLabel('Target Role', Icons.work_outline),
          const SizedBox(height: 8),
          _buildTextField(roleController, 'e.g., Senior Flutter Developer'),
          const SizedBox(height: 20),
          _buildLabel('Job Description (Optional)', Icons.description_outlined),
          const SizedBox(height: 8),
          _buildTextField(jdController, 'Paste job description...', maxLines: 4),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : onAnalyze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isLoading ? Icons.hourglass_empty : Icons.auto_awesome, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isLoading ? 'Analyzing...' : 'Analyze CV',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: isLoading ? null : onReset,
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w400),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
      style: GoogleFonts.poppins(fontWeight: FontWeight.w400),
    );
  }
}

class _FileUploadCard extends StatelessWidget {
  final PlatformFile? pickedFile;
  final VoidCallback onPickFile;

  const _FileUploadCard({required this.pickedFile, required this.onPickFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Upload CV',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4338CA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pickedFile != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Icon(_getFileIcon(pickedFile!), color: const Color(0xFF6366F1), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pickedFile!.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onPickFile,
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: onPickFile,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_upload_outlined, size: 24, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Text(
                      'Click to browse files (PDF, DOC, DOCX)',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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

class _ResultsSection extends StatelessWidget {
  final CVAnalyzerBackendProvider provider;

  const _ResultsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) return const SizedBox.shrink();

    if (provider.error != null) {
      return _ErrorCard(error: provider.error!);
    }

    if (provider.score == null && provider.advisory == null && provider.highlights.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined, size: 64, color: Color(0xFF64748B)),
              const SizedBox(height: 16),
              Text(
                'Upload a CV to get Analysis',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              if (provider.advisory != null) _AdvisoryCard(advisory: provider.advisory!),
              if (provider.advisory != null && provider.highlights.isNotEmpty)
                const SizedBox(height: 16),
              if (provider.highlights.isNotEmpty)
                _HighlightsCard(highlights: provider.highlights),
            ],
          ),
        ),
        if (provider.score != null) ...[
          const SizedBox(width: 16),
          SizedBox(
            width: 220,
            child: _ScoreCard(score: provider.score!),
          ),
        ],
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Failed',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF991B1B),
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

class _AdvisoryCard extends StatelessWidget {
  final String advisory;

  const _AdvisoryCard({required this.advisory});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Insights',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: MarkdownWidget(
                data: _formatAdvisory(advisory),
                shrinkWrap: true,
                config: MarkdownConfig(
                  configs: [
                    PConfig(
                      textStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4B5563),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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

class _HighlightsCard extends StatelessWidget {
  final List<Map<String, dynamic>> highlights;

  const _HighlightsCard({required this.highlights});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.stars, color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Key Highlights',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${highlights.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: highlights.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, idx) => _HighlightItem(highlight: highlights[idx]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightItem extends StatelessWidget {
  final Map<String, dynamic> highlight;

  const _HighlightItem({required this.highlight});

  @override
  Widget build(BuildContext context) {
    final type = highlight['type']?.toString().toLowerCase() ?? 'info';
    final config = _getConfig(type);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config['bgColor'],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: config['borderColor']),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config['icon'], color: config['iconColor'], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight['text'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (highlight['detail'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    highlight['detail'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
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
          'iconColor': const Color(0xFF10B981),
          'bgColor': const Color(0xFFF0FDF4),
          'borderColor': const Color(0xFFD1FAE5),
        };
      case 'weakness':
        return {
          'icon': Icons.warning_amber_rounded,
          'iconColor': const Color(0xFFF59E0B),
          'bgColor': const Color(0xFFFFFBEB),
          'borderColor': const Color(0xFFFEF3C7),
        };
      default:
        return {
          'icon': Icons.info,
          'iconColor': const Color(0xFF6366F1),
          'bgColor': const Color(0xFFF5F3FF),
          'borderColor': const Color(0xFFE0E7FF),
        };
    }
  }
}

class _ScoreCard extends StatelessWidget {
  final double score;

  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    final label = _getScoreLabel(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.analytics_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Match Score',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(140, 140),
                  painter: _CircularScorePainter(
                    progress: (score / 100).clamp(0.0, 1.0),
                    color: color,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toStringAsFixed(0),
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      'of 100',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded, color: color, size: 16),
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
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFFF59E0B);
    if (score >= 40) return const Color(0xFFEF4444);
    return const Color(0xFFDC2626);
  }

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good Match';
    if (score >= 40) return 'Fair Match';
    return 'Needs Work';
  }
}

class _CircularScorePainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularScorePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 10, bgPaint);

    final rect = Rect.fromCircle(center: center, radius: radius - 10);
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularScorePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
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
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E7FF)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_outlined,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        stageText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF3F4F6),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% Complete',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
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
    if (progress < 0.15) return 'Initializing AI analysis...';
    if (progress < 0.35) return 'Reading document...';
    if (progress < 0.60) return 'Extracting information...';
    if (progress < 0.85) return 'Comparing requirements...';
    if (progress < 0.95) return 'Generating insights...';
    return 'Finalizing report...';
  }
}