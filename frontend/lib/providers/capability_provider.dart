import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/capability_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// API Provider
final capabilityApiProvider = Provider<CapabilityApi>((ref) {
  final dio = ref.watch(dioProvider);
  return CapabilityApi(dio);
});

// State class
class CapabilityState {
  final bool isLoading;
  final String? error;
  final List<dynamic> capabilities;
  final List<dynamic> categories;
  final Map<String, dynamic>? myCapabilities;

  CapabilityState({
    this.isLoading = false,
    this.error,
    this.capabilities = const [],
    this.categories = const [],
    this.myCapabilities,
  });

  CapabilityState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? capabilities,
    List<dynamic>? categories,
    Map<String, dynamic>? myCapabilities,
  }) {
    return CapabilityState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      capabilities: capabilities ?? this.capabilities,
      categories: categories ?? this.categories,
      myCapabilities: myCapabilities ?? this.myCapabilities,
    );
  }
}

// State Notifier
class CapabilityNotifier extends StateNotifier<CapabilityState> {
  final CapabilityApi _api;

  CapabilityNotifier(this._api) : super(CapabilityState());

  Future<void> loadAllCapabilities() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getAllCapabilities();
      state = state.copyWith(
        isLoading: false,
        capabilities: response['capabilities'] as List<dynamic>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadCategories() async {
    try {
      final response = await _api.getCategories();
      state = state.copyWith(
        categories: response['categories'] as List<dynamic>,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<List<dynamic>> getCapabilitiesByCategory(String category) async {
    try {
      final response = await _api.getCapabilitiesByCategory(category);
      return response['capabilities'] as List<dynamic>;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<List<dynamic>> searchCapabilities(String keyword) async {
    try {
      final response = await _api.searchCapabilities(keyword);
      return response['capabilities'] as List<dynamic>;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<void> loadMyCapabilities() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getMyCapabilities();
      state = state.copyWith(
        isLoading: false,
        myCapabilities: response['capabilities'] as Map<String, dynamic>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  bool hasCapability(String capabilityKey, {String requiredLevel = 'view'}) {
    if (state.myCapabilities == null) return false;

    final capability = state.myCapabilities![capabilityKey];
    if (capability == null) return false;

    final accessLevel = capability['access_level'] as String;

    // Access level hierarchy: none < view < limited < full
    const levelHierarchy = {
      'none': 0,
      'view': 1,
      'limited': 2,
      'full': 3,
    };

    return (levelHierarchy[accessLevel] ?? 0) >= (levelHierarchy[requiredLevel] ?? 0);
  }
}

// Provider
final capabilityProvider = StateNotifierProvider<CapabilityNotifier, CapabilityState>((ref) {
  final api = ref.watch(capabilityApiProvider);
  return CapabilityNotifier(api);
});
