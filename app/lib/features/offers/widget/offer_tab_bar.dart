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

  static const _duration = Duration(milliseconds: 260);
  static const _gap = 4.0;

  // Beyaz pill tek bir parça ve sekmeler arasında KAYIYOR (Ekran 1'deki
  // gibi); yazılar üstünde, renkleri geçişli değişiyor.
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.weak50,
      borderRadius: BorderRadius.circular(54),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        const count = 3;
        final pillWidth = (constraints.maxWidth - _gap * (count - 1)) / count;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: _duration,
              curve: Curves.easeOutCubic,
              left: active.index * (pillWidth + _gap),
              top: 0,
              bottom: 0,
              width: pillWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: AppShadows.tabActiveRequests,
                ),
              ),
            ),
            Row(
              spacing: _gap,
              children: [for (final tab in OfferTab.values) _label(tab)],
            ),
          ],
        );
      },
    ),
  );

  Widget _label(OfferTab tab) => Expanded(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(tab),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: AnimatedDefaultTextStyle(
          duration: _duration,
          style: AppTextStyle.tab13.copyWith(
            color: tab == active ? AppColors.strong : AppColors.soft,
          ),
          child: Text(
            tab.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ),
  );
}
