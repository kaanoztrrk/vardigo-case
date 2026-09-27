import '../../data/enum/offer_sort.dart';
import '../../data/enum/offer_tab.dart';
import '../../data/models/offer_detail_model.dart';
import '../../data/models/offer_model.dart';

class OffersState {
  /// Aktif sekmenin listesi, SUNUCUNUN sırasıyla (en yeni üstte).
  /// Ekran [visibleOffers]'ı çiziyor.
  final List<OfferModel> offers;

  final OfferTab tab;
  final OfferSort sort;

  /// "N talep yanıt bekliyor" etiketi.
  final int pendingCount;

  /// Detayı açık kartlar.
  final Set<String> expandedIds;

  /// GET /offers/:id sonuçları — bir kez çekilen detay tekrar çekilmiyor.
  final Map<String, OfferDetailModel> details;

  final bool loading;

  /// En az bir kez liste geldi mi (CandidatesState'teki aynı gerekçe).
  final bool loaded;

  /// Liste HİÇ gelmediyse: ekranın yerine hata + "Tekrar dene".
  final String? error;

  /// Tek seferlik hata toast'ı.
  final String? actionError;

  const OffersState({
    this.offers = const [],
    this.tab = OfferTab.pending,
    this.sort = OfferSort.recommended,
    this.pendingCount = 0,
    this.expandedIds = const {},
    this.details = const {},
    this.loading = false,
    this.loaded = false,
    this.error,
    this.actionError,
  });

  /// Sıralama istemcide (karar B10). Eşitlikte sunucunun sırası korunuyor
  /// (List.sort kararlı değil, o yüzden index ile).
  List<OfferModel> get visibleOffers {
    if (sort == OfferSort.recommended) return offers;
    final indexed = offers.indexed.toList();
    indexed.sort((a, b) {
      final byKey = switch (sort) {
        OfferSort.time => a.$2.expiresAt.compareTo(b.$2.expiresAt),
        OfferSort.pay => b.$2.payValue.compareTo(a.$2.payValue),
        OfferSort.recommended => 0,
      };
      return byKey != 0 ? byKey : a.$1.compareTo(b.$1);
    });
    return indexed.map((e) => e.$2).toList();
  }

  /// Header'daki alt başlık (spec 02).
  String get subtitle => switch (tab) {
    OfferTab.pending => '$pendingCount talep yanıt bekliyor',
    OfferTab.answered => 'Cevaplanan talepler',
    OfferTab.expired => 'Süresi dolan talepler',
  };

  OffersState copyWith({
    List<OfferModel>? offers,
    OfferTab? tab,
    OfferSort? sort,
    int? pendingCount,
    Set<String>? expandedIds,
    Map<String, OfferDetailModel>? details,
    bool? loading,
    bool? loaded,
    String? error,
    bool clearError = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return OffersState(
      offers: offers ?? this.offers,
      tab: tab ?? this.tab,
      sort: sort ?? this.sort,
      pendingCount: pendingCount ?? this.pendingCount,
      expandedIds: expandedIds ?? this.expandedIds,
      details: details ?? this.details,
      loading: loading ?? this.loading,
      loaded: loaded ?? this.loaded,
      error: clearError ? null : (error ?? this.error),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}
