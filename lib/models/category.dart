class Subcategory {
  final int id;
  final String name;
  final String slug;

  Subcategory({required this.id, required this.name, required this.slug});

  factory Subcategory.fromJson(Map<String, dynamic> json) => Subcategory(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
      );
}

class Category {
  final int id;
  final String name;
  final String? nameWolof;
  final String slug;
  final String? icon;
  final String? color;
  final int? listingsCount;
  final List<String>? allowedListingTypes;
  final List<Subcategory> subcategories;

  Category({
    required this.id,
    required this.name,
    this.nameWolof,
    required this.slug,
    this.icon,
    this.color,
    this.listingsCount,
    this.allowedListingTypes,
    this.subcategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        nameWolof: json['nameWolof'] as String?,
        slug: json['slug'] as String,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
        listingsCount: json['listingsCount'] as int?,
        allowedListingTypes: (json['allowedListingTypes'] as List?)?.map((e) => e as String).toList(),
        subcategories: (json['subcategories'] as List? ?? [])
            .map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
