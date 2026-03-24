import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/data/models/trip_model.dart';

// ─── Typography & Colours ─────────────────────────────────────────────────────
TextStyle _manrope(
        {double size = 14,
        FontWeight weight = FontWeight.w600,
        Color color = const Color(0xFF191C1E)}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);

TextStyle _inter(
        {double size = 13,
        FontWeight weight = FontWeight.w400,
        Color color = const Color(0xFF546067)}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

const _primary   = Color(0xFFFF6B00);
const _bg        = Color(0xFFF8F9FB);
const _surface   = Color(0xFFFFFFFF);
const _secondary = Color(0xFF546067);
const _onSurface = Color(0xFF191C1E);
const _success   = Color(0xFF006B5E);
const _border    = Color(0xFFECEEF0);

// ─── Tracking Screen ──────────────────────────────────────────────────────────

class TruckTrackingScreen extends StatefulWidget {
  final TripModel trip;

  /// Optional weigh data passed from stage 3 completion
  final String? emptyWeightKg;
  final String emptyWeightUnit;
  final String? loadedWeightKg;
  final String loadedWeightUnit;
  final String? driverName;
  final String? vehiclePlate;

  const TruckTrackingScreen({
    super.key,
    required this.trip,
    this.emptyWeightKg,
    this.emptyWeightUnit = 'tons',
    this.loadedWeightKg,
    this.loadedWeightUnit = 'tons',
    this.driverName,
    this.vehiclePlate,
  });

  @override
  State<TruckTrackingScreen> createState() => _TruckTrackingScreenState();
}

class _TruckTrackingScreenState extends State<TruckTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // Simulated status updates
  final List<_StatusEvent> _events = [];
  Timer? _simulateTimer;
  int _simulatedStep = 0;

  static const _simulatedUpdates = [
    _StatusEvent(time: 'Just now',    icon: Icons.check_circle_rounded,            color: _success,           text: 'Truck intake complete. Vehicle loaded and cleared for departure.'),
    _StatusEvent(time: '10 min ago',  icon: Icons.scale_outlined,                  color: Color(0xFF1565C0),  text: 'Loaded weight recorded at dharma kanta.'),
    _StatusEvent(time: '15 min ago',  icon: Icons.scale_outlined,                  color: Color(0xFF1565C0),  text: 'Empty truck weight recorded at dharma kanta.'),
    _StatusEvent(time: '20 min ago',  icon: Icons.security_rounded,                color: _secondary,         text: 'Security cleared. Entry permission issued.'),
    _StatusEvent(time: '25 min ago',  icon: Icons.assignment_turned_in_outlined,   color: _success,           text: 'All compliance checks passed.'),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Populate events progressively for a live feel
    _addNextEvent();
  }

  void _addNextEvent() {
    if (_simulatedStep >= _simulatedUpdates.length) return;
    _events.insert(0, _simulatedUpdates[_simulatedStep]);
    _simulatedStep++;
    if (_simulatedStep < _simulatedUpdates.length) {
      _simulateTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(_addNextEvent);
        }
      });
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simulateTimer?.cancel();
    super.dispose();
  }

  String? get _netLoad {
    final empty = double.tryParse(widget.emptyWeightKg ?? '');
    final loaded = double.tryParse(widget.loadedWeightKg ?? '');
    if (empty == null || loaded == null) return null;
    // Both weights must share the same unit for the difference to be meaningful
    if (widget.emptyWeightUnit != widget.loadedWeightUnit) return null;
    final net = loaded - empty;
    if (net <= 0) return null;
    return '${net.toStringAsFixed(widget.emptyWeightUnit == 'tons' ? 2 : 0)} ${widget.emptyWeightUnit}';
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Track Truck',
                style: _manrope(size: 15, weight: FontWeight.w800)),
            Text(trip.tripNumber,
                style: _inter(size: 11), maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withValues(alpha: 0.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Opacity(
                    opacity: _pulseAnim.value,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text('IN TRANSIT',
                    style: _inter(
                        size: 10,
                        weight: FontWeight.w700,
                        color: _primary)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Route card ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _DotNode(color: _success, icon: Icons.radio_button_checked_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(trip.origin,
                            style: _manrope(
                                size: 14, weight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(
                      children: [
                        Container(
                            width: 2,
                            height: 32,
                            color: _border),
                        const SizedBox(width: 16),
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Opacity(
                            opacity: _pulseAnim.value,
                            child: Row(
                              children: [
                                const Icon(Icons.local_shipping_rounded,
                                    color: _primary, size: 18),
                                const SizedBox(width: 6),
                                Text('In Transit',
                                    style: _inter(
                                        size: 12,
                                        weight: FontWeight.w600,
                                        color: _primary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _DotNode(color: _secondary, icon: Icons.location_on_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(trip.destination,
                            style: _manrope(
                                size: 14,
                                weight: FontWeight.w700,
                                color: _secondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Journey milestones ───────────────────────────────────────────
            Text('Journey Milestones',
                style: _manrope(size: 14, weight: FontWeight.w800)),
            const SizedBox(height: 10),
            _Milestone(
              icon: Icons.assignment_turned_in_rounded,
              title: 'Truck Intake Complete',
              subtitle: 'All 3 compliance stages passed',
              done: true,
            ),
            _Milestone(
              icon: Icons.scale_rounded,
              title: 'Weighed at Dharma Kanta',
              subtitle: _buildWeightSubtitle(),
              done: true,
            ),
            _Milestone(
              icon: Icons.local_shipping_rounded,
              title: 'In Transit',
              subtitle: '${trip.origin} → ${trip.destination}',
              done: false,
              isActive: true,
              pulseAnim: _pulseAnim,
            ),
            _Milestone(
              icon: Icons.where_to_vote_rounded,
              title: 'Delivered at Destination',
              subtitle: 'Awaiting arrival confirmation',
              done: false,
              isActive: false,
            ),
            const SizedBox(height: 16),

            // ── Trip details ────────────────────────────────────────────────
            Text('Trip Details',
                style: _manrope(size: 14, weight: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  if ((widget.vehiclePlate ?? trip.vehiclePlate) != null)
                    _DetailRow(
                      icon: Icons.directions_car_rounded,
                      label: 'Vehicle',
                      value: widget.vehiclePlate ?? trip.vehiclePlate!,
                    ),
                  if ((widget.driverName ?? trip.driverName) != null)
                    _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Driver',
                      value: widget.driverName ?? trip.driverName!,
                    ),
                  _DetailRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Load',
                    value: trip.loadItem,
                  ),
                  if (widget.emptyWeightKg?.isNotEmpty == true)
                    _DetailRow(
                      icon: Icons.scale_outlined,
                      label: 'Empty Weight',
                      value: '${widget.emptyWeightKg} ${widget.emptyWeightUnit}',
                    ),
                  if (widget.loadedWeightKg?.isNotEmpty == true)
                    _DetailRow(
                      icon: Icons.scale_rounded,
                      label: 'Loaded Weight',
                      value: '${widget.loadedWeightKg} ${widget.loadedWeightUnit}',
                    ),
                  if (_netLoad != null)
                    _DetailRow(
                      icon: Icons.straighten_rounded,
                      label: 'Net Load',
                      value: _netLoad!,
                      highlight: true,
                    ),
                  if (trip.tripAmount != null)
                    _DetailRow(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Trip Amount',
                      value:
                          '₹${trip.tripAmount!.toStringAsFixed(0)}',
                      highlight: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Live status feed ─────────────────────────────────────────────
            Row(
              children: [
                Text('Status Updates',
                    style: _manrope(size: 14, weight: FontWeight.w800)),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Opacity(
                    opacity: _pulseAnim.value,
                    child: Text('● LIVE',
                        style: _inter(
                            size: 10,
                            weight: FontWeight.w700,
                            color: _primary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: _events.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _primary),
                        ),
                      ),
                    )
                  : Column(
                      children: List.generate(_events.length, (i) {
                        final e = _events[i];
                        return _EventTile(
                          event: e,
                          isLast: i == _events.length - 1,
                        );
                      }),
                    ),
            ),

            const SizedBox(height: 20),

            // ── GPS note ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF1565C0), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Real-time GPS location tracking will be available once the driver app is connected.',
                      style: _inter(
                          size: 12, color: const Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildWeightSubtitle() {
    final e = widget.emptyWeightKg;
    final l = widget.loadedWeightKg;
    if (e == null && l == null) return 'Weights recorded';
    if (e != null && l != null) return 'Empty: ${e}kg · Loaded: ${l}kg';
    if (e != null) return 'Empty: ${e}kg';
    return 'Loaded: ${l}kg';
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _DotNode extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _DotNode({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(icon, size: 10, color: color),
    );
  }
}

class _Milestone extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final bool isActive;
  final Animation<double>? pulseAnim;

  const _Milestone({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    this.isActive = false,
    this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final Color nodeColor = done
        ? _success
        : isActive
            ? _primary
            : _secondary.withValues(alpha: 0.4);

    final Widget dot = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: done
            ? _success.withValues(alpha: 0.10)
            : isActive
                ? _primary.withValues(alpha: 0.10)
                : _border,
        shape: BoxShape.circle,
        border: Border.all(color: nodeColor, width: 1.5),
      ),
      child: Icon(
        done ? Icons.check_rounded : icon,
        color: nodeColor,
        size: 17,
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                isActive && pulseAnim != null
                    ? AnimatedBuilder(
                        animation: pulseAnim!,
                        builder: (_, __) => Opacity(
                          opacity: pulseAnim!.value,
                          child: dot,
                        ),
                      )
                    : dot,
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: done
                        ? _success.withValues(alpha: 0.3)
                        : _border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: _manrope(
                          size: 13,
                          weight: FontWeight.w700,
                          color: done
                              ? _onSurface
                              : isActive
                                  ? _primary
                                  : _secondary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: _inter(size: 12, color: _secondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: highlight ? _primary : _secondary),
          const SizedBox(width: 10),
          Text(label,
              style: _inter(size: 12, color: _secondary)),
          const Spacer(),
          Text(value,
              style: _inter(
                  size: 13,
                  weight: FontWeight.w600,
                  color: highlight ? _primary : _onSurface)),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final _StatusEvent event;
  final bool isLast;
  const _EventTile({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(event.icon, size: 14, color: event.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.text,
                        style: _inter(
                            size: 12,
                            color: _onSurface,
                            weight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(event.time,
                        style: _inter(size: 11, color: _secondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: _border),
      ],
    );
  }
}

class _StatusEvent {
  final String time;
  final IconData icon;
  final Color color;
  final String text;
  const _StatusEvent({
    required this.time,
    required this.icon,
    required this.color,
    required this.text,
  });
}
