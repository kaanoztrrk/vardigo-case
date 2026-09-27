import 'package:equatable/equatable.dart';

/// GET /api/candidates listesindeki bir aday.
///
/// Sayısal alanlar (rating, km...) sunucudan EKRANDA GÖRÜNDÜĞÜ GİBİ metin
/// geliyor ("4.9", "%100 katılım", "4.9 km"): sıralama sunucuda, istemci
/// bunlarla hesap yapmıyor. `score` / `perfect` bu yüzden modele alınmadı.
class CandidateModel extends Equatable {
  final String id;
  final String name;
  final String rating;
  final String attend;
  final String km;

  /// TAM adres — repository sunucunun göreli yolunu çeviriyor.
  final String photoUrl;
  final bool online;

  /// Aylık ücret beklentisi, "25.000" biçiminde (₺ öneki ekranda).
  final String expectedPay;

  /// Beklenti işverenin teklifiyle uyuşuyor mu (kartta yeşil / turuncu).
  final bool payMatch;

  const CandidateModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.attend,
    required this.km,
    required this.photoUrl,
    required this.online,
    required this.expectedPay,
    required this.payMatch,
  });

  factory CandidateModel.fromMap(
    Map<String, dynamic> map, {
    required String Function(String path) assetUrl,
  }) {
    return CandidateModel(
      id: map['id'] as String,
      name: map['name'] as String,
      rating: map['rating'] as String,
      attend: map['attend'] as String,
      km: map['km'] as String,
      photoUrl: assetUrl(map['photo'] as String),
      online: map['online'] as bool? ?? false,
      expectedPay: map['expectedPay'] as String,
      payMatch: map['payMatch'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    rating,
    attend,
    km,
    photoUrl,
    online,
    expectedPay,
    payMatch,
  ];
}
