import 'package:dio/dio.dart';
import 'constants.dart';
import 'token_storage.dart';

/// Exception applicative uniforme pour toutes les erreurs API — les écrans
/// n'ont qu'un seul type d'erreur à gérer, avec un message déjà prêt à
/// afficher (déjà extrait des réponses `{error: ...}` / `{errors: [...]}`
/// renvoyées par Api::V1::BaseController côté Rails).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Signal levé par l'intercepteur quand le jeton est invalide/expiré (401)
/// — permet à l'app de rediriger vers l'écran de connexion sans dupliquer
/// cette logique dans chaque service.
typedef OnUnauthorized = void Function();

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  OnUnauthorized? onUnauthorized;

  Dio get dio => _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return (res.data ?? {}) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> patch(String path, {dynamic data}) async {
    try {
      final res = await _dio.patch(path, data: data);
      return (res.data ?? {}) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    try {
      final res = await _dio.put(path, data: data);
      return (res.data ?? {}) as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    String message = 'Une erreur est survenue. Vérifiez votre connexion.';
    if (data is Map) {
      if (data['error'] is String) {
        message = data['error'] as String;
      } else if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        message = (data['errors'] as List).join(', ');
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'La connexion a expiré. Réessayez.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
    }

    return ApiException(message, statusCode: status);
  }
}
