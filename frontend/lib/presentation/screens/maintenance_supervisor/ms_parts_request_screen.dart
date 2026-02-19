import 'package:flutter/material.dart';

class MsPartsRequestScreen extends StatefulWidget {
  const MsPartsRequestScreen({super.key});

  @override
  State<MsPartsRequestScreen> createState() => _MsPartsRequestScreenState();
}

class _MsPartsRequestScreenState extends State<MsPartsRequestScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  int _selectedPriority = 1; // 0=Routine, 1=Urgent, 2=Critical
  int _qty = 1;
  final _notesCtrl = TextEditingController()
    ..text = 'Brake pad thickness measured below 2mm on front-left assembly. '
        'Noticeable scoring on rotor surface. Requesting high-durability pads due to heavy load cycles.';

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text('Parts Request', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.black87),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E2E2)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _buildContextCard(),
                const SizedBox(height: 20),
                _buildPartsSearch(),
                const SizedBox(height: 20),
                _buildPrioritySelector(),
                const SizedBox(height: 20),
                _buildNotes(),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildSubmitFooter(context),
    );
  }

  Widget _buildContextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Vehicle: Truck-042',
                      style: TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('FAIL', style: TextStyle(color: Color(0xFFDC2626), fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Front Brake Pads', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                const Text('Scheduled maintenance inspection failure.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E2E2)),
            ),
            child: const Icon(Icons.album_outlined, size: 32, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPartsSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SELECT COMPATIBLE PARTS', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search for parts...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Part 1: In stock
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E2E2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Heavy Duty Ceramic Pads', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('ID: BP-77291 • In Stock: 14', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              _QtySelector(
                value: _qty,
                onChanged: (v) => setState(() => _qty = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Part 2: Out of stock
        Opacity(
          opacity: 0.55,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E2E2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Standard OEM Pads', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54)),
                      Text('ID: BP-44210 • Out of Stock', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: null,
                  child: Text('ADD', style: TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PRIORITY LEVEL', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _PriorityButton(label: 'Routine', icon: Icons.calendar_today_outlined, selected: _selectedPriority == 0, onTap: () => setState(() => _selectedPriority = 0), selectedColor: _primary)),
            const SizedBox(width: 8),
            Expanded(child: _PriorityButton(label: 'Urgent', icon: Icons.priority_high, selected: _selectedPriority == 1, onTap: () => setState(() => _selectedPriority = 1), selectedColor: _primary)),
            const SizedBox(width: 8),
            Expanded(child: _PriorityButton(label: 'Critical', icon: Icons.warning_outlined, selected: _selectedPriority == 2, onTap: () => setState(() => _selectedPriority = 2), selectedColor: const Color(0xFFEF4444))),
          ],
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TECHNICIAN NOTES', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        TextField(
          controller: _notesCtrl,
          maxLines: 5,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Describe failure details or specific part requirements...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(top: BorderSide(color: Color(0xFFE2E2E2))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          icon: const Icon(Icons.send_outlined, size: 20),
          label: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}

class _QtySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _QtySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E2E2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () { if (value > 1) onChanged(value - 1); },
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Icon(Icons.remove, size: 16, color: Color(0xFFEC5B13))),
          ),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          GestureDetector(
            onTap: () => onChanged(value + 1),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), child: Icon(Icons.add, size: 16, color: Color(0xFFEC5B13))),
          ),
        ],
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _PriorityButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? selectedColor : const Color(0xFFE2E2E2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? selectedColor : Colors.grey, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? selectedColor : Colors.black87,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
