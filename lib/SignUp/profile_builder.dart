import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:job_portal/SignUp/signup_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../Parser_CV/cv_parser-UI.dart';
import '../Parser_CV/cv_parser.dart';

// ─── Breakpoints ────────────────────────────────────────────────────────────
class _BP {
  static bool isMobile(double w) => w < 600;
  static bool isTablet(double w) => w >= 600 && w < 960;
  static bool isDesktop(double w) => w >= 960;
  static double hPad(double w) => isMobile(w)
      ? 16
      : isTablet(w)
      ? 24
      : 48;
  static double vPad(double w) => isMobile(w)
      ? 12
      : isTablet(w)
      ? 20
      : 28;
  static double cardPad(double w) => isMobile(w)
      ? 14
      : isTablet(w)
      ? 18
      : 24;
  static double maxContent(double w) => isDesktop(w) ? 960 : double.infinity;
}

// ─── Design tokens ─────────────────────────────────────────────────────────
class _T {
  static const primary = Color(0xFF14507F);
  static const green = Color(0xFF059669);
  static const textPri = Color(0xFF0F172A);
  static const textSec = Color(0xFF64748B);
  static const textTert = Color(0xFF94A3B8);
  static const bg = Color(0xFFF8FAFC);
  static const white = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const indigo10 = Color(0xFFE8F1F8);
  static const red = Color(0xFFDC2626);

  static TextStyle label({
    double fs = 12,
    Color? c,
    FontWeight fw = FontWeight.w500,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: fs,
    fontWeight: fw,
    color: c ?? textSec,
  );

  static TextStyle head({double fs = 16, Color? c}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fs,
        fontWeight: FontWeight.w800,
        color: c ?? textPri,
      );

  static TextStyle body({double fs = 14, Color? c}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: fs,
        color: c ?? textPri,
        height: 1.55,
      );
}

// ─── Layout InheritedWidget ─────────────────────────────────────────────────
class _LD extends InheritedWidget {
  final double screenWidth;
  const _LD({required this.screenWidth, required super.child});

  static double width(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<_LD>()!.screenWidth;
  static bool mobile(BuildContext ctx) =>
      _BP.isMobile(ctx.dependOnInheritedWidgetOfExactType<_LD>()!.screenWidth);
  static bool tablet(BuildContext ctx) =>
      _BP.isTablet(ctx.dependOnInheritedWidgetOfExactType<_LD>()!.screenWidth);
  static bool desktop(BuildContext ctx) =>
      _BP.isDesktop(ctx.dependOnInheritedWidgetOfExactType<_LD>()!.screenWidth);

  @override
  bool updateShouldNotify(_LD old) => old.screenWidth != screenWidth;
}

// ─── Input decoration factory ───────────────────────────────────────────────
InputDecoration _inputDec({
  required String hint,
  required IconData icon,
  String? label,
}) => InputDecoration(
  labelText: label,
  labelStyle: _T.label(fs: 12, fw: FontWeight.w600, c: _T.primary),
  hintText: hint,
  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: _T.textTert),
  prefixIcon: Icon(icon, color: _T.textTert, size: 18),
  filled: true,
  fillColor: _T.bg,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _T.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _T.border),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _T.primary, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: _T.red),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  isDense: true,
);

// ═════════════════════════════════════════════════════════════════════════════
// ROOT
// ═════════════════════════════════════════════════════════════════════════════
class ProfileBuilderScreen extends StatefulWidget {
  const ProfileBuilderScreen({super.key});
  @override
  State<ProfileBuilderScreen> createState() => _ProfileBuilderScreenState();
}

