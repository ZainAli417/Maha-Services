import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/onboarding/models/aviation_role.dart';
import '../../core/onboarding/models/question.dart';
import '../../core/onboarding/questionnaire_service.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';

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
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toolbar(),
          const SizedBox(height: 16),
          Expanded(
            child: isMobile
                ? _questionsPanel()
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 280, child: _rolesPanel()),
                      const SizedBox(width: 16),
                      Expanded(child: _questionsPanel()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('${_roles.length} roles',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, color: _ink)),
        if (_dirty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('Unpublished changes',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB45309))),
          ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _saving ? null : _seed,
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Seed defaults'),
        ),
        OutlinedButton.icon(
          onPressed: _saving ? null : _addRole,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add role'),
        ),
        ElevatedButton.icon(
          onPressed: (_saving || !_dirty) ? null : _publish,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.publish_rounded, size: 16),
          label: const Text('Publish'),
        ),
      ],
    );
  }

  Widget _rolesPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _roles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 2),
        itemBuilder: (_, i) {
          final r = _roles[i];
          final selected = r.id == _selectedRoleId;
          return Material(
            color: selected ? const Color(0xFFEEF2FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              dense: true,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: Text(r.title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
              subtitle: Text('${r.category} · ${r.questions.length} questions',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: _muted)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                onPressed: () => _deleteRole(r),
              ),
              onTap: () => setState(() => _selectedRoleId = r.id),
            ),
          );
        },
      ),
    );
  }

  Widget _questionsPanel() {
    final role = _selected;
    if (role == null) {
      return const EmptyState(
        icon: Icons.quiz_outlined,
        title: 'No role selected',
        subtitle: 'Add or select a role to edit its questions.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.title,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      Text(role.category,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: _muted)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _editQuestion(role, null),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add question'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _border),
          Expanded(
            child: role.questions.isEmpty
                ? const EmptyState(
                    icon: Icons.help_outline_rounded,
                    title: 'No questions',
                    subtitle: 'Add the first question for this role.',
                    compact: true,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: role.questions.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (_, i) {
                      final q = role.questions[i];
                      return ListTile(
                        dense: true,
                        title: Text(q.label,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _ink)),
                        subtitle: Text(
                          '${q.type.name}'
                          '${q.group != null ? ' · ${q.group}' : ''}'
                          '${q.required ? ' · required' : ''}'
                          '${q.options.isNotEmpty ? ' · ${q.options.length} options' : ''}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: _muted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _editQuestion(role, q),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18),
                              onPressed: () => _deleteQuestion(role, q),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
