import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_management/l10n/app_localizations.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/presentation/widgets/rr_search_field.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// RR-blue for header/brand surfaces (matches the RR-ops dashboard these
// quick-add screens are opened from), orange reserved for the primary CTA —
// same blue+orange split used across the rest of the RR-ops UI, instead of
// this screen being all-orange on its own.
const _rrBlue = Color(0xFF1B6CA8);
const _accent = Color(0xFFFF6B00);
const _secondary = Color(0xFF546067);
const _success = Color(0xFF2E7D32);
const _error = Color(0xFFBA1A1A);

// Mirrors RR's `UserOrCompanyTypes` enum (rrbc-api/app/enum_directory.py).
// "Vehicle Owner" is the default since that's what makes a company usable as
// a trip's vehicle provider — any of the others remain selectable if needed.
// Sent to RR as-is; display text comes from _businessTypeLabel().
const _businessTypes = <String>[
  'Vehicle Owner',
  'Transporter',
  'Vehicle Agent',
  'Commission Agent',
  'Parcel Sender - Consignor',
  'Parcel Sender Agent - Consignor Commission Agent',
  'Parcel Receiver - Consignee',
  'Parcel Receiver Agent - Consignee Commission Agent',
  'Driver',
  'Other',
];

String _businessTypeLabel(AppLocalizations l10n, String t) {
  switch (t) {
    case 'Vehicle Owner': return l10n.rrQuickAddBizVehicleOwner;
    case 'Transporter': return l10n.rrQuickAddBizTransporter;
    case 'Vehicle Agent': return l10n.rrQuickAddBizVehicleAgent;
    case 'Commission Agent': return l10n.rrQuickAddBizCommissionAgent;
    case 'Parcel Sender - Consignor': return l10n.rrQuickAddBizParcelSender;
    case 'Parcel Sender Agent - Consignor Commission Agent': return l10n.rrQuickAddBizParcelSenderAgent;
    case 'Parcel Receiver - Consignee': return l10n.rrQuickAddBizParcelReceiver;
    case 'Parcel Receiver Agent - Consignee Commission Agent': return l10n.rrQuickAddBizParcelReceiverAgent;
    case 'Driver': return l10n.rrQuickAddBizDriver;
    case 'Other': return l10n.rrQuickAddBizOther;
    default: return t;
  }
}

TextStyle _manrope({double size = 14, FontWeight weight = FontWeight.w700, Color color = const Color(0xFF191C1E)}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
TextStyle _inter({double size = 13, FontWeight weight = FontWeight.w400, Color color = _secondary}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

/// Quick-add: register a new company (vehicle provider) directly on RR.
/// Mirrors rr_kanpur's AddCompanyScreen (owner → name → city → business type).
class AddRrCompanyScreen extends ConsumerStatefulWidget {
  const AddRrCompanyScreen({super.key});

  @override
  ConsumerState<AddRrCompanyScreen> createState() => _AddRrCompanyScreenState();
}

class _AddRrCompanyScreenState extends ConsumerState<AddRrCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  String? _ownerId;
  String? _cityId;
  String _businessType = _businessTypes.first;
  bool _submitting = false;

  Future<List<Map<String, dynamic>>> _searchOwners(String q) =>
      runRrAction(context, ref, () => ref.read(rrSyncApiProvider).searchRrUsers(q));

  Future<List<Map<String, dynamic>>> _searchCities(String q) async {
    final resp = await ref.read(rrSyncApiProvider).dio.get('/api/rr/cities', queryParameters: {'q': q});
    final items = (resp.data['items'] as List? ?? []).cast<Map<String, dynamic>>();
    return items;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    if (_cityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.rrQuickAddSelectCity, style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _error,
      ));
      return;
    }
    final ownerPhone = _ownerId == null ? _ownerCtrl.text.trim() : null;
    if (_ownerId == null && !RegExp(r'^\d{10}$').hasMatch(ownerPhone ?? '')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.rrQuickAddOwnerOrPhone, style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _error,
      ));
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await runRrAction(context, ref, () => ref.read(rrSyncApiProvider).createRrCompany(
            name: _nameCtrl.text.trim(),
            cityId: _cityId!,
            businessType: _businessType,
            ownerUserId: _ownerId,
            newOwnerPhone: _ownerId == null ? ownerPhone : null,
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.rrQuickAddCompanyAdded('${result['name']}'), style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(apiServiceProvider).handleError(e), style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _ownerCtrl.dispose();
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rrQuickAddCompanyTitle, style: _manrope(size: 17, color: Colors.white)), backgroundColor: _rrBlue),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.rrQuickAddCompanyIntro, style: _inter(size: 13)),
                    const SizedBox(height: 20),
                    RrSearchField<Map<String, dynamic>>(
                      label: l10n.rrQuickAddCompanyOwnerLabel,
                      hintText: l10n.rrQuickAddPhoneSearchHint,
                      controller: _ownerCtrl,
                      keyboardType: TextInputType.phone,
                      search: _searchOwners,
                      itemLabel: (u) => u['name'] as String? ?? '',
                      itemSubtitle: (u) => u['phone'] as String? ?? '',
                      onSelected: (u) {
                        setState(() {
                          _ownerId = u['user_id'] as String?;
                          _ownerCtrl.text = '${u['name']} (${u['phone']})';
                        });
                      },
                      onCleared: () => setState(() { _ownerId = null; }),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.companyCreateNameLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? l10n.rrQuickAddCompanyNameRequired : null,
                    ),
                    const SizedBox(height: 16),
                    RrSearchField<Map<String, dynamic>>(
                      label: l10n.companyCreateCityLabel,
                      controller: _cityCtrl,
                      search: _searchCities,
                      itemLabel: (c) => c['name'] as String? ?? '',
                      onSelected: (c) {
                        setState(() {
                          _cityId = c['rr_city_id'] as String?;
                          _cityCtrl.text = c['name'] as String? ?? '';
                        });
                      },
                      onCleared: () => setState(() { _cityId = null; }),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _businessType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.rrQuickAddBusinessTypeLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _businessTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(_businessTypeLabel(l10n, t), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _businessType = v ?? _businessTypes.first),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(l10n.rrQuickAddAddCompanyButton, style: _manrope(size: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
