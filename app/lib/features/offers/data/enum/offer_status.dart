enum OfferStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  expired('expired');

  const OfferStatus(this.value);

  final String value;

  /// Unknown values fall back to `expired`. Showing answer buttons on an
  /// offer that can't be answered is worse than hiding them.
  static OfferStatus fromValue(String? value) => values.firstWhere(
    (s) => s.value == value,
    orElse: () => OfferStatus.expired,
  );
}
