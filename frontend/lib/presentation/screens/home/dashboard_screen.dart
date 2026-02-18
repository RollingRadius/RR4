import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Section fade animations (opacity)
  late Animation<double> _headerFade;
  late Animation<double> _metricsFade;
  late Animation<double> _statsFade;
  late Animation<double> _actionsFade;
  late Animation<double> _activityFade;

  // Section slide animations (vertical offset)
  late Animation<Offset> _metricsSlide;
  late Animation<Offset> _statsSlide;
  late Animation<Offset> _actionsSlide;
  late Animation<Offset> _activitySlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Header: 0–35%
    _headerFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    // Metrics: 15–50%
    _metricsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
    );
    _metricsSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
    ));

    // Stats: 30–60%
    _statsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.60, curve: Curves.easeOut),
    );
    _statsSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.60, curve: Curves.easeOut),
    ));

    // Actions + Fleet: 45–75%
    _actionsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );
    _actionsSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    ));

    // Activity: 60–100%
    _activityFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
    );
    _activitySlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final isDesktop = constraints.maxWidth >= 1024;

        final hPad = isMobile ? 16.0 : 24.0;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header — full screen width, bottom-rounded
              FadeTransition(
                opacity: _headerFade,
                child: _WelcomeHeader(
                  user: user,
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
              ),
              SizedBox(height: isMobile ? 20 : 32),
              // All remaining sections inside horizontal padding
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

              // Metrics Overview
              FadeTransition(
                opacity: _metricsFade,
                child: SlideTransition(
                  position: _metricsSlide,
                  child: _MetricsOverview(
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 32),

              // Stats Cards
              FadeTransition(
                opacity: _statsFade,
                child: SlideTransition(
                  position: _statsSlide,
                  child: _StatsSection(
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 32),

              // Quick Actions + Fleet Status
              FadeTransition(
                opacity: _actionsFade,
                child: SlideTransition(
                  position: _actionsSlide,
                  child: isDesktop || isTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _QuickActionsSection(
                                isMobile: isMobile,
                                isTablet: isTablet,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _FleetStatusSection(),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _QuickActionsSection(
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),
                            const SizedBox(height: 20),
                            _FleetStatusSection(),
                          ],
                        ),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 32),

              // Recent Activity
              FadeTransition(
                opacity: _activityFade,
                child: SlideTransition(
                  position: _activitySlide,
                  child: _RecentActivitySection(isMobile: isMobile),
                ),
              ),
                  ], // inner Column children
                ),   // inner Column
              ),     // Padding
            ],       // outer Column children
          ),         // outer Column
        );           // SingleChildScrollView
      },
    );
  }
}

// ==================== WELCOME HEADER ====================
class _WelcomeHeader extends StatelessWidget {
  final dynamic user;
  final bool isMobile;
  final bool isTablet;

