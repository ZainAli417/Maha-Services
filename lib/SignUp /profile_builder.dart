// lib/screens/profile_builder_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:job_portal/SignUp%20/signup_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../Parser_CV/cv_parser-UI.dart';
import '../Parser_CV/cv_parser.dart';
import '../main.dart';

class ProfileBuilderScreen extends StatefulWidget {
  const ProfileBuilderScreen({super.key});

  @override
  State<ProfileBuilderScreen> createState() => _ProfileBuilderScreenState();
}

class _ProfileBuilderScreenState extends State<ProfileBuilderScreen>
    with TickerProviderStateMixin {
  final _personalFormKey = GlobalKey<FormState>();

  late AnimationController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static final String GEMINI_API_KEY = Env.geminiApiKey;
  late final extractor = CvExtractor(geminiApiKey: GEMINI_API_KEY);

  // Professional Data Sets
  // final List<Map<String, dynamic>> _commonMajors = [
  //   {'label': 'Computer Science', 'icon': Icons.computer_rounded},
  //   {'label': 'Software Engineering', 'icon': Icons.code_rounded},
  //   {'label': 'Data Science', 'icon': Icons.analytics_rounded},
  //   {'label': 'Business Admin', 'icon': Icons.business_rounded},
  //   {'label': 'Marketing', 'icon': Icons.trending_up_rounded},
  //   {'label': 'Design', 'icon': Icons.design_services_rounded},
  //   {'label': 'Finance', 'icon': Icons.account_balance_rounded},
  //   {'label': 'Psychology', 'icon': Icons.psychology_rounded},
  // ];

  final List<Map<String, dynamic>> _commonSkills = [
    {'label': 'Flutter', 'icon': Icons.flutter_dash_rounded},
    {'label': 'React', 'icon': Icons.javascript_rounded},
    {'label': 'Python', 'icon': Icons.code_rounded},
    {'label': 'Project Mgmt', 'icon': Icons.account_tree_rounded},
    {'label': 'UI/UX', 'icon': Icons.palette_rounded},
    {'label': 'Data Analysis', 'icon': Icons.bar_chart_rounded},
    {'label': 'AWS', 'icon': Icons.cloud_rounded},
    {'label': 'Leadership', 'icon': Icons.groups_rounded},
  ];

  final List<String> _countries = [
    'Pakistan', 'United States', 'United Kingdom', 'Canada',
    'Australia', 'Germany', 'UAE', 'India', 'Singapore'
  ];

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _animateStepChange() {
    _fadeController.reset();
    _fadeController.forward();
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(24),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  // Navigate to CV Upload Screen
  void _navigateToCvUpload(BuildContext context, SignupProvider p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CvUploadSection(
          extractor: extractor,
          provider: p,
          onSuccess: () => context.go('/login'),
          onManualContinue: () {
            Navigator.of(context).pop();
            p.revealCvUpload(reveal: false);
            p.revealNextPersonalField();
            p.goToStep(1);
            _animateStepChange();
          },
        ),
      ),
    );
  }

  // ================== STEP INDICATOR ==================
  Widget _buildStepper(SignupProvider p) {
    final steps = [
      {'icon': Icons.person_outline, 'label': 'Profile'},
      {'icon': Icons.school_outlined, 'label': 'Education'},
      {'icon': Icons.check_circle_outline, 'label': 'Review'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final lineActive = (index ~/ 2) < (p.currentStep - 1);
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: lineActive ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isActive = stepIndex == (p.currentStep - 1);
          final isCompleted = stepIndex < (p.currentStep - 1);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF6366F1)
                      : isCompleted
                      ? const Color(0xFF6366F1).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive || isCompleted
                        ? const Color(0xFF6366F1)
                        : const Color(0xFFE2E8F0),
                    width: 2,
                  ),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : steps[stepIndex]['icon'] as IconData,
                  color: isActive
                      ? Colors.white
                      : isCompleted
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF94A3B8),
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                steps[stepIndex]['label'] as String,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ================== STEP 0: CHOICE ==================
  Widget _buildMethodSelection(BuildContext context, SignupProvider p) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 24),
            Text(
              "Create Your Profile",
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Choose how you'd like to build your professional profile",
              style: GoogleFonts.inter(
                fontSize: 18,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 60),
            Row(
              children: [
                Expanded(
                  child: _MethodCard(
                    icon: Icons.upload_file_rounded,
                    title: "Upload Resume",
                    description: "AI extracts your information instantly",
                    accentColor: const Color(0xFF6366F1),
                    onTap: () => _navigateToCvUpload(context, p),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _MethodCard(
                    icon: Icons.edit_note_rounded,
                    title: "Manual Entry",
                    description: "Build your profile step by step",
                    accentColor: const Color(0xFF10B981),
                    onTap: () {
                      p.revealCvUpload(reveal: false);
                      p.revealNextPersonalField();
                      p.goToStep(1);
                      _animateStepChange();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================== STEP 1: PERSONAL INFO ==================
  Widget _buildPersonalInfo(BuildContext context, SignupProvider p) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Form(
          key: _personalFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                icon: Icons.person_outline,
                title: "Personal Information",
                subtitle: "Tell us about yourself",
              ),
              const SizedBox(height: 32),

              // Profile Photo & Quick Stats Row
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        _AvatarUploader(
                          imageData: p.profilePicBytes,
                          networkImage: p.imageDataUrl,
                          onTap: () => p.pickProfilePicture(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Profile Photo",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 40),

                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _InputField(
                                  controller: p.nameController,
                                  label: "Full Name",
                                  icon: Icons.badge_outlined,
                                  hint: "John Doe",
                                  onChanged: (v) => p.onFieldTypedAutoReveal(0, v),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _InputField(
                                  controller: p.contactNumberController,
                                  label: "Phone Number",
                                  icon: Icons.phone_outlined,
                                  hint: "+92 300 1234567",
                                  onChanged: (v) => p.onFieldTypedAutoReveal(1, v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _AutoCompleteField(
                                  controller: p.nationalityController,
                                  label: "Nationality",
                                  icon: Icons.public_outlined,
                                  options: _countries,
                                  onSelected: (val) {
                                    p.nationalityController.text = val;
                                    p.onFieldTypedAutoReveal(2, val);
                                  },
                                  onChanged: (v) => p.onFieldTypedAutoReveal(2, v),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _DatePickerField(
                                  label: "Date of Birth",
                                  value: p.dob,
                                  onTap: () async {
                                    final DateTime? d = await showDatePicker(
                                      context: context,
                                      initialDate: p.dob ?? DateTime(2000),
                                      firstDate: DateTime(1960),
                                      lastDate: DateTime.now(),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            // Use ThemeData properties to style the picker globally
                                            colorScheme: const ColorScheme.light(
                                              primary: Color(0xFF6366F1), // Premium Indigo
                                              onPrimary: Colors.white,
                                              onSurface: Color(0xFF1E293B), // Professional Slate
                                            ),
                                            // Corrected: Use DialogThemeData for the theme property
                                            dialogTheme: DialogThemeData(
                                              backgroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                                              ),
                                            ),
                                            textButtonTheme: TextButtonThemeData(
                                              style: TextButton.styleFrom(
                                                textStyle: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (d != null) p.setDob(d);
                                  },
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

              const SizedBox(height: 24),

              // Professional Summary
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined,
                            color: const Color(0xFF6366F1), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Professional Summary",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      controller: p.summaryController,
                      label: "Summary",
                      icon: Icons.summarize_outlined,
                      hint: "Brief overview of your background and expertise...",
                      isMultiLine: true,
                      showLabel: false,
                      onChanged: (v) => p.onFieldTypedAutoReveal(3, v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Skills Section
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_outlined,
                                color: const Color(0xFF6366F1), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Skills & Expertise",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Optional",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add skills to highlight your expertise (or skip this step)",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (p.skills.isNotEmpty) ...[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: p.skills
                            .map((s) => _SkillTag(
                          label: s,
                          onDelete: () => p.removeSkillAt(p.skills.indexOf(s)),
                          isSelected: true,
                        ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            controller: p.skillInputController,
                            label: "Add Skill",
                            icon: Icons.add_rounded,
                            hint: "Type skill and press Enter",
                            showLabel: false,
                            onSubmitted: (v) {
                              if (v.isNotEmpty) {
                                p.addSkill(v.trim());
                                p.skillInputController.clear();
                              }
                            },
                            validator: (_) => null, // Skills are optional
                          ),
                        ),
                        const SizedBox(width: 12),
                        _IconButton(
                          icon: Icons.add,
                          onTap: () {
                            final v = p.skillInputController.text.trim();
                            if (v.isNotEmpty) {
                              p.addSkill(v);
                              p.skillInputController.clear();
                            }
                          },
                        ),
                      ],
                    ),

                    if (p.skills.length < 5) ...[
                      const SizedBox(height: 20),
                      Text(
                        "Suggestions:",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _commonSkills
                            .where((s) => !p.skills.contains(s['label']))
                            .take(6)
                            .map((s) => _SuggestionChip(
                          label: s['label'] as String,
                          icon: s['icon'] as IconData,
                          onTap: () => p.addSkill(s['label'] as String),
                        ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Career Objectives
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flag_outlined, color: const Color(0xFF6366F1), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Career Objectives",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      controller: p.objectivesController,
                      label: "Objectives",
                      icon: Icons.gps_fixed_outlined,
                      hint: "What are your career goals?",
                      isMultiLine: true,
                      showLabel: false,
                      onChanged: (v) => p.onFieldTypedAutoReveal(5, v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              _buildNavigation(
                onBack: () {
                  p.goToStep(0);
                  _animateStepChange();
                },
                onNext: () {
                  if (_personalFormKey.currentState?.validate() ?? false) {
                    p.goToStep(2);
                    _animateStepChange();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================== STEP 2: EDUCATION ==================
  Widget _buildEducation(BuildContext context, SignupProvider p) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              icon: Icons.school_outlined,
              title: "Education History",
              subtitle: "Add your academic qualifications",
            ),
            const SizedBox(height: 32),

            if (p.educationalProfile.isEmpty)
              _EmptyState(
                icon: Icons.school_outlined,
                title: "No education added",
                subtitle: "Add your academic background to strengthen your profile",
                action: _PrimaryButton(
                  icon: Icons.add_rounded,
                  label: "Add Education",
                  onPressed: () => _showEducationModal(context, p),
                ),
              )
            else
              Column(
                children: [
                  ...p.educationalProfile
                      .asMap()
                      .entries
                      .map(
                        (e) => _EducationTimelineItem(
                      index: e.key,
                      data: e.value,
                      isLast: e.key == p.educationalProfile.length - 1,
                      onEdit: () => _showEducationModal(context, p, e.key, e.value),
                      onDelete: () => p.removeEducation(e.key),
                    ),
                  )
                      .toList(),
                  const SizedBox(height: 24),
                  _SecondaryButton(
                    icon: Icons.add_rounded,
                    label: "Add Another Qualification",
                    onPressed: () => _showEducationModal(context, p),
                  ),
                ],
              ),

            const SizedBox(height: 48),
            _buildNavigation(
              onBack: () {
                p.goToStep(1);
                _animateStepChange();
              },
              onNext: () {
                if (p.educationalProfile.isEmpty) {
                  _showNotification("Add at least one education entry", isError: true);
                  return;
                }
                p.goToStep(3);
                _animateStepChange();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================== STEP 3: REVIEW ==================
  Widget _buildReview(BuildContext context, SignupProvider p) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              icon: Icons.preview_outlined,
              title: "Review Profile",
              subtitle: "Verify your information before submitting",
            ),
            const SizedBox(height: 32),

            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E293B).withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                      image: p.profilePicBytes != null
                          ? DecorationImage(
                        image: MemoryImage(p.profilePicBytes!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: p.profilePicBytes == null
                        ? Icon(Icons.person_rounded,
                        size: 40, color: Colors.white.withOpacity(0.5))
                        : null,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nameController.text.isEmpty ? "Your Name" : p.nameController.text,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _QuickInfo(
                                icon: Icons.email_outlined, text: p.emailController.text),
                            const SizedBox(width: 24),
                            _QuickInfo(
                                icon: Icons.phone_outlined,
                                text: p.contactNumberController.text),
                            const SizedBox(width: 24),
                            _QuickInfo(
                                icon: Icons.public_outlined,
                                text: p.nationalityController.text),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _IconButton(
                    icon: Icons.edit_outlined,
                    color: Colors.white,
                    onTap: () => p.goToStep(1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Summary
                      if (p.summaryController.text.isNotEmpty)
                        _ReviewCard(
                          title: "Professional Summary",
                          icon: Icons.description_outlined,
                          onEdit: () => p.goToStep(1),
                          child: Text(
                            p.summaryController.text,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: const Color(0xFF475569),
                              height: 1.6,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Education List
                      _ReviewCard(
                        title: "Education",
                        icon: Icons.school_outlined,
                        onEdit: () => p.goToStep(2),
                        child: Column(
                          children: p.educationalProfile
                              .map(
                                (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.school_rounded,
                                        color: Color(0xFF6366F1), size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e['institutionName'] ?? '',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${e['majorSubjects']} • ${e['duration']}",
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF64748B),
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (e['marksOrCgpa']?.isNotEmpty ?? false)
                                          Text(
                                            "Grade: ${e['marksOrCgpa']}",
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF94A3B8),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      // Skills Cloud
                      _ReviewCard(
                        title: "Skills",
                        icon: Icons.auto_awesome_outlined,
                        onEdit: () => p.goToStep(1),
                        child: p.skills.isEmpty
                            ? Text(
                          "No skills added",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontStyle: FontStyle.italic,
                          ),
                        )
                            : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: p.skills
                              .map((s) => _SkillTag(
                            label: s,
                            isSelected: true,
                            compact: true,
                          ))
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Career Objectives
                      if (p.objectivesController.text.isNotEmpty)
                        _ReviewCard(
                          title: "Objectives",
                          icon: Icons.flag_outlined,
                          onEdit: () => p.goToStep(1),
                          child: Text(
                            p.objectivesController.text,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF475569),
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),
            _buildNavigation(
              onBack: () {
                p.goToStep(2);
                _animateStepChange();
              },
              onNext: p.isLoading
                  ? () {}
                  : () async {
                final success = await p.createJobSeekerProfile();
                if (success) {
                  _showSuccessDialog();
                } else {
                  _showNotification(
                      p.generalError ?? "Error creating profile",
                      isError: true);
                }
              },
              nextLabel: p.isLoading ? "Creating..." : "Submit Profile",
              isFinal: true,
            ),
          ],
        ),
      ),
    );
  }

  // ================== MODALS ==================
  void _showEducationModal(BuildContext context, SignupProvider p,
      [int? index, Map<String, dynamic>? data]) {
    final isEdit = index != null;
    final instController = TextEditingController(text: data?['institutionName']);
    final majorController = TextEditingController(text: data?['majorSubjects']);
    final marksController = TextEditingController(text: data?['marksOrCgpa']);

    String startYear = "2018";
    String endYear = "2022";
    if (isEdit && data != null && data['duration'] != null && data['duration'].contains('-')) {
      final parts = data['duration'].split('-');
      if (parts.isNotEmpty) startYear = parts[0].trim();
      if (parts.length > 1) endYear = parts[1].trim();
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school_rounded,
                          color: Color(0xFF6366F1), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isEdit ? "Edit Education" : "Add Education",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InputField(
                          controller: instController,
                          label: "Institution Name",
                          icon: Icons.account_balance_outlined,
                          hint: "e.g., Stanford University",
                        ),
                        const SizedBox(height: 20),
                        _InputField(
                          controller: majorController,
                          label: "Degree/Major",
                          icon: Icons.book_outlined,
                          hint: "e.g., BS/MS Computer Science",
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _YearDropdown(
                                label: "Start Year",
                                value: startYear,
                                onChanged: (v) => setState(() => startYear = v!),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _YearDropdown(
                                label: "End Year",
                                value: endYear,
                                onChanged: (v) => setState(() => endYear = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "CGPA / Grade",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: marksController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            DecimalTextInputFormatter(decimalRange: 2),
                          ],
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.score_outlined,
                                color: const Color(0xFF94A3B8), size: 20),
                            hintText: 'e.g., 3.5 or 85%',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFFCBD5E1),
                              fontSize: 15,
                            ),
                            filled: false,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: Color(0xFF6366F1), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFDC2626)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PrimaryButton(
                      icon: Icons.check_rounded,
                      label: "Save Education",
                      onPressed: () {
                        if (instController.text.isEmpty) {
                          _showNotification("Institution name is required", isError: true);
                          return;
                        }
                        final entry = {
                          'institutionName': instController.text,
                          'duration': "$startYear - $endYear",
                          'majorSubjects': majorController.text,
                          'marksOrCgpa': marksController.text
                        };
                        if (isEdit) {
                          p.updateEducation(index!, entry);
                        } else {
                          p.addEducation(
                            institutionName: entry['institutionName']!,
                            duration: entry['duration']!,
                            majorSubjects: entry['majorSubjects']!,
                            marksOrCgpa: entry['marksOrCgpa']!,
                          );
                        }
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Profile Created!",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Redirecting to your dashboard...",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      context.go('/dashboard');
    });
  }

  // ================== HELPER WIDGETS ==================
  Widget _buildSectionTitle(
      {required IconData icon, required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigation({
    required VoidCallback onBack,
    required VoidCallback onNext,
    String nextLabel = "Continue",
    bool isFinal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(
            "Back",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        _PrimaryButton(
          icon: isFinal ? Icons.check_rounded : Icons.arrow_forward_rounded,
          label: nextLabel,
          onPressed: onNext,
          isDestructive: isFinal,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SignupProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildTopBar(),
          // Content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Builder(
                  builder: (ctx) {
                    switch (provider.currentStep) {
                      case 0:
                        return _buildMethodSelection(ctx, provider);
                      case 1:
                        return _buildPersonalInfo(ctx, provider);
                      case 2:
                        return _buildEducation(ctx, provider);
                      case 3:
                        return _buildReview(ctx, provider);
                      default:
                        return const SizedBox();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
Widget _buildTopBar() {
  return RepaintBoundary(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 65, vertical: 10),
      decoration: BoxDecoration(
        color:  Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_buildEnhancedLogo()],
      ),
    ),
  );
}

Widget _buildEnhancedLogo() {
  return Row(
    children: [
      Image.asset(
        'images/logo.png',
        width: 100,
        height: 100,
        fit: BoxFit.fill,
        cacheWidth: 200, // Web optimization
        cacheHeight: 200,
      ),
      const SizedBox(width: 14),
    ],
  );
}


// ================== NEW CV UPLOAD SCREEN ==================
// class CvUploadScreen extends StatelessWidget {
//   final CvExtractor extractor;
//   final SignupProvider provider;
//   final VoidCallback onSuccess;
//   final VoidCallback onManualContinue;
//
//   const CvUploadScreen({
//     super.key,
//     required this.extractor,
//     required this.provider,
//     required this.onSuccess,
//     required this.onManualContinue,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Clean, professional background slate
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         toolbarHeight: 80, // Increased height for a more premium feel
//         leadingWidth: 70,
//         leading: Padding(
//           padding: const EdgeInsets.only(left: 16.0),
//           child: IconButton(
//             icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF64748B)),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ),
//         title: Row(
//           children: [
//             // Your logo integrated on the left side of the title area
//             Image.asset(
//               'images/logo.png',
//               width: 100,
//               height: 100,
//               fit: BoxFit.contain,
//               errorBuilder: (context, error, stackTrace) => const SizedBox(width: 40),
//             ),
//             const Spacer(),
//             Text(
//               "Upload Resume",
//               style: GoogleFonts.plusJakartaSans( // More modern "International" feel than Inter
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//                 color: const Color(0xFF0F172A),
//                 letterSpacing: -0.5,
//               ),
//             ),
//             const Spacer(flex: 2), // Keeps the text visually balanced
//           ],
//         ),
//
//       ),
//       body: CvUploadSection(
//         extractor: extractor,
//         provider: provider,
//         onSuccess: onSuccess,
//         onManualContinue: onManualContinue,
//       ),
//     );
//   }
// }// ================== UI COMPONENTS ==================

class _MethodCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_MethodCard> createState() => _MethodCardState();
}

class _MethodCardState extends State<_MethodCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? widget.accentColor.withOpacity(0.5)
                  : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered
                    ? widget.accentColor.withOpacity(0.1)
                    : const Color(0xFF64748B).withOpacity(0.03),
                blurRadius: isHovered ? 12 : 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: widget.accentColor,
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isHovered ? 1.0 : 0.0,
                    child: Transform.translate(
                      offset: Offset(isHovered ? 0 : -5, 0),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.4,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool isMultiLine;
  final bool showLabel;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.isMultiLine = false,
    this.showLabel = true,
    this.onChanged,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: isMultiLine ? 4 : 1,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator ?? (v) => v!.isEmpty ? "Required" : null,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFFCBD5E1),
              fontSize: 15,
            ),
            filled: false,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _AutoCompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final List<String> options;
  final Function(String) onSelected;
  final Function(String) onChanged;

  const _AutoCompleteField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.options,
    required this.onSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (v) {
            if (v.text.isEmpty) return const Iterable<String>.empty();
            return options.where((c) => c.toLowerCase().contains(v.text.toLowerCase()));
          },
          onSelected: onSelected,
          fieldViewBuilder: (ctx, ctrl, focus, onSub) {
            if (ctrl.text != controller.text) {
              ctrl.text = controller.text;
            }
            return TextFormField(
              controller: ctrl,
              focusNode: focus,
              onChanged: onChanged,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
                filled: false,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DatePickerField extends StatefulWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569), // Slate-600 for labels
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isHovered ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isHovered ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: isHovered
                    ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined, // More modern icon
                    color: widget.value == null ? const Color(0xFF94A3B8) : const Color(0xFF6366F1),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.value == null ? "Select date" : DateFormat('MMMM d, y').format(widget.value!),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: widget.value == null ? FontWeight.w400 : FontWeight.w500,
                      color: widget.value == null ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
class _AvatarUploader extends StatefulWidget {
  final Uint8List? imageData;
  final String? networkImage;
  final VoidCallback onTap;

  const _AvatarUploader({
    this.imageData,
    this.networkImage,
    required this.onTap,
  });

  @override
  State<_AvatarUploader> createState() => _AvatarUploaderState();
}

class _AvatarUploaderState extends State<_AvatarUploader> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageData != null || widget.networkImage != null;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            // Outer Ring
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHovered ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF1F5F9),
                  image: widget.imageData != null
                      ? DecorationImage(image: MemoryImage(widget.imageData!), fit: BoxFit.cover)
                      : widget.networkImage != null
                      ? DecorationImage(
                    image: MemoryImage(base64Decode(widget.networkImage!.split(',').last)),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: !hasImage
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_1_outlined,
                        color: const Color(0xFF94A3B8), size: 30),
                    const SizedBox(height: 4),
                    Text(
                      "Add Photo",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                )
                    : isHovered
                    ? Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0F172A).withOpacity(0.4),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 24),
                )
                    : null,
              ),
            ),

            // Floating Edit Badge
            if (hasImage)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
class _SkillTag extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool compact;

  const _SkillTag({
    required this.label,
    this.onDelete,
    this.isSelected = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF475569),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close_rounded, size: 16, color: const Color(0xFF6366F1)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.add, size: 16, color: const Color(0xFF6366F1)),
          ],
        ),
      ),
    );
  }
}

class _EducationTimelineItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EducationTimelineItem({
    required this.index,
    required this.data,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6366F1), width: 2),
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF64748B).withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['institutionName'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['majorSubjects'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: const Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 14, color: const Color(0xFF94A3B8)),
                                const SizedBox(width: 6),
                                Text(
                                  data['duration'] ?? '',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                    fontSize: 14,
                                  ),
                                ),
                                if (data['marksOrCgpa']?.isNotEmpty ?? false) ...[
                                  const SizedBox(width: 16),
                                  Icon(Icons.grade_outlined,
                                      size: 14, color: const Color(0xFF94A3B8)),
                                  const SizedBox(width: 6),
                                  Text(
                                    data['marksOrCgpa'],
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF64748B),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _IconButton(
                            icon: Icons.edit_outlined,
                            onTap: onEdit,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          _IconButton(
                            icon: Icons.delete_outline,
                            onTap: onDelete,
                            color: const Color(0xFFDC2626),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onEdit;

  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF6366F1), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: const Color(0xFF6366F1)),
                      const SizedBox(width: 4),
                      Text(
                        "Edit",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }
}

class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _QuickInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(64),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 64, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          action,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color =
    widget.isDestructive ? const Color(0xFF059669) : const Color(0xFF6366F1);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isHovered
                ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Icon(widget.icon, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF6366F1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF6366F1)),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _IconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _IconButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHovered ? const Color(0xFFF1F5F9) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            color: widget.color ?? const Color(0xFF64748B),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _YearDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Function(String?) onChanged;

  const _YearDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final years = List.generate(40, (index) => (2035 - index).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: years.contains(value) ? value : years[0],
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF0F172A),
              ),
              items: years
                  .map((y) => DropdownMenuItem(
                value: y,
                child: Text(y),
              ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;
  DecimalTextInputFormatter({this.decimalRange = 2}) : assert(decimalRange >= 0);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (text == '') return newValue;

    if (RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      if (text.contains('.')) {
        final parts = text.split('.');
        if (parts.length > 2) return oldValue;
        if (decimalRange >= 0 && parts[1].length > decimalRange) return oldValue;
      }
      return newValue;
    }
    return oldValue;
  }
}