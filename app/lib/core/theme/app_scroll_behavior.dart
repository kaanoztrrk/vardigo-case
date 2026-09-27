import 'dart:ui';

import 'package:flutter/material.dart';

/// Telefon çerçevesinin içindeki listeler telefondaki gibi kaysın.
///
/// Flutter web masaüstünde varsayılan olarak yalnızca tekerlek / touchpad
/// ile kaydırıyor; fareyle tutup çekmek hiçbir şey yapmıyor. Ekran bir
/// telefon taklidi olduğu için kullanıcı listeyi doğal olarak fareyle
/// yukarı çekiyor — o yüzden fare de sürükleme cihazı sayılıyor.
///
/// Masaüstüne özgü kaydırma çubuğu da çizilmiyor: telefonda yok.
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
