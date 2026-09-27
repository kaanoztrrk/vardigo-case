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

/// Toast gösterildi — tekrar gösterilmesin.
class CandidatesActionErrorCleared extends CandidatesEvent {}
