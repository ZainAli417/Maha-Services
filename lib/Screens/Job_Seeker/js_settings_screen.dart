// lib/Screens/Job_Seeker/js_settings_screen.dart
//
// Job Seeker Settings — Responsive, adaptive, and animated.
// Optimized for Flutter Web, Android tablets, and phones.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'JS_Top_Bar.dart';
import '../../services/job_alert_service.dart';

// ═══════════════════════════════════════════════════════════════
//  DESIGN TOKENS — Material-3 inspired, high-contrast accessible
// ═══════════════════════════════════════════════════════════════
abstract final class _Tokens {
  // Primary palette
  static const Color primary = Color(0xFF4F46E5);   // Indigo 600
  static const Color primarySoft = Color(0xFFEEF2FF); // Indigo 50
  static const Color accent = Color(0xFF7C3AED);    // Violet 600

  // Neutral palette
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);     // Slate 200
  static const Color divider = Color(0xFFF1F5F9);    // Slate 100

  // Text palette
  static const Color textDark = Color(0xFF0F172A);   // Slate 900
  static const Color textBase = Color(0xFF334155);   // Slate 700
  static const Color textMuted = Color(0xFF64748B);  // Slate 500
  static const Color textLight = Color(0xFF94A3B8);  // Slate 400

  // Semantic
  static const Color success = Color(0xFF10B981);    // Emerald 500
  static const Color successSoft = Color(0xFFD1FAE5);// Emerald 100
  static const Color warning = Color(0xFFF59E0B);    // Amber 500
  static const Color danger = Color(0xFFEF4444);     // Red 500

  // Motion
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration base = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Breakpoints (shortest-side logic for foldables) [^4^]
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  // Layout
  static const double maxContentWidth = 960;
  static const double cardRadius = 16;
  static const double iconRadius = 12;
}

// ═══════════════════════════════════════════════════════════════
//  RESPONSIVE HELPERS
// ═══════════════════════════════════════════════════════════════
enum _FormFactor { compact, medium, expanded }

_FormFactor _getFormFactor(BoxConstraints constraints) {
  final width = constraints.maxWidth;
  if (width >= _Tokens.desktop) return _FormFactor.expanded;
  if (width >= _Tokens.tablet) return _FormFactor.medium;
  return _FormFactor.compact;
}

// ═══════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════
class JSSettingsScreen extends StatefulWidget {
  const JSSettingsScreen({super.key});

  @override
  State<JSSettingsScreen> createState() => _JSSettingsScreenState();
}

