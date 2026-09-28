import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_endpoint.dart';
import '../../core/services/api_service.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/data/repository/auth_repository.dart';
import '../../features/candidates/bloc/candidates/candidates_bloc.dart';
import '../../features/candidates/data/repository/candidate_repository.dart';
import '../../features/offers/bloc/offers/offers_bloc.dart';
import '../../features/offers/data/repository/offer_repository.dart';

final GetIt getIt = GetIt.instance;

/// Call from main.dart before runApp.
///
/// Registrations are done by hand rather than with injectable. For an app
/// this size, code generation isn't worth the setup.
void setupDependencies() {
  // --- External ---
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // --- Core services ---
  // Single instance since it holds the token every repository uses.
  getIt.registerLazySingleton<ApiService>(
    () =>
        ApiService(client: getIt<http.Client>(), baseUrl: ApiEndpoint.baseUrl),
  );

  // --- Repositories ---
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<CandidateRepository>(
    () => CandidateRepository(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<OfferRepository>(
    () => OfferRepository(getIt<ApiService>()),
  );

  // --- Blocs (singletons, so their data outlives the screen) ---
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<CandidatesBloc>(
    () =>
        CandidatesBloc(getIt<CandidateRepository>(), getIt<OfferRepository>()),
  );
  getIt.registerLazySingleton<OffersBloc>(
    () => OffersBloc(getIt<OfferRepository>()),
  );
}
