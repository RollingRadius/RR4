import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/auth_provider.dart';

// ─── Provider: pending worker count (watched by drawers for badge) ────────────

/// Fetches the count of pending worker join requests for this owner's org.
/// Returns 0 silently on error (non-owner users, network issues, etc.).
final pendingWorkerCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/api/organization/worker-requests');
    final data = response.data as Map<String, dynamic>;
    return (data['count'] as int? ?? 0);
  } catch (_) {
    return 0;
  }
});

// ─── Typography ───────────────────────────────────────────────────────────────

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

// ─── Colours ──────────────────────────────────────────────────────────────────
const _primary = Color(0xFFFF6B00);
const _bg = Color(0xFFF8F9FB);
const _surface = Color(0xFFFFFFFF);
const _secondary = Color(0xFF546067);
const _onSurface = Color(0xFF191C1E);
const _success = Color(0xFF006B5E);
const _error = Color(0xFFBA1A1A);
const _successBg = Color(0xFFE0F2EE);

// ─── Screen ───────────────────────────────────────────────────────────────────

class WorkerRequestsScreen extends ConsumerStatefulWidget {
  const WorkerRequestsScreen({super.key});

  @override
  ConsumerState<WorkerRequestsScreen> createState() =>
      _WorkerRequestsScreenState();
}

