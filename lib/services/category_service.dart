import '../core/api_client.dart';
import '../models/category.dart';
import '../models/listing.dart';

class CategoryShowResult {
  final Category category;
  final List<Listing> listings;
  final PaginationMeta meta;
  final Subcategory? activeSubcategory;
  CategoryShowResult({required this.category, required this.listings, required this.meta, this.activeSubcategory});
}

class CategoryService {
  final _api = ApiClient.instance;

  Future<List<Category>> index() async {
    final res = await _api.get('/categories');
    return (res['categories'] as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CategoryShowResult> show(String slug, {String? subcategory, int page = 1, String sort = 'hot'}) async {
    final res = await _api.get('/categories/$slug', query: {
      if (subcategory != null) 'subcategory': subcategory,
      'page': page,
      'sort': sort,
    });
    return CategoryShowResult(
      category: Category.fromJson(res['category'] as Map<String, dynamic>),
      listings: (res['listings'] as List).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList(),
      meta: PaginationMeta.fromJson(res['meta'] as Map<String, dynamic>),
      activeSubcategory: res['activeSubcategory'] != null
          ? Subcategory.fromJson(res['activeSubcategory'] as Map<String, dynamic>)
          : null,
    );
  }
}
