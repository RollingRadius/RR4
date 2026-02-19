import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FuelConsumptionReportScreen extends StatefulWidget {
  const FuelConsumptionReportScreen({super.key});

  @override
  State<FuelConsumptionReportScreen> createState() =>
      _FuelConsumptionReportScreenState();
}

class _FuelConsumptionReportScreenState
    extends State<FuelConsumptionReportScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  String _selectedPeriod = 'Today';
  final _periods = ['Today', '7D', '1M', 'YTD', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodFilter(),
                  const SizedBox(height: 16),
                  _buildKPICards(),
                  const SizedBox(height: 16),
                  _buildFuelUsageTrend(),
                  const SizedBox(height: 12),
                  _buildFuelPriceHistory(),
                  const SizedBox(height: 16),
                  _buildTopVehicles(),
                  const SizedBox(height: 20),
                  _buildExportButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 10, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Fuel Consumption Report',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: () => setState(() {}),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.refresh_rounded,
                  size: 18, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Period filter ───────────────────────────────────────────────────────────

  Widget _buildPeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((p) {
          final active = _selectedPeriod == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = p),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? _primary : Colors.grey.shade300),
                ),
                child: Text(p,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : Colors.grey.shade600)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── KPI cards ───────────────────────────────────────────────────────────────

  Widget _buildKPICards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FuelKPICard(
                icon: Icons.water_drop_outlined,
                label: 'Total Consumption',
                value: '4,250 L',
                trend: '+5%',
                trendUp: true,
                sub: 'vs last month',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FuelKPICard(
                icon: Icons.payments_outlined,
                label: 'Total Cost',
                value: '\$5,120.00',
                trend: '+12%',
                trendUp: true,
                sub: 'vs last month',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _FuelKPICard(
          icon: Icons.speed_outlined,
          label: 'Avg Fuel Economy',
          value: '8.5 km/L',
          trend: '-3%',
          trendUp: false,
          sub: 'vs last month',
          fullWidth: true,
        ),
      ],
    );
  }

  // ── Fuel usage trend chart ──────────────────────────────────────────────────

  Widget _buildFuelUsageTrend() {
    return _ChartCard(
      title: 'Fuel Usage Trend (Litres)',
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _FuelTrendPainter(),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Text(d,
                    style: TextStyle(
                        fontSize: 9, color: Colors.grey.shade400)))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Fuel price history chart ────────────────────────────────────────────────

  Widget _buildFuelPriceHistory() {
    return _ChartCard(
      title: 'Fuel Price History (\$/L)',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Avg \$1.60',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _primary)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _FuelPricePainter(),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun']
                .map((d) => Text(d,
                    style: TextStyle(
                        fontSize: 9, color: Colors.grey.shade400)))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Top consuming vehicles ──────────────────────────────────────────────────

  Widget _buildTopVehicles() {
    const vehicles = [
      (
        name: 'FreightLiner Cascadia',
        litres: '842 L',
        km: '2,840 km',
        economy: '3.4 km/L',
        rank: 1,
      ),
      (
        name: 'Volvo VHR_603',
        litres: '785 L',
        km: '2,420 km',
        economy: '3.8 km/L',
        rank: 2,
      ),
      (
        name: 'Kenworth T680',
        litres: '620 L',
        km: '1,980 km',
        economy: '4.2 km/L',
        rank: 3,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Consuming Vehicles',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2)),
        const SizedBox(height: 10),
        ...vehicles.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VehicleConsumptionCard(
                rank: v.rank,
                name: v.name,
                litres: v.litres,
                km: v.km,
                economy: v.economy,
              ),
            )),
      ],
    );
  }

  // ── Export buttons ──────────────────────────────────────────────────────────

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Download PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.table_chart_outlined,
                size: 18, color: Colors.grey.shade700),
            label: Text('Export CSV',
                style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _FuelKPICard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool trendUp;
  final String sub;
  final bool fullWidth;

  const _FuelKPICard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.sub,
    this.fullWidth = false,
  });

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    final trendColor =
        trendUp ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                      trendUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 13,
                      color: trendColor),
                  const SizedBox(width: 3),
                  Text(trend,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: trendColor)),
                ],
              ),
              Text(sub,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _ChartCard({
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _VehicleConsumptionCard extends StatelessWidget {
  final int rank;
  final String name;
  final String litres;
  final String km;
  final String economy;

  const _VehicleConsumptionCard({
    required this.rank,
    required this.name,
    required this.litres,
    required this.km,
    required this.economy,
  });

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank == 1
                  ? _primary
                  : _primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$rank',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: rank == 1 ? Colors.white : _primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('$km  •  Avg $economy',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(litres,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text('consumed',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chart painters ────────────────────────────────────────────────────────────

class _FuelTrendPainter extends CustomPainter {
  static const _primary = Color(0xFFEC5B13);

  // Normalized Y values (0=top, 1=bottom)
  static const _pts = [0.70, 0.55, 0.80, 0.45, 0.60, 0.35, 0.50];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_primary.withOpacity(0.2), _primary.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final offsets = List.generate(
      _pts.length,
      (i) => Offset(
        size.width * i / (_pts.length - 1),
        size.height * _pts[i],
      ),
    );

    final path = _smoothPath(offsets);
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Dot on last point
    canvas.drawCircle(offsets.last, 4, Paint()..color = _primary);
    canvas.drawCircle(
        offsets.last, 4, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cpX = (pts[i].dx + pts[i + 1].dx) / 2;
      path.cubicTo(
          cpX, pts[i].dy, cpX, pts[i + 1].dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_FuelTrendPainter old) => false;
}

class _FuelPricePainter extends CustomPainter {
  static const _primary = Color(0xFFEC5B13);

  static const _pts = [0.60, 0.50, 0.65, 0.40, 0.55, 0.35];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_primary.withOpacity(0.18), _primary.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Average line
    final avgPaint = Paint()
      ..color = _primary.withOpacity(0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.47),
        Offset(size.width, size.height * 0.47), avgPaint);

    final offsets = List.generate(
      _pts.length,
      (i) => Offset(
        size.width * i / (_pts.length - 1),
        size.height * _pts[i],
      ),
    );

    final path = _smoothPath(offsets);
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cpX = (pts[i].dx + pts[i + 1].dx) / 2;
      path.cubicTo(
          cpX, pts[i].dy, cpX, pts[i + 1].dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_FuelPricePainter old) => false;
}
