import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/animations/app_animations.dart';
import 'package:fleet_management/l10n/app_localizations.dart';

class CompanySelectionScreen extends ConsumerWidget {
  final Map<String, dynamic>? signupData;
  final Function(String selectionType, {dynamic data})? onSelectionComplete;

  const CompanySelectionScreen({
    super.key,
    this.signupData,
    this.onSelectionComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companySelectTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              FadeSlide(
                delay: 0,
                child: Column(
                  children: [
                    Text(
                      l10n.companySelectHeading,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.companySelectSubheading,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Option 1: Join Existing Company
              Expanded(
                child: FadeSlide(
                  delay: 100,
                  child: _SelectionCard(
                    icon: Icons.business,
                    title: l10n.companySelectJoinTitle,
                    description: l10n.companySelectJoinDesc,
                    color: Colors.blue,
                    onTap: () {
                      if (onSelectionComplete != null) {
                        onSelectionComplete!('existing');
                      }
                      context.push('/company/search', extra: signupData);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Option 2: Create New Company
              Expanded(
                child: FadeSlide(
                  delay: 200,
                  child: _SelectionCard(
                    icon: Icons.add_business,
                    title: l10n.companySelectCreateTitle,
                    description: l10n.companySelectCreateDesc,
                    color: Colors.green,
                    onTap: () {
                      if (onSelectionComplete != null) {
                        onSelectionComplete!('new');
                      }
                      context.push('/company/create', extra: signupData);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Option 3: Skip
              Expanded(
                child: FadeSlide(
                  delay: 300,
                  child: _SelectionCard(
                    icon: Icons.person,
                    title: l10n.companySelectSkipTitle,
                    description: l10n.companySelectSkipDesc,
                    color: Colors.grey,
                    onTap: () {
                      if (onSelectionComplete != null) {
                        onSelectionComplete!('skip');
                      }

                      // Complete signup without company
                      _handleSkipCompany(context, ref);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSkipCompany(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Show confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.companySelectSkipDialogTitle),
        content: Text(l10n.companySelectSkipDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.companySelectSkipDone),
                  backgroundColor: Colors.green,
                ),
              );

              // Navigate to login or email verification based on auth method
              if (signupData != null &&
                  signupData!['auth_method'] == AppConstants.authMethodEmail) {
                context.go('/verify-email',
                    extra: {'email': signupData!['email']});
              } else {
                context.go(AppConstants.routeLogin);
              }
            },
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Arrow icon
              Icon(
                Icons.arrow_forward,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