class _ProfileBuilderScreenState extends State<ProfileBuilderScreen>
    with TickerProviderStateMixin {
  final _personalFormKey = GlobalKey<FormState>();
  late final CvExtractor extractor = CvExtractor();

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOut,
  );

  static const _countries = [
    'Pakistan',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'UAE',
    'India',
    'Singapore',
  ];

  static const _commonSkills = [
    {'label': 'Flutter', 'icon': Icons.flutter_dash_rounded},
    {'label': 'React', 'icon': Icons.javascript_rounded},
    {'label': 'Python', 'icon': Icons.code_rounded},
    {'label': 'Project Mgmt', 'icon': Icons.account_tree_rounded},
    {'label': 'UI/UX', 'icon': Icons.palette_rounded},
    {'label': 'Data Analysis', 'icon': Icons.bar_chart_rounded},
    {'label': 'AWS', 'icon': Icons.cloud_rounded},
    {'label': 'Leadership', 'icon': Icons.groups_rounded},
  ];

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _stepChange() {
    _fadeCtrl.reset();
    _fadeCtrl.forward();
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: _T.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg, style: _T.label(fs: 13, c: _T.white)),
              ),
            ],
          ),
          backgroundColor: error ? _T.red : _T.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

  void _goToCvUpload(BuildContext ctx, SignupProvider p) =>
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => CvUploadSection(
            extractor: extractor,
            provider: p,
            onSuccess: () => ctx.go('/login'),
            onManualContinue: () {
              Navigator.of(ctx).pop();
              p.revealCvUpload(reveal: false);
              p.revealNextPersonalField();
              p.goToStep(1);
              _stepChange();
            },
          ),
        ),
      );

  // ─── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SignupProvider>();

    return LayoutBuilder(
      builder: (ctx, bc) {
        final w = bc.maxWidth;
        return _LD(
          screenWidth: w,
          child: SafeArea(
            // ← KEY: SafeArea wraps everything for Android nav/status bars
            top: true,
            bottom: true,
            child: Scaffold(
              backgroundColor: _T.bg,
              body: Column(
                children: [
                  // Top bar
                  RepaintBoundary(child: _TopBar()),
                  // Stepper (hidden on step 0)
                  if (provider.currentStep > 0)
                    RepaintBoundary(
                      child: _Stepper(step: provider.currentStep),
                    ),
                  // Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: _BP.hPad(w),
                          vertical: _BP.vPad(w),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: _BP.maxContent(w),
                            ),
                            child: _stepContent(ctx, provider, w),
                          ),
                        ),
                      ),
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

  Widget _stepContent(BuildContext ctx, SignupProvider p, double w) {
    switch (p.currentStep) {
      case 0:
        return _StepMethod(
          onUpload: () => _goToCvUpload(ctx, p),
          onManual: () {
            p.revealCvUpload(reveal: false);
            p.revealNextPersonalField();
            p.goToStep(1);
            _stepChange();
          },
        );
      case 1:
        return _StepPersonal(
          formKey: _personalFormKey,
          countries: _countries,
          commonSkills: _commonSkills,
          onBack: () {
            p.goToStep(0);
            _stepChange();
          },
          onNext: () {
            if (_personalFormKey.currentState?.validate() ?? false) {
              p.goToStep(2);
              _stepChange();
            }
          },
        );
      case 2:
        return _StepEducation(
          onBack: () {
            p.goToStep(1);
            _stepChange();
          },
          onNext: () {
            if (p.educationalProfile.isEmpty) {
              _snack('Add at least one education entry', error: true);
              return;
            }
            p.goToStep(3);
            _stepChange();
          },
          onSnack: _snack,
        );
      case 3:
        return _StepReview(
          onBack: () {
            p.goToStep(2);
            _stepChange();
          },
          onSubmit: () async {
            final ok = await p.createJobSeekerProfile();
            if (ok) {
              _showSuccessDialog();
            } else {
              _snack(p.generalError ?? 'Error creating profile', error: true);
            }
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showSuccessDialog() =>
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: _T.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 44,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Profile Created!', style: _T.head(fs: 22)),
                const SizedBox(height: 6),
                Text('Redirecting to dashboard…', style: _T.label(fs: 13)),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  color: _T.primary,
                  strokeWidth: 2.5,
                ),
              ],
            ),
          ),
        ),
      )..then(
        (_) => Future.delayed(
          const Duration(seconds: 2),
          () => context.go('/dashboard'),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═════════════════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final w = _LD.width(context);
    final isMob = _BP.isMobile(w);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _BP.hPad(w),
        vertical: isMob ? 6 : 10,
      ),
      decoration: const BoxDecoration(color: _T.bg),
      child: Row(
        children: [
          Image.asset(
            'images/logo_new.jpeg',
            width: isMob ? 100 : 72,
            height: isMob ? 100 : 72,
            fit: BoxFit.contain,
            cacheWidth: 144,
            cacheHeight: 144,
          ),
        ],
      ),
    );
  }
}

// ─── Step indicator ─────────────────────────────────────────────────────────
class _Stepper extends StatelessWidget {
  final int step;
  const _Stepper({required this.step});

  static const _steps = [
    {'icon': Icons.person_outline, 'label': 'Profile'},
    {'icon': Icons.school_outlined, 'label': 'Education'},
    {'icon': Icons.check_circle_outline, 'label': 'Review'},
  ];

