import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/button/app_pressable.dart';
import '../../../core/widgets/icon/app_icon.dart';
import '../data/enum/offer_status.dart';
import '../data/models/offer_detail_model.dart';
import '../data/models/offer_model.dart';

/// spec 02 → TALEP KARTI.
///
/// Yanıt butonları ve geri sayım yalnızca BEKLEYEN talepte; cevaplanan ve
/// süresi dolan talepte onların yerine durum satırı var (spec bu iki
/// sekmenin kartını tanımlamıyor).
class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.now,
    required this.expanded,
    required this.detail,
    required this.onAccept,
    required this.onReject,
    required this.onToggleDetail,
  });

  final OfferModel offer;

  /// Geri sayımın rengi için (bkz. OfferModel.isUrgent).
  final DateTime now;
  final bool expanded;

  /// null ve [expanded] ise detay henüz yükleniyor.
  final OfferDetailModel? detail;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onToggleDetail;

  @override
  Widget build(BuildContext context) {
    final pending = offer.status == OfferStatus.pending;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Summary(offer: offer),
          if (pending) ...[
            const SizedBox(height: 12),
            Row(
              spacing: 12,
              children: [
                _ActionButton(
                  icon: 'close',
                  label: 'İlgilenmiyorum',
                  color: AppColors.error,
                  background: AppColors.errorSoft,
                  onTap: onReject,
                ),
                _ActionButton(
                  icon: 'check',
                  label: 'İlgileniyorum',
                  color: AppColors.white,
                  background: AppColors.green,
                  onTap: onAccept,
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _DetailButton(expanded: expanded, onTap: onToggleDetail),
          // Detay yumuşakça açılıp kapanıyor; yüklenirken → içerik geçişi
          // de solarak.
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? _Detail(offer: offer, detail: detail)
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 10),
          pending
              ? _Countdown(offer: offer, urgent: offer.isUrgent(now))
              : _StatusLine(status: offer.status),
        ],
      ),
    );
  }
}

/// Logo | ünvan + ücret / işletme / konum · saat
class _Summary extends StatelessWidget {
  const _Summary({required this.offer});

  final OfferModel offer;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 12,
    children: [
      ClipOval(
        child: SvgPicture.network(
          offer.logoUrl,
          width: 56,
          height: 56,
          placeholderBuilder: (_) => const SizedBox.square(
            dimension: 56,
            child: ColoredBox(color: AppColors.slate200),
          ),
          // Logo gelmezse (sunucu kapalı, 404) kart bozulmasın: aynı gri
          // daire. Yoksa hata yakalanmadan fırlıyor.
          errorBuilder: (_, _, _) => const SizedBox.square(
            dimension: 56,
            child: ColoredBox(color: AppColors.slate200),
          ),
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    offer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.title18,
                  ),
                ),
                const AppIcon('money', size: 24, color: AppColors.green),
                const SizedBox(width: 4),
                Text(
                  '₺${offer.pay}',
                  style: AppTextStyle.title18.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            Text(offer.place, style: AppTextStyle.caption12),
            const SizedBox(height: 8),
            Row(
              children: [
                _meta(const AppIcon('pin', size: 14), offer.district),
                Container(
                  width: 1,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppColors.slate200,
                ),
                // date çok renkli (mavi daire + beyaz akrep), boyanmıyor.
                Flexible(
                  child: _meta(const AppIcon('date', size: 16), offer.when),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _meta(Widget icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [
      icon,
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.caption12Medium,
        ),
      ),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: AppPressable(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            AppIcon(icon, size: 16, color: color),
            Text(label, style: AppTextStyle.label14.copyWith(color: color)),
          ],
        ),
      ),
    ),
  );
}

class _DetailButton extends StatelessWidget {
  const _DetailButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppPressable(
    onTap: onTap,
    child: Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          const AppIcon('eye', size: 20, color: AppColors.sub),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              expanded ? 'Detayları Gizle' : 'Detayları Gör',
              key: ValueKey(expanded),
              style: AppTextStyle.label14.copyWith(color: AppColors.sub),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Spec 02: "kartın altına 2 satırlık düz metin yeter: konum + ücret +
/// saat tekrarı" (karar B11 — ayrı sayfa yok).
class _Detail extends StatelessWidget {
  const _Detail({required this.offer, required this.detail});

  final OfferModel offer;
  final OfferDetailModel? detail;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyle.caption12.copyWith(color: AppColors.sub);
    final d = detail;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topLeft,
          children: [...previous, ?current],
        ),
        child: d == null
            ? Text('Yükleniyor…', key: const ValueKey('loading'), style: style)
            : Column(
                key: const ValueKey('detail'),
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    '${d.city}, ${offer.district} · ${d.note}',
                    style: style,
                  ),
                  Text('₺${offer.pay} / ay · ${offer.when}', style: style),
                ],
              ),
      ),
    );
  }
}

/// "Teklifin sonlanmasına **21 saat 32 dakika** kaldı." — 6 saatten az
/// kaldıysa ikon ve kalın kısım kırmızı (karar D6).
class _Countdown extends StatelessWidget {
  const _Countdown({required this.offer, required this.urgent});

  final OfferModel offer;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyle.caption12.copyWith(color: AppColors.strong);
    return Row(
      spacing: 4,
      children: [
        // alarm.svg kendi rengiyle turuncu; acilse kırmızıya boyanıyor.
        AppIcon('alarm', size: 16, color: urgent ? AppColors.error : null),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: style,
              children: [
                const TextSpan(text: 'Teklifin sonlanmasına '),
                TextSpan(
                  text: offer.remain ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: urgent ? AppColors.error : AppColors.strong,
                  ),
                ),
                const TextSpan(text: ' kaldı.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Cevaplanan / süresi dolan talepte butonların ve geri sayımın yerine.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status});

  final OfferStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = switch (status) {
      OfferStatus.accepted => (
        'check',
        'İlgileniyorum dedin.',
        AppColors.green,
      ),
      OfferStatus.rejected => (
        'close',
        'İlgilenmiyorum dedin.',
        AppColors.error,
      ),
      _ => ('alarm', 'Teklifin süresi doldu.', AppColors.sub),
    };
    return Row(
      spacing: 4,
      children: [
        AppIcon(icon, size: 16, color: color),
        Text(
          text,
          style: AppTextStyle.caption12.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
