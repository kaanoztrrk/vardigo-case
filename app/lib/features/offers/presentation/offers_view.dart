import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/button/app_sort_chip.dart';
import '../../../core/widgets/sheet/app_sort_sheet.dart';
import '../bloc/offers/offers_bloc.dart';
import '../bloc/offers/offers_event.dart';
import '../bloc/offers/offers_state.dart';
import '../data/enum/offer_sort.dart';
import '../widget/offer_card.dart';
import '../widget/offer_list.dart';
import '../widget/offer_tab_bar.dart';
import '../widget/offers_header.dart';

/// Ekran 2 — Görüşme Talepleri (iş arayan).
///
/// Header ve sekmeler sabit; sort chip ve kartlar kayıyor. Footer yok
/// (spec 02).
class OffersView extends StatefulWidget {
  const OffersView({super.key});

  @override
  State<OffersView> createState() => _OffersViewState();
}

class _OffersViewState extends State<OffersView> {
  /// Geri sayım metnini sunucu üretiyor (spec 03); ekran açıkken dakikada
  /// bir liste tazeleniyor ki "21 saat 32 dakika" ilerlesin (karar B6).
  /// Zamanlayıcı ekranda: ekran kapanınca tazeleme de durmalı.
  static const _refreshEvery = Duration(seconds: 60);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<OffersBloc>();
    bloc.add(OffersRequested());
    _timer = Timer.periodic(_refreshEvery, (_) => bloc.add(OffersRequested()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OffersBloc>();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: BlocConsumer<OffersBloc, OffersState>(
        listenWhen: (prev, curr) =>
            curr.actionError != null && prev.actionError != curr.actionError,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionError!),
              behavior: SnackBarBehavior.floating,
            ),
          );
          bloc.add(OffersToastShown());
        },
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 12,
                20,
                8,
              ),
              child: Column(
                children: [
                  OffersHeader(subtitle: state.subtitle),
                  const SizedBox(height: 16),
                  OfferTabBar(
                    active: state.tab,
                    onChanged: (tab) => bloc.add(OffersTabChanged(tab)),
                  ),
                ],
              ),
            ),
            Expanded(
              // Yükleniyor ↔ liste ↔ (sekme / sıralama değişince) yeni liste
              // arasında yumuşak geçiş. Aynı sekmedeki kart ekleme /
              // çıkarma ise OfferList'in kendi animasyonu.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                child: KeyedSubtree(
                  key: ValueKey(_bodyKey(state)),
                  child: _List(state: state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _bodyKey(OffersState state) {
  if (!state.loaded && state.error != null) return 'error';
  if (!state.loaded) return 'loading';
  return 'list|${state.tab.name}|${state.sort.name}';
}

class _List extends StatelessWidget {
  const _List({required this.state});

  final OffersState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OffersBloc>();
    final offers = state.visibleOffers;

    if (!state.loaded && state.error != null) {
      return _Message(
        text: state.error!,
        onRetry: () => bloc.add(OffersRequested()),
      );
    }
    if (!state.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    return OfferList(
      offers: offers,
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      header: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: AppSortChip(
            label: state.sort.label,
            onTap: () => _pickSort(context, state.sort),
          ),
        ),
      ),
      empty: _Message(text: state.tab.emptyText),
      itemBuilder: (offer) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OfferCard(
          key: ValueKey(offer.id),
          offer: offer,
          now: now,
          expanded: state.expandedIds.contains(offer.id),
          detail: state.details[offer.id],
          onAccept: () =>
              bloc.add(OfferAnswerRequested(offer.id, accept: true)),
          onReject: () =>
              bloc.add(OfferAnswerRequested(offer.id, accept: false)),
          onToggleDetail: () => bloc.add(OfferDetailToggled(offer.id)),
        ),
      ),
    );
  }

  Future<void> _pickSort(BuildContext context, OfferSort current) async {
    final bloc = context.read<OffersBloc>();
    final picked = await showAppSortSheet<OfferSort>(
      context: context,
      options: [for (final s in OfferSort.values) (s, s.label)],
      selected: current,
    );
    if (picked != null) bloc.add(OffersSortSelected(picked));
  }
}

/// Boş state (spec 02: py 40, center, 14/400 #5C5C5C) ve hata.
class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyle.label14.copyWith(
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: AppColors.sub,
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
      ],
    ),
  );
}
