import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/button/app_sort_chip.dart';
import '../../../core/widgets/sheet/app_sort_sheet.dart';
import '../../../core/widgets/text/app_animated_count.dart';
import '../bloc/candidates/candidates_bloc.dart';
import '../bloc/candidates/candidates_event.dart';
import '../bloc/candidates/candidates_state.dart';
import '../data/enum/candidate_sort.dart';
import '../widget/candidate_card.dart';
import '../widget/candidate_tab_bar.dart';
import '../widget/candidates_header.dart';
import '../widget/send_offer_footer.dart';

/// Screen 1: Eşleşen Personeller (employer).
///
/// Header, tabs and the "N kişi seçildi" row stay fixed. Only the cards
/// scroll, and they slide under the footer like in the reference.
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
                  AppAnimatedCount(
                    count: state.selectedCount,
                    suffix: ' kişi seçildi',
                    style: AppTextStyle.title16Semi,
                  ),
                  const Spacer(),
                  AppSortChip(
                    label: state.sort.label,
                    onTap: () => _pickSort(context, state.sort),
                  ),
                ],
              ),
            ),
            Expanded(
              // Cross-fade between loading and lists on tab/sort changes.
              // Keyed on the list contents so toggling a selection
              // doesn't trigger it.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_listKey(state)),
                  child: _List(state: state),
                ),
              ),
            ),
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

  Future<void> _pickSort(BuildContext context, CandidateSort current) async {
    final bloc = context.read<CandidatesBloc>();
    final picked = await showAppSortSheet<CandidateSort>(
      context: context,
      options: [for (final s in CandidateSort.values) (s, s.label)],
      selected: current,
    );
    if (picked != null) bloc.add(CandidatesSortSelected(picked));
  }

  static String _listKey(CandidatesState state) {
    if (!state.loaded) return state.error == null ? 'loading' : 'error';
    return state.candidates.map((c) => c.id).join(',');
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
      // Spec says "mt 8", but the reference has ~16 above the first card.
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
