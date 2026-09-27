/// Ekran 1'in sıralamaları, paneldeki sırasıyla. Sıralamayı sunucu
/// yapıyor. (Spec 01 chip'e basınca döngü diyor; panele çevrildi — bkz.
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
