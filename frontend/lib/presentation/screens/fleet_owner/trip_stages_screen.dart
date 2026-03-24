import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/providers/trip_stages_provider.dart';
import 'package:fleet_management/presentation/screens/shared/truck_tracking_screen.dart';

// ─── Typography & Colours ─────────────────────────────────────────────────────
TextStyle _manrope({double size = 14, FontWeight weight = FontWeight.w600, Color color = const Color(0xFF191C1E)}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter({double size = 13, FontWeight weight = FontWeight.w400, Color color = const Color(0xFF546067)}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

const _primary   = Color(0xFFFF6B00);
const _bg        = Color(0xFFF8F9FB);
const _surface   = Color(0xFFFFFFFF);
const _secondary = Color(0xFF546067);
const _onSurface = Color(0xFF191C1E);
const _success   = Color(0xFF006B5E);
const _error     = Color(0xFFBA1A1A);
const _border    = Color(0xFFECEEF0);

// ─── Main Screen ──────────────────────────────────────────────────────────────

class TripStagesScreen extends ConsumerStatefulWidget {
  final TripModel trip;
  const TripStagesScreen({super.key, required this.trip});

  @override
  ConsumerState<TripStagesScreen> createState() => _TripStagesScreenState();
}

class _TripStagesScreenState extends ConsumerState<TripStagesScreen> {
  late final (String, int) _providerKey;

  @override
  void initState() {
    super.initState();
    _providerKey = (widget.trip.id, widget.trip.currentStage);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripStagesProvider(_providerKey));
    final stage = state.currentStage;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.trip.tripNumber,
                style: _manrope(size: 15, weight: FontWeight.w800)),
            Text('${widget.trip.origin} → ${widget.trip.destination}',
                style: _inter(size: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(currentStage: stage),
          if (state.error != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: _error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.error!, style: _inter(size: 12, color: _error))),
                ],
              ),
            ),
          Expanded(
            child: stage == 3
                ? _CompletionView(
                    trip: widget.trip,
                    emptyWeightKg: state.emptyWeightKg,
                    emptyWeightUnit: state.emptyWeightUnit ?? 'tons',
                    loadedWeightKg: state.loadedWeightKg,
                    loadedWeightUnit: state.loadedWeightUnit ?? 'tons',
                    onDone: () => Navigator.of(context).pop(),
                  )
                : stage == 0
                    ? _Stage1Form(providerKey: _providerKey)
                    : stage == 1
                        ? _Stage2Form(providerKey: _providerKey, trip: widget.trip)
                        : _Stage3Form(providerKey: _providerKey),
          ),
        ],
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStage;
  const _StepIndicator({required this.currentStage});

  static const _labels = ['Truck Details', 'Compliance', 'Arrival'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: List.generate(3, (i) {
          final stepNum = i + 1;
          final isDone = currentStage > i;
          final isActive = currentStage == i;
          final color = isDone ? _success : isActive ? _primary : _secondary;
          final bgColor = isDone
              ? _success.withValues(alpha: 0.10)
              : isActive
                  ? _primary.withValues(alpha: 0.10)
                  : _border;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: isDone || isActive ? 2 : 1),
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(Icons.check_rounded, color: _success, size: 18)
                            : Text(
                                '$stepNum',
                                style: _manrope(size: 14, weight: FontWeight.w800, color: color),
                              ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _labels[i],
                      style: _inter(
                          size: 10,
                          weight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: color),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 22),
                      color: isDone ? _success.withValues(alpha: 0.4) : _border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Stage 1: Truck Detail Registration ───────────────────────────────────────

class _Stage1Form extends ConsumerStatefulWidget {
  final (String, int) providerKey;
  const _Stage1Form({required this.providerKey});

  @override
  ConsumerState<_Stage1Form> createState() => _Stage1FormState();
}

class _Stage1FormState extends ConsumerState<_Stage1Form> {
  final _formKey = GlobalKey<FormState>();

  final _driverName      = TextEditingController();
  final _driverPhone     = TextEditingController();
  final _drivingLicense  = TextEditingController();
  final _aadhaar         = TextEditingController();
  final _rc              = TextEditingController();
  final _insurance       = TextEditingController();
  final _pollution       = TextEditingController();
  final _fitness         = TextEditingController();
  final _pan             = TextEditingController();
  final _taxDeclaration  = TextEditingController();
  final _cancelledCheque = TextEditingController();

  @override
  void dispose() {
    for (final c in [_driverName, _driverPhone, _drivingLicense, _aadhaar,
        _rc, _insurance, _pollution, _fitness, _pan, _taxDeclaration, _cancelledCheque]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(tripStagesProvider(widget.providerKey).notifier).submitStage1({
      'driver_name':      _driverName.text.trim(),
      'driver_phone':     _driverPhone.text.trim(),
      'driving_license':  _drivingLicense.text.trim(),
      'aadhaar':          _aadhaar.text.trim(),
      'rc':               _rc.text.trim(),
      'insurance':        _insurance.text.trim(),
      'pollution':        _pollution.text.trim(),
      'fitness':          _fitness.text.trim(),
      'pan':              _pan.text.trim(),
      'tax_declaration':  _taxDeclaration.text.trim(),
      'cancelled_cheque': _cancelledCheque.text.trim(),
    });
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stage 1 saved. Proceed to compliance check.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(tripStagesProvider(widget.providerKey)).isSubmitting;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(icon: Icons.person_outline_rounded, title: 'Driver Details'),
            _FormField(controller: _driverName,     label: 'Driver Name',     required: true),
            _FormField(controller: _driverPhone,    label: 'Driver Phone',    required: true, keyboardType: TextInputType.phone),
            _FormField(controller: _drivingLicense, label: 'Driving License', required: true),
            _FormField(controller: _aadhaar,        label: 'Aadhaar Card',    required: true, keyboardType: TextInputType.number),
            const SizedBox(height: 8),

            _SectionHeader(icon: Icons.directions_car_outlined, title: 'Vehicle Documents'),
            _FormField(controller: _rc,        label: 'RC (Registration Certificate)', required: true),
            _FormField(controller: _insurance, label: 'Insurance',                     required: true),
            _FormField(controller: _pollution, label: 'Pollution Certificate',          required: true),
            _FormField(controller: _fitness,   label: 'Fitness Certificate',            required: true),
            const SizedBox(height: 8),

            _SectionHeader(icon: Icons.business_outlined, title: 'Owner Documents'),
            _FormField(controller: _pan,             label: 'PAN',              required: true),
            _FormField(controller: _taxDeclaration,  label: 'Tax Declaration',  required: false),
            const SizedBox(height: 8),

            _SectionHeader(icon: Icons.account_balance_outlined, title: 'Truck Owner Payment Details'),
            _FormField(controller: _cancelledCheque, label: 'Cancelled Cheque (Owner / Transporter)', required: false),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: busy
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save & Continue →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stage 2: Pre-Arrival Compliance Check ────────────────────────────────────

class _Stage2Form extends ConsumerStatefulWidget {
  final (String, int) providerKey;
  final TripModel trip;
  const _Stage2Form({required this.providerKey, required this.trip});

  @override
  ConsumerState<_Stage2Form> createState() => _Stage2FormState();
}

class _Stage2FormState extends ConsumerState<_Stage2Form> {
  bool _specsVerified    = false;
  bool _docsVerified     = false;
  bool _driverDocsValid  = false;
  bool _entryPermission  = false;

  Future<void> _submit() async {
    if (!_entryPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entry Permission must be issued to proceed.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final ok = await ref.read(tripStagesProvider(widget.providerKey).notifier).submitStage2({
      'specs_verified':    _specsVerified,
      'docs_verified':     _docsVerified,
      'driver_docs_valid': _driverDocsValid,
      'entry_permission':  _entryPermission,
    });
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entry permission issued. Coordinate truck arrival.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(tripStagesProvider(widget.providerKey)).isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: _primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.trip.tripNumber,
                          style: _manrope(size: 13, weight: FontWeight.w800, color: _primary)),
                      Text('${widget.trip.origin} → ${widget.trip.destination}',
                          style: _inter(size: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('RR Executive verifies:',
              style: _manrope(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('All items must be confirmed before issuing entry permission.',
              style: _inter(size: 12)),
          const SizedBox(height: 16),

          _CheckItem(
            label: 'Truck specifications match requirement',
            value: _specsVerified,
            onChanged: (v) => setState(() => _specsVerified = v),
          ),
          _CheckItem(
            label: 'All documents uploaded',
            value: _docsVerified,
            onChanged: (v) => setState(() => _docsVerified = v),
          ),
          _CheckItem(
            label: 'Driver documents valid',
            value: _driverDocsValid,
            onChanged: (v) => setState(() => _driverDocsValid = v),
          ),
          const SizedBox(height: 20),

          // Entry permission — highlighted
          Container(
            decoration: BoxDecoration(
              color: _entryPermission
                  ? _success.withValues(alpha: 0.08)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _entryPermission ? _success : _primary,
                width: 1.5,
              ),
            ),
            child: _CheckItem(
              label: 'Truck Entry Permission Issued',
              sublabel: 'Factory logistics team receives truck number + driver details.',
              value: _entryPermission,
              onChanged: (v) => setState(() => _entryPermission = v),
              activeColor: _success,
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _entryPermission ? _success : _secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: busy
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Issue Entry Permission →'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stage 3: Truck Arrival at Factory ────────────────────────────────────────

class _Stage3Form extends ConsumerStatefulWidget {
  final (String, int) providerKey;
  const _Stage3Form({required this.providerKey});

  @override
  ConsumerState<_Stage3Form> createState() => _Stage3FormState();
}

class _Stage3FormState extends ConsumerState<_Stage3Form> {
  bool _driverParked       = false;
  bool _docsSubmitted      = false;
  bool _securityVerified   = false;
  bool _driverExitedCabin  = false;
  bool _wheelStoppers      = false;
  bool _safetyGear         = false;

  final _emptyTruckWeight  = TextEditingController();
  final _loadedTruckWeight = TextEditingController();
  final _emptyWeightUnit   = ValueNotifier<String>('tons');
  final _loadedWeightUnit  = ValueNotifier<String>('tons');

  // Two-phase: first "Loading Complete", then "Complete Stage"
  bool _loadingComplete = false;

  @override
  void dispose() {
    _emptyTruckWeight.dispose();
    _loadedTruckWeight.dispose();
    _emptyWeightUnit.dispose();
    _loadedWeightUnit.dispose();
    super.dispose();
  }

  bool get _allChecked =>
      _driverParked && _docsSubmitted && _securityVerified &&
      _driverExitedCabin && _wheelStoppers && _safetyGear;

  void _onLoadingComplete() {
    if (!_allChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All steps must be completed before marking loading complete.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() => _loadingComplete = true);
  }

  Future<void> _completeStage() async {
    await ref.read(tripStagesProvider(widget.providerKey).notifier).submitStage3({
      'driver_parked':              _driverParked,
      'docs_submitted':             _docsSubmitted,
      'security_verified':          _securityVerified,
      'driver_exited_cabin':        _driverExitedCabin,
      'wheel_stoppers':             _wheelStoppers,
      'safety_gear':                _safetyGear,
      'empty_truck_weight_kg':      _emptyTruckWeight.text.trim(),
      'empty_truck_weight_unit':    _emptyWeightUnit.value,
      'loaded_truck_weight_kg':     _loadedTruckWeight.text.trim(),
      'loaded_truck_weight_unit':   _loadedWeightUnit.value,
    });
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(tripStagesProvider(widget.providerKey)).isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RR Executive coordinates with driver:',
              style: _manrope(size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 16),

          _SectionHeader(icon: Icons.local_parking_rounded, title: 'Arrival Steps'),
          _CheckItem(
            label: 'Driver parks outside factory',
            value: _driverParked,
            onChanged: (v) => setState(() => _driverParked = v),
          ),
          _CheckItem(
            label: 'Documents submitted to security',
            value: _docsSubmitted,
            onChanged: (v) => setState(() => _docsSubmitted = v),
          ),
          _CheckItem(
            label: 'Security verifies vehicle requirements',
            value: _securityVerified,
            onChanged: (v) => setState(() => _securityVerified = v),
          ),
          const SizedBox(height: 8),

          _SectionHeader(icon: Icons.security_rounded, title: 'Driver Safety Rules'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withValues(alpha: 0.30)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _CheckItem(
                  label: 'Driver must exit cabin',
                  value: _driverExitedCabin,
                  onChanged: (v) => setState(() => _driverExitedCabin = v),
                  activeColor: _primary,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: _primary.withValues(alpha: 0.15)),
                _CheckItem(
                  label: 'Wheel stoppers installed',
                  value: _wheelStoppers,
                  onChanged: (v) => setState(() => _wheelStoppers = v),
                  activeColor: _primary,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: _primary.withValues(alpha: 0.15)),
                _CheckItem(
                  label: 'Safety shoes and helmet required',
                  value: _safetyGear,
                  onChanged: (v) => setState(() => _safetyGear = v),
                  activeColor: _primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dharma Kanta — Empty Weight
          _SectionHeader(icon: Icons.scale_rounded, title: 'Dharma Kanta (Weigh Bridge)'),
          _WeighField(
            controller: _emptyTruckWeight,
            label: 'Empty Truck Weight',
            hint: 'e.g. 12.5',
            note: 'Record the empty truck weight before loading.',
            enabled: !_loadingComplete,
            unitNotifier: _emptyWeightUnit,
          ),
          const SizedBox(height: 20),

          // Phase 1 button — "Loading Complete"
          if (!_loadingComplete) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onLoadingComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allChecked ? _primary : _secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: const Text('Loading Complete →'),
              ),
            ),
          ],

          // Phase 2 — Loaded weight + Complete Stage button
          if (_loadingComplete) ...[
            // Confirmation banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _success.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: _success, size: 16),
                  const SizedBox(width: 8),
                  Text('Loading complete. Record loaded truck weight.',
                      style: _inter(size: 12, color: _success, weight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _WeighField(
              controller: _loadedTruckWeight,
              label: 'Loaded Truck Weight',
              hint: 'e.g. 28.5',
              note: 'Record the truck weight after loading is done.',
              enabled: true,
              unitNotifier: _loadedWeightUnit,
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : _completeStage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: busy
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Complete Stage ✓'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Completion View ──────────────────────────────────────────────────────────

class _CompletionView extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onDone;
  final String? emptyWeightKg;
  final String emptyWeightUnit;
  final String? loadedWeightKg;
  final String loadedWeightUnit;

  const _CompletionView({
    required this.trip,
    required this.onDone,
    this.emptyWeightKg,
    this.emptyWeightUnit = 'tons',
    this.loadedWeightKg,
    this.loadedWeightUnit = 'tons',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: _success, size: 56),
            ),
            const SizedBox(height: 24),
            Text('Truck Intake Complete!',
                style: _manrope(size: 22, weight: FontWeight.w800, color: _success)),
            const SizedBox(height: 8),
            Text(trip.tripNumber,
                style: _manrope(size: 16, weight: FontWeight.w700, color: _secondary)),
            const SizedBox(height: 6),
            Text(
              '${trip.origin} → ${trip.destination}',
              style: _inter(size: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'All 3 compliance stages completed.\nThe trip is now active.',
              textAlign: TextAlign.center,
              style: _inter(size: 13, color: _secondary),
            ),
            const SizedBox(height: 32),

            // Track Truck — primary CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TruckTrackingScreen(
                      trip: trip,
                      emptyWeightKg: emptyWeightKg,
                      emptyWeightUnit: emptyWeightUnit,
                      loadedWeightKg: loadedWeightKg,
                      loadedWeightUnit: loadedWeightUnit,
                    ),
                  ),
                ),
                icon: const Icon(Icons.local_shipping_rounded, size: 18),
                label: const Text('Track Truck →'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Back to Dashboard — secondary
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDone,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: _border, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 8),
          Text(title, style: _manrope(size: 14, weight: FontWeight.w800, color: _onSurface)),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final TextInputType keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    this.required = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _inter(size: 12, color: _secondary),
          filled: true,
          fillColor: _surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _error),
          ),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _CheckItem({
    required this.label,
    required this.value,
    required this.onChanged,
    this.sublabel,
    this.activeColor = _success,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: value ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? activeColor : _secondary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: _inter(
                          size: 13,
                          weight: value ? FontWeight.w600 : FontWeight.w400,
                          color: value ? _onSurface : _secondary)),
                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(sublabel!,
                        style: _inter(size: 11, color: _secondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeighField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String note;
  final bool enabled;
  final ValueNotifier<String>? unitNotifier;

  const _WeighField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.note,
    this.enabled = true,
    this.unitNotifier,
  });

  @override
  State<_WeighField> createState() => _WeighFieldState();
}

class _WeighFieldState extends State<_WeighField> {
  File? _slipImage;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked != null && mounted) {
      setState(() => _slipImage = File(picked.path));
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload Weigh Slip',
                  style: _manrope(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Choose how to add the slip image',
                  style: _inter(size: 12, color: _secondary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: _primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFF1565C0),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitNotifier = widget.unitNotifier;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.enabled ? _surface : _bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: widget.enabled ? _border : _border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row + unit toggle
          Row(
            children: [
              Expanded(
                child: Text(widget.note,
                    style: _inter(size: 12, color: _secondary)),
              ),
              if (unitNotifier != null)
                ValueListenableBuilder<String>(
                  valueListenable: unitNotifier,
                  builder: (_, unit, __) => _UnitToggle(
                    selected: unit,
                    enabled: widget.enabled,
                    onChanged: (u) => unitNotifier.value = u,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<String>(
            valueListenable: unitNotifier ?? ValueNotifier('tons'),
            builder: (_, unit, __) => TextFormField(
              controller: widget.controller,
              enabled: widget.enabled,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: _inter(size: 12, color: _secondary),
                hintText: unit == 'tons' ? 'e.g. 12.5' : 'e.g. 12500',
                hintStyle: _inter(size: 12, color: _secondary),
                prefixIcon:
                    const Icon(Icons.scale_outlined, size: 18, color: _secondary),
                suffixText: unit,
                suffixStyle:
                    _inter(size: 13, weight: FontWeight.w600, color: _primary),
                filled: true,
                fillColor:
                    widget.enabled ? _bg : _border.withValues(alpha: 0.3),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _border),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: _border.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Slip upload area
          if (_slipImage == null)
            GestureDetector(
              onTap: widget.enabled ? _showPickerSheet : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? _primary.withValues(alpha: 0.05)
                      : _border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.enabled
                        ? _primary.withValues(alpha: 0.30)
                        : _border.withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.upload_file_rounded,
                        color: widget.enabled ? _primary : _secondary,
                        size: 24),
                    const SizedBox(height: 6),
                    Text(
                      'Upload Weigh Slip',
                      style: _inter(
                          size: 12,
                          weight: FontWeight.w600,
                          color: widget.enabled ? _primary : _secondary),
                    ),
                    const SizedBox(height: 2),
                    Text('Camera or Gallery',
                        style: _inter(size: 11, color: _secondary)),
                  ],
                ),
              ),
            )
          else
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _slipImage!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: _showPickerSheet,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _slipImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _error.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 10),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(10)),
                    ),
                    child: Text('Weigh Slip',
                        style: _inter(
                            size: 11,
                            color: Colors.white,
                            weight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Unit Toggle (Tons / Kg) ──────────────────────────────────────────────────

class _UnitToggle extends StatelessWidget {
  final String selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _UnitToggle({
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Container(
        height: 30,
        decoration: BoxDecoration(
          color: _border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['tons', 'kg'].map((unit) {
            final active = selected == unit;
            return GestureDetector(
              onTap: enabled ? () => onChanged(unit) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  unit,
                  style: _inter(
                    size: 12,
                    weight: FontWeight.w700,
                    color: active ? Colors.white : _secondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: _manrope(
                    size: 13, weight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
