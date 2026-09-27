import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/button/app_sort_chip.dart';
import '../bloc/candidates/candidates_bloc.dart';
import '../bloc/candidates/candidates_event.dart';
import '../bloc/candidates/candidates_state.dart';
import '../widget/candidate_card.dart';
import '../widget/candidate_tab_bar.dart';
import '../widget/candidates_header.dart';
import '../widget/send_offer_footer.dart';

/// Ekran 1 — Eşleşen Personeller (işveren).
///
/// Header, sekmeler ve "N kişi seçildi" satırı sabit; yalnızca kartlar
/// kayıyor ve referanstaki gibi footer'ın altına giriyor.
class CandidatesView extends StatefulWidget {
  const CandidatesView({super.key});

  @override
  State<CandidatesView> createState() => _CandidatesViewState();
}

class _CandidatesViewState extends State<CandidatesView> {
  @override
  void initState() {
    super.initState();
    context.read<CandidatesBloc>().add(CandidatesRequested());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CandidatesBloc>();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: BlocConsumer<CandidatesBloc, CandidatesState>(
        listenWhen: (prev, curr) =>
            (curr.actionError != null &&
                prev.actionError != curr.actionError) ||
            (curr.actionMessage != null &&
                prev.actionMessage != curr.actionMessage),
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionError ?? state.actionMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
          bloc.add(CandidatesToastShown());
        },
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 16,
                20,
                8,
              ),
              child: Column(
                children: [
                  CandidatesHeader(total: state.activeTotal),
                  const SizedBox(height: 20),
                  CandidateTabBar(
                    active: state.tab,
                    totalPerfect: state.totalPerfect,
                    totalSimilar: state.totalSimilar,
                    onChanged: (tab) => bloc.add(CandidatesTabChanged(tab)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Text(
                    '${state.selectedCount} kişi seçildi',
                    style: AppTextStyle.title16Semi,
                  ),
                  const Spacer(),
                  AppSortChip(
                    label: state.sort.label,
                    onTap: () => bloc.add(CandidatesSortCycled()),
                  ),
                ],
              ),
            ),
            Expanded(child: _List(state: state)),
            SendOfferFooter(
              count: state.selectedCount,
              sending: state.sending,
              onSend: () => bloc.add(CandidatesOffersSendRequested()),
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.state});

  final CandidatesState state;

  @override
  Widget build(BuildContext context) {
    if (!state.loaded) {
      if (state.error != null) {
        return _Error(
          message: state.error!,
          onRetry: () =>
              context.read<CandidatesBloc>().add(CandidatesRequested()),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      // Spec "mt 8" diyor; referansta seçim satırı ile ilk kart arası ~16.
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: state.candidates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final candidate = state.candidates[i];
        return CandidateCard(
          candidate: candidate,
          selected: state.selectedIds.contains(candidate.id),
          onTap: () => context.read<CandidatesBloc>().add(
            CandidateSelectionToggled(candidate.id),
          ),
        );
      },
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyle.caption13,
          ),
          TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
        ],
      ),
    ),
  );
}
