/// Extra fields GET /api/offers/:id adds on top of the list item, for
/// "Detayları Gör". Location, pay and time are already in the list model.
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
