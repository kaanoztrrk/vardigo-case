import 'package:flutter/widgets.dart';

import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/button/app_square_button.dart';

/// Back | "26 personel bulundu / Eşleşen Personeller" | help.
///
/// Back and help don't go anywhere; the case has no previous screen or
/// help page.
class CandidatesHeader extends StatelessWidget {
  const CandidatesHeader({super.key, required this.total});

  /// Label count for the active tab (see CandidatesState.activeTotal).
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const AppSquareButton(icon: 'back'),
      Expanded(
        child: Column(
          children: [
            Text('$total personel bulundu', style: AppTextStyle.caption13),
            Text('Eşleşen Personeller', style: AppTextStyle.title16Medium),
          ],
        ),
      ),
      const AppSquareButton(icon: 'help'),
    ],
  );
}
