import '../data/enum/user_role.dart';

abstract class AuthEvent {}

/// Log in as this role. Sent by main.dart on startup and by the role
/// switch.
class AuthRoleSelected extends AuthEvent {
  final UserRole role;

  AuthRoleSelected(this.role);
}
