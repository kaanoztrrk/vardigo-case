import 'candidate_model.dart';

/// Full GET /api/candidates response.
class CandidateListModel {
  /// The (26) / (16) in the tab titles. Fixed labels from the seed; the
  /// actual list has 4 (the spec says that's enough).
  final int totalPerfect;
  final int totalSimilar;

  /// How many candidates from the top start selected on first load
  /// ("1 kişi seçildi" in the reference).
  final int selectedHint;

  final List<CandidateModel> candidates;

  const CandidateListModel({
    required this.totalPerfect,
    required this.totalSimilar,
    required this.selectedHint,
    required this.candidates,
  });
}
