import 'package:flutter_test/flutter_test.dart';

import 'package:vardigo_app/app/app.dart';
import 'package:vardigo_app/app/di/injection.dart';

void main() {
  testWidgets('uygulama açılıyor', (tester) async {
    setupDependencies();
    await tester.pumpWidget(const VardigoApp());
    expect(tester.takeException(), isNull);
  });
}
