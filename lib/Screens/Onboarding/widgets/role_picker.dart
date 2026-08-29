import 'package:flutter/material.dart';

import '../../../core/onboarding/models/aviation_role.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/search_field.dart';

/// Step 1 — pick the industry, then the role whose template drives the rest of
/// onboarding. Roles are grouped by category inside each industry and are
/// searchable across every industry at once.
class RolePicker extends StatefulWidget {
  const RolePicker({
    super.key,
    required this.templates,
    required this.industries,
    required this.industry,
    required this.onIndustryChanged,
    required this.onSelected,
  });

  final List<RoleTemplate> templates;
  final List<String> industries;
  final String? industry;
  final ValueChanged<String> onIndustryChanged;
  final ValueChanged<RoleTemplate> onSelected;

  @override
  State<RolePicker> createState() => _RolePickerState();
}

class _RolePickerState extends State<RolePicker> {
  String _query = '';

  bool get _searching => _query.trim().isNotEmpty;

  List<RoleTemplate> get _visible {
    if (!_searching) {
      return widget.templates
          .where((t) => t.industry == widget.industry)
          .toList();
    }
    // A search spans every industry — a candidate who types "avionics" should
    // not have to guess which tab it lives under.
    final q = _query.toLowerCase();
    return widget.templates
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q) ||
            t.industry.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<RoleTemplate>>{};
    for (final t in _visible) {
      final key = _searching ? '${t.industry} · ${t.category}' : t.category;
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What role are you targeting?',
                      style: AppText.heading(
                          fs: context.isMobile ? 21 : 26, fw: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Your answer picks the form we build for you — every '
                    'question after this is specific to the role.',
                    style: AppText.body(fs: 13.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: SearchField(
                hint: 'Search roles — pilot, avionics, DevOps…',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (!_searching && widget.industries.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final industry in widget.industries)
                      ChoiceChip(
                        // The colour has to live on this Text's own style: a
                        // label widget's style always wins over the chip's
                        // labelStyle, so setting it there left the selected
                        // chip drawing dark text on the indigo fill.
                        label: Text(
                          industry,
                          style: AppText.label(
                            fs: 12.5,
                            fw: FontWeight.w600,
                            color: widget.industry == industry
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                        selected: widget.industry == industry,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        side: BorderSide(
                          color: widget.industry == industry
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 8),
                        onSelected: (_) => widget.onIndustryChanged(industry),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: grouped.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Text('No roles match "$_query".',
                            style: AppText.body(color: AppColors.textMuted)),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0,
                          AppSpacing.xl, AppSpacing.xxl),
                      children: [
                        for (final entry in grouped.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                                top: AppSpacing.md, bottom: AppSpacing.md),
                            child: Text(
                              entry.key.toUpperCase(),
                              style: AppText.label(
                                  fs: 11,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.8,
                                  fw: FontWeight.w700),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (context, c) {
                              final columns =
                                  c.maxWidth >= 860 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
                              const gap = AppSpacing.md;
                              final width =
                                  (c.maxWidth - gap * (columns - 1)) / columns;
                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  for (final r in entry.value)
                                    SizedBox(
                                      width: width,
                                      child: _RoleCard(
                                        role: r,
                                        onTap: () => widget.onSelected(r),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({required this.role, required this.onTap});
  final RoleTemplate role;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.role.description;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppRadius.cardRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
                color: _hover ? AppColors.primary : AppColors.border),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(_iconFor(widget.role),
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.role.title,
                        style:
                            AppText.heading(fs: 13.5, fw: FontWeight.w700)),
                    // No field count here — how long the form is shouldn't
                    // steer which role someone picks. If a template has no
                    // description we simply show nothing.
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppText.body(fs: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18,
                  color: _hover ? AppColors.primary : AppColors.textFaint),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(RoleTemplate r) {
    final c = r.category.toLowerCase();
    if (c.contains('flight crew')) return Icons.flight_takeoff_rounded;
    if (c.contains('instruction')) return Icons.school_rounded;
    if (c.contains('maintenance')) return Icons.build_rounded;
    if (c.contains('safety')) return Icons.health_and_safety_rounded;
    if (c.contains('cabin')) return Icons.airline_seat_recline_normal_rounded;
    if (c.contains('air traffic')) return Icons.radar_rounded;
    if (c.contains('ground')) return Icons.local_shipping_rounded;
    if (c.contains('operations') || c.contains('dispatch')) {
      return Icons.route_rounded;
    }
    if (c.contains('security')) return Icons.shield_rounded;
    if (c.contains('management')) return Icons.corporate_fare_rounded;
    if (c.contains('software')) return Icons.code_rounded;
    if (c.contains('platform') || c.contains('infrastructure')) {
      return Icons.dns_rounded;
    }
    if (c.contains('data')) return Icons.insights_rounded;
    if (c.contains('quality')) return Icons.verified_rounded;
    return Icons.work_outline_rounded;
  }
}
