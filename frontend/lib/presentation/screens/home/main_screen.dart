import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/organization_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

class MainScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.directions_car_outlined),
      selectedIcon: Icon(Icons.directions_car),
      label: 'Vehicles',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Drivers',
    ),
    NavigationDestination(
      icon: Icon(Icons.route_outlined),
      selectedIcon: Icon(Icons.route),
      label: 'Trips',
    ),
    NavigationDestination(
      icon: Icon(Icons.assessment_outlined),
      selectedIcon: Icon(Icons.assessment),
      label: 'Reports',
    ),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/vehicles');
        break;
      case 2:
        context.go('/drivers');
        break;
      case 3:
        context.go('/trips');
        break;
      case 4:
        context.go('/reports');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Management'),
        actions: [
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          // Profile menu
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user?.username.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.push('/profile');
                  break;
                case 'organizations':
                  context.push('/organizations');
                  break;
                case 'create_organization':
                  context.push('/organizations/create');
                  break;
                case 'manage_organization':
                  _navigateToOrganizationManagement();
                  break;
                case 'settings':
                  context.push('/settings');
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user?.role ?? 'Independent User',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'organizations',
                child: Row(
                  children: [
                    Icon(Icons.business_outlined),
                    SizedBox(width: 12),
                    Text('My Organizations'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'create_organization',
                child: Row(
                  children: [
                    Icon(Icons.add_business),
                    SizedBox(width: 12),
                    Text('Create Organization'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'manage_organization',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings_outlined),
                    SizedBox(width: 12),
                    Text('Manage Organization'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }

  void _navigateToOrganizationManagement() {
    final orgState = ref.read(organizationProvider);

    if (orgState.currentOrganizationId != null && orgState.currentOrganization != null) {
      final orgId = orgState.currentOrganizationId!;
      final orgName = orgState.currentOrganization!['organization_name'] ?? 'Organization';

      context.push(
        '/organizations/$orgId/manage',
        extra: {'name': orgName},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No organization selected. Please join or create an organization first.'),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go(AppConstants.routeLogin);
      }
    }
  }
}
