class ConversationOtherUser {
  final int id;
  final String fullName;
  final String? phone;
  final int ratingsCount;
  final int? completionRate;
  final double? avgRating;
  ConversationOtherUser({
    required this.id,
    required this.fullName,
    this.phone,
    this.ratingsCount = 0,
    this.completionRate,
    this.avgRating,
  });

  factory ConversationOtherUser.fromJson(Map<String, dynamic> json) => ConversationOtherUser(
        id: json['id'] as int,
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String?,
        ratingsCount: json['ratingsCount'] as int? ?? 0,
        completionRate: json['completionRate'] as int?,
        avgRating: (json['avgRating'] as num?)?.toDouble(),
      );
}

/// Notation post-contact déjà soumise pour cette conversation (voir
/// ContactRating côté Rails) — null tant que l'acheteur n'a pas encore
/// répondu à "avez-vous conclu ?".
class ContactRatingInfo {
  final bool concluded;
  final int? stars;
  ContactRatingInfo({required this.concluded, this.stars});

  factory ContactRatingInfo.fromJson(Map<String, dynamic> json) => ContactRatingInfo(
        concluded: json['concluded'] as bool,
        stars: json['stars'] as int?,
      );
}

class LastMessagePreview {
  final String body;
  final DateTime createdAt;
  LastMessagePreview({required this.body, required this.createdAt});

  factory LastMessagePreview.fromJson(Map<String, dynamic> json) => LastMessagePreview(
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class Conversation {
  final int id;
  final String listingTitle;
  final String listingSlug;
  final ConversationOtherUser otherUser;
  final LastMessagePreview? lastMessage;
  final int unreadCount;
  final DateTime? createdAt;
  final bool isRater;
  final ContactRatingInfo? rating;

  Conversation({
    required this.id,
    required this.listingTitle,
    required this.listingSlug,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    this.createdAt,
    this.isRater = false,
    this.rating,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as int,
        listingTitle: json['listingTitle'] as String? ?? '',
        listingSlug: json['listingSlug'] as String? ?? '',
        otherUser: ConversationOtherUser.fromJson(json['otherUser'] as Map<String, dynamic>),
        lastMessage: json['lastMessage'] != null
            ? LastMessagePreview.fromJson(json['lastMessage'] as Map<String, dynamic>)
            : null,
        unreadCount: json['unreadCount'] as int? ?? 0,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
        isRater: json['isRater'] as bool? ?? false,
        rating: json['rating'] != null ? ContactRatingInfo.fromJson(json['rating'] as Map<String, dynamic>) : null,
      );
}

class ChatMessage {
  final int id;
  final String body;
  final bool read;
  final DateTime createdAt;
  final int userId;
  final String userFullName;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.body,
    required this.read,
    required this.createdAt,
    required this.userId,
    required this.userFullName,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as int,
        body: json['body'] as String,
        read: json['read'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        userId: json['userId'] as int,
        userFullName: json['userFullName'] as String? ?? '',
        isMine: json['isMine'] as bool? ?? false,
      );
}
