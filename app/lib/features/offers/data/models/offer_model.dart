import 'package:equatable/equatable.dart';

import '../enum/offer_status.dart';

/// One offer from GET /api/offers.
class OfferModel extends Equatable {
  final String id;
  final String title;
  final String place;

  /// Display format ("45.000"); the UI adds ₺.
  final String pay;

  /// Used for the "Ücret" sort.
  final int payValue;

  /// Full URL; the repository resolves the server's relative path.
  final String logoUrl;
  final String district;

  /// "16 Ağu · 12:00 - 16:00", as sent by the server.
  final String when;
  final OfferStatus status;

  /// "21 saat 32 dakika", computed by the server from expiresAt. Only set
  /// for pending offers.
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

  /// Countdown turns red under 6 hours. In the reference "5 saat 32
  /// dakika" is red and "21 saat 32 dakika" is black.
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
