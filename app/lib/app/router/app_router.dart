import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/data/enum/user_role.dart';
import '../../features/auth/presentation/splash_view.dart';
import '../../features/candidates/bloc/candidates/candidates_bloc.dart';
import '../../features/candidates/presentation/candidates_view.dart';
import '../../features/offers/bloc/offers/offers_bloc.dart';
import '../../features/offers/presentation/offers_view.dart';
import '../di/injection.dart';
import 'route.dart';

/// Wraps the AuthBloc stream in a [Listenable] so GoRouter re-runs
/// redirect once login finishes and moves the user off the splash screen.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter router = GoRouter(
  initialLocation: AppRoutes.splashView,
  refreshListenable: GoRouterRefreshStream(getIt<AuthBloc>().stream),

  // No session means splash. Otherwise each role has exactly one screen,
  // and you can't open the other role's screen (the server would return
  // 401 FORBIDDEN_ROLE anyway).
  redirect: (BuildContext context, GoRouterState state) {
    final role = getIt<AuthBloc>().state.role;
    final target = switch (role) {
      null => AppRoutes.splashView,
      UserRole.employer => AppRoutes.candidatesView,
      UserRole.worker => AppRoutes.offersView,
    };
    return state.matchedLocation == target ? null : target;
  },

  routes: [
    GoRoute(
      path: AppRoutes.splashView,
      builder: (context, state) => BlocProvider.value(
        value: getIt<AuthBloc>(),
        child: const SplashView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.candidatesView,
      builder: (context, state) => BlocProvider.value(
        value: getIt<CandidatesBloc>(),
        child: const CandidatesView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.offersView,
      builder: (context, state) => BlocProvider.value(
        value: getIt<OffersBloc>(),
        child: const OffersView(),
      ),
    ),
  ],
);
