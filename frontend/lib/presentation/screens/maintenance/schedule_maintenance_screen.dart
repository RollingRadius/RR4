import 'package:flutter/material.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

class ScheduleMaintenanceScreen extends StatefulWidget {
  final String? vehicleId;
  final String? vehicleName;

  const ScheduleMaintenanceScreen({
    super.key,
    this.vehicleId,
    this.vehicleName,
  });

  @override
  State<ScheduleMaintenanceScreen> createState() => _ScheduleMaintenanceScreenState();
}

class _ScheduleMaintenanceScreenState extends State<ScheduleMaintenanceScreen> {
  String _serviceType = 'Oil Change & Filter';
  String _priority = 'medium';
  String _technician = 'Mark Johnson (Lead Mechanic)';
  DateTime _selectedDate = DateTime(2023, 10, 24);
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  static const _serviceTypes = [
    'Oil Change & Filter',
    'Brake Inspection',
    'Engine Repair',
    'Tire Rotation',
    'Annual Inspection',
  ];

  static const _technicians = [
    'Mark Johnson (Lead Mechanic)',
    'Sarah Williams (Diagnostics)',
    'Unassigned',
  ];

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
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
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Schedule Maintenance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Information
            _SectionHeader(label: 'Vehicle Information'),
            const SizedBox(height: 12),
            _VehicleCard(
              vehicleName: widget.vehicleName ?? 'Freightliner Cascadia',
              vehicleId: widget.vehicleId ?? 'FL-7729',
              onChangeTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select vehicle — coming soon')),
                );
              },
            ),
            const SizedBox(height: 24),

            // Service Details
            _SectionHeader(label: 'Service Details'),
            const SizedBox(height: 12),
            _FormLabel(label: 'Service Type'),
            const SizedBox(height: 8),
            _StyledDropdown<String>(
              value: _serviceType,
              items: _serviceTypes,
              onChanged: (v) => setState(() => _serviceType = v!),
            ),
            const SizedBox(height: 16),
            _FormLabel(label: 'Priority Level'),
            const SizedBox(height: 8),
            _PrioritySelector(
              value: _priority,
              onChanged: (v) => setState(() => _priority = v),
            ),
            const SizedBox(height: 24),

            // Scheduling
            _SectionHeader(label: 'Scheduling'),
            const SizedBox(height: 12),
            _FormLabel(label: 'Assign Technician'),
            const SizedBox(height: 8),
            _StyledDropdown<String>(
              value: _technician,
              items: _technicians,
              onChanged: (v) => setState(() => _technician = v!),
              suffixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormLabel(label: 'Date'),
                      const SizedBox(height: 8),
                      _DateField(
                        date: _selectedDate,
                        onTap: () => _pickDate(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormLabel(label: 'Time'),
                      const SizedBox(height: 8),
                      _TimeField(
                        time: _selectedTime,
                        onTap: () => _pickTime(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FormLabel(label: 'Estimated Duration'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StyledTextField(
                    controller: _durationController,
                    hintText: 'e.g. 3.5',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E6E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Hours',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Additional Information
            _SectionHeader(label: 'Additional Information'),
            const SizedBox(height: 12),
            _FormLabel(label: 'Notes / Special Instructions'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: _notesController,
              hintText: 'Mention any specific issues reported by the driver...',
              maxLines: 4,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActionBar(
        onSchedule: () => _submitForm(context),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
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
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _submitForm(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Maintenance scheduled successfully!'),
        backgroundColor: AppTheme.statusActive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ==================== SECTION HEADER ====================
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

// ==================== VEHICLE CARD ====================
class _VehicleCard extends StatelessWidget {
  final String vehicleName;
  final String vehicleId;
  final VoidCallback onChangeTap;

  const _VehicleCard({
    required this.vehicleName,
    required this.vehicleId,
    required this.onChangeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F0F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              size: 32,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicleName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $vehicleId',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChangeTap,
            child: const Text(
              'Change',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== STYLED DROPDOWN ====================
class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final IconData suffixIcon;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.suffixIcon = Icons.expand_more,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(suffixIcon, size: 20, color: AppTheme.textSecondary),
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontFamily: 'Public Sans',
          ),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ==================== PRIORITY SELECTOR ====================
class _PrioritySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _PrioritySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _PriorityButton(label: 'Low', dotColor: const Color(0xFF10B981), selected: value == 'low', onTap: () => onChanged('low'))),
        const SizedBox(width: 8),
        Expanded(child: _PriorityButton(label: 'Medium', dotColor: const Color(0xFFF59E0B), selected: value == 'medium', onTap: () => onChanged('medium'))),
        const SizedBox(width: 8),
        Expanded(child: _PriorityButton(label: 'High', dotColor: const Color(0xFFEF4444), selected: value == 'high', onTap: () => onChanged('high'))),
      ],
    );
  }
}

class _PriorityButton extends StatelessWidget {
  final String label;
  final Color dotColor;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityButton({
    required this.label,
    required this.dotColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : const Color(0xFFE2E0E0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DATE / TIME FIELDS ====================
class _DateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
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
                formatted,
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeField({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
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
                '$hour:$minute',
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
            ),
            const Icon(Icons.access_time_outlined, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ==================== STYLED TEXT FIELD ====================
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final TextInputType? keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

// ==================== BOTTOM ACTION BAR ====================
class _BottomActionBar extends StatelessWidget {
  final VoidCallback onSchedule;

  const _BottomActionBar({required this.onSchedule});

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
          onPressed: onSchedule,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.event_available_outlined, size: 22),
          label: const Text('Schedule Service'),
        ),
      ),
    );
  }
}
