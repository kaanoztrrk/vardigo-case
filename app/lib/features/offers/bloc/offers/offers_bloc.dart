import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/repository/offer_repository.dart';
import 'offers_event.dart';
import 'offers_state.dart';

/// Görüşme Talepleri screen (worker). Singleton (see injection.dart).
class OffersBloc extends Bloc<OffersEvent, OffersState> {
  final OfferRepository _repository;

  /// Codes meaning the offer is no longer pending. The card doesn't come
  /// back since it doesn't belong in this tab anymore; we just show why.
  static const _notPendingCodes = {'OFFER_EXPIRED', 'OFFER_STATE'};

  OffersBloc(this._repository) : super(const OffersState()) {
    on<OffersRequested>((event, emit) => _load(emit));
    on<OffersTabChanged>(_onTabChanged);
    on<OffersSortSelected>(
      (event, emit) => emit(state.copyWith(sort: event.sort)),
    );
    on<OfferAnswerRequested>(_onAnswerRequested);
    on<OfferDetailToggled>(_onDetailToggled);
    on<OffersToastShown>(
      (event, emit) => emit(state.copyWith(clearActionError: true)),
    );
  }

  Future<void> _onTabChanged(
    OffersTabChanged event,
    Emitter<OffersState> emit,
  ) async {
    if (event.tab == state.tab) return;
    // Switch the tab right away and clear the old cards, otherwise they'd
    // show up with the wrong buttons until the new list arrives. Resetting
    // `loaded` makes the screen show the loading state; the 60s refresh
    // doesn't touch it, so it updates silently.
    emit(state.copyWith(tab: event.tab, offers: const [], loaded: false));
    await _load(emit);
  }

  /// Optimistic: the card leaves the list right away and the request goes
  /// out after. If it fails, the card is put back.
  Future<void> _onAnswerRequested(
    OfferAnswerRequested event,
    Emitter<OffersState> emit,
  ) async {
    final index = state.offers.indexWhere((o) => o.id == event.offerId);
    if (index == -1) return;
    final offer = state.offers[index];
    final tab = state.tab;
    emit(
      state.copyWith(
        offers: [...state.offers]..removeAt(index),
        expandedIds: state.expandedIds.difference({offer.id}),
      ),
    );

    try {
      if (event.accept) {
        await _repository.accept(offer.id);
      } else {
        await _repository.reject(offer.id);
      }
    } on Failure catch (f) {
      final restore =
          !_notPendingCodes.contains(f.code) &&
          tab == state.tab &&
          !state.offers.any((o) => o.id == offer.id);
      emit(
        state.copyWith(
          offers: restore
              ? ([...state.offers]
                  ..insert(index.clamp(0, state.offers.length), offer))
              : null,
          actionError: f.message,
        ),
      );
    }
  }

  Future<void> _onDetailToggled(
    OfferDetailToggled event,
    Emitter<OffersState> emit,
  ) async {
    final id = event.offerId;
    if (state.expandedIds.contains(id)) {
      emit(state.copyWith(expandedIds: state.expandedIds.difference({id})));
      return;
    }
    emit(state.copyWith(expandedIds: {...state.expandedIds, id}));
    if (state.details.containsKey(id)) return;

    try {
      final detail = await _repository.fetchDetail(id);
      emit(state.copyWith(details: {...state.details, id: detail}));
    } on Failure catch (f) {
      emit(
        state.copyWith(
          expandedIds: state.expandedIds.difference({id}),
          actionError: f.message,
        ),
      );
    }
  }

  Future<void> _load(Emitter<OffersState> emit) async {
    final tab = state.tab;
    emit(state.copyWith(loading: true, clearError: true));

    try {
      final result = await _repository.fetchOffers(tab);
      // Ignore late responses for a tab that's no longer active (same
      // guard as in CandidatesBloc).
      if (tab != state.tab) return;
      emit(
        state.copyWith(
          offers: result.offers,
          pendingCount: result.pendingCount,
          loading: false,
          loaded: true,
        ),
      );
    } on Failure catch (f) {
      if (tab != state.tab) return;
      emit(
        state.loaded
            ? state.copyWith(loading: false, actionError: f.message)
            : state.copyWith(loading: false, error: f.message),
      );
    }
  }
}
