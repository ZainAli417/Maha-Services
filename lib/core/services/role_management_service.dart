import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../rbac/user_role.dart';
import 'audit_log_service.dart';

/// Outcome of a role-management operation.
class RoleOpResult {
  const RoleOpResult(this.ok, [this.message = '']);
  final bool ok;
  final String message;

  static const success = RoleOpResult(true, 'Done');
}

/// Centralized, audited admin operations on user accounts: creation, role
/// conversion, suspend/activate, soft delete/restore, and profile reset.
///
/// Role resolution now reads `users.role` first (see RoleService precedence
/// flip), so conversion only needs to rewrite that field and ensure the target
/// per-role collection doc exists — stale collection docs are harmless and are
/// intentionally left in place to preserve historical data.
class RoleManagementService {
  RoleManagementService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AuditLogService? audit,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _audit = audit ?? AuditLogService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AuditLogService _audit;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  /// The per-role collection whose existence historically implied [role]
  /// (null for job seekers stored under `Job_Seeker`, handled explicitly).
  String _collectionFor(UserRole role) {
    if (role.isAdminTier) return 'admin';
    if (role.isRecruiterTier) return 'recruiter';
    return 'Job_Seeker';
  }

  // ── Create ────────────────────────────────────────────────────────────────

  /// Creates an auth account + `users/{uid}` doc without disturbing the
  /// currently signed-in admin (uses a throwaway secondary FirebaseApp).
  Future<RoleOpResult> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String userLevel = '',
  }) async {
    FirebaseApp tempApp;
    try {
      try {
        tempApp = Firebase.app('TemporaryUserCreator');
      } catch (_) {
        tempApp = await Firebase.initializeApp(
          name: 'TemporaryUserCreator',
          options: Firebase.app().options,
        );
      }
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final cred = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = cred.user!.uid;
      await tempAuth.signOut();

      await _userRef(uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'uid': uid,
        'role': role.toFirestore(),
        'isNew': 'yes',
        'account_status': 'active',
        'user_lvl': userLevel.trim(),
        'created_at': FieldValue.serverTimestamp(),
      });
      await _ensureCollectionDoc(uid, role, name: name, email: email);

      await _audit.log(
        action: AuditAction.userCreated,
        targetType: 'user',
        targetId: uid,
        targetLabel: email.trim(),
        details: {'role': role.toFirestore()},
      );
      return RoleOpResult(true, 'User created');
    } catch (e) {
      debugPrint('❌ RoleManagementService.createUser: $e');
      return RoleOpResult(false, 'Error: $e');
    }
  }

  // ── Convert role ────────────────────────────────────────────────────────

  /// Changes a user's role. [fromRole] is optional and only used for the audit
  /// entry. Ensures the target collection doc exists.
  Future<RoleOpResult> convertRole({
    required String uid,
    required UserRole targetRole,
    UserRole? fromRole,
    String? name,
    String? email,
  }) async {
    try {
      await _userRef(uid).update({
        'role': targetRole.toFirestore(),
        'role_updated_at': FieldValue.serverTimestamp(),
      });
      await _ensureCollectionDoc(uid, targetRole, name: name, email: email);

      await _audit.log(
        action: AuditAction.userRoleChanged,
        targetType: 'user',
        targetId: uid,
        targetLabel: email ?? name,
        details: {
          'from': fromRole?.toFirestore(),
          'to': targetRole.toFirestore(),
        },
      );
      return RoleOpResult(true, 'Role changed to ${targetRole.displayLabel}');
    } catch (e) {
      debugPrint('❌ RoleManagementService.convertRole: $e');
      return RoleOpResult(false, 'Error: $e');
    }
  }

  /// Creates the target per-role collection doc if it doesn't already exist,
  /// so downstream flows that still look up `recruiter/{uid}` etc. keep working.
  Future<void> _ensureCollectionDoc(
    String uid,
    UserRole role, {
    String? name,
    String? email,
  }) async {
    final collection = _collectionFor(role);
    final ref = _firestore.collection(collection).doc(uid);
    final snap = await ref.get();
    if (snap.exists) {
      // Keep super-admin level in sync when relevant.
      if (collection == 'admin') {
        await ref.set(
          {'level': role == UserRole.superAdmin ? 'super' : 'standard'},
          SetOptions(merge: true),
        );
      }
      return;
    }
    final base = <String, dynamic>{
      'uid': uid,
      'name': ?name,
      'email': ?email,
      'created_at': FieldValue.serverTimestamp(),
    };
    if (collection == 'admin') {
      base['level'] = role == UserRole.superAdmin ? 'super' : 'standard';
    }
    await ref.set(base, SetOptions(merge: true));
  }

  // ── Account status ─────────────────────────────────────────────────────

  Future<RoleOpResult> setSuspended({
    required String uid,
    required bool suspended,
    String? label,
  }) async {
    try {
      await _userRef(uid).update({
        'account_status': suspended ? 'suspended' : 'active',
      });
      await _audit.log(
        action:
            suspended ? AuditAction.userSuspended : AuditAction.userActivated,
        targetType: 'user',
        targetId: uid,
        targetLabel: label,
      );
      return RoleOpResult(true, suspended ? 'User suspended' : 'User activated');
    } catch (e) {
      debugPrint('❌ RoleManagementService.setSuspended: $e');
      return RoleOpResult(false, 'Error: $e');
    }
  }

  /// Soft delete: marks the account `deleted` (auth + data are preserved so it
  /// can be restored). The AuthNotifier signs such users out automatically.
  Future<RoleOpResult> softDelete({
    required String uid,
    String? label,
  }) async {
    try {
      await _userRef(uid).update({
        'account_status': 'deleted',
        'deleted_at': FieldValue.serverTimestamp(),
        'deleted_by': _auth.currentUser?.uid,
      });
      await _audit.log(
        action: AuditAction.userSoftDeleted,
        targetType: 'user',
        targetId: uid,
        targetLabel: label,
      );
      return RoleOpResult(true, 'User deleted');
    } catch (e) {
      debugPrint('❌ RoleManagementService.softDelete: $e');
      return RoleOpResult(false, 'Error: $e');
    }
  }

  Future<RoleOpResult> restore({required String uid, String? label}) async {
    try {
      await _userRef(uid).update({
        'account_status': 'active',
        'deleted_at': FieldValue.delete(),
        'deleted_by': FieldValue.delete(),
      });
      await _audit.log(
        action: AuditAction.userRestored,
        targetType: 'user',
        targetId: uid,
        targetLabel: label,
      );
      return RoleOpResult(true, 'User restored');
    } catch (e) {
      debugPrint('❌ RoleManagementService.restore: $e');
      return RoleOpResult(false, 'Error: $e');
    }
  }

  /// Resets onboarding/profile status so the user re-enters the wizard.
  Future<RoleOpResult> resetProfileStatus({
    required String uid,
    String? label,
  }) async {
    try {
      await _userRef(uid).update({
        'isNew': 'yes',
        'onboarding_completed': false,
      });
      await _audit.log(
        action: AuditAction.userProfileReset,
        targetType: 'user',
        targetId: uid,
        targetLabel: label,
      );
      return RoleOpResult(true, 'Profile status reset');
    } catch (e) {
      debugPrint('❌ RoleManagementService.resetProfileStatus: $e');
      return RoleOpResult(false, 'Error: $e');
    }
  }
}
