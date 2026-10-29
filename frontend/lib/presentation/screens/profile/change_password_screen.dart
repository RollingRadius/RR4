import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/l10n/app_localizations.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/profile_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

/// Holds a single security question, as returned by the questions endpoint.
class _Question {
  final String questionId;
  final String questionText;
  const _Question({required this.questionId, required this.questionText});
}

/// In-profile password change, gated by re-verifying the user's own security
/// question answers (only available for accounts registered with security
/// questions — not email-authenticated accounts). On success, every existing
/// session everywhere is invalidated server-side, so this screen finishes by
/// logging out locally and landing on the login screen.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _answerControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  List<_Question> _questions = [];
  bool _isLoadingQuestions = true;
  bool _isSubmitting = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadQuestions);
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final l10n = AppLocalizations.of(context);
    final username = ref.read(authProvider).user?.username;
    if (username == null) {
      setState(() {
        _isLoadingQuestions = false;
        _loadError = l10n.changePwNoUsername;
      });
      return;
    }

    try {
      final authApi = ref.read(authApiProvider);
      final response = await authApi.getUserSecurityQuestionsForRecovery(username);
      final rawList = response['questions'] as List<dynamic>;

      if (mounted) {
        setState(() {
          _questions = rawList
              .map((q) => _Question(
                    questionId: q['question_id'] as String,
                    questionText: q['question_text'] as String,
                  ))
              .toList();
          _isLoadingQuestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuestions = false;
          _loadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final answers = <Map<String, String>>[
      for (var i = 0; i < _questions.length; i++)
        {'question_id': _questions[i].questionId, 'answer': _answerControllers[i].text.trim()},
    ];

    setState(() => _isSubmitting = true);

    final success = await ref.read(profileProvider.notifier).changePassword(
          answers: answers,
          newPassword: _newPasswordController.text,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.changePwSuccess),
          backgroundColor: AppTheme.successColor,
        ),
      );
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go(AppConstants.routeLogin);
    } else {
      setState(() => _isSubmitting = false);
      final error = ref.read(profileProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? l10n.changePwFailed),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePwTitle)),
      body: SafeArea(
        child: _isLoadingQuestions
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _buildErrorState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.changePwIntro,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 24),

                          for (var i = 0; i < _questions.length; i++) ...[
                            Text(l10n.authQuestionNumber(i + 1),
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 6),
                            Text(
                              _questions[i].questionText,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _answerControllers[i],
                              decoration: InputDecoration(
                                hintText: l10n.authEnterAnswer,
                                prefixIcon: Icon(Icons.edit),
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? l10n.authFieldRequired
                                      : null,
                            ),
                            const SizedBox(height: 16),
                          ],

                          const SizedBox(height: 8),
                          Text(l10n.authNewPassword,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNewPassword,
                            decoration: InputDecoration(
                              labelText: l10n.authNewPassword,
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureNewPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () => setState(
                                    () => _obscureNewPassword = !_obscureNewPassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.authFieldRequired;
                              }
                              if (value.length < 8) {
                                return l10n.authPasswordRule;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: l10n.changePwConfirmNew,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.authFieldRequired;
                              }
                              if (value != _newPasswordController.text) {
                                return l10n.authPasswordMismatch;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(l10n.changePwTitle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoadingQuestions = true;
                  _loadError = null;
                });
                _loadQuestions();
              },
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
