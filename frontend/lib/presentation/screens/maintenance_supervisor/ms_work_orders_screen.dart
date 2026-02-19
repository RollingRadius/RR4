import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MsWorkOrdersScreen extends StatelessWidget {
  const MsWorkOrdersScreen({super.key});

  static const _navy = Color(0xFF1A1C2E);
  static const _card = Color(0xFF2D2F45);
  static const _orange = Color(0xFFF15A24);

  String _formatDate() {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _navy,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSummaryCards(),
                _buildCurrentTask(context),
                _buildUpcomingTasks(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Daily Assignments',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(),
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(child: _SummaryCard(label: 'Total', value: '12', borderColor: _orange)),
          const SizedBox(width: 10),
          Expanded(child: _SummaryCard(label: 'Done', value: '8', borderColor: const Color(0xFF22C55E))),
          const SizedBox(width: 10),
          Expanded(child: _SummaryCard(label: 'Left', value: '4', borderColor: const Color(0xFFEAB308))),
        ],
      ),
    );
  }

  Widget _buildCurrentTask(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Current Task',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'IN PROGRESS',
                  style: TextStyle(color: _orange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VEHICLE ID', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        const Text('TRK-8829', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('LOCATION', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text('Bay 4 • Main Depot', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1), height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_outlined, color: _orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Service Type', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
                        const SizedBox(height: 2),
                        const Text('Brake Pad Replacement', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    label: const Text('Update Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Tasks', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => context.push('/maintenance/schedule'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('View Schedule', style: TextStyle(color: _orange, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TaskItem(time: '14:30', period: 'Today', vehicle: 'VAN-402', service: 'Oil Change', location: 'Lot B, Row 12', priority: 'MEDIUM', priorityColor: const Color(0xFF3B82F6)),
          const SizedBox(height: 8),
          _TaskItem(time: '16:00', period: 'Today', vehicle: 'TRK-112', service: 'Tire Rotation', location: 'Bay 2 • Main Depot', priority: 'HIGH', priorityColor: const Color(0xFFEAB308)),
          const SizedBox(height: 8),
          _TaskItem(time: '09:00', period: 'Tomorrow', vehicle: 'BUS-08', service: 'HVAC Check', location: 'External Yard', priority: 'LOW', priorityColor: const Color(0xFF6B7280)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color borderColor;

  const _SummaryCard({required this.label, required this.value, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2F45),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String time;
  final String period;
  final String vehicle;
  final String service;
  final String location;
  final String priority;
  final Color priorityColor;

  const _TaskItem({
    required this.time,
    required this.period,
    required this.vehicle,
    required this.service,
    required this.location,
    required this.priority,
    required this.priorityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2F45).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Column(
              children: [
                Text(time, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(period.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, letterSpacing: 0.5)),
              ],
            ),
          ),
          Container(width: 1, height: 34, color: Colors.white.withOpacity(0.1), margin: const EdgeInsets.symmetric(horizontal: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$vehicle • $service',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: priorityColor.withOpacity(0.3)),
                      ),
                      child: Text(priority, style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(location, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
