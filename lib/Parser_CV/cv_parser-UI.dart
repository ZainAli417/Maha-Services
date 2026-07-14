import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../SignUp/signup_provider.dart';
import '../Parser_CV/cv_parser.dart';

// ─── Breakpoints ─────────────────────────────────────────────────────────────
class _BP {
  static bool isMobile(double w) => w < 600;
  static bool isTablet(double w) => w >= 600 && w < 960;
  static bool isDesktop(double w) => w >= 960;

  static double hPad(double w) => isMobile(w)
      ? 16
      : isTablet(w)
      ? 24
      : 40;
  static double vPad(double w) => isMobile(w)
      ? 12
      : isTablet(w)
      ? 20
      : 28;
  static double cardPad(double w) => isMobile(w)
      ? 16
      : isTablet(w)
      ? 22
      : 28;
  static double maxW(double w) => isDesktop(w) ? 1000 : double.infinity;
}

// ─── Layout InheritedWidget ───────────────────────────────────────────────────
class _LD extends InheritedWidget {
  final double screenWidth;
  const _LD({required this.screenWidth, required super.child});

  static double w(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_LD>()!.screenWidth;
  static bool mob(BuildContext c) => _BP.isMobile(w(c));
  static bool tab(BuildContext c) => _BP.isTablet(w(c));

  @override
  bool updateShouldNotify(_LD old) => old.screenWidth != screenWidth;
}

// ─── Brand tokens ─────────────────────────────────────────────────────────────
class BrandColors {
  static const white = Color(0xFFFFFFFF);
  static const slate950 = Color(0xFF020617);
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate600 = Color(0xFF475569);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate50 = Color(0xFFF8FAFC);
  static const indigo = Color(0xFF14507F);
  static const indigoHover = Color(0xFF0A2E4F);
  static const emerald = Color(0xFF10B981);
  static const rose = Color(0xFFF43F5E);

  // Brand accents (navy + teal system)
  static const navy = Color(0xFF14507F);
  static const navyDeep = Color(0xFF0A2E4F);
  static const teal = Color(0xFF2EC4B6);
  static const tealBright = Color(0xFF43E0D2);
  static const tealDeep = Color(0xFF15A99C);
  static const tealTint = Color(0xFFE4F6F4);
  static const navyTint = Color(0xFFE8F1F8);
  static const border = Color(0xFFDCE7EF);
  static const bgSoft = Color(0xFFF4F9FB);
  static const ink = Color(0xFF0B2239);
  static const slateBrand = Color(0xFF3E5C76);
  static const muted = Color(0xFF5E7A8E);
  static const faint = Color(0xFF8AA5B5);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, navy],
  );
}

class BrandTypography {
  static TextStyle h1 = GoogleFonts.plusJakartaSans(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    color: BrandColors.slate950,
  );
  static TextStyle h2 = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: BrandColors.slate950,
  );
  static TextStyle body = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: BrandColors.slate800,
    height: 1.6,
  );
  static TextStyle label = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: BrandColors.slate600,
    letterSpacing: 0.5,
  );
  static TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: BrandColors.slate400,
    letterSpacing: 0.3,
  );
}

class AviationSkills {
  static const List<String> commonSkills = [
    'Tactical Operations',
    'Flight Planning',
    'Aircraft Systems',
    'Navigation & Avionics',
    'Air Defense',
    'Combat Operations',
    'Mission Planning',
    'Weapon Systems',
    'Emergency Procedures',
    'Crew Resource Management',
    'Meteorology',
    'Formation Flying',
    'Electronic Warfare',
    'Search & Rescue',
    'Leadership & Command',
  ];
}

// ═════════════════════════════════════════════════════════════════════════════
// ROOT WIDGET
// ═════════════════════════════════════════════════════════════════════════════
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

