import '../../data/enum/candidate_tab.dart';

abstract class CandidatesEvent {}

/// Listeyi mevcut sekme + sıralamayla (yeniden) yükle — ekran açılışı ve
/// "Tekrar dene".
class CandidatesRequested extends CandidatesEvent {}

class CandidatesTabChanged extends CandidatesEvent {
  final CandidateTab tab;

  CandidatesTabChanged(this.tab);
}

/// Sort chip'e dokunuldu: sıradaki sıralamaya geç (bkz. CandidateSort.next).
class CandidatesSortCycled extends CandidatesEvent {}

class CandidateSelectionToggled extends CandidatesEvent {
  final String candidateId;

  CandidateSelectionToggled(this.candidateId);
}

/// Footer'daki "Görüşme Talebi Gönder (N)": seçili adaylara talep gönder.
class CandidatesOffersSendRequested extends CandidatesEvent {}

/// Toast gösterildi — tekrar gösterilmesin.
class CandidatesToastShown extends CandidatesEvent {}
