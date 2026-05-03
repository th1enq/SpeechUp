import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Sticky-note label with Kalam font, post-it yellow background,
/// pencil-black border, and a slight tilt.
class SectionBadge extends StatelessWidget {
  final String label;

  const SectionBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.onboardingBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.borderColor, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowHard,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.kalam(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
