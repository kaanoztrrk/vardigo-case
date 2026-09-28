import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../offers/data/repository/offer_repository.dart';
import '../../data/repository/candidate_repository.dart';
import 'candidates_event.dart';
import 'candidates_state.dart';

/// Eşleşen Personeller screen. Singleton (see injection.dart).
class CandidatesBloc extends Bloc<CandidatesEvent, CandidatesState> {
  final CandidateRepository _repository;
  final OfferRepository _offerRepository;

  /// id → name for every candidate loaded so far. Selection is shared
  /// across tabs, so a candidate in a 409 might not be in the current
  /// list, and we still want to show their name.
  final Map<String, String> _names = {};

  CandidatesBloc(this._repository, this._offerRepository)
    : super(const CandidatesState()) {
    on<CandidatesRequested>((event, emit) => _load(emit));
    on<CandidatesTabChanged>(_onTabChanged);
    on<CandidatesSortSelected>(_onSortSelected);
    on<CandidateSelectionToggled>(_onSelectionToggled);
    on<CandidatesOffersSendRequested>(_onOffersSendRequested);
    on<CandidatesToastShown>(
      (event, emit) => emit(
        state.copyWith(clearActionError: true, clearActionMessage: true),
      ),
    );
  }

  // Tab and sort update the state right away so the pill and chip react
  // immediately; the list follows when the server responds.

  Future<void> _onTabChanged(
    CandidatesTabChanged event,
    Emitter<CandidatesState> emit,
  ) async {
    if (event.tab == state.tab) return;
    emit(state.copyWith(tab: event.tab));
    await _load(emit);
  }

  Future<void> _onSortSelected(
    CandidatesSortSelected event,
    Emitter<CandidatesState> emit,
  ) async {
    if (event.sort == state.sort) return;
    emit(state.copyWith(sort: event.sort));
    await _load(emit);
  }

  void _onSelectionToggled(
    CandidateSelectionToggled event,
    Emitter<CandidatesState> emit,
  ) {
    final selected = {...state.selectedIds};
    if (!selected.remove(event.candidateId)) selected.add(event.candidateId);
    emit(state.copyWith(selectedIds: selected));
  }

  Future<void> _onOffersSendRequested(
    CandidatesOffersSendRequested event,
    Emitter<CandidatesState> emit,
  ) async {
    // The button is already disabled, but guard against double events.
    if (state.sending || state.selectedIds.isEmpty) return;
    final ids = state.selectedIds.toList();
    emit(state.copyWith(sending: true));

    try {
      await _offerRepository.sendOffers(ids);
      emit(
        state.copyWith(
          sending: false,
          selectedIds: const {},
          actionMessage: '${ids.length} kişiye görüşme talebi gönderildi.',
        ),
      );
    } on Failure catch (f) {
      if (f.code == 'OFFER_EXISTS') {
        // The server is all-or-nothing, so nothing was sent. Drop the
        // conflicting ones from the selection so the rest can be resent
        // with one tap. The server message has ids (w_merve); we show
        // names instead.
        final names = f.ids.map((id) => _names[id] ?? id).join(', ');
        emit(
          state.copyWith(
            sending: false,
            selectedIds: state.selectedIds.difference(f.ids.toSet()),
            actionError:
                '$names için zaten bekleyen bir talep var, seçimden çıkarıldı.',
          ),
        );
        return;
      }
      emit(state.copyWith(sending: false, actionError: f.message));
    }
  }

  Future<void> _load(Emitter<CandidatesState> emit) async {
    final tab = state.tab;
    final sort = state.sort;
    emit(state.copyWith(loading: true, clearError: true));

    try {
      final result = await _repository.fetchCandidates(tab: tab, sort: sort);

      // Quick tab/sort changes can return out of order. Ignore responses
      // for a tab or sort that's no longer active.
      if (tab != state.tab || sort != state.sort) return;

      for (final c in result.candidates) {
        _names[c.id] = c.name;
      }
      emit(
        state.copyWith(
          candidates: result.candidates,
          totalPerfect: result.totalPerfect,
          totalSimilar: result.totalSimilar,
          // "1 kişi seçildi" from the reference, only on the first load.
          // After that the selection is up to the user.
          selectedIds: state.loaded
              ? null
              : result.candidates
                    .take(result.selectedHint)
                    .map((c) => c.id)
                    .toSet(),
          loading: false,
          loaded: true,
        ),
      );
    } on Failure catch (f) {
      if (tab != state.tab || sort != state.sort) return;
      emit(
        state.loaded
            ? state.copyWith(loading: false, actionError: f.message)
            : state.copyWith(loading: false, error: f.message),
      );
    }
  }
}
