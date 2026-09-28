import '../../../../core/constants/api_endpoint.dart';
import '../../../../core/services/api_service.dart';
import '../enum/candidate_sort.dart';
import '../enum/candidate_tab.dart';
import '../models/candidate_list_model.dart';
import '../models/candidate_model.dart';

class CandidateRepository {
  final ApiService _api;

  CandidateRepository(this._api);

  static const String _tag = 'CandidateRepo';

  /// Candidates for the given tab, sorted by the server. Throws a
  /// [Failure] on error.
  Future<CandidateListModel> fetchCandidates({
    required CandidateTab tab,
    required CandidateSort sort,
  }) async {
    final data =
        await _api.get(
              ApiEndpoint.candidates,
              query: {'tab': tab.value, 'sort': sort.value},
              tag: _tag,
            )
            as Map<String, dynamic>;

    return CandidateListModel(
      totalPerfect: data['totalPerfect'] as int,
      totalSimilar: data['totalSimilar'] as int,
      selectedHint: data['selectedHint'] as int? ?? 0,
      candidates: (data['candidates'] as List)
          .map(
            (c) => CandidateModel.fromMap(
              c as Map<String, dynamic>,
              assetUrl: _api.assetUrl,
            ),
          )
          .toList(),
    );
  }
}
