import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_style.dart';
import '../icon/app_icon.dart';

/// specs/00-design-tokens.txt → ORTAK KONTROLLER → Sort chip.
/// "Sırala: [label]" — döngüyü çağıran ekran yönetiyor.
class AppSortChip extends StatelessWidget {
  const AppSortChip({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
        boxShadow: AppShadows.sortChip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          const AppIcon('sort', size: 20, color: AppColors.primary),
          Text(
            'Sırala: $label',
            style: AppTextStyle.label14.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    ),
  );
}
