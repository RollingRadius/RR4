import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/auth_provider.dart';

class TripStagesState {
  final bool isSubmitting;
  final String? error;
  final int currentStage; // 0-3
  final String? emptyWeightKg;
  final String? loadedWeightKg;

  const TripStagesState({
    this.isSubmitting = false,
    this.error,
    this.currentStage = 0,
    this.emptyWeightKg,
    this.loadedWeightKg,
  });

  TripStagesState copyWith({
    bool? isSubmitting,
    String? error,
    int? currentStage,
    String? emptyWeightKg,
    String? loadedWeightKg,
    bool clearError = false,
  }) =>
      TripStagesState(
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : (error ?? this.error),
        currentStage: currentStage ?? this.currentStage,
        emptyWeightKg: emptyWeightKg ?? this.emptyWeightKg,
        loadedWeightKg: loadedWeightKg ?? this.loadedWeightKg,
      );
}

class TripStagesNotifier extends StateNotifier<TripStagesState> {
  final String tripId;
  final int initialStage;
  final Ref _ref;

  TripStagesNotifier(this.tripId, this.initialStage, this._ref)
      : super(TripStagesState(currentStage: initialStage));

  Future<bool> submitStage1(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final api = _ref.read(apiServiceProvider);
      await api.dio.post('/api/trips/$tripId/stage/1', data: data);
      state = state.copyWith(isSubmitting: false, currentStage: 1);
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] as String? ??
          'Stage 1 submission failed';
      state = state.copyWith(isSubmitting: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> submitStage2(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final api = _ref.read(apiServiceProvider);
      await api.dio.post('/api/trips/$tripId/stage/2', data: data);
      state = state.copyWith(isSubmitting: false, currentStage: 2);
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] as String? ??
          'Stage 2 submission failed';
      state = state.copyWith(isSubmitting: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> submitStage3(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final api = _ref.read(apiServiceProvider);
      await api.dio.post('/api/trips/$tripId/stage/3', data: data);
      state = state.copyWith(
        isSubmitting: false,
        currentStage: 3,
        emptyWeightKg: data['empty_truck_weight_kg'] as String?,
        loadedWeightKg: data['loaded_truck_weight_kg'] as String?,
      );
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] as String? ??
          'Stage 3 submission failed';
      state = state.copyWith(isSubmitting: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

// Family provider — keyed by (tripId, initialStage)
final tripStagesProvider = StateNotifierProvider.family<
    TripStagesNotifier, TripStagesState, (String, int)>((ref, args) {
  return TripStagesNotifier(args.$1, args.$2, ref);
});
