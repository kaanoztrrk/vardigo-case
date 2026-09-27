import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';
import '../icon/app_icon.dart';

/// specs/00-design-tokens.txt → ORTAK KONTROLLER → Checkbox.
/// Yalnızca görünüm: dokunmayı üstündeki kart yakalıyor (bütün kart
/// tıklanabilir). Dolma/boşalma animasyonlu: renk geçiyor, tik büyüyerek
/// beliriyor.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.checked});

  final bool checked;

  static const _duration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: _duration,
    curve: Curves.easeOut,
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      color: checked ? AppColors.primary : AppColors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: checked ? AppColors.primary : AppColors.slate300,
      ),
    ),
    // Spec "tik çizilmese de olur" diyor; referansta tik var.
    child: AnimatedScale(
      scale: checked ? 1 : 0.4,
      duration: _duration,
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: checked ? 1 : 0,
        duration: _duration,
        child: const AppIcon('check', size: 18),
      ),
    ),
  );
}
