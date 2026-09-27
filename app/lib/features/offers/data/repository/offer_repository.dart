import '../../../../core/constants/api_endpoint.dart';
import '../../../../core/services/api_service.dart';

/// Görüşme talepleri (offers). İşveren gönderiyor; iş arayan tarafı
/// (liste, kabul/red) Ekran 2 ile buraya eklenecek.
class OfferRepository {
  final ApiService _api;

  OfferRepository(this._api);

  static const String _tag = 'OfferRepo';

  /// Seçili adaylara talep gönderir. Sunucu ATOMİK: bir aday bile
  /// çakışırsa (409 OFFER_EXISTS, `ids` = çakışanlar) hiçbiri yazılmaz.
  /// Hata olursa [Failure] fırlatır (ApiService'ten).
  Future<void> sendOffers(List<String> workerIds) async {
    await _api.post(
      ApiEndpoint.offers,
      body: {'workerIds': workerIds},
      tag: _tag,
    );
  }
}
