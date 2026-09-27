import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/button/app_pressable.dart';
import '../../../core/widgets/icon/app_icon.dart';
import '../../../core/widgets/text/app_animated_count.dart';

/// Sabit alt bar: "Görüşme Talebi Gönder (N)" (spec 01 → footer).
class SendOfferFooter extends StatelessWidget {
  const SendOfferFooter({
    super.key,
    required this.count,
    required this.sending,
    required this.onSend,
  });

  final int count;

  /// İstek sürerken buton pasif: çift dokunuş iki istek atmasın.
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    // 0 seçiliyken pasif: backend'e boş dizi gitmesin (spec 01).
    final enabled = count > 0 && !sending;
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
        child: AppPressable(
          onTap: enabled ? onSend : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
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
                  AppAnimatedCount(
                    count: count,
                    prefix: 'Görüşme Talebi Gönder (',
                    suffix: ')',
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
