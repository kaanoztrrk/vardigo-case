import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../data/models/offer_model.dart';

/// Talep listesi — kart çıkınca / geri gelince animasyonlu.
///
/// Bloc listeyi tek seferde değiştiriyor (iyimser yanıtta kart düşüyor,
/// hata olursa geri konuyor). Bu widget eski ve yeni listeyi id'ye göre
/// karşılaştırıp farkı [SliverAnimatedList]'e çeviriyor: çıkan kart
/// solup sağa kayarak küçülüyor, alttakiler yukarı kayıyor; gelen kart
/// tersine açılıyor.
///
/// Sekme / sıralama değişiminde çağıran taraf bu widget'ı YENİ bir
/// anahtarla kuruyor (tüm liste yumuşak geçişle yenileniyor); burada
/// yalnızca aynı sekmedeki ekleme / çıkarma animasyonlu.
class OfferList extends StatefulWidget {
  const OfferList({
    super.key,
    required this.offers,
    required this.header,
    required this.empty,
    required this.itemBuilder,
    required this.padding,
  });

  final List<OfferModel> offers;

  /// Listenin üstünde kayan satır (sort chip).
  final Widget header;

  /// Liste boşken (son kart da çıkınca) solarak beliren içerik.
  final Widget empty;
  final Widget Function(OfferModel offer) itemBuilder;
  final EdgeInsets padding;

  @override
  State<OfferList> createState() => _OfferListState();
}

class _OfferListState extends State<OfferList> {
  static const _duration = Duration(milliseconds: 380);

  /// Animasyon komutları (removeItem / insertItem) bu anahtarla veriliyor.
  GlobalKey<SliverAnimatedListState> _listKey = GlobalKey();

  /// SliverAnimatedList'in o an bildiği sıra. Animasyon komutları bu
  /// listeye göre verilmek zorunda.
  late List<OfferModel> _items = [...widget.offers];

  @override
  void didUpdateWidget(OfferList old) {
    super.didUpdateWidget(old);
    final next = widget.offers;
    final nextIds = next.map((o) => o.id).toSet();

    // 1) Çıkanlar — sondan başa, indeksler kaymasın.
    for (var i = _items.length - 1; i >= 0; i--) {
      if (nextIds.contains(_items[i].id)) continue;
      final removed = _items.removeAt(i);
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => _transition(removed, animation),
        duration: _duration,
      );
    }

    // 2) Kalanların sırası aynı mı?
    final keptIds = _items.map((o) => o.id).toList();
    final keptInNext = next.map((o) => o.id).where(keptIds.contains).toList();
    if (!listEquals(keptIds, keptInNext)) {
      // Kalan kartların sırası değişmiş (ör. sunucu yeni sırayla döndü):
      // ekle/çıkar ile ifade edilemez, liste animasyonsuz yeniden kuruluyor.
      _items = [...next];
      _listKey = GlobalKey();
      return;
    }

    // 3) Gelenler — yeni listedeki yerlerine.
    for (var i = 0; i < next.length; i++) {
      if (i < _items.length && _items[i].id == next[i].id) continue;
      _items.insert(i, next[i]);
      _listKey.currentState?.insertItem(i, duration: _duration);
    }

    // Ortak kartların GÜNCEL verisi (ör. 60 sn tazelemede geri sayım).
    _items = [...next];
  }

  /// Çıkışta animasyon 1 → 0 gidiyor: önce solup sağa kayıyor, sonra
  /// yüksekliği kapanıyor. Girişte tersi.
  Widget _transition(OfferModel offer, Animation<double> animation) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.4, 1, curve: Curves.easeOut),
    );
    final size = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.6, curve: Curves.easeInOutCubic),
    );
    return SizeTransition(
      sizeFactor: size,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(fade),
          child: widget.itemBuilder(offer),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: widget.padding,
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(child: widget.header),
            SliverAnimatedList(
              key: _listKey,
              initialItemCount: _items.length,
              itemBuilder: (context, i, animation) =>
                  _transition(_items[i], animation),
            ),
            // Son kart da çıkınca boş state solarak beliriyor.
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: _duration,
                child: widget.offers.isEmpty
                    ? widget.empty
                    : const SizedBox(width: double.infinity),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
