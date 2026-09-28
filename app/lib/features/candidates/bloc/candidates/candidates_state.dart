import '../../data/enum/candidate_sort.dart';
import '../../data/enum/candidate_tab.dart';
import '../../data/models/candidate_model.dart';

class CandidatesState {
  /// Active tab's list, in the server's order.
  final List<CandidateModel> candidates;

  final CandidateTab tab;
  final CandidateSort sort;

  /// Selected candidates, shared across tabs. Switching tabs keeps the
  /// selection, and the N in the footer counts all of them.
  final Set<String> selectedIds;

  final int totalPerfect;
  final int totalSimilar;

  final bool loading;

  /// Whether a list has loaded at least once. The initial state is also an
  /// empty list, so `!loading && isEmpty` can't tell "not loaded yet"
  /// from "actually empty".
  final bool loaded;

  /// Set when nothing has loaded yet; the screen shows an error and
  /// "Tekrar dene".
  final String? error;

  /// Offers are being sent; the button is disabled.
  final bool sending;

  /// One-off error toast when a refresh or send fails while a list is
  /// already showing (the old list stays).
  final String? actionError;

  /// One-off info toast ("2 kişiye görüşme talebi gönderildi.").
  final String? actionMessage;

  const CandidatesState({
    this.candidates = const [],
    this.tab = CandidateTab.perfect,
    this.sort = CandidateSort.recommended,
    this.selectedIds = const {},
    this.totalPerfect = 0,
    this.totalSimilar = 0,
    this.loading = false,
    this.loaded = false,
    this.error,
    this.sending = false,
    this.actionError,
    this.actionMessage,
  });

  int get selectedCount => selectedIds.length;

  /// "N personel bulundu" in the header, taken from the active tab.
  int get activeTotal =>
      tab == CandidateTab.perfect ? totalPerfect : totalSimilar;

  CandidatesState copyWith({
    List<CandidateModel>? candidates,
    CandidateTab? tab,
    CandidateSort? sort,
    Set<String>? selectedIds,
    int? totalPerfect,
    int? totalSimilar,
    bool? loading,
    bool? loaded,
    String? error,
    bool clearError = false,
    bool? sending,
    String? actionError,
    bool clearActionError = false,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return CandidatesState(
      candidates: candidates ?? this.candidates,
      tab: tab ?? this.tab,
      sort: sort ?? this.sort,
      selectedIds: selectedIds ?? this.selectedIds,
      totalPerfect: totalPerfect ?? this.totalPerfect,
      totalSimilar: totalSimilar ?? this.totalSimilar,
      loading: loading ?? this.loading,
      loaded: loaded ?? this.loaded,
      error: clearError ? null : (error ?? this.error),
      sending: sending ?? this.sending,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
    );
  }
}
