import '../../../../core/services/api_service.dart';
import '../../../../core/constants/api_endpoint.dart';
import '../enum/user_role.dart';

/// Case'de SMS / şifre yok: rol seçmek giriş yapmak demek
/// (bkz. server/src/auth.js).
class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  static const String _tag = 'AuthRepo';

  /// Rolün token'ını alır ve [ApiService]'e verir — sonraki TÜM istekler
  /// bu rolle gidiyor. Hata olursa [Failure] fırlatır (ApiService'ten).
  Future<void> login(UserRole role) async {
    final data = await _api.post(
      ApiEndpoint.login,
      body: {'role': role.value},
      tag: _tag,
    );
    _api.token = (data as Map<String, dynamic>)['token'] as String;
  }
}
