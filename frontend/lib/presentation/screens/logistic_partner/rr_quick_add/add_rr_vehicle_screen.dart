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

/// Quick-add: register a new vehicle directly on RR. Mirrors rr_kanpur's
/// AddVehicleScreen (owner phone → company → engine model → RC number) —
/// writes straight to RR, no local RR4 database row. Requires an RR session
/// up front (checked on open, not just at submit) since even the typeahead
/// lookups here hit RR directly.
class AddRrVehicleScreen extends ConsumerStatefulWidget {
  const AddRrVehicleScreen({super.key});

  @override
  ConsumerState<AddRrVehicleScreen> createState() => _AddRrVehicleScreenState();
}

class _AddRrVehicleScreenState extends ConsumerState<AddRrVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _engineModelCtrl = TextEditingController();
  final _rcCtrl = TextEditingController();

  String? _ownerId;
  String? _engineModelId;
  String? _companyId;
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

  Future<List<Map<String, dynamic>>> _searchOwners(String q) =>
      ref.read(rrSyncApiProvider).searchRrUsers(q, _currentToken());

  Future<List<Map<String, dynamic>>> _searchEngineModels(String q) =>
      ref.read(rrSyncApiProvider).searchVehicleEngineModels(q, _currentToken());

  Future<List<Map<String, dynamic>>> _searchCompanies(String q) =>
      ref.read(rrSyncApiProvider).searchRrCompanies(q, _currentToken());

  void _onOwnerSelected(Map<String, dynamic> owner) {
    setState(() {
      _ownerId = owner['user_id'] as String?;
      _ownerCtrl.text = '${owner['name']} (${owner['phone']})';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Select an owner from the suggestions', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _error,
      ));
      return;
    }
    if (_engineModelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Select an engine model from the suggestions', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _error,
      ));
      return;
    }

    final session = await ensureRrSession(context, ref);
    if (session == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      final result = await ref.read(rrSyncApiProvider).createRrVehicle(
            rrToken: session.token,
            engineModelId: _engineModelId!,
            rcNumber: _rcCtrl.text.trim(),
            ownerUserId: _ownerId!,
            companyId: _companyId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Vehicle "${result['rc_number']}" added on RR', style: _inter(size: 13, color: Colors.white)),
        backgroundColor: _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not add vehicle. Please try again.', style: _inter(size: 13, color: Colors.white)),
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
    _companyCtrl.dispose();
    _engineModelCtrl.dispose();
    _rcCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Vehicle', style: _manrope(size: 17, color: Colors.white)), backgroundColor: _primary),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Register a new vehicle on RR', style: _inter(size: 13)),
                    const SizedBox(height: 20),
                    RrSearchField<Map<String, dynamic>>(
                      label: 'Owner Phone Number *',
                      controller: _ownerCtrl,
                      keyboardType: TextInputType.phone,
                      search: _searchOwners,
                      itemLabel: (u) => u['name'] as String? ?? '',
                      itemSubtitle: (u) => u['phone'] as String? ?? '',
                      onSelected: _onOwnerSelected,
                      onCleared: () => setState(() { _ownerId = null; }),
                    ),
                    const SizedBox(height: 16),
                    RrSearchField<Map<String, dynamic>>(
                      label: 'Company (optional)',
                      controller: _companyCtrl,
                      search: _searchCompanies,
                      itemLabel: (c) => c['name'] as String? ?? '',
                      onSelected: (c) {
                        setState(() {
                          _companyId = c['company_id'] as String?;
                          _companyCtrl.text = c['name'] as String? ?? '';
                        });
                      },
                      onCleared: () => setState(() { _companyId = null; }),
                    ),
                    const SizedBox(height: 16),
                    RrSearchField<Map<String, dynamic>>(
                      label: 'Engine Model *',
                      controller: _engineModelCtrl,
                      search: _searchEngineModels,
                      itemLabel: (m) => m['name'] as String? ?? '',
                      onSelected: (m) {
                        setState(() {
                          _engineModelId = m['engine_model_id'] as String?;
                          _engineModelCtrl.text = m['name'] as String? ?? '';
                        });
                      },
                      onCleared: () => setState(() { _engineModelId = null; }),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rcCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'RC Number *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'RC number is required' : null,
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
                            : Text('Add Vehicle', style: _manrope(size: 14, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
