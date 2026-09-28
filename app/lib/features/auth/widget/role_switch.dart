import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_style.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../data/enum/user_role.dart';

/// Demo role switch: İşveren | İş arayan.
///
/// Sits outside the phone frame (see app.dart). It isn't part of the app,
/// just a quick way to jump between the two accounts. Picking a role logs
/// in as that role (see AuthRepository), and the router takes care of
/// showing the right screen (see app_router.dart).
class RoleSwitch extends StatelessWidget {
  const RoleSwitch({super.key, required this.bloc});

  /// Passed in directly since this lives outside the route tree.
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
      // Show the requested role while logging in, so the pill moves right
      // away instead of waiting for the server.
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
                      // No second login while one is in flight.
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
