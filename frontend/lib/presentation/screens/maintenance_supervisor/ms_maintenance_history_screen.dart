import 'package:flutter/material.dart';

class MsMaintenanceHistoryScreen extends StatelessWidget {
  final String vehicleId;
  final String vehicleName;
  final String vehicleModel;

  const MsMaintenanceHistoryScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
    this.vehicleModel = 'Freightliner Cascadia',
  });

  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildSummaryCards(),
                _buildFilterBar(),
                _buildHistoryList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: _bg.withOpacity(0.9),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vehicleName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text(vehicleModel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Log', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E2E2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _StatCard(icon: Icons.settings_suggest_outlined, label: 'Total Services', value: '24')),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(icon: Icons.event_available_outlined, label: 'Last Service', value: 'Oct 12, 23')),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(icon: Icons.update_outlined, label: 'Next Service', value: 'Jan 15, 24', subLabel: 'ESTIMATED')),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Text(
            'MAINTENANCE HISTORY',
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.filter_list, color: _primary, size: 16),
            label: const Text('Filter', style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _HistoryEntry(
            title: 'Oil Change',
            date: 'Nov 04, 2023',
            cost: '\$120.00',
            techName: 'John Doe',
            status: _EntryStatus.pending,
          ),
          const SizedBox(height: 12),
          _HistoryEntry(
            title: 'Brake Inspection',
            date: 'Oct 12, 2023',
            cost: '\$250.00',
            techName: 'Sarah Miller',
            status: _EntryStatus.completed,
          ),
          const SizedBox(height: 12),
          _HistoryEntry(
            title: 'Engine Repair',
            date: 'Sep 05, 2023',
            cost: '\$1,420.00',
            techName: 'Mike Ross',
            status: _EntryStatus.completed,
          ),
          const SizedBox(height: 12),
          _HistoryEntry(
            title: 'Tire Rotation',
            date: 'Aug 18, 2023',
            cost: '\$85.00',
            techName: 'Sarah Miller',
            status: _EntryStatus.completed,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subLabel;

  const _StatCard({required this.icon, required this.label, required this.value, this.subLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2E2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFEC5B13), size: 20),
          const SizedBox(height: 6),
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(subLabel!, style: const TextStyle(color: Color(0xFFEC5B13), fontSize: 9, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  final String title;
  final String date;
  final String cost;
  final String techName;
  final _EntryStatus status;

  const _HistoryEntry({
    required this.title,
    required this.date,
    required this.cost,
    required this.techName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = status == _EntryStatus.pending;
    final Color borderColor = isPending ? const Color(0xFFEC5B13).withOpacity(0.3) : const Color(0xFFE2E2E2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 6),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                          cost,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPending ? const Color(0xFFEC5B13) : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? const Color(0xFFEC5B13).withOpacity(0.1) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPending ? 'Pending' : 'Completed',
                    style: TextStyle(
                      color: isPending ? const Color(0xFFEC5B13) : Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                      child: const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text('Tech: $techName', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _EntryStatus { pending, completed }
