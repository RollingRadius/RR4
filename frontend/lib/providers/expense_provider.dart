import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/expense_api.dart';
import 'package:fleet_management/data/models/expense_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Expense API Provider
final expenseApiProvider = Provider<ExpenseApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ExpenseApi(apiService);
});

/// Expense State
class ExpenseState {
  final List<ExpenseModel> expenses;
  final bool isLoading;
  final String? error;
  final ExpenseModel? selectedExpense;
  final int total;
  final String? statusFilter;
  final String? categoryFilter;
  final Map<String, dynamic>? summary;

  ExpenseState({
    this.expenses = const [],
    this.isLoading = false,
    this.error,
    this.selectedExpense,
    this.total = 0,
    this.statusFilter,
    this.categoryFilter,
    this.summary,
  });

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    bool? isLoading,
    String? error,
    ExpenseModel? selectedExpense,
    int? total,
    String? statusFilter,
    String? categoryFilter,
    Map<String, dynamic>? summary,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedExpense: selectedExpense ?? this.selectedExpense,
      total: total ?? this.total,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      summary: summary ?? this.summary,
    );
  }
}

/// Expense Notifier
class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseApi _expenseApi;

  ExpenseNotifier(this._expenseApi) : super(ExpenseState());

  /// Load expenses with filters
  Future<void> loadExpenses({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? category,
    String? vehicleId,
    String? driverId,
    String? fromDate,
    String? toDate,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      statusFilter: status,
      categoryFilter: category,
    );

    try {
      final response = await _expenseApi.getExpenses(
        page: page,
        pageSize: pageSize,
        status: status,
        category: category,
        vehicleId: vehicleId,
        driverId: driverId,
        fromDate: fromDate,
        toDate: toDate,
      );

      state = state.copyWith(
        expenses: response['expenses'] as List<ExpenseModel>,
        total: response['total'] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Get expense by ID
  Future<ExpenseModel?> getExpenseById(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final expense = await _expenseApi.getExpense(id);
      state = state.copyWith(
        selectedExpense: expense,
        isLoading: false,
      );
      return expense;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Create expense
  Future<bool> createExpense(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _expenseApi.createExpense(data);
      await loadExpenses(status: state.statusFilter, category: state.categoryFilter);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update expense
  Future<bool> updateExpense(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _expenseApi.updateExpense(id, data);
      await loadExpenses(status: state.statusFilter, category: state.categoryFilter);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Delete expense
  Future<bool> deleteExpense(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _expenseApi.deleteExpense(id);
      await loadExpenses(status: state.statusFilter, category: state.categoryFilter);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Submit expense
  Future<bool> submitExpense(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _expenseApi.submitExpense(id);
      await loadExpenses(status: state.statusFilter, category: state.categoryFilter);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Approve expense
  Future<bool> approveExpense(String id, {
    required bool approved,
    String? rejectionReason,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _expenseApi.approveExpense(
        id,
        approved: approved,
        rejectionReason: rejectionReason,
      );
      await loadExpenses(status: state.statusFilter, category: state.categoryFilter);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Mark expense as paid
  Future<bool> markExpensePaid(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _expenseApi.markExpensePaid(id);
      await loadExpenses(status: state.statusFilter, category: state.categoryFilter);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Load summary
  Future<void> loadSummary({
    String groupBy = 'category',
    String? fromDate,
    String? toDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      Map<String, dynamic> summary;

      switch (groupBy) {
        case 'vehicle':
          summary = await _expenseApi.getSummaryByVehicle(
            fromDate: fromDate,
            toDate: toDate,
          );
          break;
        case 'month':
          summary = await _expenseApi.getSummaryByMonth(
            fromDate: fromDate,
            toDate: toDate,
          );
          break;
        default:
          summary = await _expenseApi.getSummaryByCategory(
            fromDate: fromDate,
            toDate: toDate,
          );
      }

      state = state.copyWith(
        summary: summary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear selected expense
  void clearSelectedExpense() {
    state = state.copyWith(selectedExpense: null);
  }
}

/// Expense State Notifier Provider
final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  final expenseApi = ref.watch(expenseApiProvider);
  return ExpenseNotifier(expenseApi);
});
