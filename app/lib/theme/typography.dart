import 'package:flutter/painting.dart';

import 'colors.dart';

/// specs/00-design-tokens.txt → TİPOGRAFİ
/// Spec satır yüksekliğini px verir; Flutter'da `height` = satır / boyut.
/// liga ve calt kapalı.
abstract final class AppText {
  static const _features = [
    FontFeature.disable('liga'),
    FontFeature.disable('calt'),
  ];

  static TextStyle _style(
    double size,
    FontWeight weight, {
    double? lineHeight,
    double tracking = 0,
    Color color = AppColors.strong,
  }) =>
      TextStyle(
        fontFamily: 'Urbanist',
        fontSize: size,
        fontWeight: weight,
        height: lineHeight == null ? null : lineHeight / size,
        letterSpacing: tracking,
        color: color,
        fontFeatures: _features,
      );

  static final statusTime =
      _style(17, FontWeight.w700, lineHeight: 22, tracking: -0.3);
  static final title20 = _style(20, FontWeight.w600,
      lineHeight: 28, color: AppColors.slate700);
  static final title18 = _style(18, FontWeight.w500,
      lineHeight: 24, tracking: -0.27, color: AppColors.slate700);
  static final title16Medium = _style(16, FontWeight.w500,
      lineHeight: 24, tracking: -0.176, color: AppColors.slate700);
  static final title16Semi = _style(16, FontWeight.w600,
      lineHeight: 24, tracking: -0.176, color: AppColors.primary);
  static final caption13 = _style(13, FontWeight.w400,
      lineHeight: 20,
      tracking: -0.078,
      color: AppColors.slate500.withValues(alpha: 0.8));
  static final caption12Medium = _style(12, FontWeight.w500,
      lineHeight: 16, color: AppColors.slate700);
  static final caption12 =
      _style(12, FontWeight.w400, lineHeight: 16, color: AppColors.gray500);
  static final label14 = _style(14, FontWeight.w500,
      lineHeight: 20, tracking: -0.084, color: AppColors.white);
  static final tab13 = _style(13, FontWeight.w500, tracking: -0.084);
}
