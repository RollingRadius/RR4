import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/data/models/trip_model.dart';

class TripStagesState {
  final bool isSubmitting;
  final String? error;
  final int currentStage; // 0-3
  final String? emptyWeightKg;
  final String? emptyWeightUnit;
  final String? loadedWeightKg;
  final String? loadedWeightUnit;
  // Stage 2 Dharam Kanta — shared with Stage 3
  final String? s2DharamKantaLoc;   // 'inside' | 'outside'
  final String? s2EmptyWeight;      // confirmed empty weight from Stage 2
  final String? s2EmptyWeightUnit;  // 'tons' | 'kg'

  const TripStagesState({
    this.isSubmitting = false,
    this.error,
    this.currentStage = 0,
    this.emptyWeightKg,
    this.emptyWeightUnit,
    this.loadedWeightKg,
    this.loadedWeightUnit,
    this.s2DharamKantaLoc,
    this.s2EmptyWeight,
    this.s2EmptyWeightUnit,
  });

  TripStagesState copyWith({
    bool? isSubmitting,
    String? error,
    int? currentStage,
    String? emptyWeightKg,
    String? emptyWeightUnit,
    String? loadedWeightKg,
    String? loadedWeightUnit,
    String? s2DharamKantaLoc,
    String? s2EmptyWeight,
    String? s2EmptyWeightUnit,
    bool clearError = false,
  }) =>
      TripStagesState(
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : (error ?? this.error),
        currentStage: currentStage ?? this.currentStage,
        emptyWeightKg: emptyWeightKg ?? this.emptyWeightKg,
        emptyWeightUnit: emptyWeightUnit ?? this.emptyWeightUnit,
        loadedWeightKg: loadedWeightKg ?? this.loadedWeightKg,
        loadedWeightUnit: loadedWeightUnit ?? this.loadedWeightUnit,
        s2DharamKantaLoc: s2DharamKantaLoc ?? this.s2DharamKantaLoc,
        s2EmptyWeight: s2EmptyWeight ?? this.s2EmptyWeight,
        s2EmptyWeightUnit: s2EmptyWeightUnit ?? this.s2EmptyWeightUnit,
      );
}

class TripStagesNotifier extends StateNotifier<TripStagesState> {
  final String tripId;
  final int initialStage;
  final Ref _ref;

  TripStagesNotifier(this.tripId, this.initialStage, this._ref)
      : super(TripStagesState(currentStage: initialStage));

  /// Parse trip from a stage response and push it into the trips list.
  void _patchTripFromResponse(dynamic respData) {
    try {
      final tripJson =
          (respData as Map<String, dynamic>)['trip'] as Map<String, dynamic>?;
      if (tripJson != null) {
        _ref.read(tripProvider.notifier).patchTrip(TripModel.fromJson(tripJson));
      }
    } catch (_) {}
  }

  /// Called when the user confirms empty weight via the "Enter" button in Stage 2.
  void setS2DharamKanta(String loc, String weight, String unit) {
    state = state.copyWith(s2DharamKantaLoc: loc, s2EmptyWeight: weight, s2EmptyWeightUnit: unit);
  }

  Future<bool> submitStage1(FormData formData) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final api = _ref.read(apiServiceProvider);
      final resp = await api.dio.post('/api/trips/$tripId/stage/1', data: formData);
      _patchTripFromResponse(resp.data);
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

  Future<bool> submitStage2(FormData formData) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final api = _ref.read(apiServiceProvider);
      final resp = await api.dio.post('/api/trips/$tripId/stage/2', data: formData);
      _patchTripFromResponse(resp.data);
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

  Future<bool> submitStage3(FormData formData) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final api = _ref.read(apiServiceProvider);
      final resp =
          await api.dio.post('/api/trips/$tripId/stage/3', data: formData);
      _patchTripFromResponse(resp.data);
      String? _field(String key) {
        final entry = formData.fields.where((f) => f.key == key).firstOrNull;
        return entry?.value;
      }
      state = state.copyWith(
        isSubmitting: false,
        currentStage: 3,
        emptyWeightKg: _field('empty_truck_weight_kg'),
        emptyWeightUnit: _field('empty_truck_weight_unit') ?? 'tons',
        loadedWeightKg: _field('loaded_truck_weight_kg'),
        loadedWeightUnit: _field('loaded_truck_weight_unit') ?? 'tons',
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
