import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vardigo_app/core/theme/app_scroll_behavior.dart';

/// On desktop browsers, dragging the list with the mouse should scroll it
/// (Flutter doesn't by default).
void main() {
  Future<double> dragWith(WidgetTester tester, PointerDeviceKind kind) async {
    final controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const AppScrollBehavior(),
        home: ListView(
          controller: controller,
          children: [
            for (var i = 0; i < 30; i++)
              SizedBox(height: 100, child: Text('$i')),
          ],
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300), kind: kind);
    await tester.pumpAndSettle();
    return controller.offset;
  }

  testWidgets('fareyle sürükleyince liste kayar', (tester) async {
    expect(await dragWith(tester, PointerDeviceKind.mouse), greaterThan(0));
  });

  testWidgets('dokunarak sürükleme de çalışmaya devam eder', (tester) async {
    expect(await dragWith(tester, PointerDeviceKind.touch), greaterThan(0));
  });
}
