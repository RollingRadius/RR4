import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

class FleetHubScreen extends StatefulWidget {
  const FleetHubScreen({super.key});

  @override
  State<FleetHubScreen> createState() => _FleetHubScreenState();
}

class _FleetHubScreenState extends State<FleetHubScreen>
    with SingleTickerProviderStateMixin {
  // ─── Animation setup ───────────────────────────────────────────────────────
  late final AnimationController _ctrl;

  // Staggered intervals: each item fades + slides in at a slightly later time
  late final Animation<double> _fadeHeader;
  late final Animation<Offset> _slideHeader;

  late final Animation<double> _fadeBanner;
  late final Animation<Offset> _slideBanner;

  late final Animation<double> _fadeCard1;
  late final Animation<Offset> _slideCard1;

  late final Animation<double> _fadeCard2;
  late final Animation<Offset> _slideCard2;

  late final Animation<double> _fadeActions;
  late final Animation<Offset> _slideActions;

  late final Animation<double> _fadeAlerts;
  late final Animation<Offset> _slideAlerts;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    Animation<double> _fade(double start, double end) =>
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        );

    Animation<Offset> _slide(double start, double end) =>
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );

    _fadeHeader  = _fade(0.00, 0.35);
    _slideHeader = _slide(0.00, 0.35);

    _fadeBanner  = _fade(0.10, 0.45);
    _slideBanner = _slide(0.10, 0.45);

    _fadeCard1   = _fade(0.20, 0.55);
    _slideCard1  = _slide(0.20, 0.55);

    _fadeCard2   = _fade(0.30, 0.65);
    _slideCard2  = _slide(0.30, 0.65);

    _fadeActions = _fade(0.40, 0.75);
    _slideActions = _slide(0.40, 0.75);

    _fadeAlerts  = _fade(0.50, 0.85);
    _slideAlerts = _slide(0.50, 0.85);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AnimItem(fade: _fadeHeader, slide: _slideHeader, child: _buildHeader()),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AnimItem(
                  fade: _fadeBanner,
                  slide: _slideBanner,
                  child: _buildSummaryBanner(),
                ),
                const SizedBox(height: 22),
                _AnimItem(
                  fade: _fadeCard1,
                  slide: _slideCard1,
                  child: _SectionLabel(label: 'MANAGE'),
                ),
                const SizedBox(height: 10),
                _AnimItem(
                  fade: _fadeCard1,
                  slide: _slideCard1,
                  child: _HubCard(
                    icon: Icons.local_shipping_rounded,
                    color: AppTheme.primaryBlue,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC5B13), Color(0xFFD14A0A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    title: 'Fleet Vehicles',
                    description: 'Track, add and manage all vehicles',
                    count: '12',
                    countLabel: 'Total vehicles',
                    chips: const [
                      _Chip(label: '10 Active', color: Color(0xFF22C55E)),
                      _Chip(label: '2 In Service', color: Color(0xFFF59E0B)),
                    ],
                    onTap: () => context.push('/vehicles'),
                  ),
                ),
                const SizedBox(height: 12),
                _AnimItem(
                  fade: _fadeCard2,
                  slide: _slideCard2,
                  child: _HubCard(
                    icon: Icons.badge_rounded,
                    color: const Color(0xFF7C3AED),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    title: 'Workers',
                    description: 'Drivers, assignments and onboarding',
                    count: '8',
                    countLabel: 'Total drivers',
                    chips: const [
                      _Chip(label: '6 Active', color: Color(0xFF7C3AED)),
                      _Chip(label: '1 Pending', color: Color(0xFF94A3B8)),
                    ],
                    onTap: () => context.push('/drivers'),
                  ),
                ),
                const SizedBox(height: 22),
                _AnimItem(
                  fade: _fadeActions,
                  slide: _slideActions,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel(label: 'QUICK ACTIONS'),
                      const SizedBox(height: 10),
                      _buildQuickActions(context),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _AnimItem(
                  fade: _fadeAlerts,
                  slide: _slideAlerts,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel(label: 'RECENT ALERTS'),
                      const SizedBox(height: 10),
                      _buildAlerts(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC5B13), Color(0xFFD14A0A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.assignment_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fleet & Workers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Manage your fleet and team',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Alert badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3ED),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.notifications_outlined,
                          color: AppTheme.primaryBlue, size: 20),
                    ),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Center(
                          child: Text('1',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Summary banner ────────────────────────────────────────────────────────

  Widget _buildSummaryBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              value: '12',
              label: 'Vehicles',
              icon: Icons.local_shipping_rounded,
              color: AppTheme.primaryBlue,
            ),
          ),
          _VSeparator(),
          Expanded(
            child: _SummaryTile(
              value: '8',
              label: 'Drivers',
              icon: Icons.badge_rounded,
              color: const Color(0xFF7C3AED),
            ),
          ),
          _VSeparator(),
          Expanded(
            child: _SummaryTile(
              value: '1',
              label: 'Alerts',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFEF4444),
            ),
          ),
          _VSeparator(),
          Expanded(
            child: _SummaryTile(
              value: '94%',
              label: 'Uptime',
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick actions grid ────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    const actions = [
      (
        icon: Icons.add_road_rounded,
        label: 'Add Vehicle',
        color: Color(0xFFEC5B13),
        route: '/vehicles/add',
      ),
      (
        icon: Icons.person_add_rounded,
        label: 'Add Driver',
        color: Color(0xFF7C3AED),
        route: '/drivers/add',
      ),
      (
        icon: Icons.map_rounded,
        label: 'Live Map',
        color: Color(0xFF059669),
        route: '/tracking/live',
      ),
      (
        icon: Icons.my_location_rounded,
        label: 'Geofences',
        color: Color(0xFFF59E0B),
        route: '/tracking/geofence-alerts',
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 0,
      crossAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: actions.map((a) {
        return _QuickActionTile(
          icon: a.icon,
          label: a.label,
          color: a.color,
          onTap: () => context.push(a.route),
        );
      }).toList(),
    );
  }

  // ─── Alerts strip ──────────────────────────────────────────────────────────

  Widget _buildAlerts() {
    const alerts = [
      (
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFEF4444),
        bg: Color(0xFFFEE2E2),
        title: 'Engine Overheat',
        sub: 'Truck-102  •  Just now',
      ),
      (
        icon: Icons.build_circle_rounded,
        color: Color(0xFFF59E0B),
        bg: Color(0xFFFEF3C7),
        title: 'Service Due Soon',
        sub: 'Van-018  •  2 days left',
      ),
    ];

    return Column(
      children: alerts.map((a) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: a.bg),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: a.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a.icon, color: a.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              )),
                          const SizedBox(height: 2),
                          Text(a.sub,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary, size: 18),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _AnimItem extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget child;

  const _AnimItem(
      {required this.fade, required this.slide, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _VSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: const Color(0xFFF1F5F9),
    );
  }
}

// ─── Hub Card ─────────────────────────────────────────────────────────────────

class _HubCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final String title;
  final String description;
  final String count;
  final String countLabel;
  final List<_Chip> chips;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.color,
    required this.gradient,
    required this.title,
    required this.description,
    required this.count,
    required this.countLabel,
    required this.chips,
    required this.onTap,
  });

  @override
  State<_HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<_HubCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _pressCtrl;
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.color.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left colored accent strip + icon
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(17),
                    bottomLeft: Radius.circular(17),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      widget.count,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      widget.countLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Right content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: widget.chips
                            .map((c) => Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: c,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: widget.color.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ─── Quick action tile ────────────────────────────────────────────────────────

class _QuickActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) =>
            Transform.scale(scale: _pressCtrl.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
