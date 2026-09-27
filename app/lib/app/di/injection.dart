import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_endpoint.dart';
import '../../core/services/api_service.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/data/repository/auth_repository.dart';
import '../../features/candidates/bloc/candidates/candidates_bloc.dart';
import '../../features/candidates/data/repository/candidate_repository.dart';
import '../../features/offers/data/repository/offer_repository.dart';

final GetIt getIt = GetIt.instance;

/// Uygulama açılışında main.dart içinde, runApp'ten ÖNCE çağrılmalı.
///
/// injectable/build_runner KULLANILMIYOR — kayıtlar burada elle yapılıyor.
/// Bu ölçekte kod üretimi zahmete değmez ve sıralama/gerekçe yorumları
/// burada okunabilir kalıyor.
void setupDependencies() {
  // --- External ---
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // --- Core servisleri ---
  // Tek instance: token'ı taşıyor, giriş yapan rolün token'ı tüm
  // repository'lerde aynı olmalı.
  getIt.registerLazySingleton<ApiService>(
    () =>
        ApiService(client: getIt<http.Client>(), baseUrl: ApiEndpoint.baseUrl),
  );

  // --- Repository'ler ---
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<CandidateRepository>(
    () => CandidateRepository(getIt<ApiService>()),
  );
  getIt.registerLazySingleton<OfferRepository>(
    () => OfferRepository(getIt<ApiService>()),
  );

  // --- Bloc'lar (veri bloc'ları singleton) ---
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<CandidatesBloc>(
    () =>
        CandidatesBloc(getIt<CandidateRepository>(), getIt<OfferRepository>()),
  );
}
