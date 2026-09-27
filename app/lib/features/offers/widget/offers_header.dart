import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/button/app_square_button.dart';

/// Geri | "Görüşme Talepleri / 12 talep yanıt bekliyor".
///
/// Spec başlığı ortalayıp sağa 44'lük boşluk koyuyor; referansta başlık
/// geri butonunun yanında, sola yaslı (karar D3 — PNG önce gelir).
/// Geri butonunun hedefi yok (Ekran 1'deki aynı gerekçe).
class OffersHeader extends StatelessWidget {
  const OffersHeader({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 16,
    children: [
      const AppSquareButton(icon: 'back'),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Görüşme Talepleri', style: AppTextStyle.title20),
            Text(
              subtitle,
              style: AppTextStyle.caption12.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