  const _WelcomeHeader({
    required this.user,
    required this.isMobile,
    required this.isTablet,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isMobile ? 28 : 32),
          bottomRight: Radius.circular(isMobile ? 28 : 32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 20.0 : 28.0,
          isMobile ? 20.0 : 28.0,
          isMobile ? 20.0 : 28.0,
          isMobile ? 28.0 : 36.0, // extra bottom padding for the curve
        ),
        child: isMobile
            ? Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 16),
                  _buildUserInfo(context),
                ],
              )
            : Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 24),
                  Expanded(child: _buildUserInfo(context)),
                  if (!isMobile) ...[
                    const SizedBox(width: 20),
                    _buildDateCard(),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: isMobile ? 36 : 40,
        backgroundColor: Colors.white.withOpacity(0.25),
        child: Icon(
          Icons.local_shipping_rounded,
          size: isMobile ? 36 : 42,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          '${_getGreeting()},',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w500,
              ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 6),
        Text(
          user?.username ?? 'User',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isMobile ? 24 : 28,
              ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
        ),
        if (user?.companyName != null) ...[
          const SizedBox(height: 12),
          _buildCompanyBadge(),
        ],
        const SizedBox(height: 12),
        _buildRoleBadge(),
      ],
    );
  }

  Widget _buildCompanyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.business_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            user.companyName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            user?.role ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: Colors.white.withOpacity(0.9),
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(DateTime.now()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ==================== METRICS OVERVIEW ====================
class _MetricsOverview extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _MetricsOverview({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = [
      {'icon': Icons.local_shipping_rounded, 'label': 'Active Fleet', 'value': '0/0', 'color': AppTheme.primaryBlue},
      {'icon': Icons.trending_up_rounded, 'label': 'Utilization', 'value': '0%', 'color': AppTheme.statusActive},
      {'icon': Icons.speed_rounded, 'label': 'Avg Speed', 'value': '-- km/h', 'color': AppTheme.statusWarning},
      {'icon': Icons.schedule_rounded, 'label': 'On-Time', 'value': '0%', 'color': AppTheme.accentCyan},
    ];

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: metrics
              .map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _MetricItem(
                      icon: m['icon'] as IconData,
                      label: m['label'] as String,
                      value: m['value'] as String,
                      iconColor: m['color'] as Color,
                      isMobile: true,
                    ),
                  ))
              .toList(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.05),
            AppTheme.accentCyan.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: List.generate(
          metrics.length * 2 - 1,
          (index) {
            if (index.isOdd) {
              return Container(
                width: 1,
                height: 50,
                color: AppTheme.textTertiary.withOpacity(0.2),
              );
            }
            final m = metrics[index ~/ 2];
            return Expanded(
              child: _MetricItem(
                icon: m['icon'] as IconData,
                label: m['label'] as String,
                value: m['value'] as String,
                iconColor: m['color'] as Color,
                isMobile: false,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isMobile;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ==================== STATS SECTION ====================
class _StatsSection extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const _StatsSection({
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'icon': Icons.directions_car_rounded,
        'title': 'Vehicles',
        'value': '0',
        'gradient': AppTheme.primaryGradient,
        'route': '/vehicles',
      },
      {
        'icon': Icons.people_rounded,
        'title': 'Drivers',
        'value': '0',
        'gradient': AppTheme.accentGradient,
        'route': '/drivers',
      },
      {
        'icon': Icons.route_rounded,
        'title': 'Active Trips',
        'value': '0',
        'gradient': AppTheme.skyGradient,
        'route': '/trips',
      },
      {
        'icon': Icons.notification_important_rounded,
        'title': 'Alerts',
        'value': '0',
        'gradient': const LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFE53935)],
        ),
        'route': '/alerts',
      },
    ];

    int crossAxisCount;
    double childAspectRatio;

    if (isDesktop) {
      crossAxisCount = 4;
      childAspectRatio = 1.3;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 1.4;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 1.9;
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _StatCard(
          icon: stat['icon'] as IconData,
          title: stat['title'] as String,
          value: stat['value'] as String,
          gradient: stat['gradient'] as LinearGradient,
          onTap: () => context.push(stat['route'] as String),
          delay: index * 100,
        );
      },
    );
  }
}

