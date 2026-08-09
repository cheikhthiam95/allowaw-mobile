import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Équivalent About.jsx.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('allôwaw', style: TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Le marché en ligne du Sénégal', style: TextStyle(color: AppColors.inkMuted)),
          const SizedBox(height: 24),
          const _Paragraph(
            "Allôwaw est la plateforme d'annonces gratuites qui connecte acheteurs, vendeurs, "
            "propriétaires et artisans partout au Sénégal. Immobilier, véhicules, électronique, "
            "services... publiez et trouvez ce que vous cherchez en toute simplicité.",
          ),
          const SizedBox(height: 20),
          const _Feature(icon: Icons.verified_outlined, title: '100% gratuit', text: 'Déposez vos annonces sans frais.'),
          const _Feature(icon: Icons.location_on_outlined, title: 'National', text: 'Louga et tout le Sénégal.'),
          const _Feature(icon: Icons.chat_bubble_outline, title: 'Messagerie intégrée', text: 'Échangez directement avec acheteurs et vendeurs.'),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(height: 1.6, color: AppColors.ink));
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Feature({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(text, style: const TextStyle(color: AppColors.inkMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
