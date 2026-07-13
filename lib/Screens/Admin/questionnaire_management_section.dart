import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/onboarding/models/aviation_role.dart';
import '../../core/onboarding/models/question.dart';
import '../../core/onboarding/questionnaire_service.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import 'widgets/admin_header.dart';

/// Admin manager for the onboarding questionnaire: seed defaults, add/edit/
/// delete aviation roles and their questions, then publish to Firestore.
class QuestionnaireManagementSection extends StatefulWidget {
  const QuestionnaireManagementSection({super.key});

  @override
  State<QuestionnaireManagementSection> createState() =>
      _QuestionnaireManagementSectionState();
}

class _QuestionnaireManagementSectionState
    extends State<QuestionnaireManagementSection> {
  final _service = QuestionnaireService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _dirty = false;

  List<AviationRole> _roles = [];
  String? _selectedRoleId;

  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _primary = Color(0xFF6366F1);

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
      // Work on a mutable copy.
      setState(() {
        _roles = roles.map((r) => r.copyWith(questions: [...r.questions])).toList();
        _selectedRoleId = _roles.isNotEmpty ? _roles.first.id : null;
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

  Future<void> _seed() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Seed default catalogue?',
      message:
          'This overwrites the current questionnaire config with the built-in '
          'default aviation roles and questions.',
      confirmLabel: 'Seed defaults',
      danger: true,
    );
    if (!ok) return;
    setState(() => _saving = true);
    try {
      await _service.seedDefaults();
      await _load();
    } catch (e) {
      if (mounted) _snack('Seed failed: $e');
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
        _snack('Questionnaire published');
      }
    } catch (e) {
      if (mounted) _snack('Publish failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

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
      color: const Color(0xFFF6F7FB),
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
                colors: [Color(0xFF7C3AED), Color(0xFF6366F1), Color(0xFF2563EB)],
              ),
              stats: [
                AdminHeaderStat('roles', '${_roles.length}',
                    icon: Icons.badge_outlined),
                AdminHeaderStat('questions', '$totalQuestions',
                    icon: Icons.help_outline_rounded),
                if (_dirty)
                  const AdminHeaderStat('unpublished', '•',
                      icon: Icons.edit_rounded),
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
                  ? _questionsPanel()
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

  // Deterministic accent color per category for visual grouping.
  static const _categoryColors = [
    Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF14B8A6), Color(0xFFEF4444),
  ];
  Color _categoryColor(String category) =>
      _categoryColors[category.hashCode.abs() % _categoryColors.length];

  Widget _rolesPanel() {
    // Group roles by category, preserving order.
    final byCategory = <String, List<AviationRole>>{};
    for (final r in _roles) {
      byCategory.putIfAbsent(r.category, () => []).add(r);
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EDF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          for (final entry in byCategory.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
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
                        fontWeight: FontWeight.w700,
                        color: _muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text('${entry.value.length}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: _muted)),
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
      child: Material(
        color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _selectedRoleId = r.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color.withValues(alpha: 0.4) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.work_outline_rounded, size: 15, color: color),
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
                              fontWeight: FontWeight.w600,
                              color: _ink)),
                      Text('${r.questions.length} questions',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: _muted)),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 17, color: Color(0xFF94A3B8)),
                  onPressed: () => _deleteRole(r),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionsPanel() {
    final role = _selected;
    if (role == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9EDF5)),
        ),
        child: const EmptyState(
          icon: Icons.quiz_outlined,
          title: 'No role selected',
          subtitle: 'Add or select a role to edit its questions.',
        ),
      );
    }
    final color = _categoryColor(role.category);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EDF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
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
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ink)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(role.category,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color)),
                          ),
                          const SizedBox(width: 8),
                          Text('${role.questions.length} questions',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: _muted)),
                        ],
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _primary),
                  onPressed: () => _editQuestion(role, null),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add question'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDF1F7)),
          Expanded(
            child: role.questions.isEmpty
                ? const EmptyState(
                    icon: Icons.help_outline_rounded,
                    title: 'No questions',
                    subtitle: 'Add the first question for this role.',
                    compact: true,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF1F7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${index + 1}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6366F1))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _ink)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _tag(_typeLabel(q.type), const Color(0xFF6366F1)),
                    if (q.group != null)
                      _tag(q.group!, const Color(0xFF0EA5E9)),
                    if (q.required)
                      _tag('required', const Color(0xFFEF4444)),
                    if (q.options.isNotEmpty)
                      _tag('${q.options.length} options',
                          const Color(0xFF10B981)),
                    if (q.unit != null) _tag(q.unit!, const Color(0xFF8B5CF6)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 17, color: Color(0xFF6366F1)),
            onPressed: () => _editQuestion(role, q),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 17, color: Color(0xFFEF4444)),
            onPressed: () => _deleteQuestion(role, q),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
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
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> _addRole() async {
    final result = await _roleMetaDialog();
    if (result == null) return;
    final id = result.$1;
    if (_roles.any((r) => r.id == id)) {
      _snack('A role with id "$id" already exists.');
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
      builder: (ctx) => AlertDialog(
        title: const Text('Add role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idC,
              decoration: const InputDecoration(
                  labelText: 'Role id (slug, e.g. flight_planner)'),
            ),
            TextField(
              controller: titleC,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: catC,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final id = idC.text.trim().toLowerCase().replaceAll(' ', '_');
              if (id.isEmpty || titleC.text.trim().isEmpty) return;
              Navigator.pop(
                  ctx, (id, titleC.text.trim(), catC.text.trim()));
            },
            child: const Text('Add'),
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

    return showDialog<OnboardingQuestion>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add question' : 'Edit question'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: idC,
                    enabled: existing == null,
                    decoration: const InputDecoration(
                        labelText: 'Question id (unique key)'),
                  ),
                  TextField(
                    controller: labelC,
                    decoration: const InputDecoration(labelText: 'Label'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<QuestionType>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: QuestionType.values
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t.name)))
                        .toList(),
                    onChanged: (v) => setLocal(() => type = v ?? type),
                  ),
                  TextField(
                    controller: groupC,
                    decoration:
                        const InputDecoration(labelText: 'Group (page)'),
                  ),
                  TextField(
                    controller: helpC,
                    decoration:
                        const InputDecoration(labelText: 'Help text (optional)'),
                  ),
                  if (type == QuestionType.number)
                    TextField(
                      controller: unitC,
                      decoration:
                          const InputDecoration(labelText: 'Unit (optional)'),
                    ),
                  if (type == QuestionType.singleSelect ||
                      type == QuestionType.multiSelect)
                    TextField(
                      controller: optionsC,
                      decoration: const InputDecoration(
                          labelText: 'Options (comma-separated)'),
                    ),
                  SwitchListTile(
                    value: required,
                    onChanged: (v) => setLocal(() => required = v),
                    title: const Text('Required'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final id = idC.text.trim();
                if (id.isEmpty || labelC.text.trim().isEmpty) return;
                final options = optionsC.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
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
                    unit: unitC.text.trim().isEmpty ? null : unitC.text.trim(),
                    options: options,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
