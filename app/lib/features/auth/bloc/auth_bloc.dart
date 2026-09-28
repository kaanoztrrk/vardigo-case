import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../data/repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Session state. A singleton (see injection.dart) because the router's
/// redirect listens to it.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthState()) {
    on<AuthRoleSelected>(_onRoleSelected);
  }

  Future<void> _onRoleSelected(
    AuthRoleSelected event,
    Emitter<AuthState> emit,
  ) async {
    // Drop the old role first so the screen doesn't fire requests as the
    // old role before the new token arrives.
    emit(
      state.copyWith(
        requestedRole: event.role,
        clearRole: true,
        loading: true,
        clearError: true,
      ),
    );
    try {
      await _repository.login(event.role);
      emit(state.copyWith(role: event.role, loading: false));
    } on Failure catch (f) {
      emit(state.copyWith(loading: false, error: f.message));
    }
  }
}
