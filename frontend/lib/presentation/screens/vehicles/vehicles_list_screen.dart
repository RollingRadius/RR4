import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

class VehiclesListScreen extends ConsumerStatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  ConsumerState<VehiclesListScreen> createState() =>
      _VehiclesListScreenState();
}

class _VehiclesListScreenState extends ConsumerState<VehiclesListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _sortBy = 'registration';
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = false;
    final vehicles = _getMockVehicles();
    final filteredVehicles = _filterAndSortVehicles(vehicles);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Enhanced Header with gradient
          _buildEnhancedHeader(context),

          // Search and Filter Section
          _buildSearchAndFilters(context, vehicles),

          // View Toggle and Sort
          _buildViewControls(context),

          // Vehicle Grid/List
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : filteredVehicles.isEmpty
                    ? _EmptyState(
                        searchQuery: _searchController.text,
                        onClear: () {
                          _searchController.clear();
                          setState(() => _selectedFilter = 'all');
                        },
                      )
                    : _buildVehiclesList(filteredVehicles),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fleet Vehicles',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_getMockVehicles().length} vehicles registered',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            FloatingActionButton(
              onPressed: () => context.push('/vehicles/add'),
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBlue,
              elevation: 4,
              child: const Icon(Icons.add_rounded, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, List<Map<String, dynamic>> vehicles) {
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
                hintText: 'Search by registration, make, model...',
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
                  label: 'All Vehicles',
                  count: vehicles.length,
                  isSelected: _selectedFilter == 'all',
                  color: AppTheme.primaryBlue,
                  icon: Icons.grid_view_rounded,
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _ModernFilterChip(
                  label: 'Active',
                  count: vehicles.where((v) => v['status'] == 'Active').length,
                  isSelected: _selectedFilter == 'active',
                  color: AppTheme.statusActive,
                  icon: Icons.check_circle_rounded,
                  onTap: () => setState(() => _selectedFilter = 'active'),
                ),
                const SizedBox(width: 8),
                _ModernFilterChip(
                  label: 'Maintenance',
                  count: vehicles.where((v) => v['status'] == 'Maintenance').length,
                  isSelected: _selectedFilter == 'maintenance',
                  color: AppTheme.statusWarning,
                  icon: Icons.build_rounded,
                  onTap: () => setState(() => _selectedFilter = 'maintenance'),
                ),
                const SizedBox(width: 8),
                _ModernFilterChip(
                  label: 'Inactive',
                  count: vehicles.where((v) => v['status'] == 'Inactive').length,
                  isSelected: _selectedFilter == 'inactive',
                  color: AppTheme.statusError,
                  icon: Icons.cancel_rounded,
                  onTap: () => setState(() => _selectedFilter = 'inactive'),
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
                DropdownMenuItem(value: 'registration', child: Text('Registration')),
                DropdownMenuItem(value: 'make', child: Text('Make')),
                DropdownMenuItem(value: 'status', child: Text('Status')),
                DropdownMenuItem(value: 'mileage', child: Text('Mileage')),
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

  Widget _buildVehiclesList(List<Map<String, dynamic>> vehicles) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isGridView
          ? _buildGridView(vehicles)
          : _buildListView(vehicles),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> vehicles) {
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
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: vehicles.length,
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
              child: _EnhancedVehicleCard(
                vehicle: vehicles[index],
                onTap: () => context.push('/vehicles/${vehicles[index]['id']}'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> vehicles) {
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
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
          child: _EnhancedVehicleListTile(
            vehicle: vehicles[index],
            onTap: () => context.push('/vehicles/${vehicles[index]['id']}'),
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
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _SkeletonCard();
      },
    );
  }

  List<Map<String, dynamic>> _filterAndSortVehicles(List<Map<String, dynamic>> vehicles) {
    var filtered = vehicles.where((vehicle) {
      // Filter by status
      if (_selectedFilter != 'all') {
        if (vehicle['status'].toString().toLowerCase() != _selectedFilter) {
          return false;
        }
      }

      // Filter by search
      if (_searchController.text.isNotEmpty) {
        final searchLower = _searchController.text.toLowerCase();
        return vehicle['registration'].toString().toLowerCase().contains(searchLower) ||
            vehicle['make'].toString().toLowerCase().contains(searchLower) ||
            vehicle['model'].toString().toLowerCase().contains(searchLower);
      }

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'make':
          return a['make'].toString().compareTo(b['make'].toString());
        case 'status':
          return a['status'].toString().compareTo(b['status'].toString());
        case 'mileage':
          return (a['mileage'] as double).compareTo(b['mileage'] as double);
        case 'registration':
        default:
          return a['registration'].toString().compareTo(b['registration'].toString());
      }
    });

    return filtered;
  }

  List<Map<String, dynamic>> _getMockVehicles() {
    return [
      {
        'id': '1',
        'registration': 'DL01AB1234',
        'make': 'Tata',
        'model': 'Ace',
        'year': 2022,
        'type': 'Truck',
        'status': 'Active',
        'driver': 'John Doe',
        'mileage': 15000.0,
        'fuelType': 'Diesel',
      },
      {
        'id': '2',
        'registration': 'MH02CD5678',
        'make': 'Mahindra',
        'model': 'Bolero',
        'year': 2021,
        'type': 'SUV',
        'status': 'Active',
        'driver': 'Jane Smith',
        'mileage': 25000.0,
        'fuelType': 'Diesel',
      },
      {
        'id': '3',
        'registration': 'KA03EF9012',
        'make': 'Maruti',
        'model': 'Swift',
        'year': 2023,
        'type': 'Car',
        'status': 'Active',
        'driver': null,
        'mileage': 5000.0,
        'fuelType': 'Petrol',
      },
      {
        'id': '4',
        'registration': 'TN04GH3456',
        'make': 'Ashok Leyland',
        'model': 'Dost',
        'year': 2020,
        'type': 'Truck',
        'status': 'Maintenance',
        'driver': null,
        'mileage': 50000.0,
        'fuelType': 'Diesel',
      },
      {
        'id': '5',
        'registration': 'UP05IJ7890',
        'make': 'Force',
        'model': 'Traveller',
        'year': 2022,
        'type': 'Van',
        'status': 'Maintenance',
        'driver': 'Bob Johnson',
        'mileage': 30000.0,
        'fuelType': 'Diesel',
      },
      {
        'id': '6',
        'registration': 'GJ06KL2345',
        'make': 'Hyundai',
        'model': 'Creta',
        'year': 2023,
        'type': 'SUV',
        'status': 'Active',
        'driver': 'Alice Brown',
        'mileage': 8000.0,
        'fuelType': 'Petrol',
      },
    ];
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

// Enhanced Vehicle Card (Grid View)
class _EnhancedVehicleCard extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onTap;

  const _EnhancedVehicleCard({
    required this.vehicle,
    required this.onTap,
  });

  @override
  State<_EnhancedVehicleCard> createState() => _EnhancedVehicleCardState();
}

class _EnhancedVehicleCardState extends State<_EnhancedVehicleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.vehicle['status'] as String;
    final statusColor = _getStatusColor(status);

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
                    // Status Badge and Icon
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
                                _getStatusIcon(status),
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getVehicleIcon(widget.vehicle['type']),
                            color: AppTheme.primaryBlue,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Registration Number
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        widget.vehicle['registration'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Vehicle Info
                    Text(
                      '${widget.vehicle['make']} ${widget.vehicle['model']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.vehicle['year']} • ${widget.vehicle['type']}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),

                    // Divider
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 8),

                    // Details Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CompactDetailItem(
                          icon: Icons.local_gas_station_rounded,
                          label: widget.vehicle['fuelType'] as String,
                          color: AppTheme.accentCyan,
                        ),
                        _CompactDetailItem(
                          icon: Icons.speed_rounded,
                          label: '${(widget.vehicle['mileage'] as double) / 1000}k',
                          color: AppTheme.accentIndigo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Driver Info
                    if (widget.vehicle['driver'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.statusActive.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.statusActive,
                              child: const Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.vehicle['driver'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_outlined,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'No driver',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
      case 'maintenance':
        return AppTheme.statusWarning;
      case 'inactive':
        return AppTheme.statusError;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle_rounded;
      case 'maintenance':
        return Icons.build_rounded;
      case 'inactive':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'truck':
        return Icons.local_shipping_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'suv':
        return Icons.directions_car_filled_rounded;
      case 'van':
        return Icons.airport_shuttle_rounded;
      default:
        return Icons.directions_car_rounded;
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
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Vehicle List Tile
class _EnhancedVehicleListTile extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onTap;

  const _EnhancedVehicleListTile({
    required this.vehicle,
    required this.onTap,
  });

  @override
  State<_EnhancedVehicleListTile> createState() => _EnhancedVehicleListTileState();
}

class _EnhancedVehicleListTileState extends State<_EnhancedVehicleListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.vehicle['status'] as String;
    final statusColor = _getStatusColor(status);

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
                  // Vehicle Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getVehicleIcon(widget.vehicle['type']),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Vehicle Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.vehicle['registration'] as String,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                status,
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
                          '${widget.vehicle['make']} ${widget.vehicle['model']} (${widget.vehicle['year']})',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _ListDetailBadge(
                              icon: Icons.category_rounded,
                              label: widget.vehicle['type'] as String,
                              color: AppTheme.accentSky,
                            ),
                            const SizedBox(width: 8),
                            _ListDetailBadge(
                              icon: Icons.local_gas_station_rounded,
                              label: widget.vehicle['fuelType'] as String,
                              color: AppTheme.accentCyan,
                            ),
                            const SizedBox(width: 8),
                            _ListDetailBadge(
                              icon: Icons.speed_rounded,
                              label: '${widget.vehicle['mileage']} km',
                              color: AppTheme.accentIndigo,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Driver Info
                  if (widget.vehicle['driver'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.statusActive.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.statusActive.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.statusActive,
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Driver',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                widget.vehicle['driver'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No driver',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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
      case 'maintenance':
        return AppTheme.statusWarning;
      case 'inactive':
        return AppTheme.statusError;
      default:
        return Colors.grey;
    }
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'truck':
        return Icons.local_shipping_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'suv':
        return Icons.directions_car_filled_rounded;
      case 'van':
        return Icons.airport_shuttle_rounded;
      default:
        return Icons.directions_car_rounded;
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 120,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              searchQuery.isEmpty
                  ? Icons.directions_car_outlined
                  : Icons.search_off_rounded,
              size: 80,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            searchQuery.isEmpty ? 'No Vehicles Yet' : 'No Vehicles Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Add your first vehicle to get started'
                : 'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          if (searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: () => context.push('/vehicles/add'),
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
                'Add Vehicle',
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
    );
  }
}
