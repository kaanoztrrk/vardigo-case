import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_style.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../data/enum/user_role.dart';

/// Demo rol anahtarı: İşveren | İş arayan.
///
/// Telefon çerçevesinin DIŞINDA duruyor (bkz. app.dart): uygulamanın bir
/// parçası değil, değerlendiricinin iki hesap arasında tek tıkla geçmesi
/// için bir demo kontrolü. Case'de rol seçmek giriş yapmak demek
/// (bkz. AuthRepository); geçiş sonrası doğru ekrana router kendisi
/// götürüyor (bkz. app_router.dart).
class RoleSwitch extends StatelessWidget {
  const RoleSwitch({super.key, required this.bloc});

  /// Çerçeve route ağacının dışında — bloc ağaçtan değil doğrudan veriliyor.
  final AuthBloc bloc;

  static const _duration = Duration(milliseconds: 260);
  static const _width = 260.0;

  static const _labels = {
    UserRole.employer: 'İşveren',
    UserRole.worker: 'İş arayan',
  };

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    bloc: bloc,
    builder: (context, state) {
      // Giriş sürerken istenen rol gösteriliyor: pill dokunur dokunmaz
      // kaysın, sunucuyu beklemesin.
      final active = state.requestedRole ?? state.role ?? UserRole.employer;
      return Container(
        width: _width,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.slate200,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                duration: _duration,
                curve: Curves.easeOutCubic,
                alignment: active == UserRole.employer
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: AppShadows.tabActiveRequests,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final role in UserRole.values)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Giriş sürerken ikinci bir istek atılmasın.
                      onTap: state.loading || role == active
                          ? null
                          : () => bloc.add(AuthRoleSelected(role)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: AnimatedDefaultTextStyle(
                          duration: _duration,
                          style: AppTextStyle.tab13.copyWith(
                            color: role == active
                                ? AppColors.strong
                                : AppColors.slate500,
                          ),
                          child: Text(
                            _labels[role]!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
