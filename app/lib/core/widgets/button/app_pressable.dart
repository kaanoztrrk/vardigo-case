import 'package:flutter/widgets.dart';

/// Basılınca hafifçe küçülüp bırakınca geri gelen dokunma alanı — tüm
/// buton, chip ve kartların ortak basma geri bildirimi.
///
/// [onTap] null ise pasif: ne küçülür ne dokunmayı yakalar.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Büyük yüzeylerde (kart) daha az küçülmesi için ayarlanabilir; küçük
  /// oranda bile geniş bir kart göze fazla oynak geliyor.
  final double pressedScale;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
