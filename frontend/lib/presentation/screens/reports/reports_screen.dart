import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _getFilteredReports();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Enhanced Header with gradient
            _buildEnhancedHeader(context),

            // Search and Category Filter
            _buildSearchAndFilter(context),

            // Quick Stats
            _buildQuickStats(context),

            // Reports by Category
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedCategory == 'all' || _selectedCategory == 'financial')
                    _buildReportSection(
                      context,
                      'Financial Reports',
                      Icons.account_balance_rounded,
                      AppTheme.statusActive,
                      filteredReports['financial']!,
                    ),
                  if (_selectedCategory == 'all' || _selectedCategory == 'operations')
                    _buildReportSection(
                      context,
                      'Operations Reports',
                      Icons.local_shipping_rounded,
                      AppTheme.primaryBlue,
                      filteredReports['operations']!,
                    ),
                  if (_selectedCategory == 'all' || _selectedCategory == 'compliance')
                    _buildReportSection(
                      context,
                      'Compliance Reports',
                      Icons.verified_user_rounded,
                      AppTheme.statusWarning,
                      filteredReports['compliance']!,
                    ),
                  if (_selectedCategory == 'all' || _selectedCategory == 'analytics')
                    _buildReportSection(
                      context,
                      'Analytics & Insights',
                      Icons.analytics_rounded,
                      AppTheme.accentIndigo,
                      filteredReports['analytics']!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentIndigo,
            AppTheme.accentIndigo.withOpacity(0.8),
            AppTheme.primaryBlue,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentIndigo.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assessment_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports & Analytics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Generate insights for your fleet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.accentIndigo.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentIndigo.withOpacity(0.1),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search reports...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.accentIndigo,
                  size: 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppTheme.accentIndigo,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),

          // Category filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryChip(
                  label: 'All Reports',
                  icon: Icons.dashboard_rounded,
                  isSelected: _selectedCategory == 'all',
                  color: AppTheme.accentIndigo,
                  onTap: () => setState(() => _selectedCategory = 'all'),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Financial',
                  icon: Icons.account_balance_rounded,
                  isSelected: _selectedCategory == 'financial',
                  color: AppTheme.statusActive,
                  onTap: () => setState(() => _selectedCategory = 'financial'),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Operations',
                  icon: Icons.local_shipping_rounded,
                  isSelected: _selectedCategory == 'operations',
                  color: AppTheme.primaryBlue,
                  onTap: () => setState(() => _selectedCategory = 'operations'),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Compliance',
                  icon: Icons.verified_user_rounded,
                  isSelected: _selectedCategory == 'compliance',
                  color: AppTheme.statusWarning,
                  onTap: () => setState(() => _selectedCategory = 'compliance'),
                ),
                const SizedBox(width: 8),
                _CategoryChip(
                  label: 'Analytics',
                  icon: Icons.analytics_rounded,
                  isSelected: _selectedCategory == 'analytics',
                  color: AppTheme.accentCyan,
                  onTap: () => setState(() => _selectedCategory = 'analytics'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          return isDesktop
              ? Row(
                  children: [
                    Expanded(child: _QuickStatCard(
                      icon: Icons.description_rounded,
                      label: 'Total Reports',
                      value: '24',
                      color: AppTheme.primaryBlue,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickStatCard(
                      icon: Icons.trending_up_rounded,
                      label: 'Generated Today',
                      value: '5',
                      color: AppTheme.statusActive,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickStatCard(
                      icon: Icons.schedule_rounded,
                      label: 'Scheduled',
                      value: '8',
                      color: AppTheme.accentCyan,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickStatCard(
                      icon: Icons.bookmark_rounded,
                      label: 'Favorites',
                      value: '12',
                      color: AppTheme.statusWarning,
                    )),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _QuickStatCard(
                          icon: Icons.description_rounded,
                          label: 'Total Reports',
                          value: '24',
                          color: AppTheme.primaryBlue,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickStatCard(
                          icon: Icons.trending_up_rounded,
                          label: 'Generated Today',
                          value: '5',
                          color: AppTheme.statusActive,
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _QuickStatCard(
                          icon: Icons.schedule_rounded,
                          label: 'Scheduled',
                          value: '8',
                          color: AppTheme.accentCyan,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _QuickStatCard(
                          icon: Icons.bookmark_rounded,
                          label: 'Favorites',
                          value: '12',
                          color: AppTheme.statusWarning,
                        )),
                      ],
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildReportSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Map<String, dynamic>> reports,
  ) {
    if (reports.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1200
                ? 3
                : constraints.maxWidth > 800
                    ? 2
                    : 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _EnhancedReportCard(
                    report: reports[index],
                    color: color,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Map<String, List<Map<String, dynamic>>> _getFilteredReports() {
    final searchLower = _searchController.text.toLowerCase();

    final allReports = {
      'financial': [
        {
          'title': 'Expense Summary',
          'description': 'Detailed breakdown of all expenses by category and vehicle',
          'icon': Icons.payments_rounded,
          'route': '/reports/expenses',
          'popular': true,
        },
        {
          'title': 'Invoice Reports',
          'description': 'View and analyze all invoices and payment status',
          'icon': Icons.receipt_long_rounded,
          'route': '/reports/invoices',
          'popular': false,
        },
        {
          'title': 'Budget Analysis',
          'description': 'Compare actual spending against budgets',
          'icon': Icons.account_balance_wallet_rounded,
          'route': '/reports/budget',
          'popular': false,
        },
        {
          'title': 'Payment Tracking',
          'description': 'Monitor payment schedules and outstanding amounts',
          'icon': Icons.paid_rounded,
          'route': '/reports/payments',
          'popular': false,
        },
      ],
      'operations': [
        {
          'title': 'Organization Summary',
          'description': 'Overview of drivers, users, and key metrics',
          'icon': Icons.dashboard_rounded,
          'route': '/reports/organization-summary',
          'popular': true,
        },
        {
          'title': 'Driver List',
          'description': 'Complete list of all drivers with details',
          'icon': Icons.people_rounded,
          'route': '/reports/driver-list',
          'popular': true,
        },
        {
          'title': 'Vehicle Utilization',
          'description': 'Track vehicle usage and efficiency metrics',
          'icon': Icons.directions_car_rounded,
          'route': '/reports/vehicle-utilization',
          'popular': false,
        },
        {
          'title': 'Trip History',
          'description': 'Detailed log of all trips and routes',
          'icon': Icons.route_rounded,
          'route': '/reports/trip-history',
          'popular': false,
        },
        {
          'title': 'Fuel Consumption',
          'description': 'Monitor fuel usage and costs per vehicle',
          'icon': Icons.local_gas_station_rounded,
          'route': '/reports/fuel',
          'popular': true,
        },
      ],
      'compliance': [
        {
          'title': 'License Expiry',
          'description': 'Track license expiration dates and renewals',
          'icon': Icons.credit_card_rounded,
          'route': '/reports/license-expiry',
          'popular': true,
        },
        {
          'title': 'Audit Log',
          'description': 'View system activity and changes',
          'icon': Icons.history_rounded,
          'route': '/reports/audit-log',
          'popular': false,
        },
        {
          'title': 'Compliance Checklist',
          'description': 'Ensure all regulatory requirements are met',
          'icon': Icons.checklist_rounded,
          'route': '/reports/compliance',
          'popular': false,
        },
        {
          'title': 'Maintenance Records',
          'description': 'Complete maintenance history for all vehicles',
          'icon': Icons.build_rounded,
          'route': '/reports/maintenance',
          'popular': false,
        },
      ],
      'analytics': [
        {
          'title': 'User Activity',
          'description': 'Monitor user engagement and actions',
          'icon': Icons.bar_chart_rounded,
          'route': '/reports/user-activity',
          'popular': false,
        },
        {
          'title': 'Performance Metrics',
          'description': 'Key performance indicators and trends',
          'icon': Icons.insights_rounded,
          'route': '/reports/performance',
          'popular': true,
        },
        {
          'title': 'Cost Analysis',
          'description': 'Analyze cost trends and find savings',
          'icon': Icons.trending_down_rounded,
          'route': '/reports/cost-analysis',
          'popular': false,
        },
        {
          'title': 'Custom Reports',
          'description': 'Create your own custom report templates',
          'icon': Icons.tune_rounded,
          'route': '/reports/custom',
          'popular': false,
        },
      ],
    };

    if (searchLower.isEmpty) return allReports;

    return allReports.map((category, reports) {
      final filtered = reports.where((report) {
        return report['title'].toString().toLowerCase().contains(searchLower) ||
            report['description'].toString().toLowerCase().contains(searchLower);
      }).toList();
      return MapEntry(category, filtered);
    });
  }
}

// Category Chip
class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick Stat Card
class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Report Card
class _EnhancedReportCard extends StatefulWidget {
  final Map<String, dynamic> report;
  final Color color;

  const _EnhancedReportCard({
    required this.report,
    required this.color,
  });

  @override
  State<_EnhancedReportCard> createState() => _EnhancedReportCardState();
}

class _EnhancedReportCardState extends State<_EnhancedReportCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isPopular = widget.report['popular'] as bool;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                widget.color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isHovered ? 0.3 : 0.15),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(widget.report['route'] as String),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [widget.color, widget.color.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.report['icon'] as IconData,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        if (isPopular)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.statusWarning.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.statusWarning,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: AppTheme.statusWarning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Popular',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.statusWarning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      widget.report['title'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.report['description'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'View Report',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.color,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: widget.color,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
