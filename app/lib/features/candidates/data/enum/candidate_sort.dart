/// Sort options for screen 1, in sheet order. The server does the sorting.
/// (Spec 01 cycles on tap; this uses a sheet instead, see
/// showAppSortSheet.)
enum CandidateSort {
  recommended('recommended', 'Önerilen'),
  near('near', 'En Yakın'),
  rating('rating', 'Puan');

  const CandidateSort(this.value, this.label);

  /// GET /api/candidates?sort=
  final String value;
  final String label;
}
