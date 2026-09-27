import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_endpoint.dart';
import '../../core/services/api_service.dart';

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
    () => ApiService(client: getIt<http.Client>(), baseUrl: ApiEndpoint.baseUrl),
  );
}
