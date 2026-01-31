import 'dart:typed_data';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../SignUp /signup_provider.dart';
import '../extractor_CV/cv_extractor.dart';

// ----------------------------------------------------------------------
// REFINED DESIGN SYSTEM
// ----------------------------------------------------------------------

class AppColors {
  // Neutral palette - professional & timeless
  static const primary = Color(0xFF0F172A);        // Deep slate
  static const primaryLight = Color(0xFF334155);   // Medium slate
  static const accent = Color(0xFF3B82F6);         // Clean blue
  static const accentHover = Color(0xFF2563EB);

  static const background = Color(0xFFFAFAFA);     // Soft white
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF8F9FA);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);

  static const border = Color(0xFFE2E8F0);
  static const borderLight = Color(0xFFF1F5F9);
  static const divider = Color(0xFFEFF2F5);

  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
}

class AppTypography {
  static TextStyle heading1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle heading2 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle heading3 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static TextStyle bodySecondary = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );

  static TextStyle button = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}

// ----------------------------------------------------------------------
// MAIN COMPONENT
// ----------------------------------------------------------------------

class CvUploadSection extends StatefulWidget {
  final CvExtractor extractor;
  final SignupProvider provider;
  final VoidCallback onSuccess;
  final VoidCallback onManualContinue;

  const CvUploadSection({
    super.key,
    required this.extractor,
    required this.provider,
    required this.onSuccess,
    required this.onManualContinue,
  });

  @override
  State<CvUploadSection> createState() => _CvUploadSectionState();
}

class _CvUploadSectionState extends State<CvUploadSection> {
  // State Variables
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isProcessing = false;
  String? _errorMsg;
  CvExtractionResult? _result;
  final Map<String, TextEditingController> _controllers = {};
  final Map<int, GlobalKey<FormState>> _formKeys = {};

