import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_style.dart';
import '../icon/app_icon.dart';
import 'app_pressable.dart';

/// specs/00-design-tokens.txt → ORTAK KONTROLLER → Sort chip.
/// "Sırala: [label]" — dokununca ne açılacağını çağıran ekran yönetiyor
/// (bkz. showAppSortSheet). Etiket değişince chip'in genişliği ve yazı
/// yumuşakça geçiyor.
class AppSortChip extends StatelessWidget {
  const AppSortChip({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppPressable(
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
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                'Sırala: $label',
                key: ValueKey(label),
                style: AppTextStyle.label14.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
