import 'package:flutter/painting.dart';

/// specs/00-design-tokens.txt → GÖLGELER ve ORTAK KONTROLLER.
/// "kart seçili" için inset gölge Flutter'da yok; sol şerit kart
/// widget'ında ayrıca çizilecek, burada yalnızca dış gölge var.
abstract final class AppShadows {
  static const card = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x0A243D82)),
  ];
  static const cardSelected = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x0A243D82)),
  ];

  static const tabActiveMatches = [
    BoxShadow(offset: Offset(0, 6), blurRadius: 5, color: Color(0x0F0E121B)),
    BoxShadow(offset: Offset(0, 2), blurRadius: 2, color: Color(0x080E121B)),
  ];
  static const tabActiveRequests = [
    BoxShadow(offset: Offset(0, 6), blurRadius: 10, color: Color(0x0F0E121B)),
    BoxShadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x080E121B)),
  ];

  static const squareButton = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x140A0D14)),
  ];
  static const sortChip = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 4, color: Color(0x0A000000)),
  ];

  static const bezel = [
    BoxShadow(offset: Offset(0, 28), blurRadius: 48, color: Color(0x380F121B)),
  ];
}
