import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/providers/driver_provider.dart';
import 'package:fleet_management/data/models/driver_model.dart';

class DriversListScreen extends ConsumerStatefulWidget {
  const DriversListScreen({super.key});

  @override
  ConsumerState<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends ConsumerState<DriversListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _sortBy = 'name';
  bool _isGridView = true;

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

    // Load drivers on screen init
    Future.microtask(() => ref.read(driverProvider.notifier).loadDrivers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshDrivers() async {
    final status = _selectedFilter == 'all' ? null : _selectedFilter;
    await ref.read(driverProvider.notifier).loadDrivers(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final filteredDrivers = _filterAndSortDrivers(driverState.drivers);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Enhanced Header with gradient
          _buildEnhancedHeader(context, driverState),

          // Search and Filter Section
          _buildSearchAndFilters(context, driverState.drivers),

          // View Toggle and Sort
          _buildViewControls(context),

          // Drivers Grid/List
          Expanded(
            child: driverState.isLoading
                ? _buildLoadingState()
                : driverState.error != null
                    ? _buildErrorState(driverState.error!)
                    : filteredDrivers.isEmpty
                        ? _EmptyState(
                            searchQuery: _searchController.text,
                            onClear: () {
                              _searchController.clear();
                              setState(() => _selectedFilter = 'all');
                            },
                          )
                        : _buildDriversList(filteredDrivers),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context, dynamic driverState) {
    final drivers = driverState.drivers as List<DriverModel>;
    final activeCount = drivers.where((d) => d.isActive).length;
    final expiringCount = drivers.where((d) => d.hasExpiringSoonLicense).length;

    return Container(
      color: AppTheme.bgPrimary,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fleet Drivers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${driverState.total} drivers registered',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => context.push('/drivers/add'),
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: _HeaderStatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Active',
                    value: activeCount.toString(),
                    color: AppTheme.statusActive,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeaderStatCard(
                    icon: Icons.warning_rounded,
                    label: 'Expiring',
                    value: expiringCount.toString(),
                    color: AppTheme.statusWarning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeaderStatCard(
                    icon: Icons.people_outline_rounded,
                    label: 'Total',
                    value: driverState.total.toString(),
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, List<DriverModel> drivers) {
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
          // Search bar with glass effect
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.1),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search by name, ID, phone...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppTheme.primaryBlue,
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

          // Modern Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ModernFilterChip(
                  label: 'All Drivers',
                  count: drivers.length,
                  isSelected: _selectedFilter == 'all',
                  color: AppTheme.primaryBlue,
                  icon: Icons.people_rounded,
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _ModernFilterChip(
                  label: 'Active',
                  count: drivers.where((d) => d.isActive).length,
                  isSelected: _selectedFilter == 'active',
                  color: AppTheme.statusActive,
                  icon: Icons.check_circle_rounded,
                  onTap: () => setState(() => _selectedFilter = 'active'),
                ),
                const SizedBox(width: 8),
                _ModernFilterChip(
                  label: 'Inactive',
                  count: drivers.where((d) => d.isInactive).length,
                  isSelected: _selectedFilter == 'inactive',
                  color: AppTheme.statusWarning,
                  icon: Icons.pause_circle_rounded,
                  onTap: () => setState(() => _selectedFilter = 'inactive'),
                ),
                const SizedBox(width: 8),
                _ModernFilterChip(
                  label: 'On Leave',
                  count: drivers.where((d) => d.isOnLeave).length,
                  isSelected: _selectedFilter == 'on_leave',
                  color: AppTheme.accentSky,
                  icon: Icons.beach_access_rounded,
                  onTap: () => setState(() => _selectedFilter = 'on_leave'),
                ),
                const SizedBox(width: 8),
                _ModernFilterChip(
                  label: 'Terminated',
                  count: drivers.where((d) => d.isTerminated).length,
                  isSelected: _selectedFilter == 'terminated',
                  color: AppTheme.statusError,
                  icon: Icons.cancel_rounded,
                  onTap: () => setState(() => _selectedFilter = 'terminated'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sort Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
              ),
            ),
            child: DropdownButton<String>(
              value: _sortBy,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryBlue),
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Name')),
                DropdownMenuItem(value: 'employee_id', child: Text('Employee ID')),
                DropdownMenuItem(value: 'status', child: Text('Status')),
                DropdownMenuItem(value: 'join_date', child: Text('Join Date')),
              ],
              onChanged: (value) => setState(() => _sortBy = value!),
            ),
          ),
          const Spacer(),

          // View Toggle
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _ViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  isSelected: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                ),
                _ViewToggleButton(
                  icon: Icons.view_list_rounded,
                  isSelected: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriversList(List<DriverModel> drivers) {
    return RefreshIndicator(
      onRefresh: _refreshDrivers,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isGridView
            ? _buildGridView(drivers)
            : _buildListView(drivers),
      ),
    );
  }

  Widget _buildGridView(List<DriverModel> drivers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : constraints.maxWidth > 600
                    ? 2
                    : 1;

        return GridView.builder(
          key: const ValueKey('grid'),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: _EnhancedDriverCard(
                driver: drivers[index],
                onTap: () {
                  ref.read(driverProvider.notifier).selectDriver(drivers[index]);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected ${drivers[index].fullName}')),
                  );
                },
                onDelete: () => _showDeleteConfirmation(context, drivers[index]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<DriverModel> drivers) {
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.all(16),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _EnhancedDriverListTile(
            driver: drivers[index],
            onTap: () {
              ref.read(driverProvider.notifier).selectDriver(drivers[index]);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Selected ${drivers[index].fullName}')),
              );
            },
            onDelete: () => _showDeleteConfirmation(context, drivers[index]),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _SkeletonCard();
      },
    );
  }

  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.statusError.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: AppTheme.statusError,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error Loading Drivers',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshDrivers,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Retry',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, DriverModel driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.statusError),
            const SizedBox(width: 12),
            const Text('Delete Driver'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${driver.fullName}? This will set their status to terminated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(driverProvider.notifier).deleteDriver(driver.driverId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${driver.fullName} deleted successfully'),
                    backgroundColor: AppTheme.statusActive,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusError,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<DriverModel> _filterAndSortDrivers(List<DriverModel> drivers) {
    var filtered = drivers.where((driver) {
      // Filter by status
      if (_selectedFilter != 'all') {
        if (_selectedFilter == 'active' && !driver.isActive) return false;
        if (_selectedFilter == 'inactive' && !driver.isInactive) return false;
        if (_selectedFilter == 'on_leave' && !driver.isOnLeave) return false;
        if (_selectedFilter == 'terminated' && !driver.isTerminated) return false;
      }

      // Filter by search
      if (_searchController.text.isNotEmpty) {
        final searchLower = _searchController.text.toLowerCase();
        return driver.fullName.toLowerCase().contains(searchLower) ||
            driver.employeeId.toLowerCase().contains(searchLower) ||
            driver.phone.contains(searchLower);
      }

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'employee_id':
          return a.employeeId.compareTo(b.employeeId);
        case 'status':
          return a.status.compareTo(b.status);
        case 'join_date':
          return b.joinDate.compareTo(a.joinDate);
        case 'name':
        default:
          return a.fullName.compareTo(b.fullName);
      }
    });

    return filtered;
  }
}

// Header Stat Card
class _HeaderStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeaderStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color == Colors.white ? AppTheme.textPrimary : color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color == Colors.white ? AppTheme.textPrimary : color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Filter Chip
class _ModernFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ModernFilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.icon,
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
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// View Toggle Button
class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isSelected ? Colors.white : AppTheme.primaryBlue,
        ),
      ),
    );
  }
}

