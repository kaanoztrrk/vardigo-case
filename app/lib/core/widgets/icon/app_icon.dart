import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// assets/icons altındaki SVG'ler. Tek renkli ikonlar [color] ile boyanır
/// (ASSETS.txt: "tek renk maske"); çok renkli olanlar (online, date, levels,
/// alarm) renksiz, kendi renkleriyle çizilir.
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, required this.size, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        'assets/icons/$name.svg',
        width: size,
        height: size,
        colorFilter:
            color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      );
}
