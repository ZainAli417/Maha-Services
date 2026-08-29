import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/audit_log_service.dart';
import 'models/aviation_role.dart';
import 'role_templates.dart';

/// Loads and persists the admin-managed role-template catalogue.
///
/// Config lives in a single document `role_templates/active` with a `roles`
/// array (well under the 1MB doc limit for the default catalogue). If the doc
/// is absent, the built-in [RoleTemplateCatalogue] is used as a fallback so
/// onboarding works before an admin ever seeds — seeding just persists an
/// editable copy.
///
/// Candidate answers do NOT live here; they belong to
/// [CandidateProfileService], which owns the `candidateProfile` field on
/// `Job_Seeker/{uid}`.
class RoleTemplateService {
  RoleTemplateService({FirebaseFirestore? firestore, AuditLogService? audit})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _audit = audit ?? AuditLogService();

  final FirebaseFirestore _firestore;
  final AuditLogService _audit;

  static const _configPath = 'role_templates';
  static const _activeDoc = 'active';

  DocumentReference<Map<String, dynamic>> get _activeRef =>
      _firestore.collection(_configPath).doc(_activeDoc);

  // In-memory cache to avoid re-reading the config within a session.
  List<RoleTemplate>? _cache;

  /// Returns the live template catalogue, falling back to the seed defaults.
  Future<List<RoleTemplate>> loadRoles({bool forceRefresh = false}) async {
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
      debugPrint('⚠️ RoleTemplateService.loadRoles fell back to seed: $e');
    }
    _cache = RoleTemplateCatalogue.templates;
    return _cache!;
  }

  Future<RoleTemplate?> roleById(String id) async {
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

  /// The seed version already persisted, or null when nothing is seeded.
  Future<int?> seededVersion() async {
    try {
      final v = (await _activeRef.get()).data()?['seedVersion'];
      return v is int ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// Writes the built-in default catalogue into Firestore (admin action).
  Future<void> seedDefaults() async {
    await saveRoles(
      RoleTemplateCatalogue.templates,
      seedVersion: RoleTemplateCatalogue.seedVersion,
      auditAction: 'seed',
    );
  }

  /// Persists an edited template catalogue (admin action). Bumps the cache.
  Future<void> saveRoles(
    List<RoleTemplate> roles, {
    int? seedVersion,
    String auditAction = 'edit',
  }) async {
    await _activeRef.set({
      'roles': roles.map((r) => r.toJson()).toList(),
      'seedVersion': seedVersion ?? RoleTemplateCatalogue.seedVersion,
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
}
