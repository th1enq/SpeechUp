import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'notifications_bell_button.dart';
import 'profile_avatar_button.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onAvatarTap;
  final EdgeInsetsGeometry? margin;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onAvatarTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = GoogleFonts.plusJakartaSans();
    final compact = MediaQuery.sizeOf(context).width < 370;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 46,
            child: Row(
              children: [
                ProfileAvatarButton(onTap: onAvatarTap),
                const SizedBox(width: 12),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: base.copyWith(
                        fontSize: compact ? 20 : 21,
                        fontWeight: FontWeight.w900,
                        color: c.textHeading,
                        height: 1.0,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                NotificationsBellButton(
                  iconColor: c.textHeading,
                  iconSize: 26,
                ),
              ],
            ),
          ),
          if (hasSubtitle) ...[
            SizedBox(height: compact ? 12 : 14),
            Text(
              subtitle!,
              style: base.copyWith(
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w500,
                color: c.textMuted,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
