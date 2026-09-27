import 'offer_model.dart';

/// GET /api/offers cevabının tamamı.
class OfferListModel {
  /// Header'daki "12 talep yanıt bekliyor". Seed'de sabit etiket;
  /// listedeki gerçek adet daha az (bkz. server/src/offers.js).
  final int pendingCount;
  final List<OfferModel> offers;

  const OfferListModel({required this.pendingCount, required this.offers});
}
