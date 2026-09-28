import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_style.dart';
import '../../../core/widgets/button/app_pressable.dart';
import '../../../core/widgets/checkbox/app_checkbox.dart';
import '../../../core/widgets/icon/app_icon.dart';
import '../data/models/candidate_model.dart';

/// Candidate card. Tapping anywhere on it toggles selection.
///
/// Flutter can't do the selected state's "inset 4 0 0 #335CFF" shadow, so
/// a 4 px stripe is drawn instead, clipped to the card so it follows the
/// rounded corners.
///
/// Selection is animated: background, border and shadow through
/// [AnimatedContainer], and the stripe grows from 0 to 4.
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

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) => AppPressable(
    onTap: onTap,
    // Wide surface, so a small scale is enough.
    pressedScale: 0.985,
    child: AnimatedContainer(
      duration: _duration,
      curve: Curves.easeOut,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLighter : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        // Keep a 1 px (transparent) border when selected too, so content
        // doesn't shift by 1 px on toggle.
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
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: _duration,
              curve: Curves.easeOut,
              width: selected ? 4 : 0,
              color: AppColors.primary,
            ),
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
            // Gray circle if the photo fails to load.
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: AppColors.slate200),
          ),
        ),
        // Badge overlaps the bottom-right of the avatar like in the
        // reference. online.svg is 28 × 28.75 including its shadow, scaled
        // to 24 (spec: 56 × 0.42).
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

  // The frame's screen is 368 px wide (390 in the reference), and
  // "%100 katılım" + "4.9 km" just barely fit. Longer values scale down
  // a bit instead of overflowing.
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
        // shield and pin keep their own colors (green / purple).
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

/// 1 px vertical divider from the reference. Side spacing is ~8 there,
/// scaled down to 6 for the narrower screen.
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

/// "Ücret beklentisi uyuşuyor / uyuşmuyor ... ₺25.000 / ay". Not in the
/// spec, but it's in the reference.
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