class _JSSettingsScreenState extends State<JSSettingsScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _staggerController;

  // State
  bool _jobAlertsEnabled = false;
  bool _newsletterEnabled = false;
  bool _isLoading = true;
  bool _isSavingAlerts = false;
  bool _isSavingNewsletter = false;
  String _role = 'Job Seeker';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: _Tokens.slow,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    );

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loadPreferences();
  }

  // ── Password Logic ───────────────────────────────────────────
  Future<void> _handleChangePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isUpdating = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: !isUpdating,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Update Password',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _Tokens.textDark,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'For security, please enter your current password and your new password.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: _Tokens.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildPasswordField(
                      controller: currentPasswordController,
                      label: 'Current Password',
                      obscure: obscureCurrent,
                      onToggle: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: newPasswordController,
                      label: 'New Password',
                      obscure: obscureNew,
                      onToggle: () => setDialogState(() => obscureNew = !obscureNew),
                      validator: (val) => (val != null && val.length >= 6)
                          ? null
                          : 'Password must be at least 6 characters',
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: confirmPasswordController,
                      label: 'Confirm New Password',
                      obscure: obscureConfirm,
                      onToggle: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      validator: (val) => val == newPasswordController.text
                          ? null
                          : 'Passwords do not match',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUpdating ? null : () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    color: _Tokens.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isUpdating = true);
                      try {
                        AuthCredential credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: currentPasswordController.text,
                        );
                        await user.reauthenticateWithCredential(credential);
                        await user.updatePassword(newPasswordController.text);

                        if (mounted) {
                          Navigator.pop(context);
                          _showStatusSnack(
                            enabled: true,
                            title: 'Password Updated',
                            subtitle: 'Your account is now more secure.',
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        String error = 'Failed to update password.';
                        if (e.code == 'wrong-password') error = 'Current password is incorrect.';
                        if (e.code == 'weak-password') error = 'The password is too weak.';
                        if (e.code == 'too-many-requests') error = 'Too many attempts. Try later.';
                        _showErrorSnack(error);
                      } catch (e) {
                        _showErrorSnack('An unexpected error occurred.');
                      } finally {
                        if (mounted) setDialogState(() => isUpdating = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Tokens.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    'Update',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: _Tokens.textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: _Tokens.textMuted),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(color: _Tokens.primary, fontWeight: FontWeight.w600),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: _Tokens.textLight,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: _Tokens.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Tokens.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Tokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Tokens.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator ?? (val) => (val == null || val.isEmpty) ? 'This field is required' : null,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  // ── Data Layer ───────────────────────────────────────────────
  Future<void> _loadPreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _setLoaded();
      return;
    }

    try {
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = userDoc.data();
      final role = data?['role'] ?? 'Job Seeker';

      final enabled = await JobAlertService.getAlertPreference(uid);

      if (mounted) {
        setState(() {
          _role = role;
          _jobAlertsEnabled = enabled;
          _isLoading = false;
        });
        _fadeController.forward();
        _staggerController.forward();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _setLoaded();
    }
  }

  void _setLoaded() {
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward();
      _staggerController.forward();
    }
  }

  Future<void> _toggleJobAlerts(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    HapticFeedback.lightImpact(); // tactile feedback

    setState(() {
      _jobAlertsEnabled = value;
      _isSavingAlerts = true;
    });

    try {
      await JobAlertService.updateAlertPreference(uid, value);
      _showStatusSnack(
        enabled: value,
        title: value ? 'Job alerts enabled' : 'Job alerts disabled',
        subtitle: value
            ? 'You\'ll receive emails for new positions.'
            : 'You won\'t receive position emails.',
      );
    } catch (e) {
      setState(() => _jobAlertsEnabled = !value); // rollback
      _showErrorSnack('Failed to update preference. Please try again.');
    } finally {
      if (mounted) setState(() => _isSavingAlerts = false);
    }
  }

  Future<void> _toggleNewsletter(bool value) async {
    HapticFeedback.lightImpact();

    setState(() {
      _newsletterEnabled = value;
      _isSavingNewsletter = true;
    });

    // Simulate API call — replace with real service
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() => _isSavingNewsletter = false);
      _showStatusSnack(
        enabled: value,
        title: value ? 'Subscribed' : 'Unsubscribed',
        subtitle: value
            ? 'Weekly digest will arrive every Monday.'
            : 'You won\'t receive newsletters anymore.',
      );
    }
  }

  // ── Feedback ─────────────────────────────────────────────────
  void _showStatusSnack({
    required bool enabled,
    required String title,
    required String subtitle,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            AnimatedContainer(
              duration: _Tokens.base,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: enabled ? _Tokens.successSoft : _Tokens.divider,
                shape: BoxShape.circle,
              ),
              child: Icon(
                enabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                color: enabled ? _Tokens.success : _Tokens.textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: enabled ? _Tokens.success : _Tokens.textMuted,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < _Tokens.mobile ? 12 : 24,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: _Tokens.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _Tokens.background,
      drawer: MediaQuery.sizeOf(context).width < _Tokens.mobile
          ? Drawer(
        child: JobSeekerSidebar(activeIndex: 4, isDrawer: true),
      )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final factor = _getFormFactor(constraints);
            final isCompact = factor == _FormFactor.compact;

            return Row(
              children: [
                if (!isCompact) const JobSeekerSidebar(activeIndex: 4),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _AppBar(
                          isCompact: isCompact,
                          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        Expanded(
                          child: _isLoading
                              ? const _SkeletonLoader()
                              : _role != 'Job Seeker'
                              ? const _AccessDeniedView()
                              : _SettingsContent(
                            formFactor: factor,
                            staggerController: _staggerController,
                            jobAlertsEnabled: _jobAlertsEnabled,
                            newsletterEnabled: _newsletterEnabled,
                            isSavingAlerts: _isSavingAlerts,
                            isSavingNewsletter: _isSavingNewsletter,
                            onToggleJobAlerts: _toggleJobAlerts,
                            onToggleNewsletter: _toggleNewsletter,
                            onTapChangePassword: _handleChangePassword,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  APP BAR
// ═══════════════════════════════════════════════════════════════
class _AppBar extends StatelessWidget {
  const _AppBar({required this.isCompact, this.onMenuTap});

  final bool isCompact;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isCompact ? 56 : 72,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 28),
      decoration: const BoxDecoration(
        color: _Tokens.surface,
        border: Border(bottom: BorderSide(color: _Tokens.divider)),
      ),
      child: Row(
        children: [
          if (isCompact)
            IconButton(
              icon: const Icon(Icons.menu_rounded, size: 22),
              onPressed: onMenuTap,
              style: IconButton.styleFrom(
                foregroundColor: _Tokens.textDark,
              ),
            ),
          if (isCompact) const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_Tokens.primary, _Tokens.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.settings_outlined,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isCompact ? 16 : 20,
                  fontWeight: FontWeight.w700,
                  color: _Tokens.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              if (!isCompact)
                Text(
                  'Manage your account preferences',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _Tokens.textMuted,
                    height: 1.3,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SETTINGS CONTENT — Responsive, centered, staggered
// ═══════════════════════════════════════════════════════════════
class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.formFactor,
    required this.staggerController,
    required this.jobAlertsEnabled,
    required this.newsletterEnabled,
    required this.isSavingAlerts,
    required this.isSavingNewsletter,
    required this.onToggleJobAlerts,
    required this.onToggleNewsletter,
    required this.onTapChangePassword,
  });

  final _FormFactor formFactor;
  final AnimationController staggerController;
  final bool jobAlertsEnabled;
  final bool newsletterEnabled;
  final bool isSavingAlerts;
  final bool isSavingNewsletter;
  final ValueChanged<bool> onToggleJobAlerts;
  final ValueChanged<bool> onToggleNewsletter;
  final VoidCallback onTapChangePassword;

  @override
  Widget build(BuildContext context) {
    final isCompact = formFactor == _FormFactor.compact;
    final horizontalPadding = isCompact
        ? 16.0
        : formFactor == _FormFactor.medium
        ? 32.0
        : 40.0;

    // Center content on large screens with max-width constraint [^4^]
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _Tokens.maxContentWidth),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.notifications_outlined,
                title: 'Notifications & Alerts',
                subtitle: 'Control how you receive job notifications',
                delay: 0,
                controller: staggerController,
              ),
              const SizedBox(height: 20),

              _ToggleCard(
                icon: Icons.email_outlined,
                iconColor: _Tokens.primary,
                iconBgColor: _Tokens.primarySoft,
                title: 'Job Posting Alerts',
                description:
                'Receive email notifications whenever recruiters post new job positions. '
                    'Stay ahead of the competition by being the first to apply.',
                value: jobAlertsEnabled,
                onChanged: onToggleJobAlerts,
                isSaving: isSavingAlerts,
                delay: 1,
                controller: staggerController,
              ),
              const SizedBox(height: 14),

              _ToggleCard(
                icon: Icons.campaign_outlined,
                iconColor: _Tokens.accent,
                iconBgColor: const Color(0xFFF3E8FF), // Violet 100
                title: 'Newsletter & Updates',
                description:
                'Get weekly digests with career tips, industry insights, '
                    'and platform updates straight to your inbox.',
                value: newsletterEnabled,
                onChanged: onToggleNewsletter,
                isSaving: isSavingNewsletter,
                delay: 2,
                controller: staggerController,
              ),

              const SizedBox(height: 36),

              _SectionHeader(
                icon: Icons.shield_outlined,
                title: 'Privacy & Security',
                subtitle: 'Manage your data and account security',
                delay: 3,
                controller: staggerController,
              ),
              const SizedBox(height: 20),

              _ActionCard(
                icon: Icons.password_rounded,
                iconColor: _Tokens.warning,
                iconBgColor: const Color(0xFFFEF3C7), // Amber 100
                title: 'Change Password',
                description: 'Update your password to keep your account secure.',
                actionLabel: 'Update',
                onTap: onTapChangePassword,
                delay: 4,
                controller: staggerController,
              ),
              const SizedBox(height: 14),

              _ActionCard(
                icon: Icons.delete_outline_rounded,
                iconColor: _Tokens.danger,
                iconBgColor: const Color(0xFFFEE2E2), // Red 100
                title: 'Delete Account',
                description:
                'Permanently delete your account and all associated data. '
                    'This action cannot be undone.',
                actionLabel: 'Delete',
                onTap: () {/* Show confirmation dialog */},
                isDestructive: true,
                delay: 5,
                controller: staggerController,
              ),

              const SizedBox(height: 36),

              _InfoCard(
                delay: 6,
                controller: staggerController,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SECTION HEADER — with staggered slide+fade
// ═══════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
    required this.controller,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final animation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay * 0.08,
          (delay * 0.08) + 0.4,
          curve: Curves.easeOutQuart,
        ),
      ),
    );

    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay * 0.08,
          (delay * 0.08) + 0.35,
          curve: Curves.easeOut,
        ),
      ),
    );

    return SlideTransition(
      position: animation,
      child: FadeTransition(
        opacity: fade,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_Tokens.primary, _Tokens.accent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: _Tokens.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _Tokens.textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: _Tokens.textMuted,
                      height: 1.4,
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
}

// ═══════════════════════════════════════════════════════════════
//  TOGGLE CARD — Hoverable on web, animated status badge
// ═══════════════════════════════════════════════════════════════
class _ToggleCard extends StatefulWidget {
  const _ToggleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.isSaving,
    required this.delay,
    required this.controller,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isSaving;
  final int delay;
  final AnimationController controller;

  @override
  State<_ToggleCard> createState() => _ToggleCardState();
}

class _ToggleCardState extends State<_ToggleCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final animation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Interval(
          widget.delay * 0.08,
          (widget.delay * 0.08) + 0.45,
          curve: Curves.easeOutQuart,
        ),
      ),
    );

    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: widget.controller,
        curve: Interval(
          widget.delay * 0.08,
          (widget.delay * 0.08) + 0.4,
          curve: Curves.easeOut,
        ),
      ),
    );

    return SlideTransition(
      position: animation,
      child: FadeTransition(
        opacity: fade,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: _Tokens.base,
            curve: Curves.easeOutQuart,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _Tokens.surface,
              borderRadius: BorderRadius.circular(_Tokens.cardRadius),
              border: Border.all(
                color: widget.value
                    ? widget.iconColor.withValues(alpha: 0.25)
                    : _isHovered
                    ? _Tokens.border.withValues(alpha: 0.8)
                    : _Tokens.divider,
                width: widget.value ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _Tokens.textDark.withValues(alpha: _isHovered ? 0.06 : 0.03),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: const Offset(0, 4),
                  spreadRadius: _isHovered ? -2 : 0,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                AnimatedContainer(
                  duration: _Tokens.fast,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.iconBgColor,
                    borderRadius: BorderRadius.circular(_Tokens.iconRadius),
                  ),
                  child: Icon(widget.icon, size: 22, color: widget.iconColor),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Switch
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: _Tokens.textDark,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (widget.isSaving)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _Tokens.primary,
                              ),
                            )
                          else
                            Switch.adaptive(
                              value: widget.value,
                              onChanged: widget.onChanged,
                              activeColor: Colors.white,
                              activeTrackColor: widget.iconColor,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: _Tokens.textLight.withValues(alpha: 0.35),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        widget.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: _Tokens.textMuted,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status badge
                      AnimatedContainer(
                        duration: _Tokens.base,
                        curve: Curves.easeOutQuart,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: widget.value
                              ? widget.iconColor.withValues(alpha: 0.08)
                              : _Tokens.divider,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.value
                                ? widget.iconColor.withValues(alpha: 0.2)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: _Tokens.fast,
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Icon(
                                widget.value
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                key: ValueKey(widget.value),
                                size: 13,
                                color: widget.value
                                    ? widget.iconColor
                                    : _Tokens.textLight,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.value ? 'Enabled' : 'Disabled',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: widget.value
                                    ? widget.iconColor
                                    : _Tokens.textLight,
                                letterSpacing: 0.2,
                              ),
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
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ACTION CARD — For navigation items (password, delete, etc.)
// ═══════════════════════════════════════════════════════════════
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
    required this.delay,
    required this.controller,
    this.isDestructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;
  final bool isDestructive;
  final int delay;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final animation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay * 0.08,
          (delay * 0.08) + 0.45,
          curve: Curves.easeOutQuart,
        ),
      ),
    );

    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay * 0.08,
          (delay * 0.08) + 0.4,
          curve: Curves.easeOut,
        ),
      ),
    );

    return SlideTransition(
      position: animation,
      child: FadeTransition(
        opacity: fade,
        child: Material(
          color: _Tokens.surface,
          borderRadius: BorderRadius.circular(_Tokens.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor: _Tokens.primarySoft.withValues(alpha: 0.3),
            splashColor: _Tokens.primary.withValues(alpha: 0.05),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: _Tokens.divider),
                borderRadius: BorderRadius.circular(_Tokens.cardRadius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(_Tokens.iconRadius),
                    ),
                    child: Icon(icon, size: 22, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _Tokens.textDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: _Tokens.textMuted,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor:
                      isDestructive ? _Tokens.danger : _Tokens.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    child: Text(actionLabel),
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

// ═══════════════════════════════════════════════════════════════
//  INFO CARD — Gradient card with explanation
// ═══════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.delay, required this.controller});

  final int delay;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final animation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay * 0.08,
          (delay * 0.08) + 0.5,
          curve: Curves.easeOutQuart,
        ),
      ),
    );

    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay * 0.08,
          (delay * 0.08) + 0.45,
          curve: Curves.easeOut,
        ),
      ),
    );

    return SlideTransition(
      position: animation,
      child: FadeTransition(
        opacity: fade,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _Tokens.primary.withValues(alpha: 0.06),
                _Tokens.accent.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(_Tokens.cardRadius),
            border: Border.all(
              color: _Tokens.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_Tokens.primary, _Tokens.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(_Tokens.iconRadius),
                  boxShadow: [
                    BoxShadow(
                      color: _Tokens.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Job Alerts Work',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _Tokens.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'When enabled, you\'ll receive an email every time a recruiter '
                          'posts a new position on Maha Services. Emails include job '
                          'title, location, salary, and a direct link to apply. '
                          'You can disable this at any time from this screen.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: _Tokens.textMuted,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SKELETON LOADER — Shimmer-free, clean pulse animation
// ═══════════════════════════════════════════════════════════════
class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(width: 180, height: 24),
          const SizedBox(height: 20),
          _SkeletonCard(),
          const SizedBox(height: 14),
          _SkeletonCard(),
          const SizedBox(height: 36),
          _SkeletonLine(width: 160, height: 24),
          const SizedBox(height: 20),
          _SkeletonCard(),
          const SizedBox(height: 14),
          _SkeletonCard(),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _Tokens.divider,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Tokens.surface,
        borderRadius: BorderRadius.circular(_Tokens.cardRadius),
        border: Border.all(color: _Tokens.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _Tokens.divider,
              borderRadius: BorderRadius.circular(_Tokens.iconRadius),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _Tokens.divider,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: _Tokens.divider,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 200,
                  decoration: BoxDecoration(
                    color: _Tokens.divider,
                    borderRadius: BorderRadius.circular(6),
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

// ═══════════════════════════════════════════════════════════════
//  ACCESS DENIED VIEW
// ═══════════════════════════════════════════════════════════════
class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _Tokens.danger.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person_outlined,
                  size: 56,
                  color: _Tokens.danger.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Access Restricted',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _Tokens.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Job Alert settings are only available for Job Seekers. '
                    'Switch to your Job Seeker profile to manage alerts.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _Tokens.textMuted,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => context.go('/recruiter-dashboard'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Return to Dashboard'),
                style: FilledButton.styleFrom(
                  backgroundColor: _Tokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}