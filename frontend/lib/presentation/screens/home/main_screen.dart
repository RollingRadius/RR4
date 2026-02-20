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
      // Each screen renders its own styled header — no global AppBar needed
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(msUser, driverUser, user),
    );
  }

  Widget _buildBottomNav(bool isMsUser, bool isDriverUser, dynamic user) {
    final items =
        isMsUser ? _msNavItems : (isDriverUser ? _driverNavItems : _navItems);
    final isDark = isMsUser;
    final bg = isDark ? const Color(0xFF1A1C2E) : AppTheme.bgSecondary;
    final activeColor =
        isDark ? const Color(0xFFF15A24) : AppTheme.primaryBlue;
    final inactiveColor = isDark
        ? Colors.white.withOpacity(0.38)
        : AppTheme.textTertiary;

    // Full name initials for avatar
    final fullName = (user?.fullName as String?) ?? '';
    final initials = fullName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final avatarLabel = initials.isNotEmpty
        ? initials
        : ((user?.username as String?)?.substring(0, 1).toUpperCase() ?? 'U');

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE8E6E6),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            children: [
              // Nav tabs
              ...List.generate(items.length, (i) {
                final item = items[i];
                final sel = _selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onNavTap(i, isMsUser, isDriverUser),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel
                            ? activeColor.withOpacity(isDark ? 0.15 : 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Active dot
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: sel ? 20 : 0,
                            height: sel ? 3 : 0,
                            margin: const EdgeInsets.only(bottom: 3),
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Icon(
                            sel ? item.activeIcon : item.icon,
                            color: sel ? activeColor : inactiveColor,
                            size: 22,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: sel ? activeColor : inactiveColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // User avatar with profile popup
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                offset: const Offset(-12, -12),
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
                      context.go('/settings');
                      break;
                    case 'logout':
                      _handleLogout();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFEC5B13),
                                  Color(0xFFBF4209),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(avatarLabel,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName.isNotEmpty
                                    ? fullName
                                    : (user?.username ?? 'User'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A)),
                              ),
                              Text(
                                _capitalize(user?.role ?? 'User'),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  _popItem(Icons.person_rounded, 'My Profile', 'profile',
                      const Color(0xFFEC5B13)),
                  _popItem(Icons.business_rounded, 'My Organizations',
                      'organizations', const Color(0xFF6366F1)),
                  _popItem(Icons.add_business_rounded, 'Create Organization',
                      'create_organization', const Color(0xFF10B981)),
                  _popItem(Icons.admin_panel_settings_rounded,
                      'Manage Organization', 'manage_organization',
                      const Color(0xFF06B6D4)),
                  const PopupMenuDivider(),
                  _popItem(Icons.settings_rounded, 'Settings', 'settings',
                      const Color(0xFF64748B)),
                  _popItem(Icons.logout_rounded, 'Sign Out', 'logout',
                      const Color(0xFFEF4444)),
                ],
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFEC5B13), Color(0xFFBF4209)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFEC5B13).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(avatarLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _popItem(
      IconData icon, String label, String value, Color color) {
    return PopupMenuItem(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: value == 'logout'
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
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
