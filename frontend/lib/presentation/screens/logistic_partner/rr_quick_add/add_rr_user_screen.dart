import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';

const _primary = Color(0xFFFF6B00);
const _secondary = Color(0xFF546067);
const _success = Color(0xFF2E7D32);
const _error = Color(0xFFBA1A1A);

TextStyle _manrope({double size = 14, FontWeight weight = FontWeight.w700, Color color = const Color(0xFF191C1E)}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
TextStyle _inter({double size = 13, FontWeight weight = FontWeight.w400, Color color = _secondary}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

/// Quick-add: register a new driver/user directly on RR. Mirrors rr_kanpur's
/// AddUserScreen (name + phone only) — writes straight to RR, no local RR4
/// database row, since Create Trip's driver picker reads RR live anyway.
class AddRrUserScreen extends ConsumerStatefulWidget {
  const AddRrUserScreen({super.key});

  @override
  ConsumerState<AddRrUserScreen> createState() => _AddRrUserScreenState();
}

class _AddRrUserScreenState extends ConsumerState<AddRrUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final result = await runRrAction(context, ref, () => ref.read(rrSyncApiProvider).createRrUser(
            name: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Driver "${result['name']}" added on RR', style: _inter(size: 13, color: Colors.white)),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Driver', style: _manrope(size: 17, color: Colors.white)), backgroundColor: _primary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Register a new driver on RR', style: _inter(size: 13)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Enter at least 2 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) {
                  final cleaned = (v ?? '').trim();
                  if (!RegExp(r'^\d{10}$').hasMatch(cleaned)) return 'Enter exactly 10 digits';
                  return null;
                },
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
                      : Text('Add Driver', style: _manrope(size: 14, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
