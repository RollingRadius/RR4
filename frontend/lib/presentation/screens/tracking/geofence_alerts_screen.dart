import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GeofenceAlertsScreen extends StatefulWidget {
  const GeofenceAlertsScreen({super.key});

  @override
  State<GeofenceAlertsScreen> createState() => _GeofenceAlertsScreenState();
}

class _GeofenceAlertsScreenState extends State<GeofenceAlertsScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  final _searchController = TextEditingController();

  final _zones = [
    _GeofenceZone(name: 'Downtown Hub', type: 'Circular • 500m radius', active: true),
    _GeofenceZone(name: 'Service Center A', type: 'Polygon • Industrial Park', active: true),
  ];

  final _alerts = [
    _AlertItem(
      name: 'John Doe (Truck #402)',
      action: 'Exited',
      zone: 'Downtown Hub',
      time: '2 mins ago',
      severity: _Severity.critical,
      isExit: true,
    ),
    _AlertItem(
      name: 'Sarah Jenkins (Van #12)',
      action: 'Entered',
      zone: 'Service Center A',
      time: '15 mins ago',
      severity: _Severity.routine,
      isExit: false,
    ),
    _AlertItem(
      name: 'Mike Ross (HGV #88)',
      action: 'Exited',
      zone: 'Restricted Zone B',
      time: '42 mins ago',
      severity: _Severity.violation,
      isExit: true,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(),
                  _buildActiveGeofences(context),
                  _buildAlertsFeed(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _bg.withOpacity(0.9),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 12),
      child: Column(
        children: [
          // Title row with back button
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6)
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.hub_rounded, color: _primary, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Geofences & Alerts',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/tracking/geofences'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick navigation chips
          Row(
            children: [
              _QuickNavChip(
                icon: Icons.local_shipping_outlined,
                label: 'Fleet',
                onTap: () => context.go('/fleet-hub'),
              ),
              const SizedBox(width: 8),
              _QuickNavChip(
                icon: Icons.map_outlined,
                label: 'Live Map',
                onTap: () => context.push('/tracking/live'),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
                hintText: 'Search geofences or vehicles...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.crop_square_rounded,
              label: 'Active Zones',
              value: '24',
              sub: '+2 this week',
              subColor: const Color(0xFF16A34A),
              subIcon: Icons.trending_up,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.notifications_active_outlined,
              label: 'Alerts (24h)',
              value: '12',
              sub: '3 high priority',
              subColor: const Color(0xFFEF4444),
              subIcon: Icons.warning_amber_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGeofences(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Geofences',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('See All',
                    style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _zones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _GeofenceCard(
                  zone: _zones[i],
                  onViewMap: () => context.push('/tracking/live')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsFeed(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Alerts Feed',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.filter_list_rounded,
                    color: _primary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._alerts.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AlertCard(alert: a),
              )),
        ],
      ),
    );
  }

}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color subColor;
  final IconData subIcon;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.subColor,
    required this.subIcon,
  });

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primary.withOpacity(0.12)),
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
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5)),
              Icon(icon, color: _primary, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(subIcon, size: 12, color: subColor),
              const SizedBox(width: 3),
              Text(sub,
                  style: TextStyle(fontSize: 11, color: subColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeofenceCard extends StatelessWidget {
  final _GeofenceZone zone;
  final VoidCallback onViewMap;

  const _GeofenceCard({required this.zone, required this.onViewMap});

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primary.withOpacity(0.1)),
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
                    Text(zone.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(zone.type,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: zone.active,
                onChanged: (_) {},
                activeColor: _primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: _MiniMapPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onViewMap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, color: _primary, size: 14),
                  SizedBox(width: 5),
                  Text('View on Map',
                      style: TextStyle(
                          color: _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final _AlertItem alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isExit = alert.isExit;
    final borderColor = isExit ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final iconColor = isExit ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final iconBg = isExit
        ? const Color(0xFFEF4444).withOpacity(0.1)
        : const Color(0xFF22C55E).withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
                isExit ? Icons.logout_rounded : Icons.login_rounded,
                color: iconColor,
                size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(alert.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(alert.time,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 3),
                Text.rich(TextSpan(
                  children: [
                    TextSpan(
                        text: alert.action,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(
                        text: ' ${alert.zone}',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                  style: const TextStyle(fontSize: 12),
                )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SeverityBadge(alert.severity),
                    const SizedBox(width: 10),
                    Text(
                      alert.severity == _Severity.critical
                          ? 'Track Live'
                          : alert.severity == _Severity.routine
                              ? 'View Log'
                              : 'Dispatch Team',
                      style: const TextStyle(
                          color: Color(0xFFEC5B13),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline),
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
}

class _SeverityBadge extends StatelessWidget {
  final _Severity severity;
  const _SeverityBadge(this.severity);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (severity) {
      case _Severity.critical:
        color = const Color(0xFFEF4444);
        label = 'CRITICAL';
        break;
      case _Severity.routine:
        color = const Color(0xFF22C55E);
        label = 'ROUTINE';
        break;
      case _Severity.violation:
        color = const Color(0xFFEF4444);
        label = 'VIOLATION';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5)),
    );
  }
}

class _QuickNavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickNavChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primary.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _primary, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primary)),
          ],
        ),
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  static const _primary = Color(0xFFEC5B13);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;
    const sp = 12.0;
    for (double x = 0; x < size.width; x += sp) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += sp) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final fill = Paint()
      ..color = _primary.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = _primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final pts = [
      Offset(size.width * 0.25, size.height * 0.2),
      Offset(size.width * 0.75, size.height * 0.25),
      Offset(size.width * 0.7, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.75),
    ];

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_MiniMapPainter old) => false;
}

// Data models
class _GeofenceZone {
  final String name;
  final String type;
  final bool active;
  _GeofenceZone({required this.name, required this.type, required this.active});
}

class _AlertItem {
  final String name;
  final String action;
  final String zone;
  final String time;
  final _Severity severity;
  final bool isExit;

  _AlertItem({
    required this.name,
    required this.action,
    required this.zone,
    required this.time,
    required this.severity,
    required this.isExit,
  });
}

enum _Severity { critical, routine, violation }
