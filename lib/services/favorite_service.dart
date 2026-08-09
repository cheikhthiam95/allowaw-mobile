import '../core/api_client.dart';
import '../models/listing.dart';

class FavoriteItem {
  final int id;
  final Listing listing;
  FavoriteItem({required this.id, required this.listing});

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
        id: json['id'] as int,
        listing: Listing.fromJson(json['listing'] as Map<String, dynamic>),
      );
}

class FavoriteService {
  final _api = ApiClient.instance;

  Future<List<FavoriteItem>> index() async {
    final res = await _api.get('/favorites');
    return (res['favorites'] as List).map((e) => FavoriteItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> add(int listingId) async {
    final res = await _api.post('/favorites', data: {'listing_id': listingId});
    return res['id'] as int;
  }

  Future<void> remove(int favoriteId) => _api.delete('/favorites/$favoriteId');
}
