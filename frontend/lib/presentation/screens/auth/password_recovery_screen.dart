import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

/// Holds a single question returned by the recovery API.
class _RecoveryQuestion {
  final String questionId; // UUID from the backend
  final String questionText;
  const _RecoveryQuestion(
      {required this.questionId, required this.questionText});
}

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

  String _recoveryMethod = 'security_questions'; // default to working method
  bool _isLoading = false;
  bool _showPasswordReset = false;

  // For security questions
  final List<TextEditingController> _answerControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  List<_RecoveryQuestion> _userQuestions = [];
  String? _resetToken;

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

  Future<void> _loadUserSecurityQuestions() async {
    if (_usernameController.text.trim().isEmpty) {
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
      _userQuestions = [];
      _showPasswordReset = false;
      _resetToken = null;
      for (var c in _answerControllers) {
        c.clear();
      }
    });

    try {
      final authApi = ref.read(authApiProvider);
      final response = await authApi.getUserSecurityQuestionsForRecovery(
          _usernameController.text.trim());

      final rawList = response['questions'] as List<dynamic>;
      final questions = rawList
          .map((q) => _RecoveryQuestion(
                questionId: q['question_id'] as String,
                questionText: q['question_text'] as String,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _userQuestions = questions;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSecurityQuestionsRecovery() async {
    if (!_formKey.currentState!.validate()) return;

    // Build answers list matching the loaded questions order
    final answers = <Map<String, String>>[];
    for (int i = 0; i < _userQuestions.length; i++) {
      final text = _answerControllers[i].text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer all security questions'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      answers.add({
        'question_id': _userQuestions[i].questionId,
        'answer': text,
      });
    }

    setState(() => _isLoading = true);

    try {
      final authApi = ref.read(authApiProvider);
      final response = await authApi.verifySecurityAnswers(
        username: _usernameController.text.trim(),
        answers: answers,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _resetToken = response['reset_token'] as String?;
          _showPasswordReset = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;
    if (_resetToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please start over.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authApi = ref.read(authApiProvider);
      await authApi.resetPasswordWithToken(
        resetToken: _resetToken!,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Password reset successful! Please login with your new password.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go(AppConstants.routeLogin);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                ScaleFade(
                  delay: 0,
                  duration: 600,
                  child: Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                FadeSlide(
                  delay: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forgot Your Password?',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reset your password using your security questions',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Recovery Method Selection
                FadeSlide(
                  delay: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),  // closes FadeSlide for Recovery Method
                const SizedBox(height: 32),

                // Username
                FadeSlide(
                  delay: 350,
                  child: TextFormField(
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
                )),  // closes FadeSlide for Username
                const SizedBox(height: 24),

                // Email Recovery — Coming Soon
                if (_recoveryMethod == 'email') ...[
                  FadeSlide(
                    delay: 450,
                    child: Card(
                      color: Colors.amber.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.amber.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(Icons.construction_rounded,
                                size: 48, color: Colors.amber.shade700),
                            const SizedBox(height: 12),
                            Text(
                              'Coming Soon',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Email-based password recovery is under development. '
                              'Please use Security Questions to reset your password for now.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.amber.shade800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlide(
                    delay: 550,
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(
                            () => _recoveryMethod = 'security_questions'),
                        icon: const Icon(Icons.security),
                        label: const Text('Use Security Questions Instead'),
                      ),
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
                        controller: i < _answerControllers.length
                            ? _answerControllers[i]
                            : TextEditingController(),
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
                FadeSlide(
                  delay: 500,
                  child: Center(
                    child: TextButton(
                      onPressed: () => context.go(AppConstants.routeLogin),
                      child: const Text('Back to Login'),
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
