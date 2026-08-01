import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/trip_provider.dart' show tripProvider, pendingRrTripNumberProvider, pendingCreatedTripIdProvider;
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/rr_session_provider.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/presentation/widgets/rr_search_field.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/rr_quick_add/add_rr_user_screen.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';
import 'package:fleet_management/providers/settings_provider.dart' show sharedPreferencesProvider;
import 'package:fleet_management/data/models/last_trip_data.dart';
import 'dart:convert';

// ─── Typography & Colours ─────────────────────────────────────────────────────
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
const _divider    = Color(0xFFECEEF0);


// ─── Main Screen ──────────────────────────────────────────────────────────────

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {

  // ── City search ───────────────────────────────────────────────────────────
  final _pickupCtrl       = TextEditingController();
  String? _pickupCityId;
  List<Map<String, dynamic>> _pickupResults = [];
  bool _pickupLoading     = false;
  Timer? _pickupDebounce;

  final _dropCtrl         = TextEditingController();
  String? _dropCityId;
  List<Map<String, dynamic>> _dropResults = [];
  bool _dropLoading       = false;
  Timer? _dropDebounce;

  // ── Material search ───────────────────────────────────────────────────────
  final _materialCtrl     = TextEditingController();
  String? _materialRrId;
  List<Map<String, dynamic>> _materialResults = [];
  bool _materialLoading   = false;
  Timer? _materialDebounce;

  // ── Enums ─────────────────────────────────────────────────────────────────
  List<String> _quantityUnits    = const ['TONNES', 'KILOGRAMS', 'LITRES', 'BOX', 'CUBIC METERS'];
  List<String> _vehicleBodyTypes = const [];
  String _weightUnit             = 'KILOGRAMS';

  // ── Partners (shared list for both consignor + consignee) ────────────────
  List<Map<String, dynamic>> _partners = [];
  bool _partnersLoading               = false;

  // ── Consignor Info ────────────────────────────────────────────────────────
  Map<String, dynamic>? _consignorPartner;
  String? _consignorPhone;
  List<Map<String, dynamic>> _consignorAddresses  = [];
  List<Map<String, dynamic>> _consignorCompanies  = [];
  bool _consignorCompaniesLoading                 = false;
  String? _consignorRrCompanyId;
  String? _consignorCompanyName;
  final _consignorNameCtrl  = TextEditingController();
  final _consignorGstinCtrl = TextEditingController();

  // ── Consignee Info ────────────────────────────────────────────────────────
  Map<String, dynamic>? _consigneePartner;
  String? _consigneePhone;
  List<Map<String, dynamic>> _consigneeAddresses  = [];
  List<Map<String, dynamic>> _consigneeCompanies  = [];
  bool _consigneeCompaniesLoading                 = false;
  String? _consigneeRrCompanyId;
  String? _consigneeCompanyName;
  final _consigneeNameCtrl  = TextEditingController();
  final _consigneeGstinCtrl = TextEditingController();

  // ── Pickup Location ───────────────────────────────────────────────────────
  final _pickupLine1Ctrl = TextEditingController();
  final _pickupLine2Ctrl = TextEditingController();
  final _pickupPinCtrl   = TextEditingController();
  bool  _pickupNoEntryZone = false;

  // ── Unload Location ───────────────────────────────────────────────────────
  final _unloadLine1Ctrl = TextEditingController();
  final _unloadLine2Ctrl = TextEditingController();
  final _unloadPinCtrl   = TextEditingController();
  final _depotCodeCtrl   = TextEditingController();
  bool  _unloadNoEntryZone = false;

  // ── Parcel / Load Info ────────────────────────────────────────────────────
  final _weightCtrl       = TextEditingController();
  final _invoiceValueCtrl = TextEditingController();
  final _parcelDescCtrl   = TextEditingController();
  bool  _partLoad         = false;

  // ── Vehicle Info ──────────────────────────────────────────────────────────
  String? _vehicleBodyType;
  String? _axleType;
  int?    _numberOfWheels;
  final _expectedFreightCtrl  = TextEditingController();
  final _bookingAmountCtrl    = TextEditingController();

  // ── Vehicle provider (transporter) multi-step picker ─────────────────────
  final _vpPhoneCtrl              = TextEditingController();
  bool   _vpLookingUp             = false;
  String? _vpLookupError;
  Map<String, dynamic>? _vpFoundUser;     // found but not yet selected: {user_id, name}
  Map<String, dynamic>? _vpUser;          // selected user
  List<Map<String, dynamic>> _vpPersonalVehicles = [];  // user's own vehicles (no company)
  List<Map<String, dynamic>> _vpCompanies = [];
  bool   _vpCompaniesLoading      = false;
  String? _vpSelectedCompanyId;           // → transporter_rr_company_id
  String? _vpSelectedCompanyName;
  List<Map<String, dynamic>> _vpVehicles  = [];  // company vehicles (fleet + market)
  bool   _vpVehiclesLoading       = false;
  String? _vpSelectedVehicleRrId;         // → rr_vehicle_id
  String? _vpSelectedVehicleNumber;       // → vehicle_number (display)
  // Driver is intentionally NOT derived from the vehicle's RR crew — it's a
  // fully independent field below (mirrors rr_kanpur's separate Vehicle/
  // Driver fields). RR's own /create_trip endpoint pairs vehicle+driver
  // together automatically as a side effect of creating the trip, so
  // requiring the vehicle to already have crew set was an unnecessary,
  // self-imposed block RR4 had added on top of RR's real behavior.

  // ── Driver (independent of vehicle) ───────────────────────────────────────
  final _driverPhoneCtrl = TextEditingController();
  String? _selectedDriverRrId;
  String? _selectedDriverName;
  bool _vehicleHasNoDriver = false;
  bool _assigningDriverToVehicle = false;

  static const _axleTypes    = ['Single', 'Double', 'Triple', 'Multiple'];
  static const _wheelOptions = [4, 6, 8, 10, 12, 14, 16, 18, 22];

  // ── Ops worker (Trip Handled By) ──────────────────────────────────────────
  List<Map<String, dynamic>> _opsWorkers     = [];
  bool _opsWorkersLoading                    = false;
  String? _selectedOpsWorkerId;
  String? _selectedOpsWorkerLocalId;

  // ── Field error tracking ──────────────────────────────────────────────────
  final Map<String, bool>   _fieldErr    = {};
  final Map<String, String> _fieldErrMsg = {};

  // ── Scroll-to anchors (one GlobalKey per mandatory field) ─────────────────
  final _keyConsignorCompany = GlobalKey();
  final _keyPickupCity       = GlobalKey();
  final _keyUnloadCity       = GlobalKey();
  final _keyMaterial         = GlobalKey();
  final _keyWeight           = GlobalKey();
  final _keyInvoiceValue     = GlobalKey();
  final _keyExpectedFreight  = GlobalKey();
  final _keyOpsWorker        = GlobalKey();
  final _keyVpPhone          = GlobalKey();
  final _keyVpCompany        = GlobalKey();
  final _keyVehicle          = GlobalKey();
  final _keyDriver           = GlobalKey();
  final _keyBookingAmount    = GlobalKey();

  // ── Per-step scroll controllers ───────────────────────────────────────────
  final _scrollCtrl0 = ScrollController();
  final _scrollCtrl1 = ScrollController();
  final _scrollCtrl2 = ScrollController();

  // ── Step state ────────────────────────────────────────────────────────────
  int _currentStep  = 0;   // 0 = Trip Info  |  1 = Vehicle  |  2 = Bidding

  // ── Submit state ──────────────────────────────────────────────────────────
  bool _submitting  = false;
  String? _submitError;

  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Listener must be registered BEFORE _loadLastTripData() runs — it sets
    // _vpPhoneCtrl.text from the cache, and that assignment is what's
    // supposed to auto-trigger the live VP lookup via _onVpPhoneChanged.
    _vpPhoneCtrl.addListener(_onVpPhoneChanged);
    _weightCtrl.addListener(() => _clearFieldErr('weight'));
    _invoiceValueCtrl.addListener(() => _clearFieldErr('invoiceValue'));
    _expectedFreightCtrl.addListener(() => _clearFieldErr('expectedFreight'));
    _bookingAmountCtrl.addListener(() => _clearFieldErr('bookingAmount'));
    // Deferred to after the first frame — the phone prefill below can
    // trigger a live lookup that shows the RR login dialog, and doing that
    // before the widget is mounted (still inside initState) is unsafe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastTripData();
      _loadRrPartyData();
    });
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    _materialCtrl.dispose();
    _weightCtrl.dispose();
    _invoiceValueCtrl.dispose();
    _parcelDescCtrl.dispose();
    _consignorNameCtrl.dispose();
    _consignorGstinCtrl.dispose();
    _consigneeNameCtrl.dispose();
    _consigneeGstinCtrl.dispose();
    _pickupLine1Ctrl.dispose();
    _pickupLine2Ctrl.dispose();
    _pickupPinCtrl.dispose();
    _unloadLine1Ctrl.dispose();
    _unloadLine2Ctrl.dispose();
    _unloadPinCtrl.dispose();
    _depotCodeCtrl.dispose();
    _expectedFreightCtrl.dispose();
    _bookingAmountCtrl.dispose();
    _vpPhoneCtrl.removeListener(_onVpPhoneChanged);
    _vpPhoneCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _scrollCtrl0.dispose();
    _scrollCtrl1.dispose();
    _scrollCtrl2.dispose();
    _pickupDebounce?.cancel();
    _dropDebounce?.cancel();
    _materialDebounce?.cancel();
    super.dispose();
  }

  // ── Remember last trip's values (rr_kanpur-style convenience prefill) ─────
  // Pure prefill cache, not a resumable draft — no trip id is stored, and
  // submitting from prefilled values always creates a brand-new trip, same
  // as rr_kanpur's own SharedPref.saveLastTripData()/getLastTripData().
  static const _lastTripDataKey = 'last_trip_data';

  void _loadLastTripData() {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_lastTripDataKey);
    if (raw == null) return;
    try {
      final data = LastTripData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      setState(() {
        _consignorNameCtrl.text  = data.consignorName ?? '';
        _consignorRrCompanyId    = data.consignorRrCompanyId;
        _consignorGstinCtrl.text = data.consignorGstin ?? '';
        _consigneeNameCtrl.text  = data.consigneeName ?? '';
        _consigneeRrCompanyId    = data.consigneeRrCompanyId;
        _consigneeGstinCtrl.text = data.consigneeGstin ?? '';
        _pickupCtrl.text         = data.pickupCityName ?? '';
        _pickupCityId            = data.pickupCityId;
        _dropCtrl.text           = data.dropCityName ?? '';
        _dropCityId              = data.dropCityId;
        _materialCtrl.text       = data.materialName ?? '';
        _materialRrId            = data.materialRrId;
        _weightCtrl.text         = data.weight ?? '';
        _invoiceValueCtrl.text   = data.invoiceValue ?? '';
        _pickupLine1Ctrl.text    = data.pickupLine1 ?? '';
        _pickupLine2Ctrl.text    = data.pickupLine2 ?? '';
        _pickupPinCtrl.text      = data.pickupPin ?? '';
        _unloadLine1Ctrl.text    = data.unloadLine1 ?? '';
        _unloadLine2Ctrl.text    = data.unloadLine2 ?? '';
        _unloadPinCtrl.text      = data.unloadPin ?? '';
        _depotCodeCtrl.text      = data.depotCode ?? '';
        _vehicleBodyType         = data.vehicleBodyType;
        _axleType                = data.axleType;
        _numberOfWheels          = data.numberOfWheels;
        // Vehicle provider phone is restored as text only (not the resolved
        // company/vehicle IDs) — typing it re-triggers the live phone lookup
        // via _onVpPhoneChanged, which is the only safe way to repopulate
        // _vpUser/_vpCompanies/_vpVehicles. Prefilling the IDs directly would
        // be dead at best (that section only renders once _vpUser is set via
        // a live lookup, which isn't restored) and a DropdownButton
        // assertion crash at worst if a stale ID doesn't match a freshly
        // loaded list — unlike rr_kanpur's free-text vehicle field, RR4's
        // vehicle/company pickers are native DropdownButtons that require an
        // exact value/items match.
        _vpPhoneCtrl.text        = data.vpPhone ?? '';
        _selectedDriverRrId      = data.driverId;
        _selectedDriverName      = data.driverName;
        if (data.driverName != null && data.driverId != null) {
          _driverPhoneCtrl.text = data.driverName!;
        }
        _expectedFreightCtrl.text = data.expectedFreight ?? '';
        _bookingAmountCtrl.text   = data.bookingAmount ?? '';
        _selectedOpsWorkerLocalId = data.opsWorkerLocalId;
      });
    } catch (_) {
      // Corrupt/old-shape cache — ignore and start blank rather than crash.
    }
  }

  Future<void> _saveLastTripData() async {
    final data = LastTripData(
      consignorName: _consignorNameCtrl.text.trim(),
      consignorRrCompanyId: _consignorRrCompanyId,
      consignorGstin: _consignorGstinCtrl.text.trim(),
      consigneeName: _consigneeNameCtrl.text.trim(),
      consigneeRrCompanyId: _consigneeRrCompanyId,
      consigneeGstin: _consigneeGstinCtrl.text.trim(),
      pickupCityName: _pickupCtrl.text.trim(),
      pickupCityId: _pickupCityId,
      dropCityName: _dropCtrl.text.trim(),
      dropCityId: _dropCityId,
      materialName: _materialCtrl.text.trim(),
      materialRrId: _materialRrId,
      weight: _weightCtrl.text.trim(),
      invoiceValue: _invoiceValueCtrl.text.trim(),
      pickupLine1: _pickupLine1Ctrl.text.trim(),
      pickupLine2: _pickupLine2Ctrl.text.trim(),
      pickupPin: _pickupPinCtrl.text.trim(),
      unloadLine1: _unloadLine1Ctrl.text.trim(),
      unloadLine2: _unloadLine2Ctrl.text.trim(),
      unloadPin: _unloadPinCtrl.text.trim(),
      depotCode: _depotCodeCtrl.text.trim(),
      vehicleBodyType: _vehicleBodyType,
      axleType: _axleType,
      numberOfWheels: _numberOfWheels,
      vpPhone: _vpPhoneCtrl.text.trim(),
      vpCompanyId: _vpSelectedCompanyId,
      vpCompanyName: _vpSelectedCompanyName,
      vehicleId: _vpSelectedVehicleRrId,
      vehicleNumber: _vpSelectedVehicleNumber,
      driverId: _selectedDriverRrId,
      driverName: _selectedDriverName,
      expectedFreight: _expectedFreightCtrl.text.trim(),
      bookingAmount: _bookingAmountCtrl.text.trim(),
      opsWorkerLocalId: _selectedOpsWorkerLocalId,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_lastTripDataKey, jsonEncode(data.toJson()));
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadRrPartyData() async {
    final dio = ref.read(dioProvider);

    // Enums need only RR4 auth — fire immediately
    dio.get('/api/rr/enums', queryParameters: {'name': 'QuantityUnit'})
        .then((r) {
          if (!mounted) return;
          final vals = (r.data['values'] as List? ?? []).cast<String>();
          if (vals.isNotEmpty) setState(() {
            _quantityUnits = vals;
            if (!_quantityUnits.contains(_weightUnit)) _weightUnit = _quantityUnits.first;
          });
        }).catchError((_) {});
    dio.get('/api/rr/enums', queryParameters: {'name': 'VehicleBodyTypes'})
        .then((r) {
          if (!mounted) return;
          setState(() => _vehicleBodyTypes = (r.data['values'] as List? ?? []).cast<String>());
        }).catchError((_) {});

    // Partners + workers use the org's own RR session — no personal login
    // needed unless it's genuinely expired. The first call goes through
    // runRrAction so an expired session prompts login exactly once; the
    // second then runs with that same now-valid session, avoiding a
    // duplicate login dialog from two concurrent 409s.
    if (mounted) setState(() { _partnersLoading = true; _opsWorkersLoading = true; });
    try {
      final r = await runRrAction(context, ref, () => dio.get('/api/rr/preferred-partners'));
      if (mounted) setState(() {
        _partners = (r.data['partners'] as List? ?? []).cast<Map<String, dynamic>>();
        _partnersLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _partnersLoading = false);
    }
    try {
      final r = await dio.get('/api/rr/company-workers');
      if (mounted) setState(() {
        _opsWorkers = (r.data['workers'] as List? ?? []).cast<Map<String, dynamic>>();
        _opsWorkersLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _opsWorkersLoading = false);
    }
  }

  // Fetch company operation locations → populates the address selector
  Future<void> _loadCompanyLocations(String? companyId, {required bool isConsignor}) async {
    if (companyId == null || companyId.isEmpty) return;
    try {
      final resp = await ref.read(dioProvider).get(
        '/api/rr/operation-locations',
        queryParameters: {'company_id': companyId},
      );
      final locs = (resp.data['locations'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      if (isConsignor) setState(() => _consignorAddresses = locs);
      else             setState(() => _consigneeAddresses = locs);
    } catch (_) {}
  }

  Future<void> _loadPartnerCompanies(Map<String, dynamic> partner, {required bool isConsignor}) async {
    final rrUserId = partner['rr_user_id'] as String?;
    if (rrUserId == null) {
      // company-type partner — company info is directly on the partner record;
      // fetch operation_locations immediately (no postal_addresses for company types)
      final id    = partner['rr_company_id'] as String?;
      final name  = partner['name'] as String? ?? '';
      final gstin = partner['gstin'] as String? ?? '';
      if (isConsignor) setState(() {
        _consignorRrCompanyId    = id; _consignorCompanyName = name; _consignorCompanies = [];
        _consignorAddresses      = [];  // will be filled by operation_locations
        _consignorGstinCtrl.text = gstin;
      });
      else setState(() {
        _consigneeRrCompanyId    = id; _consigneeCompanyName = name; _consigneeCompanies = [];
        _consigneeAddresses      = [];
        _consigneeGstinCtrl.text = gstin;
      });
      _loadCompanyLocations(id, isConsignor: isConsignor);
      return;
    }
    if (isConsignor) setState(() => _consignorCompaniesLoading = true);
    else             setState(() => _consigneeCompaniesLoading = true);
    try {
      final resp = await ref.read(dioProvider).get(
        '/api/rr/partner-companies',
        queryParameters: {'user_id': rrUserId},
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

  // ── City search ───────────────────────────────────────────────────────────

  void _onPickupTyped(String q) {
    setState(() { _pickupCityId = null; _pickupResults = []; });
    _pickupDebounce?.cancel();
    if (q.length < 2) return;
    _pickupDebounce = Timer(const Duration(milliseconds: 400), () => _searchCity(q, isPickup: true));
  }

  void _onDropTyped(String q) {
    setState(() { _dropCityId = null; _dropResults = []; });
    _dropDebounce?.cancel();
    if (q.length < 2) return;
    _dropDebounce = Timer(const Duration(milliseconds: 400), () => _searchCity(q, isPickup: false));
  }

  Future<void> _searchCity(String q, {required bool isPickup}) async {
    if (isPickup) setState(() => _pickupLoading = true);
    else          setState(() => _dropLoading   = true);
    try {
      final resp = await ref.read(dioProvider).get('/api/rr/cities', queryParameters: {'q': q});
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
    _pickupCityId    = city['rr_city_id'] as String;
    _pickupCtrl.text = city['name'] as String;
    _pickupResults   = [];
    _fieldErr.remove('pickupCity');
    _fieldErrMsg.remove('pickupCity');
  });

  void _selectDrop(Map<String, dynamic> city) => setState(() {
    _dropCityId    = city['rr_city_id'] as String;
    _dropCtrl.text = city['name'] as String;
    _dropResults   = [];
    _fieldErr.remove('unloadCity');
    _fieldErrMsg.remove('unloadCity');
  });

  // ── Material search ───────────────────────────────────────────────────────

  void _onMaterialTyped(String q) {
    setState(() { _materialRrId = null; _materialResults = []; });
    _materialDebounce?.cancel();
    _materialDebounce = Timer(const Duration(milliseconds: 350), () => _searchMaterial(q));
  }

  Future<void> _searchMaterial(String q) async {
    setState(() => _materialLoading = true);
    try {
      final session = ref.read(rrSessionProvider);
      final params = <String, dynamic>{'q': q};
      if (session != null && session.isValid) params['rr_token'] = session.token;
      final resp = await ref.read(dioProvider).get('/api/rr/materials', queryParameters: params);
      final items = (resp.data['items'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() { _materialResults = items; _materialLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _materialLoading = false);
    }
  }

  void _selectMaterial(Map<String, dynamic> mat) => setState(() {
    _materialRrId      = mat['rr_material_id'] as String?;
    _materialCtrl.text = mat['name'] as String;
    _materialResults   = [];
    _fieldErr.remove('material');
    _fieldErrMsg.remove('material');
  });

  // ── Address auto-fill ─────────────────────────────────────────────────────

  void _selectConsignorAddress(Map<String, dynamic> addr) {
    setState(() {
      _pickupLine1Ctrl.text = addr['address_line_1'] as String? ?? '';
      _pickupLine2Ctrl.text = addr['address_line_2'] as String? ?? '';
      _pickupPinCtrl.text   = addr['pin']            as String? ?? '';
      _pickupNoEntryZone    = addr['no_entry_zone']  as bool?   ?? false;
      final cId   = addr['city_id']   as String?;
      final cName = addr['city_name'] as String?;
      if (cId != null && cId.isNotEmpty && cName != null && cName.isNotEmpty) {
        _pickupCityId    = cId;
        _pickupCtrl.text = cName;
        _pickupResults   = [];
        _fieldErr.remove('pickupCity');
        _fieldErrMsg.remove('pickupCity');
      }
    });
  }

  void _selectConsigneeAddress(Map<String, dynamic> addr) {
    setState(() {
      _unloadLine1Ctrl.text = addr['address_line_1'] as String? ?? '';
      _unloadLine2Ctrl.text = addr['address_line_2'] as String? ?? '';
      _unloadPinCtrl.text   = addr['pin']            as String? ?? '';
      _unloadNoEntryZone    = addr['no_entry_zone']  as bool?   ?? false;
      final cId   = addr['city_id']   as String?;
      final cName = addr['city_name'] as String?;
      if (cId != null && cId.isNotEmpty && cName != null && cName.isNotEmpty) {
        _dropCityId    = cId;
        _dropCtrl.text = cName;
        _dropResults   = [];
        _fieldErr.remove('unloadCity');
        _fieldErrMsg.remove('unloadCity');
      }
    });
  }

  // ── Vehicle Provider Picker ────────────────────────────────────────────────

  void _onVpPhoneChanged() {
    final digits = _vpPhoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10 && _vpFoundUser == null && !_vpLookingUp) {
      _lookUpVehicleProvider();
    }
    // clear previous result if user edits back
    if (digits.length < 10 && (_vpFoundUser != null || _vpUser != null)) {
      setState(() {
        _vpFoundUser = null; _vpUser = null;
        _vpPersonalVehicles = []; _vpCompanies = []; _vpVehicles = [];
        _vpSelectedCompanyId = null; _vpSelectedCompanyName = null;
        _vpSelectedVehicleRrId = null; _vpSelectedVehicleNumber = null;
        _vpLookupError = null;
      });
    }
  }

  Future<void> _lookUpVehicleProvider() async {
    final phone = _vpPhoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() { _vpLookingUp = true; _vpLookupError = null; _vpFoundUser = null; });
    try {
      final dio = ref.read(dioProvider);
      final r = await runRrAction(context, ref, () => dio.get(
          '/api/rr/vehicle-provider-user', queryParameters: {'phone': phone}));
      if (!mounted) return;
      setState(() {
        _vpFoundUser = Map<String, dynamic>.from(r.data as Map);
        _vpLookingUp = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _vpLookingUp = false;
        _vpLookupError = 'No user found for this number';
      });
    }
  }

  Future<void> _selectVpUser() async {
    final user = _vpFoundUser;
    if (user == null) return;
    setState(() {
      _vpUser = user;
      _vpCompaniesLoading = true;
      _vpPersonalVehicles = [];
      _vpCompanies = [];
      _vpVehicles = [];
      _vpSelectedCompanyId = null;
      _vpSelectedVehicleRrId = null;
      _vpSelectedVehicleNumber = null;
    });
    final userId = user['user_id'] as String? ?? '';
    final dio = ref.read(dioProvider);
    // load companies + personal vehicles in parallel
    await Future.wait([
      dio.get('/api/rr/partner-companies',
          queryParameters: {'user_id': userId}).then((r) {
        if (!mounted) return;
        final list = (r.data['companies'] as List? ?? []).cast<Map<String, dynamic>>();
        setState(() { _vpCompanies = list; _vpCompaniesLoading = false; });
      }).catchError((_) {
        if (mounted) setState(() => _vpCompaniesLoading = false);
      }),
      dio.get('/api/rr/user-vehicles',
          queryParameters: {'user_id': userId}).then((r) {
        if (!mounted) return;
        final list = (r.data['vehicles'] as List? ?? []).cast<Map<String, dynamic>>();
        setState(() => _vpPersonalVehicles = list);
      }).catchError((_) {}),
    ]);
  }

  Future<void> _loadVpCompanyVehicles(String companyId) async {
    setState(() {
      _vpVehiclesLoading = true; _vpVehicles = [];
      _vpSelectedVehicleRrId = null; _vpSelectedVehicleNumber = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final r = await dio.get('/api/rr/company-vehicles',
          queryParameters: {'company_id': companyId});
      if (!mounted) return;
      final list = (r.data['vehicles'] as List? ?? []).cast<Map<String, dynamic>>();
      setState(() { _vpVehicles = list; _vpVehiclesLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _vpVehiclesLoading = false);
    }
  }

  // Actually attaches the picked driver to the selected vehicle's RR crew —
  // RR's booking confirmation reads the driver off the vehicle itself, not
  // off any driver id we send alongside the trip (confirmed live: trip
  // RR-71165 hit "Please add driver for vehicle." at Confirm Booking despite
  // a driver being selected here, because the vehicle's own crew was empty).
  Future<void> _assignDriverToVehicle(String driverUserId) async {
    if (_vpSelectedVehicleRrId == null || !_vehicleHasNoDriver) return;
    setState(() => _assigningDriverToVehicle = true);
    try {
      await runRrAction(context, ref, () => ref.read(rrSyncApiProvider).assignVehicleDriver(
            vehicleId: _vpSelectedVehicleRrId!,
            driverUserId: driverUserId,
          ));
      if (!mounted) return;
      void patchDriver(List<Map<String, dynamic>> list) {
        final idx = list.indexWhere((v) => v['rr_vehicle_id'] == _vpSelectedVehicleRrId);
        if (idx != -1) {
          list[idx] = {...list[idx], 'driver_id': driverUserId, 'driver_name': _selectedDriverName ?? ''};
        }
      }
      setState(() {
        _vehicleHasNoDriver = false;
        _assigningDriverToVehicle = false;
        patchDriver(_vpVehicles);
        patchDriver(_vpPersonalVehicles);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _assigningDriverToVehicle = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Could not attach driver to vehicle on RR: ${ref.read(apiServiceProvider).handleError(e)}',
          style: _inter(size: 13, color: Colors.white),
        ),
        backgroundColor: _errorClr,
      ));
    }
  }

  // ── Validation helpers ────────────────────────────────────────────────────

  void _clearFieldErr(String key) {
    if (_fieldErr.containsKey(key) && mounted) setState(() {
      _fieldErr.remove(key);
      _fieldErrMsg.remove(key);
    });
  }

  Widget _inlineErr(String fieldKey) {
    final msg = _fieldErrMsg[fieldKey];
    if (msg == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline_rounded, size: 13, color: _errorClr),
          ),
          const SizedBox(width: 5),
          Expanded(child: Text(msg, style: _inter(size: 12, color: _errorClr))),
        ],
      ),
    );
  }

  void _scrollToKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.0,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  // Sets error state, switches step if needed, then scrolls to field.
  void _failField(int step, GlobalKey key, String fieldKey, String msg) {
    final bool stepChange = _currentStep != step;
    setState(() {
      _fieldErr[fieldKey]    = true;
      _fieldErrMsg[fieldKey] = msg;
      if (stepChange) _currentStep = step;
    });
    if (stepChange) {
      // New ListView needs one extra frame to mount and lay out before scrolling.
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToKey(key)));
    } else {
      _scrollToKey(key);
    }
  }

  bool _validateStep0() {
    if (_consignorRrCompanyId == null) {
      _failField(0, _keyConsignorCompany, 'consignorCompany',
          'Must select company from dropdown');
      return false;
    }
    if (_pickupCityId == null) {
      _failField(0, _keyPickupCity, 'pickupCity',
          'Pickup City is required — search and select from the list');
      return false;
    }
    if (_dropCityId == null) {
      _failField(0, _keyUnloadCity, 'unloadCity',
          'Unload City is required — search and select from the list');
      return false;
    }
    if (_materialRrId == null) {
      _failField(0, _keyMaterial, 'material',
          'Material / Product Type is required — search and select from the list');
      return false;
    }
    final w = _weightCtrl.text.trim();
    if (w.isEmpty || double.tryParse(w) == null) {
      _failField(0, _keyWeight, 'weight', 'Total Weight / Quantity is required');
      return false;
    }
    final iv = _invoiceValueCtrl.text.trim();
    if (iv.isEmpty || double.tryParse(iv) == null) {
      _failField(0, _keyInvoiceValue, 'invoiceValue',
          'Total Invoice Value (₹) is required — used as parcel cost in RR');
      return false;
    }
    if (_selectedOpsWorkerId == null) {
      _failField(0, _keyOpsWorker, 'opsWorker',
          'Select the RR Ops worker handling this trip');
      return false;
    }
    final ef = _expectedFreightCtrl.text.trim();
    if (ef.isEmpty || double.tryParse(ef) == null) {
      _failField(0, _keyExpectedFreight, 'expectedFreight',
          'Expected Freight Amount (₹) is required by RR create trip');
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    if (_vpUser == null) {
      _failField(1, _keyVpPhone, 'vpPhone',
          'Enter Vehicle Provider phone number and tap the result to select');
      return false;
    }
    if (_vpSelectedCompanyId == null) {
      _failField(1, _keyVpCompany, 'vpCompany',
          'Vehicle Provider Company is required — select a company');
      return false;
    }
    if (_vpSelectedVehicleRrId == null) {
      _failField(1, _keyVehicle, 'vehicle', 'Select a Vehicle');
      return false;
    }
    if (_selectedDriverRrId == null || _selectedDriverRrId!.isEmpty) {
      _failField(1, _keyDriver, 'driver', 'Select a Driver');
      return false;
    }
    return true;
  }

  // Full cross-step validation — used at submit time.
  bool _validateAll() {
    if (!_validateStep0()) return false;
    if (!_validateStep1()) return false;
    final ba = double.tryParse(_bookingAmountCtrl.text.trim());
    if (ba == null || ba <= 0) {
      _failField(2, _keyBookingAmount, 'bookingAmount',
          'Booking Amount (₹) is required and must be greater than 0');
      return false;
    }
    return true;
  }

  // ── Step navigation ───────────────────────────────────────────────────────

  void _scrollStepToTop(int step) {
    final ctrl = [_scrollCtrl0, _scrollCtrl1, _scrollCtrl2][step];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ctrl.hasClients) ctrl.jumpTo(0);
    });
  }

  void _goNext() {
    setState(() { _submitError = null; _fieldErr.clear(); _fieldErrMsg.clear(); });
    if (_currentStep == 0 && !_validateStep0()) return;
    if (_currentStep == 1 && !_validateStep1()) return;
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _scrollStepToTop(_currentStep);
    }
  }

  void _goBack() {
    setState(() {
      _submitError = null;
      _fieldErr.clear();
      _fieldErrMsg.clear();
      if (_currentStep > 0) _currentStep--;
    });
    _scrollStepToTop(_currentStep);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() { _submitError = null; _fieldErr.clear(); _fieldErrMsg.clear(); });
    if (!_validateAll()) return;

    setState(() { _submitting = true; _submitError = null; });

    final weightStr = _weightCtrl.text.trim();
    final body = <String, dynamic>{
      'origin':                 _pickupCtrl.text.trim(),
      'destination':            _dropCtrl.text.trim(),
      'load_item':              _materialCtrl.text.trim(),
      'origin_rr_city_id':      _pickupCityId,
      'destination_rr_city_id': _dropCityId,
      'material_rr_id':         _materialRrId,
      'weight_value':           double.tryParse(weightStr) ?? 0,
      'weight_unit':            _weightUnit,
      'weight':                 '$weightStr $_weightUnit',
    };

    // Consignor
    if (_consignorRrCompanyId != null)              body['consignor_rr_company_id'] = _consignorRrCompanyId;
    final cn = _consignorNameCtrl.text.trim();
    final cg = _consignorGstinCtrl.text.trim();
    if (cn.isNotEmpty) body['consignor_name']  = cn;
    if (cg.isNotEmpty) body['consignor_gstin'] = cg;

    // Consignee
    if (_consigneeRrCompanyId != null)              body['consignee_rr_company_id'] = _consigneeRrCompanyId;
    final een = _consigneeNameCtrl.text.trim();
    final eeg = _consigneeGstinCtrl.text.trim();
    if (een.isNotEmpty) body['consignee_name']  = een;
    if (eeg.isNotEmpty) body['consignee_gstin'] = eeg;

    // Pickup location
    final pl1 = _pickupLine1Ctrl.text.trim();
    final pl2 = _pickupLine2Ctrl.text.trim();
    final pp  = _pickupPinCtrl.text.trim();
    if (pl1.isNotEmpty) body['pickup_address_line1'] = pl1;
    if (pl2.isNotEmpty) body['pickup_address_line2'] = pl2;
    if (pp.isNotEmpty)  body['pickup_pin']           = pp;
    body['pickup_no_entry_zone'] = _pickupNoEntryZone;

    // Unload location
    final ul1 = _unloadLine1Ctrl.text.trim();
    final ul2 = _unloadLine2Ctrl.text.trim();
    final up  = _unloadPinCtrl.text.trim();
    final dc  = _depotCodeCtrl.text.trim();
    if (ul1.isNotEmpty) body['unload_address_line1'] = ul1;
    if (ul2.isNotEmpty) body['unload_address_line2'] = ul2;
    if (up.isNotEmpty)  body['unload_pin']           = up;
    if (dc.isNotEmpty)  body['depot_code']           = dc;
    body['unload_no_entry_zone'] = _unloadNoEntryZone;

    // Parcel
    final iv = double.tryParse(_invoiceValueCtrl.text.trim());
    if (iv != null) body['invoice_value'] = iv;
    final desc = _parcelDescCtrl.text.trim();
    if (desc.isNotEmpty) body['parcel_description'] = desc;
    body['part_load'] = _partLoad;

    // Vehicle
    if (_vehicleBodyType != null) body['vehicle_body_type'] = _vehicleBodyType;
    if (_axleType        != null) body['axle_type']         = _axleType;
    if (_numberOfWheels  != null) body['number_of_wheels']  = _numberOfWheels;
    final ef = double.tryParse(_expectedFreightCtrl.text.trim());
    if (ef != null) body['expected_freight'] = ef;
    final ba = double.tryParse(_bookingAmountCtrl.text.trim());
    if (ba != null) body['booking_amount'] = ba;
    // Vehicle provider picker
    if (_vpSelectedCompanyId     != null) body['transporter_rr_company_id'] = _vpSelectedCompanyId;
    if (_vpSelectedVehicleRrId   != null) body['rr_vehicle_id']             = _vpSelectedVehicleRrId;
    if (_vpSelectedVehicleNumber != null) body['vehicle_number']            = _vpSelectedVehicleNumber;
    if (_selectedDriverRrId      != null) body['rr_driver_id']              = _selectedDriverRrId;

    // Ops worker
    if (_selectedOpsWorkerLocalId != null) body['rr_ops_user_id'] = _selectedOpsWorkerLocalId;

    // RR token: omitted here on purpose — the backend falls back to the org's
    // own RR session, so trip creation never needs a fresh interactive login.

    // Save current values for next time — unconditional, matching rr_kanpur's
    // own timing (saved right before submit, not gated on success).
    await _saveLastTripData();
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

    final rrNum      = trip.rrTripNumber;
    final syncStatus = trip.rrSyncStatus;

    // Store RR trip number so dashboard can show the popup over itself
    if (rrNum != null && rrNum.isNotEmpty) {
      ref.read(pendingRrTripNumberProvider.notifier).state = rrNum;
      ref.read(pendingCreatedTripIdProvider.notifier).state = trip.id;
    } else if (syncStatus == 'failed') {
      ref.read(pendingRrTripNumberProvider.notifier).state =
          '__failed__:${trip.rrSyncError ?? 'unknown error'}';
      ref.read(pendingCreatedTripIdProvider.notifier).state = trip.id;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
          title: Text('New Trip', style: _manrope(size: 16, weight: FontWeight.w800)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _StepIndicator(current: _currentStep),
            ),
            const Divider(height: 1),
            // ═══════════════════════════════════════════════════════════
            // STEP 0 · TRIP INFO
            // ═══════════════════════════════════════════════════════════
            if (_currentStep == 0) Expanded(child: ListView(
              controller: _scrollCtrl0,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [

            // ─── 1 · CONSIGNOR
            // ═══════════════════════════════════════════════════════════
            _SectionHeader(label: 'Consignor Info'),
            const SizedBox(height: 4),
            Text('Select from Partners to auto fill Consignor details',
                style: _inter(size: 12, color: _secondary)),
            const SizedBox(height: 12),

            _FieldLabel(label: 'Select from Partners (optional)'),
            const SizedBox(height: 6),
            _partnersLoading
                ? const _LoadingChip(label: 'Loading partners…')
                : _DropdownField<String>(
                    value: _consignorPartner?['partner_id'] as String?,
                    hint: 'Select partner',
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
                        _consignorPartner        = p;
                        _consignorPhone          = (p['phone'] as Map?)?['number'] as String?;
                        _consignorNameCtrl.text  = p['name'] as String? ?? '';
                        _consignorGstinCtrl.text = p['gstin'] as String? ?? '';
                        _consignorAddresses      = (p['postal_addresses'] as List? ?? []).cast<Map<String, dynamic>>();
                        _consignorRrCompanyId    = null;
                        _consignorCompanyName    = null;
                        _consignorCompanies      = [];
                      });
                      _loadPartnerCompanies(p, isConsignor: true);
                    },
                  ),

            if (_consignorPhone != null) ...[
              const SizedBox(height: 10),
              _FieldLabel(label: 'Phone Number'),
              const SizedBox(height: 6),
              _ReadOnlyField(value: _consignorPhone!, icon: Icons.phone_outlined),
            ],

            const SizedBox(height: 10),
            _FieldLabel(label: 'Consignor Name'),
            const SizedBox(height: 6),
            _TextInput(controller: _consignorNameCtrl, hint: 'e.g. Tata Steel Ltd'),

            const SizedBox(height: 10),
            _FieldLabel(key: _keyConsignorCompany, label: 'Select Consignor Company *'),
            const SizedBox(height: 6),
            _consignorCompaniesLoading
                ? const _LoadingChip(label: 'Loading companies…')
                : _consignorCompanies.isEmpty && _consignorRrCompanyId != null
                    ? _SelectedChip(
                        label: _consignorCompanyName ?? '',
                        onClear: () => setState(() {
                          _consignorRrCompanyId = null;
                          _consignorCompanyName = null;
                          _consignorGstinCtrl.clear();
                        }),
                      )
                    : _DropdownField<String>(
                        hasError: _fieldErr['consignorCompany'] == true,
                        value: _consignorRrCompanyId,
                        hint: _consignorPartner == null ? 'Select a partner above first' : 'Select company',
                        items: _consignorCompanies.map((c) => DropdownMenuItem<String>(
                          value: c['rr_company_id'] as String,
                          child: Text(c['name'] as String? ?? '—',
                              style: _inter(size: 13, color: _onSurface),
                              overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _consignorPartner == null ? null : (v) {
                          final c = _consignorCompanies.firstWhere(
                              (x) => x['rr_company_id'] == v, orElse: () => {});
                          setState(() {
                            _consignorRrCompanyId  = v;
                            _consignorCompanyName  = c['name'] as String?;
                            _consignorGstinCtrl.text = c['gstin'] as String? ?? '';
                            _consignorAddresses    = [];
                            _fieldErr.remove('consignorCompany');
                            _fieldErrMsg.remove('consignorCompany');
                          });
                          _loadCompanyLocations(v, isConsignor: true);
                        },
                      ),
            _inlineErr('consignorCompany'),

            const SizedBox(height: 10),
            _FieldLabel(label: 'Consignor GSTIN'),
            const SizedBox(height: 6),
            _TextInput(controller: _consignorGstinCtrl, hint: 'Auto-filled or enter manually'),

            // ═══════════════════════════════════════════════════════════
            // 2 · PICKUP LOCATION
            // ═══════════════════════════════════════════════════════════
            const SizedBox(height: 24),
            _SectionHeader(label: 'Pickup Location'),
            const SizedBox(height: 4),
            Text('Select consignor address to auto fill',
                style: _inter(size: 12, color: _secondary)),
            const SizedBox(height: 12),

            if (_consignorAddresses.isNotEmpty) ...[
              _FieldLabel(label: 'Select consignor address (optional)'),
              const SizedBox(height: 6),
              _DropdownField<int>(
                value: null,
                hint: 'Select to auto-fill address fields',
                items: List.generate(_consignorAddresses.length, (i) {
                  final a = _consignorAddresses[i];
                  final parts = <String>[
                    if ((a['city_name'] as String? ?? '').isNotEmpty) a['city_name'] as String,
                    if ((a['address_line_1'] as String? ?? '').isNotEmpty) a['address_line_1'] as String,
                  ];
                  final label = parts.isNotEmpty ? parts.join(' — ') : 'Address ${i + 1}';
                  return DropdownMenuItem<int>(
                    value: i,
                    child: Text(label, style: _inter(size: 13, color: _onSurface), overflow: TextOverflow.ellipsis),
                  );
                }),
                onChanged: (i) { if (i != null) _selectConsignorAddress(_consignorAddresses[i]); },
              ),
              const SizedBox(height: 10),
            ],

            _FieldLabel(label: 'Address Line 1'),
            const SizedBox(height: 6),
            _CountedTextInput(controller: _pickupLine1Ctrl, hint: 'Street / area', maxLength: 200),

            const SizedBox(height: 10),
            _FieldLabel(label: 'Address Line 2'),
            const SizedBox(height: 6),
            _CountedTextInput(controller: _pickupLine2Ctrl, hint: 'Landmark / locality', maxLength: 200),

            const SizedBox(height: 10),
            _FieldLabel(key: _keyPickupCity, label: 'Pickup City Name *'),
            const SizedBox(height: 6),
            _SearchField(
              hasError: _fieldErr['pickupCity'] == true,
              controller: _pickupCtrl,
              hint: 'Search city…',
              loading: _pickupLoading,
              confirmed: _pickupCityId != null,
              onChanged: _onPickupTyped,
              onClear: () => setState(() { _pickupCityId = null; _pickupCtrl.clear(); _pickupResults = []; }),
            ),
            _inlineErr('pickupCity'),
            if (_pickupResults.isNotEmpty)
              _ResultsCard(items: _pickupResults, labelKey: 'name', onSelect: _selectPickup),

            const SizedBox(height: 10),
            _FieldLabel(label: 'Pin / Zip Code'),
            const SizedBox(height: 6),
            _TextInput(controller: _pickupPinCtrl, hint: '6-digit PIN', inputType: TextInputType.number),

            const SizedBox(height: 10),
            _CheckboxRow(
              label: 'No Entry Zone',
              value: _pickupNoEntryZone,
              onChanged: (v) => setState(() => _pickupNoEntryZone = v ?? false),
            ),

            // ═══════════════════════════════════════════════════════════
            // 3 · CONSIGNEE
            // ═══════════════════════════════════════════════════════════
            const SizedBox(height: 24),
            _SectionHeader(label: 'Consignee Info'),
            const SizedBox(height: 4),
            Text('Select from Partners to auto fill Consignee details',
                style: _inter(size: 12, color: _secondary)),
            const SizedBox(height: 12),

            _FieldLabel(label: 'Select from Partners (optional)'),
            const SizedBox(height: 6),
            _partnersLoading
                ? const _LoadingChip(label: 'Loading partners…')
                : _DropdownField<String>(
                    value: _consigneePartner?['partner_id'] as String?,
                    hint: 'Select partner',
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
                        _consigneePartner        = p;
                        _consigneePhone          = (p['phone'] as Map?)?['number'] as String?;
                        _consigneeNameCtrl.text  = p['name'] as String? ?? '';
                        _consigneeGstinCtrl.text = p['gstin'] as String? ?? '';
                        _consigneeAddresses      = (p['postal_addresses'] as List? ?? []).cast<Map<String, dynamic>>();
                        _consigneeRrCompanyId    = null;
                        _consigneeCompanyName    = null;
                        _consigneeCompanies      = [];
                      });
                      _loadPartnerCompanies(p, isConsignor: false);
                    },
                  ),

            if (_consigneePhone != null) ...[
              const SizedBox(height: 10),
              _FieldLabel(label: 'Phone Number'),
              const SizedBox(height: 6),
              _ReadOnlyField(value: _consigneePhone!, icon: Icons.phone_outlined),
            ],

            const SizedBox(height: 10),
            _FieldLabel(label: 'Consignee Name'),
            const SizedBox(height: 6),
            _TextInput(controller: _consigneeNameCtrl, hint: 'e.g. JSW Steel Ltd'),

            const SizedBox(height: 10),
            _FieldLabel(label: 'Select Consignee Company'),
            const SizedBox(height: 6),
            _consigneeCompaniesLoading
                ? const _LoadingChip(label: 'Loading companies…')
                : _consigneeCompanies.isEmpty && _consigneeRrCompanyId != null
                    ? _SelectedChip(
                        label: _consigneeCompanyName ?? '',
                        onClear: () => setState(() {
                          _consigneeRrCompanyId = null;
                          _consigneeCompanyName = null;
                          _consigneeGstinCtrl.clear();
                        }),
                      )
                    : _DropdownField<String>(
                        value: _consigneeRrCompanyId,
                        hint: _consigneePartner == null ? 'Select a partner above first' : 'Select company',
                        items: _consigneeCompanies.map((c) => DropdownMenuItem<String>(
                          value: c['rr_company_id'] as String,
                          child: Text(c['name'] as String? ?? '—',
                              style: _inter(size: 13, color: _onSurface),
                              overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _consigneePartner == null ? null : (v) {
                          final c = _consigneeCompanies.firstWhere(
                              (x) => x['rr_company_id'] == v, orElse: () => {});
                          setState(() {
                            _consigneeRrCompanyId  = v;
                            _consigneeCompanyName  = c['name'] as String?;
                            _consigneeGstinCtrl.text = c['gstin'] as String? ?? '';
                            _consigneeAddresses    = [];
                          });
                          _loadCompanyLocations(v, isConsignor: false);
                        },
                      ),

            const SizedBox(height: 10),
            _FieldLabel(label: 'Consignee GSTIN'),
            const SizedBox(height: 6),
            _TextInput(controller: _consigneeGstinCtrl, hint: 'Auto-filled or enter manually'),

            // ═══════════════════════════════════════════════════════════
            // 4 · UNLOAD LOCATION
            // ═══════════════════════════════════════════════════════════
            const SizedBox(height: 24),
            _SectionHeader(label: 'Unload Location'),
            const SizedBox(height: 4),
            Text('Select consignee address to auto fill',
                style: _inter(size: 12, color: _secondary)),
            const SizedBox(height: 12),

            if (_consigneeAddresses.isNotEmpty) ...[
              _FieldLabel(label: 'Select consignee address (optional)'),
              const SizedBox(height: 6),
              _DropdownField<int>(
                value: null,
                hint: 'Select to auto-fill address fields',
                items: List.generate(_consigneeAddresses.length, (i) {
                  final a = _consigneeAddresses[i];
                  final parts = <String>[
                    if ((a['city_name'] as String? ?? '').isNotEmpty) a['city_name'] as String,
                    if ((a['address_line_1'] as String? ?? '').isNotEmpty) a['address_line_1'] as String,
                  ];
                  final label = parts.isNotEmpty ? parts.join(' — ') : 'Address ${i + 1}';
                  return DropdownMenuItem<int>(
                    value: i,
                    child: Text(label, style: _inter(size: 13, color: _onSurface), overflow: TextOverflow.ellipsis),
                  );
                }),
                onChanged: (i) { if (i != null) _selectConsigneeAddress(_consigneeAddresses[i]); },
              ),
              const SizedBox(height: 10),
            ],

            _FieldLabel(label: 'Address Line 1'),
            const SizedBox(height: 6),
            _CountedTextInput(controller: _unloadLine1Ctrl, hint: 'Street / area', maxLength: 200),

            const SizedBox(height: 10),
            _FieldLabel(label: 'Address Line 2'),
            const SizedBox(height: 6),
            _CountedTextInput(controller: _unloadLine2Ctrl, hint: 'Landmark / locality', maxLength: 200),

            const SizedBox(height: 10),
            _FieldLabel(key: _keyUnloadCity, label: 'Unload City Name *'),
            const SizedBox(height: 6),
            _SearchField(
              hasError: _fieldErr['unloadCity'] == true,
              controller: _dropCtrl,
              hint: 'Search city…',
              loading: _dropLoading,
              confirmed: _dropCityId != null,
              onChanged: _onDropTyped,
              onClear: () => setState(() { _dropCityId = null; _dropCtrl.clear(); _dropResults = []; }),
            ),
            _inlineErr('unloadCity'),
            if (_dropResults.isNotEmpty)
              _ResultsCard(items: _dropResults, labelKey: 'name', onSelect: _selectDrop),

            const SizedBox(height: 10),
            _FieldLabel(label: 'Pin / Zip Code'),
            const SizedBox(height: 6),
            _TextInput(controller: _unloadPinCtrl, hint: '6-digit PIN', inputType: TextInputType.number),

            const SizedBox(height: 10),
            _FieldLabel(label: 'Depot Code'),
            const SizedBox(height: 6),
            _TextInput(controller: _depotCodeCtrl, hint: 'e.g. KNP01'),

            const SizedBox(height: 10),
            _CheckboxRow(
              label: 'No Entry Zone',
              value: _unloadNoEntryZone,
              onChanged: (v) => setState(() => _unloadNoEntryZone = v ?? false),
            ),

            // ═══════════════════════════════════════════════════════════
            // 5 · PARCEL / LOAD INFORMATION
            // ═══════════════════════════════════════════════════════════
            const SizedBox(height: 24),
            _SectionHeader(label: 'Parcel / Load Information'),
            const SizedBox(height: 12),

            _FieldLabel(key: _keyMaterial, label: 'Material / Product Type *'),
            const SizedBox(height: 6),
            Focus(
              onFocusChange: (focused) {
                if (focused && _materialCtrl.text.isEmpty) _searchMaterial('');
              },
              child: _SearchField(
                hasError: _fieldErr['material'] == true,
                controller: _materialCtrl,
                hint: 'Search material…',
                loading: _materialLoading,
                confirmed: _materialRrId != null,
                onChanged: _onMaterialTyped,
                onClear: () => setState(() { _materialRrId = null; _materialCtrl.clear(); _materialResults = []; }),
              ),
            ),
            _inlineErr('material'),
            if (_materialResults.isNotEmpty)
              _ResultsCard(items: _materialResults, labelKey: 'name', onSelect: _selectMaterial),

            const SizedBox(height: 10),
            _FieldLabel(key: _keyWeight, label: 'Total Weight / Quantity *'),
            const SizedBox(height: 6),
            _WeightRow(
              hasError: _fieldErr['weight'] == true,
              controller: _weightCtrl,
              unit: _quantityUnits.contains(_weightUnit) ? _weightUnit : _quantityUnits.first,
              units: _quantityUnits,
              onUnitChanged: (u) => setState(() => _weightUnit = u),
            ),
            _inlineErr('weight'),

            const SizedBox(height: 10),
            _FieldLabel(key: _keyInvoiceValue, label: 'Total Invoice Value (₹) *'),
            const SizedBox(height: 6),
            _TextInput(
              hasError: _fieldErr['invoiceValue'] == true,
              controller: _invoiceValueCtrl,
              hint: 'e.g. 150000',
              inputType: TextInputType.number,
            ),
            _inlineErr('invoiceValue'),

            const SizedBox(height: 10),
            _FieldLabel(label: 'Description of Parcel'),
            const SizedBox(height: 6),
            _CountedTextInput(controller: _parcelDescCtrl, hint: 'e.g. Steel coils', maxLength: 100),

            const SizedBox(height: 10),
            _CheckboxRow(
              label: 'Part Load',
              value: _partLoad,
              onChanged: (v) => setState(() => _partLoad = v ?? false),
            ),

            // ── Trip Handled By (step 0) ──────────────────────────────
            const SizedBox(height: 24),
            _SectionHeader(label: 'Trip Handled By'),
            const SizedBox(height: 12),

            _FieldLabel(key: _keyOpsWorker, label: 'Handled by Person *'),
            const SizedBox(height: 6),
            _opsWorkersLoading
                ? const _LoadingChip(label: 'Loading workers…')
                : _DropdownField<String>(
                    hasError: _fieldErr['opsWorker'] == true,
                    value: _selectedOpsWorkerId,
                    hint: 'Select RR Ops worker',
                    items: _opsWorkers.map((w) => DropdownMenuItem<String>(
                      value: w['rr_user_id'] as String,
                      child: Text(
                        '${w['name'] ?? '—'}'
                        '${(w['position'] as String?)?.isNotEmpty == true ? '  •  ${w['position']}' : ''}',
                        style: _inter(size: 13, color: _onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (v) {
                      final w = _opsWorkers.firstWhere((x) => x['rr_user_id'] == v, orElse: () => {});
                      setState(() {
                        _selectedOpsWorkerId      = v;
                        _selectedOpsWorkerLocalId = w['local_user_id'] as String?;
                        _fieldErr.remove('opsWorker');
                        _fieldErrMsg.remove('opsWorker');
                      });
                    },
                  ),
            _inlineErr('opsWorker'),

            const SizedBox(height: 16),
            _FieldLabel(key: _keyExpectedFreight, label: 'Expected Freight Amount (₹) *'),
            const SizedBox(height: 6),
            _TextInput(
              hasError: _fieldErr['expectedFreight'] == true,
              controller: _expectedFreightCtrl,
              hint: 'e.g. 45000',
              inputType: TextInputType.number,
            ),
            _inlineErr('expectedFreight'),

            ], // end step 0 content
            )), // end step 0 Expanded+ListView
            // ═══════════════════════════════════════════════════════════
            // STEP 1 · VEHICLE
            // ═══════════════════════════════════════════════════════════
            if (_currentStep == 1) Expanded(child: ListView(
              controller: _scrollCtrl1,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [

            _SectionHeader(label: 'Vehicle Provider'),
            const SizedBox(height: 4),
            Text('Enter provider phone → select user → select company → select vehicle',
                style: _inter(size: 12, color: _secondary)),
            const SizedBox(height: 12),

            _FieldLabel(key: _keyVpPhone, label: 'Vehicle Provider Phone *'),
            const SizedBox(height: 6),
            _TextInput(
              hasError: _fieldErr['vpPhone'] == true,
              controller: _vpPhoneCtrl,
              hint: 'e.g. 8960281816 — auto-searches at 10 digits',
              inputType: TextInputType.phone,
            ),
            _inlineErr('vpPhone'),
            if (_vpLookingUp) ...[
              const SizedBox(height: 8),
              const _LoadingChip(label: 'Looking up…'),
            ],
            if (_vpLookupError != null) ...[
              const SizedBox(height: 8),
              Text(_vpLookupError!, style: _inter(size: 12, color: _errorClr)),
            ],

            if (_vpFoundUser != null && _vpUser == null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  setState(() { _fieldErr.remove('vpPhone'); _fieldErrMsg.remove('vpPhone'); });
                  await _selectVpUser();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF388E3C), width: 1),
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_outline_rounded, color: Color(0xFF388E3C), size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      _vpFoundUser!['name'] as String? ?? 'Unknown',
                      style: _inter(size: 13, weight: FontWeight.w600, color: const Color(0xFF1B5E20)),
                    )),
                    Text('Tap to select', style: _inter(size: 11, color: const Color(0xFF388E3C))),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF388E3C), size: 18),
                  ]),
                ),
              ),
            ],

            if (_vpUser != null) ...[
              const SizedBox(height: 10),
              _ReadOnlyField(
                value: _vpUser!['name'] as String? ?? 'Unknown',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              _FieldLabel(key: _keyVpCompany, label: 'Select Provider Company *'),
              const SizedBox(height: 6),
              _vpCompaniesLoading
                  ? const _LoadingChip(label: 'Loading companies…')
                  : _vpCompanies.isEmpty
                      ? Text('No companies — vehicle from personal fleet below',
                            style: _inter(size: 12, color: _secondary))
                      : _DropdownField<String>(
                          hasError: _fieldErr['vpCompany'] == true,
                          value: _vpSelectedCompanyId,
                          hint: 'Select company',
                          items: _vpCompanies.map((c) => DropdownMenuItem<String>(
                            value: c['rr_company_id'] as String,
                            child: Text(c['name'] as String? ?? '', style: _inter(size: 13, color: _onSurface)),
                          )).toList(),
                          onChanged: (v) async {
                            if (v == null) return;
                            final c = _vpCompanies.firstWhere((x) => x['rr_company_id'] == v);
                            setState(() {
                              _vpSelectedCompanyId     = v;
                              _vpSelectedCompanyName   = c['name'] as String?;
                              _vpSelectedVehicleRrId   = null;
                              _fieldErr.remove('vpCompany');
                              _fieldErrMsg.remove('vpCompany');
                              _vpSelectedVehicleNumber = null;
                            });
                            _loadVpCompanyVehicles(v);
                          },
                        ),
              _inlineErr('vpCompany'),
              const SizedBox(height: 12),
              _FieldLabel(key: _keyVehicle, label: 'Select Vehicle *'),
              const SizedBox(height: 6),
              _vpVehiclesLoading
                  ? const _LoadingChip(label: 'Loading vehicles…')
                  : () {
                      // Personal + company vehicle lists come from two independent RR
                      // endpoints and can both return the same vehicle (e.g. a vehicle
                      // personally owned by the selected user that is also affiliated
                      // with the chosen company) — dedupe by rr_vehicle_id so the same
                      // vehicle never appears twice and DropdownButtonFormField's
                      // unique-value requirement is satisfied.
                      final seen = <String>{};
                      final all = [..._vpPersonalVehicles, ..._vpVehicles].where((v) {
                        final id = v['rr_vehicle_id'] as String?;
                        if (id == null || seen.contains(id)) return false;
                        seen.add(id);
                        return true;
                      }).toList();
                      if (all.isEmpty) {
                        return Text(
                          _vpSelectedCompanyId == null
                              ? 'Select a company above to load vehicles'
                              : 'No vehicles found',
                          style: _inter(size: 12, color: _secondary),
                        );
                      }
                      String vehicleLabel(Map<String, dynamic> v) {
                        final num        = v['number'] as String? ?? 'Unknown';
                        final btype      = v['body_type'] as String? ?? '';
                        final src        = v['source'] as String? ?? '';
                        final driverName = v['driver_name'] as String? ?? '';
                        final label = btype.isNotEmpty ? '$num · $btype' : num;
                        final badge = src == 'market_vehicles' ? ' (market)' : '';
                        final driverSuffix = driverName.isNotEmpty ? '  — $driverName' : '';
                        return '$label$badge$driverSuffix';
                      }
                      return _DropdownField<String>(
                        hasError: _fieldErr['vehicle'] == true,
                        value: _vpSelectedVehicleRrId,
                        hint: 'Select a vehicle',
                        items: all.map((v) {
                          final hasDriver = (v['driver_id'] as String? ?? '').isNotEmpty;
                          return DropdownMenuItem<String>(
                            value: v['rr_vehicle_id'] as String,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Flexible(child: Text(vehicleLabel(v),
                                  style: _inter(size: 13, color: _onSurface), overflow: TextOverflow.ellipsis)),
                              if (!hasDriver) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFE65100)),
                              ],
                            ]),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          final picked = all.firstWhere((v) => v['rr_vehicle_id'] == id);
                          setState(() {
                            _vpSelectedVehicleRrId   = id;
                            _vpSelectedVehicleNumber = picked['number'] as String?;
                            _fieldErr.remove('vehicle');
                            _fieldErrMsg.remove('vehicle');

                            // Auto-fill the driver from the vehicle's own RR crew
                            // record when it has one — the old flow's behaviour,
                            // still overridable below. Vehicles with no driver on
                            // file (e.g. freshly quick-added) fall through to the
                            // warning + mandatory manual search/add.
                            final vDriverId   = picked['driver_id'] as String? ?? '';
                            final vDriverName = picked['driver_name'] as String? ?? '';
                            if (vDriverId.isNotEmpty) {
                              _selectedDriverRrId = vDriverId;
                              _selectedDriverName = vDriverName;
                              _driverPhoneCtrl.text = vDriverName;
                              _vehicleHasNoDriver = false;
                              _fieldErr.remove('driver');
                              _fieldErrMsg.remove('driver');
                            } else {
                              _selectedDriverRrId = null;
                              _selectedDriverName = null;
                              _driverPhoneCtrl.clear();
                              _vehicleHasNoDriver = true;
                            }
                          });
                        },
                      );
                    }(),
              _inlineErr('vehicle'),
            ],

            const SizedBox(height: 20),
            _FieldLabel(key: _keyDriver, label: 'Driver *'),
            if (_vehicleHasNoDriver) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFA726)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This vehicle has no driver assigned on RR — search for one below or add a new driver.',
                      style: _inter(size: 12, color: const Color(0xFFE65100)),
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 6),
            RrSearchField<Map<String, dynamic>>(
              label: 'Driver Name or Phone Number',
              hintText: 'Full 10-digit phone, or part of the name',
              controller: _driverPhoneCtrl,
              keyboardType: TextInputType.text,
              search: (q) async {
                return runRrAction(context, ref, () => ref.read(rrSyncApiProvider)
                    .searchRrUsers(q, driversOnly: true));
              },
              itemLabel: (u) => u['name'] as String? ?? '',
              itemSubtitle: (u) => u['phone'] as String? ?? '',
              onSelected: (u) {
                final driverId = u['user_id'] as String?;
                final wasVehicleDriverless = _vehicleHasNoDriver;
                setState(() {
                  _selectedDriverRrId = driverId;
                  _selectedDriverName = u['name'] as String?;
                  _driverPhoneCtrl.text = '${u['name']} (${u['phone']})';
                  _fieldErr.remove('driver');
                  _fieldErrMsg.remove('driver');
                });
                if (wasVehicleDriverless && driverId != null) {
                  _assignDriverToVehicle(driverId);
                } else {
                  setState(() => _vehicleHasNoDriver = false);
                }
              },
              onCleared: () => setState(() { _selectedDriverRrId = null; _selectedDriverName = null; }),
            ),
            _inlineErr('driver'),
            if (_assigningDriverToVehicle) ...[
              const SizedBox(height: 8),
              const _LoadingChip(label: 'Attaching driver to vehicle on RR…'),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final wasVehicleDriverless = _vehicleHasNoDriver;
                final result = await Navigator.of(context).push<Map<String, dynamic>>(
                  MaterialPageRoute(builder: (_) => const AddRrUserScreen()),
                );
                if (result != null && mounted) {
                  final driverId = result['user_id'] as String?;
                  setState(() {
                    _selectedDriverRrId = driverId;
                    _selectedDriverName = result['name'] as String?;
                    _driverPhoneCtrl.text = '${result['name']} (${result['phone']})';
                    _fieldErr.remove('driver');
                    _fieldErrMsg.remove('driver');
                  });
                  if (wasVehicleDriverless && driverId != null) {
                    _assignDriverToVehicle(driverId);
                  } else {
                    setState(() => _vehicleHasNoDriver = false);
                  }
                }
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Add New Driver'),
            ),

            const SizedBox(height: 20),
            _SectionHeader(label: 'Vehicle Specs'),
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

            const SizedBox(height: 10),
            _FieldLabel(label: 'Axle Type'),
            const SizedBox(height: 6),
            _DropdownField<String>(
              value: _axleType,
              hint: 'Select axle type',
              items: _axleTypes.map((t) => DropdownMenuItem<String>(
                value: t,
                child: Text(t, style: _inter(size: 13, color: _onSurface)),
              )).toList(),
              onChanged: (v) => setState(() => _axleType = v),
            ),

            const SizedBox(height: 10),
            _FieldLabel(label: 'Wheels'),
            const SizedBox(height: 6),
            _DropdownField<int>(
              value: _numberOfWheels,
              hint: 'Select number of wheels',
              items: _wheelOptions.map((w) => DropdownMenuItem<int>(
                value: w,
                child: Text('$w wheels', style: _inter(size: 13, color: _onSurface)),
              )).toList(),
              onChanged: (v) => setState(() => _numberOfWheels = v),
            ),

            ], // end step 1 content
            )), // end step 1 Expanded+ListView
            // ═══════════════════════════════════════════════════════════
            // STEP 2 · BIDDING AMOUNT
            // ═══════════════════════════════════════════════════════════
            if (_currentStep == 2) Expanded(child: ListView(
              controller: _scrollCtrl2,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [

            _SectionHeader(label: 'Bidding Amount'),
            const SizedBox(height: 4),
            Text('Set your offline bid / booking amount to the vehicle provider',
                style: _inter(size: 12, color: _secondary)),
            const SizedBox(height: 20),

            _FieldLabel(key: _keyBookingAmount, label: 'Vehicle Provider Booking Amount (₹) *'),
            const SizedBox(height: 6),
            _TextInput(
              hasError: _fieldErr['bookingAmount'] == true,
              controller: _bookingAmountCtrl,
              hint: 'e.g. 42000  (offline bid sent to vehicle provider)',
              inputType: TextInputType.number,
            ),
            _inlineErr('bookingAmount'),

            ], // end step 2 content
            )), // end step 2 Expanded+ListView
            // ── API error banner (trip creation failed) ───────────────
            if (_submitError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _errorClr.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: _errorClr, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_submitError!, style: _inter(size: 13, color: _errorClr))),
                  ]),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _StepBottomBar(
          currentStep: _currentStep,
          submitting: _submitting,
          onBack: _goBack,
          onNext: _goNext,
          onSubmit: _submit,
        ),
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
    return Row(children: [
      Container(width: 3, height: 16,
          decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: _manrope(size: 14, weight: FontWeight.w800, color: _onSurface)),
    ]);
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) =>
      Text(label, style: _inter(size: 12, weight: FontWeight.w500, color: _secondary));
}

