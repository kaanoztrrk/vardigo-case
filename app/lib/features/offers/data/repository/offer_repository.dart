import '../../../../core/constants/api_endpoint.dart';
import '../../../../core/services/api_service.dart';
import '../enum/offer_tab.dart';
import '../models/offer_detail_model.dart';
import '../models/offer_list_model.dart';
import '../models/offer_model.dart';

/// Offers: the employer sends them, the worker lists and answers them.
/// Every method throws a [Failure] on error.
class OfferRepository {
  final ApiService _api;

  OfferRepository(this._api);

  static const String _tag = 'OfferRepo';

  /// Sends offers to the selected candidates. All or nothing: if any of
  /// them conflicts (409 OFFER_EXISTS, with the conflicting `ids`), none
  /// are saved.
  Future<void> sendOffers(List<String> workerIds) async {
    await _api.post(
      ApiEndpoint.offers,
      body: {'workerIds': workerIds},
      tag: _tag,
    );
  }

  /// One of the worker's tabs, newest first (server order).
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

  /// İlgileniyorum. 409 if not pending (OFFER_STATE / OFFER_EXPIRED).
  Future<void> accept(String id) async {
    await _api.post(ApiEndpoint.acceptOffer(id), tag: _tag);
  }

  /// İlgilenmiyorum. 409 if not pending (OFFER_STATE / OFFER_EXPIRED).
  Future<void> reject(String id) async {
    await _api.post(ApiEndpoint.rejectOffer(id), tag: _tag);
  }
}
