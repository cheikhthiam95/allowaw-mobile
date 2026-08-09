import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/profile_service.dart';
import 'local_notifications.dart';

/// Notification push (app fermée/arrière-plan) via Firebase Cloud
/// Messaging — complète LocalNotifications, qui ne peut afficher un
/// message que tant que l'app tourne et garde sa connexion WebSocket
/// ouverte. Voir PushNotifier côté Rails pour l'envoi.
class PushNotifications {
  PushNotifications._();
  static final _profileService = ProfileService();
  static bool _initialized = false;

  /// onOpenConversation est appelé quand l'utilisateur tape une
  /// notification (app en arrière-plan ou totalement fermée).
  static Future<void> init({required void Function(int conversationId) onOpenConversation}) async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Pas de google-services.json valide sur ce build, ou projet Firebase
      // injoignable — l'app continue sans push plutôt que de planter (le
      // canal WebSocket/notifications locales reste actif indépendamment).
      return;
    }
    _initialized = true;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // Premier plan : FCM n'affiche rien automatiquement dans ce cas — on
    // réutilise le même mécanisme que pour les messages reçus par WebSocket.
    FirebaseMessaging.onMessage.listen((message) {
      final conversationId = _conversationIdOf(message);
      if (conversationId == null) return;
      LocalNotifications.showMessageNotification(
        conversationId: conversationId,
        title: message.notification?.title ?? 'Nouveau message',
        body: message.notification?.body ?? '',
      );
    });

    // Arrière-plan, notification tapée pour revenir au premier plan.
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleTap(message, onOpenConversation));

    // App totalement fermée, lancée via un tap sur la notification.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _handleTap(initialMessage, onOpenConversation);

    messaging.onTokenRefresh.listen(_registerToken);
  }

  static int? _conversationIdOf(RemoteMessage message) =>
      int.tryParse(message.data['conversationId']?.toString() ?? '');

  static void _handleTap(RemoteMessage message, void Function(int) onOpenConversation) {
    final conversationId = _conversationIdOf(message);
    if (conversationId != null) onOpenConversation(conversationId);
  }

  /// À appeler juste après une connexion réussie — envoie le jeton de cet
  /// appareil au backend pour qu'il puisse lui adresser des push.
  static Future<void> registerTokenAfterLogin() async {
    if (!_initialized) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerToken(token);
  }

  static Future<void> _registerToken(String token) async {
    try {
      await _profileService.updatePushToken(token);
    } catch (_) {
      // Silencieux — pas critique, WebSocket/WhatsApp restent actifs.
    }
  }

  /// À appeler à la déconnexion — évite d'adresser des push à quelqu'un
  /// qui ne s'est plus connecté sur cet appareil depuis.
  static Future<void> unregisterToken() async {
    if (!_initialized) return;
    try {
      await _profileService.updatePushToken(null);
    } catch (_) {}
  }
}

// Doit rester une fonction top-level (pas une méthode de classe) — FCM la
// lance dans un isolate séparé sur Android, qui n'a pas accès à l'état de
// l'app : Firebase doit y être réinitialisé indépendamment.
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
