import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:job_portal/Constant/brand_snackbar.dart';

import '../../core/onboarding/models/aviation_role.dart';
import '../../core/onboarding/models/question.dart';
import '../../core/onboarding/role_template_service.dart';
import '../../core/onboarding/role_templates.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import 'widgets/admin_header.dart';

/// Navy + teal brand tokens shared across this screen's content and dialogs.
class _C {
  static const hero = Color(0xFF061C31);
  static const heroAlt = Color(0xFF0A2E4F);
  static const navy = Color(0xFF14507F);
  static const deepNavy = Color(0xFF0A2E4F);
  static const blue = Color(0xFF2178B5);
  static const teal = Color(0xFF2EC4B6);
  static const tealDeep = Color(0xFF15A99C);
  static const coral = Color(0xFFFF7A59);
  static const amber = Color(0xFFFFB020);
  static const ink = Color(0xFF0B2239);
  static const slate = Color(0xFF3E5C76);
  static const muted = Color(0xFF5E7A8E);
  static const faint = Color(0xFF8AA5B5);
  static const border = Color(0xFFDCE7EF);
  static const bgSoft = Color(0xFFF4F9FB);
  static const tealTint = Color(0xFFE4F6F4);
  static const navyTint = Color(0xFFE8F1F8);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
}

/// Admin manager for the role templates that drive onboarding: seed
/// defaults, add/edit/
/// delete aviation roles and their questions, then publish to Firestore.
class RoleTemplateManagementSection extends StatefulWidget {
  const RoleTemplateManagementSection({super.key});

  @override
  State<RoleTemplateManagementSection> createState() =>
      _RoleTemplateManagementSectionState();
}

