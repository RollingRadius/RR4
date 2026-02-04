import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/payment_api.dart';
import 'package:fleet_management/data/models/payment_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Payment API Provider
final paymentApiProvider = Provider<PaymentApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentApi(apiService);
});

/// Payment State
class PaymentState {
  final List<PaymentModel> payments;
  final bool isLoading;
  final String? error;
  final PaymentModel? selectedPayment;
  final int total;
  final String? typeFilter;
  final String? methodFilter;
  final Map<String, dynamic>? summary;

  PaymentState({
    this.payments = const [],
    this.isLoading = false,
    this.error,
    this.selectedPayment,
    this.total = 0,
    this.typeFilter,
    this.methodFilter,
    this.summary,
  });

  PaymentState copyWith({
    List<PaymentModel>? payments,
    bool? isLoading,
    String? error,
    PaymentModel? selectedPayment,
    int? total,
    String? typeFilter,
    String? methodFilter,
    Map<String, dynamic>? summary,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedPayment: selectedPayment ?? this.selectedPayment,
      total: total ?? this.total,
      typeFilter: typeFilter ?? this.typeFilter,
      methodFilter: methodFilter ?? this.methodFilter,
      summary: summary ?? this.summary,
    );
  }
}

/// Payment Notifier
class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentApi _paymentApi;

  PaymentNotifier(this._paymentApi) : super(PaymentState());

  /// Load payments with filters
  Future<void> loadPayments({
    int page = 1,
    int pageSize = 20,
    String? paymentType,
    String? paymentMethod,
    String? fromDate,
    String? toDate,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      typeFilter: paymentType,
      methodFilter: paymentMethod,
    );

    try {
      final response = await _paymentApi.getPayments(
        page: page,
        pageSize: pageSize,
        paymentType: paymentType,
        paymentMethod: paymentMethod,
        fromDate: fromDate,
        toDate: toDate,
      );

      state = state.copyWith(
        payments: response['payments'] as List<PaymentModel>,
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

  /// Get payment by ID
  Future<PaymentModel?> getPaymentById(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final payment = await _paymentApi.getPayment(id);
      state = state.copyWith(
        selectedPayment: payment,
        isLoading: false,
      );
      return payment;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Create payment
  Future<bool> createPayment(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _paymentApi.createPayment(data);
      await loadPayments(
        paymentType: state.typeFilter,
        paymentMethod: state.methodFilter,
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

  /// Update payment
  Future<bool> updatePayment(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _paymentApi.updatePayment(id, data);
      await loadPayments(
        paymentType: state.typeFilter,
        paymentMethod: state.methodFilter,
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

  /// Delete payment
  Future<bool> deletePayment(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _paymentApi.deletePayment(id);
      await loadPayments(
        paymentType: state.typeFilter,
        paymentMethod: state.methodFilter,
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
  Future<void> loadSummary({
    String? fromDate,
    String? toDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final summary = await _paymentApi.getSummary(
        fromDate: fromDate,
        toDate: toDate,
      );

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

  /// Clear selected payment
  void clearSelectedPayment() {
    state = state.copyWith(selectedPayment: null);
  }
}

/// Payment State Notifier Provider
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final paymentApi = ref.watch(paymentApiProvider);
  return PaymentNotifier(paymentApi);
});
