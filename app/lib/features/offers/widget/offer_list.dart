import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../data/models/offer_model.dart';

/// Offer list that animates cards leaving and coming back.
///
/// The bloc swaps the whole list at once (a card drops out on an
/// optimistic answer and comes back if the request fails). This widget
/// diffs old and new lists by id and replays the difference on a
/// [SliverAnimatedList]: a removed card fades, slides right and
/// collapses while the ones below move up; an inserted card does the
/// reverse.
///
/// On tab or sort changes the parent rebuilds this with a new key, so only
/// adds and removes within the same tab are animated here.
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

  /// Scrolling row above the list (the sort chip).
  final Widget header;

  /// Fades in when the list is empty, including after the last card leaves.
  final Widget empty;
  final Widget Function(OfferModel offer) itemBuilder;
  final EdgeInsets padding;

  @override
  State<OfferList> createState() => _OfferListState();
}

class _OfferListState extends State<OfferList> {
  static const _duration = Duration(milliseconds: 380);

  /// Used to call removeItem / insertItem.
  GlobalKey<SliverAnimatedListState> _listKey = GlobalKey();

  /// What SliverAnimatedList currently thinks the items are. Indexes for
  /// removeItem / insertItem have to match this.
  late List<OfferModel> _items = [...widget.offers];

  @override
  void didUpdateWidget(OfferList old) {
    super.didUpdateWidget(old);
    final next = widget.offers;
    final nextIds = next.map((o) => o.id).toSet();

    // 1) Removals, back to front so indexes don't shift.
    for (var i = _items.length - 1; i >= 0; i--) {
      if (nextIds.contains(_items[i].id)) continue;
      final removed = _items.removeAt(i);
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => _transition(removed, animation),
        duration: _duration,
      );
    }

    // 2) Are the remaining items still in the same order?
    final keptIds = _items.map((o) => o.id).toList();
    final keptInNext = next.map((o) => o.id).where(keptIds.contains).toList();
    if (!listEquals(keptIds, keptInNext)) {
      // Order changed (e.g. the server returned a new order). That can't
      // be expressed as inserts/removes, so rebuild without animation.
      _items = [...next];
      _listKey = GlobalKey();
      return;
    }

    // 3) Inserts, at their position in the new list.
    for (var i = 0; i < next.length; i++) {
      if (i < _items.length && _items[i].id == next[i].id) continue;
      _items.insert(i, next[i]);
      _listKey.currentState?.insertItem(i, duration: _duration);
    }

    // Pick up fresh data for cards that stayed (e.g. the countdown after
    // the 60s refresh).
    _items = [...next];
  }

  /// On removal the animation runs 1 → 0: fade and slide right first, then
  /// collapse the height. Insertion is the reverse.
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
            // Empty state fades in once the last card is gone.
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
