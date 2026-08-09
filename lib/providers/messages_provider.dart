import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/local_notifications.dart';
import '../models/conversation.dart';
import '../services/conversation_service.dart';

/// Poll léger des conversations pour maintenir le badge "messages non lus"
/// à jour et déclencher une notification locale quand un nouveau message
/// arrive pendant que l'app est ouverte. Pas de websocket ici — un poll
/// toutes les 25s est largement suffisant pour une messagerie de petites
/// annonces (pas un chat temps réel critique) et évite la complexité d'un
/// client ActionCable dédié côté mobile.
class MessagesProvider extends ChangeNotifier {
  final _service = ConversationService();
  Timer? _timer;
  int? _currentConversationId; // en cours de consultation : pas de notif pour celle-ci

  int unreadCount = 0;
  List<Conversation> conversations = [];

  void setActiveConversation(int? id) {
    _currentConversationId = id;
  }

  void startPolling() {
    _poll();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => _poll());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    unreadCount = 0;
    conversations = [];
  }

  Future<void> _poll() async {
    try {
      final previous = {for (final c in conversations) c.id: c.unreadCount};
      final fresh = await _service.index();

      for (final c in fresh) {
        final before = previous[c.id] ?? 0;
        if (c.unreadCount > before && c.id != _currentConversationId) {
          await LocalNotifications.showMessageNotification(
            conversationId: c.id,
            title: c.otherUser.fullName,
            body: c.lastMessage?.body ?? 'Nouveau message',
          );
        }
      }

      conversations = fresh;
      unreadCount = fresh.fold(0, (sum, c) => sum + c.unreadCount);
      notifyListeners();
    } catch (_) {
      // Silencieux — un poll raté n'a pas besoin d'interrompre l'usage de
      // l'app, le suivant réessaiera dans 25s.
    }
  }

  Future<void> refreshNow() => _poll();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
