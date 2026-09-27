import '../../../../core/constants/api_endpoint.dart';
import '../../../../core/services/api_service.dart';
import '../enum/offer_tab.dart';
import '../models/offer_detail_model.dart';
import '../models/offer_list_model.dart';
import '../models/offer_model.dart';

/// Görüşme talepleri (offers): işveren gönderiyor, iş arayan listeliyor ve
/// yanıtlıyor. Tüm metotlar hata olursa [Failure] fırlatır (ApiService'ten).
class OfferRepository {
  final ApiService _api;

  OfferRepository(this._api);

  static const String _tag = 'OfferRepo';

  /// Seçili adaylara talep gönderir. Sunucu ATOMİK: bir aday bile
  /// çakışırsa (409 OFFER_EXISTS, `ids` = çakışanlar) hiçbiri yazılmaz.
  Future<void> sendOffers(List<String> workerIds) async {
    await _api.post(
      ApiEndpoint.offers,
      body: {'workerIds': workerIds},
      tag: _tag,
    );
  }

  /// İş arayanın sekmesi. Sıra sunucunun: en yeni üstte.
  Future<OfferListModel> fetchOffers(OfferTab tab) async {
    final data =
        await _api.get(
              ApiEndpoint.offers,
              query: {'status': tab.value},
              tag: _tag,
            )
            as Map<String, dynamic>;

    return OfferListModel(
      pendingCount: data['pendingCount'] as int,
      offers: (data['offers'] as List)
          .map(
            (o) => OfferModel.fromMap(
              o as Map<String, dynamic>,
              assetUrl: _api.assetUrl,
            ),
          )
          .toList(),
    );
  }

  Future<OfferDetailModel> fetchDetail(String id) async {
    final data = await _api.get(ApiEndpoint.offer(id), tag: _tag);
    return OfferDetailModel.fromMap(data as Map<String, dynamic>);
  }

  /// İlgileniyorum. Bekleyen değilse 409 (OFFER_STATE / OFFER_EXPIRED).
  Future<void> accept(String id) async {
    await _api.post(ApiEndpoint.acceptOffer(id), tag: _tag);
  }

  /// İlgilenmiyorum. Bekleyen değilse 409 (OFFER_STATE / OFFER_EXPIRED).
  Future<void> reject(String id) async {
    await _api.post(ApiEndpoint.rejectOffer(id), tag: _tag);
  }
}