  @override
  Widget build(BuildContext context) {
    final w = _LD.width(context);
    final isMob = _BP.isMobile(w);
    final size = isMob ? 32.0 : 40.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _BP.hPad(w),
        vertical: isMob ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: _T.white,
        border: Border(bottom: BorderSide(color: _T.border)),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final active = (i ~/ 2) < (step - 1);
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: active ? _T.primary : _T.border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }
          final idx = i ~/ 2;
          final isActive = idx == step - 1;
          final isDone = idx < step - 1;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: isActive
                      ? _T.primary
                      : isDone
                      ? _T.indigo10
                      : _T.white,
                  borderRadius: BorderRadius.circular(isMob ? 8 : 10),
                  border: Border.all(
                    color: isActive || isDone ? _T.primary : _T.border,
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: _T.primary.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isDone
                      ? Icons.check_rounded
                      : _steps[idx]['icon'] as IconData,
                  color: isActive
                      ? _T.white
                      : isDone
                      ? _T.primary
                      : _T.textTert,
                  size: isMob ? 15 : 19,
                ),
              ),
              if (!isMob) ...[
                const SizedBox(height: 5),
                Text(
                  _steps[idx]['label'] as String,
                  style: _T.label(
                    fs: 11,
                    c: isActive ? _T.textPri : _T.textTert,
                    fw: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STEP 0 — METHOD SELECTION
// ═════════════════════════════════════════════════════════════════════════════
class _StepMethod extends StatelessWidget {
  final VoidCallback onUpload, onManual;
  const _StepMethod({required this.onUpload, required this.onManual});

  @override
  Widget build(BuildContext context) {
    final w = _LD.width(context);
    final isMob = _BP.isMobile(w);
    final vGap = isMob ? 20.0 : 40.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: vGap),
        Container(
          padding: EdgeInsets.all(isMob ? 12 : 16),
          decoration: BoxDecoration(color: _T.indigo10, shape: BoxShape.circle),
          child: Icon(
            Icons.account_circle_outlined,
            size: isMob ? 36 : 48,
            color: _T.primary,
          ),
        ),
        SizedBox(height: isMob ? 12 : 18),
        Text(
          'Create Your Profile',
          style: _T.head(fs: isMob ? 20 : 28),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 6),
        Text(
          'Choose how to build your profile',
          style: _T.label(fs: isMob ? 12 : 14),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isMob ? 20 : 40),
        isMob
            ? Column(
                children: [
                  _MethodCard(
                    icon: Icons.upload_file_rounded,
                    title: 'Upload Resume',
                    desc: 'AI extracts your info instantly',
                    color: _T.primary,
                    onTap: onUpload,
                  ),
                  const SizedBox(height: 12),
                  _MethodCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Manual Entry',
                    desc: 'Build your profile step by step',
                    color: _T.green,
                    onTap: onManual,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _MethodCard(
                      icon: Icons.upload_file_rounded,
                      title: 'Upload Resume',
                      desc: 'AI extracts your info instantly',
                      color: _T.primary,
                      onTap: onUpload,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _MethodCard(
                      icon: Icons.edit_note_rounded,
                      title: 'Manual Entry',
                      desc: 'Build your profile step by step',
                      color: _T.green,
                      onTap: onManual,
                    ),
                  ),
                ],
              ),
        SizedBox(height: vGap),
      ],
    );
  }
}

class _MethodCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Color color;
  final VoidCallback onTap;
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.onTap,
  });
  @override
  State<_MethodCard> createState() => _MethodCardState();
}