  bool _showEditForm = false;
  int _currentStep = 0;
  bool _isHoveringUpload = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 4; i++) {
      _formKeys[i] = GlobalKey<FormState>();
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // LOGIC METHODS
  // ----------------------------------------------------------------------

  Future<void> _handleFileSelection() async {
    HapticFeedback.lightImpact();
    setState(() => _errorMsg = null);

    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
        withData: true,
      );

      if (res == null || res.files.isEmpty) return;

      final file = res.files.first;
      if (file.size > 15 * 1024 * 1024) {
        _showNotification('File size exceeds 15MB limit', isError: true);
        return;
      }

      setState(() {
        _fileBytes = file.bytes;
        _fileName = file.name;
        _isProcessing = true;
      });

      await _runExtraction();
    } catch (e) {
      _showNotification('Unable to process file', isError: true);
    }
  }

  Future<void> _runExtraction() async {
    if (_fileBytes == null) return;

    try {
      final result = await widget.extractor.extractFromFileBytes(
        _fileBytes!,
        filename: _fileName!,
      );

      _populateData(result);

      setState(() {
        _result = result;
        _isProcessing = false;
        _showEditForm = true;
      });

      _showNotification('Resume parsed successfully');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMsg = 'Unable to extract data. Please review and enter manually.';
      });
      _showNotification('Extraction failed', isError: true);
    }
  }

  void _populateData(CvExtractionResult r) {
    _controllers.clear();

    void bind(String k, dynamic v) {
      _controllers[k] = TextEditingController(text: v?.toString() ?? '');
    }

    final p = r.personalProfile;
    bind('name', p['name']);
    bind('email', p['email']);
    bind('phone', p['contactNumber']);
    bind('location', p['nationality']);
    bind('bio', p['summary'] ?? r.professionalSummary);
    bind('skills', (p['skills'] is List) ? (p['skills'] as List).join(', ') : p['skills']);

    for (var i = 0; i < r.educationalProfile.length; i++) {
      final edu = r.educationalProfile[i];
      bind('edu_inst_$i', edu['institutionName']);
      bind('edu_deg_$i', edu['majorSubjects']);
      bind('edu_date_$i', edu['duration']);
      bind('edu_grade_$i', edu['marksOrCgpa']);
    }

    for (var i = 0; i < r.experiences.length; i++) {
      final exp = r.experiences[i];
      bind('exp_org_$i', exp['organization']);
      bind('exp_role_$i', exp['role']);
      bind('exp_date_$i', exp['duration']);
      bind('exp_desc_$i', exp['duties']);
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message, style: AppTypography.button.copyWith(color: Colors.white)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // BUILD METHODS
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isProcessing
          ? _buildProcessingView()
          : _showEditForm
          ? _buildEditorView()
          : _buildUploadView(),
    );
  }

  // --- UPLOAD VIEW ---

  Widget _buildUploadView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              _buildBrandHeader(),
              const SizedBox(height: 48),
              Text(
                'Upload your resume',
                style: AppTypography.heading1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We will extract your information automatically',
              style: AppTypography.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildDropZone(),
              const SizedBox(height: 24),
              _buildManualOption(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.description, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          'Resume Parser',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDropZone() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringUpload = true),
      onExit: (_) => setState(() => _isHoveringUpload = false),
      child: GestureDetector(
        onTap: _handleFileSelection,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: _isHoveringUpload ? AppColors.surface : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHoveringUpload ? AppColors.accent : AppColors.border,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 28,
                  color: _isHoveringUpload ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Drop your resume here',
                style: AppTypography.heading3.copyWith(
                  color: _isHoveringUpload ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'or click to browse',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 24),
              Text(
                'Supports PDF, DOCX, TXT • Max 15MB',
                style: AppTypography.caption.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Prefer to enter manually?', style: AppTypography.bodySecondary),
        TextButton(
          onPressed: widget.onManualContinue,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: Text(
            'Click here',
            style: AppTypography.button.copyWith(color: AppColors.accent),
          ),
        ),
      ],
    );
  }

  // --- PROCESSING VIEW ---

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('Processing resume', style: AppTypography.heading2),
          const SizedBox(height: 8),
          Text(
            'Extracting your professional information',
            style: AppTypography.bodySecondary,
          ),
        ],
      ),
    );
  }

  // --- EDITOR VIEW ---

  Widget _buildEditorView() {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          child: Column(
            children: [
              _buildEditorHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Form(
                        key: _formKeys[_currentStep],
                        child: _buildStepContent(),
                      ),
                    ),
                  ),
                ),
              ),
              _buildEditorFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    final steps = [
      {'title': 'Personal', 'icon': Icons.person_outline},
      {'title': 'Education', 'icon': Icons.school_outlined},
      {'title': 'Experience', 'icon': Icons.work_outline},
      {'title': 'Review', 'icon': Icons.check_circle_outline},
    ];

    return Container(
      width: 260,
      color: AppColors.surface,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBrandHeader(),
          const SizedBox(height: 48),
          ...List.generate(steps.length, (index) {
            final isActive = _currentStep == index;
            final isCompleted = _currentStep > index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive || isCompleted
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive || isCompleted
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isCompleted
                            ? Icons.check
                            : steps[index]['icon'] as IconData,
                        size: 16,
                        color: isActive || isCompleted
                            ? Colors.white
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      steps[index]['title'] as String,
                      style: AppTypography.button.copyWith(
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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

  Widget _buildEditorHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Review & Edit', style: AppTypography.heading2),
          IconButton(
            onPressed: () => setState(() => _showEditForm = false),
            icon: const Icon(Icons.close, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                SecondaryButton(
                  label: 'Back',
                  onPressed: () => setState(() => _currentStep--),
                )
              else
                const SizedBox(),
              PrimaryButton(
                label: _currentStep == 3 ? 'Create Account' : 'Continue',
                onPressed: _currentStep == 3
                    ? _submitAccount
                    : () {
                  if (_formKeys[_currentStep]!.currentState!.validate()) {
                    setState(() => _currentStep++);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildEducationStep();
      case 2:
        return _buildWorkStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Personal Information', 'Basic details about you'),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: MinimalTextField(
                label: 'Full Name',
                controller: _controllers['name'],
                required: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MinimalTextField(
                label: 'Email Address',
                controller: _controllers['email'],
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MinimalTextField(
                label: 'Phone Number',
                controller: _controllers['phone'],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MinimalTextField(
                label: 'Location',
                controller: _controllers['location'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MinimalTextField(
          label: 'Professional Summary',
          controller: _controllers['bio'],
          maxLines: 4,
          hint: 'Brief overview of your professional background',
        ),
        const SizedBox(height: 16),
        MinimalTextField(
          label: 'Skills',
          controller: _controllers['skills'],
          hint: 'Separate skills with commas',
        ),
      ],
    );
  }

  Widget _buildEducationStep() {
    final count = _result?.educationalProfile.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Education', 'Your academic background'),
        const SizedBox(height: 32),
        if (count == 0)
          _buildEmptyState('No education data found')
        else
          ...List.generate(
            count,
                (i) => _buildEducationCard(i),
          ),
      ],
    );
  }

  Widget _buildEducationCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Education ${index + 1}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          MinimalTextField(
            label: 'Institution',
            controller: _controllers['edu_inst_$index'],
          ),
          const SizedBox(height: 16),
          MinimalTextField(
            label: 'Degree/Field of Study',
            controller: _controllers['edu_deg_$index'],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MinimalTextField(
                  label: 'Duration',
                  controller: _controllers['edu_date_$index'],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MinimalTextField(
                  label: 'Grade/CGPA',
                  controller: _controllers['edu_grade_$index'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkStep() {
    final count = _result?.experiences.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Work Experience', 'Your professional history'),
        const SizedBox(height: 32),
        if (count == 0)
          _buildEmptyState('No work experience found')
        else
          ...List.generate(
            count,
                (i) => _buildExperienceCard(i),
          ),
      ],
    );
  }

  Widget _buildExperienceCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Experience ${index + 1}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          MinimalTextField(
            label: 'Company',
            controller: _controllers['exp_org_$index'],
          ),
          const SizedBox(height: 16),
          MinimalTextField(
            label: 'Job Title',
            controller: _controllers['exp_role_$index'],
          ),
          const SizedBox(height: 16),
          MinimalTextField(
            label: 'Duration',
            controller: _controllers['exp_date_$index'],
          ),
          const SizedBox(height: 16),
          MinimalTextField(
            label: 'Description',
            controller: _controllers['exp_desc_$index'],
            maxLines: 3,
            hint: 'Key responsibilities and achievements',
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 40,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 24),
          Text('Ready to Create Account', style: AppTypography.heading1),
          const SizedBox(height: 12),
          Text(
            'Review your information in the previous steps.\nYou can go back to make any changes.',
            style: AppTypography.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.heading2),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTypography.bodySecondary),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message, style: AppTypography.bodySecondary),
      ),
    );
  }

  Future<void> _submitAccount() async {
    setState(() => _isProcessing = true);
    final success = await widget.provider.submitExtractedCvAndCreateAccount(_result!);
    setState(() => _isProcessing = false);
    if (success) widget.onSuccess();
  }
}

// ----------------------------------------------------------------------
// UI COMPONENTS
// ----------------------------------------------------------------------

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(label, style: AppTypography.button),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: AppTypography.button),
    );
  }
}

class MinimalTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final int maxLines;
  final bool required;

  const MinimalTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.maxLines = 1,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: AppColors.error)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: AppTypography.body,
          validator: required
              ? (value) => value?.isEmpty ?? true ? 'Required' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}