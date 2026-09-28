import 'package:flutter/widgets.dart';

/// "[prefix][count][suffix]" where only the number animates and the text
/// around it stays put ("1 kişi seçildi" → "2 kişi seçildi"). The new
/// number slides in from below when counting up and from above when down.
class AppAnimatedCount extends StatefulWidget {
  const AppAnimatedCount({
    super.key,
    required this.count,
    required this.style,
    this.prefix = '',
    this.suffix = '',
  });

  final int count;
  final TextStyle style;
  final String prefix;
  final String suffix;

  @override
  State<AppAnimatedCount> createState() => _AppAnimatedCountState();
}

class _AppAnimatedCountState extends State<AppAnimatedCount> {
  late int _previous = widget.count;

  @override
  void didUpdateWidget(AppAnimatedCount old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) _previous = old.count;
  }

  @override
  Widget build(BuildContext context) {
    final up = widget.count >= _previous;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.prefix.isNotEmpty) Text(widget.prefix, style: widget.style),
        ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final incoming = child.key == ValueKey(widget.count);
              final from = Offset(0, (incoming == up) ? 0.6 : -0.6);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: from,
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              '${widget.count}',
              key: ValueKey(widget.count),
              style: widget.style,
            ),
          ),
        ),
        if (widget.suffix.isNotEmpty) Text(widget.suffix, style: widget.style),
      ],
    );
  }
}
