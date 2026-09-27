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

  // Oturum yoksa açılış ekranı. Varsa her rolün TEK ekranı var: işveren
  // Eşleşen Personeller'e, iş arayan Görüşme Talepleri'ne. Diğer rolün
  // ekranına gidilemiyor (sunucu da zaten 401 FORBIDDEN_ROLE verirdi).
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
