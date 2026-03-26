import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/data/services/api_service.dart';

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
  final _organizationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _authMethod = AppConstants.authMethodEmail;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;

  // Username availability check
  Timer? _usernameDebounce;
  String? _usernameTakenError;   // non-null = taken
  bool _checkingUsername = false;

  void _onUsernameChanged(String value) {
    // Clear previous result immediately
    if (_usernameTakenError != null || _checkingUsername) {
      setState(() { _usernameTakenError = null; _checkingUsername = false; });
    }
    _usernameDebounce?.cancel();
    // Only check if the basic format is already valid (≥3 chars, no special chars)
    if (value.length < 3 || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) return;

    _usernameDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _checkingUsername = true);
      try {
        final api = ref.read(apiServiceProvider);
        final resp = await api.dio.get('/api/auth/check-username/$value');
        final available = resp.data['available'] as bool? ?? true;
        if (mounted) {
          setState(() {
            _checkingUsername = false;
            _usernameTakenError = available ? null : 'This username is already taken';
          });
        }
      } catch (_) {
        if (mounted) setState(() => _checkingUsername = false);
      }
    });
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _organizationController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_usernameTakenError != null) return;
    if (_checkingUsername) {
      _showSnackBar('Please wait — checking username availability',
          AppTheme.statusWarning, Icons.hourglass_top_rounded);
      return;
    }

    if (!_termsAccepted) {
      _showSnackBar('Please accept the terms and conditions',
          AppTheme.statusWarning, Icons.warning_amber_rounded);
      return;
    }

    final signupData = {
      'full_name': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _authMethod == AppConstants.authMethodEmail
          ? _emailController.text.trim()
          : null,
      'organization': _organizationController.text.trim(),
      'phone': '+91${_phoneController.text.trim()}',
      'password': _passwordController.text,
      'auth_method': _authMethod,
      'terms_accepted': _termsAccepted,
    };

    if (_authMethod == AppConstants.authMethodSecurityQuestions) {
      if (mounted) {
        final securityQuestions =
            await context.push<List<Map<String, dynamic>>>(
          '/security-questions',
          extra: signupData,
        );

        if (securityQuestions != null && securityQuestions.isNotEmpty) {
          signupData['security_questions'] = securityQuestions;
        } else {
          return;
        }
      }
    }

    final response = await ref.read(authProvider.notifier).signup(signupData);

    if (mounted) {
      if (response != null) {
        final message = response['message'] as String? ??
            AppConstants.successSignupEmail;
        _showSnackBar(message, AppTheme.statusActive, Icons.check_circle);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go(AppConstants.routeLogin);
        });
      } else {
        final error = ref.read(authProvider).error;
        _showSnackBar(error ?? AppConstants.errorUnknown,
            AppTheme.statusError, Icons.error_outline);
      }
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppTheme.primaryBlue),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.local_shipping,
                      color: AppTheme.primaryBlue, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'FleetPro',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable form
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Auth method toggle
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.bgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: const Color(0xFFE2E0E0)),
                        ),
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'email',
                              label: Text('Email'),
                              icon:
                                  Icon(Icons.email_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: 'security_questions',
                              label: Text('Security Q'),
                              icon: Icon(Icons.security, size: 16),
                            ),
                          ],
                          selected: {_authMethod},
                          onSelectionChanged: (s) =>
                              setState(() => _authMethod = s.first),
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: AppTheme.primaryBlue,
                            selectedForegroundColor: Colors.white,
                            foregroundColor: AppTheme.textSecondary,
                            side: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Full Name
                      _SignupFieldLabel(label: 'Full Name'),
                      const SizedBox(height: 8),
                      _SignupTextField(
                        controller: _fullNameController,
                        hintText: 'John Doe',
                        prefixIcon: Icons.person_outline,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          if (RegExp(r'[0-9]').hasMatch(v)) {
                            return 'Do not enter numbers in full name — letters only';
                          }
                          if (v.trim().length < 2) {
                            return 'Full name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Username
                      _SignupFieldLabel(label: 'Username'),
                      const SizedBox(height: 8),
                      _SignupTextField(
                        controller: _usernameController,
                        hintText: 'e.g. johndoe or john99',
                        prefixIcon: Icons.account_circle_outlined,
                        onChanged: _onUsernameChanged,
                        suffixIcon: _checkingUsername
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.textSecondary),
                                ),
                              )
                            : _usernameController.text.length >= 3 &&
                                    RegExp(r'^[a-zA-Z0-9_]+$')
                                        .hasMatch(_usernameController.text)
                                ? _usernameTakenError != null
                                    ? const Icon(Icons.cancel_rounded,
                                        color: AppTheme.statusError, size: 22)
                                    : const Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF006B5E), size: 22)
                                : null,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Username is required';
                          }
                          if (v.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                            return 'Username can only contain letters, numbers, and underscores';
                          }
                          return null;
                        },
                      ),
                      if (_usernameTakenError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel_rounded,
                                  color: AppTheme.statusError, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _usernameTakenError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.statusError,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Work Email (conditional)
                      if (_authMethod == AppConstants.authMethodEmail) ...[
                        _SignupFieldLabel(label: 'Work Email'),
                        const SizedBox(height: 8),
                        _SignupTextField(
                          controller: _emailController,
                          hintText: 'name@company.com',
                          prefixIcon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!v.contains('@')) {
                              return 'Email must contain "@" — e.g. name@company.com';
                            }
                            final parts = v.split('@');
                            if (parts.length != 2 || parts[1].isEmpty) {
                              return 'Enter a valid email — e.g. name@company.com';
                            }
                            if (!parts[1].contains('.')) {
                              return 'Email must have a domain ending — e.g. .com or .in';
                            }
                            final domainParts = parts[1].split('.');
                            if (domainParts.last.length < 2) {
                              return 'Enter a valid email — e.g. name@company.com';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Organization Name
                      _SignupFieldLabel(label: 'Organization Name'),
                      const SizedBox(height: 8),
                      _SignupTextField(
                        controller: _organizationController,
                        hintText: 'Acme Logistics Corp',
                        prefixIcon: Icons.corporate_fare_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Organization name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Phone Number
                      _SignupFieldLabel(label: 'Phone Number'),
                      const SizedBox(height: 8),
                      _SignupTextField(
                        controller: _phoneController,
                        hintText: '9876543210',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.number,
                        fixedPrefix: '+91 ',
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          if (v.trim().length < 10) {
                            return 'Mobile number must be exactly 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _SignupFieldLabel(label: 'Password'),
                      const SizedBox(height: 8),
                      _SignupTextField(
                        controller: _passwordController,
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      _SignupFieldLabel(label: 'Confirm Password'),
                      const SizedBox(height: 8),
                      _SignupTextField(
                        controller: _confirmPasswordController,
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (v != _passwordController.text) {
                            return 'Passwords do not match — please re-enter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Terms row
                      GestureDetector(
                        onTap: () => setState(
                            () => _termsAccepted = !_termsAccepted),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _termsAccepted,
                                onChanged: (v) => setState(
                                    () => _termsAccepted = v ?? false),
                                activeColor: AppTheme.primaryBlue,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                      height: 1.5),
                                  children: [
                                    const TextSpan(
                                        text:
                                            'By clicking Create Account, you agree to our '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: const TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Create Account button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed:
                              authState.isLoading ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor:
                                AppTheme.primaryBlue.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          icon: authState.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.arrow_forward_outlined,
                                  size: 20),
                          label: const Text('Create Account'),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Login link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => context.pop(),
                                  child: const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== WIDGETS ====================

class _SignupFieldLabel extends StatelessWidget {
  final String label;
  const _SignupFieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _SignupTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? fixedPrefix;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const _SignupTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.fixedPrefix,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            const TextStyle(fontSize: 14, color: AppTheme.textTertiary),
        prefixIcon: Icon(prefixIcon,
            color: AppTheme.textSecondary, size: 20),
        prefixText: fixedPrefix,
        prefixStyle: const TextStyle(
          fontSize: 15,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.statusError, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
