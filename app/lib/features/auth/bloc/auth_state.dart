import '../data/enum/user_role.dart';

class AuthState {
  /// The role being requested. "Tekrar dene" retries with this if login
  /// fails.
  final UserRole? requestedRole;

  /// The logged-in role. While null, the router keeps the user on the
  /// splash screen (see app_router.dart).
  final UserRole? role;

  final bool loading;
  final String? error;

  const AuthState({
    this.requestedRole,
    this.role,
    this.loading = false,
    this.error,
  });

  AuthState copyWith({
    UserRole? requestedRole,
    UserRole? role,
    bool clearRole = false,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      requestedRole: requestedRole ?? this.requestedRole,
      role: clearRole ? null : (role ?? this.role),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
