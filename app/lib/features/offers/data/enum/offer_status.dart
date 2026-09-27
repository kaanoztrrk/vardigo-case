enum OfferStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  expired('expired');

  const OfferStatus(this.value);

  final String value;

  /// Bilinmeyen bir değer gelirse `expired`: yanıtlanamayan bir talebe
  /// buton göstermek, göstermemekten daha kötü.
  static OfferStatus fromValue(String? value) => values.firstWhere(
    (s) => s.value == value,
    orElse: () => OfferStatus.expired,
  );
}
