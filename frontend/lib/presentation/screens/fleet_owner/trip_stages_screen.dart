import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fleet_management/data/models/trip_model.dart';
import 'package:fleet_management/providers/trip_stages_provider.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
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
  /// Visual stage index (0–4) to open directly for editing. Null = default flow.
  final int? initialStage;
  const TripStagesScreen({super.key, required this.trip, this.initialStage});

  @override
  ConsumerState<TripStagesScreen> createState() => _TripStagesScreenState();
}

class _TripStagesScreenState extends ConsumerState<TripStagesScreen> {
  late TripModel _trip;           // always the freshest copy
  late (String, int) _providerKey;
  int _tripFreshness = 0;         // increments when fresh data arrives → stage forms rebuild
  bool _fetchingFresh = false;
  bool _showStage4 = false;
  bool _stage4Done = false;
  /// Non-null when re-editing a completed stage (visual dot index 0-4).
  int? _editingStage;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _providerKey = (_trip.id, _trip.currentStage);
    if (_trip.currentStage >= 4) {
      _showStage4 = true;
      _stage4Done = true;
    }
    // If opened at a specific stage from the sliding panel, jump there directly.
    if (widget.initialStage != null) {
      _editingStage = widget.initialStage;
      if (widget.initialStage == 4) _showStage4 = true;
    }
    // Fetch fresh data after first frame so ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchFreshTrip());
  }

  Future<void> _fetchFreshTrip() async {
    if (!mounted) return;
    setState(() => _fetchingFresh = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/api/trips/${widget.trip.id}');
      if (!mounted) return;
      final fresh = TripModel.fromJson(resp.data as Map<String, dynamic>);
      setState(() {
        _trip = fresh;
        _tripFreshness++;
        _fetchingFresh = false;
        _providerKey = (fresh.id, fresh.currentStage);
        if (fresh.currentStage >= 4 && !_stage4Done) {
          _showStage4 = true;
          _stage4Done = true;
        }
      });
      // Keep the main trips list in sync
      ref.read(tripProvider.notifier).patchTrip(fresh);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _fetchingFresh = false);
      final msg = e.response?.data?['detail'] as String? ??
          'Failed to load trip details. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _fetchingFresh = false);
    }
  }

  void _exitEditMode() {
    final stage = _editingStage;
    setState(() => _editingStage = null);
    // Always try to release the claim on exit.
    // If stage was already submitted, the backend cleared the claim — release is a no-op.
    if (stage != null) _releaseStage(stage);
    _fetchFreshTrip();
  }

  /// Opens a stage form. LP workers are locked to the current stage only.
  Future<void> _enterStage(int visualStage) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() => _editingStage = visualStage);
  }

  /// No-op: claim blocking is disabled — nothing to release.
  Future<void> _releaseStage(int visualStage) async {}

  /// Returns a tap handler for the step indicator.
  /// LP workers get null — they cannot freely switch stages.
  Function(int)? _buildStepTapHandler() {
    final user = ref.read(authProvider).user;
    if (user?.isLogisticPartnerWorker == true) return null;
    return (int i) => _enterStage(i);
  }

  Widget _buildEditForm(int visualStage) {
    switch (visualStage) {
      case 0:
        return _Stage1Form(
          key: ValueKey('edit_s1_${_trip.id}_$_tripFreshness'),
          providerKey: _providerKey,
          trip: _trip,
          onEditDone: _exitEditMode,
        );
      case 1:
        return _Stage2Form(
          key: ValueKey('edit_s2_${_trip.id}_$_tripFreshness'),
          providerKey: _providerKey,
          trip: _trip,
          onEditDone: _exitEditMode,
        );
      case 2:
        return _LoadingSlipMini(
          key: ValueKey('edit_slip_${_trip.id}'),
          trip: _trip,
          onUploaded: (updated) {
            setState(() {
              _trip = updated;
              ref.read(tripProvider.notifier).patchTrip(updated);
            });
            _exitEditMode();
          },
        );
      case 3:
        return _Stage3Form(
          key: ValueKey('edit_s3_${_trip.id}_$_tripFreshness'),
          providerKey: _providerKey,
          trip: _trip,
          onEditDone: _exitEditMode,
        );
      case 4:
      default:
        return _Stage4Form(
          trip: _trip,
          onComplete: _exitEditMode,
        );
    }
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
        actions: [
          _TripStateBadge(trip: _trip),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Thin sync indicator while fetching fresh data
          if (_fetchingFresh)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: _primary,
            ),
          _StepIndicator(
            trip: _trip,
            stage4Done: _stage4Done,
            onStepTap: _buildStepTapHandler(),
          ),
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
            child: _editingStage != null
                ? _buildEditForm(_editingStage!)
                : _stage4Done
                    ? _Stage4CompleteView(
                        trip: _trip,
                        onDone: () => Navigator.of(context).pop(),
                      )
                    : _showStage4
                        ? _Stage4Form(
                            trip: _trip,
                            onComplete: () => setState(() => _stage4Done = true),
                          )
                        : stage == 3
                            ? _CompletionView(
                                trip: _trip,
                                emptyWeightKg: state.emptyWeightKg,
                                emptyWeightUnit: state.emptyWeightUnit ?? 'tons',
                                loadedWeightKg: state.loadedWeightKg,
                                loadedWeightUnit: state.loadedWeightUnit ?? 'tons',
                                onDone: () => Navigator.of(context).pop(),
                                onNextStage: () => setState(() => _showStage4 = true),
                              )
                            : stage == 0
                                ? _Stage1Form(
                                    key: ValueKey('s1_${_trip.id}_$_tripFreshness'),
                                    providerKey: _providerKey,
                                    trip: _trip,
                                    onEditDone: null,
                                  )
                                : stage == 1
                                    ? _Stage2Form(
                                        key: ValueKey('s2_${_trip.id}_$_tripFreshness'),
                                        providerKey: _providerKey,
                                        trip: _trip,
                                      )
                                    : _trip.s2LoadingSlipUrl == null
                                        ? _LoadingSlipMini(
                                            key: ValueKey('slip_${_trip.id}'),
                                            trip: _trip,
                                            onUploaded: (updated) {
                                              setState(() {
                                                _trip = updated;
                                                ref.read(tripProvider.notifier).patchTrip(updated);
                                              });
                                            },
                                          )
                                        : _Stage3Form(
                                            key: ValueKey('s3_${_trip.id}_$_tripFreshness'),
                                            providerKey: _providerKey,
                                            trip: _trip,
                                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Trip state badge (5-state: Pending / Ongoing / In Transit / Completed / Cancelled) ──

(String, Color, Color) _tripStateColors(TripModel trip) {
  if (trip.isCancelled) return ('CANCELLED', const Color(0xFFFFDAD6), const Color(0xFFBA1A1A));
  if (trip.isCompleted) return ('COMPLETED', const Color(0xFFECEEF0), const Color(0xFF546067));
  if (trip.currentStage >= 4) return ('IN TRANSIT', const Color(0xFFD7F0D9), const Color(0xFF1B5E20));
  if (trip.currentStage >= 1) return ('ONGOING', const Color(0xFFFFE8D5), const Color(0xFFFF6B00));
  return ('PENDING', const Color(0xFFFFF3E0), const Color(0xFFE65100));
}

class _TripStateBadge extends StatelessWidget {
  final TripModel trip;
  const _TripStateBadge({required this.trip});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _tripStateColors(trip);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w700, color: fg,
              letterSpacing: 0.6)),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatefulWidget {
  final TripModel trip;
  final bool stage4Done;
  final Function(int)? onStepTap;
  const _StepIndicator({required this.trip, required this.stage4Done, this.onStepTap});

  static const _labels = ['Details', 'Compliance', 'Slip', 'Arrival', 'Exit'];

  int visualIndex() {
    if (stage4Done) return 5;
    final s = trip.currentStage;
    if (s == 0) return 0;
    if (s == 1) return 1;
    if (s == 2 && trip.s2LoadingSlipUrl == null) return 2;
    if (s == 2) return 3;
    return 4;
  }

  @override
  State<_StepIndicator> createState() => _StepIndicatorState();
}

class _StepIndicatorState extends State<_StepIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visualIdx = widget.visualIndex();

    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: List.generate(5, (i) {
          final stepLabel = i < 2 ? '${i + 1}' : i == 2 ? 'LS' : '$i';
          final isDone   = visualIdx > i;
          final isActive = visualIdx == i;
          final color   = isDone ? _success : isActive ? _primary : _secondary;
          final bgColor = isDone
              ? _success.withValues(alpha: 0.12)
              : isActive
                  ? _primary.withValues(alpha: 0.10)
                  : _border;

          // Static green glow for done; animated orange glow for active
          final circleShadow = isDone
              ? [BoxShadow(color: _success.withValues(alpha: 0.45), blurRadius: 8, spreadRadius: 1)]
              : <BoxShadow>[];

          final dot = Column(
            children: [
              isActive
                  // Only the active circle rebuilds on every frame
                  ? AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bgColor,
                          border: Border.all(color: _primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.28 + _pulseAnim.value * 0.30),
                              blurRadius: 8 + _pulseAnim.value * 8,
                              spreadRadius: 1 + _pulseAnim.value * 1.5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(stepLabel,
                              style: _manrope(
                                  size: i == 2 ? 9 : 11,
                                  weight: FontWeight.w800,
                                  color: _primary)),
                        ),
                      ),
                    )
                  : Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgColor,
                        border: Border.all(color: color, width: isDone ? 2 : 1),
                        boxShadow: circleShadow,
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(Icons.check_rounded, color: _success, size: 14)
                            : Text(stepLabel,
                                style: _manrope(
                                    size: i == 2 ? 9 : 11,
                                    weight: FontWeight.w800,
                                    color: color)),
                      ),
                    ),
              const SizedBox(height: 5),
              Text(
                _StepIndicator._labels[i],
                style: _inter(
                    size: 8,
                    weight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: color),
                textAlign: TextAlign.center,
              ),
            ],
          );

          final Widget dotWidget = isDone && widget.onStepTap != null
              ? GestureDetector(
                  onTap: () => widget.onStepTap!(i),
                  child: dot,
                )
              : dot;

          if (i == 4) return dotWidget;

          return Expanded(
            child: Row(
              children: [
                dotWidget,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      height: isDone ? 3 : 2,
                      decoration: BoxDecoration(
                        color: isDone ? _success : _border,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: isDone
                            ? [BoxShadow(color: _success.withValues(alpha: 0.40), blurRadius: 6)]
                            : [],
                      ),
                    ),
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
  final TripModel trip;
  /// Called after a successful update-submit when the user was editing stage 1 from stage 2.
  final VoidCallback? onEditDone;
  const _Stage1Form({super.key, required this.providerKey, required this.trip, this.onEditDone});

  @override
  ConsumerState<_Stage1Form> createState() => _Stage1FormState();
}

class _Stage1FormState extends ConsumerState<_Stage1Form> {
  final _formKey = GlobalKey<FormState>();
  final _picker  = ImagePicker();

  // ── Text fields ─────────────────────────────────────────────────────────────
  final _driverName     = TextEditingController();
  final _driverPhone    = TextEditingController();
  final _drivingLicense = TextEditingController();
  final _aadhaar        = TextEditingController();

  // ── Focus nodes (for auto-scroll on validation error) ─────────────────────
  final _driverNameFocus     = FocusNode();
  final _driverPhoneFocus    = FocusNode();
  final _drivingLicenseFocus = FocusNode();
  final _aadhaarFocus        = FocusNode();

  // ── File uploads (bytes + filename, for newly picked files) ─────────────────
  ({Uint8List bytes, String name})? _dlDoc;
  ({Uint8List bytes, String name})? _dlBackDoc;
  ({Uint8List bytes, String name})? _aadhaarDoc;
  ({Uint8List bytes, String name})? _aadhaarBackDoc;
  ({Uint8List bytes, String name})? _rcDoc;
  ({Uint8List bytes, String name})? _insuranceDoc;
  ({Uint8List bytes, String name})? _pollutionDoc;
  ({Uint8List bytes, String name})? _fitnessDoc;
  ({Uint8List bytes, String name})? _panDoc;
  ({Uint8List bytes, String name})? _taxDeclDoc;
  ({Uint8List bytes, String name})? _cancelledChequeDoc;

  Timer? _debounce;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    _prefillFromDraft();
    for (final c in [_driverName, _driverPhone, _drivingLicense, _aadhaar]) {
      c.addListener(_onFieldChanged);
    }
  }

  // ── Draft restore ────────────────────────────────────────────────────────────

  void _prefillFromDraft() {
    final trip = widget.trip;
    final draft = trip.draftData;

    // Prefer draft data over committed trip fields (draft = in-progress edits)
    if (draft != null && draft['stage'] == 1) {
      final d = draft['data'] as Map<String, dynamic>? ?? {};
      _driverName.text     = d['driver_name']    as String? ?? '';
      final rawPhone       = d['driver_phone']   as String? ?? '';
      _driverPhone.text    = rawPhone.startsWith('+91') ? rawPhone.substring(3) : rawPhone;
      _drivingLicense.text = d['driving_license'] as String? ?? '';
      _aadhaar.text        = d['aadhaar']         as String? ?? '';
      _dlDoc              = _restoreFile(d, 'dl_doc');
      _dlBackDoc          = _restoreFile(d, 'dl_back_doc');
      _aadhaarDoc         = _restoreFile(d, 'aadhaar_doc');
      _aadhaarBackDoc     = _restoreFile(d, 'aadhaar_back_doc');
      _rcDoc              = _restoreFile(d, 'rc_doc');
      _insuranceDoc       = _restoreFile(d, 'insurance_doc');
      _pollutionDoc       = _restoreFile(d, 'pollution_doc');
      _fitnessDoc         = _restoreFile(d, 'fitness_doc');
      _panDoc             = _restoreFile(d, 'pan_doc');
      _taxDeclDoc         = _restoreFile(d, 'tax_decl_doc');
      _cancelledChequeDoc = _restoreFile(d, 'cancelled_cheque_doc');
      if (draft['saved_at'] != null) {
        _lastSaved = DateTime.tryParse(draft['saved_at'] as String);
      }
      return;
    }

    // Fall back to committed trip fields (stage 1 already submitted)
    if (trip.currentStage >= 1) {
      _driverName.text = trip.s1DriverName ?? '';
      final rawPhone   = trip.s1DriverPhone ?? '';
      _driverPhone.text = rawPhone.startsWith('+91') ? rawPhone.substring(3) : rawPhone;
      _drivingLicense.text = trip.s1DrivingLicense ?? '';
      _aadhaar.text        = trip.s1Aadhaar ?? '';
      // File URLs are shown via _serverUrl fields — no bytes to restore
    }
  }

  ({Uint8List bytes, String name})? _restoreFile(Map<String, dynamic> d, String key) {
    final b64  = d['${key}_b64']  as String?;
    final name = d['${key}_name'] as String?;
    if (b64 == null || name == null) return null;
    try { return (bytes: base64Decode(b64), name: name); } catch (_) { return null; }
  }

  // ── Draft save ───────────────────────────────────────────────────────────────

  void _onFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  void _onUploadChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _saveDraft);
  }

  Map<String, dynamic> _fileDraftEntry(({Uint8List bytes, String name})? f, String key) {
    if (f == null) return {};
    return {'${key}_b64': base64Encode(f.bytes), '${key}_name': f.name};
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/draft', data: {
        'stage': 1,
        'data': {
          'driver_name':     _driverName.text.trim(),
          'driver_phone':    '+91${_driverPhone.text.trim()}',
          'driving_license': _drivingLicense.text.trim(),
          'aadhaar':         _aadhaar.text.trim(),
          ..._fileDraftEntry(_dlDoc,              'dl_doc'),
          ..._fileDraftEntry(_dlBackDoc,          'dl_back_doc'),
          ..._fileDraftEntry(_aadhaarDoc,         'aadhaar_doc'),
          ..._fileDraftEntry(_aadhaarBackDoc,     'aadhaar_back_doc'),
          ..._fileDraftEntry(_rcDoc,              'rc_doc'),
          ..._fileDraftEntry(_insuranceDoc,       'insurance_doc'),
          ..._fileDraftEntry(_pollutionDoc,       'pollution_doc'),
          ..._fileDraftEntry(_fitnessDoc,         'fitness_doc'),
          ..._fileDraftEntry(_panDoc,             'pan_doc'),
          ..._fileDraftEntry(_taxDeclDoc,         'tax_decl_doc'),
          ..._fileDraftEntry(_cancelledChequeDoc, 'cancelled_cheque_doc'),
        },
      });
      if (mounted) setState(() => _lastSaved = DateTime.now());
    } on DioException catch (e) {
      // Surface draft save failures so they are visible during testing
      final status = e.response?.statusCode;
      final detail = e.response?.data?['detail'] as String? ?? e.message ?? 'Unknown error';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Draft save failed ($status): $detail',
              style: const TextStyle(fontSize: 12)),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_driverName, _driverPhone, _drivingLicense, _aadhaar]) {
      c.dispose();
    }
    for (final f in [_driverNameFocus, _driverPhoneFocus, _drivingLicenseFocus, _aadhaarFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Validators ───────────────────────────────────────────────────────────────

  String? _validateDriverName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Driver Name is required';
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v.trim())) return 'Only alphabets allowed';
    if (v.trim().length > 25) return 'Maximum 25 characters';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) return 'Enter exactly 10 digits';
    return null;
  }

  String? _validateAadhaar(String? v) {
    if (v == null || v.trim().isEmpty) return 'Aadhaar is required';
    final cleaned = v.trim().replaceAll(' ', '');
    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) return 'Aadhaar must be exactly 12 digits';
    return null;
  }

  String? _validateDrivingLicense(String? v) {
    if (v == null || v.trim().isEmpty) return 'Driving License is required';
    final cleaned = v.trim().replaceAll(RegExp(r'[\s/\-]'), '').toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{10,18}$').hasMatch(cleaned)) {
      return 'Invalid format — 10–18 alphanumeric chars (e.g. RJ1420230012345)';
    }
    return null;
  }

  // ── File picker ──────────────────────────────────────────────────────────────

  Future<void> _pickFile(
    ImageSource source,
    void Function(({Uint8List bytes, String name}) f) onPicked,
  ) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    onPicked((bytes: bytes, name: picked.name));
    setState(() {});
    _onUploadChanged();
  }

  // ── Auto-scroll to first invalid field ────────────────────────────────────

  void _scrollToFirstError() {
    final checks = [
      (_driverNameFocus,     _validateDriverName(_driverName.text)),
      (_driverPhoneFocus,    _validatePhone(_driverPhone.text)),
      (_drivingLicenseFocus, _validateDrivingLicense(_drivingLicense.text)),
      (_aadhaarFocus,        _validateAadhaar(_aadhaar.text)),
    ];
    for (final (focus, error) in checks) {
      if (error != null) {
        focus.requestFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = focus.context;
          if (ctx != null) {
            Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 300));
          }
        });
        return;
      }
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    final dlCleaned = _drivingLicense.text.trim()
        .replaceAll(RegExp(r'[\s/\-]'), '').toUpperCase();

    final fields = <String, dynamic>{
      'driver_name':     _driverName.text.trim(),
      'driver_phone':    '+91${_driverPhone.text.trim()}',
      'driving_license': dlCleaned,
      'aadhaar':         _aadhaar.text.trim().replaceAll(' ', ''),
    };

    void _addFile(String key, ({Uint8List bytes, String name})? f) {
      if (f != null) fields[key] = MultipartFile.fromBytes(f.bytes, filename: f.name);
    }
    _addFile('driving_license_doc',       _dlDoc);
    _addFile('driving_license_doc_back',  _dlBackDoc);
    _addFile('aadhaar_doc',               _aadhaarDoc);
    _addFile('aadhaar_doc_back',          _aadhaarBackDoc);
    _addFile('rc_doc',               _rcDoc);
    _addFile('insurance_doc',        _insuranceDoc);
    _addFile('pollution_doc',        _pollutionDoc);
    _addFile('fitness_doc',          _fitnessDoc);
    _addFile('pan_doc',              _panDoc);
    _addFile('tax_declaration_doc',  _taxDeclDoc);
    _addFile('cancelled_cheque_doc', _cancelledChequeDoc);

    final isEdit = widget.trip.currentStage >= 1;
    final ok = await ref
        .read(tripStagesProvider(widget.providerKey).notifier)
        .submitStage1(FormData.fromMap(fields));

    if (ok && mounted) {
      final msg = isEdit ? 'Stage 1 updated successfully.' : 'Stage 1 saved. Proceed to compliance check.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      widget.onEditDone?.call();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: _inter(size: 12, color: _secondary),
    filled: true,
    fillColor: _surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _error, width: 1.5)),
  );

  Widget _uploadTile(
    String label,
    String subtitle,
    ({Uint8List bytes, String name})? file,
    void Function(({Uint8List bytes, String name}) f) onPicked,
    VoidCallback onRemove, {
    String? existingUrl,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _DocUploadTile(
          label: label,
          subtitle: subtitle,
          bytes: file?.bytes,
          fileName: file?.name,
          existingUrl: file == null ? existingUrl : null,
          onPickSource: (src) => _pickFile(src, onPicked),
          onRemove: onRemove,
        ),
      );

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
            // ── Driver Details ─────────────────────────────────────────────────
            _SectionHeader(icon: Icons.person_outline_rounded, title: 'Driver Details'),

            // Driver Name — alphabets only, max 25
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _driverName,
                focusNode: _driverNameFocus,
                style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
                validator: _validateDriverName,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  LengthLimitingTextInputFormatter(25),
                ],
                decoration: _dec('Driver Name'),
              ),
            ),

            // Driver Phone — +91 shown as static prefix, user enters 10 digits
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _driverPhone,
                focusNode: _driverPhoneFocus,
                keyboardType: TextInputType.number,
                style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
                validator: _validatePhone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: _dec('Phone Number').copyWith(
                  prefixText: '+91 ',
                  prefixStyle: _inter(size: 13, color: _onSurface, weight: FontWeight.w600),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
            ),

            // Driving License — alphanumeric, 10-18 chars
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TextFormField(
                controller: _drivingLicense,
                focusNode: _drivingLicenseFocus,
                style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
                validator: _validateDrivingLicense,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9/\-]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: _dec('Driving License No.'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text(
                'New: RJ1420230012345   Old: RJ14/1234/2009',
                style: _inter(size: 11, color: _secondary),
              ),
            ),

            // Aadhaar — exactly 12 digits
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _aadhaar,
                focusNode: _aadhaarFocus,
                keyboardType: TextInputType.number,
                style: _inter(size: 13, color: _onSurface, weight: FontWeight.w500),
                validator: _validateAadhaar,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                decoration: _dec('Aadhaar Number (12 digits)'),
              ),
            ),

            // Driving License — Front & Back
            _DocPairSection(
              title: 'Driving License',
              frontTile: _uploadTile(
                'Front Side',
                'Photo of the front of the driving license',
                _dlDoc,
                (f) => _dlDoc = f,
                () { setState(() => _dlDoc = null); _onUploadChanged(); },
                existingUrl: widget.trip.s1DrivingLicenseUrl,
              ),
              backTile: _uploadTile(
                'Back Side',
                'Photo of the back of the driving license',
                _dlBackDoc,
                (f) => _dlBackDoc = f,
                () { setState(() => _dlBackDoc = null); _onUploadChanged(); },
                existingUrl: widget.trip.s1DrivingLicenseBackUrl,
              ),
            ),

            // Aadhaar Card — Front & Back
            _DocPairSection(
              title: 'Aadhaar Card',
              frontTile: _uploadTile(
                'Front Side',
                'Photo of the front of the Aadhaar card',
                _aadhaarDoc,
                (f) => _aadhaarDoc = f,
                () { setState(() => _aadhaarDoc = null); _onUploadChanged(); },
                existingUrl: widget.trip.s1AadhaarUrl,
              ),
              backTile: _uploadTile(
                'Back Side',
                'Photo of the back of the Aadhaar card',
                _aadhaarBackDoc,
                (f) => _aadhaarBackDoc = f,
                () { setState(() => _aadhaarBackDoc = null); _onUploadChanged(); },
                existingUrl: widget.trip.s1AadhaarBackUrl,
              ),
            ),
            const SizedBox(height: 8),

            // ── Vehicle Documents ──────────────────────────────────────────────
            _SectionHeader(icon: Icons.directions_car_outlined, title: 'Vehicle Documents'),
            _uploadTile('RC (Registration Certificate)', 'Upload vehicle RC',
              _rcDoc, (f) => _rcDoc = f,
              () { setState(() => _rcDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1Rc),
            _uploadTile('Insurance', 'Upload insurance document',
              _insuranceDoc, (f) => _insuranceDoc = f,
              () { setState(() => _insuranceDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1Insurance),
            _uploadTile('Pollution Certificate', 'Upload pollution certificate',
              _pollutionDoc, (f) => _pollutionDoc = f,
              () { setState(() => _pollutionDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1Pollution),
            _uploadTile('Fitness Certificate', 'Upload fitness certificate',
              _fitnessDoc, (f) => _fitnessDoc = f,
              () { setState(() => _fitnessDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1Fitness),
            const SizedBox(height: 8),

            // ── Owner Documents ────────────────────────────────────────────────
            _SectionHeader(icon: Icons.business_outlined, title: 'Owner Documents'),
            _uploadTile('PAN', 'Upload PAN card',
              _panDoc, (f) => _panDoc = f,
              () { setState(() => _panDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1Pan),
            _uploadTile('Tax Declaration', 'Upload tax declaration document',
              _taxDeclDoc, (f) => _taxDeclDoc = f,
              () { setState(() => _taxDeclDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1TaxDeclaration),
            const SizedBox(height: 8),

            // ── Truck Owner Payment Details ────────────────────────────────────
            _SectionHeader(icon: Icons.account_balance_outlined, title: 'Truck Owner Payment Details'),
            _uploadTile('Cancelled Cheque (Owner / Transporter)', 'Upload a cancelled cheque',
              _cancelledChequeDoc, (f) => _cancelledChequeDoc = f,
              () { setState(() => _cancelledChequeDoc = null); _onUploadChanged(); },
              existingUrl: widget.trip.s1CancelledCheque),
            const SizedBox(height: 8),

            if (_lastSaved != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined, size: 14, color: _success),
                    const SizedBox(width: 4),
                    Text('Last saved: ${_formatSaved(_lastSaved!)}',
                        style: _inter(size: 11, color: _success)),
                  ],
                ),
              ),
            const SizedBox(height: 8),

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


String _formatSaved(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  return '${diff.inHours}h ago';
}

// ─── Stage 2: Pre-Arrival Compliance Check ────────────────────────────────────

class _Stage2Form extends ConsumerStatefulWidget {
  final (String, int) providerKey;
  final TripModel trip;
  final VoidCallback? onEditDone;
  const _Stage2Form({super.key, required this.providerKey, required this.trip, this.onEditDone});

  @override
  ConsumerState<_Stage2Form> createState() => _Stage2FormState();
}

class _Stage2FormState extends ConsumerState<_Stage2Form> {
  bool _specsVerified            = false;
  bool _docsVerified             = false;
  bool _driverDocsValid          = false;
  bool _entryPermission          = false; // actual state — set only by button press
  bool _entryPermissionChecked   = false; // visual checkbox — does not affect draft
  String? _dharamKantaLoc;  // 'inside' | 'outside'
  bool _s2WeightConfirmed   = false;
  final _emptyWeightCtrl    = TextEditingController();
  final _emptyWeightUnit    = ValueNotifier<String>('tons');

  // ── Keys for auto-scroll on validation error ──────────────────────────────
  final _checklistKey         = GlobalKey();
  final _dharamKantaKey       = GlobalKey();
  final _weightSectionKey     = GlobalKey();
  final _entryPermissionKey   = GlobalKey();

  Timer? _debounce;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    _prefillFromDraft();
    _emptyWeightCtrl.addListener(_onWeightTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _emptyWeightCtrl.dispose();
    _emptyWeightUnit.dispose();
    super.dispose();
  }

  void _prefillFromDraft() {
    final trip = widget.trip;
    final draft = trip.draftData;
    if (draft != null && draft['stage'] == 2) {
      final d = draft['data'] as Map<String, dynamic>? ?? {};
      _specsVerified    = d['specs_verified']              as bool?   ?? false;
      _docsVerified     = d['docs_verified']               as bool?   ?? false;
      _driverDocsValid  = d['driver_docs_valid']           as bool?   ?? false;
      _entryPermissionChecked = d['entry_permission']       as bool?   ?? false;
      _dharamKantaLoc   = d['dharam_kanta_location']       as String?;
      _s2WeightConfirmed = d['s2_weight_confirmed']        as bool?   ?? false;
      _emptyWeightCtrl.text = d['empty_weight_before_loading'] as String? ?? '';
      _emptyWeightUnit.value = d['empty_weight_unit']      as String? ?? 'tons';
      if (draft['saved_at'] != null) {
        _lastSaved = DateTime.tryParse(draft['saved_at'] as String);
      }
      return;
    }
    // Fall back to committed stage 2 data when re-editing
    if (trip.currentStage >= 2) {
      _specsVerified   = trip.s2SpecsVerified    ?? false;
      _docsVerified    = trip.s2DocsVerified     ?? false;
      _driverDocsValid = trip.s2DriverDocsValid  ?? false;
      _entryPermissionChecked = trip.s2EntryPermission  ?? false;

      // Restore dharam kanta data persisted at submission
      if (trip.s2DharamKantaLoc != null && trip.s2DharamKantaLoc!.isNotEmpty) {
        _dharamKantaLoc = trip.s2DharamKantaLoc;
        if (trip.s2DharamKantaLoc == 'outside' &&
            trip.s2EmptyWeightKg != null && trip.s2EmptyWeightKg!.isNotEmpty) {
          _emptyWeightCtrl.text = trip.s2EmptyWeightKg!;
          _emptyWeightUnit.value = trip.s2EmptyWeightUnit ?? 'tons';
          _s2WeightConfirmed = true;
        }
      }
    }
  }

  void _onWeightTextChanged() {
    _onFieldChanged();
  }

  void _onFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  void _onCheckChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/draft', data: {
        'stage': 2,
        'data': {
          'specs_verified':             _specsVerified,
          'docs_verified':              _docsVerified,
          'driver_docs_valid':          _driverDocsValid,
          'entry_permission':           _entryPermission,
          'dharam_kanta_location':      _dharamKantaLoc ?? '',
          'empty_weight_before_loading': _emptyWeightCtrl.text.trim(),
          'empty_weight_unit':          _emptyWeightUnit.value,
          's2_weight_confirmed':        _s2WeightConfirmed,
        },
      });
      if (mounted) setState(() => _lastSaved = DateTime.now());
    } catch (_) {}
  }

  void _scrollToKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 300));
      }
    });
  }

  void _showError(GlobalKey key, String message) {
    _scrollToKey(key);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: _inter(size: 13, color: Colors.white)),
      backgroundColor: _error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _submit() async {
    // 1. All 3 verification checkboxes must be checked
    if (!_specsVerified || !_docsVerified || !_driverDocsValid) {
      _showError(_checklistKey, 'Please confirm all verification items before proceeding.');
      return;
    }

    // 2. Dharam Kanta location must be selected (inside or outside)
    if (_dharamKantaLoc == null) {
      _showError(_dharamKantaKey, 'Please select weighbridge location (Inside or Outside Factory).');
      return;
    }

    // 3. If Outside Factory, weight must be entered (> 0) and confirmed
    if (_dharamKantaLoc == 'outside') {
      final weightVal = double.tryParse(_emptyWeightCtrl.text.trim()) ?? 0;
      if (_emptyWeightCtrl.text.trim().isEmpty || weightVal <= 0 || !_s2WeightConfirmed) {
        _showError(_weightSectionKey,
            'Please enter a valid empty truck weight (greater than 0) and confirm it.');
        return;
      }
    }

    // 4. Entry permission checkbox must be checked
    if (!_entryPermissionChecked) {
      _showError(_entryPermissionKey, 'Please check "Truck Entry Permission Issued" before proceeding.');
      return;
    }

    if (!_entryPermission) {
      _scrollToKey(_entryPermissionKey);
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
    // Persist DK data into shared provider state before submit
    if (_dharamKantaLoc == 'outside' && _emptyWeightCtrl.text.trim().isNotEmpty) {
      ref.read(tripStagesProvider(widget.providerKey).notifier)
          .setS2DharamKanta('outside', _emptyWeightCtrl.text.trim(), _emptyWeightUnit.value);
    }

    final ok = await ref.read(tripStagesProvider(widget.providerKey).notifier).submitStage2({
      'specs_verified':          _specsVerified,
      'docs_verified':           _docsVerified,
      'driver_docs_valid':       _driverDocsValid,
      'entry_permission':        _entryPermission,
      'dharam_kanta_location':   _dharamKantaLoc ?? '',
      if (_dharamKantaLoc == 'outside' && _emptyWeightCtrl.text.trim().isNotEmpty) ...{
        'empty_weight_before_loading': _emptyWeightCtrl.text.trim(),
        'empty_weight_unit':           _emptyWeightUnit.value,
      },
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
      widget.onEditDone?.call();
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
            key: _checklistKey,
            label: 'Truck specifications match requirement',
            value: _specsVerified,
            onChanged: (v) { setState(() => _specsVerified = v); _onCheckChanged(); },
          ),
          _CheckItem(
            label: 'All documents uploaded',
            value: _docsVerified,
            onChanged: (v) { setState(() => _docsVerified = v); _onCheckChanged(); },
          ),
          _CheckItem(
            label: 'Driver documents valid',
            value: _driverDocsValid,
            onChanged: (v) { setState(() => _driverDocsValid = v); _onCheckChanged(); },
          ),
          const SizedBox(height: 20),

          // ── Dharam Kanta (Weighbridge) location ──
          Container(
            key: _dharamKantaKey,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border, width: 1.5),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.scale_outlined, color: _primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Dharam Kanta (Weighbridge)',
                      style: _manrope(size: 14, weight: FontWeight.w700)),
                ]),
                const SizedBox(height: 3),
                Text('Is the weighbridge inside or outside the factory?',
                    style: _inter(size: 12)),
                const SizedBox(height: 12),

                // Inside Factory checkbox
                _CheckItem(
                  label: 'Inside Factory',
                  value: _dharamKantaLoc == 'inside',
                  onChanged: (v) {
                    setState(() {
                      _dharamKantaLoc = v ? 'inside' : null;
                      if (v) {
                        _emptyWeightCtrl.clear();
                        _s2WeightConfirmed = false;
                      }
                    });
                    _onCheckChanged();
                  },
                ),

                // Outside Factory checkbox
                _CheckItem(
                  label: 'Outside Factory',
                  value: _dharamKantaLoc == 'outside',
                  onChanged: (v) {
                    setState(() {
                      _dharamKantaLoc = v ? 'outside' : null;
                      if (v) {
                        _emptyWeightCtrl.clear();
                        _s2WeightConfirmed = false;
                      }
                    });
                    _onCheckChanged();
                  },
                ),

                // Weight input — only shown when Outside Factory is selected
                if (_dharamKantaLoc == 'outside') ...[
                  const SizedBox(height: 14),
                  _WeighField(
                    key: _weightSectionKey,
                    controller: _emptyWeightCtrl,
                    label: 'Empty Truck Weight Before Loading',
                    hint: 'e.g. 12.5',
                    note: 'Weight recorded outside factory (before loading).',
                    unitNotifier: _emptyWeightUnit,
                    enabled: !_s2WeightConfirmed,
                  ),
                  const SizedBox(height: 10),
                  if (!_s2WeightConfirmed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final val = double.tryParse(_emptyWeightCtrl.text.trim()) ?? 0;
                        if (_emptyWeightCtrl.text.trim().isEmpty || val <= 0) return;
                        ref
                            .read(tripStagesProvider(widget.providerKey).notifier)
                            .setS2DharamKanta('outside', _emptyWeightCtrl.text.trim(), _emptyWeightUnit.value);
                        setState(() => _s2WeightConfirmed = true);
                        FocusScope.of(context).unfocus();
                        _saveDraft();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFDDE0E2),
                        disabledForegroundColor: _secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.input_rounded, size: 16),
                      label: const Text('Confirm Weight'),
                    ),
                  ),
                  if (_s2WeightConfirmed)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: _success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: _success, size: 16),
                        const SizedBox(width: 8),
                        Text('Weight recorded: ${_emptyWeightCtrl.text.trim()} ${_emptyWeightUnit.value}',
                            style: _manrope(size: 13, weight: FontWeight.w700, color: _success)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Entry permission — highlighted
          Container(
            key: _entryPermissionKey,
            decoration: BoxDecoration(
              color: _entryPermissionChecked
                  ? _success.withValues(alpha: 0.08)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _entryPermissionChecked ? _success : _primary,
                width: 1.5,
              ),
            ),
            child: _CheckItem(
              label: 'Truck Entry Permission Issued',
              sublabel: 'Factory logistics team receives truck number + driver details.',
              value: _entryPermissionChecked,
              onChanged: (v) => setState(() => _entryPermissionChecked = v),
              activeColor: _success,
            ),
          ),
          const SizedBox(height: 28),

          if (_lastSaved != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_outlined, size: 14, color: _success),
                  const SizedBox(width: 4),
                  Text('Last saved: ${_formatSaved(_lastSaved!)}',
                      style: _inter(size: 11, color: _success)),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : () {
                setState(() => _entryPermission = true);
                _submit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _entryPermissionChecked ? _success : _secondary,
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

// ─── Loading Slip Mini-Stage (between Stage 2 and Stage 3) ───────────────────

class _LoadingSlipMini extends ConsumerStatefulWidget {
  final TripModel trip;
  final void Function(TripModel updated) onUploaded;
  const _LoadingSlipMini({super.key, required this.trip, required this.onUploaded});

  @override
  ConsumerState<_LoadingSlipMini> createState() => _LoadingSlipMiniState();
}

class _LoadingSlipMiniState extends ConsumerState<_LoadingSlipMini> {
  ({Uint8List bytes, String name})? _slipFile;
  bool _uploading = false;
  String? _errorMsg;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _prefillFromDraft();
  }

  void _prefillFromDraft() {
    final draft = widget.trip.draftData;
    if (draft == null) return;
    if (draft['stage'] != 'loading_slip') return;
    final data = draft['data'] as Map<String, dynamic>?;
    if (data == null) return;
    final b64 = data['slip_bytes'] as String?;
    final name = data['slip_name'] as String? ?? 'loading_slip.jpg';
    if (b64 != null && b64.isNotEmpty) {
      try {
        final bytes = base64Decode(b64);
        setState(() => _slipFile = (bytes: bytes, name: name));
      } catch (_) {}
    }
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/draft', data: {
        'stage': 'loading_slip',
        'data': {
          if (_slipFile != null) 'slip_bytes': base64Encode(_slipFile!.bytes),
          if (_slipFile != null) 'slip_name': _slipFile!.name,
        },
      });
    } catch (_) {}
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _slipFile = (bytes: bytes, name: picked.name);
      _errorMsg = null;
    });
    _saveDraft();
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
              Text('Upload Loading Slip', style: _manrope(size: 16, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Choose how to add the slip image', style: _inter(size: 12, color: _secondary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: _primary,
                      onTap: () { Navigator.pop(context); _pick(ImageSource.camera); },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: _secondary,
                      onTap: () { Navigator.pop(context); _pick(ImageSource.gallery); },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _upload() async {
    if (_slipFile == null) return;
    setState(() { _uploading = true; _errorMsg = null; });
    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'slip': MultipartFile.fromBytes(_slipFile!.bytes, filename: _slipFile!.name),
      });
      final resp = await dio.post(
        '/api/trips/${widget.trip.id}/loading-slip',
        data: formData,
      );
      final updated = TripModel.fromJson(
        (resp.data as Map<String, dynamic>)['trip'] as Map<String, dynamic>,
      );
      if (mounted) widget.onUploaded(updated);
    } catch (e) {
      final msg = e is DioException
          ? (e.response?.data?['detail'] as String? ?? 'Upload failed')
          : e.toString();
      setState(() { _uploading = false; _errorMsg = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: _primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Loading Slip Required',
                          style: _manrope(size: 15, weight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('Upload the loading slip before the truck can proceed to the factory.',
                          style: _inter(size: 12, color: _secondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionHeader(icon: Icons.upload_file_rounded, title: 'Loading Slip'),

          // Upload tile / preview
          GestureDetector(
            onTap: _showPickerSheet,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _slipFile != null ? _success.withValues(alpha: 0.50) : _border,
                  width: _slipFile != null ? 1.5 : 1,
                ),
              ),
              child: _slipFile != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.memory(
                            _slipFile!.bytes,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () { setState(() => _slipFile = null); _saveDraft(); },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close_rounded, size: 16, color: _error),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _success,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text('Slip Ready', style: _inter(size: 11, color: Colors.white, weight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 40, color: _secondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          Text('Tap to upload loading slip',
                              style: _inter(size: 13, weight: FontWeight.w600, color: _secondary)),
                          const SizedBox(height: 4),
                          Text('Camera or Gallery',
                              style: _inter(size: 11, color: _secondary.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
            ),
          ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: _error, size: 15),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMsg!, style: _inter(size: 12, color: _error))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_slipFile != null && !_uploading) ? _upload : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFDDE0E2),
                disabledForegroundColor: _secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              icon: _uploading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_rounded, size: 20),
              label: Text(_uploading ? 'Uploading...' : 'Submit Loading Slip'),
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
  final TripModel trip;
  final VoidCallback? onEditDone;
  const _Stage3Form({super.key, required this.providerKey, required this.trip, this.onEditDone});

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

  // ── Keys for auto-scroll on validation error ──────────────────────────────
  final _driverParkedKey      = GlobalKey();
  final _docsSubmittedKey     = GlobalKey();
  final _securityVerifiedKey  = GlobalKey();
  final _driverExitedCabinKey = GlobalKey();
  final _wheelStoppersKey     = GlobalKey();
  final _safetyGearKey        = GlobalKey();

  final _emptyTruckWeight  = TextEditingController();
  final _loadedTruckWeight = TextEditingController();
  final _emptyWeightUnit   = ValueNotifier<String>('tons');
  final _loadedWeightUnit  = ValueNotifier<String>('tons');

  // Two-phase: first "Loading Complete", then "Complete Stage"
  bool _loadingComplete = false;

  // Stage 2 Dharam Kanta data — persisted in draft for cross-session restore
  String? _s2DharamKantaLoc;
  String? _s2EmptyWeight;
  String? _s2EmptyWeightUnit;

  // Document uploads — stored as (bytes, filename) tuples for web compatibility
  ({Uint8List bytes, String name})? _biltyData;
  List<({Uint8List bytes, String name})> _materialDocs = [];

  Timer? _debounce;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    _prefillFromDraft();
    _emptyTruckWeight.addListener(_onFieldChanged);
    _loadedTruckWeight.addListener(_onFieldChanged);
    _emptyWeightUnit.addListener(_onFieldChanged);
    _loadedWeightUnit.addListener(_onFieldChanged);
    // Restore S2 Dharam Kanta into provider after first frame (ref available)
    if (_s2DharamKantaLoc == 'outside' && (_s2EmptyWeight?.isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tripStagesProvider(widget.providerKey).notifier)
            .setS2DharamKanta('outside', _s2EmptyWeight!, _s2EmptyWeightUnit ?? 'tons');
      });
    }
  }

  void _prefillFromDraft() {
    final trip = widget.trip;
    final draft = trip.draftData;
    if (draft == null || draft['stage'] != 3) {
      // No draft — prefill weights from committed trip data when re-editing
      if (trip.currentStage >= 3) {
        _emptyTruckWeight.text  = trip.s3EmptyTruckWeightKg  ?? '';
        _loadedTruckWeight.text = trip.s3LoadedTruckWeightKg ?? '';
        _emptyWeightUnit.value  = trip.s3EmptyTruckWeightUnit ?? 'tons';
        _loadedWeightUnit.value = trip.s3LoadedTruckWeightUnit ?? 'tons';
      }
      return;
    }
    final d = draft['data'] as Map<String, dynamic>? ?? {};
    _driverParked       = d['driver_parked']       as bool? ?? false;
    _docsSubmitted      = d['docs_submitted']       as bool? ?? false;
    _securityVerified   = d['security_verified']    as bool? ?? false;
    _driverExitedCabin  = d['driver_exited_cabin']  as bool? ?? false;
    _wheelStoppers      = d['wheel_stoppers']       as bool? ?? false;
    _safetyGear         = d['safety_gear']          as bool? ?? false;
    _loadingComplete    = d['loading_complete']     as bool? ?? false;
    _emptyTruckWeight.text = d['empty_truck_weight']      as String? ?? '';
    _loadedTruckWeight.text = d['loaded_truck_weight']    as String? ?? '';
    _emptyWeightUnit.value = d['empty_truck_weight_unit'] as String? ?? 'tons';
    _loadedWeightUnit.value = d['loaded_truck_weight_unit'] as String? ?? 'tons';
    // Restore Stage 2 Dharam Kanta data (if weight was recorded outside factory)
    _s2DharamKantaLoc   = d['s2_dharam_kanta_loc']    as String?;
    _s2EmptyWeight      = d['s2_empty_weight']         as String?;
    _s2EmptyWeightUnit  = d['s2_empty_weight_unit_s2'] as String?;
    // Restore bilty upload
    final biltyB64 = d['bilty_b64'] as String?;
    final biltyName = d['bilty_name'] as String?;
    if (biltyB64 != null && biltyName != null) {
      _biltyData = (bytes: base64Decode(biltyB64), name: biltyName);
    }
    // Restore material doc uploads
    final matList = d['material_docs'] as List<dynamic>?;
    if (matList != null) {
      _materialDocs = matList
          .whereType<Map<String, dynamic>>()
          .where((m) => m['b64'] != null && m['name'] != null)
          .map((m) => (bytes: base64Decode(m['b64'] as String), name: m['name'] as String))
          .toList();
    }
    if (draft['saved_at'] != null) {
      _lastSaved = DateTime.tryParse(draft['saved_at'] as String);
    }
  }

  void _onFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  void _onCheckChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
    try {
      // Snapshot S2 Dharam Kanta from provider (same-session) or local vars (cross-session restore)
      final stagesState = ref.read(tripStagesProvider(widget.providerKey));
      final s2Loc    = stagesState.s2DharamKantaLoc  ?? _s2DharamKantaLoc;
      final s2Weight = stagesState.s2EmptyWeight      ?? _s2EmptyWeight;
      final s2Unit   = stagesState.s2EmptyWeightUnit  ?? _s2EmptyWeightUnit;

      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/draft', data: {
        'stage': 3,
        'data': {
          'driver_parked':           _driverParked,
          'docs_submitted':          _docsSubmitted,
          'security_verified':       _securityVerified,
          'driver_exited_cabin':     _driverExitedCabin,
          'wheel_stoppers':          _wheelStoppers,
          'safety_gear':             _safetyGear,
          'loading_complete':        _loadingComplete,
          'empty_truck_weight':      _emptyTruckWeight.text.trim(),
          'empty_truck_weight_unit': _emptyWeightUnit.value,
          'loaded_truck_weight':     _loadedTruckWeight.text.trim(),
          'loaded_truck_weight_unit': _loadedWeightUnit.value,
          // Persist S2 Dharam Kanta so it survives re-entry
          if (s2Loc != null) ...{
            's2_dharam_kanta_loc':    s2Loc,
            's2_empty_weight':        s2Weight ?? '',
            's2_empty_weight_unit_s2': s2Unit ?? 'tons',
          },
          // Bilty upload
          if (_biltyData != null) ...{
            'bilty_b64':  base64Encode(_biltyData!.bytes),
            'bilty_name': _biltyData!.name,
          },
          // Material doc uploads
          'material_docs': _materialDocs
              .map((f) => {'b64': base64Encode(f.bytes), 'name': f.name})
              .toList(),
        },
      });
      if (mounted) setState(() => _lastSaved = DateTime.now());
    } catch (_) {}
  }

  final _picker = ImagePicker();

  @override
  void dispose() {
    _debounce?.cancel();
    _emptyTruckWeight.dispose();
    _loadedTruckWeight.dispose();
    _emptyWeightUnit.dispose();
    _loadedWeightUnit.dispose();
    super.dispose();
  }

  Future<void> _pickBilty(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() => _biltyData = (bytes: bytes, name: picked.name));
    _saveDraft();
  }

  Future<void> _pickMaterialDocs(ImageSource source) async {
    if (source == ImageSource.camera) {
      final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      setState(() => _materialDocs = [..._materialDocs, (bytes: bytes, name: picked.name)]);
    } else {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty || !mounted) return;
      final items = await Future.wait(
        picked.map((x) async => (bytes: await x.readAsBytes(), name: x.name)),
      );
      setState(() => _materialDocs = [..._materialDocs, ...items]);
    }
    _saveDraft();
  }

  void _removeMaterialDoc(int index) {
    setState(() => _materialDocs.removeAt(index));
    _saveDraft();
  }

  bool get _allChecked =>
      _driverParked && _docsSubmitted && _securityVerified &&
      _driverExitedCabin && _wheelStoppers && _safetyGear;

  void _scrollToKey3(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 300));
      }
    });
  }

  void _scrollToFirstUnchecked() {
    final checks = [
      (_driverParkedKey,      _driverParked),
      (_docsSubmittedKey,     _docsSubmitted),
      (_securityVerifiedKey,  _securityVerified),
      (_driverExitedCabinKey, _driverExitedCabin),
      (_wheelStoppersKey,     _wheelStoppers),
      (_safetyGearKey,        _safetyGear),
    ];
    for (final (key, checked) in checks) {
      if (!checked) {
        _scrollToKey3(key);
        return;
      }
    }
  }

  void _onLoadingComplete() {
    if (!_allChecked) {
      _scrollToFirstUnchecked();
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
    _saveDraft();
  }

  Future<void> _completeStage() async {
    final stagesState = ref.read(tripStagesProvider(widget.providerKey));
    final s2Weight = stagesState.s2EmptyWeight ?? _s2EmptyWeight ?? '';
    final weightFromS2 =
        (stagesState.s2DharamKantaLoc == 'outside' || _s2DharamKantaLoc == 'outside') &&
        s2Weight.isNotEmpty;

    final fields = <String, dynamic>{
      'driver_parked':            _driverParked.toString(),
      'docs_submitted':           _docsSubmitted.toString(),
      'security_verified':        _securityVerified.toString(),
      'driver_exited_cabin':      _driverExitedCabin.toString(),
      'wheel_stoppers':           _wheelStoppers.toString(),
      'safety_gear':              _safetyGear.toString(),
      // Use Stage 2 weight if it was captured there, otherwise Stage 3 entry
      'empty_truck_weight_kg':    weightFromS2 ? s2Weight : _emptyTruckWeight.text.trim(),
      'empty_truck_weight_unit':  weightFromS2 ? (stagesState.s2EmptyWeightUnit ?? _s2EmptyWeightUnit ?? 'tons') : _emptyWeightUnit.value,
      'loaded_truck_weight_kg':   _loadedTruckWeight.text.trim(),
      'loaded_truck_weight_unit': _loadedWeightUnit.value,
    };

    if (_lastSaved != null) {
      // draft is cleared by server on submit — nothing extra needed
    }

    if (_biltyData != null) {
      fields['bilty'] = MultipartFile.fromBytes(
        _biltyData!.bytes,
        filename: _biltyData!.name,
      );
    }

    if (_materialDocs.isNotEmpty) {
      fields['material_docs'] = _materialDocs
          .map((d) => MultipartFile.fromBytes(d.bytes, filename: d.name))
          .toList();
    }

    final formData = FormData.fromMap(fields);
    final ok = await ref.read(tripStagesProvider(widget.providerKey).notifier).submitStage3(formData);
    if (ok && mounted) {
      widget.onEditDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stagesState = ref.watch(tripStagesProvider(widget.providerKey));
    final busy = stagesState.isSubmitting;
    final s2Weight = stagesState.s2EmptyWeight ?? _s2EmptyWeight ?? '';
    final weightFromS2 =
        (stagesState.s2DharamKantaLoc == 'outside' || _s2DharamKantaLoc == 'outside') &&
        s2Weight.isNotEmpty;

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
            key: _driverParkedKey,
            label: 'Driver parks outside factory',
            value: _driverParked,
            onChanged: (v) { setState(() => _driverParked = v); _onCheckChanged(); },
          ),
          _CheckItem(
            key: _docsSubmittedKey,
            label: 'Documents submitted to security',
            value: _docsSubmitted,
            onChanged: (v) { setState(() => _docsSubmitted = v); _onCheckChanged(); },
          ),
          _CheckItem(
            key: _securityVerifiedKey,
            label: 'Security verifies vehicle requirements',
            value: _securityVerified,
            onChanged: (v) { setState(() => _securityVerified = v); _onCheckChanged(); },
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
                  key: _driverExitedCabinKey,
                  label: 'Driver must exit cabin',
                  value: _driverExitedCabin,
                  onChanged: (v) { setState(() => _driverExitedCabin = v); _onCheckChanged(); },
                  activeColor: _primary,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: _primary.withValues(alpha: 0.15)),
                _CheckItem(
                  key: _wheelStoppersKey,
                  label: 'Wheel stoppers installed',
                  value: _wheelStoppers,
                  onChanged: (v) { setState(() => _wheelStoppers = v); _onCheckChanged(); },
                  activeColor: _primary,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: _primary.withValues(alpha: 0.15)),
                _CheckItem(
                  key: _safetyGearKey,
                  label: 'Safety shoes and helmet required',
                  value: _safetyGear,
                  onChanged: (v) { setState(() => _safetyGear = v); _onCheckChanged(); },
                  activeColor: _primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dharma Kanta — Empty Weight (hidden when already captured in Stage 2)
          if (!weightFromS2) ...[
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
          ],

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
                  Expanded(
                    child: Text('Loading complete. Record loaded truck weight.',
                        style: _inter(size: 12, color: _success, weight: FontWeight.w600)),
                  ),
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
            const SizedBox(height: 20),

            // ── Bilty Upload ──────────────────────────────────────────
            _SectionHeader(icon: Icons.receipt_long_rounded, title: 'Bilty'),
            _DocUploadTile(
              label: 'Upload Bilty',
              subtitle: 'Attach the lorry receipt / bilty document',
              bytes: _biltyData?.bytes,
              fileName: _biltyData?.name,
              onPickSource: _pickBilty,
              onRemove: () => setState(() => _biltyData = null),
            ),
            const SizedBox(height: 20),

            // ── Material Documents Upload ─────────────────────────────
            _SectionHeader(icon: Icons.folder_open_rounded, title: 'Material Documents'),
            _MultiDocUploadTile(
              label: 'Upload Material Documents',
              subtitle: 'Attach invoices, packing lists, or other material docs',
              bytesList: _materialDocs.map((d) => d.bytes).toList(),
              onPickSource: _pickMaterialDocs,
              onRemove: _removeMaterialDoc,
            ),
            const SizedBox(height: 28),

            if (_lastSaved != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined, size: 14, color: _success),
                    const SizedBox(width: 4),
                    Text('Last saved: ${_formatSaved(_lastSaved!)}',
                        style: _inter(size: 11, color: _success)),
                  ],
                ),
              ),
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
  final VoidCallback onNextStage;
  final String? emptyWeightKg;
  final String emptyWeightUnit;
  final String? loadedWeightKg;
  final String loadedWeightUnit;

  const _CompletionView({
    required this.trip,
    required this.onDone,
    required this.onNextStage,
    this.emptyWeightKg,
    this.emptyWeightUnit = 'tons',
    this.loadedWeightKg,
    this.loadedWeightUnit = 'tons',
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          Text('Truck Loading Complete!',
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
            'Loading complete. Proceed to factory exit.',
            textAlign: TextAlign.center,
            style: _inter(size: 13, color: _secondary),
          ),
          const SizedBox(height: 32),

          // Next Stage — primary CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNextStage,
              icon: const Icon(Icons.exit_to_app_rounded, size: 18),
              label: const Text('Next Stage — Truck Exit →'),
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

          // Track Truck
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
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
              icon: const Icon(Icons.local_shipping_rounded, size: 16, color: _primary),
              label: Text('Track Truck', style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: _primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

/// Groups a document's front and back upload tiles under a labelled header.
class _DocPairSection extends StatelessWidget {
  final String title;
  final Widget frontTile;
  final Widget backTile;
  const _DocPairSection({required this.title, required this.frontTile, required this.backTile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _secondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          frontTile,
          backTile,
        ],
      ),
    );
  }
}

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
    super.key,
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
    super.key,
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
  Uint8List? _slipBytes;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() => _slipBytes = bytes);
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
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
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
          if (_slipBytes == null)
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
                  child: Image.memory(
                    _slipBytes!,
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
                    onTap: () => setState(() => _slipBytes = null),
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

// ─── Source picker bottom sheet helper ───────────────────────────────────────

Future<ImageSource?> _showSourcePicker(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFECEEF0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: _primary, size: 20),
              ),
              title: Text('Take Photo',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600,
                      color: _onSurface)),
              subtitle: Text('Use camera',
                  style: GoogleFonts.inter(fontSize: 12, color: _secondary)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded, color: _primary, size: 20),
              ),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600,
                      color: _onSurface)),
              subtitle: Text('Browse photos',
                  style: GoogleFonts.inter(fontSize: 12, color: _secondary)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
  );
}

