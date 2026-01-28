import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/data/models/security_question_model.dart';
import 'package:fleet_management/providers/security_questions_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

class UsernameRecoveryScreen extends ConsumerStatefulWidget {
  const UsernameRecoveryScreen({super.key});

  @override
  ConsumerState<UsernameRecoveryScreen> createState() =>
      _UsernameRecoveryScreenState();
}

class _UsernameRecoveryScreenState
    extends ConsumerState<UsernameRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<TextEditingController> _answerControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  bool _isLoading = false;
  bool _showQuestions = false;
  bool _showUsername = false;
  String? _recoveredUsername;

  List<SecurityQuestionModel> _availableQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadSecurityQuestions();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSecurityQuestions() async {
    await ref.read(securityQuestionsProvider.notifier).loadQuestions();

    if (mounted) {
      final questions = ref.read(securityQuestionsProvider).questions;
      setState(() {
        _availableQuestions = questions;
      });
    }
  }

  Future<void> _handleInitialSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Verify full name and phone with backend
    // Backend should return user's security questions
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _showQuestions = true;
      });
    }
  }

  Future<void> _handleSecurityQuestionsSubmit() async {
    // Validate all answers are filled
    for (var controller in _answerControllers) {
      if (controller.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer all security questions'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Verify security answers with backend
    // Backend should return the username if answers match
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _showUsername = true;
        _recoveredUsername = 'john_doe_123'; // This would come from backend
      });
    }
  }

  void _handleContinueToLogin() {
    context.go(AppConstants.routeLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Username Recovery'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Icon(
                  Icons.person_search,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),

                Text(
                  'Forgot Your Username?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ll help you recover your username by verifying your identity',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),

                if (!_showQuestions && !_showUsername) ...[
                  // Step 1: Full Name and Phone
                  Text(
                    'Enter Your Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your registered full name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppConstants.validationRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your registered phone number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppConstants.validationRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You will need to answer your security questions to verify your identity.',
                              style: TextStyle(color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleInitialSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    ),
                  ),
                ],

                if (_showQuestions && !_showUsername) ...[
                  // Step 2: Security Questions
                  Text(
                    'Answer Your Security Questions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please answer the following questions to verify your identity',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Display 3 security questions (in production, these would be the user's questions)
                  for (int i = 0;
                      i < 3 && i < _availableQuestions.length;
                      i++) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _availableQuestions[i].questionText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _answerControllers[i],
                            decoration: const InputDecoration(
                              hintText: 'Enter your answer',
                              prefixIcon: Icon(Icons.edit),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppConstants.validationRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading ? null : _handleSecurityQuestionsSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verify & Recover Username'),
                    ),
                  ),
                ],

                if (_showUsername) ...[
                  // Step 3: Display Username
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade50,
                          Colors.green.shade100,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 80,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Username Recovered!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your username is:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SelectableText(
                            _recoveredUsername ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please save this username for future reference',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleContinueToLogin,
                      child: const Text('Continue to Login'),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Back to login
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppConstants.routeLogin),
                    child: const Text('Back to Login'),
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
