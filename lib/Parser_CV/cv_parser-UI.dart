import 'dart:typed_data';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// Assuming these paths remain the same as per your project structure
import '../SignUp /signup_provider.dart';
import '../Parser_CV/cv_parser.dart';

class BrandColors {
  // Clean White Theme
  static const Color white = Color(0xFFFFFFFF);
  static const Color slate950 = Color(0xFF020617);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  // Functional Accents
  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoHover = Color(0xFF4F46E5);
  static const Color emerald = Color(0xFF10B981);
  static const Color rose = Color(0xFFF43F5E);
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

  static TextStyle body = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: BrandColors.slate800,
    height: 1.6,
  );

  static TextStyle label = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: BrandColors.slate600,
    letterSpacing: 0.5,
  );

  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: BrandColors.slate400,
    letterSpacing: 0.3,
  );
}

class AviationSkills {
  static const List<String> commonSkills = [
    'Tactical Operations', 'Flight Planning', 'Aircraft Systems',
    'Navigation & Avionics', 'Air Defense', 'Combat Operations',
    'Mission Planning', 'Weapon Systems', 'Emergency Procedures',
    'Crew Resource Management', 'Meteorology', 'Formation Flying',
    'Electronic Warfare', 'Search & Rescue', 'Leadership & Command',
  ];
}

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

class _CvUploadSectionState extends State<CvUploadSection> with TickerProviderStateMixin {
  // State Variables
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

  // ----------------------------------------------------------------------
  // LOGIC & EXTRACTION
  // ----------------------------------------------------------------------

