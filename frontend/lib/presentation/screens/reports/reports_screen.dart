import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  // ─── Colors ─────────────────────────────────────────────────────────────────
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  // ─── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _ctrl;

  late final Animation<double> _fadeHeader;
  late final Animation<Offset> _slideHeader;
  late final Animation<double> _fadeSummary;
  late final Animation<Offset> _slideSummary;
  late final Animation<double> _fadeFilter;
  late final Animation<Offset> _slideFilter;
  late final Animation<double> _fadeKPI;
  late final Animation<Offset> _slideKPI;
  late final Animation<double> _fadeCharts;
  late final Animation<Offset> _slideCharts;
  late final Animation<double> _fadeCats;
  late final Animation<Offset> _slideCats;
  late final Animation<double> _chartProgress;

  String _selectedPeriod = 'Month';

  Animation<double> _f(double s, double e) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _ctrl, curve: Interval(s, e, curve: Curves.easeOut)),
      );

  Animation<Offset> _s(double s, double e) =>
      Tween<Offset>(
              begin: const Offset(0, 0.18), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _ctrl, curve: Interval(s, e, curve: Curves.easeOut)));

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));

    _fadeHeader = _f(0.00, 0.28);
    _slideHeader = _s(0.00, 0.28);
    _fadeSummary = _f(0.08, 0.38);
    _slideSummary = _s(0.08, 0.38);
    _fadeFilter = _f(0.16, 0.44);
    _slideFilter = _s(0.16, 0.44);
    _fadeKPI = _f(0.24, 0.52);
    _slideKPI = _s(0.24, 0.52);
    _fadeCharts = _f(0.32, 0.62);
    _slideCharts = _s(0.32, 0.62);
    _fadeCats = _f(0.46, 0.80);
    _slideCats = _s(0.46, 0.80);
    _chartProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.36, 0.92, curve: Curves.easeInOut)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _anim(Animation<double> fade, Animation<Offset> slide, Widget child) =>
      FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child));

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _anim(_fadeSummary, _slideSummary, _buildSummaryBanner()),
                const SizedBox(height: 14),
                _anim(_fadeFilter, _slideFilter, _buildPeriodFilter()),
                const SizedBox(height: 16),
                _anim(_fadeKPI, _slideKPI, _buildKPIRow()),
                const SizedBox(height: 14),
                _anim(_fadeCharts, _slideCharts, _buildRevenueChart()),
                const SizedBox(height: 12),
                _anim(_fadeCharts, _slideCharts, _buildUtilizationChart()),
                const SizedBox(height: 22),
                _anim(_fadeCats, _slideCats, _buildPinnedReports(context)),
                const SizedBox(height: 22),
                _anim(_fadeCats, _slideCats, _buildReportCategories(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return _anim(
      _fadeHeader,
      _slideHeader,
      Container(
        color: _bg,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEC5B13), Color(0xFFBF4209)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
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
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              // Notification bell
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(Icons.notifications_outlined,
                        color: Colors.grey.shade600, size: 20),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Export button
              Container(
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: _primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      child: Row(
                        children: [
                          Icon(Icons.download_rounded,
                              color: Colors.white, size: 15),
                          SizedBox(width: 5),
                          Text('Export',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary banner ────────────────────────────────────────────────────────────

  Widget _buildSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEC5B13), Color(0xFFBF4209)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -16,
            bottom: -16,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: -10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PERIOD SUMMARY',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8),
                    ),
                  ),
                  const Spacer(),
                  const Text('Jan – Jun 2025',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _SummaryMetric(
                      label: 'Revenue',
                      value: '\$124.5K',
                      trend: '+12.5%',
                      up: true),
                  _VDivider(),
                  _SummaryMetric(
                      label: 'Trips',
                      value: '847',
                      trend: '+8.2%',
                      up: true),
                  _VDivider(),
                  _SummaryMetric(
                      label: 'Efficiency',
                      value: '88%',
                      trend: '+4.1%',
                      up: true),
                  _VDivider(),
                  _SummaryMetric(
                      label: 'Fuel/gal',
                      value: '\$3.82',
                      trend: '-2.1%',
                      up: false),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Period filter ─────────────────────────────────────────────────────────────

  Widget _buildPeriodFilter() {
    const periods = ['Today', 'Week', 'Month', 'Year'];
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: periods.map((p) {
                final sel = _selectedPeriod == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: sel ? _primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: _primary.withOpacity(0.25),
                                    blurRadius: 6)
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(p,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : Colors.grey.shade500)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 5),
              Text('Filter',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  // ── KPI row ───────────────────────────────────────────────────────────────────

  Widget _buildKPIRow() {
    return Row(
      children: [
        Expanded(
          child: _KPICard(
            label: 'Revenue',
            value: '\$124.5K',
            trend: '+12.5%',
            up: true,
            icon: Icons.payments_rounded,
            accent: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KPICard(
            label: 'Fuel Cost',
            value: '\$3.82/gal',
            trend: '-2.1%',
            up: false,
            icon: Icons.local_gas_station_rounded,
            accent: _primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KPICard(
            label: 'Utilization',
            value: '88%',
            trend: '+4.2%',
            up: true,
            icon: Icons.rv_hookup_rounded,
            accent: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }

  // ── Revenue vs Expenses chart ─────────────────────────────────────────────────

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue vs Expenses',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Jan – May 2025',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              _LegendDot(color: _primary, label: 'Revenue'),
              const SizedBox(width: 10),
              _LegendDot(color: Color(0xFFCBD5E1), label: 'Expenses'),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _chartProgress,
            builder: (_, __) => SizedBox(
              height: 150,
              child: CustomPaint(
                painter:
                    _RevenueBarPainter(progress: _chartProgress.value),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Utilization trend chart ───────────────────────────────────────────────────

  Widget _buildUtilizationChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fleet Utilization Trend',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Last 7 days',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.trending_up_rounded,
                        size: 12, color: Color(0xFF16A34A)),
                    SizedBox(width: 3),
                    Text('Stable',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _chartProgress,
            builder: (_, __) => SizedBox(
              height: 110,
              child: CustomPaint(
                painter: _UtilizationLinePainter(
                    progress: _chartProgress.value),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((d) => Text(d,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400)))
                    .toList(),
          ),
        ],
      ),
    );
  }

  // ── Pinned reports ────────────────────────────────────────────────────────────

  Widget _buildPinnedReports(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Pinned Reports',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('1',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FeaturedCard(
          title: 'Fuel Consumption',
          subtitle:
              'Full analysis of fuel usage, costs, and vehicle efficiency across your fleet.',
          period: 'Jan – Jun 2025',
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEC5B13), Color(0xFFBF4209)],
          ),
          icon: Icons.local_gas_station_rounded,
          statsLabel: '4,250 L',
          statsDesc: 'Total consumed',
          onTap: () => context.push('/reports/fuel'),
        ),
      ],
    );
  }

  // ── Report categories ─────────────────────────────────────────────────────────

  Widget _buildReportCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('All Reports',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2)),
        const SizedBox(height: 14),
        _CategoryCard(
          icon: Icons.settings_applications_rounded,
          label: 'Operational',
          color: const Color(0xFF6366F1),
          items: [
            _ReportItem(
              icon: Icons.route_rounded,
              title: 'Trip Efficiency',
              subtitle: 'Route performance data',
              color: const Color(0xFF6366F1),
              onTap: () {},
            ),
            _ReportItem(
              icon: Icons.timer_off_rounded,
              title: 'Idle Time',
              subtitle: 'Engine run duration vs stop',
              color: const Color(0xFF6366F1),
              onTap: () {},
            ),
            _ReportItem(
              icon: Icons.speed_rounded,
              title: 'Driver Behavior',
              subtitle: 'Speed, braking & acceleration',
              color: const Color(0xFF6366F1),
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CategoryCard(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Financial',
          color: const Color(0xFF10B981),
          items: [
            _ReportItem(
              icon: Icons.local_gas_station_rounded,
              title: 'Fuel Consumption',
              subtitle: 'Gallons/Mile analysis',
              color: const Color(0xFF10B981),
              onTap: () => context.push('/reports/fuel'),
            ),
            _ReportItem(
              icon: Icons.build_rounded,
              title: 'Maintenance Spend',
              subtitle: 'Repair & service costs',
              color: const Color(0xFF10B981),
              onTap: () {},
            ),
            _ReportItem(
              icon: Icons.receipt_long_rounded,
              title: 'Cost Per Mile',
              subtitle: 'Total fleet operating costs',
              color: const Color(0xFF10B981),
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CategoryCard(
          icon: Icons.verified_user_rounded,
          label: 'Compliance',
          color: const Color(0xFFF59E0B),
          items: [
            _ReportItem(
              icon: Icons.access_time_rounded,
              title: 'HOS Violations',
              subtitle: 'Hours of Service logs',
              color: const Color(0xFFF59E0B),
              onTap: () {},
            ),
            _ReportItem(
              icon: Icons.fact_check_rounded,
              title: 'Inspection Pass Rate',
              subtitle: 'DOT inspection history',
              color: const Color(0xFFF59E0B),
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  BoxDecoration _card() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryMetric extends StatelessWidget {
  final String label, value, trend;
  final bool up;

  const _SummaryMetric(
      {required this.label,
      required this.value,
      required this.trend,
      required this.up});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                up
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 9,
                color: up
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFFCA5A5),
              ),
              const SizedBox(width: 2),
              Text(trend,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: up
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5))),
            ],
          ),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withOpacity(0.2),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String label, value, trend;
  final bool up;
  final IconData icon;
  final Color accent;

  const _KPICard({
    required this.label,
    required this.value,
    required this.trend,
    required this.up,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final tc = up ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 76,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 13, color: accent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                          up
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 11,
                          color: tc),
                      const SizedBox(width: 2),
                      Text(trend,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: tc)),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured pinned report card
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedCard extends StatefulWidget {
  final String title, subtitle, period, statsLabel, statsDesc;
  final LinearGradient gradient;
  final IconData icon;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.title,
    required this.subtitle,
    required this.period,
    required this.gradient,
    required this.icon,
    required this.statsLabel,
    required this.statsDesc,
    required this.onTap,
  });

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
        lowerBound: 0.97,
        upperBound: 1.0,
        value: 1.0);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _press,
      child: GestureDetector(
        onTapDown: (_) => _press.reverse(),
        onTapUp: (_) {
          _press.forward();
          widget.onTap();
        },
        onTapCancel: () => _press.forward(),
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFEC5B13).withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(widget.icon,
                    size: 130,
                    color: Colors.white.withOpacity(0.07)),
              ),
              Positioned(
                right: 30,
                top: -12,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Icon(widget.icon,
                                    color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(widget.title,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold)),
                                  Text(widget.period,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(widget.subtitle,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.45)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(widget.statsLabel,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(widget.statsDesc,
                                  style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 9)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('View →',
                              style: TextStyle(
                                  color: Color(0xFFEC5B13),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category card
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final List<_ReportItem> items;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          // Header strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 15),
                ),
                const SizedBox(width: 8),
                Text(label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.8)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${items.length}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ),
              ],
            ),
          ),
          // Items
          ...items.asMap().entries.map((e) => Column(
                children: [
                  if (e.key > 0)
                    Divider(
                        height: 1, color: Colors.grey.shade100),
                  e.value,
                ],
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report item row (with press-to-scale)
// ─────────────────────────────────────────────────────────────────────────────

class _ReportItem extends StatefulWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReportItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ReportItem> createState() => _ReportItemState();
}

class _ReportItemState extends State<_ReportItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.97,
        upperBound: 1.0,
        value: 1.0);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _press,
      child: GestureDetector(
        onTapDown: (_) => _press.reverse(),
        onTapUp: (_) {
          _press.forward();
          widget.onTap();
        },
        onTapCancel: () => _press.forward(),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(widget.icon, color: widget.color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart painters
// ─────────────────────────────────────────────────────────────────────────────

class _RevenueBarPainter extends CustomPainter {
  static const _primary = Color(0xFFEC5B13);
  final double progress;

  const _RevenueBarPainter({required this.progress});

  static const _data = [
    [0.60, 0.85],
    [0.55, 0.70],
    [0.65, 0.90],
    [0.45, 0.60],
    [0.70, 0.95],
  ];
  static const _labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
  static const _yVals = ['0', '25K', '50K', '75K', '100K'];

  @override
  void paint(Canvas canvas, Size size) {
    const barGroups = 5;
    // reserve 32px left for y-axis labels, 20px bottom for month labels
    const leftPad = 34.0;
    const bottomPad = 20.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad;
    final groupW = chartW / barGroups;
    const barW = 11.0;
    const gap = 5.0;

    // Grid lines + Y labels
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;
    final yStyle =
        TextStyle(fontSize: 9, color: Colors.grey.shade400);
    for (int i = 0; i <= 4; i++) {
      final y = chartH * (1 - i / 4);
      canvas.drawLine(
          Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: _yVals[i], style: yStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(leftPad - tp.width - 4, y - tp.height / 2));
    }

    final revPaint = Paint()..color = _primary;
    final expPaint = Paint()..color = const Color(0xFFCBD5E1);
    final monthStyle =
        TextStyle(fontSize: 9, color: Colors.grey.shade500);

    for (int i = 0; i < barGroups; i++) {
      final cx = leftPad + groupW * i + groupW / 2;
      final expH = _data[i][0] * chartH * progress;
      final revH = _data[i][1] * chartH * progress;

      // Expense bar
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - gap / 2 - barW, chartH - expH, barW, expH),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        expPaint,
      );
      // Revenue bar
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx + gap / 2, chartH - revH, barW, revH),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        revPaint,
      );

      // Revenue value label on top
      if (progress > 0.8) {
        final vPct = (_data[i][1] * 100).round();
        final valTp = TextPainter(
          text: TextSpan(
              text: '\$$vPct K',
              style: TextStyle(
                  fontSize: 8,
                  color: _primary,
                  fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        valTp.paint(
            canvas,
            Offset(cx + gap / 2 + barW / 2 - valTp.width / 2,
                chartH - revH - valTp.height - 2));
      }

      // Month label
      final tp = TextPainter(
        text: TextSpan(text: _labels[i], style: monthStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(cx - tp.width / 2, chartH + 5));
    }
  }

  @override
  bool shouldRepaint(_RevenueBarPainter old) =>
      old.progress != progress;
}

class _UtilizationLinePainter extends CustomPainter {
  static const _primary = Color(0xFFEC5B13);
  final double progress;

  const _UtilizationLinePainter({required this.progress});

  static const _rawPts = [0.80, 0.30, 0.55, 0.25, 0.60, 0.38, 0.12];

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final n = _rawPts.length;
    final allOffsets = List.generate(
        n,
        (i) => Offset(
            size.width * i / (n - 1), size.height * _rawPts[i]));

    final visF = (n * progress).clamp(1.0, n.toDouble());
    final visInt = visF.floor();
    final extra = visF - visInt;

    List<Offset> pts;
    if (visInt < n) {
      pts = allOffsets.sublist(0, visInt);
      if (extra > 0) {
        final a = allOffsets[visInt - 1];
        final b = allOffsets[math.min(visInt, n - 1)];
        pts = [...pts, Offset(a.dx + (b.dx - a.dx) * extra, a.dy + (b.dy - a.dy) * extra)];
      }
    } else {
      pts = allOffsets;
    }

    if (pts.length < 2) return;

    final linePaint = Paint()
      ..color = _primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      final cp = (pts[i - 1].dx + pts[i].dx) / 2;
      linePath.cubicTo(cp, pts[i - 1].dy, cp, pts[i].dy, pts[i].dx, pts[i].dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _primary.withOpacity(0.15),
            _primary.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(linePath, linePaint);

    // Dot at current tip
    canvas.drawCircle(pts.last, 6, Paint()..color = Colors.white);
    canvas.drawCircle(pts.last, 4, Paint()..color = _primary);

    // Y labels
    final yStyle = TextStyle(fontSize: 9, color: Colors.grey.shade400);
    for (final e in {'100%': 0.0, '50%': 0.5, '0%': 1.0}.entries) {
      final tp = TextPainter(
        text: TextSpan(text: e.key, style: yStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(0, size.height * e.value - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_UtilizationLinePainter old) =>
      old.progress != progress;
}
