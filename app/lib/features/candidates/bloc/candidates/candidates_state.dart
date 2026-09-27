import '../../data/enum/candidate_sort.dart';
import '../../data/enum/candidate_tab.dart';
import '../../data/models/candidate_model.dart';

class CandidatesState {
  /// Aktif sekmenin listesi, sunucunun sıraladığı haliyle.
  final List<CandidateModel> candidates;

  final CandidateTab tab;
  final CandidateSort sort;

  /// Seçili adaylar. Sekmeler arası ORTAK: sekme değişince seçim
  /// kaybolmuyor, footer'daki N hepsini sayıyor.
  final Set<String> selectedIds;

  final int totalPerfect;
  final int totalSimilar;

  final bool loading;

  /// En az bir kez liste geldi mi. Bloc singleton ve ilk state'i de boş
  /// liste — `!loading && isEmpty` "henüz yüklenmedi" ile "gerçekten boş"u
  /// ayıramaz.
  final bool loaded;

  /// Liste HİÇ gelmediyse: ekranın yerine hata + "Tekrar dene".
  final String? error;

  /// Liste varken yenileme başarısız oldu: eski liste kalıyor, toast.
  final String? actionError;

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
    this.actionError,
  });

  int get selectedCount => selectedIds.length;

  /// Header'daki "N personel bulundu": aktif sekmenin etiketi.
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
    String? actionError,
    bool clearActionError = false,
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
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}
