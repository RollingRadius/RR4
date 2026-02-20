import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

class FuelConsumptionReportScreen extends StatefulWidget {
  const FuelConsumptionReportScreen({super.key});

  @override
  State<FuelConsumptionReportScreen> createState() =>
      _FuelConsumptionReportScreenState();
}

class _FuelConsumptionReportScreenState
    extends State<FuelConsumptionReportScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  String _selectedPeriod = '1M';
  final _periods = ['Today', '7D', '1M', 'YTD', 'Custom'];

  late final AnimationController _animController;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodFilter(),
                  const SizedBox(height: 20),
                  _buildHeroCard(),
                  const SizedBox(height: 14),
                  _buildKPIRow(),
                  const SizedBox(height: 20),
                  _buildFuelUsageTrend(),
                  const SizedBox(height: 14),
                  _buildInsightCard(),
                  const SizedBox(height: 14),
                  _buildVehiclesSection(),
                  const SizedBox(height: 14),
                  _buildFuelPriceHistory(),
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

  // ─── Sliver App Bar ───────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              size: 18, color: Color(0xFF0F172A)),
        ),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fuel Consumption',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'Report  •  Jan – Jun 2025',
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.normal),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            _animController.forward(from: 0);
            setState(() {});
          },
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.refresh_rounded,
                size: 17, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF1F5F9)),
      ),
    );
  }

  // ─── Period filter ────────────────────────────────────────────────────────

  Widget _buildPeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((p) {
          final active = _selectedPeriod == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedPeriod = p;
                _animController.forward(from: 0);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active ? _primary : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: _primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Hero summary card ────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEC5B13), Color(0xFFD14A0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: big number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.water_drop_rounded,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'TOTAL CONSUMPTION',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '4,250',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  'Litres',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeroBadge(
                      icon: Icons.trending_up_rounded,
                      text: '+5% vs last month',
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right: ring gauge
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) => SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _RingGaugePainter(progress: _progressAnim.value),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '68%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Text(
                        'of budget',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── KPI row ──────────────────────────────────────────────────────────────

  Widget _buildKPIRow() {
    return Row(
      children: [
        Expanded(
          child: _MiniKPI(
            icon: Icons.payments_outlined,
            label: 'Total Cost',
            value: '\$5,120',
            trend: '+12%',
            trendUp: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniKPI(
            icon: Icons.speed_outlined,
            label: 'Avg Economy',
            value: '8.5 km/L',
            trend: '-3%',
            trendUp: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniKPI(
            icon: Icons.eco_outlined,
            label: 'Efficiency',
            value: '72 / 100',
            trend: '+4pts',
            trendUp: true,
            isScore: true,
          ),
        ),
      ],
    );
  }

  // ─── Fuel usage trend ─────────────────────────────────────────────────────

  Widget _buildFuelUsageTrend() {
    return _SectionCard(
      title: 'Fuel Usage Trend',
      subtitle: 'Litres per day',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_down_rounded,
                size: 12, color: Color(0xFF16A34A)),
            SizedBox(width: 3),
            Text('Improving',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A))),
          ],
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) => SizedBox(
              height: 150,
              child: CustomPaint(
                painter: _FuelTrendPainter(progress: _progressAnim.value),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Text(
                      d,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF94A3B8)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              _LegendDot(color: _primary, label: 'This week'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: const Color(0xFFCBD5E1), label: 'Last week'),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Insight callout ──────────────────────────────────────────────────────

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.lightbulb_outline_rounded, color: _primary, size: 16),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'FreightLiner Cascadia consumes 23% above fleet average. Consider scheduling a fuel efficiency inspection.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7C3D12),
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Top vehicles ─────────────────────────────────────────────────────────

  Widget _buildVehiclesSection() {
    const vehicles = [
      (
        name: 'FreightLiner Cascadia',
        litres: 842,
        km: '2,840 km',
        economy: '3.4 km/L',
        rank: 1,
      ),
      (
        name: 'Volvo VHR_603',
        litres: 785,
        km: '2,420 km',
        economy: '3.8 km/L',
        rank: 2,
      ),
      (
        name: 'Kenworth T680',
        litres: 620,
        km: '1,980 km',
        economy: '4.2 km/L',
        rank: 3,
      ),
    ];
    const maxLitres = 842;

    return _SectionCard(
      title: 'Top Consuming Vehicles',
      subtitle: 'Ranked by total fuel usage',
      child: Column(
        children: List.generate(vehicles.length, (i) {
          final v = vehicles[i];
          final pct = v.litres / maxLitres;
          final rankColors = [
            _primary,
            const Color(0xFF64748B),
            const Color(0xFF94A3B8),
          ];
          return Padding(
            padding: EdgeInsets.only(bottom: i < vehicles.length - 1 ? 16 : 0),
            child: AnimatedBuilder(
              animation: _progressAnim,
              builder: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: rankColors[i].withOpacity(i == 0 ? 1 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${v.rank}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: i == 0
                                  ? Colors.white
                                  : rankColors[i],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${v.km}  •  Avg ${v.economy}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${v.litres} L',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${(pct * 100).round()}% of top',
                            style: const TextStyle(
                                fontSize: 9, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 6,
                      color: const Color(0xFFF1F5F9),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor:
                              (pct * _progressAnim.value).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  rankColors[i].withOpacity(0.7),
                                  rankColors[i],
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Fuel price history ───────────────────────────────────────────────────

  Widget _buildFuelPriceHistory() {
    return _SectionCard(
      title: 'Fuel Price History',
      subtitle: '\$ per litre',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.remove_rounded, size: 10, color: _primary),
            SizedBox(width: 3),
            Text(
              'Avg \$1.60/L',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _primary),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (_, __) => SizedBox(
              height: 140,
              child: CustomPaint(
                painter:
                    _FuelPricePainter(progress: _progressAnim.value),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun']
                .map((d) => Text(
                      d,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF94A3B8)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── Export buttons ───────────────────────────────────────────────────────

  Widget _buildExportButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXPORT REPORT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ExportButton(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF Report',
                sub: 'Full formatted report',
                color: _primary,
                filled: true,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ExportButton(
                icon: Icons.table_chart_rounded,
                label: 'Export CSV',
                sub: 'Raw data spreadsheet',
                color: const Color(0xFF475569),
                filled: false,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _HeroBadge(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MiniKPI extends StatelessWidget {
  static const _primary = Color(0xFFEC5B13);

  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool trendUp;
  final bool isScore;

  const _MiniKPI({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    this.isScore = false,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = trendUp
        ? const Color(0xFF16A34A)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: _primary, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: isScore ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                  trendUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 10,
                  color: trendColor),
              const SizedBox(width: 2),
              Text(trend,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: trendColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: filled ? null : Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon,
                    size: 18,
                    color: filled ? Colors.white : color),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: filled ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 10,
                      color: filled
                          ? Colors.white70
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

class _RingGaugePainter extends CustomPainter {
  final double progress;

  const _RingGaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    const strokeW = 8.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // Arc
    final sweepAngle = 2 * math.pi * 0.68 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingGaugePainter old) => old.progress != progress;
}

class _FuelTrendPainter extends CustomPainter {
  static const _primary = Color(0xFFEC5B13);
  static const _secondary = Color(0xFFCBD5E1);

  // This week (normalized 0=top, 1=bottom)
  static const _thisWeek = [0.70, 0.50, 0.80, 0.42, 0.58, 0.33, 0.48];
  // Last week (lighter reference line)
  static const _lastWeek = [0.80, 0.62, 0.88, 0.55, 0.68, 0.45, 0.60];

  final double progress;

  const _FuelTrendPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawLine(canvas, size, _lastWeek, _secondary, dashed: true);
    _drawLine(canvas, size, _thisWeek, _primary, dashed: false);
    _drawDataPoints(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    // Horizontal lines
    for (int i = 1; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Y-axis labels
    const labels = ['840L', '630L', '420L', '210L'];
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < labels.length; i++) {
      tp.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
            fontSize: 8, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w500),
      );
      tp.layout();
      tp.paint(canvas, Offset(0, size.height * (i + 1) / 4 - 9));
    }
  }

  void _drawLine(Canvas canvas, Size size, List<double> pts, Color color,
      {required bool dashed}) {
    final offsets = List.generate(
      pts.length,
      (i) => Offset(
        size.width * i / (pts.length - 1),
        size.height * pts[i],
      ),
    );

    // Clip to animated width
    final clipW = size.width * progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, clipW, size.height));

    if (!dashed) {
      // Fill
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      final fillPath = _smoothPath(offsets)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = dashed ? color.withOpacity(0.5) : color
      ..strokeWidth = dashed ? 1.5 : 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_smoothPath(offsets), linePaint);
    canvas.restore();
  }

  void _drawDataPoints(Canvas canvas, Size size) {
    final offsets = List.generate(
      _thisWeek.length,
      (i) => Offset(
        size.width * i / (_thisWeek.length - 1),
        size.height * _thisWeek[i],
      ),
    );

    // Only show last point (current)
    final last = offsets.last;
    if (progress >= 0.95) {
      canvas.drawCircle(last, 5, Paint()..color = _primary);
      canvas.drawCircle(
          last,
          5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);

      // Value label
      final tp = TextPainter(
        text: const TextSpan(
          text: '280L',
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: _primary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(last.dx - 14, last.dy - 18));
    }
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
  bool shouldRepaint(_FuelTrendPainter old) => old.progress != progress;
}

class _FuelPricePainter extends CustomPainter {
  static const _primary = Color(0xFFEC5B13);

  static const _pts = [0.65, 0.52, 0.68, 0.42, 0.58, 0.35];

  final double progress;

  const _FuelPricePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawAvgLine(canvas, size);
    _drawLine(canvas, size);
    _drawPoints(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawAvgLine(Canvas canvas, Size size) {
    // Dashed avg line at ~47% height
    final y = size.height * 0.47;
    final dashPaint = Paint()
      ..color = _primary.withOpacity(0.35)
      ..strokeWidth = 1.2;

    double x = 0;
    const dashW = 6.0, gapW = 4.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashW, y), dashPaint);
      x += dashW + gapW;
    }
  }

  void _drawLine(Canvas canvas, Size size) {
    final offsets = List.generate(
      _pts.length,
      (i) => Offset(
          size.width * i / (_pts.length - 1), size.height * _pts[i]),
    );

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_primary.withOpacity(0.15), _primary.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final fillPath = _smoothPath(offsets)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(
      _smoothPath(offsets),
      Paint()
        ..color = _primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.restore();
  }

  void _drawPoints(Canvas canvas, Size size) {
    if (progress < 0.9) return;
    const prices = ['\$1.52', '\$1.55', '\$1.58', '\$1.48', '\$1.62', '\$1.65'];
    final offsets = List.generate(
      _pts.length,
      (i) => Offset(
          size.width * i / (_pts.length - 1), size.height * _pts[i]),
    );

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < offsets.length; i++) {
      canvas.drawCircle(offsets[i], 4, Paint()..color = _primary);
      canvas.drawCircle(
          offsets[i],
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);

      tp.text = TextSpan(
        text: prices[i],
        style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569)),
      );
      tp.layout();
      final labelX =
          (offsets[i].dx - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(labelX, offsets[i].dy - 15));
    }
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
  bool shouldRepaint(_FuelPricePainter old) => old.progress != progress;
}
