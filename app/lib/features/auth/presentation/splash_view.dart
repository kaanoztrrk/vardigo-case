import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Giriş sürerken ya da başarısız olduysa görünen ekran. Giriş bitince
/// router kullanıcıyı buradan KENDİSİ alıyor (bkz. app_router.dart).
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.white,
    body: Center(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final role = state.requestedRole;
          if (state.error == null || role == null) {
            return const CircularProgressIndicator();
          }
          // En olası sebep: sunucu kapalı (npm run dev).
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.caption13,
                ),
                TextButton(
                  onPressed: () =>
                      context.read<AuthBloc>().add(AuthRoleSelected(role)),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
