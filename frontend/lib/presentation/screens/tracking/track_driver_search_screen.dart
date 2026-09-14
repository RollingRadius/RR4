import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fleet_management/data/models/driver_model.dart';
import 'package:fleet_management/providers/driver_provider.dart';
import 'package:fleet_management/presentation/screens/tracking/driver_locate_screen.dart';

const _primary = Color(0xFFFF6B00);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _bg = Color(0xFFF8F9FB);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFECEEF0);

TextStyle _manrope({double size = 14, FontWeight weight = FontWeight.w600, Color color = _onSurface}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
TextStyle _inter({double size = 13, FontWeight weight = FontWeight.w400, Color color = _secondary}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

/// Sidebar "Track" feature — LP/RR-ops search their org's drivers by phone
/// number and jump into a live, driver-centric map (DriverLocateScreen),
/// independent of any specific trip.
class TrackDriverSearchScreen extends ConsumerStatefulWidget {
  const TrackDriverSearchScreen({super.key});

  @override
  ConsumerState<TrackDriverSearchScreen> createState() => _TrackDriverSearchScreenState();
}

class _TrackDriverSearchScreenState extends ConsumerState<TrackDriverSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;
  List<DriverModel> _results = [];
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(trimmed));
  }

  Future<void> _search(String phone) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(driverApiProvider).getDrivers(phoneSearch: phone, limit: 20);
      final drivers = (data['drivers'] as List<dynamic>)
          .map((e) => DriverModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _results = drivers;
          _loading = false;
          _searched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
          _searched = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Track', style: _manrope(size: 17, weight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search by driver phone number',
                hintStyle: _inter(size: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: _secondary, size: 20),
                filled: true,
                fillColor: _surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                  borderSide: const BorderSide(color: _primary),
                ),
              ),
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to search drivers: $_error',
              style: _inter(size: 13), textAlign: TextAlign.center),
        ),
      );
    }
    if (!_searched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search_rounded, size: 48, color: _secondary),
              const SizedBox(height: 12),
              Text('Type a driver\'s phone number to find and track them live',
                  style: _inter(size: 13), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text('No drivers found for that number', style: _inter(size: 13)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final driver = _results[i];
        return _DriverResultCard(
          driver: driver,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DriverLocateScreen(
                driverId: driver.driverId,
                driverName: driver.fullName,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DriverResultCard extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback onTap;
  const _DriverResultCard({required this.driver, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initials = driver.fullName.trim().split(RegExp(r'\s+')).take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initials, style: _manrope(size: 14, weight: FontWeight.w800, color: _primary)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(driver.fullName, style: _manrope(size: 14, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(driver.phone, style: _inter(size: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _secondary),
          ],
        ),
      ),
    );
  }
}
