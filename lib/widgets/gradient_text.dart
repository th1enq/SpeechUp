import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Renders text in Kalam (boldened marker font) with correction-red color.
/// Drop-in replacement for the old GradientText — API unchanged.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = GoogleFonts.kalam(
      fontSize: style?.fontSize ?? 20,
      fontWeight: FontWeight.w700,
      color: AppColors.foreground,
    ).merge(style?.copyWith(
      foreground: null,
      color: AppColors.foreground,
    ));

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
    );
  }
}
