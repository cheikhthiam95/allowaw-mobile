import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';

/// Équivalent de Listings/Index.jsx — toutes les annonces, paginées.
class ListingsIndexScreen extends StatefulWidget {
  const ListingsIndexScreen({super.key});

  @override
  State<ListingsIndexScreen> createState() => _ListingsIndexScreenState();
}

class _ListingsIndexScreenState extends State<ListingsIndexScreen> {
  final _service = ListingService();
  final _scrollController = ScrollController();

  final List<Listing> _listings = [];
  int _page = 1;
  PaginationMeta? _meta;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
    });
    try {
      final res = await _service.index(page: 1);
      setState(() {
        _listings
          ..clear()
          ..addAll(res.listings);
        _meta = res.meta;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _meta == null || !_meta!.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final res = await _service.index(page: _page + 1);
      setState(() {
        _page += 1;
        _listings.addAll(res.listings);
        _meta = res.meta;
      });
    } catch (_) {
      // silencieux, l'utilisateur peut réessayer en re-scrollant
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toutes les annonces')),
      body: _loading
          ? const SkeletonListingGrid()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _listings.isEmpty
                  ? const EmptyView(message: 'Aucune annonce disponible', emoji: '📭')
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: _listings.length + (_meta?.hasMore == true ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= _listings.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.primary)));
                          }
                          return ListingCardWidget(
                            listing: _listings[i],
                            onTap: () => context.push('/listings/${_listings[i].slug}'),
                          );
                        },
                      ),
                    ),
    );
  }
}