// ─── Single-file Document Upload Tile ────────────────────────────────────────

class _DocUploadTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final Uint8List? bytes;
  final String? fileName;
  /// Server URL of an already-uploaded file. Shown when [bytes] is null.
  final String? existingUrl;
  final Future<void> Function(ImageSource) onPickSource;
  final VoidCallback onRemove;

  const _DocUploadTile({
    required this.label,
    required this.subtitle,
    required this.bytes,
    this.fileName,
    this.existingUrl,
    required this.onPickSource,
    required this.onRemove,
  });

  Future<void> _pick(BuildContext context) async {
    final source = await _showSourcePicker(context);
    if (source != null) await onPickSource(source);
  }

  @override
  Widget build(BuildContext context) {
    // Newly picked local file — show preview
    if (bytes != null) {
      return Container(
        decoration: BoxDecoration(
          color: _success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _success.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              child: Image.memory(bytes!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: _success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName ?? 'Image selected',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _success),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _pick(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Retake',
                          style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _primary)),
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: _error),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // File saved on server (returning to edit) — show compact "saved" row
    if (existingUrl != null) {
      final docName = existingUrl!.split('/').last;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: _success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _success.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_done_rounded, size: 20, color: _success),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: _success)),
                  const SizedBox(height: 2),
                  Text(docName,
                      style: GoogleFonts.inter(fontSize: 11, color: _secondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _pick(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('Replace',
                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: _primary)),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.upload_file_rounded,
                  color: _primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _secondary)),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline_rounded,
                color: _primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Multi-file Document Upload Tile ─────────────────────────────────────────

