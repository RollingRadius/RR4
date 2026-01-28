import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/services/auth_api.dart';
import 'package:fleet_management/data/models/security_question_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Security Questions State
class SecurityQuestionsState {
  final List<SecurityQuestionModel> questions;
  final bool isLoading;
  final String? error;

  SecurityQuestionsState({
    this.questions = const [],
    this.isLoading = false,
    this.error,
  });

  SecurityQuestionsState copyWith({
    List<SecurityQuestionModel>? questions,
    bool? isLoading,
    String? error,
  }) {
    return SecurityQuestionsState(
      questions: questions ?? this.questions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Security Questions Notifier
class SecurityQuestionsNotifier extends StateNotifier<SecurityQuestionsState> {
  final AuthApi _authApi;

  SecurityQuestionsNotifier(this._authApi) : super(SecurityQuestionsState());

  /// Load security questions from API
  Future<void> loadQuestions() async {
    if (state.questions.isNotEmpty && !state.isLoading) {
      // Questions already loaded
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authApi.getSecurityQuestions();

      final questions = (response['questions'] as List)
          .map((q) => SecurityQuestionModel.fromJson(q))
          .toList();

      state = state.copyWith(
        questions: questions,
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
}

/// Security Questions Provider
final securityQuestionsProvider =
    StateNotifierProvider<SecurityQuestionsNotifier, SecurityQuestionsState>(
        (ref) {
  final authApi = ref.watch(authApiProvider);
  return SecurityQuestionsNotifier(authApi);
});
