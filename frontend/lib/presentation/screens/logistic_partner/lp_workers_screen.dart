import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// ─── Typography helpers ───────────────────────────────────────────────────────
TextStyle _m({double s = 14, FontWeight w = FontWeight.w600, Color c = const Color(0xFF191C1E)}) =>
    GoogleFonts.manrope(fontSize: s, fontWeight: w, color: c);
TextStyle _i({double s = 13, FontWeight w = FontWeight.w400, Color c = const Color(0xFF546067)}) =>
    GoogleFonts.inter(fontSize: s, fontWeight: w, color: c);

const _primary   = Color(0xFFFF6B00);
const _bg        = Color(0xFFF8F9FB);
const _surface   = Color(0xFFFFFFFF);
const _secondary = Color(0xFF546067);
const _onSurface = Color(0xFF191C1E);
const _success   = Color(0xFF006B5E);
const _border    = Color(0xFFECEEF0);
const _gold      = Color(0xFFF5A623);
const _silver    = Color(0xFF9B9B9B);
const _bronze    = Color(0xFFCD7F32);

// ─── Data model ───────────────────────────────────────────────────────────────
class _WorkerEntry {
  final int rank;
  final String userId;
  final String fullName;
  final String username;
  final String roleKey;
  final String roleLabel;
  final int s1, s2, s3, s4;
  final int totalStages;
  final int tripsCompleted;

  const _WorkerEntry({
    required this.rank,
    required this.userId,
    required this.fullName,
    required this.username,
    required this.roleKey,
    required this.roleLabel,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.totalStages,
    required this.tripsCompleted,
  });

  factory _WorkerEntry.fromJson(Map<String, dynamic> j) => _WorkerEntry(
        rank:           j['rank']           as int,
        userId:         j['user_id']        as String,
        fullName:       j['full_name']      as String,
        username:       j['username']       as String,
        roleKey:        j['role_key']       as String,
        roleLabel:      j['role_label']     as String,
        s1:             j['s1_count']       as int,
        s2:             j['s2_count']       as int,
        s3:             j['s3_count']       as int,
        s4:             j['s4_count']       as int,
        totalStages:    j['total_stages']   as int,
        tripsCompleted: j['trips_completed'] as int,
      );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class LpWorkersScreen extends ConsumerStatefulWidget {
  const LpWorkersScreen({super.key});

  @override
  ConsumerState<LpWorkersScreen> createState() => _LpWorkersScreenState();
}

class _LpWorkersScreenState extends ConsumerState<LpWorkersScreen> {
  String _period = 'daily';
  DateTime _selectedDate = DateTime.now();

