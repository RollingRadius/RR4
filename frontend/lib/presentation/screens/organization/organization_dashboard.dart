import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/presentation/screens/organization/organization_overview_tab.dart';
import 'package:fleet_management/presentation/screens/organization/employees_tab.dart';
import 'package:fleet_management/presentation/screens/organization/pending_requests_screen.dart';
import 'package:fleet_management/providers/organization_dashboard_provider.dart';

class OrganizationDashboard extends ConsumerStatefulWidget {
  const OrganizationDashboard({super.key});

  @override
  ConsumerState<OrganizationDashboard> createState() =>
      _OrganizationDashboardState();
}

class _OrganizationDashboardState
    extends ConsumerState<OrganizationDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });

    // Load organization data
    Future.microtask(() {
      ref.read(organizationDashboardProvider.notifier).loadMyOrganization();
      ref.read(organizationDashboardProvider.notifier).loadEmployees();
      ref.read(organizationDashboardProvider.notifier).loadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgState = ref.watch(organizationDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Organization'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.business),
              text: 'Overview',
            ),
            Tab(
              icon: orgState.statistics != null &&
                      orgState.statistics!['total_employees'] > 0
                  ? Badge(
                      label: Text(
                          '${orgState.statistics!['total_employees']}'),
                      child: const Icon(Icons.people),
                    )
                  : const Icon(Icons.people),
              text: 'Employees',
            ),
            Tab(
              icon: orgState.statistics != null &&
                      orgState.statistics!['pending_requests'] > 0
                  ? Badge(
                      label: Text(
                          '${orgState.statistics!['pending_requests']}'),
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.pending_actions),
                    )
                  : const Icon(Icons.pending_actions),
              text: 'Grant Access',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OrganizationOverviewTab(),
          EmployeesTab(),
          PendingRequestsScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () {
                // Refresh pending requests
                ref.read(organizationDashboardProvider.notifier).loadEmployees(
                      statusFilter: 'pending',
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            )
          : null,
    );
  }
}
