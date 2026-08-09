import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  String? lastError;

  AuthProvider() {
    ApiClient.instance.onUnauthorized = _handleUnauthorized;
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Appelé au démarrage de l'app : y a-t-il un jeton stocké, et est-il
  /// toujours valide côté serveur ?
  Future<void> bootstrap() async {
    final token = await TokenStorage.read();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      currentUser = await _authService.me();
      status = AuthStatus.authenticated;
    } catch (_) {
      await TokenStorage.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) => _attempt(() async {
        currentUser = await _authService.login(email: email, password: password);
      });

  Future<bool> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String firstName,
    required String lastName,
    required String phone,
    String accountType = 'particular',
    String? businessName,
  }) =>
      _attempt(() async {
        currentUser = await _authService.register(
          email: email,
          password: password,
          passwordConfirmation: passwordConfirmation,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          accountType: accountType,
          businessName: businessName,
        );
      });

  Future<bool> _attempt(Future<void> Function() action) async {
    lastError = null;
    try {
      await action();
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void updateUser(AppUser user) {
    currentUser = user;
    notifyListeners();
  }

  void _handleUnauthorized() {
    if (status != AuthStatus.authenticated) return;
    currentUser = null;
    status = AuthStatus.unauthenticated;
    TokenStorage.clear();
    notifyListeners();
  }
}
