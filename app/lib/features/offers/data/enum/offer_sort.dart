/// Sort options for screen 2, in sheet order.
///
/// Unlike screen 1, sorting happens on the client: GET /offers has no sort
/// param in the spec, and the list is only a few items.
enum OfferSort {
  /// Server order, newest first.
  recommended('Önerilen'),

  /// Soonest to expire first.
  time('Süre'),

  /// Highest pay first.
  pay('Ücret');

  const OfferSort(this.label);

  final String label;
}