class _MethodCardState extends State<_MethodCard> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final w = _LD.width(context);
    final isMob = _BP.isMobile(w);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(isMob ? 14 : 20),
          decoration: BoxDecoration(
            color: _T.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hov ? widget.color.withValues(alpha: 0.45) : _T.border,
            ),
            boxShadow: _hov
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.1),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: isMob
              // Compact horizontal on mobile
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, size: 20, color: widget.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: _T.head(fs: 14)),
                          const SizedBox(height: 2),
                          Text(widget.desc, style: _T.label(fs: 11)),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: widget.color,
                    ),
                  ],
                )
              // Vertical card on tablet/desktop
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 22,
                            color: widget.color,
                          ),
                        ),
                        if (_hov)
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: widget.color,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(widget.title, style: _T.head(fs: 15)),
                    const SizedBox(height: 4),
                    Text(widget.desc, style: _T.label(fs: 13)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STEP 1 — PERSONAL INFO
// ═════════════════════════════════════════════════════════════════════════════
class _StepPersonal extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<String> countries;
  final List<Map<String, dynamic>> commonSkills;
  final VoidCallback onBack, onNext;

  const _StepPersonal({
    required this.formKey,
    required this.countries,
    required this.commonSkills,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SignupProvider>();
    final w = _LD.width(context);
    final isMob = _BP.isMobile(w);
    final cp = _BP.cardPad(w);
    final gap = isMob ? 12.0 : 16.0;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.person_outline,
            title: 'Personal Info',
            subtitle: 'Tell us about yourself',
          ),
          SizedBox(height: isMob ? 14 : 24),

          // ── Photo + basic fields
          _Card(
            padding: cp,
            child: isMob
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _AvatarUploader(
                            imageData: p.profilePicBytes,
                            networkImage: p.imageDataUrl,
                            onTap: p.pickProfilePicture,
                            size: 72,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile Photo',
                                  style: _T.label(fs: 11, fw: FontWeight.w600),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Tap to upload',
                                  style: _T.label(fs: 10, c: _T.textTert),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: gap),
                      _InputField(
                        ctrl: p.nameController,
                        hint: 'John Doe',
                        icon: Icons.badge_outlined,
                        label: 'Full Name',
                        onChanged: (v) => p.onFieldTypedAutoReveal(0, v),
                      ),
                      SizedBox(height: gap),
                      _InputField(
                        ctrl: p.contactNumberController,
                        hint: '+92 300 1234567',
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        onChanged: (v) => p.onFieldTypedAutoReveal(1, v),
                      ),
                      SizedBox(height: gap),
                      _AutoField(
                        ctrl: p.nationalityController,
                        label: 'Nationality',
                        icon: Icons.public_outlined,
                        options: countries,
                        onSelected: (v) {
                          p.nationalityController.text = v;
                          p.onFieldTypedAutoReveal(2, v);
                        },
                        onChanged: (v) => p.onFieldTypedAutoReveal(2, v),
                      ),
                      SizedBox(height: gap),
                      _DateField(
                        label: 'Date of Birth',
                        value: p.dob,
                        onTap: () => _pickDate(context, p),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          _AvatarUploader(
                            imageData: p.profilePicBytes,
                            networkImage: p.imageDataUrl,
                            onTap: p.pickProfilePicture,
                          ),
                          const SizedBox(height: 6),
                          Text('Profile Photo', style: _T.label(fs: 11)),
                        ],
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _InputField(
                                    ctrl: p.nameController,
                                    hint: 'John Doe',
                                    icon: Icons.badge_outlined,
                                    label: 'Full Name',
                                    onChanged: (v) =>
                                        p.onFieldTypedAutoReveal(0, v),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _InputField(
                                    ctrl: p.contactNumberController,
                                    hint: '+92 300 1234567',
                                    icon: Icons.phone_outlined,
                                    label: 'Phone',
                                    onChanged: (v) =>
                                        p.onFieldTypedAutoReveal(1, v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _AutoField(
                                    ctrl: p.nationalityController,
                                    label: 'Nationality',
                                    icon: Icons.public_outlined,
                                    options: countries,
                                    onSelected: (v) {
                                      p.nationalityController.text = v;
                                      p.onFieldTypedAutoReveal(2, v);
                                    },
                                    onChanged: (v) =>
                                        p.onFieldTypedAutoReveal(2, v),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _DateField(
                                    label: 'Date of Birth',
                                    value: p.dob,
                                    onTap: () => _pickDate(context, p),
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

          SizedBox(height: gap),

          // ── Summary
          _Card(
            padding: cp,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(
                  icon: Icons.description_outlined,
                  title: 'Professional Summary',
                ),
                SizedBox(height: isMob ? 10 : 14),
                _InputField(
                  ctrl: p.summaryController,
                  label: '',
                  hint: 'Brief overview of your background…',
                  icon: Icons.summarize_outlined,
                  multiLine: true,
                  onChanged: (v) => p.onFieldTypedAutoReveal(3, v),
                ),
              ],
            ),
          ),

          SizedBox(height: gap),

          // ── Skills
          _Card(
            padding: cp,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CardHeader(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Skills',
                    ),
                    _Badge('Optional'),
                  ],
                ),
                SizedBox(height: isMob ? 8 : 12),
                if (p.skills.isNotEmpty) ...[
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final s in p.skills)
                        _SkillTag(
                          label: s,
                          onDelete: () => p.removeSkillAt(p.skills.indexOf(s)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _InputField(
                        ctrl: p.skillInputController,
                        label: '',
                        hint: 'Type skill & press Enter',
                        icon: Icons.add_rounded,
                        showLabel: false,
                        validator: (_) => null,
                        onSubmitted: (v) {
                          if (v.isNotEmpty) {
                            p.addSkill(v.trim());
                            p.skillInputController.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SmallIconBtn(
                      icon: Icons.add_rounded,
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
                  const SizedBox(height: 12),
                  Text('Suggestions', style: _T.label(fs: 10, c: _T.textTert)),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s
                          in commonSkills
                              .where((s) => !p.skills.contains(s['label']))
                              .take(6))
                        _SuggestionChip(
                          label: s['label'] as String,
                          icon: s['icon'] as IconData,
                          onTap: () => p.addSkill(s['label'] as String),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: gap),

          // ── Objectives
          _Card(
            padding: cp,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardHeader(
                  icon: Icons.flag_outlined,
                  title: 'Career Objectives',
                ),
                SizedBox(height: isMob ? 10 : 14),
                _InputField(
                  ctrl: p.objectivesController,
                  label: '',
                  hint: 'What are your career goals?',
                  icon: Icons.gps_fixed_outlined,
                  multiLine: true,
                  onChanged: (v) => p.onFieldTypedAutoReveal(5, v),
                ),
              ],
            ),
          ),

          SizedBox(height: isMob ? 20 : 32),
          _NavRow(onBack: onBack, onNext: onNext),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext ctx, SignupProvider p) async {
    final d = await showDatePicker(
      context: ctx,
      initialDate: p.dob ?? DateTime(2000),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _T.primary,
            onPrimary: _T.white,
            onSurface: _T.textPri,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: _T.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) p.setDob(d);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STEP 2 — EDUCATION
// ═════════════════════════════════════════════════════════════════════════════
class _StepEducation extends StatelessWidget {
  final VoidCallback onBack, onNext;
  final void Function(String, {bool error}) onSnack;

  const _StepEducation({
    required this.onBack,
    required this.onNext,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SignupProvider>();
    final w = _LD.width(context);
    final isMob = _BP.isMobile(w);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.school_outlined,
          title: 'Education',
          subtitle: 'Add your qualifications',
        ),
        SizedBox(height: isMob ? 14 : 24),

        if (p.educationalProfile.isEmpty)
          _EmptyCard(
            icon: Icons.school_outlined,
            title: 'No education added',
            subtitle: 'Add your academic background',
            action: _PrimaryBtn(
              icon: Icons.add_rounded,
              label: 'Add Education',
              onTap: () => _showEduModal(context, p),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < p.educationalProfile.length; i++)
                _EduItem(
                  index: i,
                  data: p.educationalProfile[i],
                  isLast: i == p.educationalProfile.length - 1,
                  onEdit: () =>
                      _showEduModal(context, p, i, p.educationalProfile[i]),
                  onDelete: () => p.removeEducation(i),
                ),
              const SizedBox(height: 14),
              _SecondaryBtn(
                icon: Icons.add_rounded,
                label: 'Add Another',
                onTap: () => _showEduModal(context, p),
              ),
            ],
          ),

        SizedBox(height: isMob ? 20 : 32),
        _NavRow(onBack: onBack, onNext: onNext),
      ],
    );
  }

  void _showEduModal(
    BuildContext ctx,
    SignupProvider p, [
    int? idx,
    Map<String, dynamic>? data,
  ]) {
    final instCtrl = TextEditingController(text: data?['institutionName']);
    final majCtrl = TextEditingController(text: data?['majorSubjects']);
    final marksCtrl = TextEditingController(text: data?['marksOrCgpa']);
    String sy = '2018', ey = '2022';
    if (data?['duration'] != null &&
        (data!['duration'] as String).contains('-')) {
      final parts = (data['duration'] as String).split('-');
      sy = parts[0].trim();
      ey = parts.length > 1 ? parts[1].trim() : ey;
    }

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, ss) => Dialog(
          backgroundColor: _T.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 28,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 640),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _T.indigo10,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: _T.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        idx != null ? 'Edit Education' : 'Add Education',
                        style: _T.head(fs: 17),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: _T.textSec,
                        ),
                        onPressed: () => Navigator.pop(ctx2),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _InputField(
                            ctrl: instCtrl,
                            label: 'Institution',
                            hint: 'e.g. Stanford University',
                            icon: Icons.account_balance_outlined,
                          ),
                          const SizedBox(height: 12),
                          _InputField(
                            ctrl: majCtrl,
                            label: 'Degree / Major',
                            hint: 'e.g. BS Computer Science',
                            icon: Icons.book_outlined,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _YearDrop(
                                  label: 'Start',
                                  value: sy,
                                  onChange: (v) => ss(() => sy = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _YearDrop(
                                  label: 'End',
                                  value: ey,
                                  onChange: (v) => ss(() => ey = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: marksCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [DecimalTextInputFormatter()],
                            style: _T.body(fs: 14),
                            decoration: _inputDec(
                              hint: 'e.g. 3.5 or 85%',
                              icon: Icons.score_outlined,
                              label: 'CGPA / Grade',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2),
                        child: Text('Cancel', style: _T.label(fs: 13)),
                      ),
                      const SizedBox(width: 10),
                      _PrimaryBtn(
                        icon: Icons.check_rounded,
                        label: 'Save',
                        onTap: () {
                          if (instCtrl.text.isEmpty) {
                            onSnack('Institution name required', error: true);
                            return;
                          }
                          final entry = {
                            'institutionName': instCtrl.text,
                            'duration': '$sy - $ey',
                            'majorSubjects': majCtrl.text,
                            'marksOrCgpa': marksCtrl.text,
                          };
                          if (idx != null) {
                            p.updateEducation(idx, entry);
                          } else {
                            p.addEducation(
                              institutionName: entry['institutionName']!,
                              duration: entry['duration']!,
                              majorSubjects: entry['majorSubjects']!,
                              marksOrCgpa: entry['marksOrCgpa']!,
                            );
                          }
                          Navigator.pop(ctx2);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STEP 3 — REVIEW
// ═════════════════════════════════════════════════════════════════════════════
class _StepReview extends StatelessWidget {
  final VoidCallback onBack;
  final Future<void> Function() onSubmit;
  const _StepReview({required this.onBack, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SignupProvider>();
    final w = _LD.width(context);
    final isMob = _BP.isMobile(w);
    final cp = _BP.cardPad(w);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.preview_outlined,
          title: 'Review Profile',
          subtitle: 'Verify before submitting',
        ),
        SizedBox(height: isMob ? 14 : 24),

        // Profile header banner
        Container(
          padding: EdgeInsets.all(isMob ? 14 : 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: isMob
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ProfileAvatar(bytes: p.profilePicBytes, size: 56),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nameController.text.isEmpty
                                    ? 'Your Name'
                                    : p.nameController.text,
                                style: _T.head(fs: 15, c: _T.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              _QuickInfo(
                                icon: Icons.email_outlined,
                                text: p.emailController.text,
                              ),
                            ],
                          ),
                        ),
                        _SmallIconBtn(
                          icon: Icons.edit_outlined,
                          color: _T.white,
                          onTap: () => p.goToStep(1),
                        ),
                      ],
                    ),
                    if (p.contactNumberController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _QuickInfo(
                        icon: Icons.phone_outlined,
                        text: p.contactNumberController.text,
                      ),
                    ],
                    if (p.nationalityController.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _QuickInfo(
                        icon: Icons.public_outlined,
                        text: p.nationalityController.text,
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    _ProfileAvatar(bytes: p.profilePicBytes),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nameController.text.isEmpty
                                ? 'Your Name'
                                : p.nameController.text,
                            style: _T.head(fs: 22, c: _T.white),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 18,
                            runSpacing: 5,
                            children: [
                              _QuickInfo(
                                icon: Icons.email_outlined,
                                text: p.emailController.text,
                              ),
                              if (p.contactNumberController.text.isNotEmpty)
                                _QuickInfo(
                                  icon: Icons.phone_outlined,
                                  text: p.contactNumberController.text,
                                ),
                              if (p.nationalityController.text.isNotEmpty)
                                _QuickInfo(
                                  icon: Icons.public_outlined,
                                  text: p.nationalityController.text,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _SmallIconBtn(
                      icon: Icons.edit_outlined,
                      color: _T.white,
                      onTap: () => p.goToStep(1),
                    ),
                  ],
                ),
        ),

        SizedBox(height: isMob ? 12 : 18),

        // Grid: 1-col on mobile, 2-col on tablet+
        if (isMob)
          Column(children: _reviewCards(context, p, cp))
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (p.summaryController.text.isNotEmpty) ...[
                      _ReviewCard(
                        title: 'Professional Summary',
                        icon: Icons.description_outlined,
                        onEdit: () => p.goToStep(1),
                        padding: cp,
                        child: Text(
                          p.summaryController.text,
                          style: _T.body(c: _T.textSec),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _ReviewCard(
                      title: 'Education',
                      icon: Icons.school_outlined,
                      onEdit: () => p.goToStep(2),
                      padding: cp,
                      child: _EduReviewList(p.educationalProfile),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _ReviewCard(
                      title: 'Skills',
                      icon: Icons.auto_awesome_outlined,
                      onEdit: () => p.goToStep(1),
                      padding: cp,
                      child: p.skills.isEmpty
                          ? Text(
                              'No skills added',
                              style: _T
                                  .label(c: _T.textTert)
                                  .copyWith(fontStyle: FontStyle.italic),
                            )
                          : Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                for (final s in p.skills)
                                  _SkillTag(label: s, compact: true),
                              ],
                            ),
                    ),
                    if (p.objectivesController.text.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _ReviewCard(
                        title: 'Objectives',
                        icon: Icons.flag_outlined,
                        onEdit: () => p.goToStep(1),
                        padding: cp,
                        child: Text(
                          p.objectivesController.text,
                          style: _T.body(fs: 13, c: _T.textSec),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

        SizedBox(height: isMob ? 20 : 32),
        _NavRow(
          onBack: onBack,
          onNext: p.isLoading ? () {} : onSubmit,
          nextLabel: p.isLoading ? 'Creating…' : 'Submit Profile',
          isFinal: true,
        ),
      ],
    );
  }

  List<Widget> _reviewCards(BuildContext ctx, SignupProvider p, double cp) {
    final cards = <Widget>[];
    if (p.summaryController.text.isNotEmpty) {
      cards.add(
        _ReviewCard(
          title: 'Summary',
          icon: Icons.description_outlined,
          onEdit: () => p.goToStep(1),
          padding: cp,
          child: Text(p.summaryController.text, style: _T.body(c: _T.textSec)),
        ),
      );
      cards.add(const SizedBox(height: 10));
    }
    cards.add(
      _ReviewCard(
        title: 'Education',
        icon: Icons.school_outlined,
        onEdit: () => p.goToStep(2),
        padding: cp,
        child: _EduReviewList(p.educationalProfile),
      ),
    );
    cards.add(const SizedBox(height: 10));
    cards.add(
      _ReviewCard(
        title: 'Skills',
        icon: Icons.auto_awesome_outlined,
        onEdit: () => p.goToStep(1),
        padding: cp,
        child: p.skills.isEmpty
            ? Text(
                'No skills',
                style: _T
                    .label(c: _T.textTert)
                    .copyWith(fontStyle: FontStyle.italic),
              )
            : Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final s in p.skills) _SkillTag(label: s, compact: true),
                ],
              ),
      ),
    );
    if (p.objectivesController.text.isNotEmpty) {
      cards.add(const SizedBox(height: 10));
      cards.add(
        _ReviewCard(
          title: 'Objectives',
          icon: Icons.flag_outlined,
          onEdit: () => p.goToStep(1),
          padding: cp,
          child: Text(
            p.objectivesController.text,
            style: _T.body(fs: 13, c: _T.textSec),
          ),
        ),
      );
    }
    return cards;
  }
}

class _EduReviewList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _EduReviewList(this.items);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final e in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _T.indigo10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: _T.primary,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['institutionName'] ?? '', style: _T.head(fs: 13)),
                    Text(
                      '${e['majorSubjects']} • ${e['duration']}',
                      style: _T.label(fs: 11),
                    ),
                    if ((e['marksOrCgpa'] ?? '').isNotEmpty)
                      Text(
                        'Grade: ${e['marksOrCgpa']}',
                        style: _T.label(fs: 11, c: _T.textTert),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// EDUCATION TIMELINE ITEM
// ═════════════════════════════════════════════════════════════════════════════
class _EduItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  final bool isLast;
  final VoidCallback onEdit, onDelete;
  const _EduItem({
    required this.index,
    required this.data,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final w = _LD.width(context);
    final isMob = _BP.isMobile(w);
    final cp = _BP.cardPad(w);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: isMob ? 30 : 36,
                height: isMob ? 30 : 36,
                decoration: BoxDecoration(
                  color: _T.indigo10,
                  shape: BoxShape.circle,
                  border: Border.all(color: _T.primary, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: _T.label(fs: 11, c: _T.primary, fw: FontWeight.w700),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: _T.border,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: EdgeInsets.all(cp),
              decoration: BoxDecoration(
                color: _T.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['institutionName'] ?? '',
                          style: _T.head(fs: isMob ? 13 : 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['majorSubjects'] ?? '',
                          style: _T.label(
                            fs: 12,
                            c: _T.primary,
                            fw: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: _T.textTert,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data['duration'] ?? '',
                              style: _T.label(fs: 11),
                            ),
                            if ((data['marksOrCgpa'] ?? '').isNotEmpty) ...[
                              const SizedBox(width: 10),
                              Text(
                                'GPA: ${data['marksOrCgpa']}',
                                style: _T.label(fs: 11),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _SmallIconBtn(
                        icon: Icons.edit_outlined,
                        color: _T.textSec,
                        onTap: onEdit,
                      ),
                      _SmallIconBtn(
                        icon: Icons.delete_outline,
                        color: _T.red,
                        onTap: onDelete,
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

// ═════════════════════════════════════════════════════════════════════════════
// SHARED LAYOUT WIDGETS
// ═════════════════════════════════════════════════════════════════════════════
class _Card extends StatelessWidget {
  final Widget child;
  final double padding;
  const _Card({required this.child, this.padding = 20});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: _T.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _T.border),
    ),
    child: child,
  );
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _CardHeader({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _T.primary, size: 16),
      const SizedBox(width: 7),
      Text(title, style: _T.head(fs: 13)),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    final w = _LD.width(context);
    final isMob = _BP.isMobile(w);
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMob ? 8 : 10),
          decoration: BoxDecoration(
            color: _T.indigo10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _T.primary, size: isMob ? 18 : 22),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _T.head(fs: isMob ? 17 : 22)),
            Text(subtitle, style: _T.label(fs: isMob ? 11 : 13)),
          ],
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  final VoidCallback onBack, onNext;
  final String nextLabel;
  final bool isFinal;
  const _NavRow({
    required this.onBack,
    required this.onNext,
    this.nextLabel = 'Continue',
    this.isFinal = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextButton.icon(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded, size: 15),
        label: Text('Back', style: _T.label(fs: 13, fw: FontWeight.w600)),
        style: TextButton.styleFrom(
          foregroundColor: _T.textSec,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
      _PrimaryBtn(
        icon: isFinal ? Icons.check_rounded : Icons.arrow_forward_rounded,
        label: nextLabel,
        onTap: onNext,
        color: isFinal ? _T.green : _T.primary,
      ),
    ],
  );
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onEdit;
  final double padding;
  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.onEdit,
    this.padding = 18,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: _T.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _T.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: _T.primary, size: 15),
                const SizedBox(width: 7),
                Text(title, style: _T.head(fs: 13)),
              ],
            ),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _T.indigo10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 11,
                      color: _T.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: _T.label(
                        fs: 11,
                        c: _T.primary,
                        fw: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 16, color: _T.border),
        child,
      ],
    ),
  );
}

// ─── Avatar ─────────────────────────────────────────────────────────────────
class _AvatarUploader extends StatefulWidget {
  final Uint8List? imageData;
  final String? networkImage;
  final VoidCallback onTap;
  final double size;
  const _AvatarUploader({
    this.imageData,
    this.networkImage,
    required this.onTap,
    this.size = 100,
  });
  @override
  State<_AvatarUploader> createState() => _AvatarUploaderState();
}

class _AvatarUploaderState extends State<_AvatarUploader> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final has = widget.imageData != null || widget.networkImage != null;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _hov ? _T.primary : _T.border,
                  width: 2,
                ),
              ),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _T.bg,
                  image: widget.imageData != null
                      ? DecorationImage(
                          image: MemoryImage(widget.imageData!),
                          fit: BoxFit.cover,
                        )
                      : widget.networkImage != null
                      ? DecorationImage(
                          image: MemoryImage(
                            base64Decode(widget.networkImage!.split(',').last),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !has
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add_alt_1_outlined,
                            color: _T.textTert,
                            size: widget.size * 0.27,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add Photo',
                            style: _T.label(
                              fs: widget.size * 0.1,
                              c: _T.textTert,
                              fw: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : _hov
                    ? Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x661E293B),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: _T.white,
                          size: 20,
                        ),
                      )
                    : null,
              ),
            ),
            if (has)
              Positioned(
                bottom: 3,
                right: 3,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: _T.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: _T.white,
                    size: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final Uint8List? bytes;
  final double size;
  const _ProfileAvatar({this.bytes, this.size = 68});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
      image: bytes != null
          ? DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover)
          : null,
    ),
    child: bytes == null
        ? Icon(
            Icons.person_rounded,
            size: size * 0.5,
            color: Colors.white.withValues(alpha: 0.5),
          )
        : null,
  );
}

// ─── Input field ─────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final bool multiLine, showLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  const _InputField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.label = '',
    this.multiLine = false,
    this.showLabel = true,
    this.onChanged,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (showLabel && label.isNotEmpty) ...[
        Text(
          label,
          style: _T.label(fs: 12, c: _T.textPri, fw: FontWeight.w600),
        ),
        const SizedBox(height: 5),
      ],
      TextFormField(
        controller: ctrl,
        maxLines: multiLine ? 4 : 1,
        style: _T.body(fs: 14),
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        validator: validator ?? (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        decoration: _inputDec(hint: hint, icon: icon),
      ),
    ],
  );
}

