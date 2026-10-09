import 'package:flutter/material.dart';

/// Chunky display text styles. Uses the platform's rounded bold look via
/// heavy weights + tight letter spacing — readable everywhere.
class DashText {
  static TextStyle display(double size, {required Color color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 1.2,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      );

  static TextStyle label(double size, {required Color color}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 2.0,
      );

  static TextStyle body(double size, {required Color color}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.35,
      );
}

/// A chunky pseudo-3D button: bright top face, dark bottom "edge" that
/// compresses when pressed. Physical, toy-like, readable.
class ChunkyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color top;
  final Color edge;
  final double height;
  final double radius;
  final bool small;
  const ChunkyButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.top,
    required this.edge,
    this.height = 58,
    this.radius = 18,
    this.small = false,
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final depth = widget.small ? 4.0 : 6.0;
    final squash = _down ? depth : 0.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: widget.height,
        padding: EdgeInsets.only(bottom: depth - squash),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: widget.onTap == null ? Colors.grey.shade400 : widget.edge,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: Offset(0, _down ? 1 : 3),
              blurRadius: _down ? 2 : 6,
            ),
          ],
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(widget.top, Colors.white, 0.18)!,
                widget.top,
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A wooden panel card with beveled edge and soft inner depth.
class WoodPanel extends StatelessWidget {
  final Widget child;
  final Color panel;
  final Color edge;
  final EdgeInsets padding;
  const WoodPanel({
    super.key,
    required this.child,
    required this.panel,
    required this.edge,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: edge,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(panel, Colors.white, 0.1)!,
              panel,
              Color.lerp(panel, Colors.black, 0.08)!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Toggle row used in settings.
class ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color ink;
  final Color accent;
  const ToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.ink,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DashText.label(15, color: ink)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: DashText.body(12,
                      color: ink.withValues(alpha: 0.75))),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
