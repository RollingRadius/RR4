import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/invoice_api.dart';
import 'package:fleet_management/data/models/invoice_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Invoice API Provider
final invoiceApiProvider = Provider<InvoiceApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return InvoiceApi(apiService);
});

/// Invoice State
class InvoiceState {
  final List<InvoiceModel> invoices;
  final bool isLoading;
  final String? error;
  final InvoiceModel? selectedInvoice;
  final int total;
  final String? statusFilter;
  final Map<String, dynamic>? summary;

  InvoiceState({
    this.invoices = const [],
    this.isLoading = false,
    this.error,
    this.selectedInvoice,
    this.total = 0,
    this.statusFilter,
    this.summary,
  });

  InvoiceState copyWith({
    List<InvoiceModel>? invoices,
    bool? isLoading,
    String? error,
    InvoiceModel? selectedInvoice,
    int? total,
    String? statusFilter,
    Map<String, dynamic>? summary,
  }) {
    return InvoiceState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedInvoice: selectedInvoice ?? this.selectedInvoice,
      total: total ?? this.total,
      statusFilter: statusFilter ?? this.statusFilter,
      summary: summary ?? this.summary,
    );
  }
}

/// Invoice Notifier
class InvoiceNotifier extends StateNotifier<InvoiceState> {
  final InvoiceApi _invoiceApi;

  InvoiceNotifier(this._invoiceApi) : super(InvoiceState());

  /// Load invoices with filters
  Future<void> loadInvoices({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? customerName,
    String? fromDate,
    String? toDate,
    bool overdueOnly = false,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      statusFilter: status,
    );

    try {
      final response = await _invoiceApi.getInvoices(
        page: page,
        pageSize: pageSize,
        status: status,
        customerName: customerName,
        fromDate: fromDate,
        toDate: toDate,
        overdueOnly: overdueOnly,
      );

      state = state.copyWith(
        invoices: response['invoices'] as List<InvoiceModel>,
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

  /// Get invoice by ID
  Future<InvoiceModel?> getInvoiceById(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final invoice = await _invoiceApi.getInvoice(id);
      state = state.copyWith(
        selectedInvoice: invoice,
        isLoading: false,
      );
      return invoice;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Create invoice
  Future<bool> createInvoice(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _invoiceApi.createInvoice(data);
      await loadInvoices(status: state.statusFilter);
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

  /// Update invoice
  Future<bool> updateInvoice(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _invoiceApi.updateInvoice(id, data);
      await loadInvoices(status: state.statusFilter);
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

  /// Delete invoice
  Future<bool> deleteInvoice(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _invoiceApi.deleteInvoice(id);
      await loadInvoices(status: state.statusFilter);
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

  /// Send invoice
  Future<bool> sendInvoice(String id, {
    String? recipientEmail,
    List<String>? ccEmails,
    String? customMessage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _invoiceApi.sendInvoice(
        id,
        recipientEmail: recipientEmail,
        ccEmails: ccEmails,
        customMessage: customMessage,
      );
      await loadInvoices(status: state.statusFilter);
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

  /// Record payment
  Future<bool> recordPayment(String id, {
    required double amount,
    required String paymentDate,
    required String paymentMethod,
    String? referenceNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _invoiceApi.recordPayment(
        id,
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
      );
      await loadInvoices(status: state.statusFilter);
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

  /// Cancel invoice
  Future<bool> cancelInvoice(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _invoiceApi.cancelInvoice(id);
      await loadInvoices(status: state.statusFilter);
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
      final summary = await _invoiceApi.getSummary(
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

  /// Clear selected invoice
  void clearSelectedInvoice() {
    state = state.copyWith(selectedInvoice: null);
  }
}

/// Invoice State Notifier Provider
final invoiceProvider = StateNotifierProvider<InvoiceNotifier, InvoiceState>((ref) {
  final invoiceApi = ref.watch(invoiceApiProvider);
  return InvoiceNotifier(invoiceApi);
});
