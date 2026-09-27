import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/icon/app_icon.dart';

/// Sabit alt bar: "Görüşme Talebi Gönder (N)" (spec 01 → footer).
class SendOfferFooter extends StatelessWidget {
  const SendOfferFooter({super.key, required this.count, this.onSend});

  final int count;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    // 0 seçiliyken pasif: backend'e boş dizi gitmesin (spec 01).
    final enabled = count > 0;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.weak,
        border: Border(top: BorderSide(color: AppColors.stroke)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          // Home indicator alanı + referanstaki boşluk.
          MediaQuery.paddingOf(context).bottom + 16,
        ),
        child: GestureDetector(
          onTap: enabled ? onSend : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  const AppIcon('send', size: 20, color: AppColors.white),
                  Text(
                    'Görüşme Talebi Gönder ($count)',
                    style: AppTextStyle.label14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
