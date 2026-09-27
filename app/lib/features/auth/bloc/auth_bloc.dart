import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../data/repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Oturum. Singleton (bkz. injection.dart): router redirect'i bunu
/// dinliyor.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthState()) {
    on<AuthRoleSelected>(_onRoleSelected);
  }

  Future<void> _onRoleSelected(
    AuthRoleSelected event,
    Emitter<AuthState> emit,
  ) async {
    // Önce eski rol düşürülüyor: yeni token gelene kadar ekran eski rolün
    // verisiyle istek atmasın.
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
