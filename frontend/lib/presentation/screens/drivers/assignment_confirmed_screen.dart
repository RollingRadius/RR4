import 'package:flutter/material.dart';

class AssignmentConfirmedScreen extends StatelessWidget {
  final String driverName;
  final String driverRole;
  final String vehicleName;
  final String vehicleUnitId;

  const AssignmentConfirmedScreen({
    super.key,
    this.driverName = 'Marcus Thompson',
    this.driverRole = 'Heavy Duty Operator',
    this.vehicleName = 'Freightliner Cascadia 2024',
    this.vehicleUnitId = '#TRK-8821-B',
  });

  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);
  static const _success = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Confirmation',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Success icon with glow
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _success.withAlpha(50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: _success, size: 48),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Vehicle Assigned Successfully',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The driver and vehicle are now linked in the system and ready for dispatch.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      // Assignment card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(16),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            // Driver row
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: _primary.withAlpha(30),
                                    child: const Icon(Icons.person, color: _primary, size: 32),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'DRIVER',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: _primary,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        Text(
                                          driverName,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                                        ),
                                        Text(
                                          driverRole,
                                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.verified, color: _success, size: 22),
                                ],
                              ),
                            ),
                            // Link divider
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _primary.withAlpha(26),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.link, color: _primary, size: 14),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                ],
                              ),
                            ),
                            // Vehicle row
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: const Icon(Icons.local_shipping, color: Colors.grey, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'VEHICLE',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: _primary,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        Text(
                                          vehicleName,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _primary.withAlpha(40),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'UNIT ID: $vehicleUnitId',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: _primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.local_shipping, color: Colors.grey[400], size: 20),
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
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Go to Trip Assignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey[300]!, width: 2),
                      ),
                      child: const Text('View Vehicle Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Return to Fleet Overview',
                      style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
