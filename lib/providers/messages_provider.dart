import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/action_cable_client.dart';
import '../core/local_notifications.dart';
import '../models/conversation.dart';
import '../services/conversation_service.dart';

/// Messagerie temps réel : écoute UserChannel (ActionCable, voir
/// core/action_cable_client.dart) pour un badge de non-lus et une
/// notification locale INSTANTANÉS à chaque nouveau message, dans
/// n'importe laquelle des conversations de l'utilisateur. Un poll de
/// secours (toutes les 60s) resynchronise le compte exact en cas de
/// déconnexion WebSocket passagère (réseau mobile) — le WebSocket reste
/// la source principale, le poll n'est qu'un filet de sécurité.
class MessagesProvider extends ChangeNotifier {
  final _service = ConversationService();
  StreamSubscription? _wsSub;
  Timer? _fallbackTimer;
  int? _currentConversationId; // en cours de consultation : pas de notif pour celle-ci

  int unreadCount = 0;
  List<Conversation> conversations = [];

  void setActiveConversation(int? id) {
    _currentConversationId = id;
  }

  void startPolling() {
    _wsSub?.cancel();
    _wsSub = ActionCableClient.instance.messages.listen(_onRealtimeMessage);
    ActionCableClient.instance.connect();

    _poll(); // état initial
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 60), (_) => _poll());
  }

  void stopPolling() {
    _wsSub?.cancel();
    _wsSub = null;
    ActionCableClient.instance.disconnect();
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    unreadCount = 0;
    conversations = [];
  }

  void _onRealtimeMessage(Map<String, dynamic> data) {
    if (data['type'] != 'new_message') return;

    final conversationId = data['conversationId'] as int?;
    unreadCount = (data['unreadCount'] as int?) ?? unreadCount;
    notifyListeners();

    if (conversationId != null && conversationId != _currentConversationId) {
      LocalNotifications.showMessageNotification(
        conversationId: conversationId,
        title: data['senderName'] as String? ?? 'Nouveau message',
        body: data['body'] as String? ?? '',
      );
    }

    // Resynchronise la liste des conversations en tâche de fond (pour
    // l'écran Messages, sans bloquer l'affichage instantané du badge
    // ci-dessus qui vient déjà du message WebSocket).
    _poll();
  }

  Future<void> _poll() async {
    try {
      final fresh = await _service.index();
      conversations = fresh;
      unreadCount = fresh.fold(0, (sum, c) => sum + c.unreadCount);
      notifyListeners();
    } catch (_) {
      // Silencieux — le WebSocket reste la source principale, un poll
      // raté n'a pas besoin d'interrompre l'usage de l'app.
    }
  }

  Future<void> refreshNow() => _poll();

  @override
  void dispose() {
    _wsSub?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }
}
