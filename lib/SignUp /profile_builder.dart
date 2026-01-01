// lib/screens/profile_builder_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:job_portal/SignUp%20/signup_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../extractor_CV/cv_extraction_UI.dart';
import '../extractor_CV/cv_extractor.dart';
import '../main.dart';

class ProfileBuilderScreen extends StatefulWidget {
  const ProfileBuilderScreen({super.key});

  @override
  State<ProfileBuilderScreen> createState() => _ProfileBuilderScreenState();
}

class _ProfileBuilderScreenState extends State<ProfileBuilderScreen>
    with TickerProviderStateMixin {
  final _personalFormKey = GlobalKey<FormState>();
  final _educationFormKey = GlobalKey<FormState>();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final _formKeyAccount = GlobalKey<FormState>();

  final _editInstitution = TextEditingController();
  final _editDuration = TextEditingController();
  final _editMajor = TextEditingController();
  final _editMarks = TextEditingController();

  static final String GEMINI_API_KEY = Env.geminiApiKey;
  late final extractor = CvExtractor(geminiApiKey: GEMINI_API_KEY);
  final GlobalKey _cvSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _animateStepChange() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        margin: const EdgeInsets.all(16),
        duration: Duration(milliseconds: isError ? 3500 : 2500),
      ),
    );
  }

  // ========== PROFILE CHOICE PANEL ==========
  Widget profileChoicePanel(BuildContext context, SignupProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_circle_outlined, color: Colors.white, size: 26),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build Your Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choose how you want to create your profile',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 30),

        // CV Upload Option
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.indigo.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description_outlined, color: Colors.white, size: 22),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Do you have a CV/Resume?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Upload for faster registration',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        p.revealCvUpload(reveal: true);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final ctx = _cvSectionKey.currentContext;
                          if (ctx != null) {
                            Scrollable.ensureVisible(
                              ctx,
                              duration: Duration(milliseconds: 400),
                            );
                          }
                        });
                      },
                      icon: Icon(Icons.upload_file_rounded),
                      label: Text('Upload CV', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        p.revealNextPersonalField();
                        p.goToStep(1);
                        _animateStepChange();
                      },
                      icon: Icon(Icons.arrow_forward_rounded),
                      label: Text('Continue Manually', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              Consumer<SignupProvider>(
                builder: (_, prov, __) {
                  if (!prov.showCvUploadSection) return SizedBox.shrink();
                  return Container(
                    key: _cvSectionKey,
                    margin: EdgeInsets.only(top: 20),
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: CvUploadSection(
                      extractor: extractor,
                      provider: prov,
                      onSuccess: () => context.go('/login'),
                      onManualContinue: () {
                        prov.revealCvUpload(reveal: false);
                        prov.revealNextPersonalField();
                        prov.goToStep(1);
                        _animateStepChange();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ========== PERSONAL PANEL ==========
  // OPTIMIZED & FIXED Personal Panel Widget
// OPTIMIZED & FIXED Personal Panel Widget

  Widget personalPanel(BuildContext context, SignupProvider p) {
    final progress = p.computeProgress();

    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6366F1),
                            const Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tell us about yourself and showcase your expertise',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.shade100, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Profile Completion',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo.shade900,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.indigo.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Stack(
                              children: [
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF6366F1),
                                          const Color(0xFF8B5CF6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Form Fields
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldRow(
                      isNarrow: isNarrow,
                      children: [
                        if (p.personalVisibleIndex >= 0)
                          _buildFieldWrapper(
                            flex: 2,
                            child: _buildEnhancedTextField(
                              controller: p.nameController,
                              label: 'Full Name',
                              hint: 'Enter your full name',
                              icon: Icons.person_outline_rounded,
                              onChanged: (v) =>
                                  p.onFieldTypedAutoReveal(0, v), // Index 0
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Name required'
                                  : null,
                            ),
                          ),

                        if (p.personalVisibleIndex >= 1)
                          _buildFieldWrapper(
                            flex: 2,
                            child: _buildEnhancedTextField(
                              controller: p.contactNumberController,
                              label: 'Contact Number',
                              hint: '+92 300 1234567',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              onChanged: (v) =>
                                  p.onFieldTypedAutoReveal(1, v), // Index 1
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Contact required';
                                }
                                final phoneRegex = RegExp(
                                  r'^[\d\+\-\s]{5,20}$',
                                );
                                if (!phoneRegex.hasMatch(v.trim())) {
                                  return 'Enter valid number';
                                }
                                return null;
                              },
                            ),
                          ),

                        if (p.personalVisibleIndex >= 2)
                          _buildFieldWrapper(
                            flex: 2,
                            child: _buildEnhancedTextField(
                              controller: p.nationalityController,
                              label: 'Nationality',
                              hint: 'e.g., Pakistani',
                              icon: Icons.flag_outlined,
                              onChanged: (v) =>
                                  p.onFieldTypedAutoReveal(2, v), // Index 2
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Nationality required'
                                  : null,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (p.personalVisibleIndex >= 3)
                      _buildEnhancedTextField(
                        controller: p.summaryController,
                        label: 'Professional Summary',
                        hint:
                        'Brief description of your background and expertise',
                        icon: Icons.article_outlined,
                        maxLines: 3,
                        onChanged: (v) => p.onFieldTypedAutoReveal(
                          3,
                          v,
                        ), // FIXED: Index 3 (was 4)
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Summary required'
                            : null,
                      ),

                    const SizedBox(height: 16),

                    if (p.personalVisibleIndex >= 4)
                      _buildFieldRow(
                        isNarrow: isNarrow,
                        children: [
                          _buildFieldWrapper(
                            flex: 3,
                            child: _buildAvatarCompact(p),
                          ),
                          _buildFieldWrapper(
                            flex: 4,
                            child: _buildSkillsCompact(
                              p,
                            ), // Make sure this triggers index 4 when skills are added
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    if (p.personalVisibleIndex >= 4 && p.skills.isNotEmpty)
                      _buildFieldRow(
                        isNarrow: isNarrow,
                        children: [
                          _buildFieldWrapper(
                            flex: 6,
                            child: _buildEnhancedTextField(
                              controller: p.objectivesController,
                              label: 'Career Objectives',
                              hint: 'What are your career goals?',
                              icon: Icons.flag_circle_rounded,
                              maxLines: 3,
                              onChanged: (v) => p.onFieldTypedAutoReveal(
                                5,
                                v,
                              ), // FIXED: Index 5 (was 6)
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Objectives required'
                                  : null,
                            ),
                          ),
                          _buildFieldWrapper(
                            flex: 2,
                            child: _buildDobCompact(
                              p,
                            ), // DOB should auto-reveal index 6 when selected
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    p.goToStep(0);
                    _animateStepChange();
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: Text(
                    'Back',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      foregroundColor:
                      Colors.white, // <-- THIS MAKES THE TEXT WHITE
                      backgroundColor:
                      Colors.indigo, // optional (your brand color)
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final okForm =
                          _personalFormKey.currentState?.validate() ?? false;

                      if (!okForm) {
                        _showSnackBar(
                          'Please complete all required fields',
                          isError: true,
                        );
                        return;
                      }

                      if (p.skills.isEmpty) {
                        _showSnackBar(
                          'Please add at least one skill',
                          isError: true,
                        );
                        return;
                      }

                      if (p.dob == null) {
                        _showSnackBar(
                          'Please select date of birth',
                          isError: true,
                        );
                        return;
                      }

                      p.goToStep(2);
                      _animateStepChange();
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(
                      'Next: Education',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
  Widget _buildFieldWrapper({required int flex, required Widget child}) {
    return _FieldWrapper(flex: flex, child: child);
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.15),
                    const Color(0xFF8B5CF6).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }


// FIXED DOB Widget

  Widget _buildFieldRow({
    required bool isNarrow,
    required List<Widget> children,
  }) {
    if (isNarrow) {
      return Column(
        children: children.map((child) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: child,
          );
        }).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((child) {
        final isLast = children.indexOf(child) == children.length - 1;
        return Expanded(
          flex: (child as _FieldWrapper).flex,
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: child.child,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvatarCompact(SignupProvider p) {
    Widget avatarPreview() {
      if (p.profilePicBytes != null) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: MemoryImage(p.profilePicBytes!),
          ),
        );
      }

      if (p.imageDataUrl != null) {
        try {
          final bytes = base64Decode(p.imageDataUrl!.split(',').last);
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: MemoryImage(bytes),
            ),
          );
        } catch (_) {
          // fallthrough to placeholder if decode fails
        }
      }

      // placeholder avatar
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.indigo.shade50, Colors.indigo.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.shade100,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: 56,
          backgroundColor: Colors.transparent,
          child: Icon(
            Icons.person_outline_rounded,
            size: 48,
            color: Colors.indigo.shade400,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.indigo.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatarPreview(),
          const SizedBox(height: 16),
          Text(
            'Profile Photo',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons: responsive horizontal layout with spacing
          Wrap(
            spacing: 12, // horizontal gap between buttons
            runSpacing: 8, // vertical gap if wrapped to next line
            alignment: WrapAlignment.center,
            children: [
              _buildActionButton(
                label: p.profilePicBytes == null && p.imageDataUrl == null
                    ? 'Upload'
                    : 'Change',
                icon: Icons.upload_file_rounded,
                isPrimary: true,
                onPressed: () async {
                  await p.pickProfilePicture();
                  // reveal next personal field when user uploads on the avatar/skills step
                  if (p.personalVisibleIndex == 4) p.revealNextPersonalField();
                },
              ),

              if (p.profilePicBytes != null || p.imageDataUrl != null)
                _buildActionButton(
                  label: 'Remove',
                  icon: Icons.delete_outline_rounded,
                  isPrimary: false,
                  onPressed: () => p.removeProfilePicture(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCompact(SignupProvider p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.indigo.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Skills',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${p.skills.length} added',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (p.skills.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.skills.asMap().entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.shade50,
                        Colors.indigo.shade100.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.indigo.shade200, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.value,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => p.removeSkillAt(e.key),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.indigo.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade100),
            ),
            child: TextField(
              controller: p.skillInputController,
              textInputAction: TextInputAction.done,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type skill and press Enter',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.indigo.shade600,
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (v) => p.onFieldTypedAutoReveal(5, v),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) {
                  p.addSkill(v);
                  p.skillInputController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDobCompact(SignupProvider p) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.orange.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cake_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Date of Birth',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            p.dob == null ? 'Not selected' : DateFormat.yMMMMd().format(p.dob!),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: p.dob == null
                  ? Colors.grey.shade500
                  : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final initial = DateTime(now.year - 22);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(now.year - 13),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: const Color(0xFF6366F1),
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) p.setDob(picked);
              },
              icon: Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.orange.shade700,
              ),
              label: Text(
                'Select Date',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                backgroundColor: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,

              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
    SizedBox(height: 10);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        side: BorderSide(color: Colors.grey.shade400, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        foregroundColor: Colors.grey.shade700,
      ),
    );
  }


  // ========== EDUCATION PANEL ==========
  Widget educationPanel(BuildContext context, SignupProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Educational Background',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your academic qualifications',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 24),

        if (p.educationalProfile.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade50, Colors.indigo.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.indigo.shade100, width: 2),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: Colors.indigo.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No education added yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add at least one education entry to continue',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

        if (p.educationalProfile.isNotEmpty)
          ...p.educationalProfile.asMap().entries.map((entry) {
            final idx = entry.key;
            final data = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.indigo.shade50],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.indigo.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF3949AB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                title: Text(
                  data['institutionName'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['majorSubjects'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['duration'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.grade,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['marksOrCgpa'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showEditEducationDialog(p, idx, data),
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Colors.indigo.shade700,
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => p.removeEducation(idx),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: _buildGradientButton(
            label: 'Add Education',
            icon: Icons.add_rounded,
            onPressed: () => _showAddEducationDialog(p),
          ),
        ),

        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton.icon(
                  onPressed: () {
                    p.goToStep(1);
                    _animateStepChange();
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(
                    'Back',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              flex: 2, // slightly larger than Back but balanced
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildGradientButton(
                  label: 'Review & Submit',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    if (!p.educationSectionIsComplete()) {
                      _showSnackBar(
                        'Please add at least one education entry',
                        isError: true,
                      );
                      return;
                    }
                    p.goToStep(3);
                    _animateStepChange();
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3949AB).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showAddEducationDialog(SignupProvider p) {
    final inst = TextEditingController();
    final dur = TextEditingController();
    final major = TextEditingController();
    final marks = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF3949AB)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Add Education',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _educationFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(
                  controller: inst,
                  label: 'Institution / University',
                  icon: Icons.account_balance,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: dur,
                  label: 'Duration (e.g. 2017-2021)',
                  icon: Icons.calendar_today,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: major,
                  label: 'Major Subjects',
                  icon: Icons.book,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: marks,
                  label: 'Marks / CGPA',
                  icon: Icons.grade,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (inst.text.trim().isEmpty ||
                  dur.text.trim().isEmpty ||
                  major.text.trim().isEmpty ||
                  marks.text.trim().isEmpty) {
                _showSnackBar(
                  'Please fill all education fields',
                  isError: true,
                );
                return;
              }
              p.addEducation(
                institutionName: inst.text,
                duration: dur.text,
                majorSubjects: major.text,
                marksOrCgpa: marks.text,
              );
              Navigator.of(c).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Add',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditEducationDialog(
      SignupProvider p,
      int idx,
      Map<String, dynamic> data,
      ) {
    _editInstitution.text = data['institutionName'] ?? '';
    _editDuration.text = data['duration'] ?? '';
    _editMajor.text = data['majorSubjects'] ?? '';
    _editMarks.text = data['marksOrCgpa'] ?? '';

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF3949AB)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Edit Education',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(
                controller: _editInstitution,
                label: 'Institution',
                icon: Icons.account_balance,
              ),
              const SizedBox(height: 16),
              _buildDialogTextField(
                controller: _editDuration,
                label: 'Duration',
                icon: Icons.calendar_today,
              ),
              const SizedBox(height: 16),
              _buildDialogTextField(
                controller: _editMajor,
                label: 'Major Subjects',
                icon: Icons.book,
              ),
              const SizedBox(height: 16),
              _buildDialogTextField(
                controller: _editMarks,
                label: 'Marks / CGPA',
                icon: Icons.grade,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newEntry = {
                'institutionName': _editInstitution.text.trim(),
                'duration': _editDuration.text.trim(),
                'majorSubjects': _editMajor.text.trim(),
                'marksOrCgpa': _editMarks.text.trim(),
              };
              p.updateEducation(idx, newEntry);
              Navigator.of(c).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3949AB), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // ========== REVIEW PANEL ==========
  Widget reviewPanel(BuildContext context, SignupProvider p) {
    Widget avatarCard() {
      if (p.profilePicBytes != null) {
        return CircleAvatar(
          radius: 70,
          backgroundColor: Colors.grey.shade100,
          backgroundImage: MemoryImage(p.profilePicBytes!),
        );
      }
      if (p.imageDataUrl != null) {
        try {
          final bytes = base64Decode(p.imageDataUrl!.split(',').last);
          return CircleAvatar(
            radius: 70,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      }
      return CircleAvatar(
        radius: 70,
        backgroundColor: Colors.indigo.shade50,
        child: Icon(
          Icons.person_outline_rounded,
          size: 60,
          color: Colors.indigo.shade300,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Submit',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Review your information before submitting',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 24),

        // Profile Overview Card
        RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.indigo.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.indigo.shade100, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar and Name Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.indigo.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: avatarCard(),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF3949AB)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  p.role == 'job_seeker'
                                      ? Icons.person_search_rounded
                                      : Icons.business_center_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  p.role == 'job_seeker'
                                      ? 'Job Seeker'
                                      : 'Recruiter',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.nameController.text.trim(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    p.goToStep(1);
                                    _animateStepChange();
                                  },
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: Colors.indigo.shade600,
                                  ),
                                  tooltip: 'Edit Personal Info',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.summaryController.text.trim(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.email_outlined,
                              p.emailController.text.trim(),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.phone_outlined,
                              p.contactNumberController.text.trim(),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.flag_outlined,
                              p.nationalityController.text.trim(),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.cake_outlined,
                              p.dob == null
                                  ? 'Not set'
                                  : DateFormat.yMMMMd().format(p.dob!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Skills Section
                  _buildReviewSection(
                    title: 'Skills',
                    icon: Icons.lightbulb_outlined,
                    onEdit: () {
                      p.goToStep(1);
                      _animateStepChange();
                    },
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade100,
                                Colors.indigo.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.indigo.shade200),
                          ),
                          child: Text(
                            skill,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Objectives Section
                  _buildReviewSection(
                    title: 'Career Objectives',
                    icon: Icons.flag_circle_rounded,
                    onEdit: () {
                      p.goToStep(1);
                      _animateStepChange();
                    },
                    child: Text(
                      p.objectivesController.text.trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Education Section
                  _buildReviewSection(
                    title: 'Education',
                    icon: Icons.school_outlined,
                    onEdit: () {
                      p.goToStep(2);
                      _animateStepChange();
                    },
                    child: Column(
                      children: p.educationalProfile.map((edu) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.indigo.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF3949AB),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.school,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      edu['institutionName'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                edu['majorSubjects'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    edu['duration'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.grade,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    edu['marksOrCgpa'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  p.goToStep(2);
                  _animateStepChange();
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(
                  'Back',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: Colors.grey.shade300, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF3949AB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3949AB).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: p.isLoading
                        ? null
                        : () async {
                      final ok = await p.createJobSeekerProfile();
                      if (ok) {
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (c) => WillPopScope(
                            onWillPop: () async => false,
                            child: AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF3949AB),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        10,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Finalizing Setup',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Finishing account setup...',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  const SizedBox(height: 24),
                                  const CircularProgressIndicator(
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6366F1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        await Future.delayed(const Duration(seconds: 2));

                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }

                        p.clearAll();

                        _showSnackBar(
                          'Account created & data saved successfully!',
                          isError: false,
                        );
context.go('/dashboard');
                      } else {
                        if (!mounted) return;
                        _showSnackBar(
                          p.generalError ?? 'Failed to sign up',
                          isError: true,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: p.isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Submit & Create Account',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
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
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.indigo.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection({
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: Colors.indigo.shade600),
              tooltip: 'Edit',
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignupProvider(),
      child: const _ProfileBuilderScreenInner(),
    );
  }
}
class _FieldWrapper extends StatelessWidget {
  final int flex;
  final Widget child;

  const _FieldWrapper({required this.flex, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

class _ProfileBuilderScreenInner extends StatelessWidget {
  const _ProfileBuilderScreenInner();

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<SignupProvider>(context);
    final state = context.findAncestorStateOfType<_ProfileBuilderScreenState>()!;

    Widget bodyForStep() {
      switch (p.currentStep) {
        case 0:
          return state.profileChoicePanel(context, p);
        case 1:
          return state.personalPanel(context, p);
        case 2:
          return state.educationPanel(context, p);
        case 3:
          return state.reviewPanel(context, p);
        default:
          return state.profileChoicePanel(context, p);
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
           // const HeaderNav(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(32),
                child: FadeTransition(
                  opacity: state._fadeAnimation,
                  child: SlideTransition(
                    position: state._slideAnimation,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 900),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.work_outline_rounded, color: Colors.white, size: 24),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Maha Services',
                                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.indigo.shade200),
                                  ),
                                  child: Text(
                                    'Step ${p.currentStep + 1} of 4',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
                            bodyForStep(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}