// ── Read-only display field (phone etc.) ──────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String value;
  final IconData icon;
  const _ReadOnlyField({required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F4F6),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _border),
    ),
    child: Row(children: [
      Icon(icon, size: 16, color: _secondary),
      const SizedBox(width: 8),
      Text(value, style: _inter(size: 13, weight: FontWeight.w500, color: _secondary)),
    ]),
  );
}

// ── City / Material search field ──────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool loading;
  final bool confirmed;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.loading,
    required this.confirmed,
    required this.onChanged,
    required this.onClear,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = confirmed
        ? _successClr.withOpacity(0.6)
        : (hasError ? _errorClr : _border);
    final double borderWidth = (confirmed || hasError) ? 1.5 : 1;
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Row(children: [
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
      ]),
    );
  }
}

// ── Results dropdown card ─────────────────────────────────────────────────────

class _ResultsCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String labelKey;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _ResultsCard({required this.items, required this.labelKey, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: _divider),
          itemBuilder: (_, i) => InkWell(
            onTap: () => onSelect(items[i]),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Text(items[i][labelKey] as String? ?? '', style: _inter(size: 13, color: _onSurface)),
            ),
          ),
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
  final bool hasError;

  const _WeightRow({
    required this.controller,
    required this.unit,
    required this.units,
    required this.onUnitChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _TextInput(
          hasError: hasError,
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
    ]);
  }
}

