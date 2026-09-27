import '../data/enum/user_role.dart';

abstract class AuthEvent {}

/// Bu rolle giriş yap. Şimdilik açılışta main.dart atıyor (işveren);
/// rol seçici eklenince oradan da atılacak.
class AuthRoleSelected extends AuthEvent {
  final UserRole role;

  AuthRoleSelected(this.role);
}
