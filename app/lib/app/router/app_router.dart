import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/presentation/splash_view.dart';
import '../../features/candidates/bloc/candidates/candidates_bloc.dart';
import '../../features/candidates/presentation/candidates_view.dart';
import '../di/injection.dart';
import 'route.dart';

/// AuthBloc'un state akışını GoRouter'ın anlayacağı bir [Listenable]'a
/// çevirir: giriş tamamlanınca redirect yeniden çalışıp kullanıcıyı
/// açılış ekranından alıyor.
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

  // Oturum yoksa açılış ekranı; varsa açılış ekranında bekletme.
  // İş arayan ekranı eklenince hedef rol'e göre seçilecek.
  redirect: (BuildContext context, GoRouterState state) {
    final loggedIn = getIt<AuthBloc>().state.role != null;
    final atSplash = state.matchedLocation == AppRoutes.splashView;
    if (!loggedIn) return atSplash ? null : AppRoutes.splashView;
    return atSplash ? AppRoutes.candidatesView : null;
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
  ],
);