// ── Text input ────────────────────────────────────────────────────────────────

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType inputType;
  final bool hasError;

  const _TextInput({
    required this.controller,
    required this.hint,
    this.inputType = TextInputType.text,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError ? _errorClr : _border,
          width: hasError ? 1.5 : 1,
        ),
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

// ── Text input with character counter ────────────────────────────────────────

class _CountedTextInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLength;

  const _CountedTextInput({
    required this.controller,
    required this.hint,
    required this.maxLength,
  });

  @override
  State<_CountedTextInput> createState() => _CountedTextInputState();
}

class _CountedTextInputState extends State<_CountedTextInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.controller.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: TextField(
            controller: widget.controller,
            maxLength: widget.maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            style: _inter(size: 13, color: _onSurface),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: _inter(size: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              isDense: true,
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Max ${widget.maxLength} characters   $count/${widget.maxLength}',
          style: _inter(size: 11, color: _secondary),
        ),
      ],
    );
  }
}

// ── Generic dropdown ──────────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool hasError;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Container(
      decoration: BoxDecoration(
        color: disabled ? const Color(0xFFF2F4F6) : _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError ? _errorClr : _border,
          width: hasError ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: _inter(size: 13, color: _secondary)),
          isExpanded: true,
          menuMaxHeight: 220,
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

