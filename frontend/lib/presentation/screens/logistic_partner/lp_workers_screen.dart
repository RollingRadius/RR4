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

// ─── Data models ──────────────────────────────────────────────────────────────

class _WorkerInfo {
  final String userId, fullName, username, phone, roleKey, roleLabel;
  const _WorkerInfo({
    required this.userId, required this.fullName, required this.username,
    required this.phone,  required this.roleKey,  required this.roleLabel,
  });
  factory _WorkerInfo.fromJson(Map<String, dynamic> j) => _WorkerInfo(
    userId:    j['user_id']    as String,
    fullName:  j['full_name']  as String,
    username:  j['username']   as String,
    phone:     j['phone']      as String? ?? '—',
    roleKey:   j['role_key']   as String,
    roleLabel: j['role_label'] as String,
  );
}

class _WorkerEntry {
  final int rank;
  final String userId, fullName, username, phone, roleKey, roleLabel;
  final int s1, s2, s3, s4, totalStages, tripsCompleted;

  const _WorkerEntry({
    required this.rank,      required this.userId,    required this.fullName,
    required this.username,  required this.phone,     required this.roleKey,
    required this.roleLabel, required this.s1,        required this.s2,
    required this.s3,        required this.s4,        required this.totalStages,
    required this.tripsCompleted,
  });

  factory _WorkerEntry.fromJson(Map<String, dynamic> j) => _WorkerEntry(
    rank:           j['rank']            as int,
    userId:         j['user_id']         as String,
    fullName:       j['full_name']       as String,
    username:       j['username']        as String,
    phone:          j['phone']           as String? ?? '—',
    roleKey:        j['role_key']        as String,
    roleLabel:      j['role_label']      as String,
    s1:             j['s1_count']        as int,
    s2:             j['s2_count']        as int,
    s3:             j['s3_count']        as int,
    s4:             j['s4_count']        as int,
    totalStages:    j['total_stages']    as int,
    tripsCompleted: j['trips_completed'] as int,
  );
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class LpWorkersScreen extends ConsumerStatefulWidget {
  const LpWorkersScreen({super.key});

  @override
  ConsumerState<LpWorkersScreen> createState() => _LpWorkersScreenState();
}

class _LpWorkersScreenState extends ConsumerState<LpWorkersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Shared date state
  DateTime _selectedDate = DateTime.now();
  String _period = 'daily';

  // Record tab state — simple worker roster
  bool _recLoading = true;
  String? _recError;
  List<_WorkerInfo> _workers = [];

  // Leaderboard tab state
  bool _lbLoading = true;
  String? _lbError;
  List<_WorkerEntry> _leaderboard = [];
  String _lbDateLabel = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecords();
      _fetchLeaderboard();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── date helpers ──────────────────────────────────────────────────────────

  String get _dailyParam =>
      '${_selectedDate.year}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  String get _periodParam =>
      _period == 'daily'
          ? _dailyParam
          : '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';

  bool get _canGoNext {
    final now = DateTime.now();
    if (_period == 'daily') {
      return _selectedDate.isBefore(DateTime(now.year, now.month, now.day));
    } else {
      return !(_selectedDate.year == now.year && _selectedDate.month == now.month);
    }
  }

  void _shiftDate(int delta) {
    setState(() {
      if (_period == 'daily') {
        _selectedDate = _selectedDate.add(Duration(days: delta));
      } else {
        int m = _selectedDate.month + delta;
        int y = _selectedDate.year + (m < 1 ? -1 : m > 12 ? 1 : 0);
        m = ((m - 1) % 12) + 1;
        _selectedDate = DateTime(y, m);
      }
    });
    _fetchLeaderboard();
  }

  void _onPeriodChanged(String p) {
    setState(() { _period = p; _selectedDate = DateTime.now(); });
    _fetchLeaderboard();
  }

  // ── fetchers ─────────────────────────────────────────────────────────────

  Future<void> _fetchRecords() async {
    if (!mounted) return;
    setState(() { _recLoading = true; _recError = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.dio.get('/api/workers');
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _workers = (data['workers'] as List<dynamic>)
            .map((e) => _WorkerInfo.fromJson(e as Map<String, dynamic>))
            .where((w) => w.roleKey == 'logistic_partner_worker')
            .toList();
        _recLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _recLoading = false; _recError = e.toString(); });
    }
  }

  Future<void> _fetchLeaderboard() async {
    if (!mounted) return;
    setState(() { _lbLoading = true; _lbError = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.dio.get(
        '/api/workers/leaderboard',
        queryParameters: {'period': _period, 'date': _periodParam},
      );
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _lbDateLabel  = data['date_label'] as String? ?? _periodParam;
        _leaderboard  = (data['leaderboard'] as List<dynamic>)
            .map((e) => _WorkerEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        _lbLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _lbLoading = false; _lbError = e.toString(); });
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

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
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500),
          labelColor: _primary,
          unselectedLabelColor: _secondary,
          indicatorColor: _primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Record'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _RecordTab(
            loading:   _recLoading,
            error:     _recError,
            workers:   _workers,
            onRefresh: _fetchRecords,
          ),
          _LeaderboardTab(
            loading:      _lbLoading,
            error:        _lbError,
            leaderboard:  _leaderboard,
            period:       _period,
            dateLabel:    _lbDateLabel.isEmpty ? _periodParam : _lbDateLabel,
            canGoNext:    _canGoNext,
            onPeriodChanged: _onPeriodChanged,
            onPrev:       () => _shiftDate(-1),
            onNext:       () => _shiftDate(1),
            onRefresh:    _fetchLeaderboard,
          ),
        ],
      ),
    );
  }
}

