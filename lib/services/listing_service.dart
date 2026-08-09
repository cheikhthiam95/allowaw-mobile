import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/listing.dart';

class ListingResult {
  final List<Listing> listings;
  final PaginationMeta meta;
  ListingResult({required this.listings, required this.meta});
}

class SuggestionsResult {
  final List<ListingSuggestion> listings;
  final List<Map<String, dynamic>> categories;
  SuggestionsResult({required this.listings, required this.categories});
}

class ListingService {
  final _api = ApiClient.instance;

  Future<ListingResult> index({int page = 1, String sort = 'hot', Map<String, dynamic>? filters}) async {
    final res = await _api.get('/listings', query: {'page': page, 'sort': sort, ...?filters});
    return ListingResult(
      listings: (res['listings'] as List).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList(),
      meta: PaginationMeta.fromJson(res['meta'] as Map<String, dynamic>),
    );
  }

  Future<ListingResult> search({int page = 1, String sort = 'hot', required Map<String, dynamic> query}) async {
    final res = await _api.get('/listings/search', query: {'page': page, 'sort': sort, 'q': query});
    return ListingResult(
      listings: (res['listings'] as List).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList(),
      meta: PaginationMeta.fromJson(res['meta'] as Map<String, dynamic>),
    );
  }

  Future<List<Listing>> recommended() async {
    final res = await _api.get('/listings/recommended');
    return (res['listings'] as List).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// L'API renvoie l'annonce ET les annonces similaires en un seul appel —
  /// on garde les deux ensemble plutôt que de refaire une requête séparée.
  Future<(Listing, List<Listing>)> show(String slug) async {
    final res = await _api.get('/listings/$slug');
    final listing = Listing.fromJson(res['listing'] as Map<String, dynamic>);
    final similar = (res['similarListings'] as List? ?? [])
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
    return (listing, similar);
  }

  Future<Map<String, dynamic>> _asFormData(Map<String, dynamic> fields, List<File>? photos) async {
    final map = <String, dynamic>{};
    fields.forEach((k, v) {
      if (v != null) map[k] = v.toString();
    });
    if (photos != null && photos.isNotEmpty) {
      map['photos[]'] = await Future.wait(photos.map((f) => MultipartFile.fromFile(f.path, filename: f.path.split('/').last)));
    }
    return map;
  }

  Future<Listing> create(Map<String, dynamic> fields, {List<File>? photos}) async {
    final data = FormData.fromMap(await _asFormData(fields, photos));
    final res = await _api.dio.post('/listings', data: data);
    return Listing.fromJson((res.data as Map<String, dynamic>)['listing'] as Map<String, dynamic>);
  }

  Future<Listing> update(String slug, Map<String, dynamic> fields,
      {List<File>? photos, List<String>? purgePhotoIds}) async {
    final map = await _asFormData(fields, photos);
    if (purgePhotoIds != null) {
      map['purge_photo_ids[]'] = purgePhotoIds;
    }
    final data = FormData.fromMap(map);
    final res = await _api.dio.patch('/listings/$slug', data: data);
    return Listing.fromJson((res.data as Map<String, dynamic>)['listing'] as Map<String, dynamic>);
  }

  Future<void> destroy(String slug) => _api.delete('/listings/$slug');

  Future<SuggestionsResult> suggestions(String query) async {
    final res = await _api.get('/listings/suggestions', query: {'q': query});
    return SuggestionsResult(
      listings: (res['listings'] as List).map((e) => ListingSuggestion.fromJson(e as Map<String, dynamic>)).toList(),
      categories: (res['categories'] as List).cast<Map<String, dynamic>>(),
    );
  }

  Future<List<Listing>> myListings() async {
    final res = await _api.get('/account/listings');
    return (res['listings'] as List).map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
  }
}
