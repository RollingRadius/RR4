import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';

class UploadLoadRequirementScreen extends ConsumerStatefulWidget {
  const UploadLoadRequirementScreen({super.key});

  @override
  ConsumerState<UploadLoadRequirementScreen> createState() =>
      _UploadLoadRequirementScreenState();
}

class _UploadLoadRequirementScreenState
    extends ConsumerState<UploadLoadRequirementScreen> {
  // Colours matching the Stitch design
  static const Color _primary = Color(0xFF001e40);
  static const Color _background = Color(0xFFF7F9FB);
  static const Color _surfaceContainer = Color(0xFFECEEF0);
  static const Color _surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _onSurfaceVariant = Color(0xFF43474F);
  static const Color _outlineVariant = Color(0xFFC3C6D1);

  // State
  String _entryMethod = 'manual'; // 'manual' | 'bulk' | 'photo'
  bool _truckSpecsExpanded = true;
  bool _isSubmitting = false;
  int _truckCount = 8;
  String? _materialType = 'Steel Coils';
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  DateTime? _entryDate;

  int _selectedNavIndex = 0;

  final List<String> _materials = [
    'Steel Coils',
    'Perishables',
    'Electronics',
    'Industrial',
  ];

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final initials = _initials(user?.fullName ?? 'JD');

    return Scaffold(
      backgroundColor: _background,
      appBar: _GlassAppBar(
        initials: initials,
        onBackTap: () => context.pop(),
      ),
      body: Stack(
        children: [
          // Scrollable content
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 160),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Section 1: Entry Method ─────────────────────
                    _sectionLabel('Entry Method'),
                    const SizedBox(height: 4),
                    Text(
                      'New Load',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _entryMethodToggle(),
                    const SizedBox(height: 28),

                    // ── Section 2: Manual Form ──────────────────────
                    if (_entryMethod == 'manual') ...[
                      _manualForm(),
                      const SizedBox(height: 28),
                    ],

                    // ── Section 3: Truck Specifications ────────────
                    _truckSpecsSection(),
                    const SizedBox(height: 28),

                    // ── Section 4: Bulk Upload ──────────────────────
                    _bulkUploadSection(),
                    const SizedBox(height: 28),

                    // ── Section 5: Photo Visual Verification ────────
                    _photoVerificationCard(),
                  ]),
                ),
              ),
            ],
          ),

          // Floating Submit button
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: _submitButton(),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _bottomNav(),
          ),
        ],
      ),
    );
  }

  // ── Entry Method Toggle ────────────────────────────────────────────────

  Widget _entryMethodToggle() {
    return Row(
      children: [
        _entryMethodButton(
          icon: Icons.edit_note,
          label: 'MANUAL',
          key: 'manual',
        ),
        const SizedBox(width: 10),
        _entryMethodButton(
          icon: Icons.upload_file,
          label: 'BULK',
          key: 'bulk',
        ),
        const SizedBox(width: 10),
        _entryMethodButton(
          icon: Icons.photo_camera,
          label: 'PHOTO',
          key: 'photo',
        ),
      ],
    );
  }

  Widget _entryMethodButton({
    required IconData icon,
    required String label,
    required String key,
  }) {
    final isActive = _entryMethod == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _entryMethod = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? _primary : _surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : _onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isActive ? Colors.white : _onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Manual Form ───────────────────────────────────────────────────────

  Widget _manualForm() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Route visual
          _routeInputs(),
          const SizedBox(height: 20),

          // Material + Date
          Row(
            children: [
              Expanded(child: _materialDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _datePicker()),
            ],
          ),
          const SizedBox(height: 16),

          // Truck count
          _truckCountRow(),
        ],
      ),
    );
  }

  Widget _routeInputs() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route line visual
        Column(
          children: [
            const SizedBox(height: 4),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primary, width: 2),
                color: _surfaceContainerLowest,
              ),
            ),
            SizedBox(
              width: 2,
              height: 48,
              child: CustomPaint(painter: _DashedLinePainter()),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),

        // Inputs
        Expanded(
          child: Column(
            children: [
              _formField(
                controller: _pickupController,
                label: 'Pickup Location',
                hint: 'Enter Origin Hub',
              ),
              const SizedBox(height: 20),
              _formField(
                controller: _dropController,
                label: 'Drop Location',
                hint: 'Enter Destination',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(
              fontSize: 15, color: Color(0xFF191C1E)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 14, color: Color(0xFF737780)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: _surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF001e40), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _materialDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Material Type'),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: _surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _materialType,
              isExpanded: true,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF191C1E)),
              dropdownColor: _surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              items: _materials.map((m) {
                return DropdownMenuItem(value: m, child: Text(m));
              }).toList(),
              onChanged: (v) => setState(() => _materialType = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Entry Date'),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _entryDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (ctx, child) => Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF001e40),
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _entryDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: Color(0xFF43474F)),
                const SizedBox(width: 8),
                Text(
                  _entryDate != null
                      ? '${_entryDate!.day}/${_entryDate!.month}/${_entryDate!.year}'
                      : 'Pick date',
                  style: TextStyle(
                    fontSize: 14,
                    color: _entryDate != null
                        ? const Color(0xFF191C1E)
                        : const Color(0xFF737780),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _truckCountRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Truck Count'),
                const SizedBox(height: 2),
                Text(
                  '${_truckCount.toString().padLeft(2, '0')} Units',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF001e40),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _countButton(
                icon: Icons.remove,
                onTap: () {
                  if (_truckCount > 1) {
                    setState(() => _truckCount--);
                  }
                },
                filled: false,
              ),
              const SizedBox(width: 10),
              _countButton(
                icon: Icons.add,
                onTap: () => setState(() => _truckCount++),
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? _primary : _surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(filled ? 0.15 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon,
            color: filled ? Colors.white : _primary, size: 20),
      ),
    );
  }

  // ── Truck Specifications Section ─────────────────────────────────────

  Widget _truckSpecsSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _truckSpecsExpanded = !_truckSpecsExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping,
                    color: Color(0xFF001e40), size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Truck Specifications',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF001e40),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _truckSpecsExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more,
                      color: Color(0xFF43474F)),
                ),
              ],
            ),
          ),
        ),
        if (_truckSpecsExpanded) ...[
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.0,
            children: [
              _specCard('Capacity', '24 Tons', accent: true),
              _specCard('Axel Type', 'Multi-Axel'),
              _specCard('Body', 'Open Body'),
              _specCard('Floor', 'Wooden'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _specCard(String label, String value, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: accent
            ? const Border(
                left: BorderSide(color: Color(0xFF001e40), width: 4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Color(0xFF43474F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF001e40),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bulk Upload Section ───────────────────────────────────────────────

  Widget _bulkUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Bulk Operations'),
        const SizedBox(height: 10),
        DragTarget<Object>(
          onAcceptWithDetails: (_) {},
          builder: (context, _, __) => Container(
            padding: const EdgeInsets.symmetric(
                vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: _surfaceContainerLow.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _outlineVariant,
                  width: 2,
                  style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF003366).withOpacity(0.1),
                  ),
                  child: const Icon(Icons.cloud_upload,
                      color: Color(0xFF001e40), size: 26),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Drag & Drop Manifest',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF001e40),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Excel or CSV (Max 5 Trips)',
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFF43474F)),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF001e40),
                    side: BorderSide(
                        color: _outlineVariant.withOpacity(0.4)),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Browse Files'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Photo Visual Verification ─────────────────────────────────────────

  Widget _photoVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF381300).withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF592300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.camera_alt,
                color: Color(0xFFD8885C), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visual Verification',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF001e40),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Capture load photos for instant AI data entry',
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFF43474F)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: Color(0xFF001e40), size: 22),
        ],
      ),
    );
  }

  // ── Submit Button ─────────────────────────────────────────────────────

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: _primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send, size: 20),
        label: Text(_isSubmitting ? 'Submitting…' : 'Submit Load Requirement'),
      ),
    );
  }

  // ── Bottom Navigation ─────────────────────────────────────────────────

  Widget _bottomNav() {
    return ClipRect(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF191C1E).withOpacity(0.07),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.upload_file, 'Upload'),
            _navItem(1, Icons.local_shipping, 'My Trips'),
            _navItem(2, Icons.inventory_2_outlined, 'Fleet'),
            _navItem(3, Icons.person_outline, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          context.push(AppConstants.routeLoadOwnerTrips);
          return;
        }
        if (index == 3) {
          _showProfileMenu();
          return;
        }
        setState(() => _selectedNavIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: isActive
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? Colors.white : _onSurfaceVariant,
                size: 22),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isActive ? Colors.white : _onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Color(0xFF43474F),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: Color(0xFF43474F),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'JD';
  }

  Future<void> _handleSubmit() async {
    final pickup = _pickupController.text.trim();
    final drop = _dropController.text.trim();

    if (pickup.isEmpty || drop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pickup and drop locations'),
          backgroundColor: Color(0xFF001e40),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_entryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an entry date'),
          backgroundColor: Color(0xFF001e40),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate brief loading — backend integration coming later
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // Capture values before clearing
    final submittedMaterial = _materialType ?? 'Steel Coils';
    final submittedTruckCount = _truckCount;
    final refId =
        'REQ-${(DateTime.now().millisecondsSinceEpoch % 900000 + 100000)}';

    _pickupController.clear();
    _dropController.clear();
    setState(() {
      _truckCount = 8;
      _entryDate = null;
      _materialType = 'Steel Coils';
      _isSubmitting = false;
    });

    // Show full-screen success page
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.15),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => _SubmissionSuccessPage(
        pickup: pickup,
        drop: drop,
        material: submittedMaterial,
        truckCount: submittedTruckCount,
        refId: refId,
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: Color(0xFF001e40)),
              title: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
                if (mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Glass App Bar ─────────────────────────────────────────────────────────

class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String initials;
  final VoidCallback onBackTap;

  const _GlassAppBar({required this.initials, required this.onBackTap});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB).withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF001e40), size: 22),
                  onPressed: onBackTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'RR Logistics',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF001e40),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF003366),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dashed Line Painter ───────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = const Color(0xFF001e40).withOpacity(0.3)
      ..strokeWidth = 2;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Submission Success Full-Screen Page ───────────────────────────────────────

