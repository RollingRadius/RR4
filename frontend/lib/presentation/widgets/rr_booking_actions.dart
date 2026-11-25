/// Cancel booking / Book another truck / Cancel trip for a trip in RR web (LP + RR-ops only).
/// Each action runs at once against RR (no separate sync): POST /api/rr/cancel-booking | rebook | cancel-trip.
/// Rules and decisions: md/RR_BOOKING_CANCEL_RULES.md.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/l10n/app_localizations.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';

const _danger = Color(0xFFC62828);
const _dangerBg = Color(0xFFFFEBEE);

/// A loaded weight or weight slip on our trip: the booking can never be cancelled (same as RR web).
bool tripHasLoadedWeight(TripModel t) =>
    (t.s3LoadedTruckWeightKg ?? '').isNotEmpty || (t.s3LoadedWeightSlipUrl ?? '').isNotEmpty;

bool canCancelBooking(TripModel t) =>
    t.rrTripId != null && t.status != 'cancelled' && !t.isBookingCancelled && !tripHasLoadedWeight(t);
bool canRebook(TripModel t) => t.rrTripId != null && t.status != 'cancelled' && t.isBookingCancelled;
bool canCancelTrip(TripModel t) => t.rrTripId != null && t.status != 'cancelled' && t.isBookingCancelled;

/// FastAPI's `detail` is a String for our refusals and a List for 422 validation errors.
String _errorText(Object e, AppLocalizations l10n) {
  if (e is DioException) {
    final detail = (e.response?.data is Map) ? (e.response!.data as Map)['detail'] : null;
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
    }
  }
  return l10n.bookingActionFailed;
}

void _snack(BuildContext context, String text, {bool ok = true}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(text),
    backgroundColor: ok ? const Color(0xFF2E7D32) : _danger,
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: ok ? 3 : 6),
  ));
}

/// Step 1: red warning + required description. Returns the description, or null when cancelled.
Future<String?> _reasonDialog(BuildContext context, {required String title, required List<String> points,
    required int maxLength, required String actionLabel}) {
  final l10n = AppLocalizations.of(context);
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      final valid = ctrl.text.trim().isNotEmpty;
      return AlertDialog(
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: _danger),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(color: _danger, fontWeight: FontWeight.w700))),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _dangerBg, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final p in points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $p', style: const TextStyle(fontSize: 13)),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            Text(l10n.bookingReasonLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              maxLength: maxLength,
              maxLines: 4,
              minLines: 3,
              inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.bookingReasonHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: valid ? () => Navigator.pop(ctx, ctrl.text.trim()) : null,
            child: Text(actionLabel),
          ),
        ],
      );
    }),
  );
}

/// Step 2: "Are you sure?" - cannot be undone.
Future<bool> _sureDialog(BuildContext context, String message, String yesLabel) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.bookingAreYouSure),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.bookingNoGoBack)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yesLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Cancel booking. Returns true when it was cancelled.
Future<bool> runCancelBooking(BuildContext context, WidgetRef ref, TripModel trip) async {
  final l10n = AppLocalizations.of(context);
  if (tripHasLoadedWeight(trip)) {
    _snack(context, l10n.bookingWeightRecorded, ok: false);
    return false;
  }
  final reason = await _reasonDialog(context,
      title: l10n.bookingCancelTitle,
      maxLength: 500,
      actionLabel: l10n.commonContinue,
      points: [l10n.bookingCancelPointRr, l10n.bookingCancelPointTrip, l10n.bookingCancelPointNext,
               l10n.bookingCancelPointNoUndo]);
  if (reason == null || !context.mounted) return false;
  if (!await _sureDialog(context, l10n.bookingCancelSure(trip.vehicleNumber ?? '—'), l10n.bookingCancelYes)) {
    return false;
  }
  if (!context.mounted) return false;
  try {
    await runRrAction(context, ref, () => ref.read(dioProvider).post(
        '/api/rr/cancel-booking/${trip.id}', data: {'reason': reason},
        options: Options(receiveTimeout: const Duration(seconds: 90))));
    if (context.mounted) _snack(context, l10n.bookingCancelDone);
    return true;
  } catch (e) {
    if (context.mounted) _snack(context, _errorText(e, l10n), ok: false);
    return false;
  }
}

