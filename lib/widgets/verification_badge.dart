import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Petit badge superposé sur un avatar — pastille orange avec une horloge
/// si le compte n'est pas encore vérifié, coche verte s'il l'est. Motif
/// standard (Instagram, WhatsApp Business...) : le badge se voit partout
/// où l'avatar apparaît, pas seulement sur l'écran Profil.
class VerificationBadge extends StatelessWidget {
  final bool verified;
  final double size;
  const VerificationBadge({super.key, required this.verified, this.size = 20});

  @override
  Widget build(BuildContext context) {
    if (verified) return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(Icons.access_time_filled_rounded, color: Colors.white, size: size * 0.6),
    );
  }
}

/// Avatar + badge de vérification en coin bas-droit — enveloppe le
/// CircleAvatar habituel plutôt que de dupliquer le Stack partout.
class AvatarWithVerificationBadge extends StatelessWidget {
  final Widget avatar;
  final bool verified;
  final double badgeSize;
  const AvatarWithVerificationBadge({super.key, required this.avatar, required this.verified, this.badgeSize = 20});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (!verified)
          Positioned(
            bottom: -2,
            right: -2,
            child: VerificationBadge(verified: verified, size: badgeSize),
          ),
      ],
    );
  }
}
