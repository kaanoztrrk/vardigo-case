import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../data/repository/candidate_repository.dart';
import 'candidates_event.dart';
import 'candidates_state.dart';

/// Eşleşen Personeller ekranı. Singleton (bkz. injection.dart).
class CandidatesBloc extends Bloc<CandidatesEvent, CandidatesState> {
  final CandidateRepository _repository;

  CandidatesBloc(this._repository) : super(const CandidatesState()) {
    on<CandidatesRequested>((event, emit) => _load(emit));
    on<CandidatesTabChanged>(_onTabChanged);
    on<CandidatesSortCycled>(_onSortCycled);
    on<CandidateSelectionToggled>(_onSelectionToggled);
    on<CandidatesActionErrorCleared>(
      (event, emit) => emit(state.copyWith(clearActionError: true)),
    );
  }

  // Sekme ve sıralama state'e HEMEN yazılıyor (pill / chip beklemeden
  // değişsin), liste sunucudan gelince yenileniyor.

  Future<void> _onTabChanged(
    CandidatesTabChanged event,
    Emitter<CandidatesState> emit,
  ) async {
    if (event.tab == state.tab) return;
    emit(state.copyWith(tab: event.tab));
    await _load(emit);
  }

  Future<void> _onSortCycled(
    CandidatesSortCycled event,
    Emitter<CandidatesState> emit,
  ) async {
    emit(state.copyWith(sort: state.sort.next));
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

  Future<void> _load(Emitter<CandidatesState> emit) async {
    final tab = state.tab;
    final sort = state.sort;
    emit(state.copyWith(loading: true, clearError: true));

    try {
      final result = await _repository.fetchCandidates(tab: tab, sort: sort);

      // Arka arkaya sekme/sıralama değişiminde cevaplar sırasız gelebilir:
      // artık ekranda olmayan bir isteğin cevabı listeyi ezmesin.
      if (tab != state.tab || sort != state.sort) return;

      emit(
        state.copyWith(
          candidates: result.candidates,
          totalPerfect: result.totalPerfect,
          totalSimilar: result.totalSimilar,
          // Referanstaki "1 kişi seçildi" — yalnızca İLK yüklemede;
          // sonrasında seçim kullanıcının.
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
