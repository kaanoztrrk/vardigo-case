import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_style.dart';
import '../data/enum/offer_tab.dart';

/// Bekleyen | Cevaplanan | Süresi Dolan (spec 02 → header → 3'lü tab).
/// Ekran 1'in sekmelerinden farklı bir bileşen: renkler, radius ve aktif
/// hal (beyaz pill) başka.
class OfferTabBar extends StatelessWidget {
  const OfferTabBar({super.key, required this.active, required this.onChanged});

  final OfferTab active;
  final ValueChanged<OfferTab> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.weak50,
      borderRadius: BorderRadius.circular(54),
    ),
    child: Row(
      spacing: 4,
      children: [for (final tab in OfferTab.values) _pill(tab)],
    ),
  );

  Widget _pill(OfferTab tab) {
    final isActive = tab == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.white : null,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isActive ? AppShadows.tabActiveRequests : null,
          ),
          child: Text(
            tab.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.tab13.copyWith(
              color: isActive ? AppColors.strong : AppColors.soft,
            ),
          ),
        ),
      ),
    );
  }
}
