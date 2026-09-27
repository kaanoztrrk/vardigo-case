import 'package:equatable/equatable.dart';

/// Repository katmanından Bloc katmanına taşınan hata tipi.
///
/// HTTP/ağ exception'larını doğrudan Bloc'a sızdırmak yerine bu tip
/// taşınıyor. [message] kullanıcıya gösterilebilir: sunucu mesajları zaten
/// Türkçe ve ekrana uygun yazılıyor (bkz. server/src/http.js).
abstract class Failure extends Equatable {
  final String message;

  /// Sunucunun makine okunabilir hata kodu (ör. `OFFER_EXISTS`). Ağ hatası
  /// gibi sunucuya hiç ulaşılamayan durumlarda null.
  ///
  /// Ekranlar ayrım yapacaksa MESAJA değil buna bakmalı: sunucudaki bir
  /// yazım düzeltmesi istemciyi sessizce bozmasın.
  final String? code;

  /// Sorunlu kayıtların id'leri — ör. POST /offers 409'unda zaten talep
  /// gönderilmiş adaylar.
  final List<String> ids;

  const Failure(this.message, {this.code, this.ids = const []});

  @override
  List<Object?> get props => [message, code, ids];
}

/// 400 — gönderilen veri kurallara uymuyor (boş seçim, geçersiz sorgu...).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.ids});
}

/// 401 — token yok/geçersiz ya da bu işlem bu role açık değil.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.ids});
}

/// 404 — aday ya da talep bulunamadı.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code, super.ids});
}

/// 409 — istek geçerli ama bir iş kuralına takıldı (bekleyen talep var,
/// talep zaten yanıtlanmış, süresi dolmuş).
class ConflictFailure extends Failure {
  const ConflictFailure(super.message, {super.code, super.ids});
}

/// 5xx ya da sunucudan anlaşılamayan bir cevap geldi.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.ids});
}

/// Sunucuya hiç ulaşılamadı: kapalı, bağlantı yok ya da zaman aşımı.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Sunucuya ulaşılamadı. Bağlantını kontrol edip tekrar dene.',
  ]);
}

/// Beklenmeyen / sınıflandırılamayan her şey için son çare.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Beklenmeyen bir hata oluştu.']);
}
