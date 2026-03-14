import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/transaction_model.dart';
import 'auth_provider.dart';
import 'sync_queue_provider.dart';

// Transaction list state notifier
final transactionListProvider =
    StateNotifierProvider.family<
      TransactionListNotifier,
      TransactionListState,
      String?
    >((ref, clientId) {
      final transactionService = ref.watch(transactionServiceProvider);
      return TransactionListNotifier(transactionService, clientId, ref);
    });

// Single transaction provider
final transactionDetailsProvider = FutureProvider.family<Transaction, String>((
  ref,
  transactionId,
) async {
  final transactionService = ref.watch(transactionServiceProvider);
  return transactionService.getTransactionById(transactionId);
});

class TransactionListState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  TransactionListState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 0,
    this.hasMore = true,
  });

  TransactionListState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? currentPage,
    bool? hasMore,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final TransactionService transactionService;
  final String? clientId;
  final Ref ref;
  String? _typeFilter;
  bool? _isPaidFilter;
  int? _monthFilter;
  int? _yearFilter;

  TransactionListNotifier(this.transactionService, this.clientId, this.ref)
    : super(TransactionListState()) {
    loadTransactions();
  }

  Future<void> applyFilters({
    String? type,
    bool? isPaid,
    int? month,
    int? year,
  }) async {
    _typeFilter = type;
    _isPaidFilter = isPaid;
    _monthFilter = month;
    _yearFilter = year;
    await loadTransactions(refresh: true);
  }

  Future<void> loadTransactions({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;
    if (!refresh && !state.hasMore) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentPage: refresh ? 0 : state.currentPage,
    );
    try {
      final page = refresh ? 0 : state.currentPage;
      final transactions = await transactionService.getTransactions(
        clientId: clientId,
        skip: page * 20,
        take: 20,
        type: _typeFilter,
        isPaid: _isPaidFilter,
        month: _monthFilter,
        year: _yearFilter,
      );

      if (refresh) {
        state = state.copyWith(
          transactions: transactions,
          isLoading: false,
          currentPage: 0,
          hasMore: transactions.length == 20,
        );
      } else {
        state = state.copyWith(
          transactions: [...state.transactions, ...transactions],
          isLoading: false,
          currentPage: page + 1,
          hasMore: transactions.length == 20,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createTransaction({
    required String clientId,
    required String type,
    required double amount,
    String? description,
    DateTime? dueDate,
    String? paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newTransaction = await transactionService.createTransaction(
        clientId: clientId,
        type: type,
        amount: amount,
        description: description,
        dueDate: dueDate,
        paymentMethod: type == 'PAYMENT' ? (paymentMethod ?? 'cash') : null,
      );
      state = state.copyWith(
        transactions: [newTransaction, ...state.transactions],
        isLoading: false,
      );

      ref.read(syncQueueProvider.notifier).enqueue({
        'entityType': 'transaction',
        'entityId': newTransaction.id,
        'operationType': 'CREATE',
        'data': {
          'id': newTransaction.id,
          'clientId': newTransaction.clientId,
          'type': newTransaction.type,
          'amount': newTransaction.amount,
          'description': newTransaction.description,
          'transactionDate': newTransaction.transactionDate.toIso8601String(),
          'dueDate': newTransaction.dueDate?.toIso8601String(),
          'isPaid': newTransaction.isPaid,
          'paidAt': newTransaction.paidAt?.toIso8601String(),
          'paymentMethod': newTransaction.paymentMethod,
        },
      });
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> updateTransaction(
    String transactionId, {
    double? amount,
    String? description,
    DateTime? dueDate,
    String? paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedTransaction = await transactionService.updateTransaction(
        transactionId,
        amount: amount,
        description: description,
        dueDate: dueDate,
        paymentMethod: paymentMethod,
      );

      final updatedTransactions = state.transactions.map((t) {
        return t.id == transactionId ? updatedTransaction : t;
      }).toList();

      state = state.copyWith(
        transactions: updatedTransactions,
        isLoading: false,
      );

      ref.read(syncQueueProvider.notifier).enqueue({
        'entityType': 'transaction',
        'entityId': updatedTransaction.id,
        'operationType': 'UPDATE',
        'data': {
          'id': updatedTransaction.id,
          'amount': updatedTransaction.amount,
          'description': updatedTransaction.description,
          'dueDate': updatedTransaction.dueDate?.toIso8601String(),
          'isPaid': updatedTransaction.isPaid,
          'paidAt': updatedTransaction.paidAt?.toIso8601String(),
          'paymentMethod': updatedTransaction.paymentMethod,
        },
      });
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await transactionService.deleteTransaction(transactionId);
      state = state.copyWith(
        transactions: state.transactions
            .where((t) => t.id != transactionId)
            .toList(),
        isLoading: false,
      );

      ref.read(syncQueueProvider.notifier).enqueue({
        'entityType': 'transaction',
        'entityId': transactionId,
        'operationType': 'DELETE',
        'data': {'id': transactionId},
      });
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}
