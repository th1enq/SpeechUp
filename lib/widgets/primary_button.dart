import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Production button with explicit pressed, loading, and disabled states.
class AppPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isFullWidth;
  final bool isLoading;
  final bool isSecondary;

  const AppPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = widget.onPressed != null && !widget.isLoading;
    final bg = widget.isSecondary ? c.surfaceBg : c.accentBlue;
    final disabledBg = c.borderColor.withValues(alpha: 0.55);
    final foregroundColor = widget.isSecondary ? c.accentBlue : c.textOnAccent;
    final disabledFg = c.textMuted;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isPressed ? 1.5 : 0, 0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? bg : disabledBg,
            borderRadius: BorderRadius.circular(16),
            border: widget.isSecondary
                ? Border.all(
                    color: enabled
                        ? c.accentBlue.withValues(alpha: 0.45)
                        : c.borderColor,
                  )
                : null,
            boxShadow: [
              if (enabled && !widget.isSecondary)
                BoxShadow(
                  color: c.accentBlue.withValues(
                    alpha: _isPressed ? 0.14 : 0.26,
                  ),
                  offset: Offset(0, _isPressed ? 4 : 8),
                  blurRadius: _isPressed ? 10 : 18,
                ),
            ],
          ),
          child: Container(
            width: widget.isFullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            constraints: const BoxConstraints(minHeight: 52, minWidth: 52),
            child: Row(
              mainAxisSize: widget.isFullWidth
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation(
                        enabled ? foregroundColor : disabledFg,
                      ),
                    ),
                  )
                else ...[
                  Text(
                    widget.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: enabled ? foregroundColor : disabledFg,
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
      ),
    );
  }
}

/// Backward-compat typedef so all existing `PrimaryButton(...)` calls still work.
typedef PrimaryButton = AppPrimaryButton;
typedef SketchButton = AppPrimaryButton;
