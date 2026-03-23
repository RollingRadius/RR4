import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/vehicle_provider.dart';

// ─── Typography ───────────────────────────────────────────────────────────────
TextStyle _manrope({
  double size = 14,
  FontWeight weight = FontWeight.w600,
  Color color = const Color(0xFF191C1E),
}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = const Color(0xFF546067),
}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

// ─── Colour tokens ────────────────────────────────────────────────────────────
const _primary = Color(0xFFFF6B00);
const _background = Color(0xFFF8F9FB);
const _surfaceLowest = Color(0xFFFFFFFF);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _tertiary = Color(0xFF006B5E);

// ─── Capability definitions ───────────────────────────────────────────────────

class _CapDef {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final String? route;
  final VoidCallback? Function(BuildContext ctx)? action;

  const _CapDef({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    this.route,
    this.action,
  });
}

final _capabilities = <_CapDef>[
  _CapDef(
    key: 'vehicle.view',
    title: 'View Vehicles',
    description: 'Browse fleet list & details',
    icon: Icons.directions_car_rounded,
    accent: const Color(0xFF006B5E),
    route: '/vehicles',
  ),
  _CapDef(
    key: 'vehicle.create',
    title: 'Add Vehicle',
    description: 'Register a new vehicle',
    icon: Icons.add_circle_outline_rounded,
    accent: _primary,
    route: '/vehicles/add',
  ),
  _CapDef(
    key: 'vehicle.edit',
    title: 'Edit Vehicle',
    description: 'Modify vehicle information',
    icon: Icons.edit_rounded,
    accent: const Color(0xFF1565C0),
    route: '/vehicles',
  ),
  _CapDef(
    key: 'vehicle.delete',
    title: 'Delete Vehicle',
    description: 'Remove a vehicle from fleet',
    icon: Icons.delete_outline_rounded,
    accent: const Color(0xFFBA1A1A),
    route: '/vehicles',
  ),
  _CapDef(
    key: 'vehicle.export',
    title: 'Export Data',
    description: 'Download vehicle data as CSV',
    icon: Icons.file_download_outlined,
    accent: const Color(0xFF6A1B9A),
    action: (ctx) => () => ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Export feature coming soon')),
        ),
  ),
  _CapDef(
    key: 'vehicle.import',
    title: 'Import Vehicles',
    description: 'Bulk import from spreadsheet',
    icon: Icons.file_upload_outlined,
    accent: const Color(0xFF00838F),
    action: (ctx) => () => ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Import feature coming soon')),
        ),
  ),
  _CapDef(
    key: 'vehicle.archive',
    title: 'Archive Vehicle',
    description: 'Deactivate without deletion',
    icon: Icons.archive_outlined,
    accent: const Color(0xFF546067),
    route: '/vehicles',
  ),
  _CapDef(
    key: 'vehicle.assign',
    title: 'Assign Vehicle',
    description: 'Link vehicle to a driver',
    icon: Icons.person_pin_circle_outlined,
    accent: const Color(0xFF2E7D32),
    route: '/vehicles',
  ),
  _CapDef(
    key: 'vehicle.documents.view',
    title: 'View Documents',
    description: 'Access vehicle documents',
    icon: Icons.folder_open_rounded,
    accent: const Color(0xFFBF360C),
    route: '/vehicles',
  ),
  _CapDef(
    key: 'vehicle.documents.upload',
    title: 'Upload Documents',
    description: 'Attach files to vehicle',
    icon: Icons.upload_file_rounded,
    accent: const Color(0xFF1A237E),
    route: '/vehicles',
  ),
  _CapDef(
    key: 'vehicle.documents.delete',
    title: 'Delete Documents',
    description: 'Remove attached documents',
    icon: Icons.delete_sweep_outlined,
    accent: const Color(0xFF880E4F),
    route: '/vehicles',
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class VehicleManagementScreen extends ConsumerWidget {
  const VehicleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleState = ref.watch(vehicleProvider);
    final vehicles = vehicleState.vehicles;
    final total = vehicles.length;
    final active = vehicles.where((v) => v['status'] == 'active').length;
    final maintenance =
        vehicles.where((v) => v['status'] == 'maintenance').length;

    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: _background,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: _onSurface, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Vehicle Management',
              style: _manrope(size: 17, weight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded,
                    color: _primary, size: 26),
                tooltip: 'Add vehicle',
                onPressed: () => context.push('/vehicles/add'),
              ),
            ],
          ),

          // ── Stats bar ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _StatChip(
                      label: 'Total', value: '$total', color: _primary),
                  const SizedBox(width: 8),
                  _StatChip(
                      label: 'Active',
                      value: '$active',
                      color: const Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  _StatChip(
                      label: 'Maintenance',
                      value: '$maintenance',
                      color: const Color(0xFF1565C0)),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Section header ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Capabilities',
                style: _manrope(size: 13, weight: FontWeight.w700,
                    color: _secondary),
              ),
            ),
          ),

          // ── Capability grid ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cap = _capabilities[index];
                  return _CapabilityCard(cap: cap);
                },
                childCount: _capabilities.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: _manrope(size: 18, weight: FontWeight.w800, color: color)),
          const SizedBox(width: 5),
          Text(label, style: _inter(size: 11, color: color)),
        ],
      ),
    );
  }
}

// ─── Capability Card ──────────────────────────────────────────────────────────

class _CapabilityCard extends StatelessWidget {
  final _CapDef cap;
  const _CapabilityCard({required this.cap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (cap.route != null) {
          context.push(cap.route!);
        } else if (cap.action != null) {
          cap.action!(context)?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: cap.accent.withValues(alpha: 0.18), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cap.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(cap.icon, color: cap.accent, size: 20),
            ),
            const Spacer(),
            Text(cap.title,
                style: _manrope(
                    size: 13, weight: FontWeight.w700, color: _onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(cap.description,
                style: _inter(size: 11, color: _secondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            // Capability key badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cap.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                cap.key,
                style: _inter(
                        size: 9,
                        weight: FontWeight.w600,
                        color: cap.accent)
                    .copyWith(fontFamily: 'monospace'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