/// Cancel trip (only when no truck is booked). Returns true when it was cancelled.
Future<bool> runCancelTrip(BuildContext context, WidgetRef ref, TripModel trip) async {
  final l10n = AppLocalizations.of(context);
  if (!trip.isBookingCancelled) {
    _snack(context, l10n.bookingCancelTripBookedFirst, ok: false);
    return false;
  }
  final reason = await _reasonDialog(context,
      title: l10n.bookingCancelTripTitle,
      maxLength: 1000,
      actionLabel: l10n.commonContinue,
      points: [l10n.bookingCancelTripPointRr, l10n.bookingCancelTripPointReason, l10n.bookingCancelTripPointNoUndo]);
  if (reason == null || !context.mounted) return false;
  if (!await _sureDialog(context, l10n.bookingCancelTripSure(trip.rrTripNumber ?? trip.tripNumber),
      l10n.bookingCancelTripYes)) {
    return false;
  }
  if (!context.mounted) return false;
  try {
    await runRrAction(context, ref, () => ref.read(dioProvider).post(
        '/api/rr/cancel-trip/${trip.id}', data: {'reason': reason},
        options: Options(receiveTimeout: const Duration(seconds: 90))));
    if (context.mounted) _snack(context, l10n.bookingCancelTripDone);
    return true;
  } catch (e) {
    if (context.mounted) _snack(context, _errorText(e, l10n), ok: false);
    return false;
  }
}

/// Book another truck after a cancelled booking. Returns true when it was booked.
Future<bool> runRebook(BuildContext context, WidgetRef ref, TripModel trip) async {
  final booked = await Navigator.of(context).push<bool>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => RebookTruckScreen(trip: trip),
  ));
  return booked == true;
}

class RebookTruckScreen extends ConsumerStatefulWidget {
  final TripModel trip;
  const RebookTruckScreen({super.key, required this.trip});

  @override
  ConsumerState<RebookTruckScreen> createState() => _RebookTruckScreenState();
}

