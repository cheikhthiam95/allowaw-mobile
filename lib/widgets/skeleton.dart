import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Effet de pulsation partagé par tous les skeletons — un seul
/// AnimationController réutilisé (via [SkeletonBox]) pour éviter de faire
/// tourner une animation par élément dans une longue liste.
class _Pulse extends StatefulWidget {
  final Widget Function(BuildContext, double) builder;
  const _Pulse({required this.builder});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(context, 0.4 + _controller.value * 0.35),
    );
  }
}

/// Bloc de base d'un skeleton — un rectangle gris qui pulse doucement.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({super.key, this.width, this.height = 14, this.borderRadius = const BorderRadius.all(Radius.circular(6))});

  @override
  Widget build(BuildContext context) {
    return _Pulse(
      builder: (context, opacity) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.line.withValues(alpha: opacity),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Skeleton d'une ListingCardWidget — mêmes proportions (photo 4:3 + 3
/// lignes de texte) pour que l'apparition du vrai contenu ne "saute" pas.
class SkeletonListingCard extends StatelessWidget {
  const SkeletonListingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 4 / 3, child: SkeletonBox(borderRadius: BorderRadius.zero, height: double.infinity)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 13, width: double.infinity),
                const SizedBox(height: 8),
                SkeletonBox(height: 15, width: MediaQuery.of(context).size.width * 0.24),
                const SizedBox(height: 8),
                const SkeletonBox(height: 11, width: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grille de skeletons — même gridDelegate que les grilles réelles
/// d'annonces (2 colonnes, ratio 0.68).
class SkeletonListingGrid extends StatelessWidget {
  final int count;
  final EdgeInsets padding;
  const SkeletonListingGrid({super.key, this.count = 6, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: count,
      itemBuilder: (context, i) => const SkeletonListingCard(),
    );
  }
}

/// Ligne de liste générique (conversations, mes annonces...) — avatar/vignette
/// carrée + 2 lignes de texte.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(12))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14, width: MediaQuery.of(context).size.width * 0.5),
                const SizedBox(height: 8),
                SkeletonBox(height: 12, width: MediaQuery.of(context).size.width * 0.3),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonListTiles extends StatelessWidget {
  final int count;
  const SkeletonListTiles({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, i) => const SkeletonListTile(),
    );
  }
}

/// Skeleton de la fiche annonce complète (galerie + titre + prix + description).
class SkeletonListingDetail extends StatelessWidget {
  const SkeletonListingDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 300, borderRadius: BorderRadius.zero),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 22, width: 220),
                const SizedBox(height: 12),
                const SkeletonBox(height: 26, width: 140),
                const SizedBox(height: 20),
                const SkeletonBox(height: 14, width: double.infinity),
                const SizedBox(height: 8),
                const SkeletonBox(height: 14, width: double.infinity),
                const SizedBox(height: 8),
                SkeletonBox(height: 14, width: MediaQuery.of(context).size.width * 0.6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
