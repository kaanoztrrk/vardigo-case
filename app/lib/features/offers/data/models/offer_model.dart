import 'package:equatable/equatable.dart';

import '../enum/offer_status.dart';

/// GET /api/offers listesindeki bir görüşme talebi.
class OfferModel extends Equatable {
  final String id;
  final String title;
  final String place;

  /// Ekrandaki biçim ("45.000"); ₺ öneki ekranda (karar D4).
  final String pay;

  /// "Ücret" sıralaması için.
  final int payValue;

  /// TAM adres — repository sunucunun göreli yolunu çeviriyor.
  final String logoUrl;
  final String district;

  /// "16 Ağu · 12:00 - 16:00" — sunucudaki gibi (karar D10).
  final String when;
  final OfferStatus status;

  /// "21 saat 32 dakika" — sunucu expiresAt'ten hesaplıyor (spec 03);
  /// yalnızca bekleyen talepte dolu.
  final String? remain;
  final DateTime expiresAt;

  const OfferModel({
    required this.id,
    required this.title,
    required this.place,
    required this.pay,
    required this.payValue,
    required this.logoUrl,
    required this.district,
    required this.when,
    required this.status,
    required this.remain,
    required this.expiresAt,
  });

  factory OfferModel.fromMap(
    Map<String, dynamic> map, {
    required String Function(String path) assetUrl,
  }) {
    return OfferModel(
      id: map['id'] as String,
      title: map['title'] as String,
      place: map['place'] as String,
      pay: map['pay'] as String,
      payValue: map['payValue'] as int,
      logoUrl: assetUrl(map['logo'] as String),
      district: map['district'] as String,
      when: map['when'] as String,
      status: OfferStatus.fromValue(map['status'] as String?),
      remain: map['remain'] as String?,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }

  /// 6 saatten az kaldıysa geri sayım kırmızı (karar D6; referansta
  /// "5 saat 32 dakika" kırmızı, "21 saat 32 dakika" siyah).
  bool isUrgent(DateTime now) =>
      expiresAt.difference(now) < const Duration(hours: 6);

  OfferModel copyWith({OfferStatus? status}) => OfferModel(
    id: id,
    title: title,
    place: place,
    pay: pay,
    payValue: payValue,
    logoUrl: logoUrl,
    district: district,
    when: when,
    status: status ?? this.status,
    remain: remain,
    expiresAt: expiresAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    place,
    pay,
    payValue,
    logoUrl,
    district,
    when,
    status,
    remain,
    expiresAt,
  ];
}
