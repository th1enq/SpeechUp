import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProfileAvatarButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  const ProfileAvatarButton({super.key, this.onTap, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final user = FirebaseAuth.instance.currentUser;
    final photo = user?.photoURL;

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.cardBg,
        border: Border.all(color: c.borderColor.withValues(alpha: 0.7)),
      ),
      child: ClipOval(
        child: photo == null
            ? Icon(Icons.person_rounded, color: c.textMuted, size: size * 0.52)
            : Image.network(
                photo,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person_rounded,
                  color: c.textMuted,
                  size: size * 0.52,
                ),
              ),
      ),
    );

    if (onTap == null) return avatar;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: avatar,
      ),
    );
  }
}
