import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/organization_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class OrganizationSelectorScreen extends ConsumerStatefulWidget {
  const OrganizationSelectorScreen({super.key});

  @override
  ConsumerState<OrganizationSelectorScreen> createState() =>
      _OrganizationSelectorScreenState();
}

class _OrganizationSelectorScreenState
    extends ConsumerState<OrganizationSelectorScreen> {
  String? _switchingOrgId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated && authState.token != null) {
        ref.read(organizationProvider.notifier).loadOrganizations();
      }
    });
  }

  Future<void> _switchOrg(Map<String, dynamic> org) async {
    final orgId = org['organization_id'] as String;
    setState(() => _switchingOrgId = orgId);

    final success = await ref
        .read(organizationProvider.notifier)
        .switchOrganization(orgId);

    if (success && mounted) {
      await ref.read(authProvider.notifier).refreshToken();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Switched to ${org['organization_name']}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } else if (mounted) {
      setState(() => _switchingOrgId = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to switch organization'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgState = ref.watch(organizationProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: theme.primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Select Organization',
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_business_outlined,
                    color: Colors.white),
                tooltip: 'Create Organization',
                onPressed: () => context.push('/organizations/create'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context, authState),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          if (orgState.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (orgState.error != null)
            SliverFillRemaining(
              child: _buildErrorState(context, orgState.error!),
            )
          else if (orgState.organizations.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(context),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Your Organizations',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${orgState.activeOrganizations.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final org = orgState.activeOrganizations[index];
                    final isSelected = org['organization_id'] ==
                        orgState.currentOrganizationId;
                    final isPending = org['status'] != 'active';
                    final isSwitching =
                        _switchingOrgId == org['organization_id'];

                    return StaggeredItem(
                      index: index,
                      staggerMs: 70,
                      child: _OrgCard(
                        org: org,
                        isSelected: isSelected,
                        isPending: isPending,
                        isSwitching: isSwitching,
                        onTap: (isPending || isSelected || isSwitching)
                            ? null
                            : () => _switchOrg(org),
                      ),
                    );
                  },
                  childCount: orgState.activeOrganizations.length,
                ),
              ),
            ),
            // ── Create Org CTA ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeSlide(
                delay: orgState.activeOrganizations.length * 70 + 100,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: _CreateOrgCard(
                    onTap: () => context.push('/organizations/create'),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic authState) {
    final theme = Theme.of(context);
    final user = authState.user;
    final fullName = user?.fullName ?? '';
    final username = user?.username ?? '';
    final initial =
        fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.business_center_outlined,
              size: 160,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          // Content
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fullName.isNotEmpty ? fullName : 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
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

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business_outlined,
                size: 52,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Organizations Yet',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Create your own or ask an admin to add you to an existing organization.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.push('/organizations/create'),
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text('Create Organization'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref
                  .read(organizationProvider.notifier)
                  .loadOrganizations(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Org Card ─────────────────────────────────────────────────────────────────

class _OrgCard extends StatelessWidget {
  final Map<String, dynamic> org;
  final bool isSelected;
  final bool isPending;
  final bool isSwitching;
  final VoidCallback? onTap;

  const _OrgCard({
    required this.org,
    required this.isSelected,
    required this.isPending,
    required this.isSwitching,
    required this.onTap,
  });

  Color _orgColor(String name) {
    const colors = [
      Color(0xFF1565C0), // blue
      Color(0xFF2E7D32), // green
      Color(0xFF6A1B9A), // purple
      Color(0xFF00838F), // teal
      Color(0xFFE65100), // deep orange
      Color(0xFF37474F), // blue grey
      Color(0xFFC62828), // red
      Color(0xFF0277BD), // light blue
    ];
    final idx = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orgName =
        org['organization_name'] as String? ?? 'Unknown';
    final role = org['role'] as String? ?? 'No Role';
    final initial = orgName.isNotEmpty ? orgName[0].toUpperCase() : '?';
    final color = _orgColor(orgName);

    Color borderColor;
    Color? cardColor;
    if (isSelected) {
      borderColor = Colors.green;
      cardColor = Colors.green.withOpacity(0.04);
    } else if (isPending) {
      borderColor = Colors.orange.withOpacity(0.5);
      cardColor = Colors.orange.withOpacity(0.03);
    } else {
      borderColor = theme.dividerColor.withOpacity(0.4);
      cardColor = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Org avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: color.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orgName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.green[800]
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.badge_outlined,
                            size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          role,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Pending Approval',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right indicator
              if (isSwitching)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      size: 14, color: Colors.white),
                )
              else if (isPending)
                Icon(Icons.lock_clock_outlined,
                    size: 20, color: Colors.orange[400])
              else
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 15, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Create Org Card ──────────────────────────────────────────────────────────

class _CreateOrgCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateOrgCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
          color: theme.primaryColor.withOpacity(0.04),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_business_outlined,
                  color: theme.primaryColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Organization',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Set up your own fleet organization',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 15, color: theme.primaryColor),
          ],
        ),
      ),
    );
  }
}
