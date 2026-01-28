import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/models/security_question_model.dart';
import 'package:fleet_management/providers/security_questions_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

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

  @override
  void initState() {
    super.initState();
    // Load security questions when screen loads
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
      List<SecurityQuestionModel> allQuestions, int questionNumber) {
    return allQuestions.where((q) {
      if (questionNumber == 1) {
        return q != _selectedQuestion2 && q != _selectedQuestion3;
      } else if (questionNumber == 2) {
        return q != _selectedQuestion1 && q != _selectedQuestion3;
      } else {
        return q != _selectedQuestion1 && q != _selectedQuestion2;
      }
    }).toList();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedQuestion1 == null ||
        _selectedQuestion2 == null ||
        _selectedQuestion3 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all 3 security questions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for duplicate questions
    if (_selectedQuestion1 == _selectedQuestion2 ||
        _selectedQuestion1 == _selectedQuestion3 ||
        _selectedQuestion2 == _selectedQuestion3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select 3 different security questions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final securityQuestions = [
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
      widget.onQuestionsCompleted!(securityQuestions);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Security questions saved successfully'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(securityQuestions);
  }

  @override
  Widget build(BuildContext context) {
    final questionsState = ref.watch(securityQuestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Questions'),
      ),
      body: SafeArea(
        child: questionsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : questionsState.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          questionsState.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref
                                .read(securityQuestionsProvider.notifier)
                                .loadQuestions();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Instructions
                          Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Select 3 different security questions and provide answers. These will be used to recover your account if needed.',
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Question 1
                          Text(
                            'Security Question 1',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<SecurityQuestionModel>(
                            value: _selectedQuestion1,
                            decoration: const InputDecoration(
                              hintText: 'Select a question',
                              prefixIcon: Icon(Icons.help_outline),
                            ),
                            items: _getAvailableQuestions(
                                    questionsState.questions, 1)
                                .map((question) {
                              return DropdownMenuItem(
                                value: question,
                                child: Text(
                                  question.questionText,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedQuestion1 = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a question';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _answer1Controller,
                            decoration: const InputDecoration(
                              labelText: 'Answer',
                              hintText: 'Enter your answer',
                              prefixIcon: Icon(Icons.edit),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppConstants.validationRequired;
                              }
                              if (value.length < 2) {
                                return 'Answer must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Question 2
                          Text(
                            'Security Question 2',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<SecurityQuestionModel>(
                            value: _selectedQuestion2,
                            decoration: const InputDecoration(
                              hintText: 'Select a question',
                              prefixIcon: Icon(Icons.help_outline),
                            ),
                            items: _getAvailableQuestions(
                                    questionsState.questions, 2)
                                .map((question) {
                              return DropdownMenuItem(
                                value: question,
                                child: Text(
                                  question.questionText,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedQuestion2 = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a question';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _answer2Controller,
                            decoration: const InputDecoration(
                              labelText: 'Answer',
                              hintText: 'Enter your answer',
                              prefixIcon: Icon(Icons.edit),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppConstants.validationRequired;
                              }
                              if (value.length < 2) {
                                return 'Answer must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Question 3
                          Text(
                            'Security Question 3',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<SecurityQuestionModel>(
                            value: _selectedQuestion3,
                            decoration: const InputDecoration(
                              hintText: 'Select a question',
                              prefixIcon: Icon(Icons.help_outline),
                            ),
                            items: _getAvailableQuestions(
                                    questionsState.questions, 3)
                                .map((question) {
                              return DropdownMenuItem(
                                value: question,
                                child: Text(
                                  question.questionText,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedQuestion3 = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a question';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _answer3Controller,
                            decoration: const InputDecoration(
                              labelText: 'Answer',
                              hintText: 'Enter your answer',
                              prefixIcon: Icon(Icons.edit),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppConstants.validationRequired;
                              }
                              if (value.length < 2) {
                                return 'Answer must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _handleSubmit,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.0),
                                child: Text('Continue'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
