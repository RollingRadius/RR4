import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/data/models/security_question_model.dart';
import 'package:fleet_management/providers/security_questions_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

class PasswordRecoveryScreen extends ConsumerStatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  ConsumerState<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState
    extends ConsumerState<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _recoveryMethod = 'email'; // 'email' or 'security_questions'
  bool _isLoading = false;
  bool _showPasswordReset = false;

  // For security questions
  final List<TextEditingController> _answerControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  List<SecurityQuestionModel> _userQuestions = [];

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleEmailRecovery() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement email recovery
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email!'),
          backgroundColor: Colors.green,
        ),
      );

      context.go(AppConstants.routeLogin);
    }
  }

  Future<void> _loadUserSecurityQuestions() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your username'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Load user's security questions from backend
    // For now, show all questions
    await ref.read(securityQuestionsProvider.notifier).loadQuestions();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _showPasswordReset = false;
      });

      final questions = ref.read(securityQuestionsProvider).questions;
      if (questions.isNotEmpty) {
        setState(() {
          // Take first 3 questions as user's questions (in production, this would come from backend)
          _userQuestions = questions.take(3).toList();
        });
      }
    }
  }

  Future<void> _handleSecurityQuestionsRecovery() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate answers
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
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _showPasswordReset = true;
      });
    }
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Reset password with backend
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successful! Please login with your new password.'),
          backgroundColor: Colors.green,
        ),
      );

      context.go(AppConstants.routeLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Recovery'),
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
                  Icons.lock_reset,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),

                Text(
                  'Forgot Your Password?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a recovery method to reset your password',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),

                // Recovery Method Selection
                Text(
                  'Recovery Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'email',
                      label: Text('Email'),
                      icon: Icon(Icons.email),
                    ),
                    ButtonSegment(
                      value: 'security_questions',
                      label: Text('Security Questions'),
                      icon: Icon(Icons.security),
                    ),
                  ],
                  selected: {_recoveryMethod},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _recoveryMethod = newSelection.first;
                      _showPasswordReset = false;
                      _userQuestions = [];
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.validationRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Email Recovery
                if (_recoveryMethod == 'email') ...[
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
                              'A password reset link will be sent to your registered email address.',
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
                      onPressed: _isLoading ? null : _handleEmailRecovery,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send Reset Link'),
                    ),
                  ),
                ],

                // Security Questions Recovery
                if (_recoveryMethod == 'security_questions') ...[
                  if (_userQuestions.isEmpty) ...[
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Enter your username and we\'ll show you your security questions.',
                                style: TextStyle(color: Colors.orange.shade900),
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
                        onPressed:
                            _isLoading ? null : _loadUserSecurityQuestions,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Load Security Questions'),
                      ),
                    ),
                  ] else if (!_showPasswordReset) ...[
                    Text(
                      'Answer Your Security Questions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    for (int i = 0; i < _userQuestions.length; i++) ...[
                      Text(
                        'Question ${i + 1}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userQuestions[i].questionText,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _answerControllers[i],
                        decoration: const InputDecoration(
                          hintText: 'Enter your answer',
                          prefixIcon: Icon(Icons.edit),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppConstants.validationRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _handleSecurityQuestionsRecovery,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Verify Answers'),
                      ),
                    ),
                  ] else ...[
                    // Password Reset Form
                    Text(
                      'Set New Password',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNewPassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppConstants.validationRequired;
                        }
                        if (value.length < 8) {
                          return AppConstants.validationPassword;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppConstants.validationRequired;
                        }
                        if (value != _newPasswordController.text) {
                          return AppConstants.validationPasswordMismatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handlePasswordReset,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Reset Password'),
                      ),
                    ),
                  ],
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
