/// Ekran 2'nin sıralamaları, paneldeki sırasıyla (karar B10).
///
/// Ekran 1'in tersine sıralama İSTEMCİDE: GET /offers'ın sort parametresi
/// yok (spec 03) ve liste zaten birkaç kayıt.
enum OfferSort {
  /// Sunucunun sırası: en yeni talep üstte.
  recommended('Önerilen'),

  /// Süresi en yakında dolan üstte.
  time('Süre'),

  /// Ücreti en yüksek üstte.
  pay('Ücret');

  const OfferSort(this.label);

  final String label;
}
