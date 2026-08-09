import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/formatters.dart';
import '../core/theme.dart';
import '../models/listing.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';

/// Vignette d'annonce — utilisée sur l'accueil, les listes de catégorie,
/// la recherche et les favoris. Reflète app/frontend/components/listings/ListingCard.jsx
class ListingCardWidget extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const ListingCardWidget({super.key, required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final isFav = favorites.isFavorited(listing.id) || (favorites.items.isEmpty && listing.isFavorited);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  listing.thumbnail != null
                      ? CachedNetworkImage(
                          imageUrl: listing.thumbnail!,
                          fit: BoxFit.cover,
                          placeholder: (c, _) => Container(color: AppColors.primary50),
                          errorWidget: (c, _, __) => Container(
                            color: AppColors.primary50,
                            child: const Icon(Icons.image_not_supported_outlined, color: AppColors.inkMuted),
                          ),
                        )
                      : Container(
                          color: AppColors.primary50,
                          child: const Center(child: Text('📷', style: TextStyle(fontSize: 32))),
                        ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _Badge(
                      text: listingTypeLabels[listing.listingType] ?? listing.listingType,
                      color: listing.listingType == 'sale' ? AppColors.success : AppColors.info,
                    ),
                  ),
                  if (auth.isAuthenticated)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _FavoriteButton(listingId: listing.id, isFavorited: isFav),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      height: 1.2,
                      color: AppColors.ink,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _PriceText(listing: listing),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 13, color: AppColors.inkMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          [listing.neighborhood, listing.city].where((e) => e != null && e.isNotEmpty).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.inkMuted, height: 1),
                        ),
                      ),
                      if (listing.publishedAt != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          formatRelativeDate(listing.publishedAt),
                          style: const TextStyle(fontSize: 10.5, color: AppColors.inkMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prix avec chiffres à chasse fixe (alignement propre entre les cartes
/// d'une même grille) et un poids visuel qui domine clairement le reste
/// de la carte.
class _PriceText extends StatelessWidget {
  final Listing listing;
  const _PriceText({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Text(
      formatPrice(listing.price, listing.currency, priceType: listing.priceType),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14.5,
        color: AppColors.primary,
        letterSpacing: -0.2,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final int listingId;
  final bool isFavorited;
  const _FavoriteButton({required this.listingId, required this.isFavorited});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<FavoritesProvider>().toggle(listingId),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(
          isFavorited ? Icons.favorite : Icons.favorite_border,
          size: 16,
          color: isFavorited ? AppColors.danger : AppColors.inkMuted,
        ),
      ),
    );
  }
}
