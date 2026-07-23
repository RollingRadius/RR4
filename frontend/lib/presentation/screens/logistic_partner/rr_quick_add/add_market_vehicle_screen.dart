import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/presentation/widgets/rr_search_field.dart';
import 'package:fleet_management/providers/rr_session_provider.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';

const _primary = Color(0xFFFF6B00);
const _secondary = Color(0xFF546067);
const _success = Color(0xFF2E7D32);
const _error = Color(0xFFBA1A1A);

TextStyle _manrope({double size = 14, FontWeight weight = FontWeight.w700, Color color = const Color(0xFF191C1E)}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
TextStyle _inter({double size = 13, FontWeight weight = FontWeight.w400, Color color = _secondary}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

/// Requester side of RR's vehicle-hire marketplace — search for a vehicle
/// owned by someone else and request to hire it. Mirrors RR web's "Add
/// Market Vehicle"/"Hire Vehicle" dialog, minus the "hiring person" field
/// (that's always your own logged-in org here, resolved server-side).
class AddMarketVehicleScreen extends ConsumerStatefulWidget {
  const AddMarketVehicleScreen({super.key});

  @override
  ConsumerState<AddMarketVehicleScreen> createState() => _AddMarketVehicleScreenState();
}

class _AddMarketVehicleScreenState extends ConsumerState<AddMarketVehicleScreen> {
  final _ownerCompanyCtrl = TextEditingController();
  final _ownerUserCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();

  String? _ownerCompanyId;
  String? _ownerUserId;
  String? _selectedVehicleId;
  List<Map<String, dynamic>> _ownerVehicles = [];
  bool _loadingVehicles = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSessionOnOpen());
  }

  Future<void> _ensureSessionOnOpen() async {
    final session = await ensureRrSession(context, ref);
    if (!mounted) return;
    if (session == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _ready = true);
  }

  String _currentToken() => ref.read(rrSessionProvider)?.token ?? '';

  Future<List<Map<String, dynamic>>> _searchOwnerCompanies(String q) =>
      ref.read(rrSyncApiProvider).searchRrCompanies(q, _currentToken());

  Future<List<Map<String, dynamic>>> _searchOwnerUsers(String q) =>
      ref.read(rrSyncApiProvider).searchRrUsers(q, _currentToken());

  Future<void> _loadOwnerVehicles() async {
    setState(() { _loadingVehicles = true; _ownerVehicles = []; _selectedVehicleId = null; _vehicleCtrl.clear(); });
    try {
      final token = _currentToken();
      final vehicles = _ownerCompanyId != null
          ? await ref.read(rrSyncApiProvider).getCompanyVehicles(_ownerCompanyId!, token)
          : await ref.read(rrSyncApiProvider).getUserVehicles(_ownerUserId!, token);
      if (!mounted) return;
      setState(() => _ownerVehicles = vehicles);
    } catch (e) {
      if (!mounted) return;
      setState(() => _ownerVehicles = []);
    } finally {
      if (mounted) setState(() => _loadingVehicles = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? (_startDate ?? now).add(const Duration(days: 7)));
    final firstDate = isStart ? now.subtract(const Duration(days: 1)) : (_startDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
      helpText: isStart ? 'Requested Start Date' : 'Requested End Date',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_ownerCompanyId == null && _ownerUserId == null) {
      _showError('Search and select a vehicle owner (company or individual)');
      return;
    }
    if (_selectedVehicleId == null) {
      _showError('Select a vehicle from the owner\'s fleet');
      return;
    }

    final session = await ensureRrSession(context, ref);
    if (session == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(rrSyncApiProvider).createVehicleHireRequest(
            rrToken: session.token,
            vehicleId: _selectedVehicleId!,
            ownerCompanyId: _ownerCompanyId,
            ownerUserId: _ownerUserId,
            requestedStartDate: _startDate?.toIso8601String(),
            requestedEndDate: _endDate?.toIso8601String(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Hire request sent — waiting for owner approval',
            style: _inter(size: 13, color: Colors.white)),
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
    _ownerCompanyCtrl.dispose();
    _ownerUserCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime? d) => d == null ? 'Not set' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Market Vehicle', style: _manrope(size: 17, color: Colors.white)), backgroundColor: _primary),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request to hire a vehicle owned by another company or individual', style: _inter(size: 13)),
                  const SizedBox(height: 20),
                  Text('Search by owner company', style: _inter(size: 12, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  RrSearchField<Map<String, dynamic>>(
                    label: 'Owner Company',
                    controller: _ownerCompanyCtrl,
                    search: _searchOwnerCompanies,
                    itemLabel: (c) => c['name'] as String? ?? '',
                    onSelected: (c) {
                      setState(() {
                        _ownerCompanyId = c['company_id'] as String?;
                        _ownerCompanyCtrl.text = c['name'] as String? ?? '';
                        _ownerUserId = null;
                        _ownerUserCtrl.clear();
                      });
                      _loadOwnerVehicles();
                    },
                    onCleared: () => setState(() { _ownerCompanyId = null; _ownerVehicles = []; }),
                  ),
                  const SizedBox(height: 12),
                  Text('— or by owner\'s phone number —', style: _inter(size: 12)),
                  const SizedBox(height: 6),
                  RrSearchField<Map<String, dynamic>>(
                    label: 'Owner Individual (phone)',
                    controller: _ownerUserCtrl,
                    keyboardType: TextInputType.phone,
                    search: _searchOwnerUsers,
                    itemLabel: (u) => u['name'] as String? ?? '',
                    itemSubtitle: (u) => u['phone'] as String? ?? '',
                    onSelected: (u) {
                      setState(() {
                        _ownerUserId = u['user_id'] as String?;
                        _ownerUserCtrl.text = '${u['name']} (${u['phone']})';
                        _ownerCompanyId = null;
                        _ownerCompanyCtrl.clear();
                      });
                      _loadOwnerVehicles();
                    },
                    onCleared: () => setState(() { _ownerUserId = null; _ownerVehicles = []; }),
                  ),
                  const SizedBox(height: 16),
                  if (_loadingVehicles)
                    const LinearProgressIndicator()
                  else if (_ownerCompanyId != null || _ownerUserId != null) ...[
                    Text('Vehicle to hire *', style: _inter(size: 12, weight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _ownerVehicles.isEmpty
                        ? Text('This owner has no vehicles on RR', style: _inter(size: 12, color: _secondary))
                        : DropdownButtonFormField<String>(
                            value: _selectedVehicleId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              hintText: 'Select vehicle',
                            ),
                            items: _ownerVehicles
                                .map((v) => DropdownMenuItem(
                                      value: v['rr_vehicle_id'] as String,
                                      child: Text(v['number'] as String? ?? 'Unknown'),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedVehicleId = v),
                          ),
                  ],
                  const SizedBox(height: 20),
                  Text('Requested dates (optional)', style: _inter(size: 12, weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickDate(isStart: true),
                          child: Text('Start: ${_fmtDate(_startDate)}', style: _inter(size: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickDate(isStart: false),
                          child: Text('End: ${_fmtDate(_endDate)}', style: _inter(size: 12)),
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
                          : Text('Send Hire Request', style: _manrope(size: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
