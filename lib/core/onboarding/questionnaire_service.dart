import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/audit_log_service.dart';
import 'aviation_catalogue.dart';
import 'models/aviation_role.dart';

/// Loads and persists the admin-managed onboarding questionnaire config, and
/// saves user onboarding progress/answers.
///
/// Config lives in a single document `questionnaire_config/active` with a
/// `roles` array (well under the 1MB doc limit for the default catalogue).
/// If the doc is absent, the built-in [AviationCatalogue] is used as a fallback
/// so onboarding works before an admin ever seeds — seeding just persists an
/// editable copy.
class QuestionnaireService {
  QuestionnaireService({FirebaseFirestore? firestore, AuditLogService? audit})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _audit = audit ?? AuditLogService();

  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  static const _configPath = 'questionnaire_config';
  static const _activeDoc = 'active';

  DocumentReference<Map<String, dynamic>> get _activeRef =>
      _firestore.collection(_configPath).doc(_activeDoc);

  // In-memory cache to avoid re-reading the config within a session.
  List<AviationRole>? _cache;

  /// Returns the live role catalogue, falling back to the seed defaults.
  Future<List<AviationRole>> loadRoles({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    try {
      final snap = await _activeRef.get();
      final data = snap.data();
      final rawRoles = data?['roles'];
      if (rawRoles is List && rawRoles.isNotEmpty) {
        _cache = rawRoles
            .whereType<Map>()
            .map((m) => AviationRole.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        return _cache!;
      }
    } catch (e) {
      debugPrint('⚠️ QuestionnaireService.loadRoles fell back to seed: $e');
    }
    _cache = AviationCatalogue.roles;
    return _cache!;
  }

  Future<AviationRole?> roleById(String id) async {
    final roles = await loadRoles();
    for (final r in roles) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Whether an admin has persisted a config yet.
  Future<bool> isSeeded() async {
    try {
      final snap = await _activeRef.get();
      final roles = snap.data()?['roles'];
      return roles is List && roles.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Writes the built-in default catalogue into Firestore (admin action).
  Future<void> seedDefaults() async {
    await saveRoles(
      AviationCatalogue.roles,
      seedVersion: AviationCatalogue.seedVersion,
      auditAction: 'seed',
    );
  }

  /// Persists an edited role catalogue (admin action). Bumps the cache.
  Future<void> saveRoles(
    List<AviationRole> roles, {
    int? seedVersion,
    String auditAction = 'edit',
  }) async {
    await _activeRef.set({
      'roles': roles.map((r) => r.toJson()).toList(),
      'seedVersion': seedVersion ?? AviationCatalogue.seedVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _cache = roles;
    await _audit.log(
      action: AuditAction.questionnairePublished,
      targetType: 'questionnaire',
      targetId: _activeDoc,
      details: {'action': auditAction, 'roleCount': roles.length},
    );
  }

  // ── User onboarding progress / answers ────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Loads a user's saved onboarding state for resume, or null.
  Future<OnboardingProgress?> loadProgress(String uid) async {
    try {
      final snap = await _userRef(uid).get();
      final ob = snap.data()?['onboarding'];
      if (ob is Map) {
        return OnboardingProgress.fromJson(Map<String, dynamic>.from(ob));
      }
    } catch (e) {
      debugPrint('⚠️ QuestionnaireService.loadProgress: $e');
    }
    return null;
  }

  /// Saves progress (auto-save + explicit save). Merges into users/{uid}.
  Future<void> saveProgress(
    String uid, {
    required String roleId,
    required Map<String, dynamic> answers,
    required int stepIndex,
    bool completed = false,
  }) async {
    await _userRef(uid).set({
      'onboarding': {
        'roleId': roleId,
        'answers': answers,
        'stepIndex': stepIndex,
        'completed': completed,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'onboarding_completed': completed,
    }, SetOptions(merge: true));
  }

  /// Marks onboarding complete (keeps profile-builder gating via isNew).
  Future<void> markComplete(
    String uid, {
    required String roleId,
    required Map<String, dynamic> answers,
    required int stepIndex,
  }) async {
    await saveProgress(
      uid,
      roleId: roleId,
      answers: answers,
      stepIndex: stepIndex,
      completed: true,
    );
  }
}

/// A user's saved onboarding state, used to resume the wizard.
class OnboardingProgress {
  const OnboardingProgress({
    required this.roleId,
    required this.answers,
    required this.stepIndex,
    required this.completed,
  });

  final String? roleId;
  final Map<String, dynamic> answers;
  final int stepIndex;
  final bool completed;

  factory OnboardingProgress.fromJson(Map<String, dynamic> j) {
    return OnboardingProgress(
      roleId: j['roleId']?.toString(),
      answers: j['answers'] is Map
          ? Map<String, dynamic>.from(j['answers'])
          : <String, dynamic>{},
      stepIndex: j['stepIndex'] is int ? j['stepIndex'] as int : 0,
      completed: j['completed'] == true,
    );
  }
}
