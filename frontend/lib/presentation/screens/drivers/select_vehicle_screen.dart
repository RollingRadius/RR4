import 'package:flutter/material.dart';

class SelectVehicleScreen extends StatefulWidget {
  final String driverName;
  final String driverId;

  const SelectVehicleScreen({
    super.key,
    this.driverName = 'Driver',
    this.driverId = '',
  });

  @override
  State<SelectVehicleScreen> createState() => _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends State<SelectVehicleScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  final _searchController = TextEditingController();
  String _activeFilter = 'All Units';

  final _filters = ['All Units', 'Heavy Duty', 'Medium Duty', 'Low Fuel'];

  // Mock data – replace with real API data
  final _vehicles = [
    {
      'unitId': 'TRK-8821-B',
      'model': 'Freightliner Cascadia 2024',
      'status': 'Available',
      'fuel': 85,
      'odometer': '42,300 mi',
    },
    {
      'unitId': 'TRK-9055-A',
      'model': 'Volvo VNL 860 2023',
      'status': 'Low Fuel',
      'fuel': 12,
      'odometer': '108,120 mi',
    },
    {
      'unitId': 'DEL-4412-M',
      'model': 'Kenworth T680 2022',
      'status': 'Available',
      'fuel': 64,
      'odometer': '12,450 mi',
    },
  ];

  List<Map<String, dynamic>> get _filteredVehicles {
    return _vehicles.where((v) {
      final query = _searchController.text.toLowerCase();
      final matchesSearch = query.isEmpty ||
          (v['unitId'] as String).toLowerCase().contains(query) ||
          (v['model'] as String).toLowerCase().contains(query);
      final matchesFilter = _activeFilter == 'All Units' ||
          (_activeFilter == 'Low Fuel' && v['status'] == 'Low Fuel') ||
          (_activeFilter == 'Heavy Duty' || _activeFilter == 'Medium Duty');
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Sticky header
          Material(
            color: _bg,
            elevation: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: _primary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Assign Vehicle',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  // Driver context card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primary.withAlpha(26)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: _primary.withAlpha(30),
                                child: const Icon(Icons.person, color: _primary, size: 28),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ASSIGNING TO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  widget.driverName,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.2),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                            child: const Text(
                              'Change',
                              style: TextStyle(color: _primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Search + filter
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Column(
                      children: [
                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search Unit ID, VIN or Model...',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              prefixIcon: Icon(Icons.search, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Filter chips
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filters.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final filter = _filters[i];
                              final active = filter == _activeFilter;
                              return GestureDetector(
                                onTap: () => setState(() => _activeFilter = filter),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: active ? _primary : Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: active ? _primary : Colors.grey[300]!),
                                    boxShadow: active
                                        ? [BoxShadow(color: _primary.withAlpha(60), blurRadius: 8)]
                                        : null,
                                  ),
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      color: active ? Colors.white : Colors.grey[700],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Count + sort
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_filteredVehicles.length} Available Vehicles',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Row(
                            children: [
                              const Icon(Icons.sort, size: 16, color: _primary),
                              const SizedBox(width: 4),
                              const Text('Sort', style: TextStyle(fontSize: 13, color: _primary, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Vehicle list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _filteredVehicles.length,
              itemBuilder: (context, i) => _VehicleCard(
                vehicle: _filteredVehicles[i],
                onSelect: () => Navigator.pop(context, _filteredVehicles[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final VoidCallback onSelect;

  const _VehicleCard({required this.vehicle, required this.onSelect});

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    final isLowFuel = vehicle['status'] == 'Low Fuel';
    final fuel = vehicle['fuel'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Image + info row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder image
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_shipping, color: Colors.grey, size: 40),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isLowFuel ? Colors.orange[50] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (vehicle['status'] as String).toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isLowFuel ? Colors.orange[700] : Colors.grey[600],
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Icon(Icons.info_outline, color: Colors.grey[300], size: 18),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vehicle['unitId'] as String,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        vehicle['model'] as String,
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.local_gas_station,
                    label: 'FUEL LEVEL',
                    value: '$fuel%',
                    iconColor: isLowFuel ? Colors.orange : _primary,
                    valueColor: isLowFuel ? Colors.orange[700] : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    icon: Icons.speed,
                    label: 'ODOMETER',
                    value: vehicle['odometer'] as String,
                    iconColor: _primary,
                  ),
                ),
              ],
            ),
          ),
          // Select button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Select Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color? valueColor;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.valueColor,
  });

  static const _bg = Color(0xFFF8F6F6);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey[400])),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
            ],
          ),
        ],
      ),
    );
  }
}
