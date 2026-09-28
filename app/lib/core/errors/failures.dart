import 'package:equatable/equatable.dart';

/// What repositories throw to blocs instead of raw HTTP/network errors.
///
/// [message] can go straight to the UI; the server already writes its
/// messages in Turkish for the user (see server/src/http.js).
abstract class Failure extends Equatable {
  final String message;

  /// Error code from the server (e.g. `OFFER_EXISTS`). Null when the
  /// server was never reached.
  ///
  /// Branch on this, not on [message], so a wording change on the server
  /// doesn't quietly break the client.
  final String? code;

  /// Ids the error is about, e.g. candidates that already have a pending
  /// offer in a POST /offers 409.
  final List<String> ids;

  const Failure(this.message, {this.code, this.ids = const []});

  @override
  List<Object?> get props => [message, code, ids];
}

/// 400: bad input (empty selection, invalid query, ...).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.ids});
}

/// 401: missing or invalid token, or wrong role.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.ids});
}

/// 404: candidate or offer not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code, super.ids});
}

/// 409: valid request that breaks a business rule (offer already pending,
/// already answered, or expired).
class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {super.code, super.ids});
}

/// 5xx, or a response we couldn't parse.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.ids});
}

/// Never reached the server: it's down, no connection, or timeout.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Sunucuya ulaşılamadı. Bağlantını kontrol edip tekrar dene.',
  ]);
}

/// Catch-all for anything else.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Beklenmeyen bir hata oluştu.']);
}