class _MultiDocUploadTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final List<Uint8List> bytesList;
  final Future<void> Function(ImageSource) onPickSource;
  final void Function(int) onRemove;

  const _MultiDocUploadTile({
    required this.label,
    required this.subtitle,
    required this.bytesList,
    required this.onPickSource,
    required this.onRemove,
  });

  Future<void> _pick(BuildContext context) async {
    final source = await _showSourcePicker(context);
    if (source != null) await onPickSource(source);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bytesList.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: bytesList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(bytesList[i],
                        width: 90,
                        height: 100,
                        fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: const Icon(Icons.close_rounded,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: () => _pick(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: _primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bytesList.isEmpty
                            ? label
                            : '${bytesList.length} file${bytesList.length > 1 ? 's' : ''} selected — tap to add more',
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: bytesList.isEmpty ? _onSurface : _success),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: _secondary)),
                    ],
                  ),
                ),
                const Icon(Icons.add_circle_outline_rounded,
                    color: _primary, size: 20),
              ],
            ),
          ),
        ),
      ],
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

// ─── Stage 4: Truck Exit From Factory ─────────────────────────────────────────

class _Stage4Form extends ConsumerStatefulWidget {
  final TripModel trip;
  final VoidCallback onComplete;
  const _Stage4Form({required this.trip, required this.onComplete});

