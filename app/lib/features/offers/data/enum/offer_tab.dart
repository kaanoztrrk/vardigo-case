/// The three tabs on screen 2. The server does the filtering;
/// answered = accepted + rejected.
enum OfferTab {
  pending('pending', 'Bekleyen', 'Bekleyen talep yok'),
  answered(
    'answered',
    'Cevaplanan',
    'Kabul veya red ettiğin talepler burada listelenir',
  ),
  expired('expired', 'Süresi Dolan', 'Süresi dolan talep yok');

  const OfferTab(this.value, this.label, this.emptyText);

  /// GET /api/offers?status=
  final String value;
  final String label;
  final String emptyText;
}
