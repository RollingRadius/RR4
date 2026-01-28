import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/company_api.dart';
import 'package:fleet_management/data/models/company_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Company API Provider
final companyApiProvider = Provider<CompanyApi>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CompanyApi(apiService);
});

/// Company State
class CompanyState {
  final List<CompanyModel> searchResults;
  final bool isLoading;
  final String? error;
  final CompanyModel? selectedCompany;

  CompanyState({
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
    this.selectedCompany,
  });

  CompanyState copyWith({
    List<CompanyModel>? searchResults,
    bool? isLoading,
    String? error,
    CompanyModel? selectedCompany,
  }) {
    return CompanyState(
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCompany: selectedCompany ?? this.selectedCompany,
    );
  }
}

/// Company Notifier
class CompanyNotifier extends StateNotifier<CompanyState> {
  final CompanyApi _companyApi;

  CompanyNotifier(this._companyApi) : super(CompanyState());

  /// Search companies
  Future<void> searchCompanies(String query) async {
    if (query.length < 3) {
      state = state.copyWith(searchResults: [], error: null);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final companies = await _companyApi.searchCompanies(query);

      state = state.copyWith(
        searchResults: companies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Validate company details
  Future<Map<String, dynamic>?> validateCompanyDetails({
    String? gstin,
    String? panNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _companyApi.validateCompanyDetails(
        gstin: gstin,
        panNumber: panNumber,
      );

      state = state.copyWith(isLoading: false);

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Clear search results
  void clearSearchResults() {
    state = state.copyWith(searchResults: []);
  }

  /// Select company
  void selectCompany(CompanyModel company) {
    state = state.copyWith(selectedCompany: company);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Company Provider
final companyProvider = StateNotifierProvider<CompanyNotifier, CompanyState>((ref) {
  final companyApi = ref.watch(companyApiProvider);
  return CompanyNotifier(companyApi);
});
