import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/budget_api.dart';
import 'package:fleet_management/data/models/budget_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Budget API Provider
final budgetApiProvider = Provider<BudgetApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return BudgetApi(apiService);
});

/// Budget State
class BudgetState {
  final List<BudgetModel> budgets;
  final bool isLoading;
  final String? error;
  final BudgetModel? selectedBudget;
  final int total;
  final String? categoryFilter;
  final String? periodFilter;
  final Map<String, dynamic>? summary;
  final List<BudgetModel> alerts;
  final Map<String, dynamic>? utilization;

  BudgetState({
    this.budgets = const [],
    this.isLoading = false,
    this.error,
    this.selectedBudget,
    this.total = 0,
    this.categoryFilter,
    this.periodFilter,
    this.summary,
    this.alerts = const [],
    this.utilization,
  });

  BudgetState copyWith({
    List<BudgetModel>? budgets,
    bool? isLoading,
    String? error,
    BudgetModel? selectedBudget,
    int? total,
    String? categoryFilter,
    String? periodFilter,
    Map<String, dynamic>? summary,
    List<BudgetModel>? alerts,
    Map<String, dynamic>? utilization,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedBudget: selectedBudget ?? this.selectedBudget,
      total: total ?? this.total,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      periodFilter: periodFilter ?? this.periodFilter,
      summary: summary ?? this.summary,
      alerts: alerts ?? this.alerts,
      utilization: utilization ?? this.utilization,
    );
  }
}

/// Budget Notifier
class BudgetNotifier extends StateNotifier<BudgetState> {
  final BudgetApi _budgetApi;

  BudgetNotifier(this._budgetApi) : super(BudgetState());

  /// Load budgets with filters
  Future<void> loadBudgets({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? period,
    bool activeOnly = false,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      categoryFilter: category,
      periodFilter: period,
    );

    try {
      final response = await _budgetApi.getBudgets(
        page: page,
        pageSize: pageSize,
        category: category,
        period: period,
        activeOnly: activeOnly,
      );

      state = state.copyWith(
        budgets: response['budgets'] as List<BudgetModel>,
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

  /// Get budget by ID
  Future<BudgetModel?> getBudgetById(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final budget = await _budgetApi.getBudget(id);
      state = state.copyWith(
        selectedBudget: budget,
        isLoading: false,
      );
      return budget;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Create budget
  Future<bool> createBudget(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _budgetApi.createBudget(data);
      await loadBudgets(
        category: state.categoryFilter,
        period: state.periodFilter,
      );
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

  /// Update budget
  Future<bool> updateBudget(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _budgetApi.updateBudget(id, data);
      await loadBudgets(
        category: state.categoryFilter,
        period: state.periodFilter,
      );
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

  /// Delete budget
  Future<bool> deleteBudget(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _budgetApi.deleteBudget(id);
      await loadBudgets(
        category: state.categoryFilter,
        period: state.periodFilter,
      );
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
  Future<void> loadSummary({bool activeOnly = true}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final summary = await _budgetApi.getSummary(activeOnly: activeOnly);

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

  /// Load alerts
  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final alerts = await _budgetApi.getAlerts();

      state = state.copyWith(
        alerts: alerts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load utilization
  Future<void> loadUtilization(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final utilization = await _budgetApi.getUtilization(id);

      state = state.copyWith(
        utilization: utilization,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear selected budget
  void clearSelectedBudget() {
    state = state.copyWith(selectedBudget: null);
  }
}

/// Budget State Notifier Provider
final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  final budgetApi = ref.watch(budgetApiProvider);
  return BudgetNotifier(budgetApi);
});
