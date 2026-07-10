import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../Web_routes.dart' show AuthNotifier;
import 'permission.dart';
import 'role_permissions.dart';
import 'user_role.dart';

/// Renders [child] only if the current user's role holds [permission];
/// otherwise renders [fallback] (default: nothing).
class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  final Permission permission;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthNotifier>().roleEnum;
    return can(role, permission) ? child : fallback;
  }
}

/// Convenience capability check from any [BuildContext].
extension PermissionContext on BuildContext {
  bool can(Permission permission) =>
      canDo(read<AuthNotifier>().roleEnum, permission);
}

/// Free function form (also usable outside a widget context).
bool canDo(UserRole? role, Permission permission) =>
    can(role, permission);
