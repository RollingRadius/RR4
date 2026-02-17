import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/models/branding_model.dart';
import 'package:fleet_management/data/services/branding_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/theme_provider.dart';

/// Branding State
class BrandingState {
  final OrganizationBranding? branding;
  final bool isLoading;
  final bool isUploading;
  final String? error;
  final String? successMessage;

  BrandingState({
    this.branding,
    this.isLoading = false,
    this.isUploading = false,
    this.error,
    this.successMessage,
  });

  BrandingState copyWith({
    OrganizationBranding? branding,
    bool? isLoading,
    bool? isUploading,
    String? error,
    String? successMessage,
  }) {
    return BrandingState(
      branding: branding ?? this.branding,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Branding Notifier
class BrandingNotifier extends StateNotifier<BrandingState> {
  final BrandingApi _brandingApi;
  final Ref _ref;

  BrandingNotifier(this._brandingApi, this._ref) : super(BrandingState());

  /// Load branding
  Future<void> loadBranding() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final branding = await _brandingApi.getBranding();
      state = BrandingState(branding: branding, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load branding: ${e.toString()}',
      );
    }
  }

  /// Update colors and theme config
  Future<void> updateColors({
    required BrandingColors colors,
    Map<String, dynamic>? themeConfig,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final updatedBranding = await _brandingApi.updateBranding(
        colors: colors,
        themeConfig: themeConfig,
      );

      state = BrandingState(
        branding: updatedBranding,
        isLoading: false,
        successMessage: 'Branding updated successfully',
      );

      // Reload theme with new branding
      _ref.read(themeProvider.notifier).loadBranding();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update branding: ${e.toString()}',
      );
    }
  }

  /// Upload logo
  Future<void> uploadLogo(String filePath) async {
    state = state.copyWith(isUploading: true, error: null, successMessage: null);

    try {
      await _brandingApi.uploadLogo(filePath);

      // Reload branding to get updated logo URL
      final updatedBranding = await _brandingApi.getBranding();

      state = BrandingState(
        branding: updatedBranding,
        isUploading: false,
        successMessage: 'Logo uploaded successfully',
      );

      // Reload theme with new branding
      _ref.read(themeProvider.notifier).loadBranding();
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: 'Failed to upload logo: ${e.toString()}',
      );
    }
  }

  /// Delete logo
  Future<void> deleteLogo() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _brandingApi.deleteLogo();

      // Reload branding to get updated state
      final updatedBranding = await _brandingApi.getBranding();

      state = BrandingState(
        branding: updatedBranding,
        isLoading: false,
        successMessage: 'Logo deleted successfully',
      );

      // Reload theme with new branding
      _ref.read(themeProvider.notifier).loadBranding();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete logo: ${e.toString()}',
      );
    }
  }

  /// Clear error and success messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

/// Branding Provider
final brandingProvider = StateNotifierProvider<BrandingNotifier, BrandingState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final brandingApi = BrandingApi(apiService);
  return BrandingNotifier(brandingApi, ref);
});
