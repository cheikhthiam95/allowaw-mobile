/// Configuration de l'API. Par défaut pointé vers l'environnement de dev
/// (données de démo riches — ~150 comptes, ~600 annonces avec photos).
/// Pour pointer vers la production, changez [apiBaseUrl] ci-dessous vers
/// https://allowaw.sn/api/v1
class ApiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dev.allowaw.sn/api/v1',
  );

  // Le domaine sans /api/v1, pour les liens whatsapp/tel construits côté app.
  static String get webBaseUrl => apiBaseUrl.replaceFirst('/api/v1', '');
}
