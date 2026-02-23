import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/data/models/role_model.dart';
import 'package:fleet_management/providers/role_provider.dart';
import 'package:fleet_management/core/animations/app_animations.dart';
import 'package:intl/intl.dart';

class PendingRequestsScreen extends ConsumerStatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  ConsumerState<PendingRequestsScreen> createState() =>
      _PendingRequestsScreenState();
}

class _PendingRequestsScreenState
    extends ConsumerState<PendingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(rolesProvider.notifier).loadPendingRequests(),
    );
  }

  String _timeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _handleApprove(PendingRoleRequest request,
      {String? customRoleId}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text(
          customRoleId != null
              ? 'Approve ${request.userName} with a different role?'
              : 'Approve ${request.userName} for "${request.requestedRole?.name ?? "this role"}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(rolesProvider.notifier)
          .approveRoleRequest(
            request.userOrganizationId,
            approvedRoleId: customRoleId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              success ? 'User approved successfully' : 'Failed to approve'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
      }
    }
  }

  Future<void> _handleReject(PendingRoleRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Request'),
        content: Text('Reject ${request.userName}\'s request to join?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(rolesProvider.notifier)
          .rejectRoleRequest(request.userOrganizationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Request rejected' : 'Failed to reject'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ));
      }
    }
  }

  Future<void> _handleChangeRole(PendingRoleRequest request) async {
    await ref.read(rolesProvider.notifier).loadAvailableRoles();
    final rolesState = ref.read(rolesProvider);
    if (!mounted) return;

    final selectedRoleId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Different Role'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: rolesState.roles.length,
            itemBuilder: (context, index) {
              final role = rolesState.roles[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(role.roleName, style: const TextStyle(fontSize: 14)),
                subtitle: role.description != null
                    ? Text(role.description!,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12))
                    : null,
                onTap: () => Navigator.pop(dialogContext, role.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedRoleId != null) {
      await _handleApprove(request, customRoleId: selectedRoleId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rolesState = ref.watch(rolesProvider);

    if (rolesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rolesState.error != null) {
      return _buildErrorState(rolesState.error!);
    }

    if (rolesState.pendingRequests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(rolesProvider.notifier).loadPendingRequests(),
      child: PageEntrance(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: rolesState.pendingRequests.length,
          itemBuilder: (context, index) {
            final request = rolesState.pendingRequests[index];
            return StaggeredItem(
              index: index,
              staggerMs: 70,
              child: _RequestCard(
                request: request,
                timeAgo: _timeAgo(request.joinedAt),
                onApprove: () => _handleApprove(request),
                onReject: () => _handleReject(request),
                onChangeRole: () => _handleChangeRole(request),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 52, color: Colors.green),
          ),
          const SizedBox(height: 20),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending join requests',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(rolesProvider.notifier).loadPendingRequests(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Request Card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final PendingRoleRequest request;
  final String timeAgo;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onChangeRole;

  const _RequestCard({
    required this.request,
    required this.timeAgo,
    required this.onApprove,
    required this.onReject,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial =
        request.userName.isNotEmpty ? request.userName[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.orange.withOpacity(0.15),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${request.username}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                // Time ago
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_outlined,
                        size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Contact + requested role
            Row(
              children: [
                if (request.email != null) ...[
                  Icon(Icons.email_outlined,
                      size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.email!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else if (request.phone != null) ...[
                  Icon(Icons.phone_outlined,
                      size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.phone!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            if (request.requestedRole != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: theme.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_outlined,
                        size: 14, color: theme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'Requested: ${request.requestedRole!.name}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onChangeRole,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Change Role'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Approve'),
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
