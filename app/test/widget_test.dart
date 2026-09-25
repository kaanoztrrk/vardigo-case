import 'package:flutter_test/flutter_test.dart';

import 'package:vardigo_app/main.dart';

void main() {
  testWidgets('uygulama açılıyor', (tester) async {
    await tester.pumpWidget(const VardigoApp());
    expect(tester.takeException(), isNull);
  });
}
