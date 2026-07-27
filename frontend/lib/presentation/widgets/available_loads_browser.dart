import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fleet_management/data/models/load_requirement_model.dart';
import 'package:fleet_management/providers/available_loads_provider.dart';

const _primary = Color(0xFFFF6B00);
const _secondary = Color(0xFF546067);
const _surfaceLowest = Color(0xFFFFFFFF);
const _surfaceContainer = Color(0xFFECEEF0);
const _background = Color(0xFFF6F7F8);

TextStyle _manrope({double size = 14, FontWeight weight = FontWeight.w700, Color color = const Color(0xFF191C1E)}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
TextStyle _inter({double size = 13, FontWeight weight = FontWeight.w400, Color color = _secondary}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

String _buildMessage(LoadRequirementModel load) {
  final lines = <String>[
    '*Load Requirements*',
    'Ref: ${load.refId}',
    if (load.pickupLocation != null) '📍 Pickup: ${load.pickupLocation}',
    if (load.unloadLocation != null) '🏁 Drop: ${load.unloadLocation}',
    if (load.entryDate != null) '📅 Date: ${load.entryDate}',
    'Trucks Needed: ${load.truckCount}',
    if (load.materialType != null) 'Material: ${load.materialType}',
    if (load.capacity != null) 'Capacity: ${load.capacity}',
    if (load.bodyType != null) 'Body Type: ${load.bodyType}',
    if (load.axelType != null) 'Axel Type: ${load.axelType}',
    if (load.floorType != null) 'Floor Type: ${load.floorType}',
    if (load.companyName != null) 'Company: ${load.companyName}',
    if (load.companyCity != null || load.companyState != null)
      '📌 Location: ${[
        if (load.companyCity != null) load.companyCity!,
        if (load.companyState != null) load.companyState!,
      ].join(', ')}',
    if (load.companyPhone != null) '📞 Contact: ${load.companyPhone}',
  ];
  return lines.join('\n');
}

String _buildCombinedMessage(List<LoadRequirementModel> loads) {
  final blocks = <String>[];
  for (var i = 0; i < loads.length; i++) {
    blocks.add('${i + 1}. ${_buildMessage(loads[i])}');
  }
  return blocks.join('\n\n');
}

/// Shared LP/RR-ops "browse load requirements" experience — search by
/// pickup/drop, multi-select any number of requirements, and copy them as
/// one combined, numbered text block. No fulfill action here: fulfilling a
/// load requirement is a separate, not-yet-enabled flow for a later phase.
class AvailableLoadsBrowser extends ConsumerStatefulWidget {
  const AvailableLoadsBrowser({super.key});

  @override
  ConsumerState<AvailableLoadsBrowser> createState() => _AvailableLoadsBrowserState();
}

