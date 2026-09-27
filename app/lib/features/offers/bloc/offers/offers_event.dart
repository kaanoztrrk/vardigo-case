import '../../data/enum/offer_sort.dart';
import '../../data/enum/offer_tab.dart';

abstract class OffersEvent {}

/// Mevcut sekmeyi (yeniden) yükle — ekran açılışı, "Tekrar dene" ve geri
/// sayımın 60 sn'lik tazelemesi (karar B6).
class OffersRequested extends OffersEvent {}

class OffersTabChanged extends OffersEvent {
  final OfferTab tab;

  OffersTabChanged(this.tab);
}

/// Sıralama panelinden bir seçenek seçildi.
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

/// "Detayları Gör": kartın altındaki detayı aç / kapat.
class OfferDetailToggled extends OffersEvent {
  final String offerId;

  OfferDetailToggled(this.offerId);
}

/// Toast gösterildi — tekrar gösterilmesin.
class OffersToastShown extends OffersEvent {}
