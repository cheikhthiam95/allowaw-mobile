import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/category.dart';
import '../../models/listing.dart';
import '../../services/category_service.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/sort_menu.dart';
import '../../widgets/state_views.dart';

/// Équivalent de Categories/Show.jsx — en-tête catégorie, chips de
/// sous-catégories, grille d'annonces paginée.
class CategoryScreen extends StatefulWidget {
  final String slug;
  const CategoryScreen({super.key, required this.slug});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _service = CategoryService();

  Category? _category;
  List<Listing> _listings = [];
  String? _activeSubcategorySlug;
  bool _loading = true;
  String? _error;
  String _sort = 'hot';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? subcategory}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.show(widget.slug, subcategory: subcategory, sort: _sort);
      setState(() {
        _category = res.category;
        _listings = res.listings;
        _activeSubcategorySlug = subcategory;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSortChanged(String sort) {
    setState(() => _sort = sort);
    _load(subcategory: _activeSubcategorySlug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_category?.name ?? 'Catégorie'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: SortMenuButton(value: _sort, onChanged: _onSortChanged)),
          ),
        ],
      ),
      body: _loading
          ? const SkeletonListingGrid()
          : _error != null
              ? ErrorView(message: _error!, onRetry: () => _load())
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _load(subcategory: _activeSubcategorySlug),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _Header(category: _category!)),
                      if (_category!.subcategories.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _SubcategoryChips(
                            subcategories: _category!.subcategories,
                            active: _activeSubcategorySlug,
                            onSelect: (slug) => _load(subcategory: slug),
                          ),
                        ),
                      if (_listings.isEmpty)
                        const SliverFillRemaining(child: EmptyView(message: 'Aucune annonce dans cette catégorie', emoji: '📭'))
                      else
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.68,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => ListingCardWidget(
                                listing: _listings[i],
                                onTap: () => context.push('/listings/${_listings[i].slug}'),
                              ),
                              childCount: _listings.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _Header extends StatelessWidget {
  final Category category;
  const _Header({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppColors.primary,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(category.icon ?? '📦', style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                if (category.nameWolof != null)
                  Text(category.nameWolof!, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 12)),
                Text('${category.listingsCount ?? 0} annonces', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubcategoryChips extends StatelessWidget {
  final List<Subcategory> subcategories;
  final String? active;
  final ValueChanged<String?> onSelect;
  const _SubcategoryChips({required this.subcategories, required this.active, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('Toutes'),
              selected: active == null,
              onSelected: (_) => onSelect(null),
            ),
          ),
          ...subcategories.map((s) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(s.name),
                  selected: active == s.slug,
                  onSelected: (_) => onSelect(s.slug),
                ),
              )),
        ],
      ),
    );
  }
}
