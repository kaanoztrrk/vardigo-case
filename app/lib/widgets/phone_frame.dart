import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/typography.dart';

/// specs/00-design-tokens.txt → TELEFON ÇERÇEVESİ.
/// 390×844 dış kutu, 11 px bezel → 368×822 iç ekran.
/// Status bar (54) ve home indicator (30) içeriğin üstüne çizilir;
/// ekranlar bu alanları MediaQuery padding'inden okur.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({
    super.key,
    required this.child,
    this.showHomeIndicator = true,
  });

  final Widget child;
  final bool showHomeIndicator;

  static const size = Size(390, 844);
  static const _bezel = 11.0;
  static const _statusBarHeight = 54.0;
  static const _homeIndicatorHeight = 30.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(_bezel),
      decoration: BoxDecoration(
        color: AppColors.bezel,
        borderRadius: BorderRadius.circular(54),
        boxShadow: AppShadows.bezel,
      ),
      // Bezel iç çizgi: inset 0 0 0 1 rgba(255,255,255,0.12)
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(54),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: ColoredBox(
          color: AppColors.white,
          child: Stack(
            children: [
              Positioned.fill(
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(
                      size.width - _bezel * 2,
                      size.height - _bezel * 2,
                    ),
                    padding: EdgeInsets.only(
                      top: _statusBarHeight,
                      bottom: showHomeIndicator ? _homeIndicatorHeight : 0,
                    ),
                  ),
                  child: child,
                ),
              ),
              const _StatusBar(),
              if (showHomeIndicator) const _HomeIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PhoneFrame._statusBarHeight,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 16,
            width: 100,
            child: Text(
              '9:41',
              textAlign: TextAlign.center,
              style: AppText.statusTime,
            ),
          ),
          const Positioned(
            top: 11,
            left: 0,
            right: 0,
            child: Center(child: _DynamicIsland()),
          ),
          Positioned(
            right: 24,
            top: 16,
            child: SvgPicture.asset(
              'assets/icons/levels.svg',
              width: 100,
              height: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicIsland extends StatelessWidget {
  const _DynamicIsland();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 37,
      padding: const EdgeInsets.only(right: 14),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: AppColors.island,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.islandLens,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.islandRing),
        ),
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 8,
      child: Center(
        child: Container(
          width: 135,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.homePill,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
