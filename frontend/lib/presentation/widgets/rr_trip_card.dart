/// RR Web trip card — used for trips synced via POST /create_trip.
/// Shows a 2-step flow: Step 1 = read-only trip info, Step 2 = loading slip upload.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart' show DioMediaType, FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/providers/auth_provider.dart' show apiServiceProvider;
import 'package:fleet_management/providers/rr_session_provider.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _rrBlue    = Color(0xFF1B6CA8);
const _rrBlueMid = Color(0xFF2980B9);
const _rrBlueBg  = Color(0xFFE8F3FC);
const _white     = Color(0xFFFFFFFF);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _done      = Color(0xFF2E7D32);
const _doneBg    = Color(0xFFE8F5E9);
const _errorClr  = Color(0xFFD32F2F);

TextStyle _manrope({
  double size = 14,
  FontWeight weight = FontWeight.w600,
  Color color = _onSurface,
}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color color = _secondary,
}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

// ─── Step states ──────────────────────────────────────────────────────────────
enum _StepState { pending, active, done }

// ─── Main card widget ─────────────────────────────────────────────────────────

class RrTripCard extends ConsumerStatefulWidget {
  final TripModel trip;

  /// Called after a successful loading slip upload so the parent can refresh.
  final VoidCallback? onRefresh;

  const RrTripCard({super.key, required this.trip, this.onRefresh});

  @override
  ConsumerState<RrTripCard> createState() => _RrTripCardState();
}

class _RrTripCardState extends ConsumerState<RrTripCard> {
  bool _step1Expanded = false;
  ({Uint8List bytes, String name})? _pickedSlip;
  bool _uploading = false;
  String? _uploadError;
  bool _uploadDone = false;

  TripModel get trip => widget.trip;

  _StepState get _step1State =>
      trip.rrTripId != null ? _StepState.done : _StepState.active;

  _StepState get _step2State {
    const doneStatuses = ['loading_slip_synced', 'bilty_synced', 'pod_synced'];
    if (doneStatuses.contains(trip.rrSyncStatus) || _uploadDone) return _StepState.done;
    if (trip.rrSyncStatus == 'trip_created') return _StepState.active;
    return _StepState.pending;
  }

  // ── Image picker ────────────────────────────────────────────────────────────

