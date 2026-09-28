import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/enum/user_role.dart';

void main() {
  setupDependencies();
  // Opens as the employer; the role switch above the phone changes it.
  getIt<AuthBloc>().add(AuthRoleSelected(UserRole.employer));
  runApp(const VardigoApp());
}
