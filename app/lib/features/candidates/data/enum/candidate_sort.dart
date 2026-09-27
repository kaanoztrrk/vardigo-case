/// Sort chip'in döngüsü: Önerilen → En Yakın → Puan → Önerilen
/// (spec 01 → "tıklayınca döngü"). Sıralamayı sunucu yapıyor.
enum CandidateSort {
  recommended('recommended', 'Önerilen'),
  near('near', 'En Yakın'),
  rating('rating', 'Puan');

  const CandidateSort(this.value, this.label);

  /// GET /api/candidates?sort=
  final String value;
  final String label;

  CandidateSort get next => values[(index + 1) % values.length];
}
