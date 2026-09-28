import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/button/app_square_button.dart';

/// Back | "Görüşme Talepleri / 12 talep yanıt bekliyor".
///
/// The spec centers the title with a 44 px spacer on the right, but the
/// reference has it left-aligned next to the back button, so I went with
/// the PNG. Back doesn't go anywhere, same as on screen 1.
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
