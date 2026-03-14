import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/client_service.dart';
import '../services/transaction_service.dart' as txn_service;
import '../services/dashboard_service.dart';
import '../models/user_model.dart';
import '../models/client_model.dart';
import '../models/transaction_model.dart';

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Auth State Provider (User and token)
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});

// Client Service Provider
final clientServiceProvider = Provider<ClientService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClientService(apiClient: apiClient);
});

// Transaction Service Provider
final transactionServiceProvider = Provider<txn_service.TransactionService>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return txn_service.TransactionService(apiClient: apiClient);
});

// Dashboard Service Provider
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardService(apiClient: apiClient);
});

// Clients list provider
final clientsProvider = FutureProvider.family<List<Client>, int>((
  ref,
  page,
) async {
  final clientService = ref.watch(clientServiceProvider);
  return clientService.getClients(skip: page * 10, take: 10);
});

// Client details provider
final clientDetailsProvider = FutureProvider.family<Client, String>((
  ref,
  clientId,
) async {
  final clientService = ref.watch(clientServiceProvider);
  return clientService.getClient(clientId);
});

// Transactions provider
final transactionsProvider = FutureProvider.family<List<Transaction>, String?>((
  ref,
  clientId,
) async {
  final transactionService = ref.watch(transactionServiceProvider);
  return transactionService.getTransactions(clientId: clientId);
});

// Auth State Model
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isOffline;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isOffline = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isOffline,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient apiClient;

  AuthNotifier(this.apiClient) : super(AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await apiClient.initialize();
    if (apiClient.isAuthenticated) {
      try {
        final user = await apiClient.getProfile();
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isOffline: false,
        );
      } catch (e) {
        final isNetworkError =
            e is ApiException && (e.statusCode == 0 || e.statusCode == 408);
        if (isNetworkError) {
          // Pas de réseau — utiliser le profil mis en cache
          final cachedUser = await apiClient.loadUserCache();
          if (cachedUser != null) {
            state = state.copyWith(
              user: cachedUser,
              isAuthenticated: true,
              isOffline: true,
            );
            return;
          }
        }
        // Erreur auth (401/403) ou pas de cache → déconnexion
        await apiClient.logout();
        final errorText = e.toString().toLowerCase().contains('deactivated')
            ? 'Votre compte est désactivé. Contactez l’administrateur.'
            : isNetworkError
            ? 'Hors ligne. Reconnectez-vous pour accéder à l’application.'
            : 'Session invalide. Veuillez vous reconnecter.';
        state = state.copyWith(error: errorText, isAuthenticated: false);
      }
    }
  }

  Future<void> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    String? shopName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.register(
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password,
        shopName: shopName,
        phone: phone,
      );
      final user = User.fromJson(response['user']);
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiClient.login(email: email, password: password);
      final user = User.fromJson(response['user']);
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      final errorText =
          e.toString().toLowerCase().contains('invalid credentials')
          ? 'Email ou mot de passe incorrect'
          : e.toString().toLowerCase().contains('deactivated')
          ? 'Votre compte est désactivé. Contactez l’administrateur.'
          : 'Échec de connexion. Veuillez réessayer.';
      state = state.copyWith(error: errorText, isLoading: false);
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await apiClient.updateProfile(
        firstName: firstName,
        lastName: lastName,
        shopName: shopName,
        shopAddress: shopAddress,
        shopPhone: shopPhone,
        phone: phone,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await apiClient.logout();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}
