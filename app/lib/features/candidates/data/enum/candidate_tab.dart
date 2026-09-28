/// The two tabs. The server does the split: score >= 80 is perfect
/// (see server/src/candidates.js).
enum CandidateTab {
  perfect('perfect'),
  similar('similar');

  const CandidateTab(this.value);

  /// GET /api/candidates?tab=
  final String value;
}
