import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  String _selectedPeriod = 'Today';
  final _periods = ['Today', '7D', '1M', 'YTD'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodFilter(),
                const SizedBox(height: 16),
                _buildKPIRow(),
                const SizedBox(height: 16),
                _buildRevenueChart(),
                const SizedBox(height: 12),
                _buildUtilizationChart(),
                const SizedBox(height: 20),
                _buildReportCategories(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fleet Insights',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3)),
                  Text('Analytics & Reports',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Export All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Period filter ───────────────────────────────────────────────────────────

  Widget _buildPeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._periods.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: _selectedPeriod == p ? _primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _selectedPeriod == p
                              ? _primary
                              : Colors.grey.shade300),
                    ),
                    child: Text(p,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedPeriod == p
                                ? Colors.white
                                : Colors.grey.shade600)),
                  ),
                ),
              )),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 5),
                Text('Custom',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI cards ───────────────────────────────────────────────────────────────

  Widget _buildKPIRow() {
    return Row(
      children: [
        Expanded(
          child: _KPICard(
            label: 'Total Revenue',
            value: '\$124,500',
            trend: '+12.5%',
            up: true,
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KPICard(
            label: 'Avg Fuel Cost',
            value: '\$3.82/gal',
            trend: '-2.1%',
            up: false,
            icon: Icons.local_gas_station_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KPICard(
            label: 'Fleet Util.',
            value: '88%',
            trend: '+4.2%',
            up: true,
            icon: Icons.rv_hookup_outlined,
          ),
        ),
      ],
    );
  }

  // ── Revenue vs Expenses bar chart ───────────────────────────────────────────

  Widget _buildRevenueChart() {
    return _ChartCard(
      title: 'Revenue vs Expenses',
      trailing: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text('Revenue',
              style:
                  TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          const SizedBox(width: 8),
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Text('Expenses',
              style:
                  TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
      child: SizedBox(
        height: 140,
        child: CustomPaint(
          painter: _RevenueBarPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }

  // ── Utilization trend line chart ─────────────────────────────────────────────

  Widget _buildUtilizationChart() {
    return _ChartCard(
      title: 'Utilization Trend',
      trailing: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Stable',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A))),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: CustomPaint(
              painter: _UtilizationLinePainter(),
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

  // ── Report categories ───────────────────────────────────────────────────────

  Widget _buildReportCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Report Categories',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3)),
        const SizedBox(height: 14),
        _CategorySection(
          icon: Icons.settings_applications_rounded,
          label: 'OPERATIONAL',
          items: [
            _ReportTile(
                title: 'Trip Efficiency',
                subtitle: 'Route performance data',
                onTap: () {}),
            _ReportTile(
                title: 'Idle Time',
                subtitle: 'Engine run duration vs stop',
                onTap: () {}),
          ],
        ),
        const SizedBox(height: 12),
        _CategorySection(
          icon: Icons.account_balance_wallet_outlined,
          label: 'FINANCIAL',
          items: [
            _ReportTile(
                title: 'Fuel Consumption',
                subtitle: 'Gallons/Mile analysis',
                onTap: () => context.push('/reports/fuel')),
            _ReportTile(
                title: 'Maintenance Spend',
                subtitle: 'Repair & service costs',
                onTap: () {}),
          ],
        ),
        const SizedBox(height: 12),
        _CategorySection(
          icon: Icons.verified_user_outlined,
          label: 'COMPLIANCE',
          items: [
            _ReportTile(
                title: 'HOS Violations',
                subtitle: 'Hours of Service logs',
                onTap: () {}),
            _ReportTile(
                title: 'Inspection Pass Rate',
                subtitle: 'DOT inspection history',
                onTap: () {}),
          ],
        ),
      ],
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _KPICard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool up;
  final IconData icon;

  const _KPICard({
    required this.label,
    required this.value,
    required this.trend,
    required this.up,
    required this.icon,
  });

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    final trendColor =
        up ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    return Container(
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
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(icon, size: 36, color: _primary.withOpacity(0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                      up
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: trendColor),
                  const SizedBox(width: 3),
                  Text(trend,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: trendColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget trailing;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.trailing,
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
                      fontSize: 15, fontWeight: FontWeight.bold)),
              trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<_ReportTile> items;

  const _CategorySection({
    required this.icon,
    required this.label,
    required this.items,
  });

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _primary, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((tile) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: tile,
            )),
      ],
    );
  }
}

class _ReportTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03), blurRadius: 4)
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Chart painters ────────────────────────────────────────────────────────────

class _RevenueBarPainter extends CustomPainter {
  static const _primary = Color(0xFFEC5B13);

  // [expense%, revenue%] per month
  static const _data = [
    [0.60, 0.85],
    [0.55, 0.70],
    [0.65, 0.90],
    [0.45, 0.60],
    [0.70, 0.95],
  ];
  static const _labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];

  @override
  void paint(Canvas canvas, Size size) {
    const barGroups = 5;
    final groupW = size.width / barGroups;
    const barW = 10.0;
    const gap = 4.0;
    final maxH = size.height - 20;

    final revPaint = Paint()..color = _primary;
    final expPaint = Paint()..color = const Color(0xFFCBD5E1);
    final labelStyle = TextStyle(
        fontSize: 9, color: Colors.grey.shade500);

    for (int i = 0; i < barGroups; i++) {
      final cx = groupW * i + groupW / 2;
      final expH = _data[i][0] * maxH;
      final revH = _data[i][1] * maxH;

      // Expense bar
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - gap / 2 - barW, maxH - expH, barW, expH),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        expPaint,
      );

      // Revenue bar
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx + gap / 2, maxH - revH, barW, revH),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        revPaint,
      );

      // Month label
      final tp = TextPainter(
        text: TextSpan(text: _labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, maxH + 5));
    }
  }

  @override
  bool shouldRepaint(_RevenueBarPainter old) => false;
}

class _UtilizationLinePainter extends CustomPainter {
  static const _primary = Color(0xFFEC5B13);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _primary.withOpacity(0.18),
          _primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Normalize path: M0 80 Q25 20 50 50 T100 10 (viewBox 100x100)
    final pts = [
      Offset(0, size.height * 0.80),
      Offset(size.width * 0.25, size.height * 0.20),
      Offset(size.width * 0.50, size.height * 0.50),
      Offset(size.width * 0.75, size.height * 0.30),
      Offset(size.width * 1.00, size.height * 0.10),
    ];

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    path.cubicTo(
      pts[1].dx, pts[1].dy,
      pts[2].dx, pts[2].dy,
      pts[2].dx, pts[2].dy,
    );
    path.cubicTo(
      pts[3].dx, pts[3].dy,
      pts[4].dx, pts[4].dy,
      pts[4].dx, pts[4].dy,
    );

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Y-axis labels
    final labelStyle = TextStyle(fontSize: 9, color: Colors.grey.shade400);
    for (final entry in {'100%': 0.0, '50%': 0.5, '0%': 1.0}.entries) {
      final tp = TextPainter(
        text: TextSpan(text: entry.key, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, size.height * entry.value - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_UtilizationLinePainter old) => false;
}
