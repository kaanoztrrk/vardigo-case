import 'dart:ui';

/// specs/00-design-tokens.txt → RENK
abstract final class AppColors {
  static const primary = Color(0xFF335CFF);
  static const primarySoft = Color(0xFF3485FF);
  static const primaryLight = Color(0xFFD5E2FF);
  static const primaryLighter = Color(0xFFEBF1FF);
  static const primaryDarkest = Color(0xFF1F3BAD);

  static const strong = Color(0xFF171717);
  static const slate700 = Color(0xFF2B303B);
  static const slate600 = Color(0xFF525866);
  static const slate500 = Color(0xFF717784);
  static const gray500 = Color(0xFF7B7B7B);
  static const sub = Color(0xFF5C5C5C);
  static const soft = Color(0xFFA3A3A3);

  static const white = Color(0xFFFFFFFF);
  static const weak = Color(0xFFFBFBFB);
  static const weak50 = Color(0xFFF7F7F7);
  static const slate50 = Color(0xFFF5F7FA);
  static const slate100 = Color(0xFFF2F5F8);
  static const slate200 = Color(0xFFEAECF0);
  static const stroke = Color(0xFFEBEBEB);
  static const slate300 = Color(0xFFCACFD8);

  static const green = Color(0xFF1DAF61);
  static const greenDark = Color(0xFF178C4E);
  static const greenLighter = Color(0xFFE3F7EC);
  static const error = Color(0xFFFB3748);
  static const errorSoft = Color(0x1AFB3748);
  static const warning = Color(0xFFFA7319);

  // Telefon çerçevesi
  static const bezel = Color(0xFF0B0B0D);
  static const island = Color(0xFF000000);
  static const islandLens = Color(0xFF1C1C1E);
  static const islandRing = Color(0xFF2A2A2C);
  static const homePill = Color(0xFFB9C0C9);
}
