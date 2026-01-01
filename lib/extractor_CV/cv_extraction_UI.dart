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

  // ========== FILE OPERATIONS ==========
  Future<void> _pickAndExtract() async {
    setState(() {
      _errorMsg = null;
      _showEditForm = false;
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

    final p = r.personalProfile;
    set('name', p['name']);
    set('email', p['email']);
    set('contact', p['contactNumber']);
    set('nationality', p['nationality']);
    set('summary', p['summary'] ?? r.professionalSummary);
    set('skills', (p['skills'] is List) ? (p['skills'] as List).join(', ') : p['skills']);
    set('social', (p['socialLinks'] is List) ? (p['socialLinks'] as List).join('\n') : p['socialLinks']);

    for (var i = 0; i < r.educationalProfile.length; i++) {
      final e = r.educationalProfile[i];
      set('edu_inst_$i', e['institutionName']);
      set('edu_dur_$i', e['duration']);
      set('edu_major_$i', e['majorSubjects']);
      set('edu_marks_$i', e['marksOrCgpa']);
    }

    set('exp', r.experiences.map((e) => e['text'] ?? '').join('\n\n'));
    set('cert', r.certifications.join('\n'));
    set('pub', r.publications.join('\n'));
    set('award', r.awards.join('\n'));
    set('ref', r.references.join('\n'));
  }

  Future<void> _submitAccount() async {
    if (_result == null) return;

    final p = widget.provider;


    setState(() => _isProcessing = true);

    final finalResult = CvExtractionResult(
      rawText: _result!.rawText,
      personalProfile: _buildPersonalData(),
      educationalProfile: _buildEducationData(),
      professionalSummary: _controllers['summary']!.text,
      experiences: _buildListData('exp', (t) => {'text': t}),
      certifications: _buildSimpleList('cert'),
      publications: _buildSimpleList('pub'),
      awards: _buildSimpleList('award'),
      references: _buildSimpleList('ref'),
    );

    final success = await p.submitExtractedCvAndCreateAccount(finalResult);

    setState(() => _isProcessing = false);

    if (success) {
      _showSuccess('Profile Created successfully!');
      widget.onSuccess();
    } else {
      _showError(p.generalError ?? 'Failed to create Profile');
    }
  }

  Map<String, dynamic> _buildPersonalData() => {
    'name': _controllers['name']?.text ?? '',
    'email': _controllers['email']?.text ?? '',
    'contactNumber': _controllers['contact']?.text ?? '',
    'nationality': _controllers['nationality']?.text ?? '',
    'summary': _controllers['summary']?.text ?? '',
    'skills': (_controllers['skills']?.text ?? '').split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    'socialLinks': (_controllers['social']?.text ?? '').split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
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

  List<Map<String, String>> _buildListData(String key, Map<String, String> Function(String) mapper) {
    return (_controllers[key]?.text ?? '')
        .split('\n\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(mapper)
        .toList();
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
    return Column(
      children: [
        _buildUploadCard(),
        if (_result != null) ...[
          const SizedBox(height: 16),
          _buildPreviewCard(),
        ],
        if (_showEditForm) ...[
          const SizedBox(height: 16),
          _buildEditCard(),
        ],
      ],
    );
  }

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.indigo.shade50.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.indigo.shade500, Colors.indigo.shade500]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.indigo.shade200, blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Your CV/Resume',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PDF, DOC, DOCX, TXT • Max 10MB',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_fileName != null) _buildFileChip() else _buildUploadButton(),
          if (_isProcessing) ...[
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_rounded, color: Colors.green.shade600, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_fileName!, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.green.shade800)),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.green.shade600),
            onPressed: _reset,
            tooltip: 'Remove file',
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade500, Colors.indigo.shade500]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.indigo.shade300, blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickAndExtract,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.upload_file_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Select & Extract CV',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 12),
          Text(
            'Extracting data from your CV...',
            style: GoogleFonts.poppins(color: Colors.blue.shade800, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_errorMsg!, style: GoogleFonts.poppins(color: Colors.red.shade800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xff5C738A),),
        boxShadow: [BoxShadow(color: Color(0xff5C738A), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade600]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.visibility_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Preview',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildBadge('Name', _result!.personalProfile['name']?.toString() ?? 'N/A', Icons.person_outline_rounded, Colors.blue),
              _buildBadge('Email', _result!.personalProfile['email']?.toString() ?? 'N/A', Icons.email_outlined, Colors.orange),
              _buildBadge('Contact', _result!.personalProfile['contactNumber']?.toString() ?? 'N/A', Icons.phone_outlined, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.indigo.shade700),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.indigo.shade600, fontWeight: FontWeight.w500)),
              Text(
                value.length > 25 ? '${value.substring(0, 25)}...' : value,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo.shade900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditCard() {
    return FadeTransition(
      opacity: _animController,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xff5C738A),),
          boxShadow: [BoxShadow(color: Color(0xff5C738A), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.indigo.shade600]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Review & Edit Extracted Information',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFormSections(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('Personal Information', Icons.person_outline_rounded, Colors.blue, [
          _field('Full Name', 'name'),
          _field('Email Address', 'email'),
          _field('Contact Number', 'contact'),
          _field('Nationality', 'nationality'),
          _field('Professional Summary', 'summary', lines: 3),
          _field('Skills (comma-separated)', 'skills'),
        ]),
        const SizedBox(height: 20),
        _buildSection('Education History', Icons.school_outlined, Colors.indigo, [
          ...List.generate(_result!.educationalProfile.length, (i) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Education ${i + 1}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.indigo.shade700)),
                const SizedBox(height: 8),
                _field('Institution', 'edu_inst_$i'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _field('Duration', 'edu_dur_$i')),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Major/Field', 'edu_major_$i')),
                  ],
                ),
                const SizedBox(height: 8),
                _field('Marks/CGPA', 'edu_marks_$i'),
                if (i < _result!.educationalProfile.length - 1) const SizedBox(height: 16),
              ],
            );
          }),
        ]),
        const SizedBox(height: 20),
        _buildSection('Additional Information', Icons.star_outline_rounded, Colors.orange, [
          _field('Work Experience', 'exp', lines: 4),
          _field('Certifications', 'cert', lines: 2),
          _field('Publications', 'pub', lines: 2),
          _field('Awards & Achievements', 'award', lines: 2),
          _field('References', 'ref', lines: 2),
        ]),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: Colors.indigo.shade700),
            ),
            const SizedBox(width: 10),
            Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _field(String label, String key, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          TextField(
            controller: _controllers[key],
            maxLines: lines,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.indigo.shade400, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text('Start Over', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green.shade500, Colors.green.shade700]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.green.shade300, blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _submitAccount,
                  icon: _isProcessing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(_isProcessing ? 'Creating...' : 'Create Account', style: GoogleFonts.poppins(fontWeight: FontWeight.w600,color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: widget.onManualContinue,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text('Continue with Manual Registration Instead', style: GoogleFonts.poppins(fontSize: 13)),
          style: TextButton.styleFrom(foregroundColor: Colors.indigo.shade600),
        ),
      ],
    );
  }
}