// ── Checkbox row ──────────────────────────────────────────────────────────────

class _CheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _CheckboxRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(
      width: 20, height: 20,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: _primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: _secondary),
      ),
    ),
    const SizedBox(width: 10),
    Text(label, style: _inter(size: 13, color: _onSurface)),
  ]);
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  static const _labels = ['Trip Info', 'Vehicle', 'Bidding'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final done    = i < current;
        final active  = i == current;
        final circleColor = done ? _successClr : active ? _primary : const Color(0xFFCDD1D4);
        final labelColor  = active ? _primary : done ? _successClr : _secondary;
        return Expanded(
          child: Row(children: [
            Column(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                      : Text('${i + 1}',
                          style: _manrope(size: 13, weight: FontWeight.w700,
                              color: active ? Colors.white : const Color(0xFF546067))),
                ),
              ),
              const SizedBox(height: 4),
              Text(_labels[i], style: _inter(size: 11, weight: FontWeight.w500, color: labelColor)),
            ]),
            if (i < 2)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 18),
                  color: i < current ? _successClr : const Color(0xFFCDD1D4),
                ),
              ),
          ]),
        );
      }),
    );
  }
}

// ── Step-aware bottom bar ─────────────────────────────────────────────────────

class _StepBottomBar extends StatelessWidget {
  final int currentStep;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _StepBottomBar({
    required this.currentStep,
    required this.submitting,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(children: [
        if (currentStep > 0) ...[
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(80, 52),
            ),
            onPressed: submitting ? null : onBack,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _secondary),
              const SizedBox(width: 6),
              Text('Back', style: _inter(size: 14, weight: FontWeight.w500, color: _secondary)),
            ]),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: submitting ? null : (currentStep < 2 ? onNext : onSubmit),
              child: submitting && currentStep == 2
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        currentStep < 2 ? 'Next' : 'Create Trip',
                        style: _manrope(size: 15, weight: FontWeight.w700, color: Colors.white),
                      ),
                      if (currentStep < 2) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                      ],
                    ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Loading chip ──────────────────────────────────────────────────────────────

class _LoadingChip extends StatelessWidget {
  final String label;
  const _LoadingChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F4F6),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _border),
    ),
    child: Row(children: [
      const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: _primary)),
      const SizedBox(width: 10),
      Text(label, style: _inter(size: 13)),
    ]),
  );
}

// ── Selected chip ─────────────────────────────────────────────────────────────

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
