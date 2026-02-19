import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/models/security_question_model.dart';
import 'package:fleet_management/providers/security_questions_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

class SecurityQuestionsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? signupData;
  final Function(List<Map<String, dynamic>>)? onQuestionsCompleted;

  const SecurityQuestionsScreen({
    super.key,
    this.signupData,
    this.onQuestionsCompleted,
  });

  @override
  ConsumerState<SecurityQuestionsScreen> createState() =>
      _SecurityQuestionsScreenState();
}

class _SecurityQuestionsScreenState
    extends ConsumerState<SecurityQuestionsScreen> {
  final _formKey = GlobalKey<FormState>();

  SecurityQuestionModel? _selectedQuestion1;
  SecurityQuestionModel? _selectedQuestion2;
  SecurityQuestionModel? _selectedQuestion3;

  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();
  final _answer3Controller = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _obscure3 = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(securityQuestionsProvider.notifier).loadQuestions(),
    );
  }

  @override
  void dispose() {
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    _answer3Controller.dispose();
    super.dispose();
  }

  List<SecurityQuestionModel> _getAvailableQuestions(
      List<SecurityQuestionModel> all, int num) {
    return all.where((q) {
      if (num == 1) return q != _selectedQuestion2 && q != _selectedQuestion3;
      if (num == 2) return q != _selectedQuestion1 && q != _selectedQuestion3;
      return q != _selectedQuestion1 && q != _selectedQuestion2;
    }).toList();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedQuestion1 == null ||
        _selectedQuestion2 == null ||
        _selectedQuestion3 == null) {
      _showSnackBar('Please select all 3 security questions', Colors.red);
      return;
    }

    if (_selectedQuestion1 == _selectedQuestion2 ||
        _selectedQuestion1 == _selectedQuestion3 ||
        _selectedQuestion2 == _selectedQuestion3) {
      _showSnackBar('Please select 3 different security questions', Colors.red);
      return;
    }

    final questions = [
      {
        'question_id': _selectedQuestion1!.questionKey,
        'question_text': _selectedQuestion1!.questionText,
        'answer': _answer1Controller.text.trim(),
      },
      {
        'question_id': _selectedQuestion2!.questionKey,
        'question_text': _selectedQuestion2!.questionText,
        'answer': _answer2Controller.text.trim(),
      },
      {
        'question_id': _selectedQuestion3!.questionKey,
        'question_text': _selectedQuestion3!.questionText,
        'answer': _answer3Controller.text.trim(),
      },
    ];

    if (widget.onQuestionsCompleted != null) {
      widget.onQuestionsCompleted!(questions);
    }

    _showSnackBar('Security questions saved!', AppTheme.statusActive);
    Navigator.of(context).pop(questions);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsState = ref.watch(securityQuestionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky header
            _StepHeader(
              step: 3,
              onBack: () => Navigator.of(context).pop(),
            ),

            // Content
            Expanded(
              child: questionsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryBlue))
                  : questionsState.error != null
                      ? _ErrorView(
                          error: questionsState.error!,
                          onRetry: () => ref
                              .read(securityQuestionsProvider.notifier)
                              .loadQuestions(),
                        )
                      : SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(24, 24, 24, 120),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Secure Your Account',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Choose three security questions to verify your identity if you lose access to your account.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                _QuestionBlock(
                                  number: 1,
                                  questions: _getAvailableQuestions(
                                      questionsState.questions, 1),
                                  selected: _selectedQuestion1,
                                  onChanged: (q) =>
                                      setState(() => _selectedQuestion1 = q),
                                  answerController: _answer1Controller,
                                  obscure: _obscure1,
                                  onToggleObscure: () =>
                                      setState(() => _obscure1 = !_obscure1),
                                ),
                                const SizedBox(height: 28),

                                _QuestionBlock(
                                  number: 2,
                                  questions: _getAvailableQuestions(
                                      questionsState.questions, 2),
                                  selected: _selectedQuestion2,
                                  onChanged: (q) =>
                                      setState(() => _selectedQuestion2 = q),
                                  answerController: _answer2Controller,
                                  obscure: _obscure2,
                                  onToggleObscure: () =>
                                      setState(() => _obscure2 = !_obscure2),
                                ),
                                const SizedBox(height: 28),

                                _QuestionBlock(
                                  number: 3,
                                  questions: _getAvailableQuestions(
                                      questionsState.questions, 3),
                                  selected: _selectedQuestion3,
                                  onChanged: (q) =>
                                      setState(() => _selectedQuestion3 = q),
                                  answerController: _answer3Controller,
                                  obscure: _obscure3,
                                  onToggleObscure: () =>
                                      setState(() => _obscure3 = !_obscure3),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: questionsState.isLoading || questionsState.error != null
          ? null
          : _StepFooter(
              onNext: _handleSubmit,
              onBack: () => Navigator.of(context).pop(),
            ),
    );
  }
}

