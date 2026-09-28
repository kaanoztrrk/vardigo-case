import 'app_logger.dart';
import 'failures.dart';

/// Turns server error envelopes and HTTP/network exceptions into a
/// [Failure], and logs them with [AppLogger].
///
/// [tag] shows up in the log to tell where the call came from (e.g. 'Api').
class ErrorMapper {
  ErrorMapper._();

  /// The server answered with `ok: false`.
  ///
  /// Envelope: `{ "ok": false, "error": { "code", "message", "ids"? } }`
  /// (see server/src/http.js). The status code picks the type; message and
  /// code are passed through as is.
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

  /// The request never completed, or the response couldn't be read.
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
