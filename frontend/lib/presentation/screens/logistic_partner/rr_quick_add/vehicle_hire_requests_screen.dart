import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';

const _primary = Color(0xFFFF6B00);
const _secondary = Color(0xFF546067);
const _onSurface = Color(0xFF191C1E);
const _success = Color(0xFF2E7D32);
const _error = Color(0xFFBA1A1A);
const _border = Color(0xFFECEEF0);

TextStyle _manrope({double size = 14, FontWeight weight = FontWeight.w700, Color color = _onSurface}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
TextStyle _inter({double size = 13, FontWeight weight = FontWeight.w400, Color color = _secondary}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

/// Lets LP/RR-ops review pending vehicle-hire requests (RR's "Market Vehicle"
/// marketplace — someone wants to hire a vehicle your company owns) and
/// Approve/Reject right here, instead of needing RR web's own dialog for it.
class VehicleHireRequestsScreen extends ConsumerStatefulWidget {
  const VehicleHireRequestsScreen({super.key});

  @override
  ConsumerState<VehicleHireRequestsScreen> createState() => _VehicleHireRequestsScreenState();
}

class _VehicleHireRequestsScreenState extends ConsumerState<VehicleHireRequestsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _errorMsg;
  String? _actingOnId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = await ensureRrSession(context, ref);
    if (session == null || !mounted) {
      setState(() { _loading = false; _errorMsg = 'RR login required'; });
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final items = await ref.read(rrSyncApiProvider).getVehicleHireRequests(session.token);
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _errorMsg = 'Could not load hire requests'; });
    }
  }

  Future<void> _reject(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reject hire request?', style: _manrope(size: 16)),
        content: Text(
          '${item['hirer_name'] ?? 'This company'} wants to hire vehicle ${item['vehicle_number'] ?? ''}. Reject this request?',
          style: _inter(size: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reject', style: TextStyle(color: _error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _submitReview(item, 'Rejected');
  }

  Future<void> _approve(Map<String, dynamic> item) async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Approved Start Date',
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: start.add(const Duration(days: 7)),
      firstDate: start,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Approved End Date',
    );
    if (end == null || !mounted) return;
    await _submitReview(item, 'Approved', start: start, end: end);
  }

  Future<void> _submitReview(Map<String, dynamic> item, String status, {DateTime? start, DateTime? end}) async {
    final marketVehicleId = item['market_vehicle_id'] as String;
    final session = await ensureRrSession(context, ref);
    if (session == null || !mounted) return;

    setState(() => _actingOnId = marketVehicleId);
    try {
      await ref.read(rrSyncApiProvider).reviewVehicleHireRequest(
            marketVehicleId: marketVehicleId,
            rrToken: session.token,
            status: status,
            approvedStartDate: start?.toIso8601String(),
            approvedEndDate: end?.toIso8601String(),
          );
      if (!mounted) return;
      setState(() {
        _items = _items.where((i) => i['market_vehicle_id'] != marketVehicleId).toList();
        _actingOnId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'Approved' ? 'Hire request approved' : 'Hire request rejected',
            style: _inter(size: 13, color: Colors.white)),
        backgroundColor: status == 'Approved' ? _success : _secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _actingOnId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Action failed. Please try again.', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Hire Requests', style: _manrope(size: 17, color: Colors.white)),
        backgroundColor: _primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg != null
              ? Center(child: Text(_errorMsg!, style: _inter(size: 13)))
              : _items.isEmpty
                  ? Center(
                      child: Text('No pending hire requests', style: _inter(size: 14)),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          final acting = _actingOnId == item['market_vehicle_id'];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: _border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Vehicle: ${item['vehicle_number'] ?? '—'}',
                                    style: _manrope(size: 14)),
                                const SizedBox(height: 4),
                                Text('Requested by: ${item['hirer_name'] ?? '—'}', style: _inter(size: 13)),
                                if (item['requested_start_date'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Requested: ${item['requested_start_date']} → ${item['requested_end_date']}',
                                    style: _inter(size: 12),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                if (acting)
                                  const Center(child: CircularProgressIndicator(strokeWidth: 2))
                                else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _reject(item),
                                          style: OutlinedButton.styleFrom(foregroundColor: _error),
                                          child: const Text('Reject'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _approve(item),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _success,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Approve'),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
