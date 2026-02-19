import 'package:flutter/material.dart';
import 'package:fleet_management/core/theme/app_theme.dart';

enum _InspectionResult { none, pass, fail }

class DigitalInspectionScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const DigitalInspectionScreen({
    super.key,
    this.vehicleId = 'TRK-042',
    this.vehicleName = 'Truck-042',
  });

  @override
  State<DigitalInspectionScreen> createState() => _DigitalInspectionScreenState();
}

class _DigitalInspectionScreenState extends State<DigitalInspectionScreen> {
  // Map of item key → result
  final Map<String, _InspectionResult> _results = {};

  static const _sections = [
    _InspectionSection(
      title: 'Exterior',
      items: [
        _InspectionItem(key: 'lights', label: 'Lights', subtitle: 'Headlights, signals, brake lights'),
        _InspectionItem(key: 'tires', label: 'Tires', subtitle: 'Pressure, tread depth, sidewalls'),
        _InspectionItem(key: 'body', label: 'Body Condition', subtitle: 'Dents, scratches, damage'),
        _InspectionItem(key: 'mirrors', label: 'Mirrors', subtitle: 'Position, cracks, visibility'),
      ],
    ),
    _InspectionSection(
      title: 'Engine',
      items: [
        _InspectionItem(key: 'oil', label: 'Oil Level & Condition', subtitle: 'Check dipstick and quality'),
        _InspectionItem(key: 'coolant', label: 'Coolant Level', subtitle: 'Reservoir level and color'),
        _InspectionItem(key: 'belts', label: 'Belts & Hoses', subtitle: 'Wear, cracks, tension'),
        _InspectionItem(key: 'battery', label: 'Battery Terminals', subtitle: 'Corrosion, connections'),
      ],
    ),
    _InspectionSection(
      title: 'Interior',
      items: [
        _InspectionItem(key: 'brakes', label: 'Brakes & Pedal Feel', subtitle: 'Responsiveness, firmness'),
        _InspectionItem(key: 'horn', label: 'Horn', subtitle: 'Sound and function'),
        _InspectionItem(key: 'steering', label: 'Steering', subtitle: 'Play, alignment, response'),
        _InspectionItem(key: 'seatbelts', label: 'Seat Belts', subtitle: 'Latch, retract, webbing'),
      ],
    ),
  ];

  int get _totalItems => _sections.fold(0, (sum, s) => sum + s.items.length);

  int get _completedItems =>
      _results.values.where((r) => r != _InspectionResult.none).length;

  double get _progress => _totalItems == 0 ? 0 : _completedItems / _totalItems;

  _InspectionResult _getResult(String key) =>
      _results[key] ?? _InspectionResult.none;

  void _setResult(String key, _InspectionResult result) {
    setState(() => _results[key] = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.bgSecondary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.black12,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Vehicle Inspection - ${widget.vehicleName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'IN PROGRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Progress',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        Text(
                          '$_completedItems / $_totalItems items',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8E6E6),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            for (final section in _sections) ...[
              _SectionHeader(title: section.title, count: section.items.length),
              const SizedBox(height: 12),
              for (final item in section.items) ...[
                _InspectionCard(
                  item: item,
                  result: _getResult(item.key),
                  onPass: () => _setResult(item.key, _InspectionResult.pass),
                  onFail: () => _setResult(item.key, _InspectionResult.fail),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _SubmitBar(
        completed: _completedItems,
        total: _totalItems,
        onSubmit: () => _submitInspection(context),
      ),
    );
  }

  void _submitInspection(BuildContext context) {
    final failCount = _results.values.where((r) => r == _InspectionResult.fail).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failCount > 0
              ? 'Inspection submitted — $failCount item(s) failed'
              : 'Inspection completed — all items passed!',
        ),
        backgroundColor: failCount > 0 ? Colors.orange : AppTheme.statusActive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.of(context).pop();
  }
}

// ==================== SECTION HEADER ====================
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppTheme.primaryBlue, width: 4)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count items)',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ==================== INSPECTION CARD ====================
class _InspectionCard extends StatelessWidget {
  final _InspectionItem item;
  final _InspectionResult result;
  final VoidCallback onPass;
  final VoidCallback onFail;

  const _InspectionCard({
    required this.item,
    required this.result,
    required this.onPass,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result == _InspectionResult.pass
              ? const Color(0xFF10B981).withOpacity(0.3)
              : result == _InspectionResult.fail
                  ? const Color(0xFFEF4444).withOpacity(0.3)
                  : const Color(0xFFE2E0E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add note/photo — coming soon')),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 14, color: AppTheme.primaryBlue),
                    SizedBox(width: 4),
                    Text(
                      'Add Note/Photo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ResultButton(
                  label: 'PASS',
                  icon: Icons.check_circle_outline,
                  selected: result == _InspectionResult.pass,
                  selectedColor: const Color(0xFF10B981),
                  onTap: onPass,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResultButton(
                  label: 'FAIL',
                  icon: Icons.cancel_outlined,
                  selected: result == _InspectionResult.fail,
                  selectedColor: const Color(0xFFEF4444),
                  onTap: onFail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ResultButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        decoration: BoxDecoration(
          color: selected ? selectedColor : const Color(0xFFF5F3F3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? selectedColor : const Color(0xFFE2E0E0),
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: selectedColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== SUBMIT BAR ====================
class _SubmitBar extends StatelessWidget {
  final int completed;
  final int total;
  final VoidCallback onSubmit;

  const _SubmitBar({required this.completed, required this.total, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final allDone = completed == total;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(top: BorderSide(color: Color(0xFFE2E0E0))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: allDone ? onSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE2E0E0),
            disabledForegroundColor: AppTheme.textSecondary,
            elevation: allDone ? 4 : 0,
            shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.fact_check_outlined, size: 20),
          label: Text(allDone ? 'Submit Inspection' : 'Complete all items ($completed/$total)'),
        ),
      ),
    );
  }
}

// ==================== DATA CLASSES ====================
class _InspectionSection {
  final String title;
  final List<_InspectionItem> items;
  const _InspectionSection({required this.title, required this.items});
}

class _InspectionItem {
  final String key;
  final String label;
  final String subtitle;
  const _InspectionItem({required this.key, required this.label, required this.subtitle});
}
