import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _registrationController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _vinController = TextEditingController();
  final _colorController = TextEditingController();
  final _mileageController = TextEditingController();
  final _seatingCapacityController = TextEditingController();
  final _loadCapacityController = TextEditingController();

  // Dropdown selections
  String? _selectedVehicleType;
  String? _selectedFuelType;
  String _selectedStatus = 'active';

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;

  // Vehicle Types from README
  final List<Map<String, dynamic>> _vehicleTypes = [
    {'value': 'car', 'label': 'Car', 'icon': Icons.directions_car_rounded},
    {'value': 'truck', 'label': 'Truck', 'icon': Icons.local_shipping_rounded},
    {'value': 'van', 'label': 'Van', 'icon': Icons.airport_shuttle_rounded},
    {'value': 'bus', 'label': 'Bus', 'icon': Icons.directions_bus_rounded},
    {'value': 'motorcycle', 'label': 'Motorcycle', 'icon': Icons.two_wheeler_rounded},
    {'value': 'pickup', 'label': 'Pickup', 'icon': Icons.local_shipping_outlined},
    {'value': 'suv', 'label': 'SUV', 'icon': Icons.directions_car_filled_rounded},
    {'value': 'trailer', 'label': 'Trailer', 'icon': Icons.rv_hookup_rounded},
  ];

  // Fuel Types from README
  final List<Map<String, dynamic>> _fuelTypes = [
    {'value': 'petrol', 'label': 'Petrol', 'icon': Icons.local_gas_station_rounded},
    {'value': 'diesel', 'label': 'Diesel', 'icon': Icons.local_gas_station_outlined},
    {'value': 'electric', 'label': 'Electric', 'icon': Icons.electric_bolt_rounded},
    {'value': 'hybrid', 'label': 'Hybrid', 'icon': Icons.battery_charging_full_rounded},
    {'value': 'cng', 'label': 'CNG', 'icon': Icons.propane_tank_rounded},
    {'value': 'lpg', 'label': 'LPG', 'icon': Icons.propane_rounded},
  ];

  // Status options
  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'active', 'label': 'Active', 'color': Color(0xFF66BB6A)},
    {'value': 'maintenance', 'label': 'Maintenance', 'color': Color(0xFFFF9800)},
    {'value': 'inactive', 'label': 'Inactive', 'color': Color(0xFF757575)},
    {'value': 'retired', 'label': 'Retired', 'color': Color(0xFFEF5350)},
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _vinController.dispose();
    _colorController.dispose();
    _mileageController.dispose();
    _seatingCapacityController.dispose();
    _loadCapacityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Implement API call to save vehicle
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    if (mounted) {
      setState(() => _isLoading = false);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vehicle ${_registrationController.text} added successfully!',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate back
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.02),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context),

              // Form Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 16,
                        vertical: 24,
                      ),
                      child: Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 800 : double.infinity,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeaderSection(context),
                                const SizedBox(height: 32),
                                _buildBasicInfoCard(context),
                                const SizedBox(height: 20),
                                _buildVehicleDetailsCard(context),
                                const SizedBox(height: 20),
                                _buildAdditionalInfoCard(context),
                                const SizedBox(height: 32),
                                _buildSaveButton(context),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Add New Vehicle',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Vehicle Information',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Fill in the details to add a new vehicle to your fleet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBasicInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Registration Number
            TextFormField(
              controller: _registrationController,
              decoration: InputDecoration(
                labelText: 'Registration Number *',
                hintText: 'e.g., DL01AB1234',
                prefixIcon: Icon(
                  Icons.badge_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Registration number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Make and Model Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _makeController,
                    decoration: InputDecoration(
                      labelText: 'Make *',
                      hintText: 'e.g., Tata, Mahindra',
                      prefixIcon: Icon(
                        Icons.business_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Make is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: 'Model *',
                      hintText: 'e.g., Ace, Bolero',
                      prefixIcon: Icon(
                        Icons.directions_car_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Model is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Year
            TextFormField(
              controller: _yearController,
              decoration: InputDecoration(
                labelText: 'Year *',
                hintText: 'e.g., 2023',
                prefixIcon: Icon(
                  Icons.calendar_today_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Year is required';
                }
                final year = int.tryParse(value);
                if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                  return 'Enter a valid year';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetailsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: AppTheme.secondaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Vehicle Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Vehicle Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              decoration: InputDecoration(
                labelText: 'Vehicle Type *',
                hintText: 'Select vehicle type',
                prefixIcon: Icon(
                  Icons.category_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              items: _vehicleTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Row(
                    children: [
                      Icon(type['icon'] as IconData, size: 20),
                      const SizedBox(width: 12),
                      Text(type['label'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedVehicleType = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vehicle type is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Fuel Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedFuelType,
              decoration: InputDecoration(
                labelText: 'Fuel Type',
                hintText: 'Select fuel type',
                prefixIcon: Icon(
                  Icons.local_gas_station_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              items: _fuelTypes.map((fuel) {
                return DropdownMenuItem<String>(
                  value: fuel['value'],
                  child: Row(
                    children: [
                      Icon(fuel['icon'] as IconData, size: 20),
                      const SizedBox(width: 12),
                      Text(fuel['label'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedFuelType = value);
              },
            ),
            const SizedBox(height: 20),

            // VIN Number
            TextFormField(
              controller: _vinController,
              decoration: InputDecoration(
                labelText: 'VIN Number',
                hintText: 'Vehicle Identification Number',
                prefixIcon: Icon(
                  Icons.fingerprint_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),

            // Color
            TextFormField(
              controller: _colorController,
              decoration: InputDecoration(
                labelText: 'Color',
                hintText: 'e.g., White, Blue',
                prefixIcon: Icon(
                  Icons.palette_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            // Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status *',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _statusOptions.map((status) {
                    final isSelected = _selectedStatus == status['value'];
                    final statusColor = status['color'] as Color;

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedStatus = status['value'] as String);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? statusColor.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? statusColor : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: statusColor,
                                size: 18,
                              ),
                            if (isSelected) const SizedBox(width: 8),
                            Text(
                              status['label'] as String,
                              style: TextStyle(
                                color: isSelected ? statusColor : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: AppTheme.infoColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Additional Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Optional fields - can be added later',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // Mileage
            TextFormField(
              controller: _mileageController,
              decoration: InputDecoration(
                labelText: 'Current Mileage (km)',
                hintText: 'e.g., 15000',
                prefixIcon: Icon(
                  Icons.speed_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 20),

            // Seating and Load Capacity Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _seatingCapacityController,
                    decoration: InputDecoration(
                      labelText: 'Seating Capacity',
                      hintText: 'e.g., 5',
                      prefixIcon: Icon(
                        Icons.event_seat_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _loadCapacityController,
                    decoration: InputDecoration(
                      labelText: 'Load Capacity (kg)',
                      hintText: 'e.g., 1000',
                      prefixIcon: Icon(
                        Icons.scale_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
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

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: _isLoading ? null : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isLoading
            ? null
            : [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveVehicle,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? null : Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'ADD VEHICLE',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