  Future<void> _pickSlip(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedSlip  = (bytes: bytes, name: picked.name);
      _uploadError = null;
    });
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: _rrBlueBg,
                child: Icon(Icons.camera_alt_outlined, color: _rrBlue, size: 20)),
            title: Text('Camera', style: _inter(size: 14, color: _onSurface)),
            onTap: () { Navigator.pop(context); _pickSlip(ImageSource.camera); },
          ),
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: _rrBlueBg,
                child: Icon(Icons.photo_library_outlined, color: _rrBlue, size: 20)),
            title: Text('Gallery', style: _inter(size: 14, color: _onSurface)),
            onTap: () { Navigator.pop(context); _pickSlip(ImageSource.gallery); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Upload loading slip ─────────────────────────────────────────────────────

  Future<void> _uploadSlip() async {
    if (_pickedSlip == null || _uploading) return;

    final session = await ensureRrSession(context, ref);
    if (session == null || !mounted) return;

    setState(() { _uploading = true; _uploadError = null; });

    try {
      final api = ref.read(apiServiceProvider);
      final ext  = _pickedSlip!.name.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          _pickedSlip!.bytes,
          filename: _pickedSlip!.name,
          contentType: DioMediaType.parse(mime),
        ),
        'rr_token': session.token,
      });

      await api.dio.post(
        '/api/rr/sync/loading-slip/${trip.id}',
        data: formData,
      );

      if (!mounted) return;
      setState(() { _uploading = false; _uploadDone = true; _pickedSlip = null; _uploadError = null; });
      widget.onRefresh?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading   = false;
        _uploadError = e.toString().replaceAll('DioException', '').trim();
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _rrBlue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildStepRow(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F8)),
          _buildStep1Tile(),
          if (_step1Expanded) _buildStep1Info(),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F4F8)),
          _buildStep2Tile(),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final rrNum = trip.rrTripNumber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF124E7E), _rrBlueMid],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text('RR WEB',
                style: _manrope(size: 10, weight: FontWeight.w800, color: _white)),
          ),
          const Spacer(),
          if (rrNum != null && rrNum.isNotEmpty) ...[
            Text(rrNum,
                style: _manrope(size: 15, weight: FontWeight.w800, color: _white)),
          ] else
            Text(trip.tripNumber,
                style: _manrope(size: 13, weight: FontWeight.w600,
                    color: _white.withOpacity(0.7))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Text(trip.origin,
                style: _manrope(size: 13, weight: FontWeight.w700, color: _white),
                overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded,
                color: _white.withOpacity(0.7), size: 16),
          ),
          Expanded(
            child: Text(trip.destination,
                style: _manrope(size: 13, weight: FontWeight.w700, color: _white),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          [
            trip.loadItem,
            if (trip.weight != null && trip.weight!.isNotEmpty) trip.weight!,
          ].join(' · '),
          style: _inter(size: 12, color: _white.withOpacity(0.8)),
          overflow: TextOverflow.ellipsis,
        ),
      ]),
    );
  }

  // ── Step indicator row ───────────────────────────────────────────────────────

  Widget _buildStepRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        _StepCircle(number: 1, state: _step1State),
        Expanded(child: _StepLine(filled: _step2State != _StepState.pending)),
        _StepCircle(number: 2, state: _step2State),
      ]),
    );
  }

  // ── Step 1 collapsible tile ──────────────────────────────────────────────────

  Widget _buildStep1Tile() {
    return InkWell(
      onTap: () => setState(() => _step1Expanded = !_step1Expanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(children: [
          const Icon(Icons.receipt_long_outlined, color: _rrBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Trip Info',
              style: _manrope(size: 13, weight: FontWeight.w700, color: _onSurface))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _doneBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Completed',
                style: _inter(size: 11, weight: FontWeight.w600, color: _done)),
          ),
          const SizedBox(width: 6),
          Icon(
            _step1Expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: _secondary,
            size: 20,
          ),
        ]),
      ),
    );
  }

  // ── Step 1 expanded info ─────────────────────────────────────────────────────

  Widget _buildStep1Info() {
    return Container(
      color: const Color(0xFFF8FAFB),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Parties
        if (trip.consignorName != null || trip.consigneeName != null) ...[
          _InfoRow(icon: Icons.business_outlined, label: 'Consignor',
              value: trip.consignorName ?? '—'),
          if (trip.consignorGstin != null && trip.consignorGstin!.isNotEmpty)
            _InfoRow(icon: null, label: 'Consignor GSTIN', value: trip.consignorGstin!),
          _InfoRow(icon: Icons.business_center_outlined, label: 'Consignee',
              value: trip.consigneeName ?? '—'),
          if (trip.consigneeGstin != null && trip.consigneeGstin!.isNotEmpty)
            _InfoRow(icon: null, label: 'Consignee GSTIN', value: trip.consigneeGstin!),
          _Divider(),
        ],

        // Locations
        if (trip.pickupAddressLine1 != null || trip.pickupPin != null) ...[
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Pickup Address',
            value: [
              trip.pickupAddressLine1,
              trip.pickupAddressLine2,
              trip.pickupPin,
            ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
          ),
        ],
        if (trip.unloadAddressLine1 != null || trip.unloadPin != null) ...[
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Unload Address',
            value: [
              trip.unloadAddressLine1,
              trip.unloadAddressLine2,
              trip.unloadPin,
            ].whereType<String>().where((s) => s.isNotEmpty).join(', '),
          ),
        ],
        if (trip.depotCode != null && trip.depotCode!.isNotEmpty)
          _InfoRow(icon: null, label: 'Depot Code', value: trip.depotCode!),
        _Divider(),

        // Material
        _InfoRow(icon: Icons.inventory_2_outlined, label: 'Material',
            value: trip.loadItem),
        if (trip.weight != null && trip.weight!.isNotEmpty)
          _InfoRow(icon: null, label: 'Weight', value: trip.weight!),
        if (trip.parcelDescription != null && trip.parcelDescription!.isNotEmpty)
          _InfoRow(icon: null, label: 'Description', value: trip.parcelDescription!),
        if (trip.invoiceValue != null)
          _InfoRow(icon: null, label: 'Total Invoice Value',
              value: '₹${trip.invoiceValue!.toStringAsFixed(0)}'),
        if (trip.partLoad == true)
          _InfoRow(icon: null, label: 'Part Load', value: 'Yes'),
        _Divider(),

        // Vehicle
        if (trip.vehicleNumber != null && trip.vehicleNumber!.isNotEmpty)
          _InfoRow(icon: Icons.local_shipping_outlined, label: 'Vehicle',
              value: trip.vehicleNumber!),
        if (trip.vehicleBodyType != null && trip.vehicleBodyType!.isNotEmpty)
          _InfoRow(icon: null, label: 'Body Type', value: trip.vehicleBodyType!),
        if (trip.axleType != null && trip.axleType!.isNotEmpty)
          _InfoRow(icon: null, label: 'Axle Type', value: trip.axleType!),
        if (trip.numberOfWheels != null)
          _InfoRow(icon: null, label: 'Wheels', value: '${trip.numberOfWheels}'),
        _Divider(),

        // Financials
        if (trip.expectedFreight != null)
          _InfoRow(icon: Icons.payments_outlined, label: 'Expected Freight',
              value: '₹${trip.expectedFreight!.toStringAsFixed(0)}'),
        _Divider(),

        // RR identifiers
        if (trip.rrTripNumber != null && trip.rrTripNumber!.isNotEmpty)
          _InfoRow(icon: Icons.tag_rounded, label: 'RR Trip Number',
              value: trip.rrTripNumber!),
        if (trip.rrBookingId != null && trip.rrBookingId!.isNotEmpty)
          _InfoRow(icon: null, label: 'RR Booking ID', value: trip.rrBookingId!),
      ]),
    );
  }

  // ── Step 2 loading slip tile ─────────────────────────────────────────────────

  Widget _buildStep2Tile() {
    final s2 = _step2State;

    if (s2 == _StepState.done) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          const Icon(Icons.upload_file_outlined, color: _done, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('Loading Slip',
              style: _manrope(size: 13, weight: FontWeight.w700, color: _onSurface))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _doneBg, borderRadius: BorderRadius.circular(20)),
            child: Text('Posted', style: _inter(size: 11, weight: FontWeight.w600, color: _done)),
          ),
        ]),
      );
    }

    // Active — show upload UI
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.upload_file_outlined, color: _rrBlue, size: 18),
          const SizedBox(width: 10),
          Text('Loading Slip',
              style: _manrope(size: 13, weight: FontWeight.w700, color: _onSurface)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _rrBlueBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Pending',
                style: _inter(size: 11, weight: FontWeight.w600, color: _rrBlue)),
          ),
        ]),
        const SizedBox(height: 12),

        // Pick / preview area
        if (_pickedSlip == null)
          GestureDetector(
            onTap: _showPickerSheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _rrBlueBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _rrBlue.withOpacity(0.3), width: 1.5),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_photo_alternate_outlined, color: _rrBlue, size: 28),
                const SizedBox(height: 6),
                Text('Tap to attach loading slip',
                    style: _inter(size: 13, color: _rrBlue)),
                Text('Camera or Gallery',
                    style: _inter(size: 11, color: _rrBlue.withOpacity(0.7))),
              ]),
            ),
          )
        else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                _pickedSlip!.bytes,
                width: 72, height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_pickedSlip!.name,
                    style: _inter(size: 12, color: _onSurface),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${(_pickedSlip!.bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                  style: _inter(size: 11),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() { _pickedSlip = null; _uploadError = null; }),
                  child: Text('Remove',
                      style: _inter(size: 12, color: _errorClr, weight: FontWeight.w500)),
                ),
              ]),
            ),
          ]),

        if (_uploadError != null) ...[
          const SizedBox(height: 8),
          Text(_uploadError!,
              style: _inter(size: 12, color: _errorClr)),
        ],

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _pickedSlip != null ? _rrBlue : _rrBlue.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _pickedSlip != null && !_uploading ? _uploadSlip : null,
            icon: _uploading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_upload_outlined, size: 18),
            label: Text(
              _uploading ? 'Posting…' : 'Post Loading Slip',
              style: _inter(size: 14, weight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Step circle ──────────────────────────────────────────────────────────────

class _StepCircle extends StatelessWidget {
  final int number;
  final _StepState state;
  const _StepCircle({required this.number, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDone   = state == _StepState.done;
    final isActive = state == _StepState.active;
    final bg    = isDone ? _done : isActive ? _rrBlue : const Color(0xFFCDD0D5);
    final fgClr = (isDone || isActive) ? Colors.white : _secondary;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Center(
          child: isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : Text('$number',
                  style: _manrope(size: 13, weight: FontWeight.w800, color: fgClr)),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        number == 1 ? 'Trip Info' : 'Loading Slip',
        style: _inter(size: 10,
            weight: FontWeight.w600,
            color: isDone ? _done : isActive ? _rrBlue : _secondary),
      ),
    ]);
  }
}

// ─── Step connecting line ─────────────────────────────────────────────────────

class _StepLine extends StatelessWidget {
  final bool filled;
  const _StepLine({required this.filled});

  @override
  Widget build(BuildContext context) => Container(
    height: 2,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: filled ? _rrBlue : const Color(0xFFCDD0D5),
      borderRadius: BorderRadius.circular(1),
    ),
  );
}

// ─── Info row (step 1 read-only fields) ───────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 20,
        child: icon != null
            ? Icon(icon, size: 15, color: _secondary)
            : null,
      ),
      const SizedBox(width: 4),
      SizedBox(
        width: 120,
        child: Text(label, style: _inter(size: 12)),
      ),
      Expanded(
        child: Text(value,
            style: _inter(size: 12, color: _onSurface, weight: FontWeight.w500)),
      ),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 12, thickness: 1, color: Color(0xFFF0F4F8));
}
