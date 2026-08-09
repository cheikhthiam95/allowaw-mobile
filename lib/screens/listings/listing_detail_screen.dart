import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/listing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/conversation_service.dart';
import '../../services/listing_service.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/state_views.dart';

class ListingDetailScreen extends StatefulWidget {
  final String slug;
  const ListingDetailScreen({super.key, required this.slug});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final _service = ListingService();
  Listing? _listing;
  List<Listing> _similar = [];
  bool _loading = true;
  String? _error;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (listing, similar) = await _service.show(widget.slug);
      if (!mounted) return;
      context.read<FavoritesProvider>().hydrateFromListing(listing.id, listing.isFavorited, listing.favoriteId);
      setState(() {
        _listing = listing;
        _similar = similar;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _startConversation() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      context.push('/login?redirect=${Uri.encodeComponent('/listings/${widget.slug}')}');
      return;
    }
    try {
      final convId = await ConversationService().startConversation(listingId: _listing!.id);
      if (mounted) context.push('/messages/$convId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _call() async {
    final phone = _listing?.user.phone;
    if (phone == null) return;
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _whatsapp() async {
    final wa = _listing?.user.whatsapp ?? _listing?.user.phone;
    if (wa == null) return;
    final digits = wa.replaceAll(RegExp(r'[^\d+]'), '');
    await launchUrl(Uri.parse('https://wa.me/${digits.replaceAll('+', '')}'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingView());
    if (_error != null) return Scaffold(appBar: AppBar(), body: ErrorView(message: _error!, onRetry: _load));

    final listing = _listing!;
    final auth = context.watch<AuthProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final isOwner = auth.currentUser?.id == listing.user.id;
    final isFav = favorites.isFavorited(listing.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: AppColors.primary,
            actions: [
              if (isOwner) ...[
                IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/listings/${listing.slug}/edit')),
              ] else if (auth.isAuthenticated)
                IconButton(
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? AppColors.danger : Colors.white),
                  onPressed: () => context.read<FavoritesProvider>().toggle(listing.id),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _PhotoGallery(
                photos: listing.photos,
                index: _photoIndex,
                onChanged: (i) => setState(() => _photoIndex = i),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Badge(text: listingTypeLabels[listing.listingType] ?? listing.listingType, color: AppColors.primary),
                      if (listing.premium) ...[const SizedBox(width: 6), const _Badge(text: '⭐ Premium', color: AppColors.gold)],
                      if (listing.urgent) ...[const SizedBox(width: 6), const _Badge(text: 'Urgent', color: AppColors.danger)],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(listing.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    formatPrice(listing.price, listing.currency, priceType: listing.priceType),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                  if (listing.priceNegotiable)
                    const Padding(padding: EdgeInsets.only(top: 2), child: Text('Négociable', style: TextStyle(color: AppColors.inkMuted, fontSize: 12))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: AppColors.inkMuted),
                      const SizedBox(width: 4),
                      Text([listing.neighborhood, listing.city].where((e) => e != null && e.isNotEmpty).join(', '),
                          style: const TextStyle(color: AppColors.inkMuted)),
                      const SizedBox(width: 12),
                      const Icon(Icons.visibility_outlined, size: 16, color: AppColors.inkMuted),
                      const SizedBox(width: 4),
                      Text('${listing.viewsCount} vues', style: const TextStyle(color: AppColors.inkMuted)),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(listing.description ?? '', style: const TextStyle(color: AppColors.ink, height: 1.5)),
                  const Divider(height: 32),
                  _SellerCard(listing: listing),
                  if (!isOwner) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _startConversation,
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text('Message'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (listing.user.whatsapp != null || listing.user.phone != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _whatsapp,
                              icon: const Icon(Icons.chat, size: 18, color: AppColors.whatsapp),
                              label: const Text('WhatsApp'),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.whatsapp)),
                            ),
                          ),
                        if (listing.user.phone != null) ...[
                          const SizedBox(width: 8),
                          IconButton.filled(onPressed: _call, icon: const Icon(Icons.call)),
                        ],
                      ],
                    ),
                  ],
                  if (_similar.isNotEmpty) ...[
                    const Divider(height: 32),
                    const Text('Annonces similaires', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similar.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => SizedBox(
                          width: 150,
                          child: ListingCardWidget(
                            listing: _similar[i],
                            onTap: () => context.pushReplacement('/listings/${_similar[i].slug}'),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  final List<String> photos;
  final int index;
  final ValueChanged<int> onChanged;
  const _PhotoGallery({required this.photos, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(color: AppColors.primary50, child: const Center(child: Text('📷', style: TextStyle(fontSize: 48))));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          onPageChanged: onChanged,
          itemCount: photos.length,
          itemBuilder: (context, i) => CachedNetworkImage(imageUrl: photos[i], fit: BoxFit.cover),
        ),
        if (photos.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == index ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class _SellerCard extends StatelessWidget {
  final Listing listing;
  const _SellerCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary100,
            backgroundImage: listing.user.avatarUrl != null ? NetworkImage(listing.user.avatarUrl!) : null,
            child: listing.user.avatarUrl == null
                ? Text(listing.user.fullName.isNotEmpty ? listing.user.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.user.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                const Text('Vendeur', style: TextStyle(color: AppColors.inkMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
