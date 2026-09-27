import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../icon/app_icon.dart';
import 'app_pressable.dart';

/// specs/00-design-tokens.txt → ORTAK KONTROLLER → Kare buton
/// (geri / yardım).
class AppSquareButton extends StatelessWidget {
  const AppSquareButton({super.key, required this.icon, this.onTap});

  final String icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppPressable(
    onTap: onTap,
    child: Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
        boxShadow: AppShadows.squareButton,
      ),
      child: AppIcon(icon, size: 20, color: AppColors.slate600),
    ),
  );
}
