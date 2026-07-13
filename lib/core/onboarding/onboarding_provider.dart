import 'package:flutter/foundation.dart';

import 'models/aviation_role.dart';
import 'models/question.dart';
import 'questionnaire_service.dart';

/// Drives the dynamic onboarding wizard: role selection, per-group question
/// pages, answer capture, conditional visibility, auto-save and resume.
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({QuestionnaireService? service})
      : _service = service ?? QuestionnaireService();

  final QuestionnaireService _service;

  bool loading = true;
  bool saving = false;
  String? error;

  List<AviationRole> roles = [];
  AviationRole? _role;
  AviationRole? get role => _role;

  final Map<String, dynamic> answers = {};

  /// Ordered group/page keys for the selected role.
  List<String> _pages = [];
  List<String> get pages => _pages;
  int step = 0;

  String? _uid;

  /// Loads config + any saved progress for [uid] and prepares the wizard.
  Future<void> init(String uid) async {
    _uid = uid;
    loading = true;
    error = null;
    notifyListeners();
    try {
      roles = await _service.loadRoles();
      final progress = await _service.loadProgress(uid);
      if (progress?.roleId != null) {
        final match = roles.where((r) => r.id == progress!.roleId);
        if (match.isNotEmpty) {
          _selectRoleInternal(match.first);
          answers
            ..clear()
            ..addAll(progress!.answers);
          step = progress.stepIndex.clamp(0, _pages.isEmpty ? 0 : _pages.length - 1);
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _selectRoleInternal(AviationRole r) {
    _role = r;
    // Ordered unique group names; questions with no group go under "General".
    final seen = <String>[];
    for (final q in r.questions) {
      final g = q.group ?? 'General';
      if (!seen.contains(g)) seen.add(g);
    }
    _pages = seen;
    step = 0;
  }

  void selectRole(AviationRole r) {
    _selectRoleInternal(r);
    answers.clear();
    notifyListeners();
    _autoSave();
  }

  /// Questions on the current page whose conditional dependency is satisfied.
  List<OnboardingQuestion> questionsForCurrentPage() {
    if (_role == null || _pages.isEmpty) return const [];
    final group = _pages[step];
    return _role!.questions
        .where((q) => (q.group ?? 'General') == group)
        .where(_isVisible)
        .toList();
  }

  bool _isVisible(OnboardingQuestion q) {
    if (q.dependsOnId == null) return true;
    final dep = answers[q.dependsOnId];
    if (q.dependsOnValue == null) return dep != null;
    return dep?.toString() == q.dependsOnValue;
  }

  double get progress =>
      _pages.isEmpty ? 0 : (step + 1) / _pages.length;

  bool get isFirst => step == 0;
  bool get isLast => _pages.isEmpty || step >= _pages.length - 1;

  void setAnswer(String id, dynamic value) {
    if (value == null || (value is String && value.isEmpty)) {
      answers.remove(id);
    } else {
      answers[id] = value;
    }
    notifyListeners();
  }

  dynamic answer(String id) => answers[id];

  Future<void> next() async {
    if (!isLast) {
      step++;
      notifyListeners();
      await _autoSave();
    }
  }

  Future<void> previous() async {
    if (!isFirst) {
      step--;
      notifyListeners();
      await _autoSave();
    }
  }

  /// Skip the current page without clearing answers already entered.
  Future<void> skip() => next();

  Future<void> _autoSave() async {
    final uid = _uid;
    final role = _role;
    if (uid == null || role == null) return;
    try {
      await _service.saveProgress(
        uid,
        roleId: role.id,
        answers: answers,
        stepIndex: step,
      );
    } catch (e) {
      debugPrint('⚠️ Onboarding auto-save failed: $e');
    }
  }

  /// Explicit save (Save & Continue). Returns success.
  Future<bool> save() async {
    saving = true;
    notifyListeners();
    await _autoSave();
    saving = false;
    notifyListeners();
    return error == null;
  }

  /// Finalizes onboarding for the user.
  Future<bool> complete() async {
    final uid = _uid;
    final role = _role;
    if (uid == null || role == null) return false;
    saving = true;
    notifyListeners();
    try {
      await _service.markComplete(
        uid,
        roleId: role.id,
        answers: answers,
        stepIndex: step,
      );
      saving = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      saving = false;
      notifyListeners();
      return false;
    }
  }
}