class _WorkerRequestsScreenState extends ConsumerState<WorkerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _accepted = [];
  bool _loading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final dio = ref.read(dioProvider);

      // Pending
      final pendingRes = await dio.get('/api/organization/worker-requests');
      final pendingData = pendingRes.data as Map<String, dynamic>;

      // Accepted workers (employees with worker role keys)
      final acceptedRes = await dio.get(
        '/api/organization/employees',
        queryParameters: {'status_filter': 'active'},
      );
      final acceptedData = acceptedRes.data as Map<String, dynamic>;

      if (mounted) {
        final allActive =
            List<Map<String, dynamic>>.from(acceptedData['employees'] ?? []);
        // Filter to only worker roles
        const workerRoles = [
          'logistic_partner_worker',
          'lp_rr_operations',
          'load_owner_worker'
        ];
        setState(() {
          _pending =
              List<Map<String, dynamic>>.from(pendingData['requests'] ?? []);
          _accepted = allActive.where((e) {
            final roleKey = (e['role'] as Map?)?['key'] as String?;
            return roleKey != null && workerRoles.contains(roleKey);
          }).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = e.toString();
        });
      }
    }
  }

  Future<void> _accept(String userOrgId,
      {String? requestedRoleKey, String? requestedRoleName}) async {
    // Accept immediately grants the role the worker requested (or the
    // owner's override picked directly on the card's role badge, if any) —
    // no confirmation dialog in the way. The org is already fixed: this
    // pending row was created against this owner's organization the moment
    // the worker applied to join it, Accept doesn't "assign" that part.
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/api/organization/worker-requests/$userOrgId/accept',
        data: {if (requestedRoleKey != null) 'role_key': requestedRoleKey},
      );
      ref.invalidate(pendingWorkerCountProvider);
      _fetchAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Worker accepted!',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Error: $e', style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  /// Overrides a pending request's role right away — persisted server-side
  /// immediately (not just staged locally), so it survives a refresh and a
  /// later plain Accept just uses whatever this last set.
  Future<void> _overrideRole(String userOrgId, String roleKey) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch(
        '/api/organization/worker-requests/$userOrgId/role',
        data: {'role_key': roleKey},
      );
      await _fetchAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Error: $e', style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<void> _reject(String userOrgId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Request', style: _manrope(size: 16)),
        content: Text('Are you sure you want to reject this worker request?',
            style: _inter(size: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/organization/worker-requests/$userOrgId/reject');
      ref.invalidate(pendingWorkerCountProvider);
      _fetchAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Request rejected.',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _secondary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Error: $e', style: _inter(size: 13, color: Colors.white)),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Employee Requests',
            style: _manrope(size: 18, weight: FontWeight.w800)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: _surface,
            child: TabBar(
              controller: _tabs,
              labelColor: _primary,
              unselectedLabelColor: _secondary,
              indicatorColor: _primary,
              indicatorWeight: 3,
              labelStyle:
                  _manrope(size: 13, weight: FontWeight.w700, color: _primary),
              unselectedLabelStyle: _inter(size: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Pending'),
                      if (_pending.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${_pending.length}',
                              style: _inter(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Accepted'),
                      if (_accepted.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _success,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${_accepted.length}',
                              style: _inter(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _secondary),
            onPressed: _fetchAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _errorMsg != null
              ? _ErrorView(error: _errorMsg!, onRetry: _fetchAll)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _PendingTab(
                      requests: _pending,
                      onAccept: _accept,
                      onReject: _reject,
                      onOverrideRole: _overrideRole,
                      isLoadOwnerOrg:
                          ref.watch(authProvider).user?.isLoadOwner == true,
                    ),
                    _AcceptedTab(workers: _accepted),
                  ],
                ),
    );
  }
}

// ─── Pending Tab ──────────────────────────────────────────────────────────────

class _PendingTab extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final Future<void> Function(String,
      {String? requestedRoleKey, String? requestedRoleName}) onAccept;
  final Future<void> Function(String) onReject;
  final Future<void> Function(String userOrgId, String roleKey) onOverrideRole;
  final bool isLoadOwnerOrg;

  const _PendingTab({
    required this.requests,
    required this.onAccept,
    required this.onReject,
    required this.onOverrideRole,
    required this.isLoadOwnerOrg,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_rounded, color: _primary, size: 40),
            ),
            const SizedBox(height: 16),
            Text('No pending requests',
                style: _manrope(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Worker requests will appear here.', style: _inter(size: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: requests.length,
        itemBuilder: (_, i) => _PendingCard(
          request: requests[i],
          onAccept: onAccept,
          onReject: onReject,
          onOverrideRole: onOverrideRole,
          isLoadOwnerOrg: isLoadOwnerOrg,
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final Future<void> Function(String,
      {String? requestedRoleKey, String? requestedRoleName}) onAccept;
  final Future<void> Function(String) onReject;
  final Future<void> Function(String userOrgId, String roleKey) onOverrideRole;
  final bool isLoadOwnerOrg;

  const _PendingCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.onOverrideRole,
    required this.isLoadOwnerOrg,
  });

  @override
  Widget build(BuildContext context) {
    final userOrgId = request['user_organization_id'] as String;
    final name = request['full_name'] as String? ?? 'Unknown';
    final username = request['username'] as String? ?? '';
    final phone = request['phone'] as String? ?? '';
    final joinedAt = request['joined_at'] as String? ?? '';
    final requestedRole = request['requested_role'] as Map<String, dynamic>?;
    final roleName = requestedRole?['name'] as String?;
    final roleKey = requestedRole?['key'] as String?;
    final roleUnknown = roleName == null;

    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase();

    // Parse date
    String dateStr = '';
    try {
      final dt = DateTime.parse(joinedAt).toLocal();
      dateStr =
          '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Main info row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initials,
                        style: _manrope(
                            size: 18,
                            weight: FontWeight.w800,
                            color: _primary)),
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: _manrope(size: 15, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.alternate_email_rounded,
                              size: 13, color: _secondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(username,
                                style: _inter(size: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded,
                                size: 13, color: _secondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(phone,
                                  style: _inter(size: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Role badge — tap to override (persists immediately,
                      // see onOverrideRole)
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final chosen = await showDialog<String>(
                            context: context,
                            builder: (ctx) => _RoleOverrideDialog(
                              requestedRoleKey: roleKey,
                              requestedRoleName: roleName,
                              isLoadOwnerOrg: isLoadOwnerOrg,
                            ),
                          );
                          if (chosen != null) {
                            await onOverrideRole(userOrgId, chosen);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleUnknown
                                ? _error.withOpacity(0.08)
                                : _primary.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: roleUnknown
                                    ? _error.withOpacity(0.4)
                                    : _primary.withOpacity(0.25),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (roleUnknown) ...[
                                const Icon(Icons.warning_amber_rounded,
                                    size: 12, color: _error),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                roleUnknown
                                    ? 'Role not set — tap to assign'
                                    : roleName!,
                                style: _inter(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: roleUnknown ? _error : _primary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit_outlined,
                                  size: 12,
                                  color: roleUnknown ? _error : _primary),
                            ],
                          ),
                        ),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 12, color: _secondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text('Requested: $dateStr',
                                  style: _inter(size: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Action row ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(
                top: BorderSide(color: _primary.withOpacity(0.12), width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onReject(userOrgId),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _error,
                      side: const BorderSide(color: _error, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: _inter(
                          size: 13, weight: FontWeight.w700, color: _error),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onAccept(userOrgId,
                        requestedRoleKey: roleKey, requestedRoleName: roleName),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: _inter(
                          size: 13,
                          weight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Accepted Tab ─────────────────────────────────────────────────────────────

class _AcceptedTab extends StatelessWidget {
  final List<Map<String, dynamic>> workers;
  const _AcceptedTab({required this.workers});

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _success.withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_rounded, color: _success, size: 40),
            ),
            const SizedBox(height: 16),
            Text('No accepted employees yet',
                style: _manrope(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Accepted employees will appear here.',
                style: _inter(size: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: workers.length,
      itemBuilder: (_, i) => _AcceptedCard(worker: workers[i]),
    );
  }
}

class _AcceptedCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  const _AcceptedCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    final name = worker['full_name'] as String? ?? 'Unknown';
    final username = worker['username'] as String? ?? '';
    final phone = worker['phone'] as String? ?? '';
    final role = worker['role'] as Map<String, dynamic>?;
    final roleName = role?['name'] as String? ?? 'Worker';
    final approvedAt = worker['approved_at'] as String?;
    final approvedBy = worker['approved_by'] as String?;

    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase();

    String approvedDateStr = '';
    if (approvedAt != null) {
      try {
        final dt = DateTime.parse(approvedAt).toLocal();
        approvedDateStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _success.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _successBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(initials,
                  style: _manrope(
                      size: 16, weight: FontWeight.w800, color: _success)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: _manrope(size: 14, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.alternate_email_rounded,
                      size: 12, color: _secondary),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(username,
                        style: _inter(size: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.phone_rounded,
                        size: 12, color: _secondary),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(phone,
                          style: _inter(size: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _successBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(roleName,
                            style: _inter(
                                size: 11,
                                weight: FontWeight.w700,
                                color: _success),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    if (approvedDateStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          approvedBy != null && approvedBy.isNotEmpty
                              ? 'Joined $approvedDateStr by $approvedBy'
                              : 'Joined $approvedDateStr',
                          style: _inter(size: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Active badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _successBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: _success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text('Active',
                    style: _inter(
                        size: 10, weight: FontWeight.w700, color: _success)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _error, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load requests',
                style: _manrope(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(error, style: _inter(size: 12), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Role Override Dialog ──────────────────────────────────────────────────────

class _RoleOption {
  final String key;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  const _RoleOption({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Opened by tapping the role badge on a pending request card — lets the
/// owner correct a role the worker picked by mistake at signup. Selecting a
/// role here is persisted immediately server-side (see _overrideRole in the
/// parent screen), it doesn't just stage a local choice for Accept to send
/// later.
class _RoleOverrideDialog extends StatefulWidget {
  final String? requestedRoleKey;
  final String? requestedRoleName;
  // Which role choices make sense depends on the accepting owner's own org
  // type — an LP org only ever wants Field Executive/RR Operations for its
  // team, a load_owner org only ever wants Load Owner Worker. Showing all
  // three regardless of org type let an LP owner accidentally assign
  // "Load Owner Worker" to their own team member, which isn't a valid role
  // for a logistic_partner org.
  final bool isLoadOwnerOrg;

  const _RoleOverrideDialog({
    this.requestedRoleKey,
    this.requestedRoleName,
    required this.isLoadOwnerOrg,
  });

  @override
  State<_RoleOverrideDialog> createState() => _RoleOverrideDialogState();
}

class _RoleOverrideDialogState extends State<_RoleOverrideDialog> {
  late String _selectedRole;
  late final List<_RoleOption> _roles;

  static const _lpRoles = [
    _RoleOption(
      key: 'logistic_partner_worker',
      label: 'Field Executive',
      description: 'Manages trip stages and fleet status on the ground',
      icon: Icons.badge_outlined,
      color: Color(0xFFFF6B00),
    ),
    _RoleOption(
      key: 'lp_rr_operations',
      label: 'RR Operations',
      description: 'Handles RR sync and trip data entry in the RR system',
      icon: Icons.sync_alt_rounded,
      color: Color(0xFF1B6CA8),
    ),
  ];
  static const _loadOwnerRoles = [
    _RoleOption(
      key: 'load_owner_worker',
      label: 'Load Owner Worker',
      description: 'Manages load postings and shipment tracking',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF6A4FB6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _roles = widget.isLoadOwnerOrg ? _loadOwnerRoles : _lpRoles;
    // Pre-select the requested role if valid, else default to the first
    // option for this org type.
    _selectedRole = _roles.any((r) => r.key == widget.requestedRoleKey)
        ? widget.requestedRoleKey!
        : _roles.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final roleUnknown = widget.requestedRoleKey == null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.manage_accounts_outlined,
                      size: 20, color: _primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assign Role', style: _manrope(size: 16)),
                      const SizedBox(height: 2),
                      Text(
                        roleUnknown
                            ? 'No role requested yet'
                            : 'Currently: ${widget.requestedRoleName}',
                        style: _inter(
                            size: 12, color: roleUnknown ? _error : _secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (roleUnknown)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: _error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'This worker didn\'t pick a role at signup — choose one below.',
                        style: _inter(size: 12, color: _error),
                      ),
                    ),
                  ],
                ),
              ),
            ..._roles.map((r) {
              final selected = _selectedRole == r.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedRole = r.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? r.color.withOpacity(0.08)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? r.color : Colors.grey[300]!,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: r.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(r.icon, size: 18, color: r.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.label,
                                  style: _inter(
                                      size: 13.5,
                                      weight: FontWeight.w700,
                                      color: _onSurface)),
                              const SizedBox(height: 2),
                              Text(r.description,
                                  style: _inter(size: 11.5, color: _secondary)),
                            ],
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 20,
                          color: selected ? r.color : Colors.grey[350],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Cancel',
                        style: _inter(size: 13.5, color: _secondary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context, _selectedRole),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text('Save',
                        style: _inter(
                            size: 13.5,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
