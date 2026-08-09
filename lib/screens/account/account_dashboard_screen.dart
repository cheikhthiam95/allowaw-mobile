import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/verification_badge.dart';

/// Équivalent de Account/Dashboard.jsx — raccourcis vers les sous-sections
/// du compte. Affiche un écran de connexion si non-authentifié (le web
/// redirige côté serveur ; ici la redirection GoRouter s'en charge déjà,
/// cet écran ne sert qu'aux utilisateurs connectés).
class AccountDashboardScreen extends StatelessWidget {
  const AccountDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Mon compte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                AvatarWithVerificationBadge(
                  verified: user.verified,
                  avatar: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary100,
                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null
                        ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 20, color: AppColors.primary, fontWeight: FontWeight.w700))
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(user.email, style: const TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!user.verified) ...[
            const SizedBox(height: 12),
            _UnverifiedBanner(onTap: () => context.push('/account/profile')),
          ],
          const SizedBox(height: 20),
          _MenuTile(icon: Icons.list_alt, label: 'Mes annonces', onTap: () => context.push('/account/listings')),
          _MenuTile(icon: Icons.favorite_border, label: 'Mes favoris', onTap: () => context.push('/account/favorites')),
          _MenuTile(icon: Icons.chat_bubble_outline, label: 'Messages', onTap: () => context.push('/messages')),
          _MenuTile(icon: Icons.person_outline, label: 'Mon profil', onTap: () => context.push('/account/profile')),
          _MenuTile(icon: Icons.add_circle_outline, label: 'Déposer une annonce', onTap: () => context.push('/listings/new')),
          _MenuTile(icon: Icons.info_outline, label: 'À propos', onTap: () => context.push('/a-propos')),
          _MenuTile(icon: Icons.mail_outline, label: 'Nous contacter', onTap: () => context.push('/contact')),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Déconnexion', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

/// Signal discret mais visible que le compte n'est pas encore vérifié —
/// ton informatif (pas une erreur), amène vers la carte de vérification
/// complète sur l'écran Profil.
class _UnverifiedBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _UnverifiedBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.gold50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
              child: const Icon(Icons.priority_high, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Compte non vérifié', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink)),
                  SizedBox(height: 1),
                  Text('Vérifiez votre numéro pour inspirer confiance', style: TextStyle(fontSize: 11.5, color: AppColors.inkMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.goldDark, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.inkMuted),
        onTap: onTap,
      ),
    );
  }
}
