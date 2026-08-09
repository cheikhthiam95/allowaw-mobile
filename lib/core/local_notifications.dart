import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Fine couche autour de flutter_local_notifications — utilisée pour
/// signaler un nouveau message pendant que l'app est ouverte (premier plan
/// ou arrière-plan léger). Le vrai push (app totalement fermée) nécessite
/// Firebase Cloud Messaging, non configuré pour l'instant (voir README).
class LocalNotifications {
  LocalNotifications._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init({void Function(String? payload)? onTap}) async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) => onTap?.call(response.payload),
    );
    _initialized = true;

    // Android 13+ et iOS exigent une autorisation explicite à l'exécution —
    // la déclaration dans AndroidManifest.xml/Info.plist seule ne suffit pas.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> showMessageNotification({
    required int conversationId,
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Messages',
        channelDescription: 'Nouveaux messages de la messagerie Allôwaw',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
    );
    await _plugin.show(conversationId, title, body, details, payload: conversationId.toString());
  }
}
