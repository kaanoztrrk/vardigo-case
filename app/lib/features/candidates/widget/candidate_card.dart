import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/checkbox/app_checkbox.dart';
import '../../../core/widgets/icon/app_icon.dart';
import '../data/models/candidate_model.dart';

/// spec 01 → ADAY KARTI. Kartın tamamı seçimi değiştirir.
///
/// Seçili halin "inset 4 0 0 #335CFF" gölgesi Flutter'da yok; yerine
/// kartın içine kırpılmış 4 px'lik bir şerit çiziliyor — köşelerde kartın
/// radius'unu izliyor.
class CandidateCard extends StatelessWidget {
  const CandidateCard({
    super.key,
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final CandidateModel candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLighter : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        // Seçiliyken de 1 px'lik (şeffaf) border duruyor: seçim değişince
        // içerik 1 px kaymasın.
        border: Border.all(
          color: selected ? const Color(0x00000000) : AppColors.slate200,
        ),
        boxShadow: selected ? AppShadows.cardSelected : AppShadows.card,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _Avatar(url: candidate.photoUrl, online: candidate.online),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(candidate.name, style: AppTextStyle.title18),
                          _MetaRow(candidate: candidate),
                        ],
                      ),
                    ),
                    AppCheckbox(checked: selected),
                  ],
                ),
                const SizedBox(height: 12),
                _PayRow(
                  match: candidate.payMatch,
                  amount: candidate.expectedPay,
                ),
              ],
            ),
          ),
          if (selected)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: ColoredBox(color: AppColors.primary),
            ),
        ],
      ),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.online});

  final String url;
  final bool online;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 56,
    height: 56,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: Image.network(
            url,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            // Foto gelmezse kart bozulmasın: boş gri daire.
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: AppColors.slate200),
          ),
        ),
        // Rozet referansta avatarın sağ-altında, çemberin üstüne taşıyor.
        // online.svg 28 × 28.75 ve gölge payı içeriyor; 24'e ölçekleniyor
        // (spec: 56 × 0.42).
        if (online)
          const Positioned(
            left: 37,
            top: 31,
            child: AppIcon('online', size: 24),
          ),
      ],
    ),
  );
}

/// ★ 4.9 | 🛡 %100 katılım | 📍 4.9 km
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.candidate});

  final CandidateModel candidate;

  // Çerçevenin iç ekranı 368 px (referansınki 390): "%100 katılım" +
  // "4.9 km" ile satır sığan alanın sınırında. Daha uzun bir değer
  // gelirse taşmak yerine hafifçe küçülsün.
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      children: [
        _item(
          const AppIcon('star', size: 16, color: AppColors.warning),
          candidate.rating,
        ),
        const _Divider(),
        // shield ve pin kendi renkleriyle (yeşil / mor) çiziliyor.
        _item(const AppIcon('shield', size: 16), candidate.attend),
        const _Divider(),
        _item(const AppIcon('pin', size: 14), candidate.km),
      ],
    ),
  );

  Widget _item(Widget icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [
      icon,
      Text(text, style: AppTextStyle.caption12Medium),
    ],
  );
}

/// Referanstaki 1 px dikey ayırıcı (karar D7). Yan boşluk referansta ~8;
/// dar ekrana oranlanıp 6.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 16,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: AppColors.slate200,
  );
}

/// "Ücret beklentisi uyuşuyor / uyuşmuyor ... ₺25.000 / ay" (karar D1:
/// spec'te yok, referansta var).
class _PayRow extends StatelessWidget {
  const _PayRow({required this.match, required this.amount});

  final bool match;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final color = match ? AppColors.green : AppColors.warning;
    final style = AppTextStyle.caption13.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        spacing: 4,
        children: [
          AppIcon('money', size: 16, color: color),
          Expanded(
            child: Text(
              match
                  ? 'Ücret beklentisi uyuşuyor'
                  : 'Ücret beklentisi uyuşmuyor',
              style: style,
            ),
          ),
          Text(
            '₺$amount / ay',
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
