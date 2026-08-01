/// Connected/Disconnected badge + Connect/Disconnect button for the org's
/// RR session — shown on LP and RR-ops dashboards (never FE, who can't hold
/// RR credentials). Fetches status on mount; "Connect" opens the RR login
/// dialog explicitly (this is the one place doing so pre-emptively makes
/// sense — it's a deliberate user action, not a side effect of some other
/// task); "Disconnect" clears the org's session after confirming.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/rr_sync_provider.dart';
import 'package:fleet_management/presentation/widgets/rr_login_dialog.dart';

const _connectedColor = Color(0xFF2E7D32);
const _connectedBg = Color(0xFFE8F5E9);
const _disconnectedColor = Color(0xFF546067);
const _disconnectedBg = Color(0xFFF1F3F4);
const _warningColor = Color(0xFFB25E00);
const _warningBg = Color(0xFFFFF3E0);

TextStyle _inter({double size = 12, FontWeight weight = FontWeight.w600, Color color = _disconnectedColor}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

class RrConnectionStatus extends ConsumerStatefulWidget {
  const RrConnectionStatus({super.key});

  @override
  ConsumerState<RrConnectionStatus> createState() => _RrConnectionStatusState();
}

class _RrConnectionStatusState extends ConsumerState<RrConnectionStatus> {
  bool _loading = true;
  bool _busy = false;
  bool _connected = false;
  bool _expiringSoon = false;

  bool get _canManageRr {
    final user = ref.read(authProvider).user;
    return user?.roleKey == 'logistic_partner' || user?.isLpRrOperations == true;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final status = await ref.read(rrSyncApiProvider).getConnectionStatus();
      if (!mounted) return;
      setState(() {
        _connected = status['connected'] == true;
        _expiringSoon = status['expiring_soon'] == true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      final session = await ensureRrSession(context, ref);
      if (session != null) await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Disconnect from RR?', style: _inter(size: 15, weight: FontWeight.w700, color: Colors.black87)),
        content: Text(
          'Sync and pre-fill will stop working for everyone at your company until someone reconnects.',
          style: _inter(size: 13, color: _disconnectedColor),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Disconnect')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(rrSyncApiProvider).disconnectRr();
      if (!mounted) return;
      setState(() {
        _connected = false;
        _expiringSoon = false;
      });
    } catch (_) {
      // Best-effort — status will self-correct on the next refresh either way.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManageRr) return const SizedBox.shrink();
    if (_loading) {
      return const SizedBox(
        height: 28, width: 28,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final Color fg;
    final Color bg;
    final IconData icon;
    final String label;
    if (!_connected) {
      fg = _disconnectedColor; bg = _disconnectedBg; icon = Icons.link_off_rounded; label = 'Disconnected';
    } else if (_expiringSoon) {
      fg = _warningColor; bg = _warningBg; icon = Icons.warning_amber_rounded; label = 'Expiring Soon';
    } else {
      fg = _connectedColor; bg = _connectedBg; icon = Icons.link_rounded; label = 'Connected';
    }

    return GestureDetector(
      onTap: _busy ? null : (_connected ? _disconnect : _connect),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              SizedBox(height: 13, width: 13, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
            else
              Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(label, style: _inter(color: fg)),
            const SizedBox(width: 4),
            Text(
              _connected ? '· Disconnect' : '· Connect',
              style: _inter(size: 11, weight: FontWeight.w500, color: fg.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }
}
