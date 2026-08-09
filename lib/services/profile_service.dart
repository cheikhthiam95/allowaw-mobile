import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class ProfileService {
  final _api = ApiClient.instance;

  Future<AppUser> update(Map<String, dynamic> fields, {File? avatar}) async {
    final map = <String, dynamic>{};
    fields.forEach((k, v) {
      if (v != null) map[k] = v.toString();
    });
    if (avatar != null) {
      map['avatar'] = await MultipartFile.fromFile(avatar.path, filename: avatar.path.split('/').last);
    }
    final res = await _api.dio.patch('/profile', data: FormData.fromMap(map));
    return AppUser.fromJson((res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  Future<AppUser> complete(Map<String, dynamic> fields) async {
    final res = await _api.patch('/profile/complete', data: fields);
    return AppUser.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) {
    return _api.patch('/profile/password', data: {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  /// Enregistre/rafraîchit le jeton FCM de l'appareil pour les
  /// notifications push (app fermée/arrière-plan) — voir PushNotifier
  /// côté Rails. Passer null efface le jeton (déconnexion).
  Future<void> updatePushToken(String? fcmToken) {
    return _api.patch('/profile/push_token', data: {'fcm_token': fcmToken});
  }
}