class _SubmissionSuccessPage extends StatefulWidget {
  final String pickup;
  final String drop;
  final String material;
  final int truckCount;
  final String refId;

  const _SubmissionSuccessPage({
    required this.pickup,
    required this.drop,
    required this.material,
    required this.truckCount,
    required this.refId,
  });

  @override
  State<_SubmissionSuccessPage> createState() => _SubmissionSuccessPageState();
}

class _SubmissionSuccessPageState extends State<_SubmissionSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _iconScale;
  late final Animation<double> _contentFade;

  static const _primary = Color(0xFF001e40);
  static const _bg = Color(0xFFF7F9FB);
  static const _surfaceLowest = Color(0xFFFFFFFF);
  static const _surfaceContainerLow = Color(0xFFF2F4F6);
  static const _onSurfaceVariant = Color(0xFF43474F);
  static const _outlineVariant = Color(0xFFC3C6D1);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _iconScale = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
    _contentFade = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Centered success content ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
                child: Column(
                  children: [
                    // Animated icon
                    ScaleTransition(
                      scale: _iconScale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow halo
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD5E3FF).withOpacity(0.35),
                            ),
                          ),
                          // Icon card
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _surfaceLowest,
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              size: 52,
                              color: Color(0xFF1F477B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title + description
                    FadeTransition(
                      opacity: _contentFade,
                      child: Column(
                        children: [
                          const Text(
                            'Submission Successful',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: _primary,
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Your load requirement for '
                            '${widget.truckCount} units of ${widget.material} '
                            'has been received. Our team is now assigning the fleet.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.55,
                              color: _onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Reference ID chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: _surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _outlineVariant.withOpacity(0.5)),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'REFERENCE ID',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                    color: _onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.refId,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                    letterSpacing: 1.5,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Action buttons
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                context.push(AppConstants.routeLoadOwnerTrips);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: _primary.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                textStyle: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Track in My Trips'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primary,
                                side: BorderSide(
                                    color: _outlineVariant, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                textStyle: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              child: const Text('New Load Requirement'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Info panel ────────────────────────────────────────────
              FadeTransition(
                opacity: _contentFade,
                child: Container(
                  width: double.infinity,
                  color: _surfaceContainerLow,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _infoRow(
                        label: 'PROCESS UPDATE',
                        body:
                            'Fleet optimization algorithms are calculating the most efficient route for your cargo.',
                      ),
                      const SizedBox(height: 20),
                      _infoRow(
                        label: 'EXPECTED CONTACT',
                        body:
                            'Our logistics coordinator will reach out within 15 minutes for final verification.',
                        highlight: '15 minutes',
                      ),
                      const SizedBox(height: 20),
                      _infoRow(
                        label: 'FLEET STATUS',
                        body:
                            '4 heavy-duty trailers are currently available in your pickup zone.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String body,
    String? highlight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Accent bar
        Container(width: 3, height: 48, color: _primary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: _onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              highlight != null
                  ? RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 13,
                            color: _onSurfaceVariant,
                            height: 1.5),
                        children: _buildHighlightedText(body, highlight),
                      ),
                    )
                  : Text(
                      body,
                      style: const TextStyle(
                          fontSize: 13,
                          color: _onSurfaceVariant,
                          height: 1.5),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildHighlightedText(String text, String highlight) {
    final idx = text.indexOf(highlight);
    if (idx == -1) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, idx)),
      TextSpan(
        text: highlight,
        style: const TextStyle(
            fontWeight: FontWeight.w700, color: _primary),
      ),
      TextSpan(text: text.substring(idx + highlight.length)),
    ];
  }
}