// ─── Autocomplete field ──────────────────────────────────────────────────────
class _AutoField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final List<String> options;
  final ValueChanged<String> onSelected, onChanged;
  const _AutoField({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.options,
    required this.onSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: _T.label(fs: 12, c: _T.textPri, fw: FontWeight.w600),
      ),
      const SizedBox(height: 5),
      Autocomplete<String>(
        optionsBuilder: (v) => v.text.isEmpty
            ? const []
            : options.where(
                (c) => c.toLowerCase().contains(v.text.toLowerCase()),
              ),
        onSelected: onSelected,
        fieldViewBuilder: (_, c, focus, _) {
          if (c.text != ctrl.text) c.text = ctrl.text;
          return TextFormField(
            controller: c,
            focusNode: focus,
            style: _T.body(fs: 14),
            onChanged: onChanged,
            decoration: _inputDec(hint: '', icon: icon),
          );
        },
      ),
    ],
  );
}

// ─── Date picker field ───────────────────────────────────────────────────────
class _DateField extends StatefulWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        widget.label,
        style: _T.label(fs: 12, c: _T.textPri, fw: FontWeight.w600),
      ),
      const SizedBox(height: 5),
      MouseRegion(
        onEnter: (_) => setState(() => _hov = true),
        onExit: (_) => setState(() => _hov = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _T.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hov ? _T.primary : _T.border,
                width: _hov ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: widget.value == null ? _T.textTert : _T.primary,
                  size: 16,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    widget.value == null
                        ? 'Select date'
                        : DateFormat('MMM d, y').format(widget.value!),
                    style: _T.body(
                      fs: 13,
                      c: widget.value == null ? _T.textTert : _T.textPri,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _T.textTert,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

// ─── Year dropdown ───────────────────────────────────────────────────────────
class _YearDrop extends StatelessWidget {
  final String label, value;
  final ValueChanged<String?> onChange;
  const _YearDrop({
    required this.label,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final years = List.generate(40, (i) => (2035 - i).toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _T.label(fs: 12, c: _T.textPri, fw: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _T.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _T.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: years.contains(value) ? value : years.first,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _T.textTert,
              ),
              style: _T.body(fs: 14),
              items: [
                for (final y in years)
                  DropdownMenuItem(value: y, child: Text(y)),
              ],
              onChanged: onChange,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Buttons ─────────────────────────────────────────────────────────────────
class _PrimaryBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _PrimaryBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _T.primary,
  });
  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hov = true),
    onExit: (_) => setState(() => _hov = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _hov
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: _T.label(fs: 13, c: _T.white, fw: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Icon(widget.icon, color: _T.white, size: 15),
          ],
        ),
      ),
    ),
  );
}

