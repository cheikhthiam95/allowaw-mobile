import '../core/api_client.dart';
import '../models/user.dart';

class PhoneVerificationService {
  final _api = ApiClient.instance;

  Future<String> sendCode() async {
    final res = await _api.post('/phone_verification');
    return res['message'] as String? ?? 'Code envoyé.';
  }

  Future<AppUser> verifyCode(String code) async {
    final res = await _api.patch('/phone_verification', data: {'code': code});
    return AppUser.fromJson(res['user'] as Map<String, dynamic>);
  }
}
