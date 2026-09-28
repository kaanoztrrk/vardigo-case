import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// SVGs from assets/icons. Single-color icons are tinted with [color];
/// multi-color ones (online, date, levels, alarm) keep their own colors.
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
