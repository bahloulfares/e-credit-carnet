import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/client_service.dart';
import '../models/client_model.dart';
import 'auth_provider.dart';

// Client list state notifier
final clientListProvider =
    StateNotifierProvider<ClientListNotifier, ClientListState>((ref) {
      final clientService = ref.watch(clientServiceProvider);
      return ClientListNotifier(clientService);
    });

// Search clients provider
final searchClientsProvider = FutureProvider.family<List<Client>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) {
    return [];
  }
  final clientService = ref.watch(clientServiceProvider);
  return clientService.searchClients(query);
});

// Client details provider
final clientDetailsProvider = FutureProvider.family<Client, String>((
  ref,
  clientId,
) async {
  final clientService = ref.watch(clientServiceProvider);
  return clientService.getClient(clientId);
});

class ClientListState {
  final List<Client> clients;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  ClientListState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
  });

  ClientListState copyWith({
    List<Client>? clients,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? currentPage,
    bool? hasMore,
  }) {
    return ClientListState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ClientListNotifier extends StateNotifier<ClientListState> {
  final ClientService clientService;

  ClientListNotifier(this.clientService) : super(ClientListState()) {
    loadClients();
  }

  Future<void> loadClients({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    if (!refresh && !state.hasMore) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentPage: refresh ? 0 : state.currentPage,
    );
    try {
      final page = refresh ? 0 : state.currentPage;
      final clients = await clientService.getClients(skip: page * 10, take: 10);

      if (refresh) {
        state = state.copyWith(
          clients: clients,
          isLoading: false,
          currentPage: 0,
          hasMore: clients.length == 10,
        );
      } else {
        state = state.copyWith(
          clients: [...state.clients, ...clients],
          isLoading: false,
          currentPage: page + 1,
          hasMore: clients.length == 10,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createClient({
    required String firstName,
    required String lastName,
    String? phone,
    String? email,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newClient = await clientService.createClient(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        address: address,
      );
      state = state.copyWith(
        clients: [newClient, ...state.clients],
        isLoading: false,
      );
      // Auto-refresh pour corriger pagination et stats
      await loadClients(refresh: true);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> updateClient(
    String clientId, {
    required String firstName,
    required String lastName,
    String? phone,
    String? email,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedClient = await clientService.updateClient(
        clientId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        address: address,
      );

      final updatedClients = state.clients.map((c) {
        return c.id == clientId ? updatedClient : c;
      }).toList();

      state = state.copyWith(clients: updatedClients, isLoading: false);
      // Auto-refresh pour corriger pagination et stats
      await loadClients(refresh: true);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteClient(String clientId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await clientService.deleteClient(clientId);
      state = state.copyWith(
        clients: state.clients.where((c) => c.id != clientId).toList(),
        isLoading: false,
      );
      // Auto-refresh pour synchroniser la pagination
      await loadClients(refresh: true);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> setClientStatus(String clientId, bool isActive) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await clientService.setClientStatus(clientId, isActive);
      // Auto-refresh pour synchroniser les données
      await loadClients(refresh: true);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}