class _AvailableLoadsBrowserState extends ConsumerState<AvailableLoadsBrowser> {
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(availableLoadsProvider.notifier).loadAvailableLoads();
    });
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    super.dispose();
  }

  void _search() {
    setState(() => _selectedIds.clear());
    ref.read(availableLoadsProvider.notifier).loadAvailableLoads(
          pickup: _pickupCtrl.text.trim(),
          drop: _dropCtrl.text.trim(),
        );
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _copySelected(List<LoadRequirementModel> allLoads) {
    final selected = allLoads.where((l) => _selectedIds.contains(l.id)).toList();
    if (selected.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _buildCombinedMessage(selected)));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(selected.length == 1
          ? 'Load requirement copied to clipboard'
          : '${selected.length} load requirements copied to clipboard'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
    setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(availableLoadsProvider);

    return Column(
      children: [
        // ── Search bar ─────────────────────────────────────────────────
        Container(
          color: _background,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search Loads', style: _manrope(size: 20, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Browse pending requirements from load owners', style: _inter(size: 12, color: _secondary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SearchField(controller: _pickupCtrl, hint: 'Pickup city…', icon: Icons.trip_origin_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SearchField(controller: _dropCtrl, hint: 'Drop city…', icon: Icons.location_on_outlined),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _search,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Results ────────────────────────────────────────────────────
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : state.error != null
                  ? _LoadsError(message: state.error!)
                  : state.loads.isEmpty
                      ? const _LoadsEmpty()
                      : RefreshIndicator(
                          color: _primary,
                          onRefresh: () => ref.read(availableLoadsProvider.notifier).loadAvailableLoads(
                                pickup: _pickupCtrl.text.trim(),
                                drop: _dropCtrl.text.trim(),
                              ),
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(16, 4, 16, _selectedIds.isEmpty ? 24 : 90),
                            itemCount: state.loads.length,
                            itemBuilder: (_, i) {
                              final load = state.loads[i];
                              return _LoadCard(
                                load: load,
                                selected: _selectedIds.contains(load.id),
                                onToggleSelect: () => _toggleSelect(load.id),
                              );
                            },
                          ),
                        ),
        ),

        // ── Copy Selected bar ────────────────────────────────────────────
        if (_selectedIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: _surfaceLowest,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _copySelected(state.loads),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text('Copy Selected (${_selectedIds.length})',
                        style: _manrope(size: 14, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _SearchField({required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: _inter(size: 13, color: const Color(0xFF191C1E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _inter(size: 13),
        prefixIcon: Icon(icon, size: 16, color: _secondary),
        filled: true,
        fillColor: _background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _surfaceContainer)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _surfaceContainer)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
      ),
    );
  }
}

// ── Load card ──────────────────────────────────────────────────────────────────

class _LoadCard extends StatelessWidget {
  final LoadRequirementModel load;
  final bool selected;
  final VoidCallback onToggleSelect;
  const _LoadCard({required this.load, required this.selected, required this.onToggleSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        border: selected ? Border.all(color: _primary, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onToggleSelect,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(value: selected, onChanged: (_) => onToggleSelect(), activeColor: _primary),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(load.refId, style: _manrope(size: 13, weight: FontWeight.w800, color: const Color(0xFF001e40))),
                                  if (load.companyName != null)
                                    Text(load.companyName!, style: _inter(size: 12, weight: FontWeight.w600, color: _secondary)),
                                  if (load.companyCity != null || load.companyState != null)
                                    Text(
                                      [
                                        if (load.companyCity != null) load.companyCity!,
                                        if (load.companyState != null) load.companyState!,
                                      ].join(', '),
                                      style: _inter(size: 11, color: _secondary),
                                    ),
                                ],
                              ),
                            ),
                            _LoadStatusChip(status: load.status),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _RouteRow(pickup: load.pickupLocation ?? '—', drop: load.unloadLocation ?? '—'),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _primary.withValues(alpha: 0.20), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_shipping_outlined, size: 15, color: _primary),
                              const SizedBox(width: 7),
                              Text('Trucks Needed: ', style: _inter(size: 12, weight: FontWeight.w500, color: const Color(0xFF7A3200))),
                              Text('${load.truckCount}', style: _manrope(size: 14, weight: FontWeight.w800, color: _primary)),
                              Text(' truck${load.truckCount == 1 ? '' : 's'}', style: _inter(size: 12, weight: FontWeight.w600, color: const Color(0xFF7A3200))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            if (load.materialType != null) _SpecChip(icon: Icons.inventory_2_outlined, label: load.materialType!),
                            if (load.capacity != null) _SpecChip(icon: Icons.scale_outlined, label: load.capacity!),
                            if (load.axelType != null) _SpecChip(icon: Icons.settings_outlined, label: load.axelType!),
                            if (load.bodyType != null) _SpecChip(icon: Icons.category_outlined, label: load.bodyType!),
                            if (load.entryDate != null) _SpecChip(icon: Icons.calendar_today_outlined, label: load.entryDate!),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _surfaceContainer.withValues(alpha: 0.7), indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _copyDetails(context, load),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF001E40).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF001E40).withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF001E40)),
                            const SizedBox(width: 6),
                            Text('Copy Details', style: _manrope(size: 12, weight: FontWeight.w700, color: const Color(0xFF001E40))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _shareOnWhatsApp(context, load),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.40)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle),
                              child: const Icon(Icons.chat_rounded, size: 9, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            Text('WhatsApp', style: _manrope(size: 12, weight: FontWeight.w700, color: const Color(0xFF128C7E))),
                          ],
                        ),
                      ),
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

  void _copyDetails(BuildContext context, LoadRequirementModel load) {
    Clipboard.setData(ClipboardData(text: _buildMessage(load)));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Load details copied to clipboard'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _shareOnWhatsApp(BuildContext context, LoadRequirementModel load) async {
    final encoded = Uri.encodeComponent(_buildMessage(load));
    final url = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open WhatsApp'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

class _RouteRow extends StatelessWidget {
  final String pickup;
  final String drop;
  const _RouteRow({required this.pickup, required this.drop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.trip_origin_rounded, size: 14, color: _primary),
              const SizedBox(width: 6),
              Expanded(child: Text(pickup, style: _inter(size: 12, weight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_rounded, size: 14, color: _secondary),
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: _primary),
              const SizedBox(width: 6),
              Expanded(child: Text(drop, style: _inter(size: 12, weight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(8), border: Border.all(color: _surfaceContainer)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _secondary),
          const SizedBox(width: 5),
          Text(label, style: _inter(size: 11, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _LoadStatusChip extends StatelessWidget {
  final String status;
  const _LoadStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final color = isPending ? _primary : _secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: _inter(size: 10, weight: FontWeight.w700, color: color)),
    );
  }
}

class _LoadsError extends StatelessWidget {
  final String message;
  const _LoadsError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: _secondary),
            const SizedBox(height: 12),
            Text(message, style: _inter(size: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LoadsEmpty extends StatelessWidget {
  const _LoadsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 44, color: _secondary),
            const SizedBox(height: 12),
            Text('No pending load requirements', style: _inter(size: 13, color: _secondary)),
          ],
        ),
      ),
    );
  }
}
