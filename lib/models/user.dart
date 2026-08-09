class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String? accountType;
  final String? businessName;
  final String? phone;
  final String? whatsapp;
  final String? city;
  final String? neighborhood;
  final bool verified;
  final bool isAdmin;
  final bool isSuperAdmin;
  final String? avatarUrl;
  final bool needsProfileCompletion;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.accountType,
    this.businessName,
    this.phone,
    this.whatsapp,
    this.city,
    this.neighborhood,
    this.verified = false,
    this.isAdmin = false,
    this.isSuperAdmin = false,
    this.avatarUrl,
    this.needsProfileCompletion = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        accountType: json['accountType'] as String?,
        businessName: json['businessName'] as String?,
        phone: json['phone'] as String?,
        whatsapp: json['whatsapp'] as String?,
        city: json['city'] as String?,
        neighborhood: json['neighborhood'] as String?,
        verified: json['verified'] as bool? ?? false,
        isAdmin: json['isAdmin'] as bool? ?? false,
        isSuperAdmin: json['isSuperAdmin'] as bool? ?? false,
        avatarUrl: json['avatarUrl'] as String?,
        needsProfileCompletion: json['needsProfileCompletion'] as bool? ?? false,
      );
}

/// Version allégée d'un utilisateur telle qu'imbriquée dans une annonce
/// (`listing.user`) — pas les mêmes champs que le profil complet.
class ListingOwner {
  final int id;
  final String fullName;
  final String? phone;
  final String? whatsapp;
  final String? avatarUrl;
  final bool verified;
  final int ratingsCount;
  final int? completionRate;
  final double? avgRating;

  ListingOwner({
    required this.id,
    required this.fullName,
    this.phone,
    this.whatsapp,
    this.avatarUrl,
    this.verified = false,
    this.ratingsCount = 0,
    this.completionRate,
    this.avgRating,
  });

  factory ListingOwner.fromJson(Map<String, dynamic> json) => ListingOwner(
        id: json['id'] as int,
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String?,
        whatsapp: json['whatsapp'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        verified: json['verified'] as bool? ?? false,
        ratingsCount: json['ratingsCount'] as int? ?? 0,
        completionRate: json['completionRate'] as int?,
        avgRating: (json['avgRating'] as num?)?.toDouble(),
      );
}
