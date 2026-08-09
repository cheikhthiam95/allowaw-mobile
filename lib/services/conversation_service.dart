import '../core/api_client.dart';
import '../models/conversation.dart';

class ConversationDetail {
  final Conversation conversation;
  final List<ChatMessage> messages;
  ConversationDetail({required this.conversation, required this.messages});
}

class ConversationService {
  final _api = ApiClient.instance;

  Future<List<Conversation>> index() async {
    final res = await _api.get('/conversations');
    return (res['conversations'] as List).map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ConversationDetail> show(int id) async {
    final res = await _api.get('/conversations/$id');
    return ConversationDetail(
      conversation: Conversation.fromJson(res['conversation'] as Map<String, dynamic>),
      messages: (res['messages'] as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Démarre une conversation à propos d'une annonce (ou renvoie celle
  /// existante). Renvoie l'id de conversation pour naviguer directement
  /// vers l'écran de discussion.
  Future<int> startConversation({required int listingId, String? body}) async {
    final res = await _api.post('/conversations', data: {
      'listing_id': listingId,
      if (body != null) 'body': body,
    });
    return (res['conversation'] as Map<String, dynamic>)['id'] as int;
  }

  Future<ChatMessage> sendMessage({required int conversationId, required String body}) async {
    final res = await _api.post('/conversations/$conversationId/messages', data: {'body': body});
    return ChatMessage.fromJson(res['message'] as Map<String, dynamic>);
  }

  /// Notation post-contact — seul l'acheteur (auteur du premier message)
  /// peut noter, voir ContactRating côté Rails.
  Future<void> rateContact({required int conversationId, required bool concluded, int? stars}) async {
    await _api.post('/conversations/$conversationId/rating', data: {
      'concluded': concluded,
      if (stars != null) 'stars': stars,
    });
  }
}
