import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';
import '../icon/app_icon.dart';

/// specs/00-design-tokens.txt → ORTAK KONTROLLER → Checkbox.
/// Yalnızca görünüm: dokunmayı üstündeki kart yakalıyor (bütün kart
/// tıklanabilir).
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) => Container(
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
    child: checked ? const AppIcon('check', size: 18) : null,
  );
}
