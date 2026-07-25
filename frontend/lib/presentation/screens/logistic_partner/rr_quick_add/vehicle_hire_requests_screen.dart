import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';

String _errorMessage(Object e) {
  if (e is DioException) {
    final detail = e.response?.data is Map ? (e.response?.data as Map)['detail'] : null;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) return detail.first.toString();
  }
  return 'Action failed. Please try again.';
}

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

String _fmtDateTime(dynamic iso) {
  if (iso == null) return '';
  final dt = DateTime.tryParse(iso as String);
  if (dt == null) return iso;
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$d/$m/${dt.year} $hh:$mm';
}

/// Lets LP/RR-ops review pending vehicle-hire requests marketplace-wide (RR's
/// "Market Vehicle" system) and Approve/Reject any of them — RR itself lets
/// Admin/CSR/CSR Supervisor sessions act on any company's request, so we
/// don't restrict client-side either; `is_mine` is shown only as a "Your
/// fleet" hint. Mirrors RR web's Review Market Vehicle Request dialog: tap a
/// request, see Request Information (Hire Person / Vehicle Detail / Request
/// Time Period), pick Approve or Reject, submit.
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

  Future<void> _openReviewDialog(Map<String, dynamic> item) async {
    final result = await showDialog<_ReviewResult>(
      context: context,
      builder: (_) => _ReviewRequestDialog(item: item),
    );
    if (result == null) return;
    await _submitReview(item, result.status, start: result.start, end: result.end);
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
      setState(() => _actingOnId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'Approved' ? 'Hire request approved' : 'Hire request rejected',
            style: _inter(size: 13, color: Colors.white)),
        backgroundColor: status == 'Approved' ? _success : _secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _actingOnId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_errorMessage(e), style: _inter(size: 13, color: Colors.white)),
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
                          final isMine = item['is_mine'] == true;
                          return InkWell(
                            onTap: acting ? null : () => _openReviewDialog(item),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(color: _border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text('Vehicle: ${item['vehicle_number'] ?? '—'}',
                                            style: _manrope(size: 14)),
                                      ),
                                      if (acting)
                                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      else
                                        const Icon(Icons.chevron_right, color: _secondary),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Owner: ${item['owner_name'] ?? '—'}', style: _inter(size: 13)),
                                  const SizedBox(height: 2),
                                  Text('Requested by: ${item['hirer_name'] ?? '—'}', style: _inter(size: 13)),
                                  if (item['requested_start_date'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Requested: ${_fmtDateTime(item['requested_start_date'])} → ${_fmtDateTime(item['requested_end_date'])}',
                                      style: _inter(size: 12),
                                    ),
                                  ],
                                  if (isMine) ...[
                                    const SizedBox(height: 8),
                                    Text('Your fleet', style: _inter(size: 12, weight: FontWeight.w600, color: _success)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ReviewResult {
  final String status;
  final DateTime? start;
  final DateTime? end;
  _ReviewResult(this.status, {this.start, this.end});
}

/// Mirrors RR web's Review Market Vehicle Request dialog: a read-only
/// "Request Information" recap (Hire Person / Vehicle Detail / Request Time
/// Period), an Approve/Reject radio choice, and — only when Approve is
/// selected — the approved start/end date fields RR requires for approval.
class _ReviewRequestDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  const _ReviewRequestDialog({required this.item});

  @override
  State<_ReviewRequestDialog> createState() => _ReviewRequestDialogState();
}

class _ReviewRequestDialogState extends State<_ReviewRequestDialog> {
  String _decision = 'Approved';
  DateTime? _start;
  DateTime? _end;

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_start ?? now) : (_end ?? (_start ?? now).add(const Duration(days: 7)));
    final firstDate = isStart ? now.subtract(const Duration(days: 1)) : (_start ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
      helpText: isStart ? 'Approved Start Date' : 'Approved End Date',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  String _fmtPicked(DateTime? d) => d == null ? 'Select date' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final vehicleDetail = [item['vehicle_model'], item['vehicle_number']]
        .where((v) => v != null && (v as String).isNotEmpty)
        .join(' | ');
    final canSubmit = _decision == 'Rejected' || (_start != null && _end != null);

    return AlertDialog(
      title: Text('Review Hire Request', style: _manrope(size: 16)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Request Information', style: _manrope(size: 12, color: _primary)),
            const SizedBox(height: 10),
            _InfoRow(label: 'Hire Person', value: (item['hirer_name'] as String?) ?? '—'),
            const SizedBox(height: 6),
            _InfoRow(label: 'Vehicle Detail', value: vehicleDetail.isEmpty ? '—' : vehicleDetail),
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Request Time Period',
              value: '${_fmtDateTime(item['requested_start_date'])} to ${_fmtDateTime(item['requested_end_date'])}',
            ),
            const Divider(height: 24),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: 'Approved',
              groupValue: _decision,
              activeColor: _success,
              title: Text('Approve', style: _inter(size: 14, weight: FontWeight.w600)),
              onChanged: (v) => setState(() => _decision = v ?? 'Approved'),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: 'Rejected',
              groupValue: _decision,
              activeColor: _error,
              title: Text('Reject', style: _inter(size: 14, weight: FontWeight.w600)),
              onChanged: (v) => setState(() => _decision = v ?? 'Approved'),
            ),
            if (_decision == 'Approved') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isStart: true),
                      child: Text('Start: ${_fmtPicked(_start)}', style: _inter(size: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(isStart: false),
                      child: Text('End: ${_fmtPicked(_end)}', style: _inter(size: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: canSubmit
              ? () => Navigator.pop(
                    context,
                    _ReviewResult(_decision, start: _start, end: _end),
                  )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _decision == 'Approved' ? _success : _error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Text(label, style: _inter(size: 12, weight: FontWeight.w600))),
        const Text(': '),
        Expanded(child: Text(value, style: _inter(size: 13, color: _onSurface))),
      ],
    );
  }
}
