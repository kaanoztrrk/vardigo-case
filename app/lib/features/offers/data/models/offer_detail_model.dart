/// GET /api/offers/:id'nin listeye EK olarak verdiği alanlar
/// ("Detayları Gör" — karar B11). Konum/ücret/saat zaten listedeki
/// modelde var.
class OfferDetailModel {
  final String city;
  final String note;

  const OfferDetailModel({required this.city, required this.note});

  factory OfferDetailModel.fromMap(Map<String, dynamic> map) =>
      OfferDetailModel(
        city: map['city'] as String,
        note: map['note'] as String,
      );
}
