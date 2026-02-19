import 'package:flutter/material.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _tripNameController = TextEditingController();
  final _startController = TextEditingController();
  final _destController = TextEditingController();
  String? _selectedDriver;
  String? _selectedVehicle;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  static const _drivers = [
    'John Smith (Available)',
    'Sarah Jenkins (Available)',
    'Marcus Vane (On Break)',
  ];

  static const _vehicles = [
    'Ford Transit - #FL-402 (Fuel: 85%)',
    'Sprinter Van - #FL-109 (Fuel: 92%)',
    'Box Truck - #BT-002 (In Service)',
  ];

  @override
  void dispose() {
    _tripNameController.dispose();
    _startController.dispose();
    _destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create New Trip',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Information
            _SectionTitle(icon: Icons.route_outlined, label: 'Route Information'),
            const SizedBox(height: 16),
            _TripFormField(
              label: 'Trip Name',
              child: _StyledInput(
                controller: _tripNameController,
                hintText: 'e.g., Downtown Delivery Hub',
              ),
            ),
            const SizedBox(height: 16),
            _TripFormField(
              label: 'Starting Point',
              child: _LocationInput(
                controller: _startController,
                hintText: 'Enter pickup location',
                leadIcon: Icons.location_on_outlined,
                trailIcon: Icons.my_location,
                onTrailTap: () {},
              ),
            ),
            const SizedBox(height: 16),
            _TripFormField(
              label: 'Destination',
              child: _LocationInput(
                controller: _destController,
                hintText: 'Enter drop-off location',
                leadIcon: Icons.flag_outlined,
                trailIcon: Icons.map_outlined,
                onTrailTap: () {},
              ),
            ),
            const SizedBox(height: 28),

            // Schedule
            _SectionTitle(icon: Icons.calendar_today_outlined, label: 'Schedule'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TripFormField(
                    label: 'Date',
                    child: _PickerField(
                      value: _selectedDate != null
                          ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                          : 'Select date',
                      icon: Icons.calendar_today_outlined,
                      onTap: () => _pickDate(context),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TripFormField(
                    label: 'Departure Time',
                    child: _PickerField(
                      value: _selectedTime != null
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : 'Select time',
                      icon: Icons.access_time_outlined,
                      onTap: () => _pickTime(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Assignments
            _SectionTitle(icon: Icons.person_add_outlined, label: 'Assignments'),
            const SizedBox(height: 16),
            _TripFormField(
              label: 'Assign Driver',
              child: _TripDropdown(
                value: _selectedDriver,
                hint: 'Select an available driver',
                items: _drivers,
                onChanged: (v) => setState(() => _selectedDriver = v),
              ),
            ),
            const SizedBox(height: 16),
            _TripFormField(
              label: 'Assign Vehicle',
              child: _TripDropdown(
                value: _selectedVehicle,
                hint: 'Select a vehicle',
                items: _vehicles,
                onChanged: (v) => setState(() => _selectedVehicle = v),
              ),
            ),
            const SizedBox(height: 24),

            // Map Preview placeholder
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E0E0)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: const Color(0xFFE8E6E0),
                      child: const Center(
                        child: Icon(Icons.map_outlined, size: 64, color: Color(0xFFB0ADA8)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map_outlined, size: 14, color: Colors.white70),
                          SizedBox(width: 6),
                          Text(
                            'Route visualization will appear here',
                            style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(onConfirm: () => _confirmTrip(context)),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _confirmTrip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Trip dispatched successfully!'),
        backgroundColor: AppTheme.statusActive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.of(context).pop();
  }
}

// ==================== WIDGETS ====================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 22),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TripFormField extends StatelessWidget {
  final String label;
  final Widget child;
  const _TripFormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  const _StyledInput({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        filled: true,
        fillColor: AppTheme.bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
      ),
    );
  }
}

class _LocationInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData leadIcon;
  final IconData trailIcon;
  final VoidCallback onTrailTap;

  const _LocationInput({
    required this.controller,
    required this.hintText,
    required this.leadIcon,
    required this.trailIcon,
    required this.onTrailTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 14),
        prefixIcon: Icon(leadIcon, color: AppTheme.primaryBlue.withOpacity(0.7), size: 20),
        suffixIcon: IconButton(
          icon: Icon(trailIcon, color: AppTheme.primaryBlue, size: 20),
          onPressed: onTrailTap,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        filled: true,
        fillColor: AppTheme.bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({required this.value, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E0E0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: value.contains('Select') ? AppTheme.textTertiary : AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(icon, size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _TripDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _TripDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: AppTheme.textTertiary)),
          isExpanded: true,
          icon: const Icon(Icons.expand_more, size: 20, color: AppTheme.primaryBlue),
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onConfirm;
  const _BottomBar({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.bgPrimary,
        border: Border(top: BorderSide(color: Color(0xFFE2E0E0))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.send_outlined, size: 20),
          label: const Text('Confirm and Dispatch Trip'),
        ),
      ),
    );
  }
}
