/// Sunucu adresi ve uç nokta yolları — tek merkez.
///
/// Yollar server/src altındaki router'larla BİREBİR aynı olmak zorunda;
/// değişiklik iki tarafta birlikte yapılmalı.
class ApiEndpoint {
  ApiEndpoint._();

  /// Sunucunun kök adresi. Varsayılan geliştirme sunucusu (`npm run dev`).
  ///
  /// Derlemede değiştirilebilir:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String login = '/api/auth/login';
  static const String candidates = '/api/candidates';
  static const String offers = '/api/offers';

  static String offer(String id) => '/api/offers/$id';
  static String acceptOffer(String id) => '/api/offers/$id/accept';
  static String rejectOffer(String id) => '/api/offers/$id/reject';
}