class _SecondaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 15),
    label: Text(label, style: _T.label(fs: 13, fw: FontWeight.w600)),
    style: TextButton.styleFrom(
      foregroundColor: _T.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: const BorderSide(color: _T.primary),
      ),
    ),
  );
}

class _SmallIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _SmallIconBtn({required this.icon, required this.onTap, this.color});
  @override
  State<_SmallIconBtn> createState() => _SmallIconBtnState();
}

class _SmallIconBtnState extends State<_SmallIconBtn> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hov = true),
    onExit: (_) => setState(() => _hov = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _hov ? _T.bg : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, color: widget.color ?? _T.textSec, size: 17),
      ),
    ),
  );
}

// ─── Skill tag ────────────────────────────────────────────────────────────────
class _SkillTag extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;
  final bool compact;
  const _SkillTag({required this.label, this.onDelete, this.compact = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 9 : 11,
      vertical: compact ? 4 : 7,
    ),
    decoration: BoxDecoration(
      color: _T.indigo10,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _T.primary.withValues(alpha: 0.28)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: _T.label(
            fs: compact ? 11 : 12,
            c: _T.primary,
            fw: FontWeight.w600,
          ),
        ),
        if (onDelete != null) ...[
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close_rounded, size: 13, color: _T.primary),
          ),
        ],
      ],
    ),
  );
}

