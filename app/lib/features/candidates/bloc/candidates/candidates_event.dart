import '../../data/enum/candidate_sort.dart';
import '../../data/enum/candidate_tab.dart';

abstract class CandidatesEvent {}

/// Listeyi mevcut sekme + sıralamayla (yeniden) yükle — ekran açılışı ve
/// "Tekrar dene".
class CandidatesRequested extends CandidatesEvent {}

class CandidatesTabChanged extends CandidatesEvent {
  final CandidateTab tab;

  CandidatesTabChanged(this.tab);
}

/// Sıralama panelinden bir seçenek seçildi.
class CandidatesSortSelected extends CandidatesEvent {
  final CandidateSort sort;

  CandidatesSortSelected(this.sort);
}

class CandidateSelectionToggled extends CandidatesEvent {
  final String candidateId;

  CandidateSelectionToggled(this.candidateId);
}

/// Footer'daki "Görüşme Talebi Gönder (N)": seçili adaylara talep gönder.
class CandidatesOffersSendRequested extends CandidatesEvent {}

/// Toast gösterildi — tekrar gösterilmesin.
class CandidatesToastShown extends CandidatesEvent {}
