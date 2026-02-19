import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

// Mock vehicle data for Fleet Overview
class _VehicleData {
  final String id;
  final String name;
  final String info;
  final String status;
  final double level;
  final bool isAlert;

  const _VehicleData({
    required this.id,
    required this.name,
    required this.info,
    required this.status,
    required this.level,
    this.isAlert = false,
  });
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _vehicles = [
    _VehicleData(
      id: 'TRK-042',
      name: 'Truck-042',
      info: 'John Doe',
      status: 'active',
      level: 0.85,
    ),
    _VehicleData(
      id: 'VAN-018',
      name: 'Van-018',
      info: 'Service Center A',
      status: 'maintenance',
      level: 0.20,
    ),
    _VehicleData(
      id: 'SMI-009',
      name: 'Semi-009',
      info: 'I-95 Northbound',
      status: 'active',
      level: 0.62,
    ),
    _VehicleData(
      id: 'TRK-102',
      name: 'Truck-102',
      info: 'Engine Overheat',
      status: 'alert',
      level: 0.45,
      isAlert: true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_VehicleData> get _filtered {
    if (_searchQuery.isEmpty) return _vehicles;
    return _vehicles
        .where((v) =>
            v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            v.info.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            v.id.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final total = _vehicles.length;
    final active = _vehicles.where((v) => v.status == 'active').length;
    final maintenance = _vehicles.where((v) => v.status == 'maintenance').length;
    final alerts = _vehicles.where((v) => v.status == 'alert').length;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Sticky Header
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: AppTheme.bgPrimary,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 70,
                collapsedHeight: 70,
                automaticallyImplyLeading: false,
                flexibleSpace: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        // Brand icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Fleet Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        // Notifications
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.bgSecondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Search + Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Search Bar
                    _buildSearchBar(),
                    const SizedBox(height: 20),

                    // Metric Cards 2x2
                    _buildMetricCards(total, active, maintenance, alerts),
                    const SizedBox(height: 24),

                    // Vehicle Status Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Vehicle Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/vehicles'),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Vehicle cards
                    ..._filtered.map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VehicleStatusCard(vehicle: v),
                        )),

                    if (_filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: const Text(
                          'No vehicles match your search',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),

          // FAB
          Positioned(
            right: 20,
            bottom: 88,
            child: FloatingActionButton(
              onPressed: () => context.push('/vehicles/add'),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search vehicle ID or driver',
                hintStyle: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
                prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary, size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.bgPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune, size: 18, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(int total, int active, int maintenance, int alerts) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _MetricCard(
          label: 'Total',
          value: total.toString(),
          color: AppTheme.textPrimary,
          trend: '+2%',
          trendUp: true,
        ),
        _MetricCard(
          label: 'Active',
          value: active.toString(),
          color: AppTheme.statusActive,
          trend: '+1%',
          trendUp: true,
        ),
        _MetricCard(
          label: 'Maintenance',
          value: maintenance.toString(),
          color: AppTheme.primaryBlue,
          trend: '-5%',
          trendUp: false,
          highlight: true,
        ),
        _MetricCard(
          label: 'Alerts',
          value: alerts.toString(),
          color: AppTheme.statusError,
          trend: '10%',
          trendUp: false,
          alertIcon: true,
        ),
      ],
    );
  }
}

// ==================== METRIC CARD ====================
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String trend;
  final bool trendUp;
  final bool highlight;
  final bool alertIcon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.trend,
    required this.trendUp,
    this.highlight = false,
    this.alertIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border(
                left: BorderSide(color: AppTheme.primaryBlue, width: 4),
                top: const BorderSide(color: Color(0xFFE2E0E0)),
                right: const BorderSide(color: Color(0xFFE2E0E0)),
                bottom: const BorderSide(color: Color(0xFFE2E0E0)),
              )
            : Border.all(color: const Color(0xFFE2E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    alertIcon
                        ? Icons.error_outline
                        : trendUp
                            ? Icons.trending_up
                            : Icons.trending_down,
                    size: 12,
                    color: trendUp ? AppTheme.statusActive : color,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trend,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: trendUp ? AppTheme.statusActive : color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== VEHICLE STATUS CARD ====================
class _VehicleStatusCard extends StatelessWidget {
  final _VehicleData vehicle;

  const _VehicleStatusCard({required this.vehicle});

  (Color, Color, String) _statusStyle() {
    switch (vehicle.status) {
      case 'active':
        return (const Color(0xFF10B981), const Color(0xFFD1FAE5), 'Active');
      case 'maintenance':
        return (AppTheme.primaryBlue, const Color(0xFFFFE4D6), 'Maintenance');
      case 'alert':
        return (AppTheme.statusError, const Color(0xFFFEE2E2), 'Alert');
      default:
        return (AppTheme.statusIdle, const Color(0xFFF1F0F0), 'Offline');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBg, statusLabel) = _statusStyle();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: vehicle.isAlert
              ? AppTheme.statusError.withOpacity(0.3)
              : const Color(0xFFE2E0E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          vehicle.isAlert
                              ? Icons.warning_rounded
                              : vehicle.status == 'active'
                                  ? Icons.person_outline
                                  : Icons.location_on_outlined,
                          size: 12,
                          color: vehicle.isAlert
                              ? AppTheme.statusError
                              : AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vehicle.info,
                            style: TextStyle(
                              fontSize: 12,
                              color: vehicle.isAlert
                                  ? AppTheme.statusError
                                  : AppTheme.textTertiary,
                              fontWeight: vehicle.isAlert
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Status badge + level
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${(vehicle.level * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        vehicle.status == 'active' ? Icons.battery_full : Icons.gas_meter_outlined,
                        size: 14,
                        color: statusColor,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: vehicle.level,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F0F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
