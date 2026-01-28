import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _authMethod = AppConstants.authMethodEmail;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final signupData = {
      'full_name': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _authMethod == AppConstants.authMethodEmail
          ? _emailController.text.trim()
          : null,
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'auth_method': _authMethod,
      'terms_accepted': _termsAccepted,
    };

    // If security questions method, navigate to security questions screen first
    if (_authMethod == AppConstants.authMethodSecurityQuestions) {
      if (mounted) {
        // Navigate to security questions screen and wait for result
        final securityQuestions = await context.push<List<Map<String, dynamic>>>(
          '/security-questions',
          extra: signupData,
        );

        // If user completed security questions, add them to signup data
        if (securityQuestions != null && securityQuestions.isNotEmpty) {
          signupData['security_questions'] = securityQuestions;
        } else {
          // User cancelled, don't proceed
          return;
        }
      }
    }

    // Submit signup with complete data (either email or security questions)
    final response = await ref.read(authProvider.notifier).signup(signupData);

    if (mounted) {
      if (response != null) {
        final message = response['message'] as String? ??
            AppConstants.successSignupEmail;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to login
        context.go(AppConstants.routeLogin);
      } else {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? AppConstants.errorUnknown),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.signupTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Auth Method Selection
                Text(
                  'Choose Authentication Method',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
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
                  selected: {_authMethod},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _authMethod = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: AppConstants.fullNameLabel,
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

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: AppConstants.usernameLabel,
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.validationRequired;
                    }
                    if (value.length < 3) {
                      return AppConstants.validationUsername;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email (only for email method)
                if (_authMethod == AppConstants.authMethodEmail) ...[
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: AppConstants.emailLabel,
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (_authMethod == AppConstants.authMethodEmail) {
                        if (value == null || value.isEmpty) {
                          return AppConstants.validationRequired;
                        }
                        if (!value.contains('@')) {
                          return AppConstants.validationEmail;
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: AppConstants.phoneLabel,
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.validationRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: AppConstants.passwordLabel,
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
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

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: AppConstants.confirmPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.validationRequired;
                    }
                    if (value != _passwordController.text) {
                      return AppConstants.validationPasswordMismatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Terms and Conditions
                CheckboxListTile(
                  value: _termsAccepted,
                  onChanged: (value) {
                    setState(() {
                      _termsAccepted = value ?? false;
                    });
                  },
                  title: const Text('I accept the terms and conditions'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),

                // Signup Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleSignup,
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(AppConstants.signupButton),
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
