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

class _PendingRequestsScreenState extends ConsumerState<PendingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Load pending requests when screen loads
    Future.microtask(
      () => ref.read(rolesProvider.notifier).loadPendingRequests(),
    );
  }

  Future<void> _handleApprove(PendingRoleRequest request,
      {String? customRoleId}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Text(
          customRoleId != null
              ? 'Approve ${request.userName} with a different role?'
              : 'Approve ${request.userName} for ${request.requestedRole?.name ?? "this role"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(rolesProvider.notifier).approveRoleRequest(
            request.userOrganizationId,
            approvedRoleId: customRoleId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'User approved successfully'
                  : 'Failed to approve request',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(PendingRoleRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Text('Reject ${request.userName}\'s request to join?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Request rejected'
                  : 'Failed to reject request',
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleChangeRole(PendingRoleRequest request) async {
    // Load available roles first
    await ref.read(rolesProvider.notifier).loadAvailableRoles();

    final rolesState = ref.read(rolesProvider);

    if (!mounted) return;

    final selectedRoleId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Different Role'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: rolesState.roles.length,
            itemBuilder: (context, index) {
              final role = rolesState.roles[index];
              return ListTile(
                title: Text(role.roleName),
                subtitle: role.description != null
                    ? Text(
                        role.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                onTap: () => Navigator.pop(context, role.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Requests'),
        elevation: 0,
      ),
      body: rolesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rolesState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        rolesState.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref
                              .read(rolesProvider.notifier)
                              .loadPendingRequests();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : rolesState.pendingRequests.isEmpty
                  ? _buildEmptyState()
                  : _buildRequestsList(rolesState.pendingRequests),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All requests have been processed',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<PendingRoleRequest> requests) {
    return PageEntrance(
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return StaggeredItem(
            index: index,
            staggerMs: 80,
            child: _buildRequestCard(request),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(PendingRoleRequest request) {
    final joinedDate = DateTime.parse(request.joinedAt);
    final formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(joinedDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    request.userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${request.username}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Contact Info
            if (request.email != null) ...[
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    request.email!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (request.phone != null) ...[
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    request.phone!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Requested Role
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.badge, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Requested Role:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.requestedRole?.name ?? 'Not specified',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Request Date
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Requested on $formattedDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReject(request),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleChangeRole(request),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleApprove(request),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
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
