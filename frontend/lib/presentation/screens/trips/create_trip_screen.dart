import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/trip_provider.dart';
import 'package:fleet_management/providers/vehicle_provider.dart';
import 'package:fleet_management/providers/driver_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/rr_session_provider.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/presentation/screens/fleet_owner/trip_stages_screen.dart';

// ─── Typography & Colours (mirrors TripStagesScreen palette) ─────────────────
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

const _primary    = Color(0xFFFF6B00);
const _bg         = Color(0xFFF8F9FB);
const _surface    = Color(0xFFFFFFFF);
const _secondary  = Color(0xFF546067);
const _onSurface  = Color(0xFF191C1E);
const _border     = Color(0xFFECEEF0);
const _errorClr   = Color(0xFFBA1A1A);
const _successClr = Color(0xFF006B5E);


// ─── Main Screen ──────────────────────────────────────────────────────────────

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  // ── Pickup city ─────────────────────────────────────────────────────────────
  final _pickupCtrl = TextEditingController();
  String? _pickupCityId;
  List<Map<String, dynamic>> _pickupResults = [];
  bool _pickupLoading = false;
  Timer? _pickupDebounce;

  // ── Drop city ───────────────────────────────────────────────────────────────
  final _dropCtrl = TextEditingController();
  String? _dropCityId;
  List<Map<String, dynamic>> _dropResults = [];
  bool _dropLoading = false;
  Timer? _dropDebounce;

  // ── Material ─────────────────────────────────────────────────────────────────
  final _materialCtrl = TextEditingController();
  String? _materialRrId;
  List<Map<String, dynamic>> _materialResults = [];
  bool _materialLoading = false;
  Timer? _materialDebounce;
  bool _materialFocused = false;

  // ── Cargo ────────────────────────────────────────────────────────────────────
  final _weightCtrl        = TextEditingController();
  String _weightUnit       = 'TONNES';  // RR-native default
  List<String> _quantityUnits    = const ['TONNES', 'KILOGRAMS', 'LITRES', 'BOX', 'CUBIC METERS'];
  List<String> _vehicleBodyTypes = const [];
  String? _vehicleBodyType;
  final _invoiceValueCtrl  = TextEditingController();
  final _freightAmountCtrl = TextEditingController();

  // ── Optional ─────────────────────────────────────────────────────────────────
  final _biltyCtrl          = TextEditingController();
  final _invoiceNumberCtrl  = TextEditingController();

  // ── Assignment ───────────────────────────────────────────────────────────────
  String? _selectedVehicleId;
  String? _selectedDriverId;

  // ── Parties (RR) ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _partners       = [];
  bool _partnersLoading                      = false;

  // Consignor
  Map<String, dynamic>? _consignorPartner;
  List<Map<String, dynamic>> _consignorCompanies = [];
  bool _consignorCompaniesLoading            = false;
  String? _consignorRrCompanyId;
  String? _consignorCompanyName;

  // Consignee
  Map<String, dynamic>? _consigneePartner;
  List<Map<String, dynamic>> _consigneeCompanies = [];
  bool _consigneeCompaniesLoading            = false;
  String? _consigneeRrCompanyId;
  String? _consigneeCompanyName;

  // Ops worker
  List<Map<String, dynamic>> _opsWorkers     = [];
  bool _opsWorkersLoading                    = false;
  String? _selectedOpsWorkerId;      // rr_user_id (dropdown key)
  String? _selectedOpsWorkerLocalId; // local_user_id (UUID) sent to backend
  String? _selectedOpsWorkerName;

  // ── State ────────────────────────────────────────────────────────────────────
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vehicleProvider.notifier).loadVehicles();
      ref.read(driverProvider.notifier).loadDrivers();
      _loadRrPartyData();
    });
  }

  Future<void> _loadRrPartyData() async {
    final dio = ref.read(dioProvider);

    // Enums only need RR4 auth — fire immediately, no RR session required.
    dio.get('/api/rr/enums', queryParameters: {'name': 'QuantityUnit'})
        .then((r) {
          if (!mounted) return;
          final vals = (r.data['values'] as List? ?? []).cast<String>();
          if (vals.isNotEmpty) {
            setState(() {
              _quantityUnits = vals;
              if (!_quantityUnits.contains(_weightUnit)) _weightUnit = _quantityUnits.first;
            });
          }
        }).catchError((_) {});
    dio.get('/api/rr/enums', queryParameters: {'name': 'VehicleBodyTypes'})
        .then((r) {
          if (!mounted) return;
          setState(() {
            _vehicleBodyTypes = (r.data['values'] as List? ?? []).cast<String>();
          });
        }).catchError((_) {});

    // Partners and workers require an RR token — ask for login if no valid session.
    final session = await ensureRrSession(context, ref);
    if (session == null) {
      if (mounted) setState(() { _partnersLoading = false; _opsWorkersLoading = false; });
      return;
    }
    final token = session.token;
    setState(() { _partnersLoading = true; _opsWorkersLoading = true; });
    await Future.wait([
      dio.get('/api/rr/preferred-partners', queryParameters: {'rr_token': token})
          .then((r) {
            if (mounted) setState(() {
              _partners = (r.data['partners'] as List? ?? []).cast<Map<String, dynamic>>();
              _partnersLoading = false;
            });
          }).catchError((_) { if (mounted) setState(() => _partnersLoading = false); }),
      dio.get('/api/rr/company-workers', queryParameters: {'rr_token': token})
          .then((r) {
            if (mounted) setState(() {
              _opsWorkers = (r.data['workers'] as List? ?? []).cast<Map<String, dynamic>>();
              _opsWorkersLoading = false;
            });
          }).catchError((_) { if (mounted) setState(() => _opsWorkersLoading = false); }),
    ]);
  }

  Future<void> _loadPartnerCompanies(Map<String, dynamic> partner, {required bool isConsignor}) async {
    final rrUserId = partner['rr_user_id'] as String?;
    if (rrUserId == null) {
      // company-type partner — the company is directly on the partner record
      final companyId = partner['rr_company_id'] as String?;
      final companyName = partner['name'] as String? ?? '';
      if (isConsignor) {
        setState(() {
          _consignorRrCompanyId = companyId;
          _consignorCompanyName = companyName;
          _consignorCompanies   = [];
        });
      } else {
        setState(() {
          _consigneeRrCompanyId = companyId;
          _consigneeCompanyName = companyName;
          _consigneeCompanies   = [];
        });
      }
      return;
    }
    if (isConsignor) setState(() => _consignorCompaniesLoading = true);
    else             setState(() => _consigneeCompaniesLoading = true);
    try {
      final session = ref.read(rrSessionProvider);
      final token = (session != null && session.isValid) ? session.token : '';
      final resp = await ref.read(dioProvider).get(
        '/api/rr/partner-companies',
        queryParameters: {'user_id': rrUserId, 'rr_token': token},
      );
      final companies = (resp.data['companies'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      if (isConsignor) setState(() { _consignorCompanies = companies; _consignorCompaniesLoading = false; });
      else             setState(() { _consigneeCompanies = companies; _consigneeCompaniesLoading = false; });
    } catch (_) {
      if (!mounted) return;
      if (isConsignor) setState(() => _consignorCompaniesLoading = false);
      else             setState(() => _consigneeCompaniesLoading = false);
    }
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _materialCtrl.dispose();
    _weightCtrl.dispose();
    _invoiceValueCtrl.dispose();
    _freightAmountCtrl.dispose();
    _biltyCtrl.dispose();
    _invoiceNumberCtrl.dispose();
    _pickupDebounce?.cancel();
    _dropDebounce?.cancel();
    _materialDebounce?.cancel();
    super.dispose();
  }

  // ── City search helpers ───────────────────────────────────────────────────────

  void _onPickupTyped(String q) {
    setState(() { _pickupCityId = null; _pickupResults = []; });
    _pickupDebounce?.cancel();
    if (q.length < 2) return;
    _pickupDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchCity(q, isPickup: true),
    );
  }

  void _onDropTyped(String q) {
    setState(() { _dropCityId = null; _dropResults = []; });
    _dropDebounce?.cancel();
    if (q.length < 2) return;
    _dropDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _searchCity(q, isPickup: false),
    );
  }

  Future<void> _searchCity(String q, {required bool isPickup}) async {
    if (isPickup) setState(() => _pickupLoading = true);
    else          setState(() => _dropLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/api/rr/cities', queryParameters: {'q': q});
      final items = (resp.data['items'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        if (isPickup) { _pickupResults = items; _pickupLoading = false; }
        else          { _dropResults   = items; _dropLoading   = false; }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (isPickup) _pickupLoading = false;
        else          _dropLoading   = false;
      });
    }
  }

  void _selectPickup(Map<String, dynamic> city) => setState(() {
    _pickupCityId   = city['rr_city_id'] as String;
    _pickupCtrl.text = city['name'] as String;
    _pickupResults  = [];
  });

  void _selectDrop(Map<String, dynamic> city) => setState(() {
    _dropCityId    = city['rr_city_id'] as String;
    _dropCtrl.text  = city['name'] as String;
    _dropResults   = [];
  });

  // ── Material search helpers ───────────────────────────────────────────────────

  void _onMaterialTyped(String q) {
    setState(() { _materialRrId = null; _materialResults = []; });
    _materialDebounce?.cancel();
    _materialDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _searchMaterial(q),
    );
  }

  Future<void> _searchMaterial(String q) async {
    setState(() => _materialLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/api/rr/materials', queryParameters: {'q': q});
      final items = (resp.data['items'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() { _materialResults = items; _materialLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _materialLoading = false);
    }
  }

  void _selectMaterial(Map<String, dynamic> mat) => setState(() {
    _materialRrId    = mat['rr_material_id'] as String?;
    _materialCtrl.text = mat['name'] as String;
    _materialResults = [];
    _materialFocused = false;
  });

  // ── Submit ────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_submitting) return;

    // Validation
    if (_pickupCityId == null) {
      setState(() => _submitError = 'Select a pickup city from the dropdown');
      return;
    }
    if (_dropCityId == null) {
      setState(() => _submitError = 'Select a drop city from the dropdown');
      return;
    }
    if (_materialRrId == null) {
      setState(() => _submitError = 'Select a material from the dropdown');
      return;
    }
    final weightStr = _weightCtrl.text.trim();
    if (weightStr.isEmpty || double.tryParse(weightStr) == null) {
      setState(() => _submitError = 'Enter a valid weight');
      return;
    }

    setState(() { _submitting = true; _submitError = null; });

    final body = <String, dynamic>{
      'origin':                  _pickupCtrl.text.trim(),
      'destination':             _dropCtrl.text.trim(),
      'load_item':               _materialCtrl.text.trim(),
      'origin_rr_city_id':       _pickupCityId,
      'destination_rr_city_id':  _dropCityId,
      'material_rr_id':          _materialRrId,
      'weight_value':            double.parse(weightStr),
      'weight_unit':             _weightUnit,
      'weight':                  '$weightStr $_weightUnit',
    };

    final invoiceVal = double.tryParse(_invoiceValueCtrl.text.trim());
    if (invoiceVal != null) body['invoice_value'] = invoiceVal;

    final freight = double.tryParse(_freightAmountCtrl.text.trim());
    if (freight != null) body['trip_amount'] = freight;

    final bilty = _biltyCtrl.text.trim();
    if (bilty.isNotEmpty) body['bilty_number'] = bilty;

    final invoiceNum = _invoiceNumberCtrl.text.trim();
    if (invoiceNum.isNotEmpty) body['invoice_number'] = invoiceNum;

    if (_vehicleBodyType          != null) body['vehicle_body_type']      = _vehicleBodyType;
    if (_selectedVehicleId        != null) body['vehicle_id']             = _selectedVehicleId;
    if (_selectedDriverId         != null) body['driver_id']              = _selectedDriverId;
    if (_consignorRrCompanyId     != null) body['consignor_rr_company_id'] = _consignorRrCompanyId;
    if (_consigneeRrCompanyId     != null) body['consignee_rr_company_id'] = _consigneeRrCompanyId;
    if (_selectedOpsWorkerLocalId != null) body['rr_ops_user_id']          = _selectedOpsWorkerLocalId;

    // Ensure valid RR session just before submit — token may have expired while form was being filled
    final rrSession = await ensureRrSession(context, ref);
    if (rrSession != null && rrSession.isValid) {
      body['rr_token'] = rrSession.token;
    }
    // If session null/cancelled we still create the trip locally; RR sync skipped

    if (!mounted) return;

    final trip = await ref.read(tripProvider.notifier).createTrip(body);

    if (!mounted) return;

    if (trip == null) {
      setState(() {
        _submitting  = false;
        _submitError = ref.read(tripProvider).error ?? 'Failed to create trip';
      });
      return;
    }

    // Capture messenger before navigation (context becomes invalid after pushReplacement)
    final messenger = ScaffoldMessenger.of(context);
    final rrNum = trip.rrTripNumber;
    final syncStatus = trip.rrSyncStatus;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TripStagesScreen(trip: trip)),
    );

    if (rrNum != null && rrNum.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Synced to RR web — Trip $rrNum'),
          backgroundColor: _successClr,
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (syncStatus == 'failed') {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Trip created locally. RR sync failed: ${trip.rrSyncError ?? 'unknown error'}'),
          backgroundColor: _errorClr,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleProvider).vehicles;
    final drivers  = ref.watch(driverProvider).drivers;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _onSurface, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Create Trip', style: _manrope(size: 16, weight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          children: [

            // ── Route ──────────────────────────────────────────────────────
            _SectionHeader(label: 'Route'),
            const SizedBox(height: 12),

            _FieldLabel(label: 'Pickup City'),
            const SizedBox(height: 6),
            _SearchField(
              controller: _pickupCtrl,
              hint: 'Search city…',
              loading: _pickupLoading,
              confirmed: _pickupCityId != null,
              onChanged: _onPickupTyped,
              onClear: () => setState(() {
                _pickupCityId = null;
                _pickupCtrl.clear();
                _pickupResults = [];
              }),
            ),
            if (_pickupResults.isNotEmpty)
              _ResultsCard(
                items: _pickupResults,
                labelKey: 'name',
                onSelect: _selectPickup,
              ),

            const SizedBox(height: 12),

            _FieldLabel(label: 'Drop City'),
            const SizedBox(height: 6),
            _SearchField(
              controller: _dropCtrl,
              hint: 'Search city…',
              loading: _dropLoading,
              confirmed: _dropCityId != null,
              onChanged: _onDropTyped,
              onClear: () => setState(() {
                _dropCityId = null;
                _dropCtrl.clear();
                _dropResults = [];
              }),
            ),
            if (_dropResults.isNotEmpty)
              _ResultsCard(
                items: _dropResults,
                labelKey: 'name',
                onSelect: _selectDrop,
              ),

            // ── Cargo ───────────────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Cargo'),
            const SizedBox(height: 12),

            _FieldLabel(label: 'Material'),
            const SizedBox(height: 6),
            Focus(
              onFocusChange: (focused) {
                if (focused && _materialCtrl.text.isEmpty) _searchMaterial('');
                if (!focused) {
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (mounted) setState(() => _materialFocused = false);
                  });
                } else {
                  setState(() => _materialFocused = true);
                }
              },
              child: _SearchField(
                controller: _materialCtrl,
                hint: 'Search material…',
                loading: _materialLoading,
                confirmed: _materialRrId != null,
                onChanged: _onMaterialTyped,
                onClear: () => setState(() {
                  _materialRrId = null;
                  _materialCtrl.clear();
                  _materialResults = [];
                }),
              ),
            ),
            if (_materialResults.isNotEmpty)
              _ResultsCard(
                items: _materialResults,
                labelKey: 'name',
                onSelect: _selectMaterial,
              ),

            const SizedBox(height: 12),

            _FieldLabel(label: 'Weight'),
            const SizedBox(height: 6),
            _WeightRow(
              controller: _weightCtrl,
              unit: _quantityUnits.contains(_weightUnit) ? _weightUnit : _quantityUnits.first,
              units: _quantityUnits,
              onUnitChanged: (u) => setState(() => _weightUnit = u),
            ),

            const SizedBox(height: 12),
            _FieldLabel(label: 'Vehicle Body Type'),
            const SizedBox(height: 6),
            _vehicleBodyTypes.isEmpty
                ? const _LoadingChip(label: 'Loading body types…')
                : _DropdownField<String>(
                    value: _vehicleBodyType,
                    hint: 'Select vehicle body type',
                    items: _vehicleBodyTypes.map((t) => DropdownMenuItem<String>(
                      value: t,
                      child: Text(t, style: _inter(size: 13, color: _onSurface)),
                    )).toList(),
                    onChanged: (v) => setState(() => _vehicleBodyType = v),
                  ),

            const SizedBox(height: 12),
            _FieldLabel(label: 'Invoice Value (₹)'),
            const SizedBox(height: 6),
            _TextInput(
              controller: _invoiceValueCtrl,
              hint: 'e.g. 150000',
              inputType: TextInputType.number,
            ),

            // ── Parties (RR) ────────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Parties'),
            const SizedBox(height: 12),

            // ── Consignor ────────────────────────────────────────────────────
            _FieldLabel(label: 'Consignor Partner (optional)'),
            const SizedBox(height: 6),
            _partnersLoading
                ? const _LoadingChip(label: 'Loading partners…')
                : _DropdownField<String>(
                    value: _consignorPartner?['partner_id'] as String?,
                    hint: 'Select partner to auto-fill',
                    items: _partners.map((p) => DropdownMenuItem<String>(
                      value: p['partner_id'] as String?,
                      child: Text(p['name'] as String? ?? '—',
                          style: _inter(size: 13, color: _onSurface),
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) {
                      final p = _partners.firstWhere((x) => x['partner_id'] == v, orElse: () => {});
                      if (p.isEmpty) return;
                      setState(() {
                        _consignorPartner      = p;
                        _consignorRrCompanyId  = null;
                        _consignorCompanyName  = null;
                        _consignorCompanies    = [];
                      });
                      _loadPartnerCompanies(p, isConsignor: true);
                    },
                  ),
            const SizedBox(height: 10),
            _FieldLabel(label: 'Consignor Company'),
            const SizedBox(height: 6),
            _consignorCompaniesLoading
                ? const _LoadingChip(label: 'Loading companies…')
                : _consignorCompanies.isEmpty && _consignorRrCompanyId != null
                    ? _SelectedChip(label: _consignorCompanyName ?? '', onClear: () => setState(() {
                        _consignorRrCompanyId = null; _consignorCompanyName = null;
                      }))
                    : _DropdownField<String>(
                        value: _consignorRrCompanyId,
                        hint: _consignorPartner == null
                            ? 'Select a partner above first'
                            : 'Select consignor company',
                        items: _consignorCompanies.map((c) => DropdownMenuItem<String>(
                          value: c['rr_company_id'] as String,
                          child: Text(c['name'] as String? ?? '—',
                              style: _inter(size: 13, color: _onSurface),
                              overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _consignorPartner == null ? null : (v) {
                          final c = _consignorCompanies.firstWhere((x) => x['rr_company_id'] == v);
                          setState(() {
                            _consignorRrCompanyId = v;
                            _consignorCompanyName = c['name'] as String?;
                          });
                        },
                      ),

            const SizedBox(height: 16),

            // ── Consignee ────────────────────────────────────────────────────
            _FieldLabel(label: 'Consignee Partner (optional)'),
            const SizedBox(height: 6),
            _partnersLoading
                ? const _LoadingChip(label: 'Loading partners…')
                : _DropdownField<String>(
                    value: _consigneePartner?['partner_id'] as String?,
                    hint: 'Select partner to auto-fill',
                    items: _partners.map((p) => DropdownMenuItem<String>(
                      value: p['partner_id'] as String?,
                      child: Text(p['name'] as String? ?? '—',
                          style: _inter(size: 13, color: _onSurface),
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) {
                      final p = _partners.firstWhere((x) => x['partner_id'] == v, orElse: () => {});
                      if (p.isEmpty) return;
                      setState(() {
                        _consigneePartner      = p;
                        _consigneeRrCompanyId  = null;
                        _consigneeCompanyName  = null;
                        _consigneeCompanies    = [];
                      });
                      _loadPartnerCompanies(p, isConsignor: false);
                    },
                  ),
            const SizedBox(height: 10),
            _FieldLabel(label: 'Consignee Company'),
            const SizedBox(height: 6),
            _consigneeCompaniesLoading
                ? const _LoadingChip(label: 'Loading companies…')
                : _consigneeCompanies.isEmpty && _consigneeRrCompanyId != null
                    ? _SelectedChip(label: _consigneeCompanyName ?? '', onClear: () => setState(() {
                        _consigneeRrCompanyId = null; _consigneeCompanyName = null;
                      }))
                    : _DropdownField<String>(
                        value: _consigneeRrCompanyId,
                        hint: _consigneePartner == null
                            ? 'Select a partner above first'
                            : 'Select consignee company',
                        items: _consigneeCompanies.map((c) => DropdownMenuItem<String>(
                          value: c['rr_company_id'] as String,
                          child: Text(c['name'] as String? ?? '—',
                              style: _inter(size: 13, color: _onSurface),
                              overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _consigneePartner == null ? null : (v) {
                          final c = _consigneeCompanies.firstWhere((x) => x['rr_company_id'] == v);
                          setState(() {
                            _consigneeRrCompanyId = v;
                            _consigneeCompanyName = c['name'] as String?;
                          });
                        },
                      ),

            const SizedBox(height: 12),

            // RR Ops Worker
            _FieldLabel(label: 'RR Ops Worker'),
            const SizedBox(height: 6),
            _opsWorkersLoading
                ? const _LoadingChip(label: 'Loading workers…')
                : _DropdownField<String>(
                    value: _selectedOpsWorkerId,
                    hint: 'Select handled by',
                    items: _opsWorkers.map((w) => DropdownMenuItem<String>(
                      value: w['rr_user_id'] as String,
                      child: Text(
                        '${w['name'] ?? '—'}${(w['position'] as String?)?.isNotEmpty == true ? '  •  ${w['position']}' : ''}',
                        style: _inter(size: 13, color: _onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (v) {
                      final w = _opsWorkers.firstWhere((x) => x['rr_user_id'] == v, orElse: () => {});
                      setState(() {
                        _selectedOpsWorkerId      = v;
                        _selectedOpsWorkerLocalId = w['local_user_id'] as String?;
                        _selectedOpsWorkerName    = w['name'] as String?;
                      });
                    },
                  ),

            // ── Assignment ──────────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Assignment'),
            const SizedBox(height: 12),

            _FieldLabel(label: 'Vehicle'),
            const SizedBox(height: 6),
            _DropdownField<String>(
              value: _selectedVehicleId,
              hint: 'Select vehicle',
              items: vehicles
                  .map((v) => DropdownMenuItem<String>(
                        value: v['id'] as String?,
                        child: Text(
                          '${v['registration_number'] ?? v['vehicle_number'] ?? ''}  •  ${v['make'] ?? ''} ${v['model'] ?? ''}',
                          style: _inter(size: 13, color: _onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedVehicleId = v),
            ),

            const SizedBox(height: 12),
            _FieldLabel(label: 'Driver'),
            const SizedBox(height: 6),
            _DropdownField<String>(
              value: _selectedDriverId,
              hint: 'Select driver',
              items: drivers
                  .map((d) => DropdownMenuItem(
                        value: d.driverId,
                        child: Text(
                          '${d.fullName}  •  ${d.phone}',
                          style: _inter(size: 13, color: _onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDriverId = v),
            ),

            const SizedBox(height: 12),
            _FieldLabel(label: 'Freight Amount (₹)'),
            const SizedBox(height: 6),
            _TextInput(
              controller: _freightAmountCtrl,
              hint: 'Trip freight amount',
              inputType: TextInputType.number,
            ),

            // ── Optional ────────────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Optional'),
            const SizedBox(height: 12),

            _FieldLabel(label: 'Bilty Number'),
            const SizedBox(height: 6),
            _TextInput(controller: _biltyCtrl, hint: 'Consignment note number'),

            const SizedBox(height: 12),
            _FieldLabel(label: 'Invoice Number'),
            const SizedBox(height: 6),
            _TextInput(controller: _invoiceNumberCtrl, hint: 'Invoice / GR number'),

            // ── Error ────────────────────────────────────────────────────────
            if (_submitError != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _errorClr.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: _errorClr, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_submitError!, style: _inter(size: 13, color: _errorClr))),
                  ],
                ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: _BottomBar(submitting: _submitting, onSubmit: _submit),
      ),
    );
  }
}


// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(width: 3, height: 16,
              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label, style: _manrope(size: 14, weight: FontWeight.w800, color: _onSurface)),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) =>
      Text(label, style: _inter(size: 12, weight: FontWeight.w500, color: _secondary));
}

// ── City / Material search field ──────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool loading;
  final bool confirmed;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.loading,
    required this.confirmed,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: confirmed ? _successClr.withOpacity(0.6) : _border,
          width: confirmed ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            confirmed ? Icons.check_circle_rounded : Icons.search_rounded,
            size: 18,
            color: confirmed ? _successClr : _secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: _inter(size: 13, color: _onSurface),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: _inter(size: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
              ),
            )
          else if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: _secondary),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }
}

// ── Results dropdown card ─────────────────────────────────────────────────────

class _ResultsCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String labelKey;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _ResultsCard({
    required this.items,
    required this.labelKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
          itemBuilder: (_, i) {
            final item = items[i];
            return InkWell(
              onTap: () => onSelect(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Text(
                  item[labelKey] as String? ?? '',
                  style: _inter(size: 13, color: _onSurface),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Weight row ────────────────────────────────────────────────────────────────

class _WeightRow extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final List<String> units;
  final ValueChanged<String> onUnitChanged;

  const _WeightRow({
    required this.controller,
    required this.unit,
    required this.units,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TextInput(
            controller: controller,
            hint: 'e.g. 20',
            inputType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: unit,
              style: _inter(size: 13, color: _onSurface),
              icon: const Icon(Icons.expand_more_rounded, size: 18, color: _secondary),
              items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) { if (v != null) onUnitChanged(v); },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Generic text input ────────────────────────────────────────────────────────

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType inputType;

  const _TextInput({
    required this.controller,
    required this.hint,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        style: _inter(size: 13, color: _onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: _inter(size: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          isDense: true,
        ),
      ),
    );
  }
}

// ── Generic dropdown ──────────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;   // nullable → null disables the dropdown

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Container(
      decoration: BoxDecoration(
        color: disabled ? const Color(0xFFF2F4F6) : _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: _inter(size: 13, color: disabled ? _secondary : _secondary)),
          isExpanded: true,
          style: _inter(size: 13, color: _onSurface),
          icon: Icon(Icons.expand_more_rounded, size: 18,
              color: disabled ? _border : _secondary),
          items: disabled ? null : items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Bottom submit bar ─────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool submitting;
  final VoidCallback onSubmit;
  const _BottomBar({required this.submitting, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: submitting ? null : onSubmit,
          child: submitting
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Create Trip',
                  style: _manrope(size: 15, weight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

// ─── Loading chip ─────────────────────────────────────────────────────────────

class _LoadingChip extends StatelessWidget {
  final String label;
  const _LoadingChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F4F6),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFECEEF0)),
    ),
    child: Row(children: [
      const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: _primary)),
      const SizedBox(width: 10),
      Text(label, style: _inter(size: 13)),
    ]),
  );
}

// ─── Selected chip (company-type partner — no dropdown needed) ────────────────

class _SelectedChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  const _SelectedChip({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _successClr.withOpacity(0.4)),
    ),
    child: Row(children: [
      const Icon(Icons.business_rounded, size: 16, color: _successClr),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: _inter(size: 13, weight: FontWeight.w600, color: _successClr))),
      GestureDetector(onTap: onClear, child: const Icon(Icons.close, size: 16, color: _successClr)),
    ]),
  );
}