  bool _loading = true;
  String? _error;
  List<_WorkerEntry> _leaderboard = [];
  String _dateLabel = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  String get _dateParam {
    if (_period == 'daily') {
      return '${_selectedDate.year}-'
          '${_selectedDate.month.toString().padLeft(2, '0')}-'
          '${_selectedDate.day.toString().padLeft(2, '0')}';
    } else {
      return '${_selectedDate.year}-'
          '${_selectedDate.month.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.dio.get(
        '/api/workers/leaderboard',
        queryParameters: {'period': _period, 'date': _dateParam},
      );
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _dateLabel   = data['date_label'] as String? ?? _dateParam;
        _leaderboard = (data['leaderboard'] as List<dynamic>)
            .map((e) => _WorkerEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _shiftDate(int delta) {
    setState(() {
      if (_period == 'daily') {
        _selectedDate = _selectedDate.add(Duration(days: delta));
      } else {
        final m = _selectedDate.month + delta;
        final y = _selectedDate.year + (m < 1 ? -1 : m > 12 ? 1 : 0);
        final nm = ((m - 1) % 12) + 1;
        _selectedDate = DateTime(y, nm);
      }
    });
    _fetch();
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
        title: Text('Workers', style: _m(s: 17, w: FontWeight.w800)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: Column(
        children: [
          _PeriodAndDateBar(
            period: _period,
            dateLabel: _dateLabel.isEmpty ? _dateParam : _dateLabel,
            onPeriodChanged: (p) {
              setState(() { _period = p; _selectedDate = DateTime.now(); });
              _fetch();
            },
            onPrev: () => _shiftDate(-1),
            onNext: () => _shiftDate(1),
            canGoNext: _period == 'monthly'
                ? !(_selectedDate.year == DateTime.now().year &&
                    _selectedDate.month == DateTime.now().month)
                : _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1))) ||
                  (_selectedDate.day != DateTime.now().day ||
                   _selectedDate.month != DateTime.now().month ||
                   _selectedDate.year != DateTime.now().year)
                  ? true
                  : false,
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: _primary)))
          else if (_error != null)
            Expanded(child: _ErrorView(error: _error!, onRetry: _fetch))
          else if (_leaderboard.isEmpty)
            const Expanded(child: _EmptyView())
          else
            Expanded(
              child: RefreshIndicator(
                color: _primary,
                onRefresh: _fetch,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // Podium for top 3
                    if (_leaderboard.length >= 2) ...[
                      _Podium(entries: _leaderboard.take(3).toList()),
                      const SizedBox(height: 20),
                    ],
                    // Rest of the list
                    ..._leaderboard.skip(_leaderboard.length >= 2 ? 3 : 0).map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WorkerCard(entry: e),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Period & Date Bar ────────────────────────────────────────────────────────

class _PeriodAndDateBar extends StatelessWidget {
  final String period;
  final String dateLabel;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  const _PeriodAndDateBar({
    required this.period,
    required this.dateLabel,
    required this.onPeriodChanged,
    required this.onPrev,
    required this.onNext,
    required this.canGoNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Period toggle
          Container(
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: ['daily', 'monthly'].map((p) {
                final active = period == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onPeriodChanged(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? _primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        p[0].toUpperCase() + p.substring(1),
                        textAlign: TextAlign.center,
                        style: _m(
                          s: 13,
                          w: FontWeight.w700,
                          c: active ? Colors.white : _secondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Date navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: _onSurface),
                onPressed: onPrev,
                visualDensity: VisualDensity.compact,
              ),
              Text(dateLabel, style: _m(s: 14, w: FontWeight.w700)),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded,
                    color: canGoNext ? _onSurface : _border),
                onPressed: canGoNext ? onNext : null,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Podium (top 3) ───────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<_WorkerEntry> entries;
  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    final first  = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1  ? entries[1] : null;
    final third  = entries.length > 2  ? entries[2] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text('Leaderboard', style: _m(s: 15, w: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd
              if (second != null)
                Expanded(child: _PodiumSlot(entry: second, color: _silver, height: 80))
              else
                const Expanded(child: SizedBox()),
              const SizedBox(width: 8),
              // 1st (tallest)
              if (first != null)
                Expanded(child: _PodiumSlot(entry: first, color: _gold, height: 100))
              else
                const Expanded(child: SizedBox()),
              const SizedBox(width: 8),
              // 3rd
              if (third != null)
                Expanded(child: _PodiumSlot(entry: third, color: _bronze, height: 64))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final _WorkerEntry entry;
  final Color color;
  final double height;

  const _PodiumSlot({required this.entry, required this.color, required this.height});

  String get _medal => entry.rank == 1 ? '🥇' : entry.rank == 2 ? '🥈' : '🥉';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_medal, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          entry.fullName.split(' ').first,
          style: _m(s: 11, w: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.totalStages} pts',
          style: _m(s: 12, w: FontWeight.w800, c: color),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: _m(s: 18, w: FontWeight.w900, c: color),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Worker Card (rank 4+) ────────────────────────────────────────────────────

class _WorkerCard extends StatelessWidget {
  final _WorkerEntry entry;
  const _WorkerCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _bg,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: Center(
              child: Text('#${entry.rank}', style: _m(s: 11, w: FontWeight.w800, c: _secondary)),
            ),
          ),
          const SizedBox(width: 12),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.fullName, style: _m(s: 13, w: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: entry.roleKey == 'logistic_partner'
                            ? _primary.withValues(alpha: 0.1)
                            : _success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.roleLabel,
                        style: _i(
                          s: 10,
                          w: FontWeight.w600,
                          c: entry.roleKey == 'logistic_partner' ? _primary : _success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('@${entry.username}', style: _i(s: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.totalStages} pts', style: _m(s: 15, w: FontWeight.w800, c: _primary)),
              const SizedBox(height: 3),
              Text('${entry.tripsCompleted} trips', style: _i(s: 11, c: _secondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty & Error views ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 48, color: _primary),
            ),
            const SizedBox(height: 20),
            Text('No activity yet', style: _m(s: 18, w: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'No stage submissions recorded for this period.',
              style: _i(s: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFBA1A1A), size: 48),
            const SizedBox(height: 16),
            Text('Failed to load', style: _m(s: 16, w: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(error, style: _i(s: 12), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