class _RebookTruckScreenState extends ConsumerState<RebookTruckScreen> {
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _driverCtrl = TextEditingController();
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _provider;                  // {user_id, name, ...}
  List<Map<String, dynamic>> _companies = [];
  String? _companyId;                               // [_ownTrucks] = no company: booked to the person himself
  // RR web books a truck to a company or to a person with no company (participant_user_id), user 2026-11-24
  static const _ownTrucks = '__own_trucks__';
  List<Map<String, dynamic>> _vehicles = [];
  Map<String, dynamic>? _vehicle;                   // {rr_vehicle_id, number, driver_id, driver_name}
  String? _driverId;
  String? _driverName;
  List<Map<String, dynamic>> _driverResults = [];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _driverCtrl.dispose();
    super.dispose();
  }

  Future<T?> _call<T>(Future<T> Function() f) async {
    setState(() { _busy = true; _error = null; });
    try {
      return await runRrAction(context, ref, f);
    } catch (e) {
      if (mounted) setState(() => _error = _errorText(e, AppLocalizations.of(context)));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _findProvider() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    final dio = ref.read(dioProvider);
    final r = await _call(() => dio.get('/api/rr/vehicle-provider-user', queryParameters: {'phone': phone}));
    if (r == null || !mounted) return;
    final user = Map<String, dynamic>.from(r.data as Map);
    final c = await _call(() => dio.get('/api/rr/partner-companies', queryParameters: {'user_id': user['user_id']}));
    if (!mounted) return;
    setState(() {
      _provider = user;
      _companies = ((c?.data as Map?)?['companies'] as List? ?? []).cast<Map<String, dynamic>>();
      _companyId = null; _vehicles = []; _vehicle = null; _driverId = null; _driverName = null;
    });
    if (_companies.isEmpty) await _pickCompany(_ownTrucks);   // no company: his own trucks at once
  }

  Future<void> _pickCompany(String id) async {
    setState(() { _companyId = id; _vehicles = []; _vehicle = null; _driverId = null; _driverName = null; });
    final api = ref.read(rrSyncApiProvider);
    final list = await _call(() => id == _ownTrucks
        ? api.getUserVehicles(_provider!['user_id'] as String)   // his own + hired trucks, no company (as RR web)
        : api.getCompanyVehicles(id));
    if (list != null && mounted) setState(() => _vehicles = list);
  }

  void _pickVehicle(String id) {
    final v = _vehicles.firstWhere((x) => x['rr_vehicle_id'] == id);
    final dId = v['driver_id'] as String? ?? '';
    setState(() {
      _vehicle = v;
      _driverId = dId.isNotEmpty ? dId : null;
      _driverName = dId.isNotEmpty ? v['driver_name'] as String? : null;
    });
  }

  Future<void> _searchDriver() async {
    final q = _driverCtrl.text.trim();
    if (q.isEmpty) return;
    final list = await _call(() => ref.read(rrSyncApiProvider).searchRrUsers(q, driversOnly: true));
    if (list != null && mounted) setState(() => _driverResults = list);
  }

  bool get _ready {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    return _companyId != null && _vehicle != null && _driverId != null && amount > 0;
  }

  Future<void> _book() async {
    final l10n = AppLocalizations.of(context);
    final number = _vehicle!['number'] as String? ?? '';
    if (!await _sureDialog(context, l10n.bookingRebookSure(number, _driverName ?? ''), l10n.bookingRebookYes)) {
      return;
    }
    if (!mounted) return;
    final r = await _call(() => ref.read(dioProvider).post('/api/rr/rebook/${widget.trip.id}', data: {
      'rr_vehicle_id': _vehicle!['rr_vehicle_id'],
      'vehicle_number': number,
      if (_companyId == _ownTrucks) 'transporter_rr_user_id': _provider!['user_id']
      else 'transporter_rr_company_id': _companyId,
      'rr_driver_id': _driverId,
      'booking_amount': double.parse(_amountCtrl.text.trim()),
    }, options: Options(receiveTimeout: const Duration(seconds: 120))));
    if (r != null && mounted) {
      _snack(context, l10n.bookingRebookDone);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingRebookTitle)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
            child: Text(l10n.bookingRebookIntro(widget.trip.rrTripNumber ?? widget.trip.tripNumber),
                style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 16),
          Text(l10n.bookingRebookProviderPhone, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            )),
            const SizedBox(width: 8),
            FilledButton(onPressed: _findProvider, child: Text(l10n.bookingRebookFind)),
          ]),
          if (_provider != null) ...[
            const SizedBox(height: 8),
            Text('${_provider!['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(l10n.bookingRebookCompany, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (_companies.isEmpty)
              Text(l10n.bookingRebookNoCompanyOwnTrucks, style: const TextStyle(color: Color(0xFF5F6B7A)))
            else
              DropdownButtonFormField<String>(
                value: _companyId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: [
                  DropdownMenuItem(value: _ownTrucks,
                      child: Text(l10n.createTripOwnTrucksOption, overflow: TextOverflow.ellipsis)),
                  for (final c in _companies)
                    DropdownMenuItem(value: c['rr_company_id'] as String, child: Text(c['name'] as String? ?? ''))],
                onChanged: (v) { if (v != null) _pickCompany(v); },
              ),
          ],
          if (_companyId != null) ...[
            const SizedBox(height: 12),
            Text(l10n.bookingRebookTruck, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (_vehicles.isEmpty && !_busy)
              Text(_companyId == _ownTrucks ? l10n.bookingRebookNoOwnTrucks : l10n.bookingRebookNoTrucks,
                  style: const TextStyle(color: _danger))
            else
              DropdownButtonFormField<String>(
                value: _vehicle?['rr_vehicle_id'] as String?,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: [for (final v in _vehicles)
                  if (v['rr_vehicle_id'] != widget.trip.rrVehicleId)
                    DropdownMenuItem(value: v['rr_vehicle_id'] as String, child: Text(
                        '${v['number'] ?? ''}${(v['driver_name'] as String? ?? '').isNotEmpty ? '  — ${v['driver_name']}' : ''}',
                        overflow: TextOverflow.ellipsis))],
                onChanged: (v) { if (v != null) _pickVehicle(v); },
              ),
          ],
          if (_vehicle != null) ...[
            const SizedBox(height: 12),
            Text(l10n.bookingRebookDriver, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (_driverId != null)
              Chip(
                label: Text(_driverName ?? ''),
                onDeleted: () => setState(() { _driverId = null; _driverName = null; }),
              )
            else ...[
              Text(l10n.bookingRebookDriverHint, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: TextField(
                  controller: _driverCtrl,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                )),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _searchDriver, child: Text(l10n.bookingRebookFind)),
              ]),
              for (final u in _driverResults)
                ListTile(
                  dense: true,
                  title: Text(u['name'] as String? ?? ''),
                  subtitle: Text(u['phone'] as String? ?? ''),
                  onTap: () => setState(() {
                    _driverId = u['user_id'] as String?;
                    _driverName = u['name'] as String?;
                    _driverResults = [];
                  }),
                ),
            ],
            const SizedBox(height: 12),
            Text(l10n.bookingRebookAmount, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}(\.\d{0,2})?'))],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, prefixText: '₹ '),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: _danger)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _ready && !_busy ? _book : null,
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.bookingRebookYes),
          ),
        ]),
      ),
    );
  }
}
