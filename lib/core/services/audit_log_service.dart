import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Canonical admin action names recorded in the `audit_logs` collection.
///
/// Kept as constants (not an enum) so historical log documents remain readable
/// even if the set changes over time.
abstract final class AuditAction {
  static const userCreated = 'user.created';
  static const userRoleChanged = 'user.role_changed';
  static const userSuspended = 'user.suspended';
  static const userActivated = 'user.activated';
  static const userSoftDeleted = 'user.soft_deleted';
  static const userRestored = 'user.restored';
  static const userProfileReset = 'user.profile_reset';
  static const questionnairePublished = 'questionnaire.published';
}

/// Writes immutable admin-action entries to `audit_logs`.
///
/// Entries are attributed to the currently-signed-in admin. Firestore rules
/// (Phase 1) allow admins to create actor-attributed entries and forbid any
/// update/delete, so the trail is append-only.
class AuditLogService {
  AuditLogService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('audit_logs');

  /// Records an action. Never throws — audit logging must not break the
  /// operation it accompanies; failures are logged to the console only.
  Future<void> log({
    required String action,
    required String targetType,
    String? targetId,
    String? targetLabel,
    Map<String, dynamic> details = const {},
  }) async {
    final actor = _auth.currentUser;
    if (actor == null) {
      debugPrint('⚠️ AuditLogService: no signed-in actor; skipping "$action".');
      return;
    }
    try {
      await _col.add({
        'actorUid': actor.uid,
        'actorEmail': actor.email ?? '',
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'targetLabel': targetLabel,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ AuditLogService.log("$action") failed: $e');
    }
  }

  /// Paginated read of recent entries (newest first). Uses a one-shot get so it
  /// does not hold an open listener; callers page with [startAfter].
  Future<QuerySnapshot<Map<String, dynamic>>> fetchPage({
    int limit = 25,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    String? actionFilter,
  }) {
    Query<Map<String, dynamic>> q =
        _col.orderBy('timestamp', descending: true);
    if (actionFilter != null && actionFilter.isNotEmpty) {
      q = q.where('action', isEqualTo: actionFilter);
    }
    if (startAfter != null) q = q.startAfterDocument(startAfter);
    return q.limit(limit).get();
  }
}
