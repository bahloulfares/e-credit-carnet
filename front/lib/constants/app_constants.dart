/// CONSTANTES D'APPLICATION - À UTILISER PARTOUT
const String appName = 'ProCreditApp';
const String appVersion = '1.0.0';

/// ========================================
/// CONFIGURATION API
/// Priorité 1: --dart-define=API_BASE_URL
/// Priorité 2: valeur locale par défaut
/// ========================================
const String apiIpAddress = '10.251.81.78';
const String defaultApiBaseUrl = 'http://$apiIpAddress:3000/api';
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: defaultApiBaseUrl,
);

void validateRuntimeConfig() {
  const envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  const isRelease = bool.fromEnvironment('dart.vm.product');

  if (isRelease && envApiBaseUrl.isEmpty) {
    throw Exception(
      'Missing API_BASE_URL for release build. Use --dart-define=API_BASE_URL=https://your-api/api',
    );
  }
}

const int connectionTimeout = 30000;
const int receiveTimeout = 30000;

/// ROUTES DE NAVIGATION
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String clients = '/clients';
  static const String clientDetails = '/client-details';
  static const String addClient = '/add-client';
  static const String transactions = '/transactions';
  static const String adminEpiciers = '/admin-epiciers';
  static const String addTransaction = '/add-transaction';
  static const String settings = '/settings';
  static const String profile = '/profile';
}

/// MESSAGES D'ERREUR GÉNÉRIQUES
class ErrorMessages {
  static const String networkError =
      'Erreur de connexion. Veuillez vérifier votre connexion Internet.';
  static const String validationError =
      'Erreur de validation. Veuillez vérifier vos données.';
  static const String serverError =
      'Erreur serveur. Veuillez réessayer plus tard.';
  static const String unauthorizedError =
      'Non autorisé. Veuillez vous reconnecter.';
  static const String notFoundError = 'Ressource non trouvée.';
}
