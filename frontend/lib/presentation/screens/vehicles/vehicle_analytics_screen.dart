import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/data/models/driver_model.dart';
import 'package:fleet_management/data/services/vehicle_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/driver_provider.dart';
import 'package:fleet_management/providers/vehicle_provider.dart';

class VehicleAnalyticsScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const VehicleAnalyticsScreen({
    super.key,
    required this.vehicleId,
    this.vehicleName = 'Vehicle',
  });

  @override
  ConsumerState<VehicleAnalyticsScreen> createState() =>
      _VehicleAnalyticsScreenState();
}

class _VehicleAnalyticsScreenState
    extends ConsumerState<VehicleAnalyticsScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  String _timeRange = '1M';
  Map<String, dynamic>? _vehicleData;
  bool _isLoadingVehicle = true;
  bool _isAssigning = false;

  static const _chartBars = [
    0.60, 0.55, 0.70, 0.65, 0.80, 0.75, 0.90, 0.85, 0.70, 0.60, 0.75, 0.65
  ];
  static const _chartLabels = ['01 Oct', '10 Oct', '20 Oct', '30 Oct'];

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    if (!mounted) return;
    setState(() => _isLoadingVehicle = true);
    try {
      final vehicleApi = VehicleApi(ref.read(apiServiceProvider));
      final data = await vehicleApi.getVehicleById(widget.vehicleId);
      if (mounted) setState(() { _vehicleData = data; _isLoadingVehicle = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingVehicle = false);
    }
  }

  Future<void> _showAssignDriverSheet() async {
    final token = ref.read(authProvider).token;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignDriverSheet(
        vehicleId: widget.vehicleId,
        token: token,
      ),
    );

    if (result != null && mounted) {
      await _loadVehicle();
      ref.read(vehicleProvider.notifier).loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$result assigned successfully'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    }
  }

  Future<void> _unassignDriver() async {
    final driverName = _vehicleData?['current_driver_name'] as String? ?? 'driver';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Unassign Driver'),
          ],
        ),
        content: Text('Remove $driverName from this vehicle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isAssigning = true);
    try {
      final vehicleApi = VehicleApi(ref.read(apiServiceProvider));
      await vehicleApi.unassignDriver(vehicleId: widget.vehicleId);
      await _loadVehicle();
      ref.read(vehicleProvider.notifier).loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver unassigned'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _vehicleData;
    final name = v != null
        ? '${v['manufacturer'] ?? ''} ${v['model'] ?? ''}'.trim()
        : widget.vehicleName;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Vehicle Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadVehicle,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAssetHeader(v, name),
            const SizedBox(height: 12),
            _buildDriverCard(v),
            const SizedBox(height: 16),
            _buildTimeSelector(),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildUtilizationGauge()),
                const SizedBox(width: 12),
                Expanded(child: _buildOdometerProgress()),
              ],
            ),
            const SizedBox(height: 16),
            _buildFuelChart(),
            const SizedBox(height: 16),
            _buildMaintenanceCosts(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Asset Header ──────────────────────────────────────────────────────────

  Widget _buildAssetHeader(Map<String, dynamic>? v, String name) {
    final status = v?['status'] as String? ?? 'active';
    final statusDisplay = status[0].toUpperCase() + status.substring(1);
    final statusColor = _getStatusColor(status);
    final registration = v?['registration_number'] as String? ?? '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_outlined,
                size: 36, color: Colors.grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(statusDisplay,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('Reg: $registration',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _ActionChip(
                      icon: Icons.download_outlined,
                      label: 'Download Report',
                      filled: true,
                      onTap: () {},
                    ),
                    _ActionChip(
                      icon: Icons.map_outlined,
                      label: 'View Live Map',
                      filled: false,
                      onTap: () => context.push('/tracking/live'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF15803D);
      case 'maintenance':
        return const Color(0xFFD97706);
      case 'inactive':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  // ─── Driver Assignment Card ────────────────────────────────────────────────

  Widget _buildDriverCard(Map<String, dynamic>? v) {
    final hasDriver = v != null && v['current_driver_id'] != null;
    final driverName = v?['current_driver_name'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.person_rounded, color: _primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Driver Assignment',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_isLoadingVehicle)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _primary),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoadingVehicle)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Loading vehicle data…',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ),
            )
          else if (hasDriver) ...[
            // Driver assigned — show info + change/unassign buttons
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _primary.withOpacity(0.15),
                  child: Text(
                    driverName?.isNotEmpty == true
                        ? driverName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driverName ?? 'Unknown Driver',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      Text('Currently assigned',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _isAssigning ? null : _showAssignDriverSheet,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Change'),
                  style: TextButton.styleFrom(foregroundColor: _primary),
                ),
                IconButton(
                  onPressed: _isAssigning ? null : _unassignDriver,
                  icon: const Icon(Icons.person_remove_outlined, size: 18),
                  color: Colors.red.shade400,
                  tooltip: 'Unassign driver',
                ),
              ],
            ),
          ] else ...[
            // No driver assigned
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_off_outlined,
                        size: 32, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 10),
                  Text('No driver assigned',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAssigning ? null : _showAssignDriverSheet,
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Assign Driver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Analytics Widgets (unchanged from before) ────────────────────────────

  Widget _buildTimeSelector() {
    const ranges = ['7D', '1M', '3M', 'YTD'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ranges.map((r) {
          final selected = _timeRange == r;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _timeRange = r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4)
                        ]
                      : [],
                ),
                child: Text(r,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.w500,
                      color: selected
                          ? Colors.black87
                          : Colors.grey.shade500,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.local_gas_station_outlined,
            label: 'Avg MPG',
            value: '18.5',
            trend: '+1.2%',
            trendUp: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.timer_outlined,
            label: 'Idle Time',
            value: '42h 15m',
            trend: '-4.5%',
            trendUp: false,
          ),
        ),
      ],
    );
  }

  Widget _buildUtilizationGauge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('UTILIZATION SCORE',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(100, 100),
                  painter: _CircleGaugePainter(0.82),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('82%',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900)),
                    Text('OPTIMAL',
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Vehicle was active for 19.6 hours per day on average.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildOdometerProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ODOMETER PROGRESS',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: const Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '45,280 ',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: 'km',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('Next: 50k km',
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.905,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: _primary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(const TextSpan(
                    children: [
                      TextSpan(text: 'Service required in '),
                      TextSpan(
                          text: '4,720 km',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' (Approx. 12 days)'),
                    ],
                    style: TextStyle(fontSize: 10),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fuel Efficiency Trend',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Daily average over last 30 days',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.show_chart_rounded, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_chartBars.length, (i) {
                final opacity = 0.2 + (_chartBars[i] * 0.8);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      height: _chartBars[i] * 100,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(opacity),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _chartLabels
                .map((l) => Text(l,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                        letterSpacing: 0.3)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCosts() {
    const items = [
      {
        'icon': Icons.oil_barrel_outlined,
        'name': 'Oil & Filter Change',
        'date': 'Oct 24, 2023',
        'cost': '₹15,000'
      },
      {
        'icon': Icons.tire_repair_outlined,
        'name': 'Tire Rotation',
        'date': 'Sep 12, 2023',
        'cost': '₹6,500'
      },
      {
        'icon': Icons.settings_input_component_outlined,
        'name': 'Brake Pad Replacement',
        'date': 'Aug 05, 2023',
        'cost': '₹37,000'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Maintenance',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {},
                child: const Text('View All',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _primary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((e) {
            final item = e.value;
            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item['icon'] as IconData,
                          color: Colors.grey.shade600, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] as String,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          Text(item['date'] as String,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Text(item['cost'] as String,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (e.key < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child:
                        Divider(height: 1, color: Colors.grey.shade100),
                  ),
              ],
            );
          }),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL (LAST 30D)',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5)),
                const Text('₹58,500',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Assign Driver Bottom Sheet ───────────────────────────────────────────────

class _AssignDriverSheet extends ConsumerStatefulWidget {
  final String vehicleId;
  final String? token;

  const _AssignDriverSheet({required this.vehicleId, required this.token});

  @override
  ConsumerState<_AssignDriverSheet> createState() =>
      _AssignDriverSheetState();
}

class _AssignDriverSheetState extends ConsumerState<_AssignDriverSheet> {
  static const _primary = Color(0xFFEC5B13);
  final _searchController = TextEditingController();
  bool _isAssigning = false;
  String? _assigningDriverId;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(driverProvider.notifier).loadDrivers(status: 'active'));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final search = _searchController.text.toLowerCase();
    final drivers = driverState.drivers.where((d) {
      if (!d.isActive) return false;
      if (search.isEmpty) return true;
      return d.fullName.toLowerCase().contains(search) ||
          d.employeeId.toLowerCase().contains(search) ||
          d.phone.contains(search);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_add_rounded,
                        color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Driver',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Choose an active driver to assign',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name, ID, or phone…',
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: _primary),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            Divider(height: 1, color: Colors.grey.shade200),

            // Driver list
            Expanded(
              child: driverState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary))
                  : drivers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_outlined,
                                  size: 52,
                                  color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                search.isNotEmpty
                                    ? 'No drivers match "$search"'
                                    : 'No active drivers available',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          itemCount: drivers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final driver = drivers[i];
                            final loading = _isAssigning &&
                                _assigningDriverId == driver.driverId;
                            return _DriverListItem(
                              driver: driver,
                              token: widget.token,
                              isLoading: loading,
                              onTap: (_isAssigning && !loading)
                                  ? null
                                  : () => _assignDriver(driver),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignDriver(DriverModel driver) async {
    setState(() {
      _isAssigning = true;
      _assigningDriverId = driver.driverId;
    });
    try {
      final vehicleApi = VehicleApi(ref.read(apiServiceProvider));
      await vehicleApi.assignDriver(
        vehicleId: widget.vehicleId,
        driverId: driver.driverId,
      );
      if (mounted) Navigator.pop(context, driver.fullName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
          _assigningDriverId = null;
        });
      }
    }
  }
}

// ─── Driver List Item ─────────────────────────────────────────────────────────

class _DriverListItem extends StatelessWidget {
  final DriverModel driver;
  final String? token;
  final bool isLoading;
  final VoidCallback? onTap;

  const _DriverListItem({
    required this.driver,
    required this.token,
    required this.isLoading,
    required this.onTap,
  });

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    final photoUrl =
        '${AppConfig.apiBaseUrl}/api/drivers/${driver.driverId}/photo';
    final headers = token != null
        ? {'Authorization': 'Bearer $token'}
        : <String, String>{};

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isLoading ? _primary.withOpacity(0.05) : Colors.white,
            border: Border.all(
              color: isLoading
                  ? _primary.withOpacity(0.4)
                  : Colors.grey.shade200,
              width: isLoading ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Driver photo
              ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.network(
                    photoUrl,
                    headers: headers,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _primary.withOpacity(0.15),
                      child: Center(
                        child: Text(
                          driver.firstName.isNotEmpty
                              ? driver.firstName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Driver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.fullName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('ID: ${driver.employeeId}  •  ${driver.phone}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),

              // Trailing icon / spinner
              isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: _primary),
                    )
                  : Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool trendUp;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade500, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 6),
              Text(trend,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: trendUp
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: filled ? _primary : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 4)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: filled ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: filled ? Colors.white : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _CircleGaugePainter extends CustomPainter {
  final double value;
  _CircleGaugePainter(this.value);

  static const _primary = Color(0xFFEC5B13);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -3.14159 / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      value * 2 * 3.14159,
      false,
      Paint()
        ..color = _primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CircleGaugePainter old) => old.value != value;
}
