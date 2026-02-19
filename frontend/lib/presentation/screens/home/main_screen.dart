import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/organization_provider.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

class MainScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  // Standard nav items: Fleet, Tasks, Roles, Reports, Settings
  static const _navItems = [
    _NavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Fleet'),
    _NavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment, label: 'Tasks'),
    _NavItem(icon: Icons.groups_outlined, activeIcon: Icons.groups, label: 'Roles'),
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Reports'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  static const _routes = [
    '/dashboard',
    '/fleet-hub',
    '/roles/custom',
    '/reports',
    '/settings',
  ];

  // Maintenance Supervisor nav items: My Tasks, Inventory, Schedule, Settings
  static const _msNavItems = [
    _NavItem(icon: Icons.task_alt_outlined, activeIcon: Icons.task_alt, label: 'My Tasks'),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Inventory'),
    _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Schedule'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  static const _msRoutes = [
    '/ms/work-orders',
    '/ms/inventory',
    '/maintenance/schedule',
    '/settings',
  ];

  // Driver nav items: My Trips, My Vehicle, Schedule, Settings
  static const _driverNavItems = [
    _NavItem(icon: Icons.route_outlined, activeIcon: Icons.route, label: 'My Trips'),
    _NavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'My Vehicle'),
    _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Schedule'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  static const _driverRoutes = [
    '/driver/trips',
    '/driver/vehicle',
    '/maintenance/schedule',
    '/settings',
  ];

  bool _isMsUser(String? role) {
    if (role == null) return false;
    final r = role.toLowerCase();
    return r == 'maintenance_supervisor' || r == 'maintenance supervisor';
  }

  bool _isDriverUser(String? role) {
    if (role == null) return false;
    final r = role.toLowerCase();
    return r == 'driver';
  }

  int _indexFromRoute(String location, bool isMsUser, bool isDriverUser) {
    if (isMsUser) {
      if (location.startsWith('/ms/work-orders')) return 0;
      if (location.startsWith('/ms/inventory')) return 1;
      if (location.startsWith('/maintenance/schedule')) return 2;
      if (location.startsWith('/settings')) return 3;
      return 0;
    }
    if (isDriverUser) {
      if (location.startsWith('/driver/trips')) return 0;
      if (location.startsWith('/driver/vehicle')) return 1;
      if (location.startsWith('/maintenance/schedule')) return 2;
      if (location.startsWith('/settings')) return 3;
      return 0;
    }
    if (location.startsWith('/fleet-hub')) return 1;
    if (location.startsWith('/vehicles')) return 1;
    if (location.startsWith('/drivers')) return 1;
    if (location.startsWith('/roles')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onNavTap(int index, bool isMsUser, bool isDriverUser) {
    if (isMsUser) {
      context.go(_msRoutes[index]);
    } else if (isDriverUser) {
      context.go(_driverRoutes[index]);
    } else {
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final location = GoRouterState.of(context).matchedLocation;
    final msUser = _isMsUser(user?.role);
    final driverUser = _isDriverUser(user?.role);
    _selectedIndex = _indexFromRoute(location, msUser, driverUser);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: (msUser || driverUser) ? null : AppBar(
        backgroundColor: AppTheme.bgSecondary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Fleet Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          // Profile menu
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryBlue,
                child: Text(
                  user?.username.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppTheme.textPrimary),
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
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(msUser, driverUser),
    );
  }

  Widget _buildBottomNav(bool isMsUser, bool isDriverUser) {
    final items = isMsUser ? _msNavItems : (isDriverUser ? _driverNavItems : _navItems);
    final isDarkNav = isMsUser;
    return Container(
      decoration: BoxDecoration(
        color: isDarkNav ? const Color(0xFF1A1C2E) : AppTheme.bgSecondary,
        border: Border(
          top: BorderSide(color: isDarkNav ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E0E0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = _selectedIndex == i;
              final activeColor = isDarkNav ? const Color(0xFFF15A24) : AppTheme.primaryBlue;
              final inactiveColor = isDarkNav ? Colors.white.withOpacity(0.4) : AppTheme.textTertiary;
              return GestureDetector(
                onTap: () => _onNavTap(i, isMsUser, isDriverUser),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? activeColor : inactiveColor,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? activeColor : inactiveColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToOrganizationManagement() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Loading organizations...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    await ref.read(organizationProvider.notifier).loadOrganizations();

    if (!mounted) return;

    final orgState = ref.read(organizationProvider);

    if (orgState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading organizations: ${orgState.error}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (orgState.currentOrganizationId != null && orgState.currentOrganization != null) {
      final orgId = orgState.currentOrganizationId!;
      final orgName = orgState.currentOrganization!['organization_name'] ?? 'Organization';
      context.push('/organizations/$orgId/manage', extra: {'name': orgName});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No organization found. Please join or create one first.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
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
      if (mounted) context.go(AppConstants.routeLogin);
    }
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
