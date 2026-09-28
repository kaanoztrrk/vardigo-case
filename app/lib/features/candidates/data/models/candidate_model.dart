import 'package:equatable/equatable.dart';

/// One candidate from GET /api/candidates.
///
/// Numbers like rating and km arrive as display strings ("4.9",
/// "%100 katılım", "4.9 km"). Sorting happens on the server and the client
/// never does math on them, which is also why `score` / `perfect` aren't
/// in the model.
class CandidateModel extends Equatable {
  final String id;
  final String name;
  final String rating;
  final String attend;
  final String km;

  /// Full URL; the repository resolves the server's relative path.
  final String photoUrl;
  final bool online;

  /// Expected monthly pay like "25.000" (the UI adds ₺).
  final String expectedPay;

  /// Whether it matches the employer's offer (green / orange on the card).
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
