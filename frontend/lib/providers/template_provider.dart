import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/template_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// API Provider
final templateApiProvider = Provider<TemplateApi>((ref) {
  final dio = ref.watch(dioProvider);
  return TemplateApi(dio);
});

// State class
class TemplateState {
  final bool isLoading;
  final String? error;
  final List<dynamic> predefinedTemplates;
  final List<dynamic> customTemplates;
  final Map<String, dynamic>? mergedCapabilities;
  final Map<String, dynamic>? comparison;

  TemplateState({
    this.isLoading = false,
    this.error,
    this.predefinedTemplates = const [],
    this.customTemplates = const [],
    this.mergedCapabilities,
    this.comparison,
  });

  TemplateState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? predefinedTemplates,
    List<dynamic>? customTemplates,
    Map<String, dynamic>? mergedCapabilities,
    Map<String, dynamic>? comparison,
  }) {
    return TemplateState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      predefinedTemplates: predefinedTemplates ?? this.predefinedTemplates,
      customTemplates: customTemplates ?? this.customTemplates,
      mergedCapabilities: mergedCapabilities ?? this.mergedCapabilities,
      comparison: comparison ?? this.comparison,
    );
  }
}

// State Notifier
class TemplateNotifier extends StateNotifier<TemplateState> {
  final TemplateApi _api;

  TemplateNotifier(this._api) : super(TemplateState());

  Future<void> loadPredefinedTemplates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getAllPredefinedTemplates();
      state = state.copyWith(
        isLoading: false,
        predefinedTemplates: response['templates'] as List<dynamic>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>?> getPredefinedTemplate(String roleKey) async {
    try {
      final response = await _api.getPredefinedTemplate(roleKey);
      return response['template'] as Map<String, dynamic>;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> mergeTemplates(List<String> templateKeys, String strategy) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.mergeTemplates(templateKeys, strategy);
      state = state.copyWith(
        isLoading: false,
        mergedCapabilities: response,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> compareTemplates(List<String> templateKeys) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.compareTemplates(templateKeys);
      state = state.copyWith(
        isLoading: false,
        comparison: response['comparison'] as Map<String, dynamic>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadCustomTemplates() async {
    try {
      final response = await _api.getCustomTemplates();
      state = state.copyWith(
        customTemplates: response['templates'] as List<dynamic>,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearMergedCapabilities() {
    state = state.copyWith(mergedCapabilities: null);
  }

  void clearComparison() {
    state = state.copyWith(comparison: null);
  }
}

// Provider
final templateProvider = StateNotifierProvider<TemplateNotifier, TemplateState>((ref) {
  final api = ref.watch(templateApiProvider);
  return TemplateNotifier(api);
});
