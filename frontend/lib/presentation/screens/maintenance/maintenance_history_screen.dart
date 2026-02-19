import 'package:flutter/material.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

class MaintenanceHistoryScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const MaintenanceHistoryScreen({
    super.key,
    required this.vehicleId,
    this.vehicleName = 'Vehicle',
  });

  @override
  State<MaintenanceHistoryScreen> createState() => _MaintenanceHistoryScreenState();
}

class _MaintenanceHistoryScreenState extends State<MaintenanceHistoryScreen> {
  String _filter = 'all';

  static const _records = [
    _MaintenanceRecord(
      title: 'Oil Change',
      date: 'Nov 04, 2023',
      cost: '\$120.00',
      status: 'pending',
      technician: 'John Doe',
      notes: 'Full synthetic 5W-30, filter replaced',
    ),
    _MaintenanceRecord(
      title: 'Brake Inspection',
      date: 'Sep 18, 2023',
      cost: '\$85.00',
      status: 'completed',
      technician: 'Sarah Kim',
      notes: 'Front pads replaced, rotors OK',
    ),
    _MaintenanceRecord(
      title: 'Tire Rotation',
      date: 'Aug 02, 2023',
      cost: '\$45.00',
      status: 'completed',
      technician: 'Mike Chen',
      notes: 'All 4 tires rotated, pressure adjusted',
    ),
    _MaintenanceRecord(
      title: 'AC Service',
      date: 'Jun 15, 2023',
      cost: '\$210.00',
      status: 'completed',
      technician: 'John Doe',
      notes: 'Refrigerant recharged, cabin filter replaced',
    ),
    _MaintenanceRecord(
      title: 'Annual Inspection',
      date: 'Jan 20, 2023',
      cost: '\$150.00',
      status: 'completed',
      technician: 'Sarah Kim',
      notes: 'Full vehicle inspection, passed all checks',
    ),
  ];

  List<_MaintenanceRecord> get _filtered {
    if (_filter == 'all') return _records;
    return _records.where((r) => r.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.bgPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vehicleName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Text(
                  'Maintenance History',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddLogDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Log'),
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.settings_suggest_rounded,
                        label: 'Total Services',
                        value: '${_records.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.event_available_rounded,
                        label: 'Last Service',
                        value: 'Nov 4, 23',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.update_rounded,
                        label: 'Next Service',
                        value: 'Jan 15, 24',
                        highlight: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MAINTENANCE HISTORY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterSheet(context),
                      child: const Row(
                        children: [
                          Icon(Icons.filter_list, size: 16, color: AppTheme.primaryBlue),
                          SizedBox(width: 4),
                          Text(
                            'Filter',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Records
                ..._filtered.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MaintenanceCard(record: r),
                    )),

                if (_filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.build_circle_outlined,
                            size: 48, color: AppTheme.textTertiary),
                        const SizedBox(height: 12),
                        const Text(
                          'No maintenance records',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Status',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...['all', 'pending', 'completed'].map((f) => ListTile(
                  leading: Radio<String>(
                    value: f,
                    groupValue: _filter,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (val) {
                      setState(() => _filter = val!);
                      Navigator.pop(ctx);
                    },
                  ),
                  title: Text(f[0].toUpperCase() + f.substring(1)),
                  onTap: () {
                    setState(() => _filter = f);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showAddLogDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add maintenance log - coming soon')),
    );
  }
}

// ==================== SUMMARY CARD ====================
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E0E0)),
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
          Icon(icon, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          if (highlight)
            const Text(
              'ESTIMATED',
              style: TextStyle(
                fontSize: 9,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== MAINTENANCE CARD ====================
class _MaintenanceCard extends StatelessWidget {
  final _MaintenanceRecord record;

  const _MaintenanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isPending = record.status == 'pending';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? AppTheme.primaryBlue.withOpacity(0.3)
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                record.date,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.circle, size: 4, color: AppTheme.textTertiary),
                              ),
                              Text(
                                record.cost,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AppTheme.primaryBlue.withOpacity(0.1)
                            : AppTheme.statusActive.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPending ? 'PENDING' : 'DONE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPending ? AppTheme.primaryBlue : AppTheme.statusActive,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              border: const Border(
                top: BorderSide(color: Color(0xFFF1F0F0)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tech: ${record.technician}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== DATA CLASS ====================
class _MaintenanceRecord {
  final String title;
  final String date;
  final String cost;
  final String status;
  final String technician;
  final String notes;

  const _MaintenanceRecord({
    required this.title,
    required this.date,
    required this.cost,
    required this.status,
    required this.technician,
    required this.notes,
  });
}
