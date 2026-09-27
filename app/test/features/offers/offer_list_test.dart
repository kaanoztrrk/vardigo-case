import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vardigo_app/features/offers/data/enum/offer_status.dart';
import 'package:vardigo_app/features/offers/data/models/offer_model.dart';
import 'package:vardigo_app/features/offers/widget/offer_list.dart';

OfferModel _offer(String id) => OfferModel(
  id: id,
  title: id,
  place: '',
  pay: '',
  payValue: 0,
  logoUrl: '',
  district: '',
  when: '',
  status: OfferStatus.pending,
  remain: null,
  expiresAt: DateTime.utc(2026),
);

Widget _list(List<String> ids) => MaterialApp(
  home: Scaffold(
    body: OfferList(
      offers: ids.map(_offer).toList(),
      padding: EdgeInsets.zero,
      header: const SizedBox.shrink(),
      empty: const Text('boş'),
      itemBuilder: (o) => SizedBox(height: 50, child: Text(o.id)),
    ),
  ),
);

List<String> _visible(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data!)
    .where((d) => d.startsWith('o_'))
    .toList();

void main() {
  testWidgets('çıkan kart animasyon boyunca kalır, sonra gider', (
    tester,
  ) async {
    await tester.pumpWidget(_list(['o_a', 'o_b', 'o_c']));

    await tester.pumpWidget(_list(['o_a', 'o_c']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('o_b'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('o_b'), findsNothing);
    expect(_visible(tester), ['o_a', 'o_c']);
  });

  testWidgets('geri konan kart eski yerine animasyonla döner', (tester) async {
    await tester.pumpWidget(_list(['o_a', 'o_b', 'o_c']));
    await tester.pumpWidget(_list(['o_a', 'o_c']));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_list(['o_a', 'o_b', 'o_c']));
    await tester.pumpAndSettle();

    expect(_visible(tester), ['o_a', 'o_b', 'o_c']);
  });

  testWidgets('son kart da çıkınca boş state belirir', (tester) async {
    await tester.pumpWidget(_list(['o_a']));

    await tester.pumpWidget(_list([]));
    await tester.pumpAndSettle();

    expect(_visible(tester), isEmpty);
    expect(find.text('boş'), findsOneWidget);
  });

  testWidgets('kalanların sırası değişirse liste yeniden kurulur', (
    tester,
  ) async {
    await tester.pumpWidget(_list(['o_a', 'o_b', 'o_c']));

    await tester.pumpWidget(_list(['o_c', 'o_a', 'o_b']));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(_visible(tester), ['o_c', 'o_a', 'o_b']);
  });
}
