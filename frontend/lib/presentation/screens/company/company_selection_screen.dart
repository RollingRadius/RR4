import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Selection'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Company Association',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to proceed with your account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Option 1: Join Existing Company
              Expanded(
                child: _SelectionCard(
                  icon: Icons.business,
                  title: 'Join Existing Company',
                  description:
                      'Search and join an existing company. You will be added as a Pending User until approved by the company owner.',
                  color: Colors.blue,
                  onTap: () {
                    if (onSelectionComplete != null) {
                      onSelectionComplete!('existing');
                    }
                    context.push('/company/search', extra: signupData);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Option 2: Create New Company
              Expanded(
                child: _SelectionCard(
                  icon: Icons.add_business,
                  title: 'Create New Company',
                  description:
                      'Register your company and become the Owner. You will have full control over your company and can invite team members.',
                  color: Colors.green,
                  onTap: () {
                    if (onSelectionComplete != null) {
                      onSelectionComplete!('new');
                    }
                    context.push('/company/create', extra: signupData);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Option 3: Skip
              Expanded(
                child: _SelectionCard(
                  icon: Icons.person,
                  title: 'Skip for Now',
                  description:
                      'Continue as an Independent User without company affiliation. You can join or create a company later from your profile.',
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSkipCompany(BuildContext context, WidgetRef ref) {
    // Show confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Company Selection'),
        content: const Text(
          'You will be registered as an Independent User. You can join or create a company later from your profile settings.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Registration completed! You can now login as an Independent User.'),
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
            child: const Text('Continue'),
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
