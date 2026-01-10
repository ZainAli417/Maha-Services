import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../SignUp /signup_provider.dart';
import '../extractor_CV/cv_extractor.dart';

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

class _CvUploadSectionState extends State<CvUploadSection> with SingleTickerProviderStateMixin {
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isProcessing = false;
  String? _errorMsg;
  CvExtractionResult? _result;
  final _controllers = <String, TextEditingController>{};
  bool _showEditForm = false;
  late AnimationController _animController;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // ========== FILE OPERATIONS ==========
  Future<void> _pickAndExtract() async {
    setState(() {
      _errorMsg = null;
      _showEditForm = false;
      _currentStep = 0;
    });

    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
        withData: true,
      );

      if (res == null || res.files.isEmpty) return;

      final file = res.files.first;
      if (file.size > 10 * 1024 * 1024) {
        _showError('File too large. Maximum size is 10MB');
        return;
      }

      setState(() {
        _fileBytes = file.bytes;
        _fileName = file.name;
        _isProcessing = true;
      });

      await _extractData();
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _extractData() async {
    if (_fileBytes == null || _fileName == null) return;

    try {
      final result = await widget.extractor.extractFromFileBytes(
        _fileBytes!,
        filename: _fileName!,
      );

      setState(() {
        _result = result;
        _populateControllers(result);
        _showEditForm = true;
        _isProcessing = false;
      });

      _animController.forward();
      _showSuccess('Data extracted successfully!');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMsg = 'Extraction failed: $e';
      });
    }
  }

  void _populateControllers(CvExtractionResult r) {
    _controllers.clear();

    void set(String key, dynamic value) {
      _controllers[key] = TextEditingController(text: value?.toString() ?? '');
    }

    // Personal info
    final p = r.personalProfile;
    set('name', p['name']);
    set('email', p['email']);
    set('contact', p['contactNumber']);
    set('nationality', p['nationality']);
    set('summary', p['summary'] ?? r.professionalSummary);
    set('skills', (p['skills'] is List) ? (p['skills'] as List).join(', ') : p['skills']);
    set('social', (p['socialLinks'] is List) ? (p['socialLinks'] as List).join('\n') : p['socialLinks']);

    // Education
    for (var i = 0; i < r.educationalProfile.length; i++) {
      final e = r.educationalProfile[i];
      set('edu_inst_$i', e['institutionName']);
      set('edu_dur_$i', e['duration']);
      set('edu_major_$i', e['majorSubjects']);
      set('edu_marks_$i', e['marksOrCgpa']);
    }

    // ✅ NEW: Work Experience
    for (var i = 0; i < r.experiences.length; i++) {
      final exp = r.experiences[i];
      set('exp_org_$i', exp['organization']);
      set('exp_dur_$i', exp['duration']);
      set('exp_role_$i', exp['role']);
      set('exp_duties_$i', exp['duties']);
    }

    // ✅ NEW: Certifications
    for (var i = 0; i < r.certifications.length; i++) {
      final cert = r.certifications[i];
      set('cert_org_$i', cert['organization']);
      set('cert_name_$i', cert['name']);
    }

    // Other fields
    set('pub', r.publications.join('\n'));
    set('award', r.awards.join('\n'));
    set('ref', r.references.join('\n'));
  }
  Future<void> _submitAccount() async {
    if (_result == null) return;

    setState(() => _isProcessing = true);

    final finalResult = CvExtractionResult(
      rawText: _result!.rawText,
      personalProfile: _buildPersonalData(),
      educationalProfile: _buildEducationData(),
      professionalSummary: _controllers['summary']!.text,
      experiences: _buildExperienceData(), // ✅ NEW
      certifications: _buildCertificationData(), // ✅ NEW
      publications: _buildSimpleList('pub'),
      awards: _buildSimpleList('award'),
      references: _buildSimpleList('ref'),
    );

    final success = await widget.provider.submitExtractedCvAndCreateAccount(finalResult);

    setState(() => _isProcessing = false);

    if (success) {
      _showSuccess('Profile created successfully!');
      widget.onSuccess();
    } else {
      _showError(widget.provider.generalError ?? 'Failed to create profile');
    }
  }

  Map<String, dynamic> _buildPersonalData() => {
    'name': _controllers['name']?.text ?? '',
    'email': _controllers['email']?.text ?? '',
    'contactNumber': _controllers['contact']?.text ?? '',
    'nationality': _controllers['nationality']?.text ?? '',
    'summary': _controllers['summary']?.text ?? '',
    'skills': (_controllers['skills']?.text ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(),
    'socialLinks': (_controllers['social']?.text ?? '')
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(),
  };

  List<Map<String, String>> _buildEducationData() {
    final list = <Map<String, String>>[];
    for (var i = 0; i < (_result?.educationalProfile.length ?? 0); i++) {
      list.add({
        'institutionName': _controllers['edu_inst_$i']?.text ?? '',
        'duration': _controllers['edu_dur_$i']?.text ?? '',
        'majorSubjects': _controllers['edu_major_$i']?.text ?? '',
        'marksOrCgpa': _controllers['edu_marks_$i']?.text ?? '',
      });
    }
    return list;
  }

// ✅ NEW: Build work experience data
  List<Map<String, dynamic>> _buildExperienceData() {
    final list = <Map<String, dynamic>>[];
    for (var i = 0; i < (_result?.experiences.length ?? 0); i++) {
      list.add({
        'organization': _controllers['exp_org_$i']?.text ?? '',
        'duration': _controllers['exp_dur_$i']?.text ?? '',
        'role': _controllers['exp_role_$i']?.text ?? '',
        'duties': _controllers['exp_duties_$i']?.text ?? '',
      });
    }
    return list;
  }

// ✅ NEW: Build certification data
  List<Map<String, String>> _buildCertificationData() {
    final list = <Map<String, String>>[];
    for (var i = 0; i < (_result?.certifications.length ?? 0); i++) {
      list.add({
        'organization': _controllers['cert_org_$i']?.text ?? '',
        'name': _controllers['cert_name_$i']?.text ?? '',
      });
    }
    return list;
  }

  List<String> _buildSimpleList(String key) {
    return (_controllers[key]?.text ?? '')
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }











  void _reset() {
    setState(() {
      _fileBytes = null;
      _fileName = null;
      _result = null;
      _showEditForm = false;
      _errorMsg = null;
      _currentStep = 0;
      _controllers.clear();
    });
    _animController.reset();
  }

  void _showError(String msg) {
    setState(() => _errorMsg = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: GoogleFonts.poppins(fontSize: 14))),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: GoogleFonts.poppins(fontSize: 14))),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ========== UI BUILDERS ==========
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUploadCard(),
              if (_showEditForm) ...[
                const SizedBox(height: 32),
                _buildStepperHeader(),
                const SizedBox(height: 24),
                _buildEditCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Row(
      children: [
        _buildStepIndicator(0, 'Personal', Icons.person),
        _buildStepLine(0),
        _buildStepIndicator(1, 'Education', Icons.school),
        _buildStepLine(1),
        _buildStepIndicator(2, 'Experience', Icons.work),
      ],
    );
  }

  Widget _buildStepIndicator(int index, String label, IconData icon) {
    bool isActive = _currentStep == index;
    bool isCompleted = _currentStep > index;
    Color activeColor = const Color(0xFF6366F1);

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive || isCompleted ? activeColor : Colors.grey.shade100,
              shape: BoxShape.circle,
              boxShadow: isActive ? [BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))] : null,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isActive || isCompleted ? Colors.white : Colors.grey.shade500,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? activeColor : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int index) {
    bool isCompleted = _currentStep > index;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isCompleted ? const Color(0xFF6366F1) : Colors.grey.shade200,
    );
  }

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF6366F1), size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'Extract Profile from CV',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your resume to automatically fill your professional profile',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          if (_fileName != null) _buildFileChip() else _buildUploadButton(),
          if (_isProcessing) ...[
            const SizedBox(height: 24),
            _buildLoadingIndicator(),
          ],
          if (_errorMsg != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildFileChip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_rounded, color: Color(0xFF10B981), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fileName!, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                Text('Ready to process', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF10B981))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            onPressed: _reset,
            tooltip: 'Remove file',
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _pickAndExtract,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Choose File'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        const LinearProgressIndicator(
          backgroundColor: Color(0xFFF1F5F9),
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          minHeight: 6,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        const SizedBox(height: 12),
        Text(
          'Analyzing your career path...',
          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMsg!, style: GoogleFonts.poppins(color: const Color(0xFF991B1B), fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildEditCard() {
    return FadeTransition(
      opacity: _animController,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _buildCurrentStepContent(),
            ),
            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Personal Details', 'Basic information for your profile'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _field('Full Name', 'name', icon: Icons.person_outline)),
                const SizedBox(width: 16),
                Expanded(child: _field('Email Address', 'email', icon: Icons.alternate_email_rounded)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _field('Contact Number', 'contact', icon: Icons.phone_android_rounded)),
                const SizedBox(width: 16),
                Expanded(child: _field('Nationality', 'nationality', icon: Icons.public_rounded)),
              ],
            ),
            const SizedBox(height: 16),
            _field('Professional Summary', 'summary', lines: 4, icon: Icons.description_outlined),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Education', 'Your academic background'),
            const SizedBox(height: 24),
            ...List.generate(_result!.educationalProfile.length, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _field('Institution', 'edu_inst_$i', icon: Icons.school_outlined),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _field('Duration', 'edu_dur_$i', icon: Icons.calendar_today_rounded)),
                        const SizedBox(width: 16),
                        Expanded(child: _field('Major/Field', 'edu_major_$i', icon: Icons.category_outlined)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _field('Marks/CGPA', 'edu_marks_$i', icon: Icons.grade_outlined),
                  ],
                ),
              );
            }),
          ],
        );
      case 2:
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Professional Experience', 'Your career journey'),
            const SizedBox(height: 24),

            // ✅ Work Experience Section
            Text(
              'Work Experience',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_result!.experiences.length, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.work_outline_rounded, color: Color(0xFF6366F1), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Position ${i + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _field('Organization', 'exp_org_$i', icon: Icons.business_rounded),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('Duration', 'exp_dur_$i', icon: Icons.calendar_today_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Role/Title', 'exp_role_$i', icon: Icons.badge_outlined)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field('Key Responsibilities & Achievements', 'exp_duties_$i', lines: 4, icon: Icons.checklist_rounded),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            // ✅ Certifications Section
            Text(
              'Certifications',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_result!.certifications.length, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.verified_outlined, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _field('Issuing Organization', 'cert_org_$i', icon: Icons.corporate_fare_rounded),
                          const SizedBox(height: 12),
                          _field('Certification Name', 'cert_name_$i', icon: Icons.emoji_events_outlined),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            _field('Core Skills (comma separated)', 'skills', icon: Icons.auto_awesome_rounded),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        Text(subtitle, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _field(String label, String key, {int lines = 1, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
        const SizedBox(height: 8),
        TextField(
          controller: _controllers[key],
          maxLines: lines,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF64748B)) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey.shade200),
                foregroundColor: const Color(0xFF64748B),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _currentStep < 2 ? _nextStep : _submitAccount,
            icon: Icon(_currentStep < 2 ? Icons.arrow_forward_rounded : Icons.check_circle_rounded),
            label: Text(_currentStep < 2 ? 'Continue' : 'Create Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
