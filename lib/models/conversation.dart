class ConversationOtherUser {
  final int id;
  final String fullName;
  final String? phone;
  ConversationOtherUser({required this.id, required this.fullName, this.phone});

  factory ConversationOtherUser.fromJson(Map<String, dynamic> json) => ConversationOtherUser(
        id: json['id'] as int,
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String?,
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

  Conversation({
    required this.id,
    required this.listingTitle,
    required this.listingSlug,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
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
