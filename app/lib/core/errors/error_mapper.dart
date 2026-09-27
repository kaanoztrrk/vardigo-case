import 'app_logger.dart';
import 'failures.dart';

/// Sunucunun hata zarfını ve HTTP/ağ exception'larını standart bir
/// [Failure]'a çevirir; aynı anda [AppLogger] ile loglar.
///
/// [tag] hangi katmandan çağrıldığını belirtir (ör. 'Api') — log çıktısında
/// bu etiket görünüyor.
class ErrorMapper {
  ErrorMapper._();

  /// Sunucu cevap verdi ama `ok: false` döndü.
  ///
  /// Zarf: `{ "ok": false, "error": { "code", "message", "ids"? } }`
  /// (bkz. server/src/http.js). Durum koduna göre tip seçiliyor; mesaj ve
  /// kod sunucudan olduğu gibi taşınıyor.
  static Failure fromResponse(
    int statusCode,
    Object? error, {
    String tag = 'Api',
  }) {
    final body = error is Map<String, dynamic> ? error : const {};
    final message = body['message'] is String
        ? body['message'] as String
        : 'Beklenmeyen bir hata oluştu.';
    final code = body['code'] is String ? body['code'] as String : null;
    final ids = body['ids'] is List
        ? (body['ids'] as List).whereType<String>().toList()
        : const <String>[];

    final failure = switch (statusCode) {
      400 => ValidationFailure(message, code: code, ids: ids),
      401 || 403 => AuthFailure(message, code: code, ids: ids),
      404 => NotFoundFailure(message, code: code, ids: ids),
      409 => ConflictFailure(message, code: code, ids: ids),
      _ => ServerFailure(message, code: code, ids: ids),
    };

    AppLogger.warning(
      tag: tag,
      message: 'HTTP $statusCode ${code ?? '-'}: $message',
    );
    return failure;
  }

  /// İstek hiç tamamlanamadı ya da cevap okunamadı.
  static Failure fromException(
    Object error,
    StackTrace stackTrace, {
    String tag = 'Api',
    Failure fallback = const UnknownFailure(),
  }) {
    AppLogger.error(
      tag: tag,
      message: 'İstek başarısız: $error',
      error: error,
      stackTrace: stackTrace,
    );
    return fallback;
  }
}
