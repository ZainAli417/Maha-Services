import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/onboarding/cv_extraction_service.dart';
import '../../../core/onboarding/models/aviation_role.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Picks a document and returns its bytes. `withData: true` keeps the read in
/// memory on every platform, so no `dart:io` path is needed for web builds.
Future<({Uint8List bytes, String name})?> pickDocument({
  List<String> extensions = const ['pdf', 'doc', 'docx', 'txt'],
}) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: extensions,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) return null;
  return (bytes: bytes, name: file.name);
}

/// Step 2 — upload a CV for automatic extraction, or go straight to the form.
class EntryModeStep extends StatefulWidget {
  const EntryModeStep({
    super.key,
    required this.template,
    required this.onManual,
    required this.onCvPicked,
    required this.onChangeRole,
  });

  final RoleTemplate template;
  final VoidCallback onManual;
  final void Function(Uint8List bytes, String filename) onCvPicked;
  final VoidCallback onChangeRole;

  @override
  State<EntryModeStep> createState() => _EntryModeStepState();
}

class _EntryModeStepState extends State<EntryModeStep> {
  String? _error;

  Future<void> _pick() async {
    setState(() => _error = null);
    try {
      final picked = await pickDocument();
      if (picked == null) return;
      if (!CvExtractionService.isSupported(picked.name)) {
        setState(() => _error = 'Upload a PDF, DOC, DOCX or TXT file.');
        return;
      }
      if (picked.bytes.length > 10 * 1024 * 1024) {
        setState(() => _error = 'That file is over the 10MB limit.');
        return;
      }
      widget.onCvPicked(picked.bytes, picked.name);
    } catch (e) {
      setState(() => _error = 'Could not read that file. Try another.');
      debugPrint('⚠️ pickDocument: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    final cards = [
      _MethodCard(
        icon: Icons.auto_awesome_rounded,
        title: 'Upload your CV',
        subtitle:
            'We read it and fill in what we can find. You review everything '
            'before it is saved.',
        badge: 'Fastest',
        primary: true,
        onTap: _pick,
      ),
      _MethodCard(
        icon: Icons.edit_note_rounded,
        title: 'Fill in manually',
        subtitle:
            'Go straight to the ${widget.template.title} form. '
            'Mostly dropdowns and checkboxes — very little typing.',
        onTap: widget.onManual,
      ),
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How would you like to start?',
                            style: AppText.heading(
                                fs: isMobile ? 20 : 25, fw: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          'Building your ${widget.template.title} profile.',
                          style: AppText.body(
                              fs: 13.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onChangeRole,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('Change role'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_error != null) ...[
                _InlineError(message: _error!),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (isMobile)
                Column(
                  children: [
                    for (final c in cards) ...[
                      c,
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                )
              else
                // IntrinsicHeight is what makes `stretch` legal here. Inside a
                // SingleChildScrollView the Row's maxHeight is infinite, and a
                // stretching Row hands its children tightFor(height: infinity)
                // — the cards then lay out to no valid size, which surfaces as
                // "Cannot hit test a render box with no size" on every mouse
                // move. IntrinsicHeight measures the taller card first so the
                // Row stretches to a finite height, which is the equal-height
                // behaviour we wanted from `stretch` in the first place.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: cards[1]),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 14, color: AppColors.textFaint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your CV is used only to pre-fill this form. Nothing is '
                      'shared with recruiters until you submit.',
                      style:
                          AppText.body(fs: 11.5, color: AppColors.textFaint),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatefulWidget {
  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final bool primary;

  @override
  State<_MethodCard> createState() => _MethodCardState();
}

class _MethodCardState extends State<_MethodCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.primary ? AppColors.primary : AppColors.textSecondary;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppRadius.lgRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: _hover || widget.primary
                  ? AppColors.primary
                  : AppColors.border,
              width: widget.primary ? 1.5 : 1,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: widget.primary
                          ? const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent])
                          : null,
                      color: widget.primary ? null : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(widget.icon,
                        size: 20,
                        color: widget.primary ? Colors.white : accent),
                  ),
                  const Spacer(),
                  if (widget.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(widget.badge!,
                          style: AppText.label(
                              fs: 10,
                              color: AppColors.primary,
                              fw: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(widget.title,
                  style: AppText.heading(fs: 16, fw: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(widget.subtitle,
                  style: AppText.body(
                      fs: 12.5, color: AppColors.textMuted, height: 1.45)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen state while Gemini reads the CV against the role schema.
class ExtractionProgress extends StatelessWidget {
  const ExtractionProgress({super.key, required this.filename});

  final String filename;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PulsingIcon(),
              const SizedBox(height: AppSpacing.xl),
              Text('Reading your CV',
                  style: AppText.heading(fs: 18, fw: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(fs: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              const LinearProgressIndicator(
                minHeight: 5,
                backgroundColor: AppColors.surfaceAlt,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Matching what we find against the fields for this role. '
                'This usually takes under a minute.',
                textAlign: TextAlign.center,
                style: AppText.body(
                    fs: 12, color: AppColors.textFaint, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon();

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.92, end: 1.06).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent]),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.auto_awesome_rounded,
            color: Colors.white, size: 28),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: AppText.body(fs: 12.5, color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