class _RoleTemplateManagementSectionState
    extends State<RoleTemplateManagementSection> {
  final _service = RoleTemplateService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _dirty = false;

  List<AviationRole> _roles = [];
  String? _selectedRoleId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roles = await _service.loadRoles(forceRefresh: true);
      final version = await _service.seededVersion();
      // Work on a mutable copy.
      setState(() {
        _roles = roles.map((r) => r.copyWith(questions: [...r.questions])).toList();
        _selectedRoleId = _roles.isNotEmpty ? _roles.first.id : null;
        _seededVersion = version;
        _loading = false;
        _dirty = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  AviationRole? get _selected {
    if (_selectedRoleId == null) return null;
    for (final r in _roles) {
      if (r.id == _selectedRoleId) return r;
    }
    return null;
  }

  void _replaceSelected(AviationRole updated) {
    setState(() {
      _roles = _roles.map((r) => r.id == updated.id ? updated : r).toList();
      _dirty = true;
    });
  }

  /// Seed version already persisted, so the header can tell an admin their
  /// config predates the current built-in templates.
  int? _seededVersion;

  Future<void> _seed() async {
    final stale = _seededVersion != null &&
        _seededVersion! < RoleTemplateCatalogue.seedVersion;
    final ok = await ConfirmDialog.show(
      context,
      title: 'Seed default catalogue?',
      message: stale
          ? 'Your saved config is at version $_seededVersion; the built-in '
              'templates are at version ${RoleTemplateCatalogue.seedVersion}. '
              'Seeding replaces the current config — including any edits you '
              'have published — with the built-in role templates.'
          : 'This overwrites the current questionnaire config with the '
              'built-in default role templates and questions.',
      confirmLabel: 'Seed defaults',
      danger: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await _service.seedDefaults();
      await _load();
    } catch (e) {
      if (mounted) BrandSnack.error(context, 'Seed failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish() async {
    setState(() => _saving = true);
    try {
      await _service.saveRoles(_roles);
      if (mounted) {
        setState(() => _dirty = false);
        BrandSnack.success(context, 'Questionnaire published');
      }
    } catch (e) {
      if (mounted) BrandSnack.error(context, 'Publish failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (_loading) {
      return const LoadingView(message: 'Loading questionnaire config…');
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final totalQuestions =
        _roles.fold<int>(0, (sum, r) => sum + r.questions.length);
    return Container(
      color: _C.bgSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, isMobile ? 12 : 24,
                isMobile ? 12 : 24, 0),
            child: AdminGradientHeader(
              icon: Icons.quiz_rounded,
              title: 'Onboarding Questionnaires',
              subtitle:
                  'Manage aviation roles and the questions each one asks.',
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.hero, _C.navy, _C.tealDeep],
              ),
              stats: [
                AdminHeaderStat('roles', '${_roles.length}',
                    icon: Icons.badge_outlined),
                AdminHeaderStat('questions', '$totalQuestions',
                    icon: Icons.help_outline_rounded),
                if (_dirty)
                  const AdminHeaderStat('unpublished', '•',
                      icon: Icons.edit_rounded),
                if (_seededVersion != null &&
                    _seededVersion! < RoleTemplateCatalogue.seedVersion)
                  AdminHeaderStat('seed v$_seededVersion — update available',
                      'v${RoleTemplateCatalogue.seedVersion}',
                      icon: Icons.system_update_alt_rounded),
              ],
              actions: [
                AdminHeaderButton(
                  icon: Icons.download_rounded,
                  label: 'Seed defaults',
                  onPressed: _saving ? null : _seed,
                ),
                AdminHeaderButton(
                  icon: Icons.add_rounded,
                  label: 'Add role',
                  onPressed: _saving ? null : _addRole,
                ),
                AdminHeaderButton(
                  icon: Icons.publish_rounded,
                  label: _dirty ? 'Publish changes' : 'Published',
                  filled: true,
                  busy: _saving,
                  onPressed: (_saving || !_dirty) ? null : _publish,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 24, 0, isMobile ? 12 : 24, isMobile ? 12 : 24),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _mobileRoleSelector(),
                        const SizedBox(height: 12),
                        Expanded(child: _questionsPanel()),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 300, child: _rolesPanel()),
                        const SizedBox(width: 16),
                        Expanded(child: _questionsPanel()),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Deterministic accent color per category for visual grouping (brand hues).
  static const _categoryColors = [
    _C.navy, _C.blue, _C.teal, _C.tealDeep,
    _C.coral, _C.amber, _C.success, _C.deepNavy,
  ];
  Color _categoryColor(String category) =>
      _categoryColors[category.hashCode.abs() % _categoryColors.length];

  // Shared card decoration for the two side panels.
  BoxDecoration get _panelDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: _C.ink.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      );

  /// Horizontal role picker shown on compact (mobile) layouts where the side
  /// panel is hidden.
  Widget _mobileRoleSelector() {
    if (_roles.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _roles.length,
        cacheExtent: 700,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final r = _roles[i];
          final selected = r.id == _selectedRoleId;
          final color = _categoryColor(r.category);
          return Material(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: () => setState(() => _selectedRoleId = r.id),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? color.withValues(alpha: 0.45)
                        : _C.border,
                    width: selected ? 1.4 : 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work_outline_rounded,
                        size: 15,
                        color: selected ? color : _C.faint),
                    const SizedBox(width: 7),
                    Text(
                      r.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? color : _C.slate,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rolesPanel() {
    // Group roles by category, preserving order.
    final byCategory = <String, List<AviationRole>>{};
    for (final r in _roles) {
      byCategory.putIfAbsent(r.category, () => []).add(r);
    }
    return Container(
      decoration: _panelDecoration,
      child: ListView(
        padding: const EdgeInsets.all(10),
        cacheExtent: 700,
        children: [
          for (final entry in byCategory.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _categoryColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _C.tealDeep,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Text('${entry.value.length}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _C.faint)),
                ],
              ),
            ),
            for (final r in entry.value) _roleTile(r),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _roleTile(AviationRole r) {
    final selected = r.id == _selectedRoleId;
    final color = _categoryColor(r.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _Hoverable(
        builder: (hovered) => Material(
          color: selected
              ? color.withValues(alpha: 0.10)
              : (hovered ? _C.bgSoft : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => setState(() => _selectedRoleId = r.id),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      selected ? color.withValues(alpha: 0.35) : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  // Left accent bar on the active row.
                  Container(
                    width: 3,
                    height: 30,
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child:
                        Icon(Icons.work_outline_rounded, size: 15, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _C.ink)),
                        Text('${r.questions.length} questions',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _C.muted)),
                      ],
                    ),
                  ),
                  _iconAction(
                    Icons.delete_outline_rounded,
                    _C.error,
                    () => _deleteRole(r),
                    'Delete role',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionsPanel() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final role = _selected;
    if (role == null) {
      return Container(
        decoration: _panelDecoration,
        child: const EmptyState(
          icon: Icons.quiz_outlined,
          title: 'No role selected',
          subtitle: 'Add or select a role to edit its questions.',
          iconColor: _C.navy,
        ),
      );
    }
    final color = _categoryColor(role.category);
    return Container(
      decoration: _panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.badge_outlined, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 15 : 17,
                              fontWeight: FontWeight.w800,
                              color: _C.ink)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.3)),
                            ),
                            child: Text(role.category,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text('${role.questions.length} questions',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _C.muted)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _GradientButton(
                  label: isMobile ? 'Add' : 'Add question',
                  icon: Icons.add_rounded,
                  onPressed: () => _editQuestion(role, null),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _C.border),
          Expanded(
            child: role.questions.isEmpty
                ? EmptyState(
                    icon: Icons.help_outline_rounded,
                    title: 'No questions',
                    subtitle: 'Add the first question for this role.',
                    iconColor: _C.teal,
                    compact: true,
                    action: _GradientButton(
                      label: 'Add question',
                      icon: Icons.add_rounded,
                      onPressed: () => _editQuestion(role, null),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(isMobile ? 10 : 12),
                    cacheExtent: 700,
                    itemCount: role.questions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _questionCard(role, role.questions[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(AviationRole role, OnboardingQuestion q, int index) {
    final color = _categoryColor(role.category);
    return RepaintBoundary(
      child: _Hoverable(
        builder: (hovered) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          transform:
              Matrix4.translationValues(0, hovered ? -3 : 0, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hovered ? _C.teal.withValues(alpha: 0.5) : _C.border,
            ),
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: _C.teal.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text('${index + 1}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.label,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _C.ink)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tag(_typeLabel(q.type), _C.navy),
                        if (q.group != null) _tag(q.group!, _C.blue),
                        if (q.required) _tag('required', _C.error),
                        if (q.options.isNotEmpty)
                          _tag('${q.options.length} options', _C.tealDeep),
                        if (q.unit != null) _tag(q.unit!, _C.amber),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _iconAction(Icons.edit_outlined, _C.navy,
                  () => _editQuestion(role, q), 'Edit question'),
              const SizedBox(width: 6),
              _iconAction(Icons.delete_outline_rounded, _C.error,
                  () => _deleteQuestion(role, q), 'Delete question'),
            ],
          ),
        ),
      ),
    );
  }

  // Small tinted square icon action button.
  Widget _iconAction(
      IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
    );
  }

  String _typeLabel(QuestionType t) {
    switch (t) {
      case QuestionType.text:
        return 'Text';
      case QuestionType.longText:
        return 'Long text';
      case QuestionType.number:
        return 'Number';
      case QuestionType.singleSelect:
        return 'Single select';
      case QuestionType.multiSelect:
        return 'Multi select';
      case QuestionType.boolean:
        return 'Yes / No';
      case QuestionType.date:
        return 'Date';
      case QuestionType.searchSelect:
        return 'Searchable select';
      case QuestionType.searchMultiSelect:
        return 'Searchable multi-select';
      case QuestionType.tags:
        return 'Tags';
      case QuestionType.monthYear:
        return 'Month / year';
      case QuestionType.yesNoDetail:
        return 'Yes / No + details';
      case QuestionType.file:
        return 'File upload';
      case QuestionType.phone:
        return 'Phone (country code + number)';
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> _addRole() async {
    final result = await _roleMetaDialog();
    if (result == null) return;
    final id = result.$1;
    if (_roles.any((r) => r.id == id)) {
      BrandSnack.warning(context, 'A role with id "$id" already exists.');
      return;
    }
    setState(() {
      _roles = [
        ..._roles,
        AviationRole(id: id, title: result.$2, category: result.$3),
      ];
      _selectedRoleId = id;
      _dirty = true;
    });
  }

  Future<void> _deleteRole(AviationRole r) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete role?',
      message: 'Remove "${r.title}" and all its questions from the config.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok) return;
    setState(() {
      _roles = _roles.where((x) => x.id != r.id).toList();
      if (_selectedRoleId == r.id) {
        _selectedRoleId = _roles.isNotEmpty ? _roles.first.id : null;
      }
      _dirty = true;
    });
  }

  Future<void> _deleteQuestion(AviationRole role, OnboardingQuestion q) async {
    _replaceSelected(role.copyWith(
      questions: role.questions.where((x) => x.id != q.id).toList(),
    ));
  }

  Future<void> _editQuestion(
      AviationRole role, OnboardingQuestion? existing) async {
    final result = await _questionDialog(existing);
    if (result == null) return;
    final list = [...role.questions];
    final idx = list.indexWhere((x) => x.id == result.id);
    if (idx >= 0) {
      list[idx] = result;
    } else {
      list.add(result);
    }
    _replaceSelected(role.copyWith(questions: list));
  }

  /// Returns (id, title, category) or null.
  Future<(String, String, String)?> _roleMetaDialog() async {
    final idC = TextEditingController();
    final titleC = TextEditingController();
    final catC = TextEditingController(text: 'Other');
    return showDialog<(String, String, String)>(
      context: context,
      builder: (ctx) => _DialogScaffold(
        icon: Icons.badge_outlined,
        title: 'Add role',
        subtitle: 'Create a new aviation role to hold questions.',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _labelledField(
              label: 'Role id',
              required: true,
              hint: 'slug, e.g. flight_planner',
              controller: idC,
              icon: Icons.tag_rounded,
            ),
            const SizedBox(height: 16),
            _labelledField(
              label: 'Title',
              required: true,
              hint: 'e.g. Flight Planner',
              controller: titleC,
              icon: Icons.title_rounded,
            ),
            const SizedBox(height: 16),
            _labelledField(
              label: 'Category',
              hint: 'e.g. Operations',
              controller: catC,
              icon: Icons.category_outlined,
            ),
          ],
        ),
        actions: [
          _GhostButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: 10),
          _GradientButton(
            label: 'Add role',
            onPressed: () {
              final id = idC.text.trim().toLowerCase().replaceAll(' ', '_');
              if (id.isEmpty || titleC.text.trim().isEmpty) return;
              Navigator.pop(ctx, (id, titleC.text.trim(), catC.text.trim()));
            },
          ),
        ],
      ),
    );
  }

  Future<OnboardingQuestion?> _questionDialog(
      OnboardingQuestion? existing) async {
    final idC = TextEditingController(text: existing?.id);
    final labelC = TextEditingController(text: existing?.label);
    final groupC = TextEditingController(text: existing?.group);
    final helpC = TextEditingController(text: existing?.helpText);
    final unitC = TextEditingController(text: existing?.unit);
    final optionsC =
        TextEditingController(text: existing?.options.join(', ') ?? '');
    var type = existing?.type ?? QuestionType.text;
    var required = existing?.required ?? false;

    List<String> parsedOptions() => optionsC.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return showDialog<OnboardingQuestion>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final needsOptions = type.isSelect;
          return _DialogScaffold(
            icon: existing == null
                ? Icons.add_circle_outline_rounded
                : Icons.edit_outlined,
            title: existing == null ? 'Add question' : 'Edit question',
            subtitle: existing == null
                ? 'Define a new question for this role.'
                : 'Update the details of this question.',
            body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labelledField(
                  label: 'Question id',
                  required: true,
                  hint: 'unique key',
                  controller: idC,
                  enabled: existing == null,
                  icon: Icons.key_rounded,
                ),
                const SizedBox(height: 16),
                _labelledField(
                  label: 'Label',
                  required: true,
                  hint: 'The question shown to applicants',
                  controller: labelC,
                  icon: Icons.short_text_rounded,
                ),
                const SizedBox(height: 16),
                _FieldLabel(text: 'Question type'),
                const SizedBox(height: 8),
                _TypeSelector(
                  selected: type,
                  labelFor: _typeLabel,
                  onChanged: (t) => setLocal(() => type = t),
                ),
                const SizedBox(height: 16),
                _labelledField(
                  label: 'Group (page)',
                  hint: 'Optional section grouping',
                  controller: groupC,
                  icon: Icons.layers_outlined,
                ),
                const SizedBox(height: 16),
                _labelledField(
                  label: 'Help text',
                  hint: 'Optional guidance shown under the field',
                  controller: helpC,
                  icon: Icons.help_outline_rounded,
                ),
                if (type == QuestionType.number) ...[
                  const SizedBox(height: 16),
                  _labelledField(
                    label: 'Unit',
                    hint: 'Optional, e.g. hours, kg',
                    controller: unitC,
                    icon: Icons.straighten_rounded,
                  ),
                ],
                if (needsOptions) ...[
                  const SizedBox(height: 16),
                  _labelledField(
                    label: 'Options',
                    required: true,
                    hint: 'Comma-separated, e.g. Yes, No, Maybe',
                    controller: optionsC,
                    icon: Icons.list_rounded,
                    onChanged: (_) => setLocal(() {}),
                  ),
                  if (parsedOptions().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final o in parsedOptions())
                          _tag(o, _C.tealDeep),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                _RequiredToggle(
                  value: required,
                  onChanged: (v) => setLocal(() => required = v),
                ),
              ],
            ),
            actions: [
              _GhostButton(
                label: 'Cancel',
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(width: 10),
              _GradientButton(
                label: existing == null ? 'Add question' : 'Save changes',
                icon: Icons.check_rounded,
                onPressed: () {
                  final id = idC.text.trim();
                  if (id.isEmpty || labelC.text.trim().isEmpty) return;
                  Navigator.pop(
                    ctx,
                    OnboardingQuestion(
                      id: id,
                      label: labelC.text.trim(),
                      type: type,
                      required: required,
                      group: groupC.text.trim().isEmpty
                          ? null
                          : groupC.text.trim(),
                      helpText:
                          helpC.text.trim().isEmpty ? null : helpC.text.trim(),
                      unit:
                          unitC.text.trim().isEmpty ? null : unitC.text.trim(),
                      options: parsedOptions(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  /// A labelled, branded text field used across the dialogs.
  Widget _labelledField({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? icon,
    bool required = false,
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label, required: required),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: enabled ? _C.ink : _C.muted,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _C.muted,
            ),
            isDense: true,
            filled: true,
            fillColor: enabled ? Colors.white : _C.bgSoft,
            prefixIcon: icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(icon, size: 18, color: _C.tealDeep),
                  ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.navy, width: 1.6),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.border, width: 1.2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.border, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable branded dialog primitives ───────────────────────────────────────

/// A rounded, branded dialog shell: gradient icon badge header, scrollable
/// body and a bottom actions row.
class _DialogScaffold extends StatelessWidget {
  const _DialogScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    return Dialog(
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header strip.
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 10, 16),
              decoration: const BoxDecoration(
                color: _C.bgSoft,
                border: Border(bottom: BorderSide(color: _C.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_C.teal, _C.navy],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _C.teal.withValues(alpha: 0.32),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _C.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _C.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: _C.muted),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: body,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration:
                  const BoxDecoration(color: Colors.white, border: Border(
                top: BorderSide(color: _C.border),
              )),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A field label with an optional coral required-asterisk.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _C.slate,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _C.coral,
            ),
          ),
      ],
    );
  }
}

/// Wrap of selectable chips for choosing a question type.
class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.labelFor,
    required this.onChanged,
  });

  final QuestionType selected;
  final String Function(QuestionType) labelFor;
  final ValueChanged<QuestionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in QuestionType.values)
          _TypeChip(
            label: labelFor(t),
            selected: t == selected,
            onTap: () => onChanged(t),
          ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _C.navy.withValues(alpha: 0.10) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _C.navy : _C.border,
              width: selected ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, size: 15, color: _C.navy),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? _C.navy : _C.slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Branded "Required" toggle row.
class _RequiredToggle extends StatelessWidget {
  const _RequiredToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        color: _C.bgSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, size: 18, color: _C.tealDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Required field',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.ink,
                  ),
                ),
                Text(
                  'Applicants must answer this question',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _C.muted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _C.teal,
          ),
        ],
      ),
    );
  }
}

/// Ghost (secondary) button: navy text + navy border.
class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _C.navy,
        side: const BorderSide(color: _C.navy, width: 1.4),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Gradient primary button (teal→navy), or a red destructive variant.
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final gradient = danger
        ? const LinearGradient(colors: [Color(0xFFF87171), _C.error])
        : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_C.teal, _C.navy],
          );
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled ? gradient : null,
            color: enabled ? null : _C.border,
            borderRadius: BorderRadius.circular(12),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: (danger ? _C.error : _C.teal)
                          .withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

/// Provides a hover flag to its [builder] for web hover-lift affordances.
class _Hoverable extends StatefulWidget {
  const _Hoverable({required this.builder});
  final Widget Function(bool hovered) builder;

  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(_hovered),
    );
  }
}
