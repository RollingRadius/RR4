import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VehicleAnalyticsScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const VehicleAnalyticsScreen({
    super.key,
    required this.vehicleId,
    this.vehicleName = 'Vehicle',
  });

  @override
  State<VehicleAnalyticsScreen> createState() => _VehicleAnalyticsScreenState();
}

class _VehicleAnalyticsScreenState extends State<VehicleAnalyticsScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  String _timeRange = '1M';

  // Mock bar chart heights (0.0–1.0)
  static const _chartBars = [0.60, 0.55, 0.70, 0.65, 0.80, 0.75, 0.90, 0.85, 0.70, 0.60, 0.75, 0.65];
  static const _chartLabels = ['01 Oct', '10 Oct', '20 Oct', '30 Oct'];

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Asset Analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () {},
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
            _buildAssetHeader(context),
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

  Widget _buildAssetHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
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
            child: const Icon(Icons.local_shipping_outlined, size: 36, color: Colors.grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.vehicleName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Active',
                          style: TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('ID: #${widget.vehicleId} • VIN: 1XK...492',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _ActionChip(
                      icon: Icons.download_outlined,
                      label: 'Download Report',
                      filled: true,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
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
                      ? [BoxShadow(
                          color: Colors.black.withOpacity(0.08), blurRadius: 4)]
                      : [],
                ),
                child: Text(r,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? Colors.black87 : Colors.grey.shade500,
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
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
                  fontSize: 10, color: Colors.grey.shade500, height: 1.4)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
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
              const Text.rich(TextSpan(
                children: [
                  TextSpan(
                      text: '45,280 ',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: 'mi',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              )),
              Text('Next: 50k mi',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.905,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
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
                const Icon(Icons.warning_amber_rounded, color: _primary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(const TextSpan(
                    children: [
                      TextSpan(text: 'Service required in '),
                      TextSpan(
                          text: '4,720 mi',
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fuel Efficiency Trend',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Daily average MPG over last 30 days',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
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
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
      {'icon': Icons.oil_barrel_outlined, 'name': 'Oil & Filter Change', 'date': 'Oct 24, 2023', 'cost': '\$185.00'},
      {'icon': Icons.tire_repair_outlined, 'name': 'Tire Rotation', 'date': 'Sep 12, 2023', 'cost': '\$80.00'},
      {'icon': Icons.settings_input_component_outlined, 'name': 'Brake Pad Replacement', 'date': 'Aug 05, 2023', 'cost': '\$450.00'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Maintenance',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {},
                child: const Text('View All',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: _primary)),
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
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(item['date'] as String,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
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
                    child: Divider(height: 1, color: Colors.grey.shade100),
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
                const Text('\$715.00',
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
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: filled ? _primary : Colors.grey.shade300),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)
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
  final double value; // 0.0 to 1.0

  _CircleGaugePainter(this.value);

  static const _primary = Color(0xFFEC5B13);

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -3.14159 / 2; // top

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Value arc
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