class _StatCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.gradient,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  // Animated counter: 0 → 1 applied to numeric values
  late Animation<double> _valueAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Counter counts up during second half of the card animation
    _valueAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Adapt padding and font size to available card height
                final compact = constraints.maxHeight < 160;
                final cardPadding = compact ? 14.0 : 20.0;
                final iconPad = compact ? 9.0 : 12.0;
                final iconSize = compact ? 24.0 : 28.0;
                final valueFontSize = compact ? 28.0 : 36.0;

                return Container(
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient.colors.first.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.all(iconPad),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(widget.icon, color: Colors.white, size: iconSize),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '0%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated count-up for numeric values
                          AnimatedBuilder(
                            animation: _valueAnimation,
                            builder: (context, _) {
                              final numVal = int.tryParse(widget.value) ?? 0;
                              final displayed = numVal > 0
                                  ? (numVal * _valueAnimation.value).round().toString()
                                  : widget.value;
                              return Text(
                                displayed,
                                style: TextStyle(
                                  fontSize: valueFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== QUICK ACTIONS ====================
class _QuickActionsSection extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _QuickActionsSection({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Quick Actions',
          subtitle: 'Manage your fleet',
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: 16),
        _QuickActionsGrid(isMobile: isMobile, isTablet: isTablet),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const _QuickActionsGrid({
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': Icons.add_circle_outline_rounded, 'label': 'Add Vehicle', 'color': AppTheme.primaryBlue, 'route': '/vehicles/add'},
      {'icon': Icons.person_add_outlined, 'label': 'Add Driver', 'color': AppTheme.statusActive, 'route': '/drivers/add'},
      {'icon': Icons.route_rounded, 'label': 'New Trip', 'color': AppTheme.statusWarning, 'route': '/trips'},
      {'icon': Icons.assessment_outlined, 'label': 'Reports', 'color': AppTheme.accentIndigo, 'route': '/reports'},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'color': AppTheme.accentCyan, 'route': '/settings'},
      {'icon': Icons.help_outline_rounded, 'label': 'Help', 'color': AppTheme.accentSky, 'route': '/help'},
    ];

    int crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 3);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _QuickActionCard(
            icon: action['icon'] as IconData,
            label: action['label'] as String,
            color: action['color'] as Color,
            onTap: () => context.push(action['route'] as String),
            delay: index * 80,
          );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.delay = 0,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryScale;
  late Animation<double> _entryFade;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );
    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entryFade,
      child: ScaleTransition(
        scale: _entryScale,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.color.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, size: 28, color: widget.color),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== FLEET STATUS ====================
class _FleetStatusSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Fleet Status',
          subtitle: 'Real-time overview',
          icon: Icons.pie_chart_rounded,
        ),
        const SizedBox(height: 16),
        _FleetStatusCard(),
      ],
    );
  }
}

class _FleetStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final statuses = [
      {'icon': Icons.check_circle_rounded, 'label': 'Active', 'count': 0, 'color': AppTheme.statusActive},
      {'icon': Icons.pause_circle_rounded, 'label': 'Idle', 'count': 0, 'color': AppTheme.statusWarning},
      {'icon': Icons.build_circle_rounded, 'label': 'Maintenance', 'count': 0, 'color': AppTheme.statusInfo},
      {'icon': Icons.cancel_rounded, 'label': 'Offline', 'count': 0, 'color': AppTheme.statusError},
    ];

    final total = statuses.fold<int>(0, (sum, s) => sum + (s['count'] as int));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: statuses
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _StatusItem(
                    icon: s['icon'] as IconData,
                    label: s['label'] as String,
                    count: s['count'] as int,
                    total: total,
                    color: s['color'] as Color,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Animated progress bar
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: ratio),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ==================== RECENT ACTIVITY ====================
class _RecentActivitySection extends StatelessWidget {
  final bool isMobile;

  const _RecentActivitySection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Recent Activity',
          subtitle: 'Latest updates',
          icon: Icons.access_time_rounded,
        ),
        const SizedBox(height: 16),
        _RecentActivityList(isMobile: isMobile),
      ],
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final bool isMobile;

  const _RecentActivityList({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'icon': Icons.check_circle_rounded,
        'title': 'System Online',
        'subtitle': 'All systems operational',
        'time': 'Just now',
        'color': AppTheme.statusActive,
      },
      {
        'icon': Icons.local_shipping_rounded,
        'title': 'Fleet Ready',
        'subtitle': 'Ready to manage vehicles',
        'time': '2 min ago',
        'color': AppTheme.primaryBlue,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          // Staggered slide-in per item
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + index * 150),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: ListTile(
              contentPadding: EdgeInsets.all(isMobile ? 16 : 20),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  activity['icon'] as IconData,
                  color: activity['color'] as Color,
                  size: 24,
                ),
              ),
              title: Text(
                activity['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                activity['subtitle'] as String,
                style: const TextStyle(fontSize: 13),
              ),
              trailing: Text(
                activity['time'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== SECTION HEADER ====================
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withOpacity(0.15),
                AppTheme.primaryBlue.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
