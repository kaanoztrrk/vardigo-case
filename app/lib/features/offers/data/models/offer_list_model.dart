import 'offer_model.dart';

/// Full GET /api/offers response.
class OfferListModel {
  /// "12 talep yanıt bekliyor" in the header. A fixed label from the seed;
  /// the real list is shorter (see server/src/offers.js).
  final int pendingCount;
  final List<OfferModel> offers;

  const OfferListModel({required this.pendingCount, required this.offers});
}
