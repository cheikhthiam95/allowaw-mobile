import 'user.dart';

class ListingCategoryRef {
  final int id;
  final String name;
  final String slug;
  ListingCategoryRef({required this.id, required this.name, required this.slug});

  factory ListingCategoryRef.fromJson(Map<String, dynamic> json) => ListingCategoryRef(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
      );
}

class ListingPhoto {
  final String url;
  final String blobId;
  ListingPhoto({required this.url, required this.blobId});

  factory ListingPhoto.fromJson(Map<String, dynamic> json) => ListingPhoto(
        url: json['url'] as String,
        blobId: json['blobId'].toString(),
      );
}

class Listing {
  final int id;
  final String title;
  final String slug;
  final int? price;
  final String currency;
  final String? priceType;
  final bool priceNegotiable;
  final String listingType;
  final String status;
  final String? city;
  final String? neighborhood;
  final bool premium;
  final bool urgent;
  final DateTime? publishedAt;
  final ListingCategoryRef category;
  final ListingOwner user;
  final String? thumbnail;

  // Champs présents uniquement sur la version complète (fiche annonce)
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int viewsCount;
  final int favoritesCount;
  final bool verified;
  final int coverPhotoIndex;
  final List<String> photos;
  final List<ListingPhoto> existingPhotos;
  final bool isFavorited;
  final int? favoriteId;

  Listing({
    required this.id,
    required this.title,
    required this.slug,
    this.price,
    this.currency = 'XOF',
    this.priceType,
    this.priceNegotiable = false,
    required this.listingType,
    required this.status,
    this.city,
    this.neighborhood,
    this.premium = false,
    this.urgent = false,
    this.publishedAt,
    required this.category,
    required this.user,
    this.thumbnail,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.viewsCount = 0,
    this.favoritesCount = 0,
    this.verified = false,
    this.coverPhotoIndex = 0,
    this.photos = const [],
    this.existingPhotos = const [],
    this.isFavorited = false,
    this.favoriteId,
  });

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: json['id'] as int,
        title: json['title'] as String,
        slug: json['slug'] as String,
        price: json['price'] as int?,
        currency: json['currency'] as String? ?? 'XOF',
        priceType: json['priceType'] as String?,
        priceNegotiable: json['priceNegotiable'] as bool? ?? false,
        listingType: json['listingType'] as String? ?? 'sale',
        status: json['status'] as String? ?? 'active',
        city: json['city'] as String?,
        neighborhood: json['neighborhood'] as String?,
        premium: json['premium'] as bool? ?? false,
        urgent: json['urgent'] as bool? ?? false,
        publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt'] as String) : null,
        category: ListingCategoryRef.fromJson(json['category'] as Map<String, dynamic>),
        user: ListingOwner.fromJson(json['user'] as Map<String, dynamic>),
        thumbnail: json['thumbnail'] as String?,
        description: json['description'] as String?,
        address: json['address'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        viewsCount: json['viewsCount'] as int? ?? 0,
        favoritesCount: json['favoritesCount'] as int? ?? 0,
        verified: json['verified'] as bool? ?? false,
        coverPhotoIndex: json['coverPhotoIndex'] as int? ?? 0,
        photos: (json['photos'] as List? ?? []).map((e) => e as String).toList(),
        existingPhotos: (json['existingPhotos'] as List? ?? [])
            .map((e) => ListingPhoto.fromJson(e as Map<String, dynamic>))
            .toList(),
        isFavorited: json['isFavorited'] as bool? ?? false,
        favoriteId: json['favoriteId'] as int?,
      );
}

/// Version très allégée d'une annonce, telle que renvoyée par
/// /listings/suggestions (autocomplétion) — pas le même shape qu'une
/// Listing complète, donc un modèle dédié plutôt que de forcer
/// Listing.fromJson sur des champs qui n'existent pas dans cette réponse.
class ListingSuggestion {
  final String slug;
  final String title;
  final int? price;
  final String currency;
  final String? priceType;
  final String categoryName;
  final String? thumbnail;

  ListingSuggestion({
    required this.slug,
    required this.title,
    this.price,
    this.currency = 'XOF',
    this.priceType,
    required this.categoryName,
    this.thumbnail,
  });

  factory ListingSuggestion.fromJson(Map<String, dynamic> json) => ListingSuggestion(
        slug: json['slug'] as String,
        title: json['title'] as String,
        price: json['price'] as int?,
        currency: json['currency'] as String? ?? 'XOF',
        priceType: json['priceType'] as String?,
        categoryName: json['categoryName'] as String? ?? '',
        thumbnail: json['thumbnail'] as String?,
      );
}

class PaginationMeta {
  final int total;
  final int page;
  final int pages;
  PaginationMeta({required this.total, required this.page, required this.pages});

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
        total: json['total'] as int? ?? 0,
        page: json['page'] as int? ?? 1,
        pages: json['pages'] as int? ?? 1,
      );

  bool get hasMore => page < pages;
}
