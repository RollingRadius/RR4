import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/report_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Report API Provider
final reportApiProvider = Provider<ReportApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReportApi(apiService);
});

/// Report State
class ReportState {
  final Map<String, dynamic>? currentReport;
  final String? currentReportType;
  final bool isLoading;
  final String? error;

  ReportState({
    this.currentReport,
    this.currentReportType,
    this.isLoading = false,
    this.error,
  });

  ReportState copyWith({
    Map<String, dynamic>? currentReport,
    String? currentReportType,
    bool? isLoading,
    String? error,
  }) {
    return ReportState(
      currentReport: currentReport ?? this.currentReport,
      currentReportType: currentReportType ?? this.currentReportType,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Report Notifier
class ReportNotifier extends StateNotifier<ReportState> {
  final ReportApi _reportApi;

  ReportNotifier(this._reportApi) : super(ReportState());

  /// Load driver list report
  Future<void> loadDriverListReport({String? statusFilter}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final report = await _reportApi.getDriverListReport(
        statusFilter: statusFilter,
      );

      state = state.copyWith(
        currentReport: report,
        currentReportType: 'driver_list',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load license expiry report
  Future<void> loadLicenseExpiryReport({int daysAhead = 90}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final report = await _reportApi.getLicenseExpiryReport(
        daysAhead: daysAhead,
      );

      state = state.copyWith(
        currentReport: report,
        currentReportType: 'license_expiry',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load organization summary report
  Future<void> loadOrganizationSummaryReport() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final report = await _reportApi.getOrganizationSummaryReport();

      state = state.copyWith(
        currentReport: report,
        currentReportType: 'organization_summary',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load audit log report
  Future<void> loadAuditLogReport({
    DateTime? startDate,
    DateTime? endDate,
    String? actionFilter,
    int limit = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final report = await _reportApi.getAuditLogReport(
        startDate: startDate,
        endDate: endDate,
        actionFilter: actionFilter,
        limit: limit,
      );

      state = state.copyWith(
        currentReport: report,
        currentReportType: 'audit_log',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load user activity report
  Future<void> loadUserActivityReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final report = await _reportApi.getUserActivityReport(
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        currentReport: report,
        currentReportType: 'user_activity',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear current report
  void clearReport() {
    state = ReportState();
  }
}

/// Report Provider
final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final reportApi = ref.watch(reportApiProvider);
  return ReportNotifier(reportApi);
});