  @override
  ConsumerState<_Stage4Form> createState() => _Stage4FormState();
}

class _Stage4FormState extends ConsumerState<_Stage4Form> {
  bool _truckMoved    = false;
  bool _securityCheck = false;
  bool _biltyChecked  = false;
  bool _weightChecked = false;
  bool _materialChecked = false;
  bool _submitting = false;

  Timer? _debounce;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    _prefillFromDraft();
  }

  void _prefillFromDraft() {
    final trip = widget.trip;
    final draft = trip.draftData;
    if (draft == null || draft['stage'] != 4) {
      // No draft — prefill from committed trip data when re-editing
      if (trip.currentStage >= 4) {
        _truckMoved      = trip.s4TruckMoved       ?? false;
        _securityCheck   = trip.s4SecurityVerified  ?? false;
        _biltyChecked    = trip.s4BiltyChecked      ?? false;
        _weightChecked   = trip.s4WeightChecked     ?? false;
        _materialChecked = trip.s4MaterialChecked   ?? false;
      }
      return;
    }
    final d = draft['data'] as Map<String, dynamic>? ?? {};
    _truckMoved     = d['truck_moved']      as bool? ?? false;
    _securityCheck  = d['security_check']   as bool? ?? false;
    _biltyChecked   = d['bilty_checked']    as bool? ?? false;
    _weightChecked  = d['weight_checked']   as bool? ?? false;
    _materialChecked = d['material_checked'] as bool? ?? false;
    if (draft['saved_at'] != null) {
      _lastSaved = DateTime.tryParse(draft['saved_at'] as String);
    }
  }

  void _onCheckChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (!mounted) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/api/trips/${widget.trip.id}/draft', data: {
        'stage': 4,
        'data': {
          'truck_moved':      _truckMoved,
          'security_check':   _securityCheck,
          'bilty_checked':    _biltyChecked,
          'weight_checked':   _weightChecked,
          'material_checked': _materialChecked,
        },
      });
      if (mounted) setState(() => _lastSaved = DateTime.now());
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  bool get _allDone =>
      _truckMoved && _securityCheck && _biltyChecked && _weightChecked && _materialChecked;

  Future<void> _submit() async {
    if (!_allDone || _submitting) return;
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post('/api/trips/${widget.trip.id}/stage/4', data: {
        'truck_moved':        _truckMoved,
        'security_verified':  _securityCheck,
        'bilty_checked':      _biltyChecked,
        'weight_checked':     _weightChecked,
        'material_checked':   _materialChecked,
      });
      // Immediately patch the in-memory trip so currentStage: 4 is reflected
      try {
        final tripJson = (resp.data as Map<String, dynamic>?)?['trip'] as Map<String, dynamic>?;
        if (tripJson != null) {
          ref.read(tripProvider.notifier).patchTrip(TripModel.fromJson(tripJson));
        }
      } catch (_) {}
      widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e', style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildCheckTile({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? _success.withValues(alpha: 0.06) : _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? _success.withValues(alpha: 0.35) : _border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? _success : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? _success : _secondary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: _manrope(
                  size: 14,
                  weight: FontWeight.w600,
                  color: value ? _success : _onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.exit_to_app_rounded, color: _primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Truck Exit From Factory',
                          style: _manrope(size: 15, weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('Verify all exit procedures before releasing truck',
                          style: _inter(size: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Arrival steps section
          _SectionHeader(icon: Icons.directions_car_outlined, title: 'Exit Procedure'),
          const SizedBox(height: 8),
          _buildCheckTile(
            value: _truckMoved,
            label: 'Truck moves to factory exit gate',
            onChanged: (v) { setState(() => _truckMoved = v ?? false); _onCheckChanged(); },
          ),
          _buildCheckTile(
            value: _securityCheck,
            label: 'Security verifies documents',
            onChanged: (v) { setState(() => _securityCheck = v ?? false); _onCheckChanged(); },
          ),
          const SizedBox(height: 16),

          // Documents checked section
          _SectionHeader(icon: Icons.description_outlined, title: 'Documents Checked'),
          const SizedBox(height: 8),
          _buildCheckTile(
            value: _biltyChecked,
            label: 'Bilty',
            onChanged: (v) { setState(() => _biltyChecked = v ?? false); _onCheckChanged(); },
          ),
          _buildCheckTile(
            value: _weightChecked,
            label: 'Loaded Weight Slip',
            onChanged: (v) { setState(() => _weightChecked = v ?? false); _onCheckChanged(); },
          ),
          _buildCheckTile(
            value: _materialChecked,
            label: 'Material Documents',
            onChanged: (v) { setState(() => _materialChecked = v ?? false); _onCheckChanged(); },
          ),
          const SizedBox(height: 32),

          // Complete button
          if (!_allDone)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please confirm all items above before proceeding',
                      style: _inter(size: 12, color: const Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
            ),
          if (!_allDone) const SizedBox(height: 12),
          if (_lastSaved != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done_outlined, size: 14, color: _success),
                  const SizedBox(width: 4),
                  Text('Last saved: ${_formatSaved(_lastSaved!)}',
                      style: _inter(size: 11, color: _success)),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_allDone && !_submitting) ? _submit : null,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.logout_rounded, size: 18),
              label: Text(_submitting ? 'Saving…' : 'Truck Exits Factory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _border,
                disabledForegroundColor: _secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stage 4 Complete View ────────────────────────────────────────────────────

class _Stage4CompleteView extends ConsumerStatefulWidget {
  final TripModel trip;
  final VoidCallback onDone;
  const _Stage4CompleteView({required this.trip, required this.onDone});

  @override
  ConsumerState<_Stage4CompleteView> createState() => _Stage4CompleteViewState();
}

class _Stage4CompleteViewState extends ConsumerState<_Stage4CompleteView> {
  bool _notifying   = false;
  bool _notified    = false;
  bool _notifyingLP = false;
  bool _notifiedLP  = false;
  bool _completing  = false;
  bool _completed   = false;

  Future<void> _notify() async {
    if (_notifying || _notified) return;
    setState(() => _notifying = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/trips/${widget.trip.id}/notify-stage4');
      if (mounted) {
        setState(() { _notified = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Load owner notified successfully!',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Notification failed: $e',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _notifying = false);
    }
  }

  Future<void> _notifyLP() async {
    if (_notifyingLP || _notifiedLP) return;
    setState(() => _notifyingLP = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/trips/${widget.trip.id}/notify-lp');
      if (mounted) {
        setState(() { _notifiedLP = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('LP team notified successfully!',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Notification failed: $e',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _notifyingLP = false);
    }
  }

  Future<void> _completeTrip() async {
    if (_completing || _completed) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Complete Trip?',
            style: _manrope(size: 17, weight: FontWeight.w700)),
        content: Text(
          'This will mark trip ${widget.trip.tripNumber} as completed and notify the load owner.',
          style: _inter(size: 14, color: _secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: _inter(size: 14, color: _secondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Complete', style: _manrope(size: 14, weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _completing = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/trips/${widget.trip.id}/complete');
      if (mounted) {
        setState(() { _completed = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Trip completed! Load owner has been notified.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to complete trip: $e',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_rounded, color: _primary, size: 56),
          ),
          const SizedBox(height: 24),
          Text('Truck Exits Factory!',
              style: _manrope(size: 22, weight: FontWeight.w800, color: _primary),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(trip.tripNumber,
              style: _manrope(size: 16, weight: FontWeight.w700, color: _secondary)),
          const SizedBox(height: 6),
          Text(
            '${trip.origin} → ${trip.destination}',
            style: _inter(size: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: (_completed ? _primary : _success).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (_completed ? _primary : _success).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _completed ? _primary : _success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(
                  _completed ? 'Trip Completed' : 'Factory Exit Done — Awaiting Completion',
                  style: _manrope(size: 13, weight: FontWeight.w700,
                      color: _completed ? _primary : _success),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'All factory exit procedures have been completed.\nThe truck is now on its way.',
            textAlign: TextAlign.center,
            style: _inter(size: 13, color: _secondary),
          ),
          const SizedBox(height: 28),

          // Summary info row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                _SummaryRow(label: 'Load', value: trip.loadItem),
                if (trip.weight != null) ...[
                  const Divider(height: 16, color: _border),
                  _SummaryRow(label: 'Weight', value: trip.weight!),
                ],
                if (trip.vehiclePlate != null) ...[
                  const Divider(height: 16, color: _border),
                  _SummaryRow(label: 'Vehicle', value: trip.vehiclePlate!),
                ],
                if (trip.driverName != null) ...[
                  const Divider(height: 16, color: _border),
                  _SummaryRow(label: 'Driver', value: trip.driverName!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Notify Load Owner button ──
          if (trip.loadOwnerOrgId != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_notifying || _notified) ? null : _notify,
                icon: _notifying
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_notified ? Icons.check_circle_rounded : Icons.notifications_rounded,
                        size: 18),
                label: Text(_notified
                    ? '${widget.trip.loadOwnerOrgName ?? 'Load Owner'} Notified'
                    : _notifying
                        ? 'Sending…'
                        : 'Notify ${widget.trip.loadOwnerOrgName ?? 'Load Owner'}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _notified ? _success : _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _success.withValues(alpha: 0.7),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Notify LP Team button (LP Worker only) ──
          if (ref.watch(authProvider).user?.isLogisticPartnerWorker == true)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_notifyingLP || _notifiedLP) ? null : _notifyLP,
              icon: _notifyingLP
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_notifiedLP ? Icons.check_circle_rounded : Icons.group_rounded,
                      size: 18),
              label: Text(_notifiedLP
                  ? '${widget.trip.lpOrgName ?? 'LP Team'} Notified'
                  : _notifyingLP
                      ? 'Sending…'
                      : 'Notify ${widget.trip.lpOrgName ?? 'LP Team'}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _notifiedLP ? _success : const Color(0xFF006B5E),
                foregroundColor: Colors.white,
                disabledBackgroundColor: _success.withValues(alpha: 0.7),
                disabledForegroundColor: Colors.white,
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
              onPressed: widget.onDone,
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
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _inter(size: 13, color: _secondary)),
        Flexible(
          child: Text(value,
              style: _manrope(size: 13, weight: FontWeight.w700),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
