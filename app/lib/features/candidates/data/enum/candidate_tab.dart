/// Ekranın iki sekmesi. Ayrımı sunucu yapıyor: score >= 80 → perfect
/// (bkz. server/src/candidates.js).
enum CandidateTab {
  perfect('perfect'),
  similar('similar');

  const CandidateTab(this.value);

  /// GET /api/candidates?tab=
  final String value;
}
