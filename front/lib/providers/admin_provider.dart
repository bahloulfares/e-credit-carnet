import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_epicier_model.dart';
import '../services/admin_service.dart';
import 'auth_provider.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminService(apiClient: apiClient);
});

final adminEpiciersProvider =
    StateNotifierProvider<AdminEpiciersNotifier, AdminEpiciersState>((ref) {
      final adminService = ref.watch(adminServiceProvider);
      return AdminEpiciersNotifier(adminService);
    });

final adminGlobalStatsProvider = FutureProvider<AdminGlobalStats>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getGlobalStats();
});

final adminEpicierDetailsProvider = FutureProvider.family<AdminEpicier, String>(
  (ref, epicierId) async {
    final adminService = ref.watch(adminServiceProvider);
    return adminService.getEpicierById(epicierId);
  },
);

class AdminEpiciersState {
  final List<AdminEpicier> epiciers;
  final bool isLoading;
  final String? error;
  final String search;
  final int currentPage;
  final bool hasMore;

  AdminEpiciersState({
    this.epiciers = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.currentPage = 0,
    this.hasMore = true,
  });

  AdminEpiciersState copyWith({
    List<AdminEpicier>? epiciers,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? search,
    int? currentPage,
    bool? hasMore,
  }) {
    return AdminEpiciersState(
      epiciers: epiciers ?? this.epiciers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      search: search ?? this.search,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class AdminEpiciersNotifier extends StateNotifier<AdminEpiciersState> {
  final AdminService adminService;
  static const int _pageSize = 20;

  AdminEpiciersNotifier(this.adminService) : super(AdminEpiciersState()) {
    loadEpiciers();
  }

  Future<void> loadEpiciers({String? search, bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    if (!refresh && !state.hasMore) return;

    final nextSearch = search ?? state.search;
    final page = refresh ? 0 : state.currentPage;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      search: nextSearch,
      currentPage: page,
    );
    try {
      final epiciers = await adminService.getEpiciers(
        search: nextSearch,
        skip: page * _pageSize,
        take: _pageSize,
      );

      if (refresh) {
        state = state.copyWith(
          epiciers: epiciers,
          isLoading: false,
          currentPage: 1,
          hasMore: epiciers.length == _pageSize,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          epiciers: [...state.epiciers, ...epiciers],
          isLoading: false,
          currentPage: page + 1,
          hasMore: epiciers.length == _pageSize,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleStatus(AdminEpicier epicier) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await adminService.setEpicierStatus(epicier.id, !epicier.isActive);
      await loadEpiciers(search: state.search, refresh: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String epicierId,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await adminService.resetEpicierPassword(epicierId, newPassword);
      // Auto-refresh après changement de mot de passe
      await loadEpiciers(search: state.search, refresh: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<AdminEpicier> createEpicier({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    String? phone,
    String? shopName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newEpicier = await adminService.createEpicier(
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password,
        phone: phone,
        shopName: shopName,
      );
      // Auto-refresh après création
      await loadEpiciers(search: state.search, refresh: true);
      return newEpicier;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<AdminEpicier> updateEpicier({
    required String epicierId,
    String? firstName,
    String? lastName,
    String? phone,
    String? shopName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await adminService.updateEpicier(
        epicierId,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        shopName: shopName,
      );
      // Auto-refresh après modification
      await loadEpiciers(search: state.search, refresh: true);
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
