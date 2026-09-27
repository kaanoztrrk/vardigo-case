import 'candidate_model.dart';

/// GET /api/candidates cevabının tamamı.
class CandidateListModel {
  /// Sekme başlıklarındaki (26) / (16). Seed'de sabit etiket; listedeki
  /// gerçek adet 4 (spec 01: "case için yeterli").
  final int totalPerfect;
  final int totalSimilar;

  /// İlk yüklemede listenin başından kaç adayın seçili geleceği
  /// (referansta "1 kişi seçildi").
  final int selectedHint;

  final List<CandidateModel> candidates;

  const CandidateListModel({
    required this.totalPerfect,
    required this.totalSimilar,
    required this.selectedHint,
    required this.candidates,
  });
}
