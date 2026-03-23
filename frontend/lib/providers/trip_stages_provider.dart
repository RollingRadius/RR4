import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final String tripId;
  final int initialStage;

  TripStagesNotifier(this.tripId, this.initialStage)
      : super(TripStagesState(currentStage: initialStage));

  Future<bool> submitStage1(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(isSubmitting: false, currentStage: 1);
    return true;
  }

  Future<bool> submitStage2(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(isSubmitting: false, currentStage: 2);
    return true;
  }

  Future<bool> submitStage3(Map<String, dynamic> data) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(isSubmitting: false, currentStage: 3);
    return true;
  }
}

// Family provider — keyed by (tripId, initialStage)
final tripStagesProvider = StateNotifierProvider.family<
    TripStagesNotifier, TripStagesState, (String, int)>((ref, args) {
  return TripStagesNotifier(args.$1, args.$2);
});