// ==================== STEP HEADER ====================
class _StepHeader extends StatelessWidget {
  final int step;
  final VoidCallback onBack;

  const _StepHeader({required this.step, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgPrimary,
        border: Border(
          bottom: BorderSide(
              color: AppTheme.primaryBlue.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppTheme.textPrimary),
                  onPressed: onBack,
                ),
                Expanded(
                  child: Text(
                    'Step $step of 4',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Progress dots
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final active = i < step;
                final current = i == step - 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? current
                              ? AppTheme.primaryBlue
                              : AppTheme.primaryBlue.withOpacity(0.4)
                          : const Color(0xFFE2E0E0),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: current
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withOpacity(0.4),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== QUESTION BLOCK ====================
class _QuestionBlock extends StatelessWidget {
  final int number;
  final List<SecurityQuestionModel> questions;
  final SecurityQuestionModel? selected;
  final ValueChanged<SecurityQuestionModel?> onChanged;
  final TextEditingController answerController;
  final bool obscure;
  final VoidCallback onToggleObscure;

  const _QuestionBlock({
    required this.number,
    required this.questions,
    required this.selected,
    required this.onChanged,
    required this.answerController,
    required this.obscure,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number badge + label
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Question $number',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Question dropdown
        DropdownButtonFormField<SecurityQuestionModel>(
          value: selected,
          isExpanded: true,
          hint: const Text(
            'Select a security question',
            style: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
          ),
          icon: const Icon(Icons.expand_more,
              size: 20, color: AppTheme.textSecondary),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: AppTheme.bgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.statusError, width: 1.5),
            ),
          ),
          style: const TextStyle(
              fontSize: 14, color: AppTheme.textPrimary),
          items: questions
              .map((q) => DropdownMenuItem(
                    value: q,
                    child: Text(
                      q.questionText,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: (v) =>
              v == null ? 'Please select a question' : null,
        ),
        const SizedBox(height: 10),

        // Answer field
        TextFormField(
          controller: answerController,
          obscureText: obscure,
          style: const TextStyle(
              fontSize: 14, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Your answer',
            hintStyle: const TextStyle(
                fontSize: 14, color: AppTheme.textTertiary),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: AppTheme.bgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.statusError, width: 1.5),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return AppConstants.validationRequired;
            if (v.length < 2) return 'Answer must be at least 2 characters';
            return null;
          },
        ),
      ],
    );
  }
}

// ==================== STEP FOOTER ====================
class _StepFooter extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _StepFooter({required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppTheme.bgPrimary,
        border: Border(
          top: BorderSide(
              color: AppTheme.primaryBlue.withOpacity(0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text('Next'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: onBack,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: const Text('Go Back'),
            ),
          ),
          const SizedBox(height: 4),
          // Security badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock_outline,
                  size: 12, color: AppTheme.textTertiary),
              SizedBox(width: 4),
              Text(
                'END-TO-END ENCRYPTED',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== ERROR VIEW ====================
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.statusError, size: 56),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
