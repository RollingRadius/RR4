import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/presentation/widgets/rr_search_field.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';

const _primary = Color(0xFFFF6B00);
const _secondary = Color(0xFF546067);
const _onSurface = Color(0xFF191C1E);
const _success = Color(0xFF2E7D32);
const _error = Color(0xFFBA1A1A);

TextStyle _manrope({double size = 14, FontWeight weight = FontWeight.w700, Color color = _onSurface}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
TextStyle _inter({double size = 13, FontWeight weight = FontWeight.w400, Color color = _secondary}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

/// Requester side of RR's vehicle-hire marketplace — mirrors RR web's "Hire
/// Market Vehicle" dialog (hire-market-vehicle.component.html) field for
/// field: Vehicle Hire Person, then a Lender Detail section (Vehicle Owner +
/// Lender Vehicles), then a Hiring Request Date range, then Submit. Both
/// Hire Person and Vehicle Owner are independent search fields — a
/// privileged RR session (Admin/CSR/CSR Supervisor) can create a hire
/// request on behalf of any company, same as RR web itself.
class AddMarketVehicleScreen extends ConsumerStatefulWidget {
  const AddMarketVehicleScreen({super.key});

  @override
  ConsumerState<AddMarketVehicleScreen> createState() => _AddMarketVehicleScreenState();
}

class _AddMarketVehicleScreenState extends ConsumerState<AddMarketVehicleScreen> {
  final _hirePersonCompanyCtrl = TextEditingController();
  final _hirePersonUserCtrl = TextEditingController();
  final _ownerCompanyCtrl = TextEditingController();
  final _ownerUserCtrl = TextEditingController();

  String? _hirePersonCompanyId;
  String? _hirePersonUserId;
  String? _ownerCompanyId;
  String? _ownerUserId;
  String? _selectedVehicleId;
  List<Map<String, dynamic>> _ownerVehicles = [];
  bool _loadingVehicles = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;

  Future<List<Map<String, dynamic>>> _searchCompanies(String q) =>
      runRrAction(context, ref, () => ref.read(rrSyncApiProvider).searchRrCompanies(q));

  Future<List<Map<String, dynamic>>> _searchUsers(String q) =>
      runRrAction(context, ref, () => ref.read(rrSyncApiProvider).searchRrUsers(q));

  Future<void> _loadOwnerVehicles() async {
    setState(() { _loadingVehicles = true; _ownerVehicles = []; _selectedVehicleId = null; });
    try {
      final vehicles = await runRrAction(context, ref, () => _ownerCompanyId != null
          ? ref.read(rrSyncApiProvider).getCompanyVehicles(_ownerCompanyId!)
          : ref.read(rrSyncApiProvider).getUserVehicles(_ownerUserId!));
      if (!mounted) return;
      setState(() => _ownerVehicles = vehicles);
    } catch (e) {
      if (!mounted) return;
      setState(() => _ownerVehicles = []);
    } finally {
      if (mounted) setState(() => _loadingVehicles = false);
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? (_startDate ?? now).add(const Duration(days: 7)));
    final firstDate = isStart ? now.subtract(const Duration(days: 1)) : (_startDate ?? now);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
      helpText: isStart ? 'Hiring Request Date — From' : 'Hiring Request Date — To',
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null) return;
    final combined = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    setState(() {
      if (isStart) {
        _startDate = combined;
        if (_endDate != null && _endDate!.isBefore(combined)) _endDate = null;
      } else {
        _endDate = combined;
      }
    });
  }

  Future<void> _submit() async {
    if (_hirePersonCompanyId == null && _hirePersonUserId == null) {
      _showError('Search and select the Vehicle Hire Person');
      return;
    }
    if (_ownerCompanyId == null && _ownerUserId == null) {
      _showError('Search and select the Vehicle Owner');
      return;
    }
    if (_selectedVehicleId == null) {
      _showError('Select a vehicle from the owner\'s fleet');
      return;
    }
    final hirePersonId = _hirePersonCompanyId ?? _hirePersonUserId;
    final ownerId = _ownerCompanyId ?? _ownerUserId;
    if (hirePersonId == ownerId) {
      _showError('The hiring person and lender must be different. You cannot hire your own vehicle.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await runRrAction(context, ref, () => ref.read(rrSyncApiProvider).createVehicleHireRequest(
            vehicleId: _selectedVehicleId!,
            ownerCompanyId: _ownerCompanyId,
            ownerUserId: _ownerUserId,
            hirerCompanyId: _hirePersonCompanyId,
            hirerUserId: _hirePersonUserId,
            // RR stores whatever clock digits it's sent as literal UTC (no
            // conversion on its side) — .toUtc() here is required, not
            // cosmetic, or an IST pick lands 5:30h off in RR's DB.
            requestedStartDate: _startDate?.toUtc().toIso8601String(),
            requestedEndDate: _endDate?.toUtc().toIso8601String(),
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hiring request sent successfully', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not send hire request. Please try again.', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: _inter(size: 13, color: Colors.white)),
      backgroundColor: _error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _hirePersonCompanyCtrl.dispose();
    _hirePersonUserCtrl.dispose();
    _ownerCompanyCtrl.dispose();
    _ownerUserCtrl.dispose();
    super.dispose();
  }

  String _fmtDateTime(DateTime? d) {
    if (d == null) return 'Not set';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mi';
  }

  Widget _dualSearchField({
    required String label,
    required TextEditingController companyCtrl,
    required TextEditingController userCtrl,
    required String? companyId,
    required String? userId,
    required void Function(String? companyId, String? userId) onChanged,
    required VoidCallback? onOwnerContextChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _manrope(size: 13)),
        const SizedBox(height: 6),
        Text('Search by company/firm', style: _inter(size: 12)),
        const SizedBox(height: 6),
        RrSearchField<Map<String, dynamic>>(
          label: 'Company / Firm Name',
          controller: companyCtrl,
          search: _searchCompanies,
          itemLabel: (c) => c['name'] as String? ?? '',
          onSelected: (c) {
            setState(() {
              onChanged(c['company_id'] as String?, null);
              companyCtrl.text = c['name'] as String? ?? '';
              userCtrl.clear();
            });
            onOwnerContextChanged?.call();
          },
          onCleared: () => setState(() => onChanged(null, userId)),
        ),
        const SizedBox(height: 10),
        Text('— or by phone number —', style: _inter(size: 12)),
        const SizedBox(height: 6),
        RrSearchField<Map<String, dynamic>>(
          label: 'Phone Number',
          hintText: 'Full 10-digit phone, or part of the name',
          controller: userCtrl,
          keyboardType: TextInputType.phone,
          search: _searchUsers,
          itemLabel: (u) => u['name'] as String? ?? '',
          itemSubtitle: (u) => u['phone'] as String? ?? '',
          onSelected: (u) {
            setState(() {
              onChanged(null, u['user_id'] as String?);
              userCtrl.text = '${u['name']} (${u['phone']})';
              companyCtrl.clear();
            });
            onOwnerContextChanged?.call();
          },
          onCleared: () => setState(() => onChanged(companyId, null)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Market Vehicle', style: _manrope(size: 17, color: Colors.white)), backgroundColor: _primary),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Vehicle Hire Person ──────────────────────────────────
                  _dualSearchField(
                    label: 'Vehicle Hire Person *',
                    companyCtrl: _hirePersonCompanyCtrl,
                    userCtrl: _hirePersonUserCtrl,
                    companyId: _hirePersonCompanyId,
                    userId: _hirePersonUserId,
                    onChanged: (c, u) { _hirePersonCompanyId = c; _hirePersonUserId = u; },
                    onOwnerContextChanged: null,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // ── Lender Detail ────────────────────────────────────────
                  Text('Lender Detail', style: _manrope(size: 13, color: _primary)),
                  const SizedBox(height: 10),
                  _dualSearchField(
                    label: 'Vehicle Owner *',
                    companyCtrl: _ownerCompanyCtrl,
                    userCtrl: _ownerUserCtrl,
                    companyId: _ownerCompanyId,
                    userId: _ownerUserId,
                    onChanged: (c, u) { _ownerCompanyId = c; _ownerUserId = u; },
                    onOwnerContextChanged: _loadOwnerVehicles,
                  ),
                  const SizedBox(height: 14),
                  if (_loadingVehicles)
                    const LinearProgressIndicator()
                  else if (_ownerCompanyId != null || _ownerUserId != null) ...[
                    Text('Lender Vehicles *', style: _inter(size: 12, weight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _ownerVehicles.isEmpty
                        ? Text('This owner has no vehicles on RR', style: _inter(size: 12, color: _secondary))
                        : DropdownButtonFormField<String>(
                            value: _selectedVehicleId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              hintText: 'Select vehicle',
                            ),
                            items: _ownerVehicles.map((v) {
                              final model = v['model_name'] as String? ?? '';
                              final number = v['number'] as String? ?? '';
                              final label = [
                                if (model.isNotEmpty) model,
                                if (number.isNotEmpty) '($number)',
                              ].join(' ');
                              return DropdownMenuItem(
                                value: v['rr_vehicle_id'] as String,
                                child: Text(label.isEmpty ? 'Unknown' : label, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedVehicleId = v),
                          ),
                  ],
                  const SizedBox(height: 20),

                  // ── Hiring Request Date ─────────────────────────────────
                  Text('Hiring Request Date', style: _manrope(size: 13, color: _primary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickDateTime(isStart: true),
                          child: Text('From: ${_fmtDateTime(_startDate)}', style: _inter(size: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickDateTime(isStart: false),
                          child: Text('To: ${_fmtDateTime(_endDate)}', style: _inter(size: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Submit', style: _manrope(size: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
