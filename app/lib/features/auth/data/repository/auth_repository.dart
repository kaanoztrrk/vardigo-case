import '../../../../core/services/api_service.dart';
import '../../../../core/constants/api_endpoint.dart';
import '../enum/user_role.dart';

/// No SMS or password in this case; picking a role is the login
/// (see server/src/auth.js).
class AuthRepository {
  final ApiService _api;

  AuthRepository(this._api);

  static const String _tag = 'AuthRepo';

  /// Gets the role's token and hands it to [ApiService], so every request
  /// after this goes out as that role. Throws a [Failure] on error.
  Future<void> login(UserRole role) async {
    final data = await _api.post(
      ApiEndpoint.login,
      body: {'role': role.value},
      tag: _tag,
    );
    _api.token = (data as Map<String, dynamic>)['token'] as String;
  }
}
