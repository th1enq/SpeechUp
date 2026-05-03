import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SketchCardDecoration { none, tape, tack }

/// A hand-drawn style card with wobbly borders, hard offset shadows,
/// and optional tape/tack decoration.
class SketchCard extends StatefulWidget {
  final Widget child;
  final bool isFeatured;        // post-it yellow background
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final SketchCardDecoration decoration;
  final double rotation;        // radians; default tiny wobble

  const SketchCard({
    super.key,
    required this.child,
    this.isFeatured = false,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.decoration = SketchCardDecoration.none,
    this.rotation = 0.0,
  });

  @override
  State<SketchCard> createState() => _SketchCardState();
}

class _SketchCardState extends State<SketchCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.isFeatured ? AppColors.postItYellow : c.cardBg;
    final borderColor = isDark ? c.borderColor : AppColors.border;
    final shadowColor = isDark ? c.shadowColor : AppColors.shadowHard;

    final double shadowDx = _isPressed ? 1 : 4;
    final double shadowDy = _isPressed ? 1 : 4;
    final double translateX = _isPressed ? 3 : 0;
    final double translateY = _isPressed ? 3 : 0;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translateByDouble(translateX, translateY, 0.0, 1.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: Offset(shadowDx, shadowDy),
            blurRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );

    // Tape decoration: translucent strip at the top
    if (widget.decoration == SketchCardDecoration.tape) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: -0.05,
                child: Container(
                  width: 60,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.30),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Tack decoration: red thumbtack at the top center
    if (widget.decoration == SketchCardDecoration.tack) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Apply rotation
    if (widget.rotation != 0.0) {
      content = Transform.rotate(angle: widget.rotation, child: content);
    }

    if (widget.onTap != null) {
      content = GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap!();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: content,
      );
    }

    return content;
  }
}

/// Backward-compat typedef so all existing `ElevatedCard(...)` calls still work.
typedef ElevatedCard = SketchCard;
