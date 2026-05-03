import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// A hand-drawn style button — wobbly oval, hard offset shadow, presses flat.
class SketchButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Widget? icon;
  final bool isFullWidth;
  final bool isLoading;
  final bool isSecondary; // muted bg, blue hover

  const SketchButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  State<SketchButton> createState() => _SketchButtonState();
}

class _SketchButtonState extends State<SketchButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Normal: 4px offset shadow; pressed: shadow gone, translate (4,4)
    final double shadowDx = _isPressed ? 0 : 4;
    final double shadowDy = _isPressed ? 0 : 4;
    final double tx = _isPressed ? 4 : 2;
    final double ty = _isPressed ? 4 : 2;

    final Color bg = widget.isSecondary ? c.surfaceBg : c.cardBg;
    final Color borderColor = widget.isSecondary ? c.accentBlue : c.textHeading;
    final Color foregroundColor = widget.isSecondary ? c.accentBlue : c.textHeading;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(tx, ty, 0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: c.shadowColor,
              offset: Offset(shadowDx, shadowDy),
              blurRadius: 0,
            ),
          ],
        ),
        child: Container(
          width: widget.isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          constraints: const BoxConstraints(minHeight: 50),
          child: Row(
            mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(foregroundColor),
                  ),
                )
              else ...[
                Text(
                  widget.text,
                  style: GoogleFonts.patrickHand(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
                  ),
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: 8),
                  widget.icon!,
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward-compat typedef so all existing `PrimaryButton(...)` calls still work.
typedef PrimaryButton = SketchButton;
