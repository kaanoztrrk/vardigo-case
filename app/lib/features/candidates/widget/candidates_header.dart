import 'package:flutter/widgets.dart';

import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/button/app_square_button.dart';

/// Geri | "26 personel bulundu / Eşleşen Personeller" | yardım.
///
/// Geri ve yardım butonlarının hedefi yok: case'de bu ekranın öncesi ve
/// bir yardım sayfası tanımlı değil.
class CandidatesHeader extends StatelessWidget {
  const CandidatesHeader({super.key, required this.total});

  /// Aktif sekmenin etiket sayısı (bkz. CandidatesState.activeTotal).
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
