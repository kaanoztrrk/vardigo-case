import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/enum/user_role.dart';

void main() {
  setupDependencies();
  // Şimdilik uygulama işveren olarak açılıyor; rol seçici gelince
  // varsayılan rol oradan değişecek.
  getIt<AuthBloc>().add(AuthRoleSelected(UserRole.worker));
  runApp(const VardigoApp());
}
