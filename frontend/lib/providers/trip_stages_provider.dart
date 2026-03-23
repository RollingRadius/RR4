import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/api_service.dart';
import 'package:fleet_management/providers/auth_provider.dart';

class TripStagesState {
  final bool isSubmitting;
  final String? error;
  final int currentStage; // 0-3

  const TripStagesState({
    this.isSubmitting = false,
    this.error,
    this.currentStage = 0,
  });

  TripStagesState copyWith({
    bool? isSubmitting,
    String? error,
    int? currentStage,
    bool clearError = false,
  }) =>
      TripStagesState(
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : (error ?? this.error),
        currentStage: currentStage ?? this.currentStage,
      );
}

class TripStagesNotifier extends StateNotifier<TripStagesState> {
  final ApiService _api;
  final String tripId;
  final int initialStage;

  TripStagesNotifier(this._api, this.tripId, this.initialStage)
      : super(TripStagesState(currentStage: initialStage));

  Future<bool> submitStage1(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _api.dio.post('/api/trips/$tripId/stage/1', data: data);
      state = state.copyWith(isSubmitting: false, currentStage: 1);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _api.handleError(e));
      return false;
    }
  }

  Future<bool> submitStage2(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _api.dio.post('/api/trips/$tripId/stage/2', data: data);
      state = state.copyWith(isSubmitting: false, currentStage: 2);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _api.handleError(e));
      return false;
    }
  }

  Future<bool> submitStage3(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _api.dio.post('/api/trips/$tripId/stage/3', data: data);
      state = state.copyWith(isSubmitting: false, currentStage: 3);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _api.handleError(e));
      return false;
    }
  }
}

// Family provider — keyed by (tripId, initialStage)
final tripStagesProvider = StateNotifierProvider.family<
    TripStagesNotifier, TripStagesState, (String, int)>((ref, args) {
  final api = ref.watch(apiServiceProvider);
  return TripStagesNotifier(api, args.$1, args.$2);
});
