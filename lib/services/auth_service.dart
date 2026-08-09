import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/user.dart';

class AuthService {
  final _api = ApiClient.instance;

  Future<AppUser> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String firstName,
    required String lastName,
    required String phone,
    String accountType = 'particular',
    String? businessName,
  }) async {
    final res = await _api.post('/registrations', data: {
      'user': {
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'account_type': accountType,
        if (businessName != null) 'business_name': businessName,
      }
    });
    await TokenStorage.save(res['token'] as String);
    return AppUser.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<AppUser> login({required String email, required String password}) async {
    final res = await _api.post('/sessions', data: {
      'user': {'email': email, 'password': password}
    });
    await TokenStorage.save(res['token'] as String);
    return AppUser.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<AppUser> me() async {
    final res = await _api.get('/me');
    return AppUser.fromJson(res['user'] as Map<String, dynamic>);
  }

  Future<void> logout() => TokenStorage.clear();

  Future<String> forgotPassword(String email) async {
    final res = await _api.post('/password', data: {'email': email});
    return res['message'] as String? ?? 'Email envoyé si le compte existe.';
  }

  Future<AppUser> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await _api.put('/password', data: {
      'reset_password_token': token,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    await TokenStorage.save(res['token'] as String);
    return AppUser.fromJson(res['user'] as Map<String, dynamic>);
  }
}