// ─── Record Tab ───────────────────────────────────────────────────────────────

class _RecordTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<_WorkerInfo> workers;
  final VoidCallback onRefresh;

  const _RecordTab({
    required this.loading,   required this.error,
    required this.workers,   required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (error != null) {
      return _ErrorView(error: error!, onRetry: onRefresh);
    }
    if (workers.isEmpty) {
      return _EmptyView(
        icon: Icons.people_outline_rounded,
        title: 'No workers found',
        subtitle: 'Active workers in your organisation will appear here.',
      );
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: workers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _WorkerInfoCard(worker: workers[i]),
      ),
    );
  }
}

// ─── Worker Info Card ─────────────────────────────────────────────────────────

class _WorkerInfoCard extends StatelessWidget {
  final _WorkerInfo worker;
  const _WorkerInfoCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    final isOwner = worker.roleKey == 'logistic_partner';
    final accent  = isOwner ? _primary : _success;
    final initials = worker.fullName.trim().split(RegExp(r'\s+')).take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(initials, style: _m(s: 15, w: FontWeight.w800, c: accent)),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.fullName,
                    style: _m(s: 14, w: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.alternate_email_rounded, size: 12, color: _secondary),
                    const SizedBox(width: 4),
                    Text(worker.username, style: _i(s: 12)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 12, color: _secondary),
                    const SizedBox(width: 4),
                    Text(worker.phone, style: _i(s: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            child: Text(worker.roleLabel,
                style: _i(s: 11, w: FontWeight.w700, c: accent)),
          ),
        ],
      ),
    );
  }
}

// ─── Leaderboard Tab ──────────────────────────────────────────────────────────

class _LeaderboardTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<_WorkerEntry> leaderboard;
  final String period, dateLabel;
  final bool canGoNext;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onPrev, onNext, onRefresh;

  const _LeaderboardTab({
    required this.loading,    required this.error,
    required this.leaderboard, required this.period,
    required this.dateLabel,  required this.canGoNext,
    required this.onPeriodChanged, required this.onPrev,
    required this.onNext,     required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PeriodAndDateBar(
          period: period,
          dateLabel: dateLabel,
          onPeriodChanged: onPeriodChanged,
          onPrev: onPrev,
          onNext: onNext,
          canGoNext: canGoNext,
        ),
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: _primary)))
        else if (error != null)
          Expanded(child: _ErrorView(error: error!, onRetry: onRefresh))
        else if (leaderboard.isEmpty)
          Expanded(child: _EmptyView(
            icon: Icons.leaderboard_outlined,
            title: 'No activity yet',
            subtitle: 'No stage submissions recorded for this period.',
          ))
        else
          Expanded(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: () async => onRefresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (leaderboard.length >= 2) ...[
                    _Podium(entries: leaderboard.take(3).toList()),
                    const SizedBox(height: 20),
                  ],
                  ...leaderboard.skip(leaderboard.length >= 2 ? 3 : 0).map(
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
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _DateNavBar extends StatelessWidget {
  final String dateLabel;
  final bool canGoNext;
  final VoidCallback onPrev, onNext;
  const _DateNavBar({required this.dateLabel, required this.canGoNext,
                     required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
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
    );
  }
}

class _PeriodAndDateBar extends StatelessWidget {
  final String period, dateLabel;
  final bool canGoNext;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onPrev, onNext;

  const _PeriodAndDateBar({
    required this.period,      required this.dateLabel,
    required this.canGoNext,   required this.onPeriodChanged,
    required this.onPrev,      required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
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
                        style: _m(s: 13, w: FontWeight.w700,
                            c: active ? Colors.white : _secondary),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
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

// ─── Podium ───────────────────────────────────────────────────────────────────

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
              if (second != null)
                Expanded(child: _PodiumSlot(entry: second, color: _silver, height: 80))
              else const Expanded(child: SizedBox()),
              const SizedBox(width: 8),
              if (first != null)
                Expanded(child: _PodiumSlot(entry: first, color: _gold, height: 100))
              else const Expanded(child: SizedBox()),
              const SizedBox(width: 8),
              if (third != null)
                Expanded(child: _PodiumSlot(entry: third, color: _bronze, height: 64))
              else const Expanded(child: SizedBox()),
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
        Text(entry.fullName.split(' ').first,
            style: _m(s: 11, w: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text('${entry.totalStages} pts',
            style: _m(s: 12, w: FontWeight.w800, c: color), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Center(child: Text('#${entry.rank}',
              style: _m(s: 18, w: FontWeight.w900, c: color))),
        ),
      ],
    );
  }
}

// ─── Worker card (rank 4+) ────────────────────────────────────────────────────

class _WorkerCard extends StatelessWidget {
  final _WorkerEntry entry;
  const _WorkerCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _bg, shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: Center(child: Text('#${entry.rank}',
                style: _m(s: 11, w: FontWeight.w800, c: _secondary))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.fullName, style: _m(s: 13, w: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      child: Text(entry.roleLabel, style: _i(s: 10, w: FontWeight.w600,
                          c: entry.roleKey == 'logistic_partner' ? _primary : _success)),
                    ),
                    const SizedBox(width: 6),
                    Text('@${entry.username}', style: _i(s: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.totalStages} pts',
                  style: _m(s: 15, w: FontWeight.w800, c: _primary)),
              const SizedBox(height: 3),
              Text('${entry.tripsCompleted} trips', style: _i(s: 11, c: _secondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty & Error ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _EmptyView({required this.icon, required this.title, required this.subtitle});

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
                color: _primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: _primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: _m(s: 18, w: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(subtitle, style: _i(s: 13), textAlign: TextAlign.center),
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
                backgroundColor: _primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
