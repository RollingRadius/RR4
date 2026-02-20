import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/data/models/driver_model.dart';
import 'package:fleet_management/providers/driver_provider.dart';

class DriverManagementScreen extends ConsumerStatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  ConsumerState<DriverManagementScreen> createState() =>
      _DriverManagementScreenState();
}

class _DriverManagementScreenState
    extends ConsumerState<DriverManagementScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  static const _filters = ['All', 'Active', 'On Leave', 'Available'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(driverProvider.notifier).loadDrivers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DriverModel> _filteredDrivers(List<DriverModel> drivers) {
    var filtered = drivers;
    if (_selectedFilter != 'All') {
      filtered = filtered.where((d) {
        switch (_selectedFilter) {
          case 'Active':
            return d.status.toLowerCase() == 'active';
          case 'On Leave':
            return d.status.toLowerCase() == 'on_leave';
          case 'Available':
            return d.status.toLowerCase() == 'inactive';
          default:
            return true;
        }
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((d) =>
              d.fullName.toLowerCase().contains(q) ||
              d.employeeId.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final drivers = _filteredDrivers(driverState.drivers);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          _buildHeader(driverState.total),
          Expanded(
            child: driverState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                    ),
                  )
                : driverState.error != null
                    ? _buildError(driverState.error!)
                    : drivers.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: AppTheme.primaryBlue,
                            onRefresh: () =>
                                ref.read(driverProvider.notifier).loadDrivers(),
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 100),
                              itemCount: drivers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) => _DriverCard(
                                driver: drivers[i],
                                onTap: () => context.push(
                                  '/drivers/${drivers[i].driverId}/view',
                                  extra: {'driverName': drivers[i].fullName},
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/drivers/add'),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 4,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Container(
      color: AppTheme.bgPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.local_shipping_rounded,
                        color: AppTheme.primaryBlue, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Drivers',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '$total total fleet members',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          size: 22, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search drivers, employee ID...',
                    hintStyle: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: AppTheme.textSecondary),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            // Filter chips
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final selected = f == _selectedFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryBlue
                            : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryBlue
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color:
                                      AppTheme.primaryBlue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 52, color: Colors.red[300]),
          const SizedBox(height: 14),
          Text(
            error,
            style: const TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(driverProvider.notifier).loadDrivers(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedFilter != 'All'
                ? 'No drivers match your filter'
                : 'No drivers yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          if (_searchQuery.isEmpty && _selectedFilter == 'All') ...[
            const SizedBox(height: 6),
            Text(
              'Tap + to add your first driver',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Driver Card
// ─────────────────────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback onTap;

  const _DriverCard({required this.driver, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(driver);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar + status dot
            Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.15),
                        width: 2),
                  ),
                  child: Center(
                    child: Text(
                      driver.firstName.isNotEmpty
                          ? driver.firstName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: info.dotColor,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: info.badgeColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          info.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: info.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(info.secondaryIcon,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          info.secondaryText,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  _StatusInfo _statusInfo(DriverModel d) {
    switch (d.status.toLowerCase()) {
      case 'active':
        return _StatusInfo(
          label: 'Active',
          dotColor: const Color(0xFF22C55E),
          badgeColor: const Color(0xFFDCFCE7),
          textColor: const Color(0xFF15803D),
          secondaryIcon: Icons.local_shipping_rounded,
          secondaryText: '#${d.employeeId}',
        );
      case 'on_leave':
        return _StatusInfo(
          label: 'On Leave',
          dotColor: AppTheme.primaryBlue,
          badgeColor: AppTheme.primaryBlue.withOpacity(0.1),
          textColor: AppTheme.primaryBlue,
          secondaryIcon: Icons.calendar_month_rounded,
          secondaryText: 'Currently on leave',
        );
      case 'terminated':
        return _StatusInfo(
          label: 'Terminated',
          dotColor: const Color(0xFFEF4444),
          badgeColor: const Color(0xFFFEE2E2),
          textColor: const Color(0xFFDC2626),
          secondaryIcon: Icons.badge_rounded,
          secondaryText: '#${d.employeeId}',
        );
      default:
        return _StatusInfo(
          label: 'Available',
          dotColor: const Color(0xFF3B82F6),
          badgeColor: const Color(0xFFDBEAFE),
          textColor: const Color(0xFF1D4ED8),
          secondaryIcon: Icons.location_on_rounded,
          secondaryText: d.city ?? 'Main Depot',
        );
    }
  }
}

class _StatusInfo {
  final String label;
  final Color dotColor;
  final Color badgeColor;
  final Color textColor;
  final IconData secondaryIcon;
  final String secondaryText;

  const _StatusInfo({
    required this.label,
    required this.dotColor,
    required this.badgeColor,
    required this.textColor,
    required this.secondaryIcon,
    required this.secondaryText,
  });
}