  Future<void> _handleFileSelection() async {
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
    _selectedSkills.clear();

    void bind(String k, dynamic v) {
      _controllers[k] = TextEditingController(text: v?.toString() ?? '');
    }

    final p = r.personalProfile;
    bind('name', p['name']);
    bind('email', p['email']);
    bind('phone', p['contactNumber']);
    bind('location', p['nationality']);
    bind('bio', p['summary'] ?? r.professionalSummary);

    if (p['skills'] is List) {
      _selectedSkills.addAll((p['skills'] as List).map((s) => s.toString()));
    } else if (p['skills'] is String && (p['skills'] as String).isNotEmpty) {
      _selectedSkills.addAll((p['skills'] as String).split(',').map((s) => s.trim()));
    }

    for (var i = 0; i < r.educationalProfile.length; i++) {
      final edu = r.educationalProfile[i];
      bind('edu_inst_$i', edu['institutionName']);
      bind('edu_deg_$i', edu['majorSubjects']);
      bind('edu_date_$i', edu['duration']);
      bind('edu_grade_$i', edu['marksOrCgpa']);
    }

    for (var i = 0; i < r.professionalExperience.length; i++) {
      final exp = r.professionalExperience[i];
      bind('exp_org_$i', exp['organization']);
      bind('exp_role_$i', exp['role']);
      bind('exp_date_$i', exp['duration']);
      bind('exp_desc_$i', exp['duties']);
      bind('exp_rank_$i', exp['rank']);
      bind('exp_unit_$i', exp['unit']);
      bind('exp_command_$i', exp['command']);
      bind('exp_location_$i', exp['location']);
      bind('exp_aircraft_$i', exp['aircraftType']);
      bind('exp_hours_$i', exp['flightHours']);
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: isError ? BrandColors.rose : BrandColors.emerald,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // UI BUILDERS
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.white,
      body: Column(
        children: [
          _buildCleanHeader(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutQuart,
              child: _isProcessing
                  ? _buildProcessingView()
                  : _showEditForm
                  ? _buildEditorView()
                  : _buildUploadView(),
            ),
          ),
        ],
      ),
    );
  }


  // --- VIEW: UPLOAD ---
  Widget _buildCleanHeader() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        color: BrandColors.white,
      ),
      child: Row(
        children: [
          Image.asset(
            'images/logo.png',
            height: 80,
            fit: BoxFit.fill
          ),
          Spacer(),
          Center(

         child: _buildCenteredTimeline(),
          ),
          Spacer(),


        ],
      ),
    );
  }
  Widget _buildUploadView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('Professional Data Extraction', style: BrandTypography.h1.copyWith(fontSize: 32)),
              const SizedBox(height: 14),
              Text(
                'Upload your CV. Our AI will automatically categorize your aviation experience, flight hours, and technical certifications.',
                textAlign: TextAlign.center,
                style: BrandTypography.body.copyWith(color: BrandColors.slate400),
              ),
              const SizedBox(height: 50),
              _buildDropZone(),
              const SizedBox(height: 32),
              TextButton(
                onPressed: widget.onManualContinue,
                child: Text(
                  'Enter data manually instead →',
                  style: BrandTypography.body.copyWith(color: BrandColors.indigo, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropZone() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringUpload = true),
      onExit: (_) => setState(() => _isHoveringUpload = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _handleFileSelection,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: 280,
          decoration: BoxDecoration(
            color: _isHoveringUpload ? BrandColors.slate50 : BrandColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHoveringUpload ? BrandColors.indigo : BrandColors.slate200,
              width: 2,
            ),
            boxShadow: _isHoveringUpload
                ? [BoxShadow(color: BrandColors.indigo.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))]
                : [BoxShadow(color: BrandColors.slate950.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, size: 52, color: _isHoveringUpload ? BrandColors.indigo : BrandColors.slate400),
              const SizedBox(height: 18),
              Text('Drag and drop resume here', style: BrandTypography.h2.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Text('Supports PDF, DOCX up to 15MB', style: BrandTypography.caption.copyWith(color: BrandColors.slate400)),
            ],
          ),
        ),
      ),
    );
  }

  // --- VIEW: PROCESSING ---

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated processing indicator with rings
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              TweenAnimationBuilder(
                key: const ValueKey('outer-ring'), // ✅ Add key
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                onEnd: () {
                  // Do nothing - let it stop naturally
                },
                builder: (context, double value, child) {
                  return Container(
                    width: 120 + (value * 20),
                    height: 120 + (value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: BrandColors.indigo.withOpacity(0.2 * (1 - value)),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              // Middle ring
              TweenAnimationBuilder(
                key: const ValueKey('middle-ring'), // ✅ Add key
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1500),
                onEnd: () {
                  // Do nothing - let it stop naturally
                },
                builder: (context, double value, child) {
                  return Container(
                    width: 100 + (value * 15),
                    height: 100 + (value * 15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: BrandColors.indigo.withOpacity(0.3 * (1 - value)),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              // Inner container with icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BrandColors.white,
                  border: Border.all(color: BrandColors.slate200, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.indigo.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    // Rotating progress indicator
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: BrandColors.indigo,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    // Document icon
                    Icon(
                      Icons.description_outlined,
                      size: 36,
                      color: BrandColors.indigo,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Static title (no animation loop)
          Text(
            'Analyzing Document',
            style: BrandTypography.h2.copyWith(fontSize: 26),
          ),

          const SizedBox(height: 12),

          // Animated subtitle with dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Extracting aviation data',
                style: BrandTypography.body.copyWith(
                  color: BrandColors.slate400,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              _buildLoadingDots(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),

          builder: (context, double value, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -4 * (value > 0.5 ? 1 - value : value) * 2),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BrandColors.slate400.withOpacity(
                      0.4 + (0.6 * (value > 0.5 ? 1 - value : value) * 2),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }



  // --- VIEW: EDITOR ---

  Widget _buildEditorView() {
    return Column(
      children: [

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: Form(
                      key: _formKeys[_currentStep],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStepContent(),

                          const SizedBox(height: 40),

                          /// ✅ FOOTER NOW AT END OF FORM
                          _buildStickyFooter(),

                          const SizedBox(height: 40), // bottom breathing space
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


  Widget _buildCenteredTimeline() {
    final steps = [
      {'label': 'Personal', 'icon': Icons.person_outline},
      {'label': 'Education', 'icon': Icons.school_outlined},
      {'label': 'Experience', 'icon': Icons.flight_outlined},
      {'label': 'Review', 'icon': Icons.verified_outlined},
    ];

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: BrandColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BrandColors.slate200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: BrandColors.slate950.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. The Timeline Row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(steps.length, (index) {
                final isDone = _currentStep > index;
                final isCurrent = _currentStep == index;
                final isUpcoming = _currentStep < index;

                return Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon Circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isCurrent ? 42 : 36,
                          height: isCurrent ? 42 : 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? BrandColors.indigo
                                : (isDone ? BrandColors.emerald : BrandColors.white),
                            border: Border.all(
                              color: isCurrent
                                  ? BrandColors.indigo
                                  : (isDone ? BrandColors.emerald : BrandColors.slate300),
                              width: 2,
                            ),
                            boxShadow: isCurrent
                                ? [
                              BoxShadow(
                                color: BrandColors.indigo.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ]
                                : null,
                          ),
                          child: Icon(
                            isDone ? Icons.check_rounded : (steps[index]['icon'] as IconData),
                            size: 18,
                            color: isCurrent || isDone
                                ? Colors.white
                                : BrandColors.slate400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Label
                        Text(
                          steps[index]['label'] as String,
                          style: BrandTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent
                                ? BrandColors.slate950
                                : (isDone ? BrandColors.emerald : BrandColors.slate400),
                          ),
                        ),
                      ],
                    ),
                    // Connecting Line
                    if (index < steps.length - 1)
                      Container(
                        width: 40,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
                        color: isDone ? BrandColors.emerald : BrandColors.slate200,
                      ),
                  ],
                );
              }),
            ),

            const SizedBox(height: 5),

            // 2. The AI Disclaimer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BrandColors.white, // Light orange/yellow background
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BrandColors.emerald.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: BrandColors.emerald),
                  const SizedBox(width: 6),
                  Text(
                    "Extraction is Powered by LLM May Not Extract Images or speical characters. You can edit any information now or later after creating profile",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: BrandColors.emerald,
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
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalStep();
      case 1:
        return _buildEducationStep();
      case 2:
        return _buildExperienceStep();
      case 3:
        return _buildFinalReviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPersonalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Personal Profile', 'Personal Record and contact details'),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildTextField('Full Name', _controllers['name'], true)),
            const SizedBox(width: 20),
            Expanded(child: _buildTextField('Email Address', _controllers['email'], true)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('Phone Number', _controllers['phone'])),
            const SizedBox(width: 20),
            Expanded(child: _buildTextField('Location', _controllers['location'])),
          ],
        ),
        const SizedBox(height: 20),
        _buildTextField('Professional Summary', _controllers['bio'], false, 4),
        const SizedBox(height: 36),
        _buildSkillSelector(),
      ],
    );
  }

  Widget _buildSkillSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TECHNICAL COMPETENCIES', style: BrandTypography.label.copyWith(fontSize: 12)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: BrandColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrandColors.slate200, width: 1.5),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AviationSkills.commonSkills.map((s) {
              bool selected = _selectedSkills.contains(s);
              return InkWell(
                onTap: () => setState(() => selected ? _selectedSkills.remove(s) : _selectedSkills.add(s)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? BrandColors.indigo.withOpacity(0.08) : BrandColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? BrandColors.indigo : BrandColors.slate200, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        s,
                        style: BrandTypography.caption.copyWith(
                          color: selected ? BrandColors.indigo : BrandColors.slate600,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle, size: 15, color: BrandColors.indigo),
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

  Widget _buildEducationStep() {
    int count = _result?.educationalProfile.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Educational Background', 'Academic qualifications and technical schooling'),
        const SizedBox(height: 32),
        if (count == 0)
          _buildEmptyState('No academic data found.')
        else
          ...List.generate(
            count,
                (i) => _buildDataCard(
              title: 'QUALIFICATION ${i + 1}',
              children: [
                _buildTextField('Institution', _controllers['edu_inst_$i']),
                const SizedBox(height: 18),
                _buildTextField('Major Subjects', _controllers['edu_deg_$i']),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Duration', _controllers['edu_date_$i'])),
                    const SizedBox(width: 18),
                    Expanded(child: _buildTextField('GPA / Marks', _controllers['edu_grade_$i'])),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildExperienceStep() {
    int count = _result?.professionalExperience.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Operational Experience', 'Detailed breakdown of flight commands and duties'),
        const SizedBox(height: 32),
        if (count == 0)
          _buildEmptyState('No experience data found.')
        else
          ...List.generate(
            count,
                (i) => _buildDataCard(
              title: 'OPERATIONAL ROLE ${i + 1}',
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTextField('Organization', _controllers['exp_org_$i'])),
                    const SizedBox(width: 18),
                    Expanded(child: _buildTextField('Role', _controllers['exp_role_$i'])),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Rank', _controllers['exp_rank_$i'])),
                    const SizedBox(width: 18),
                    Expanded(child: _buildTextField('Unit', _controllers['exp_unit_$i'])),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Aircraft Type', _controllers['exp_aircraft_$i'])),
                    const SizedBox(width: 18),
                    Expanded(child: _buildTextField('Flight Hours', _controllers['exp_hours_$i'])),
                  ],
                ),
                const SizedBox(height: 18),
                _buildTextField('Duties & Responsibilities', _controllers['exp_desc_$i'], false, 3),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFinalReviewStep() {
    return Column(
      children: [
        // Top header for the review stage
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              Text('Final Document Review', style: BrandTypography.h1),
              Text(
                'This is how your profile will appear to recruiters. Please verify all details.',
                style: BrandTypography.body.copyWith(color: BrandColors.slate400),
              ),
            ],
          ),
        ),

        // The Virtual "Paper" CV
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: BrandColors.slate200),
            boxShadow: [
              BoxShadow(
                color: BrandColors.slate950.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- LEFT SIDEBAR (Contact & Skills) ---
                Expanded(
                  flex: 3,
                  child: Container(
                    color: BrandColors.slate50,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReviewCircleAvatar(),
                        const SizedBox(height: 32),
                        _buildReviewSidebarSection('CONTACT', [
                          _reviewInfoItem(Icons.email_outlined, _controllers['email']?.text),
                          _reviewInfoItem(Icons.phone_iphone_outlined, _controllers['phone']?.text),
                          _reviewInfoItem(Icons.location_on_outlined, _controllers['location']?.text),
                        ]),
                        const SizedBox(height: 40),
                        _buildReviewSidebarSection('TECHNICAL SKILLS', [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _selectedSkills.map((skill) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: BrandColors.slate200),
                              ),
                              child: Text(
                                skill,
                                style: BrandTypography.label.copyWith(fontSize: 10, color: BrandColors.slate800),
                              ),
                            )).toList(),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),

                // --- MAIN CONTENT (Experience & Education) ---
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Bio
                        Text(_controllers['name']?.text.toUpperCase() ?? 'NAME NOT PROVIDED',
                            style: BrandTypography.h1.copyWith(letterSpacing: 2, fontSize: 32)),
                        const SizedBox(height: 12),
                        Text(
                          _controllers['bio']?.text ?? 'No professional summary provided.',
                          style: BrandTypography.body.copyWith(color: BrandColors.slate800, height: 1.5),
                        ),
                        const SizedBox(height: 48),

                        // Experience Section
                        _buildReviewMainSection('PROFESSIONAL EXPERIENCE', Icons.work_outline),
                        ..._buildExperienceReviewList(),

                        const SizedBox(height: 40),

                        // Education Section
                        _buildReviewMainSection('ACADEMIC BACKGROUND', Icons.school_outlined),
                        ..._buildEducationReviewList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

// --- HELPER UI COMPONENTS FOR CV TEMPLATE ---

  Widget _buildReviewCircleAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: BrandColors.slate200,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Center(
        child: Icon(Icons.person, size: 40, color: BrandColors.slate400),
      ),
    );
  }

  Widget _buildReviewSidebarSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: BrandTypography.label.copyWith(color: BrandColors.indigo, fontSize: 11)),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _reviewInfoItem(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: BrandColors.slate400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: BrandTypography.body.copyWith(fontSize: 13, color: BrandColors.slate800)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewMainSection(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: BrandColors.slate950),
              const SizedBox(width: 12),
              Text(title, style: BrandTypography.h2.copyWith(fontSize: 16, letterSpacing: 1.5)),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: BrandColors.slate950),
        ],
      ),
    );
  }

  List<Widget> _buildExperienceReviewList() {
    int count = _result?.professionalExperience.length ?? 0;
    if (count == 0) return [Text('No experience entries.', style: BrandTypography.body)];

    return List.generate(count, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_controllers['exp_role_$i']?.text ?? '',
                    style: BrandTypography.body.copyWith(fontWeight: FontWeight.w700, color: BrandColors.slate950)),
                Text(_controllers['exp_date_$i']?.text ?? '',
                    style: BrandTypography.label.copyWith(fontSize: 11)),
              ],
            ),
            Text(_controllers['exp_org_$i']?.text ?? '',
                style: BrandTypography.body.copyWith(color: BrandColors.indigo, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            if (_controllers['exp_aircraft_$i']?.text.isNotEmpty ?? false)
              Text('AIRCRAFT: ${_controllers['exp_aircraft_$i']?.text} | ${_controllers['exp_hours_$i']?.text} hrs',
                  style: BrandTypography.label.copyWith(fontSize: 10, color: BrandColors.slate400)),
            const SizedBox(height: 8),
            Text(_controllers['exp_desc_$i']?.text ?? '',
                style: BrandTypography.body.copyWith(fontSize: 14, color: BrandColors.slate800)),
          ],
        ),
      );
    });
  }

  List<Widget> _buildEducationReviewList() {
    int count = _result?.educationalProfile.length ?? 0;
    if (count == 0) return [Text('No education entries.', style: BrandTypography.body)];

    return List.generate(count, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_controllers['edu_inst_$i']?.text ?? '',
                      style: BrandTypography.body.copyWith(fontWeight: FontWeight.w700)),
                  Text(_controllers['edu_deg_$i']?.text ?? '',
                      style: BrandTypography.body.copyWith(fontSize: 14)),
                ],
              ),
            ),
            Text(_controllers['edu_date_$i']?.text ?? '',
                style: BrandTypography.label.copyWith(fontSize: 11)),
          ],
        ),
      );
    });
  }
  // --- REUSABLE UI COMPONENTS ---

  Widget _buildSectionHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: BrandTypography.h1.copyWith(fontSize: 26)),
        const SizedBox(height: 4),
        Text(sub, style: BrandTypography.body.copyWith(color: BrandColors.slate400)),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController? ctrl, [bool required = false, int maxLines = 1]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: BrandTypography.label.copyWith(fontSize: 11)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: BrandTypography.body.copyWith(fontSize: 14),
          validator: required ? (v) => v!.isEmpty ? 'Field required' : null : null,
          decoration: InputDecoration(
            filled: false,
            fillColor: BrandColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: BrandColors.slate200, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: BrandColors.slate200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: BrandColors.indigo, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: BrandColors.rose, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: BrandColors.rose, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: BrandColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.slate200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bookmark_border, size: 18, color: BrandColors.indigo),
              const SizedBox(width: 10),
              Text(title, style: BrandTypography.label.copyWith(color: BrandColors.indigo, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.slate200, width: 1.5),
      ),
      child: Center(child: Text(msg, style: BrandTypography.body.copyWith(color: BrandColors.slate400))),
    );
  }

  Widget _buildStickyFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: BrandColors.white,
        border: Border(top: BorderSide(color: BrandColors.slate200, width: 1)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    side: const BorderSide(color: BrandColors.slate300, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Previous Step', style: BrandTypography.body.copyWith(color: BrandColors.slate600, fontWeight: FontWeight.w600)),
                )
              else
                const SizedBox(),
              ElevatedButton(
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
                  backgroundColor: BrandColors.slate950,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  _currentStep == 3 ? 'Confirm & Create Account' : 'Continue to Next Step',
                  style: BrandTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitFinal() async {
    if (_result != null) {
      _result!.personalProfile['skills'] = _selectedSkills;
    }
    setState(() => _isProcessing = false);

    try {
      final success = await widget.provider.submitExtractedCvAndCreateAccount(_result!);


      if (success) {
        // Show success message
        _showNotification('Profile created successfully!');

        // Small delay to show the notification
        await Future.delayed(const Duration(milliseconds: 500));

        // Call the success callback
        widget.onSuccess();
        context.go('/dashboard');
      } else {
        _showNotification('Failed to create profile. Please try again.', isError: true);
      }
    } catch (e) {
      _showNotification('Error: ${e.toString()}', isError: true);
    }
  }

}