// ─── Suggestion chip ──────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _T.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _T.textTert),
          const SizedBox(width: 5),
          Text(label, style: _T.label(fs: 11)),
          const SizedBox(width: 4),
          const Icon(Icons.add_rounded, size: 12, color: _T.primary),
        ],
      ),
    ),
  );
}

// ─── Badge ────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _T.bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: _T.label(fs: 10)),
  );
}

// ─── Quick info (review banner) ───────────────────────────────────────────────
class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _QuickInfo({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: Colors.white70),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          style: _T.label(fs: 11, c: Colors.white70),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

// ─── Empty card ───────────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget action;
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });
  @override
  Widget build(BuildContext context) {
    final w = _LD.width(context);
    final isMob = _BP.isMobile(w);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMob ? 28 : 48),
      decoration: BoxDecoration(
        color: _T.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: isMob ? 40 : 52, color: _T.textTert),
          const SizedBox(height: 12),
          Text(
            title,
            style: _T.head(fs: isMob ? 15 : 17, c: _T.textSec),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: _T.label(fs: 12), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          action,
        ],
      ),
    );
  }
}

// ─── Decimal formatter ────────────────────────────────────────────────────────
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;
  const DecimalTextInputFormatter({this.decimalRange = 2});
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nw) {
    final t = nw.text;
    if (t.isEmpty) return nw;
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(t)) return old;
    if (t.contains('.')) {
      final p = t.split('.');
      if (p.length > 2 || p[1].length > decimalRange) return old;
    }
    return nw;
  }
}
