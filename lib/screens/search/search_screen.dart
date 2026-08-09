import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/listing.dart';
import '../../services/listing_service.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/sort_menu.dart';
import '../../widgets/state_views.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _service = ListingService();
  final _controller = TextEditingController();
  Timer? _debounce;

  List<ListingSuggestion> _suggestions = [];
  List<Map<String, dynamic>> _suggestedCategories = [];
  bool _suggesting = false;

  List<Listing> _results = [];
  PaginationMeta? _meta;
  bool _searched = false;
  bool _loading = false;
  String? _error;
  String _query = '';
  String _sort = 'hot';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      _runSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _suggestedCategories = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _suggesting = true);
      try {
        final res = await _service.suggestions(value.trim());
        if (!mounted) return;
        setState(() {
          _suggestions = res.listings;
          _suggestedCategories = res.categories;
        });
      } catch (_) {
        // silencieux — l'autocomplete n'est pas critique
      } finally {
        if (mounted) setState(() => _suggesting = false);
      }
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _loading = true;
      _searched = true;
      _query = query;
      _suggestions = [];
      _suggestedCategories = [];
      _error = null;
    });
    try {
      final res = await _service.search(query: {'title_cont': query}, sort: _sort);
      setState(() {
        _results = res.listings;
        _meta = res.meta;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSortChanged(String sort) {
    setState(() => _sort = sort);
    if (_searched) _runSearch(_query);
  }

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _suggestions.isNotEmpty || _suggestedCategories.isNotEmpty || _suggesting;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery == null,
          onChanged: _onChanged,
          onSubmitted: _runSearch,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Que cherchez-vous ?',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
            // Le thème global remplit les champs en blanc (filled: true) —
            // sans ce override, le texte blanc devient invisible sur fond
            // blanc dans cette barre de recherche sur AppBar sombre.
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _runSearch(_controller.text.trim())),
        ],
      ),
      body: Stack(
        children: [
          if (_loading)
            const SkeletonListingGrid()
          else if (_error != null)
            ErrorView(message: _error!, onRetry: () => _runSearch(_query))
          else if (_searched)
            _ResultsList(
              results: _results,
              meta: _meta,
              query: _query,
              sort: _sort,
              onSortChanged: _onSortChanged,
            )
          else
            const EmptyView(message: 'Recherchez une annonce par mot-clé', emoji: '🔎'),

          if (showSuggestions)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4,
                child: _SuggestionsPanel(
                  suggesting: _suggesting,
                  listings: _suggestions,
                  categories: _suggestedCategories,
                  query: _controller.text,
                  onSelectListing: (slug) => context.push('/listings/$slug'),
                  onSelectCategory: (slug) => context.push('/categories/$slug'),
                  onSeeAll: () => _runSearch(_controller.text.trim()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionsPanel extends StatelessWidget {
  final bool suggesting;
  final List<ListingSuggestion> listings;
  final List<Map<String, dynamic>> categories;
  final String query;
  final ValueChanged<String> onSelectListing;
  final ValueChanged<String> onSelectCategory;
  final VoidCallback onSeeAll;

  const _SuggestionsPanel({
    required this.suggesting,
    required this.listings,
    required this.categories,
    required this.query,
    required this.onSelectListing,
    required this.onSelectCategory,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          if (suggesting) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
          if (listings.isNotEmpty) ...[
            const _SuggestionSectionLabel('ANNONCES'),
            ...listings.map((l) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      height: 44,
                      color: AppColors.primary50,
                      child: l.thumbnail != null
                          ? Image.network(l.thumbnail!, fit: BoxFit.cover)
                          : const Icon(Icons.image_outlined, color: AppColors.inkMuted, size: 18),
                    ),
                  ),
                  title: Text(
                    l.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink),
                  ),
                  subtitle: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatPrice(l.price, l.currency, priceType: l.priceType),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 12.5),
                        ),
                        TextSpan(text: '  ·  ${l.categoryName}', style: const TextStyle(color: AppColors.inkMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  onTap: () => onSelectListing(l.slug),
                )),
          ],
          if (categories.isNotEmpty) ...[
            const _SuggestionSectionLabel('CATÉGORIES'),
            ...categories.map((c) => ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(c['icon'] as String? ?? '📦', style: const TextStyle(fontSize: 19))),
                  ),
                  title: Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  onTap: () => onSelectCategory(c['slug'] as String),
                )),
          ],
          if (query.trim().length >= 2)
            ListTile(
              leading: const Icon(Icons.search, color: AppColors.primary, size: 18),
              title: Text('Voir tous les résultats pour « $query »',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              tileColor: AppColors.canvas,
              onTap: onSeeAll,
            ),
        ],
      ),
    );
  }
}

class _SuggestionSectionLabel extends StatelessWidget {
  final String label;
  const _SuggestionSectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.inkMuted)),
      );
}

class _ResultsList extends StatelessWidget {
  final List<Listing> results;
  final PaginationMeta? meta;
  final String query;
  final String sort;
  final ValueChanged<String> onSortChanged;
  const _ResultsList({
    required this.results,
    required this.meta,
    required this.query,
    required this.sort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return EmptyView(message: 'Aucun résultat pour « $query »', emoji: '📭');
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
                    children: [
                      TextSpan(
                        text: '${meta?.total ?? results.length}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 14),
                      ),
                      const TextSpan(text: ' résultat(s)'),
                    ],
                  ),
                ),
              ),
              SortMenuButton(value: sort, onChanged: onSortChanged),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemCount: results.length,
            itemBuilder: (context, i) => ListingCardWidget(
              listing: results[i],
              onTap: () => context.push('/listings/${results[i].slug}'),
            ),
          ),
        ),
      ],
    );
  }
}
