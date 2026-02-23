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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

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
    final orgName = orgState.organization?['name'] as String?;
    final pendingCount = orgState.statistics?['pending_requests'] as int? ?? 0;
    final employeeCount = orgState.statistics?['total_employees'] as int? ?? 0;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 16, bottom: 56),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orgName ?? 'My Organization',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    orgState.organization?['business_type'] ?? 'Fleet Management',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      Icons.business,
                      size: 72,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: theme.primaryColor,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    const Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined, size: 18)),
                    Tab(
                      icon: employeeCount > 0
                          ? Badge(
                              label: Text('$employeeCount'),
                              backgroundColor: Colors.white,
                              textColor: theme.primaryColor,
                              child: const Icon(Icons.people_outline, size: 18),
                            )
                          : const Icon(Icons.people_outline, size: 18),
                      text: 'Employees',
                    ),
                    Tab(
                      icon: pendingCount > 0
                          ? Badge(
                              label: Text('$pendingCount'),
                              backgroundColor: Colors.red.shade300,
                              child: const Icon(Icons.pending_actions_outlined, size: 18),
                            )
                          : const Icon(Icons.pending_actions_outlined, size: 18),
                      text: 'Requests',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            OrganizationOverviewTab(),
            EmployeesTab(),
            PendingRequestsScreen(),
          ],
        ),
      ),
    );
  }
}
