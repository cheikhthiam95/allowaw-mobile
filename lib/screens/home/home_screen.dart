import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/category.dart';
import '../../models/listing.dart';
import '../../providers/categories_provider.dart';
import '../../services/listing_service.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_views.dart';

/// Équivalent mobile de app/frontend/pages/Home.jsx — hero + recherche +
/// catégories + annonces récentes + artisans.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _listingService = ListingService();
  List<Listing> _recent = [];
  List<Listing> _artisans = [];
  List<Listing> _recommended = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Après le 1er frame : appeler notifyListeners() pendant initState (donc
    // pendant le build initial) est interdit par Flutter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoriesProvider>().load();
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recent = await _listingService.index(page: 1);
      final artisans = await _listingService.search(query: {'listing_type_eq': 'service'});
      setState(() {
        _recent = recent.listings.take(8).toList();
        _artisans = artisans.listings.take(6).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
    // Séparé du chargement principal : une erreur ici (ex. utilisateur non
    // connecté, aucun favori) ne doit pas casser le reste de la page — la
    // section est simplement masquée si la liste reste vide.
    try {
      final recommended = await _listingService.recommended();
      if (mounted) setState(() => _recommended = recommended);
    } catch (_) {
      // silencieux — section optionnelle
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesProvider>();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([_load(), context.read<CategoriesProvider>().load(force: true)]);
      },
      child: CustomScrollView(
        slivers: [
          // Un simple sliver (pas de SliverAppBar/FlexibleSpaceBar) : la
          // hauteur du hero est fixe, il défile normalement avec le reste
          // de la page — comme sur le web. Un FlexibleSpaceBar aurait dû
          // interpoler cette hauteur en continu jusqu'à l'état "réduit" de
          // l'appbar, où le contenu ne tient plus (débordement RenderFlex).
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('allôwaw', style: TextStyle(color: AppColors.goldLight, fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      const Text('Le marché en ligne du Sénégal', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 14),
                      _SearchBarStub(onTap: () => context.push('/search')),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Les catégories ont leur propre skeleton et leur propre état de
          // chargement (CategoriesProvider), indépendant de celui des
          // annonces — sinon la ligne de catégories reste vide (ni contenu
          // ni skeleton) tant que les annonces n'ont pas fini de charger.
          SliverToBoxAdapter(child: _CategoriesSection(categories: categories.categories, loading: categories.loading)),
          if (_recommended.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: '✨ Recommandé pour vous',
                subtitle: "D'après vos favoris",
                onSeeAll: null,
              ),
            ),
            _ListingsGridSliver(listings: _recommended),
          ],
          if (_loading)
            const SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(child: SkeletonListingGrid(count: 4, padding: EdgeInsets.zero)),
            )
          else if (_error != null)
            SliverFillRemaining(child: ErrorView(message: _error!, onRetry: _load))
          else ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Annonces à la une',
                subtitle: 'Les plus pertinentes en ce moment',
                onSeeAll: () => context.push('/listings'),
              ),
            ),
            _ListingsGridSliver(listings: _recent),
            if (_artisans.isNotEmpty) ...[
              SliverToBoxAdapter(child: _SectionHeader(title: 'Artisans & Services', onSeeAll: () => context.push('/listings'))),
              _ListingsGridSliver(listings: _artisans),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ],
      ),
    );
  }
}

class _SearchBarStub extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBarStub({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.inkMuted, size: 20),
            SizedBox(width: 10),
            Text('Rechercher : moto, terrain, électricien...', style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final List<Category> categories;
  final bool loading;
  const _CategoriesSection({required this.categories, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && !loading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
        children: loading
            ? List.generate(8, (i) => const _CategoryTileSkeleton())
            : categories.map((c) => _CategoryTile(category: c)).toList(),
      ),
    );
  }
}

class _CategoryTileSkeleton extends StatelessWidget {
  const _CategoryTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(26))),
        SizedBox(height: 8),
        SkeletonBox(width: 40, height: 9),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/categories/${category.slug}'),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
            child: Center(child: Text(category.icon ?? '📦', style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.subtitle, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  ),
              ],
            ),
          ),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('Voir tout')),
        ],
      ),
    );
  }
}

class _ListingsGridSliver extends StatelessWidget {
  final List<Listing> listings;
  const _ListingsGridSliver({required this.listings});

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const SliverToBoxAdapter(child: EmptyView(message: 'Aucune annonce pour le moment', emoji: '📭'));
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => ListingCardWidget(
            listing: listings[i],
            onTap: () => context.push('/listings/${listings[i].slug}'),
          ),
          childCount: listings.length,
        ),
      ),
    );
  }
}
