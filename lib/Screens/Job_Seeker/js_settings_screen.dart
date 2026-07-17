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
//  DESIGN TOKENS — Maha HR brand (navy + teal), accessible
// ═══════════════════════════════════════════════════════════════
abstract final class _Tokens {
  // Brand primary palette (navy)
  static const Color primary = Color(0xFF14507F); // navy primary
  static const Color primaryDeep = Color(0xFF0A2E4F); // deep navy
  static const Color primarySoft = Color(0xFFE8F1F8); // navy tint
  static const Color accent = Color(0xFF2EC4B6); // teal accent
  static const Color accentDeep = Color(0xFF15A99C); // teal deep
  static const Color accentSoft = Color(0xFFE4F6F4); // teal tint

  // Hero / deep surfaces
  static const Color hero1 = Color(0xFF061C31);
  static const Color hero2 = Color(0xFF0A2E4F);
  static const Color hero3 = Color(0xFF14507F);

  // Neutral palette
  static const Color background = Color(0xFFF4F9FB); // bgSoft
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDCE7EF); // brand border
  static const Color divider = Color(0xFFEDF4F8); // faint divider

  // Text palette
  static const Color textDark = Color(0xFF0B2239); // ink
  static const Color textBase = Color(0xFF3E5C76); // slate
  static const Color textMuted = Color(0xFF5E7A8E); // muted
  static const Color textLight = Color(0xFF8AA5B5); // faint

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

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
    _fadeController = AnimationController(vsync: this, duration: _Tokens.slow);
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
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
                      onToggle: () => setDialogState(
                        () => obscureCurrent = !obscureCurrent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: newPasswordController,
                      label: 'New Password',
                      obscure: obscureNew,
                      onToggle: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                      validator: (val) => (val != null && val.length >= 6)
                          ? null
                          : 'Password must be at least 6 characters',
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: confirmPasswordController,
                      label: 'Confirm New Password',
                      obscure: obscureConfirm,
                      onToggle: () => setDialogState(
                        () => obscureConfirm = !obscureConfirm,
                      ),
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
                              AuthCredential credential =
                                  EmailAuthProvider.credential(
                                    email: user.email!,
                                    password: currentPasswordController.text,
                                  );
                              await user.reauthenticateWithCredential(
                                credential,
                              );
                              await user.updatePassword(
                                newPasswordController.text,
                              );

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
                              if (e.code == 'wrong-password') {
                                error = 'Current password is incorrect.';
                              }
                              if (e.code == 'weak-password') {
                                error = 'The password is too weak.';
                              }
                              if (e.code == 'too-many-requests') {
                                error = 'Too many attempts. Try later.';
                              }
                              _showErrorSnack(error);
                            } catch (e) {
                              _showErrorSnack('An unexpected error occurred.');
                            } finally {
                              if (mounted) {
                                setDialogState(() => isUpdating = false);
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Tokens.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                          ),
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
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: _Tokens.textMuted,
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          color: _Tokens.accentDeep,
          fontWeight: FontWeight.w600,
        ),
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
          borderSide: const BorderSide(color: _Tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Tokens.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _Tokens.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator:
          validator ??
          (val) =>
              (val == null || val.isEmpty) ? 'This field is required' : null,
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
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
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
                enabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            fontWeight: FontWeight.w600,
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
          ? const Drawer(child: JobSeekerSidebar(activeIndex: 4, isDrawer: true))
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
                          onMenuTap: () =>
                              _scaffoldKey.currentState?.openDrawer(),
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
    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 12 : 24,
          isCompact ? 12 : 20,
          isCompact ? 12 : 24,
          0,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 22,
            vertical: isCompact ? 14 : 20,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_Tokens.hero1, _Tokens.hero2, _Tokens.hero3],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _Tokens.primaryDeep.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              if (isCompact)
                IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 22),
                  onPressed: onMenuTap,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              if (isCompact) const SizedBox(width: 8),
              // Glass teal icon chip
              Container(
                padding: EdgeInsets.all(isCompact ? 9 : 11),
                decoration: BoxDecoration(
                  color: _Tokens.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _Tokens.accent.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  size: isCompact ? 18 : 22,
                  color: const Color(0xFF43E0D2),
                ),
              ),
              SizedBox(width: isCompact ? 12 : 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isCompact ? 17 : 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your account preferences',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isCompact ? 11.5 : 13,
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.3,
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

    // Center content on large screens with max-width constraint
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _Tokens.maxContentWidth),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            isCompact ? 16 : 24,
            horizontalPadding,
            isCompact ? 32 : 48,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                eyebrow: 'NOTIFICATIONS',
                icon: Icons.notifications_active_outlined,
                title: 'Notifications & Alerts',
                subtitle: 'Control how you receive job notifications',
                isCompact: isCompact,
                delay: 0,
                controller: staggerController,
                children: [
                  _ToggleTile(
                    icon: Icons.email_outlined,
                    accent: _Tokens.primary,
                    accentBg: _Tokens.primarySoft,
                    title: 'Job Posting Alerts',
                    description:
                        'Receive email notifications whenever recruiters post new positions. '
                        'Be the first to apply.',
                    value: jobAlertsEnabled,
                    onChanged: onToggleJobAlerts,
                    isSaving: isSavingAlerts,
                    isCompact: isCompact,
                  ),
                  const _TileDivider(),
                  _ToggleTile(
                    icon: Icons.campaign_outlined,
                    accent: _Tokens.accentDeep,
                    accentBg: _Tokens.accentSoft,
                    title: 'Newsletter & Updates',
                    description:
                        'Get weekly digests with career tips, industry insights, '
                        'and platform updates.',
                    value: newsletterEnabled,
                    onChanged: onToggleNewsletter,
                    isSaving: isSavingNewsletter,
                    isCompact: isCompact,
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 16 : 24),

              _SectionCard(
                eyebrow: 'ACCOUNT',
                icon: Icons.shield_outlined,
                title: 'Privacy & Security',
                subtitle: 'Manage your data and account security',
                isCompact: isCompact,
                delay: 3,
                controller: staggerController,
                children: [
                  _ActionTile(
                    icon: Icons.password_rounded,
                    accent: _Tokens.primary,
                    accentBg: _Tokens.primarySoft,
                    title: 'Change Password',
                    description:
                        'Update your password to keep your account secure.',
                    actionLabel: 'Update',
                    onTap: onTapChangePassword,
                    isCompact: isCompact,
                  ),
                  const _TileDivider(),
                  _ActionTile(
                    icon: Icons.delete_outline_rounded,
                    accent: _Tokens.danger,
                    accentBg: const Color(0xFFFEE2E2),
                    title: 'Delete Account',
                    description:
                        'Permanently delete your account and all associated data. '
                        'This action cannot be undone.',
                    actionLabel: 'Delete',
                    onTap: () {
                      /* Show confirmation dialog */
                    },
                    isDestructive: true,
                    isCompact: isCompact,
                  ),
                ],
              ),

              SizedBox(height: isCompact ? 16 : 24),

              _InfoCard(
                isCompact: isCompact,
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
//  SECTION CARD — branded white card w/ teal eyebrow + navy title
// ═══════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.eyebrow,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompact,
    required this.delay,
    required this.controller,
    required this.children,
  });

  final String eyebrow;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompact;
  final int delay;
  final AnimationController controller;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final slide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
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
      position: slide,
      child: FadeTransition(
        opacity: fade,
        child: Container(
          decoration: BoxDecoration(
            color: _Tokens.surface,
            borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
            border: Border.all(color: _Tokens.border),
            boxShadow: [
              BoxShadow(
                color: _Tokens.textDark.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 14 : 20,
                  isCompact ? 14 : 18,
                  isCompact ? 14 : 20,
                  isCompact ? 10 : 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8 : 10),
                      decoration: BoxDecoration(
                        color: _Tokens.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: isCompact ? 18 : 20,
                        color: _Tokens.accentDeep,
                      ),
                    ),
                    SizedBox(width: isCompact ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _Tokens.accentDeep,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isCompact ? 15 : 17,
                              fontWeight: FontWeight.w800,
                              color: _Tokens.textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (!isCompact) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: _Tokens.textMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const _TileDivider(),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// Thin brand divider between tiles
class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: _Tokens.divider);
  }
}

// ═══════════════════════════════════════════════════════════════
//  TOGGLE TILE — row tile inside a section card (teal switch)
// ═══════════════════════════════════════════════════════════════
class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.accent,
    required this.accentBg,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.isSaving,
    required this.isCompact,
  });

  final IconData icon;
  final Color accent;
  final Color accentBg;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isSaving;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 12 : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading tinted rounded-square icon
          Container(
            padding: EdgeInsets.all(isCompact ? 9 : 11),
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: isCompact ? 18 : 22, color: accent),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isCompact ? 13.5 : 14.5,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: isCompact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isCompact ? 11.5 : 12.5,
                    color: _Tokens.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 8 : 12),
          // Trailing control
          if (isSaving)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _Tokens.accentDeep,
              ),
            )
          else
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: _Tokens.accent,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: _Tokens.textLight.withValues(alpha: 0.35),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ACTION TILE — row tile w/ trailing button (brand / error red)
// ═══════════════════════════════════════════════════════════════
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.accent,
    required this.accentBg,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
    required this.isCompact,
    this.isDestructive = false,
  });

  final IconData icon;
  final Color accent;
  final Color accentBg;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;
  final bool isCompact;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color btnColor = isDestructive ? _Tokens.danger : _Tokens.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: (isDestructive ? _Tokens.danger : _Tokens.primary)
            .withValues(alpha: 0.04),
        splashColor: btnColor.withValues(alpha: 0.05),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 14 : 20,
            vertical: isCompact ? 12 : 16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 9 : 11),
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: isCompact ? 18 : 22, color: accent),
              ),
              SizedBox(width: isCompact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isCompact ? 13.5 : 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDestructive ? _Tokens.danger : _Tokens.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: isCompact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isCompact ? 11.5 : 12.5,
                        color: _Tokens.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              // Trailing branded button
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 16,
                  vertical: isCompact ? 7 : 9,
                ),
                decoration: BoxDecoration(
                  color: btnColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: btnColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 11.5 : 12.5,
                    color: btnColor,
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

// ═══════════════════════════════════════════════════════════════
//  INFO CARD — Gradient card with explanation
// ═══════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.isCompact,
    required this.delay,
    required this.controller,
  });

  final bool isCompact;
  final int delay;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final animation =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
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
          padding: EdgeInsets.all(isCompact ? 16 : 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _Tokens.primary.withValues(alpha: 0.06),
                _Tokens.accent.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
            border: Border.all(color: _Tokens.accent.withValues(alpha: 0.18)),
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
          const _SkeletonLine(width: 180, height: 24),
          const SizedBox(height: 20),
          _SkeletonCard(),
          const SizedBox(height: 14),
          _SkeletonCard(),
          const SizedBox(height: 36),
          const _SkeletonLine(width: 160, height: 24),
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
        color: _Tokens.primarySoft,
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
        border: Border.all(color: _Tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _Tokens.accentSoft,
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
                    color: _Tokens.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: _Tokens.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 200,
                  decoration: BoxDecoration(
                    color: _Tokens.primarySoft,
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
              // Gradient primary action
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.go('/recruiter-dashboard'),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_Tokens.accent, _Tokens.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _Tokens.accent.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Return to Dashboard',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
  }
}
