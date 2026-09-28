import '../../data/enum/offer_sort.dart';
import '../../data/enum/offer_tab.dart';

abstract class OffersEvent {}

/// (Re)load the current tab. Used on open, by "Tekrar dene", and by the
/// 60s countdown refresh.
class OffersRequested extends OffersEvent {}

class OffersTabChanged extends OffersEvent {
  final OfferTab tab;

  OffersTabChanged(this.tab);
}

/// An option was picked in the sort sheet.
class OffersSortSelected extends OffersEvent {
  final OfferSort sort;

  OffersSortSelected(this.sort);
}

/// İlgileniyorum ([accept] true) / İlgilenmiyorum ([accept] false).
class OfferAnswerRequested extends OffersEvent {
  final String offerId;
  final bool accept;

  OfferAnswerRequested(this.offerId, {required this.accept});
}

/// "Detayları Gör": expand / collapse the detail under the card.
class OfferDetailToggled extends OffersEvent {
  final String offerId;

  OfferDetailToggled(this.offerId);
}

/// The toast was shown; clear it so it doesn't show again.
class OffersToastShown extends OffersEvent {}
