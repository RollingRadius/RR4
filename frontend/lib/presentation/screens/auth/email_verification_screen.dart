import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/animations/app_animations.dart';
import 'package:fleet_management/l10n/app_localizations.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String? email;

  const EmailVerificationScreen({super.key, this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _handleVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final success = await ref
          .read(authProvider.notifier)
          .verifyEmail(_tokenController.text.trim());

      if (mounted) {
        setState(() {
          _isVerifying = false;
        });

        final l10n = AppLocalizations.of(context);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.emailVerifyVerified),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to login
          context.go(AppConstants.routeLogin);
        } else {
          final error = ref.read(authProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? l10n.emailVerifyFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).emailVerifyError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.authVerifyEmail),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Email icon
                ScaleFade(
                  delay: 0,
                  duration: 600,
                  child: Icon(
                    Icons.mark_email_read,
                    size: 100,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 32),

                // Title + Instructions
                FadeSlide(
                  delay: 150,
                  child: Column(
                    children: [
                      Text(
                        l10n.emailVerifyHeading,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (widget.email != null) ...[
                        Text(
                          l10n.emailVerifySentTo,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.email!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        l10n.emailVerifyEnterCode,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Verification form
                FadeSlide(
                  delay: 300,
                  child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Token input
                          TextFormField(
                            controller: _tokenController,
                            decoration: InputDecoration(
                              labelText: l10n.emailVerifyCodeLabel,
                              hintText: l10n.emailVerifyCodeHint,
                              prefixIcon: const Icon(Icons.vpn_key),
                            ),
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.authFieldRequired;
                              }
                              if (value.length < 6) {
                                return l10n.emailVerifyCodeTooShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Verify button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isVerifying ? null : _handleVerification,
                              child: _isVerifying
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
                                  : Text(l10n.authVerifyEmail),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ),  // closes FadeSlide for Card
                const SizedBox(height: 24),

                // Resend + Back to login
                FadeSlide(
                  delay: 400,
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          // TODO: Implement resend verification email
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.emailVerifyResent),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: Text(l10n.emailVerifyResend),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go(AppConstants.routeLogin);
                        },
                        child: Text(l10n.authBackToLogin),
                      ),
                    ],
                  ),
                ),  // closes FadeSlide for buttons
              ],
            ),
          ),
        ),
      ),
    );
  }
}
