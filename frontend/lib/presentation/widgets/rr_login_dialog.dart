import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/data/services/rr_sync_api.dart';
import 'package:fleet_management/providers/rr_session_provider.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';

// ─── Typography helpers ───────────────────────────────────────────────────────

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

// ─── Colour tokens ────────────────────────────────────────────────────────────

const _primary = Color(0xFFFF6B00);
const _secondary = Color(0xFF546067);

// ─── Helper — call before any RR operation ────────────────────────────────────

/// Returns the current valid [RrSession], showing the login dialog if needed.
/// Returns null if the user cancels or login fails.
Future<RrSession?> ensureRrSession(BuildContext context, WidgetRef ref) async {
  final session = ref.read(rrSessionProvider);
  if (session != null && session.isValid) return session;

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const RrLoginDialog(),
  );
  if (ok != true) return null;
  return ref.read(rrSessionProvider);
}

// ─── Dialog widget ────────────────────────────────────────────────────────────

/// Shared RR login dialog — collects RR credentials, calls POST /api/rr/auth/login,
/// stores the result in [rrSessionProvider], and pops with `true` on success.
class RrLoginDialog extends ConsumerStatefulWidget {
  const RrLoginDialog({super.key});

  @override
  ConsumerState<RrLoginDialog> createState() => _RrLoginDialogState();
}

class _RrLoginDialogState extends ConsumerState<RrLoginDialog> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Enter your RR username and password');
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final result = await ref.read(rrSyncApiProvider).loginToRr(username, password);
      ref.read(rrSessionProvider.notifier).setSession(
        token: result.token,
        rrUserId: result.rrUserId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['detail'] ?? 'Login failed')
          : 'Login failed';
      setState(() {
        _errorMsg = msg.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Unexpected error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Sign in to RR',
          style: _manrope(size: 16, weight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter your RollingRadius credentials to continue.',
              style: _inter(size: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameCtrl,
            decoration: InputDecoration(
              labelText: 'Username / Phone',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            enabled: !_loading,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _loading ? null : _submit(),
            enabled: !_loading,
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 10),
            Text(_errorMsg!,
                style: _inter(size: 12, color: const Color(0xFFBA1A1A))),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: _inter(size: 14, color: _secondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _primary),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text('Sign in',
                  style: _manrope(size: 14, color: Colors.white)),
        ),
      ],
    );
  }
}