// Enhanced Driver Card (Grid View)
class _EnhancedDriverCard extends StatefulWidget {
  final DriverModel driver;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EnhancedDriverCard({
    required this.driver,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_EnhancedDriverCard> createState() => _EnhancedDriverCardState();
}

class _EnhancedDriverCardState extends State<_EnhancedDriverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.driver.status);
    final hasLicenseWarning = widget.driver.hasExpiredLicense || widget.driver.hasExpiringSoonLicense;

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
                statusColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(_isHovered ? 0.3 : 0.15),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge and Delete Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [statusColor, statusColor.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(widget.driver.status),
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.driver.statusDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onDelete,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.statusError,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Avatar and Name
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [statusColor, statusColor.withOpacity(0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.driver.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'ID: ${widget.driver.employeeId}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Divider
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 8),

                    // Contact Details
                    _CompactDetailItem(
                      icon: Icons.phone_rounded,
                      label: widget.driver.phone,
                      color: AppTheme.accentIndigo,
                    ),
                    if (widget.driver.email != null) ...[
                      const SizedBox(height: 8),
                      _CompactDetailItem(
                        icon: Icons.email_rounded,
                        label: widget.driver.email!,
                        color: AppTheme.accentSky,
                      ),
                    ],
                    const SizedBox(height: 12),

                    // License Warning
                    if (hasLicenseWarning)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.driver.hasExpiredLicense
                              ? AppTheme.statusError.withOpacity(0.1)
                              : AppTheme.statusWarning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.driver.hasExpiredLicense
                                ? AppTheme.statusError
                                : AppTheme.statusWarning,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.driver.hasExpiredLicense
                                  ? Icons.error_rounded
                                  : Icons.warning_rounded,
                              size: 16,
                              color: widget.driver.hasExpiredLicense
                                  ? AppTheme.statusError
                                  : AppTheme.statusWarning,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.driver.hasExpiredLicense
                                    ? 'License Expired'
                                    : 'License Expiring Soon',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: widget.driver.hasExpiredLicense
                                      ? AppTheme.statusError
                                      : AppTheme.statusWarning,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.statusActive;
      case 'inactive':
        return AppTheme.statusWarning;
      case 'on_leave':
        return AppTheme.accentSky;
      case 'terminated':
        return AppTheme.statusError;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle_rounded;
      case 'inactive':
        return Icons.pause_circle_rounded;
      case 'on_leave':
        return Icons.beach_access_rounded;
      case 'terminated':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}

// Compact Detail Item
class _CompactDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CompactDetailItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Driver List Tile
class _EnhancedDriverListTile extends StatefulWidget {
  final DriverModel driver;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EnhancedDriverListTile({
    required this.driver,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_EnhancedDriverListTile> createState() => _EnhancedDriverListTileState();
}

class _EnhancedDriverListTileState extends State<_EnhancedDriverListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.driver.status);
    final hasLicenseWarning = widget.driver.hasExpiredLicense || widget.driver.hasExpiringSoonLicense;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white,
              statusColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(_isHovered ? 0.5 : 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(_isHovered ? 0.2 : 0.1),
              blurRadius: _isHovered ? 12 : 8,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Driver Avatar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Driver Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.driver.fullName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [statusColor, statusColor.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.driver.statusDisplay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ID: ${widget.driver.employeeId}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _ListDetailBadge(
                              icon: Icons.phone_rounded,
                              label: widget.driver.phone,
                              color: AppTheme.accentIndigo,
                            ),
                            if (widget.driver.email != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ListDetailBadge(
                                  icon: Icons.email_rounded,
                                  label: widget.driver.email!,
                                  color: AppTheme.accentSky,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (hasLicenseWarning) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.driver.hasExpiredLicense
                                  ? AppTheme.statusError.withOpacity(0.1)
                                  : AppTheme.statusWarning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.driver.hasExpiredLicense
                                    ? AppTheme.statusError
                                    : AppTheme.statusWarning,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.driver.hasExpiredLicense
                                      ? Icons.error_rounded
                                      : Icons.warning_rounded,
                                  size: 14,
                                  color: widget.driver.hasExpiredLicense
                                      ? AppTheme.statusError
                                      : AppTheme.statusWarning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.driver.hasExpiredLicense
                                      ? 'License Expired'
                                      : 'License Expiring Soon',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: widget.driver.hasExpiredLicense
                                        ? AppTheme.statusError
                                        : AppTheme.statusWarning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Delete Button
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.statusError,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.statusActive;
      case 'inactive':
        return AppTheme.statusWarning;
      case 'on_leave':
        return AppTheme.accentSky;
      case 'terminated':
        return AppTheme.statusError;
      default:
        return Colors.grey;
    }
  }
}

// List Detail Badge
class _ListDetailBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ListDetailBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Skeleton Loading Card
class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 80,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Empty State
class _EmptyState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback onClear;

  const _EmptyState({
    required this.searchQuery,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              searchQuery.isEmpty
                  ? Icons.people_outline_rounded
                  : Icons.search_off_rounded,
              size: 80,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            searchQuery.isEmpty ? 'No Drivers Yet' : 'No Drivers Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Add your first driver to get started'
                : 'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          if (searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: () => context.push('/drivers/add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Driver',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: BorderSide(color: AppTheme.primaryBlue, width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text(
                'Clear Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
