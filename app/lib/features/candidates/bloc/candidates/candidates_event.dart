import '../../data/enum/candidate_sort.dart';
import '../../data/enum/candidate_tab.dart';

abstract class CandidatesEvent {}

/// (Re)load with the current tab and sort. Used on open and by
/// "Tekrar dene".
class CandidatesRequested extends CandidatesEvent {}

class CandidatesTabChanged extends CandidatesEvent {
  final CandidateTab tab;

  CandidatesTabChanged(this.tab);
}

/// An option was picked in the sort sheet.
class CandidatesSortSelected extends CandidatesEvent {
  final CandidateSort sort;

  CandidatesSortSelected(this.sort);
}

class CandidateSelectionToggled extends CandidatesEvent {
  final String candidateId;

  CandidateSelectionToggled(this.candidateId);
}

/// "Görüşme Talebi Gönder (N)": send offers to the selected candidates.
class CandidatesOffersSendRequested extends CandidatesEvent {}

/// The toast was shown; clear it so it doesn't show again.
class CandidatesToastShown extends CandidatesEvent {}
