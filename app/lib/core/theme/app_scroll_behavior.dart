import 'dart:ui';

import 'package:flutter/material.dart';

/// Makes lists inside the phone frame scroll like on a phone.
///
/// On desktop web, Flutter only scrolls with the wheel or touchpad by
/// default, and dragging with the mouse does nothing. Since this is a
/// phone mockup, people naturally try to drag, so the mouse counts as a
/// drag device here.
///
/// The desktop scrollbar is hidden too, since phones don't have one.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