class _CvUploadSectionState extends State<CvUploadSection>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isProcessing = false;
  String? _errorMsg;
  CvExtractionResult? _result;

  final Map<String, TextEditingController> _controllers = {};
  final Map<int, GlobalKey<FormState>> _formKeys = {};
  final TextEditingController _skillInputController = TextEditingController();
  final List<String> _selectedSkills = [];

  bool _showEditForm = false;
  int _currentStep = 0;
  bool _isHoveringUpload = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
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
    _skillInputController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGIC
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _handleFileSelection() async {
    setState(() => _errorMsg = null);
    try {
      final res = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'txt'],
        withData: kIsWeb,
      );
      if (res == null || res.files.isEmpty) return;

      final file = res.files.first;
      if (file.size > 15 * 1024 * 1024) {
        _showNotification('File size exceeds 15 MB limit', isError: true);
        return;
      }

      Uint8List? bytes;
      if (kIsWeb) {
        bytes = file.bytes;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        _showNotification('Cannot read file content', isError: true);
        return;
      }

      setState(() {
        _fileBytes = bytes;
        _fileName = file.name;
        _isProcessing = true;
      });
      await _runExtraction();
    } catch (_) {
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
    } catch (_) {
      setState(() {
        _isProcessing = false;
        _errorMsg = 'Unable to extract data. Please review and enter manually.';
      });
      _showNotification('Extraction failed', isError: true);
    }
  }

  void _populateData(CvExtractionResult r) {
    _controllers.clear();
    _selectedSkills.clear();

    void bind(String k, dynamic v) =>
        _controllers[k] = TextEditingController(text: v?.toString() ?? '');

    final p = r.personalProfile;
    bind('name', p['name']);
    bind('email', p['email']);
    bind('phone', p['contactNumber']);
    bind('location', p['nationality']);
    bind('bio', p['summary'] ?? r.professionalSummary);

    if (p['skills'] is List) {
      _selectedSkills.addAll((p['skills'] as List).map((s) => s.toString()));
    } else if (p['skills'] is String && (p['skills'] as String).isNotEmpty) {
      _selectedSkills.addAll(
        (p['skills'] as String).split(',').map((s) => s.trim()),
      );
    }

    for (var i = 0; i < r.educationalProfile.length; i++) {
      final e = r.educationalProfile[i];
      bind('edu_inst_$i', e['institutionName']);
      bind('edu_deg_$i', e['majorSubjects']);
      bind('edu_date_$i', e['duration']);
      bind('edu_grade_$i', e['marksOrCgpa']);
    }

    for (var i = 0; i < r.professionalExperience.length; i++) {
      final x = r.professionalExperience[i];
      bind('exp_org_$i', x['organization']);
      bind('exp_role_$i', x['role']);
      bind('exp_date_$i', x['duration']);
      bind('exp_desc_$i', x['duties']);
      bind('exp_rank_$i', x['rank']);
      bind('exp_unit_$i', x['unit']);
      bind('exp_command_$i', x['command']);
      bind('exp_location_$i', x['location']);
      bind('exp_aircraft_$i', x['aircraftType']);
      bind('exp_hours_$i', x['flightHours']);
    }
  }

  void _showNotification(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? BrandColors.rose : BrandColors.emerald,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, bc) {
        final w = bc.maxWidth;
        return _LD(
          screenWidth: w,
          // ← SafeArea: fixes Android status-bar / nav-bar overlap
          child: SafeArea(
            top: true,
            bottom: true,
            child: Scaffold(
              backgroundColor: BrandColors.white,
              body: Column(
                children: [
                  _TopBar(
                    currentStep: _currentStep,
                    showTimeline: _showEditForm || _isProcessing,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeOutQuart,
                      child: _isProcessing
                          ? _buildProcessingView()
                          : _showEditForm
                          ? _buildEditorView(w)
                          : _buildUploadView(w),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── UPLOAD VIEW ──────────────────────────────────────────────────────────
  Widget _buildUploadView(double w) {
    final isMob = _BP.isMobile(w);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: _BP.hPad(w),
        vertical: _BP.vPad(w),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMob ? double.infinity : 680),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: isMob ? 8 : 20),
              // Gradient icon badge
              Container(
                padding: EdgeInsets.all(isMob ? 14 : 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2EC4B6), Color(0xFF14507F)],
                  ),
                  borderRadius: BorderRadius.circular(isMob ? 16 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2EC4B6).withValues(alpha: 0.4),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: isMob ? 26 : 34),
              ),
              SizedBox(height: isMob ? 16 : 22),
              // Eyebrow badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2EC4B6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: const Color(0xFF2EC4B6).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'ATS CV ANALYZER',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMob ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15A99C),
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              SizedBox(height: isMob ? 14 : 18),
              // Gradient title
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF14507F), Color(0xFF2EC4B6)],
                ).createShader(b),
                child: Text(
                  'Professional Data Extraction',
                  style: BrandTypography.h1
                      .copyWith(fontSize: isMob ? 22 : 30, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isMob ? 8 : 12),
              Text(
                'Upload your CV. Our AI will automatically categorize your aviation experience, flight hours, and technical certifications.',
                textAlign: TextAlign.center,
                style: BrandTypography.body.copyWith(
                  color: BrandColors.slate400,
                  fontSize: isMob ? 13 : 15,
                ),
              ),
              SizedBox(height: isMob ? 24 : 44),
              _buildDropZone(w),
              SizedBox(height: isMob ? 20 : 28),
              TextButton(
                onPressed: widget.onManualContinue,
                child: Text(
                  'Enter data manually instead →',
                  style: BrandTypography.body.copyWith(
                    color: BrandColors.indigo,
                    fontWeight: FontWeight.w600,
                    fontSize: isMob ? 13 : 15,
                  ),
                ),
              ),
              SizedBox(height: isMob ? 12 : 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropZone(double w) {
    final isMob = _BP.isMobile(w);
    final height = isMob ? 220.0 : 288.0;
    final hover = _isHoveringUpload;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringUpload = true),
      onExit: (_) => setState(() => _isHoveringUpload = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleFileSelection,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: double.infinity,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: isMob ? 16 : 28),
          decoration: BoxDecoration(
            color: hover ? BrandColors.tealTint : BrandColors.bgSoft,
            borderRadius: BorderRadius.circular(isMob ? 18 : 22),
            border: Border.all(
              color: hover ? BrandColors.teal : BrandColors.border,
              width: 2,
            ),
            boxShadow: hover
                ? [
                    BoxShadow(
                      color: BrandColors.teal.withValues(alpha: 0.28),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: BrandColors.ink.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gradient icon badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.all(isMob ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: BrandColors.brandGradient,
                  borderRadius: BorderRadius.circular(isMob ? 14 : 18),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.teal.withValues(
                        alpha: hover ? 0.45 : 0.25,
                      ),
                      blurRadius: hover ? 22 : 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.cloud_upload_rounded,
                  size: isMob ? 26 : 34,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isMob ? 14 : 18),
              Text(
                isMob ? 'Tap to upload your CV' : 'Drag & drop your CV here',
                textAlign: TextAlign.center,
                style: BrandTypography.h2.copyWith(
                  fontSize: isMob ? 16 : 19,
                  color: BrandColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMob ? 'or browse from your device' : 'or click to browse files',
                textAlign: TextAlign.center,
                style: BrandTypography.body.copyWith(
                  color: BrandColors.muted,
                  fontSize: isMob ? 12 : 14,
                ),
              ),
              SizedBox(height: isMob ? 14 : 18),
              // Gradient "Browse files" affordance
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMob ? 18 : 24,
                  vertical: isMob ? 9 : 12,
                ),
                decoration: BoxDecoration(
                  gradient: BrandColors.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.teal.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open_rounded,
                        size: isMob ? 15 : 17, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Browse files',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isMob ? 13 : 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMob ? 14 : 18),
              // Supported-format chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _FormatChip(label: 'PDF'),
                  _FormatChip(label: 'DOCX'),
                  _FormatChip(label: 'TXT'),
                  _FormatChip(label: 'Up to 15 MB'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PROCESSING VIEW ──────────────────────────────────────────────────────
  Widget _buildProcessingView() {
    final isMob = _LD.mob(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMob ? 24 : 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated brand ring — isolated repaint layer
            RepaintBoundary(
              child: SizedBox(
                width: 128,
                height: 128,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(seconds: 2),
                      builder: (_, double v, _) => Container(
                        width: 120 + v * 20,
                        height: 120 + v * 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: BrandColors.teal.withValues(
                              alpha: 0.25 * (1 - v),
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1500),
                      builder: (_, double v, _) => Container(
                        width: 100 + v * 15,
                        height: 100 + v * 15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: BrandColors.teal.withValues(
                              alpha: 0.35 * (1 - v),
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BrandColors.white,
                        border: Border.all(color: BrandColors.border, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.teal.withValues(alpha: 0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 92,
                            height: 92,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: BrandColors.teal,
                              backgroundColor: BrandColors.tealTint,
                            ),
                          ),
                          Icon(
                            Icons.description_rounded,
                            size: 34,
                            color: BrandColors.navy,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isMob ? 28 : 36),
            Text(
              'Analyzing Document',
              style: BrandTypography.h2.copyWith(
                fontSize: isMob ? 20 : 24,
                color: BrandColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Extracting aviation data',
                  style: BrandTypography.body.copyWith(
                    color: BrandColors.muted,
                    fontSize: isMob ? 13 : 14,
                  ),
                ),
                const SizedBox(width: 4),
                RepaintBoundary(child: _LoadingDots()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── EDITOR VIEW ──────────────────────────────────────────────────────────
  Widget _buildEditorView(double w) {
    final isMob = _BP.isMobile(w);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: _BP.hPad(w),
              vertical: _BP.vPad(w),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _BP.maxW(w)),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: Form(
                      key: _formKeys[_currentStep],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStepContent(w),
                          SizedBox(height: isMob ? 20 : 36),
                          _buildFooter(w),
                          SizedBox(height: isMob ? 20 : 36),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── STEP ROUTER ──────────────────────────────────────────────────────────
  Widget _buildStepContent(double w) {
    switch (_currentStep) {
      case 0:
        return _buildPersonalStep(w);
      case 1:
        return _buildEducationStep(w);
      case 2:
        return _buildExperienceStep(w);
      case 3:
        return _buildFinalReviewStep(w);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── STEP 0: PERSONAL ─────────────────────────────────────────────────────
  Widget _buildPersonalStep(double w) {
    final isMob = _BP.isMobile(w);
    final gap = isMob ? 14.0 : 20.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Personal Profile',
          'Personal record and contact details',
          w,
        ),
        SizedBox(height: isMob ? 20 : 32),
        isMob
            ? Column(
                children: [
                  _buildTextField('Full Name', _controllers['name'], true),
                  SizedBox(height: gap),
                  _buildTextField('Email Address', _controllers['email'], true),
                  SizedBox(height: gap),
                  _buildTextField('Phone Number', _controllers['phone']),
                  SizedBox(height: gap),
                  _buildTextField('Location', _controllers['location']),
                ],
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Full Name',
                          _controllers['name'],
                          true,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildTextField(
                          'Email Address',
                          _controllers['email'],
                          true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: gap),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Phone Number',
                          _controllers['phone'],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildTextField(
                          'Location',
                          _controllers['location'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        SizedBox(height: gap),
        _buildTextField(
          'Professional Summary',
          _controllers['bio'],
          false,
          isMob ? 3 : 4,
        ),
        SizedBox(height: isMob ? 24 : 36),
        _buildSkillSelector(w),
      ],
    );
  }

  Widget _buildSkillSelector(double w) {
    final isMob = _BP.isMobile(w);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                gradient: BrandColors.brandGradient,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'TECHNICAL COMPETENCIES',
              style: BrandTypography.label.copyWith(
                fontSize: 11,
                color: BrandColors.tealDeep,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: isMob ? 10 : 14),
        Container(
          padding: EdgeInsets.all(_BP.cardPad(w)),
          decoration: BoxDecoration(
            color: BrandColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BrandColors.border),
            boxShadow: [
              BoxShadow(
                color: BrandColors.ink.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Wrap(
            spacing: isMob ? 8 : 10,
            runSpacing: isMob ? 8 : 10,
            children: AviationSkills.commonSkills.map((s) {
              final selected = _selectedSkills.contains(s);
              return GestureDetector(
                onTap: () => setState(
                  () => selected
                      ? _selectedSkills.remove(s)
                      : _selectedSkills.add(s),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMob ? 10 : 14,
                    vertical: isMob ? 7 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? BrandColors.teal.withValues(alpha: 0.12)
                        : BrandColors.bgSoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? BrandColors.teal
                          : BrandColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s,
                        style: BrandTypography.caption.copyWith(
                          fontSize: isMob ? 11 : 12,
                          color: selected
                              ? BrandColors.tealDeep
                              : BrandColors.muted,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: BrandColors.tealDeep,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── STEP 1: EDUCATION ────────────────────────────────────────────────────
  Widget _buildEducationStep(double w) {
    final count = _result?.educationalProfile.length ?? 0;
    final isMob = _BP.isMobile(w);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Educational Background',
          'Academic qualifications and technical schooling',
          w,
        ),
        SizedBox(height: isMob ? 20 : 32),
        if (count == 0)
          _buildEmptyState('No academic data found.')
        else
          ...List.generate(
            count,
            (i) => _buildDataCard(
              title: 'QUALIFICATION ${i + 1}',
              w: w,
              children: [
                _buildTextField('Institution', _controllers['edu_inst_$i']),
                SizedBox(height: isMob ? 12 : 18),
                _buildTextField('Major Subjects', _controllers['edu_deg_$i']),
                SizedBox(height: isMob ? 12 : 18),
                isMob
                    ? Column(
                        children: [
                          _buildTextField(
                            'Duration',
                            _controllers['edu_date_$i'],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            'GPA / Marks',
                            _controllers['edu_grade_$i'],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              'Duration',
                              _controllers['edu_date_$i'],
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _buildTextField(
                              'GPA / Marks',
                              _controllers['edu_grade_$i'],
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── STEP 2: EXPERIENCE ───────────────────────────────────────────────────
  Widget _buildExperienceStep(double w) {
    final count = _result?.professionalExperience.length ?? 0;
    final isMob = _BP.isMobile(w);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Operational Experience',
          'Detailed breakdown of flight commands and duties',
          w,
        ),
        SizedBox(height: isMob ? 20 : 32),
        if (count == 0)
          _buildEmptyState('No experience data found.')
        else
          ...List.generate(
            count,
            (i) => _buildDataCard(
              title: 'OPERATIONAL ROLE ${i + 1}',
              w: w,
              children: [
                isMob
                    ? Column(
                        children: [
                          _buildTextField(
                            'Organization',
                            _controllers['exp_org_$i'],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField('Role', _controllers['exp_role_$i']),
                          const SizedBox(height: 12),
                          _buildTextField('Rank', _controllers['exp_rank_$i']),
                          const SizedBox(height: 12),
                          _buildTextField('Unit', _controllers['exp_unit_$i']),
                          const SizedBox(height: 12),
                          _buildTextField(
                            'Aircraft Type',
                            _controllers['exp_aircraft_$i'],
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            'Flight Hours',
                            _controllers['exp_hours_$i'],
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'Organization',
                                  _controllers['exp_org_$i'],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _buildTextField(
                                  'Role',
                                  _controllers['exp_role_$i'],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'Rank',
                                  _controllers['exp_rank_$i'],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _buildTextField(
                                  'Unit',
                                  _controllers['exp_unit_$i'],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'Aircraft Type',
                                  _controllers['exp_aircraft_$i'],
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _buildTextField(
                                  'Flight Hours',
                                  _controllers['exp_hours_$i'],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                SizedBox(height: isMob ? 12 : 18),
                _buildTextField(
                  'Duties & Responsibilities',
                  _controllers['exp_desc_$i'],
                  false,
                  isMob ? 3 : 4,
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── STEP 3: FINAL REVIEW ─────────────────────────────────────────────────
  Widget _buildFinalReviewStep(double w) {
    final isMob = _BP.isMobile(w);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: isMob ? 20 : 32),
          child: Column(
            children: [
              Text(
                'Final Document Review',
                style: BrandTypography.h1.copyWith(fontSize: isMob ? 22 : 30),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This is how your profile will appear to recruiters.',
                style: BrandTypography.body.copyWith(
                  color: BrandColors.slate400,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: BrandColors.slate200),
            boxShadow: [
              BoxShadow(
                color: BrandColors.slate950.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          // On mobile: stack sidebar above content
          child: isMob
              ? Column(
                  children: [
                    _buildReviewSidebar(isMob: true),
                    const Divider(height: 1, color: BrandColors.slate200),
                    _buildReviewMain(isMob: true),
                  ],
                )
              : IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _buildReviewSidebar()),
                      Expanded(flex: 7, child: _buildReviewMain()),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildReviewSidebar({bool isMob = false}) {
    return Container(
      color: BrandColors.slate50,
      padding: EdgeInsets.all(isMob ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMob) ...[
            _buildReviewCircleAvatar(),
            const SizedBox(height: 28),
          ],
          _buildReviewSidebarSection('CONTACT', [
            _reviewInfoItem(Icons.email_outlined, _controllers['email']?.text),
            _reviewInfoItem(
              Icons.phone_iphone_outlined,
              _controllers['phone']?.text,
            ),
            _reviewInfoItem(
              Icons.location_on_outlined,
              _controllers['location']?.text,
            ),
          ]),
          const SizedBox(height: 28),
          _buildReviewSidebarSection('TECHNICAL SKILLS', [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedSkills
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: BrandColors.slate200),
                      ),
                      child: Text(
                        skill,
                        style: BrandTypography.label.copyWith(
                          fontSize: 10,
                          color: BrandColors.slate800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildReviewMain({bool isMob = false}) {
    return Padding(
      padding: EdgeInsets.all(isMob ? 20 : 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _controllers['name']?.text.toUpperCase() ?? 'NAME NOT PROVIDED',
            style: BrandTypography.h1.copyWith(
              letterSpacing: 1.5,
              fontSize: isMob ? 20 : 30,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _controllers['bio']?.text ?? 'No professional summary provided.',
            style: BrandTypography.body.copyWith(
              color: BrandColors.slate800,
              height: 1.5,
              fontSize: isMob ? 13 : 15,
            ),
          ),
          SizedBox(height: isMob ? 28 : 44),
          _buildReviewMainSection(
            'PROFESSIONAL EXPERIENCE',
            Icons.work_outline,
          ),
          ..._buildExperienceReviewList(),
          SizedBox(height: isMob ? 24 : 36),
          _buildReviewMainSection('ACADEMIC BACKGROUND', Icons.school_outlined),
          ..._buildEducationReviewList(),
        ],
      ),
    );
  }

  // ─── Review helpers ───────────────────────────────────────────────────────
  Widget _buildReviewCircleAvatar() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: BrandColors.slate200,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: const Icon(Icons.person, size: 36, color: BrandColors.slate400),
  );

  Widget _buildReviewSidebarSection(String title, List<Widget> children) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: BrandTypography.label.copyWith(
              color: BrandColors.indigo,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      );

  Widget _reviewInfoItem(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 13, color: BrandColors.slate400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: BrandTypography.body.copyWith(
                fontSize: 12,
                color: BrandColors.slate800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewMainSection(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: BrandColors.slate950),
            const SizedBox(width: 10),
            Text(
              title,
              style: BrandTypography.h2.copyWith(
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const Divider(height: 20, thickness: 1, color: BrandColors.slate950),
      ],
    ),
  );

  List<Widget> _buildExperienceReviewList() {
    final count = _result?.professionalExperience.length ?? 0;
    if (count == 0) {
      return [Text('No experience entries.', style: BrandTypography.body)];
    }
    return List.generate(
      count,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _controllers['exp_role_$i']?.text ?? '',
                    style: BrandTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: BrandColors.slate950,
                    ),
                  ),
                ),
                Text(
                  _controllers['exp_date_$i']?.text ?? '',
                  style: BrandTypography.label.copyWith(fontSize: 11),
                ),
              ],
            ),
            Text(
              _controllers['exp_org_$i']?.text ?? '',
              style: BrandTypography.body.copyWith(
                color: BrandColors.indigo,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_controllers['exp_aircraft_$i']?.text.isNotEmpty ?? false) ...[
              const SizedBox(height: 5),
              Text(
                'AIRCRAFT: ${_controllers['exp_aircraft_$i']?.text}'
                ' | ${_controllers['exp_hours_$i']?.text} hrs',
                style: BrandTypography.label.copyWith(
                  fontSize: 10,
                  color: BrandColors.slate400,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              _controllers['exp_desc_$i']?.text ?? '',
              style: BrandTypography.body.copyWith(
                fontSize: 13,
                color: BrandColors.slate800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEducationReviewList() {
    final count = _result?.educationalProfile.length ?? 0;
    if (count == 0) {
      return [Text('No education entries.', style: BrandTypography.body)];
    }
    return List.generate(
      count,
      (i) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _controllers['edu_inst_$i']?.text ?? '',
                    style: BrandTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _controllers['edu_deg_$i']?.text ?? '',
                    style: BrandTypography.body.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              _controllers['edu_date_$i']?.text ?? '',
              style: BrandTypography.label.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FOOTER ───────────────────────────────────────────────────────────────
  Widget _buildFooter(double w) {
    final isMob = _BP.isMobile(w);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMob ? 0 : 20,
        vertical: isMob ? 16 : 20,
      ),
      decoration: const BoxDecoration(
        color: BrandColors.white,
        border: Border(top: BorderSide(color: BrandColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: _currentStep > 0
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.end,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back_rounded,
                  size: 16, color: BrandColors.navy),
              label: Text(
                'Previous',
                style: BrandTypography.body.copyWith(
                  color: BrandColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: isMob ? 13 : 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isMob ? 16 : 24,
                  vertical: isMob ? 12 : 16,
                ),
                side: const BorderSide(color: BrandColors.navy, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          // Gradient primary — decoration wraps a transparent ElevatedButton
          // so the existing validate/step/submit logic is untouched.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: BrandColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: BrandColors.teal.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (_formKeys[_currentStep]!.currentState!.validate()) {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    _submitFinal();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMob ? 18 : 30,
                  vertical: isMob ? 12 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentStep == 3
                    ? (isMob ? 'Confirm & Create' : 'Confirm & Create Account')
                    : 'Continue →',
                style: BrandTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: isMob ? 13 : 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Reusable components ──────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String sub, double w) {
    final isMob = _BP.isMobile(w);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                gradient: BrandColors.brandGradient,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'STEP DETAILS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMob ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: BrandColors.tealDeep,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: isMob ? 8 : 10),
        Text(
          title,
          style: BrandTypography.h1.copyWith(
            fontSize: isMob ? 20 : 26,
            color: BrandColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: BrandTypography.body.copyWith(
            color: BrandColors.muted,
            fontSize: isMob ? 13 : 15,
          ),
        ),
      ],
    );
  }

  IconData _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('name')) return Icons.person_outline_rounded;
    if (l.contains('email')) return Icons.email_outlined;
    if (l.contains('phone')) return Icons.phone_iphone_rounded;
    if (l.contains('location')) return Icons.location_on_outlined;
    if (l.contains('summary') || l.contains('duties') || l.contains('bio')) {
      return Icons.notes_rounded;
    }
    if (l.contains('institution')) return Icons.account_balance_outlined;
    if (l.contains('major') || l.contains('subject')) {
      return Icons.menu_book_outlined;
    }
    if (l.contains('duration')) return Icons.calendar_today_outlined;
    if (l.contains('gpa') || l.contains('marks')) return Icons.grade_outlined;
    if (l.contains('organization')) return Icons.business_outlined;
    if (l.contains('role')) return Icons.badge_outlined;
    if (l.contains('rank')) return Icons.military_tech_outlined;
    if (l.contains('unit')) return Icons.groups_outlined;
    if (l.contains('aircraft')) return Icons.flight_outlined;
    if (l.contains('hours')) return Icons.timer_outlined;
    return Icons.edit_outlined;
  }

  Widget _buildTextField(
    String label,
    TextEditingController? ctrl, [
    bool required = false,
    int maxLines = 1,
  ]) {
    final multiline = maxLines > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: BrandTypography.label.copyWith(
                fontSize: 11,
                color: BrandColors.slateBrand,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: BrandTypography.label.copyWith(
                  fontSize: 11,
                  color: BrandColors.teal,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: BrandTypography.body.copyWith(
            fontSize: 14,
            color: BrandColors.ink,
          ),
          validator: required
              ? (v) => v!.isEmpty ? 'Field required' : null
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: BrandColors.bgSoft,
            isDense: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 10,
                bottom: multiline ? 40 : 0,
              ),
              child: Icon(
                _iconForLabel(label),
                size: 18,
                color: BrandColors.teal,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 0,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BrandColors.border,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: BrandColors.border,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BrandColors.teal, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BrandColors.rose, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BrandColors.rose, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCard({
    required String title,
    required List<Widget> children,
    required double w,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(_BP.cardPad(w)),
      decoration: BoxDecoration(
        color: BrandColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandColors.border),
        boxShadow: [
          BoxShadow(
            color: BrandColors.ink.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: BrandColors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: BrandTypography.label.copyWith(
                  color: BrandColors.tealDeep,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: BrandColors.bgSoft,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: BrandColors.border),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: BrandColors.tealTint,
              shape: BoxShape.circle,
              border: Border.all(color: BrandColors.teal.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.folder_off_outlined,
              size: 26,
              color: BrandColors.tealDeep,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Nothing here yet',
            style: BrandTypography.h2.copyWith(
              fontSize: 16,
              color: BrandColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: BrandTypography.body.copyWith(
              color: BrandColors.muted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submitFinal() async {
    if (_result != null) {
      _result!.personalProfile['skills'] = _selectedSkills;
    }
    setState(() => _isProcessing = false);

    try {
      final success = await widget.provider.submitExtractedCvAndCreateAccount(
        _result!,
      );
      if (success) {
        _showNotification('Profile created successfully!');
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onSuccess();
        context.go('/dashboard');
      } else {
        _showNotification(
          'Failed to create profile. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      _showNotification('Error: ${e.toString()}', isError: true);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TOP BAR — responsive header + inline timeline
// ═════════════════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final int currentStep;
  final bool showTimeline;
  const _TopBar({required this.currentStep, required this.showTimeline});

  static const _steps = [
    {'label': 'Personal', 'icon': Icons.person_outline},
    {'label': 'Education', 'icon': Icons.school_outlined},
    {'label': 'Experience', 'icon': Icons.flight_outlined},
    {'label': 'Review', 'icon': Icons.verified_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, bc) {
        final w = bc.maxWidth;
        final isMob = _BP.isMobile(w);
        final isTab = _BP.isTablet(w);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: _BP.hPad(w),
            vertical: isMob ? 8 : 12,
          ),
          decoration: const BoxDecoration(
            color: BrandColors.white,
            border: Border(bottom: BorderSide(color: BrandColors.slate200)),
          ),
          child: isMob
              // ── MOBILE: logo + compact stepper stacked ──────────────────
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Image.asset(
                        'images/logo_new.jpeg',
                        height: 60,
                        fit: BoxFit.fill,
                      ),
                    ),
                    if (showTimeline) ...[
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 50,
                          child: _buildMobileStepper(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAiDisclaimer(isMob: true),
                    ],
                  ],
                )
              // ── TABLET / DESKTOP: logo + centered timeline ──────────────
              : Row(
                  children: [
                    Image.asset(
                      'images/logo_new.jpeg',
                      height: isMob ? 70 : 68,
                      fit: BoxFit.contain,
                    ),
                    if (showTimeline) ...[
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDesktopStepper(isTab),
                          const SizedBox(height: 8),
                          _buildAiDisclaimer(),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ],
                ),
        );
      },
    );
  }

  // Compact pill-stepper for mobile
  Widget _buildMobileStepper() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = (i ~/ 2) < currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: done ? BrandColors.teal : BrandColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }
        final idx = i ~/ 2;
        final isCur = currentStep == idx;
        final isDone = currentStep > idx;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isCur ? 46 : 38,
          height: isCur ? 46 : 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isCur ? BrandColors.brandGradient : null,
            color: isCur
                ? null
                : isDone
                ? BrandColors.teal
                : BrandColors.white,
            border: Border.all(
              color: isCur
                  ? BrandColors.teal
                  : isDone
                  ? BrandColors.teal
                  : BrandColors.border,
              width: 1.5,
            ),
            boxShadow: isCur
                ? [
                    BoxShadow(
                      color: BrandColors.teal.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isDone ? Icons.check_rounded : _steps[idx]['icon'] as IconData,
            size: 22,
            color: (isCur || isDone) ? Colors.white : BrandColors.faint,
          ),
        );
      }),
    );
  }

  // Full stepper for tablet / desktop
  Widget _buildDesktopStepper(bool isTab) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_steps.length, (idx) {
        final isDone = currentStep > idx;
        final isCur = currentStep == idx;
        return Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: isCur ? 40 : 34,
                  height: isCur ? 40 : 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isCur ? BrandColors.brandGradient : null,
                    color: isCur
                        ? null
                        : isDone
                        ? BrandColors.teal
                        : BrandColors.white,
                    border: Border.all(
                      color: isCur
                          ? BrandColors.teal
                          : isDone
                          ? BrandColors.teal
                          : BrandColors.border,
                      width: 2,
                    ),
                    boxShadow: isCur
                        ? [
                            BoxShadow(
                              color: BrandColors.teal.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isDone
                        ? Icons.check_rounded
                        : _steps[idx]['icon'] as IconData,
                    size: 22,
                    color: (isCur || isDone)
                        ? Colors.white
                        : BrandColors.faint,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _steps[idx]['label'] as String,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: isCur ? FontWeight.w700 : FontWeight.w500,
                    color: isCur
                        ? BrandColors.navy
                        : isDone
                        ? BrandColors.tealDeep
                        : BrandColors.faint,
                  ),
                ),
              ],
            ),
            if (idx < _steps.length - 1)
              Container(
                width: isTab ? 32 : 44,
                height: 2,
                margin: const EdgeInsets.only(bottom: 22, left: 6, right: 6),
                decoration: BoxDecoration(
                  color: isDone ? BrandColors.teal : BrandColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildAiDisclaimer({bool isMob = false}) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: isMob ? 8 : 12,
      vertical: isMob ? 4 : 6,
    ),
    decoration: BoxDecoration(
      color: BrandColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: BrandColors.emerald.withValues(alpha: 0.5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_awesome, size: 11, color: BrandColors.emerald),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            isMob
                ? 'AI-powered. May miss images/special chars. Editable anytime.'
                : 'Extraction powered by LLM. May not extract images or special characters. Editable anytime.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: BrandColors.emerald,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// FORMAT CHIP — supported-format pill for the upload card
// ═════════════════════════════════════════════════════════════════════════════
class _FormatChip extends StatelessWidget {
  final String label;
  const _FormatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: BrandColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: BrandColors.teal.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: BrandColors.tealDeep,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOADING DOTS (extracted as StatelessWidget — no setState loops)
// ═════════════════════════════════════════════════════════════════════════════
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      final anim = Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
      _ctrls.add(ctrl);
      _anims.add(anim);
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      3,
      (i) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.translate(
            offset: Offset(0, -4 * _anims[i].value),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: BrandColors.slate400.withValues(
                  alpha: 0.4 + 0.6 * _anims[i].value,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
