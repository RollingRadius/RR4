import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/organization_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class OrganizationSelectorScreen extends ConsumerStatefulWidget {
  const OrganizationSelectorScreen({super.key});

  @override
  ConsumerState<OrganizationSelectorScreen> createState() => _OrganizationSelectorScreenState();
}

class _OrganizationSelectorScreenState extends ConsumerState<OrganizationSelectorScreen> {
  @override
  void initState() {
    super.initState();
    // Load organizations when screen opens (only if authenticated)
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated && authState.token != null) {
        ref.read(organizationProvider.notifier).loadOrganizations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orgState = ref.watch(organizationProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Organization'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            tooltip: 'Create Organization',
            onPressed: () => context.push('/organizations/create'),
          ),
        ],
      ),
      body: orgState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orgState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading organizations',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(orgState.error ?? 'Unknown error'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(organizationProvider.notifier).loadOrganizations();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : orgState.organizations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No Organizations Found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text('You are not associated with any organization yet.'),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/organizations/create'),
                            icon: const Icon(Icons.add_business),
                            label: const Text('Create Your Organization'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        if (authState.user != null) ...[
                          FadeSlide(
                            delay: 0,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          child: Icon(Icons.person),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                authState.user!.fullName,
                                                style: Theme.of(context).textTheme.titleMedium,
                                              ),
                                              Text(
                                                authState.user!.username,
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        FadeSlide(
                          delay: 100,
                          child: Text(
                            'Your Organizations',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...orgState.activeOrganizations.asMap().entries.map((entry) {
                          final index = entry.key;
                          final org = entry.value;
                          final isSelected = org['organization_id'] == orgState.currentOrganizationId;
                          final isPending = org['status'] != 'active';

                          return StaggeredItem(
                            index: index,
                            staggerMs: 80,
                            child: Card(
                            elevation: isSelected ? 4 : 1,
                            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPending ? Colors.orange : Theme.of(context).primaryColor,
                                child: Icon(
                                  isPending ? Icons.pending : Icons.business,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                org['organization_name'] ?? 'Unknown Organization',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(org['role'] ?? 'No Role'),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : isPending
                                      ? const Chip(
                                          label: Text('Pending', style: TextStyle(fontSize: 12)),
                                          backgroundColor: Colors.orange,
                                          labelPadding: EdgeInsets.symmetric(horizontal: 8),
                                        )
                                      : const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: isPending || isSelected
                                  ? null
                                  : () async {
                                      final success = await ref
                                          .read(organizationProvider.notifier)
                                          .switchOrganization(org['organization_id']);

                                      if (success && mounted) {
                                        // Refresh token with new organization context
                                        await ref.read(authProvider.notifier).refreshToken();

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Switched to ${org['organization_name']}',
                                            ),
                                          ),
                                        );
                                        context.pop();
                                      } else if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Failed to switch organization'),
                                          ),
                                        );
                                      }
                                    },
                            ),
                          ),  // closes Card
                          );  // closes StaggeredItem
                        }).toList(),
                        if (orgState.activeOrganizations.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No active organizations available'),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
