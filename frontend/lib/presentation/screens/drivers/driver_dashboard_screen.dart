import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/data/models/driver_model.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/driver_provider.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  final String driverId;

  const DriverDashboardScreen({super.key, required this.driverId});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState
    extends ConsumerState<DriverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(driverProvider.notifier).getDriverById(widget.driverId));
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverProvider);
    final driver = driverState.selectedDriver;
    final token = ref.watch(authProvider).token;

    if (driverState.isLoading && driver == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F6F6),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFEC5B13)),
        ),
      );
    }

    if (driver == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          ),
          title: const Text('Driver', style: TextStyle(color: AppTheme.textPrimary)),
        ),
        body: const Center(child: Text('Driver not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context, driver, token),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (driver.license != null) ...[
                    _licenseWarningBanner(driver.license!),
                    const SizedBox(height: 16),
                  ],
                  _buildInfoCard(driver),
                  const SizedBox(height: 16),
                  _buildLicenseCard(driver.license),
                  const SizedBox(height: 16),
                  _buildContactCard(driver),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sliver header ─────────────────────────────────────────────────────────

  SliverAppBar _buildSliverHeader(
      BuildContext context, DriverModel driver, String? token) {
    final statusInfo = _statusInfo(driver.status);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: const Color(0xFFEC5B13),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEC5B13), Color(0xFFB84000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar (photo if uploaded, else initial)
                      _DriverAvatar(
                        driverId: driver.driverId,
                        firstName: driver.firstName,
                        token: token,
                        size: 72,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.fullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'ID: ${driver.employeeId}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Status chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusInfo.color.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    driver.statusDisplay,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bottom stats strip
                  Row(
                    children: [
                      _HeaderStat(
                        icon: Icons.phone_rounded,
                        value: driver.phone,
                      ),
                      const SizedBox(width: 12),
                      _HeaderStat(
                        icon: Icons.flag_rounded,
                        value: driver.country,
                      ),
                      const SizedBox(width: 12),
                      _HeaderStat(
                        icon: Icons.calendar_today_rounded,
                        value: _fmtDate(driver.joinDate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Text(
        driver.fullName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ─── License warning banner ─────────────────────────────────────────────

  Widget _licenseWarningBanner(DriverLicenseModel license) {
    if (!license.isExpired && !license.isExpiringSoon) return const SizedBox();

    final isExpired = license.isExpired;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isExpired
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFFCD34D),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.error_rounded : Icons.warning_rounded,
            color: isExpired
                ? const Color(0xFFDC2626)
                : const Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isExpired
                  ? 'License expired on ${_fmtDate(license.expiryDate)}'
                  : 'License expires on ${_fmtDate(license.expiryDate)} — renew soon',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isExpired
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Personal info card ────────────────────────────────────────────────────

  Widget _buildInfoCard(DriverModel driver) {
    return _Card(
      title: 'Personal Information',
      icon: Icons.person_rounded,
      children: [
        _InfoRow(label: 'Full Name', value: driver.fullName),
        _InfoRow(label: 'Employee ID', value: driver.employeeId),
        _InfoRow(label: 'Phone', value: driver.phone),
        _InfoRow(label: 'Email', value: driver.email ?? '—'),
        _InfoRow(
          label: 'Date of Birth',
          value: driver.dateOfBirth != null
              ? _fmtDate(driver.dateOfBirth!)
              : '—',
        ),
        _InfoRow(
          label: 'Age',
          value: driver.age != null ? '${driver.age} years' : '—',
        ),
        _InfoRow(label: 'Country', value: driver.country),
        _InfoRow(
          label: 'Address',
          value: driver.fullAddress,
          isLast: true,
        ),
      ],
    );
  }

  // ─── License card ──────────────────────────────────────────────────────────

  Widget _buildLicenseCard(DriverLicenseModel? license) {
    if (license == null) {
      return _Card(
        title: 'License Details',
        icon: Icons.badge_rounded,
        children: [
          const _InfoRow(label: 'Status', value: 'No license on file', isLast: true),
        ],
      );
    }

    final daysLeft = license.expiryDate.difference(DateTime.now()).inDays;
    final expiryColor = license.isExpired
        ? const Color(0xFFDC2626)
        : license.isExpiringSoon
            ? const Color(0xFFD97706)
            : const Color(0xFF16A34A);

    return _Card(
      title: 'License Details',
      icon: Icons.badge_rounded,
      children: [
        _InfoRow(label: 'License Number', value: license.licenseNumber),
        _InfoRow(label: 'Type', value: license.licenseTypeDisplay),
        _InfoRow(label: 'Class', value: license.licenseType),
        _InfoRow(label: 'Issue Date', value: _fmtDate(license.issueDate)),
        _InfoRow(
          label: 'Expiry Date',
          value: _fmtDate(license.expiryDate),
          valueColor: expiryColor,
        ),
        _InfoRow(
          label: 'Status',
          value: license.isExpired
              ? 'Expired'
              : license.isExpiringSoon
                  ? 'Expiring in $daysLeft days'
                  : 'Valid ($daysLeft days left)',
          valueColor: expiryColor,
        ),
        if (license.issuingAuthority != null)
          _InfoRow(label: 'Authority', value: license.issuingAuthority!),
        _InfoRow(
          label: 'Issuing State',
          value: license.issuingState ?? '—',
          isLast: true,
        ),
      ],
    );
  }

  // ─── Contact / Emergency card ──────────────────────────────────────────────

  Widget _buildContactCard(DriverModel driver) {
    final hasContact = driver.emergencyContactName != null ||
        driver.emergencyContactPhone != null;

    return _Card(
      title: 'Emergency Contact',
      icon: Icons.contact_phone_rounded,
      children: hasContact
          ? [
              _InfoRow(
                label: 'Name',
                value: driver.emergencyContactName ?? '—',
              ),
              _InfoRow(
                label: 'Phone',
                value: driver.emergencyContactPhone ?? '—',
              ),
              _InfoRow(
                label: 'Relationship',
                value: driver.emergencyContactRelationship ?? '—',
                isLast: true,
              ),
            ]
          : [
              const _InfoRow(
                label: 'Status',
                value: 'No emergency contact on file',
                isLast: true,
              ),
            ],
    );
  }

  // ─── Quick Actions ────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    const actions = [
      _ActionData(
        icon: Icons.report_problem_rounded,
        label: 'Report\nIssue',
        bgColor: Color(0xFFFEE2E2),
        iconColor: Color(0xFFDC2626),
      ),
      _ActionData(
        icon: Icons.receipt_long_rounded,
        label: 'Fuel\nReceipt',
        bgColor: Color(0xFFFFF3ED),
        iconColor: Color(0xFFEC5B13),
      ),
      _ActionData(
        icon: Icons.checklist_rounded,
        label: 'Safety\nCheck',
        bgColor: Color(0xFFEFF6FF),
        iconColor: Color(0xFF3B82F6),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'QUICK ACTIONS'),
        const SizedBox(height: 10),
        Row(
          children: List.generate(actions.length, (i) {
            final a = actions[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < actions.length - 1 ? 10 : 0),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: a.bgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(a.icon, color: a.iconColor, size: 20),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  ({Color color}) _statusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return (color: const Color(0xFF16A34A));
      case 'on_leave':
        return (color: const Color(0xFF2563EB));
      case 'inactive':
        return (color: const Color(0xFF94A3B8));
      case 'terminated':
        return (color: const Color(0xFFDC2626));
      default:
        return (color: const Color(0xFF94A3B8));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Circular avatar that shows the driver's uploaded photo (bytea served via
/// GET /api/drivers/{id}/photo) or falls back to their name initial.
class _DriverAvatar extends StatelessWidget {
  final String driverId;
  final String firstName;
  final String? token;
  final double size;

  const _DriverAvatar({
    required this.driverId,
    required this.firstName,
    required this.token,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl =
        '${AppConfig.apiBaseUrl}/api/drivers/$driverId/photo';
    final headers =
        token != null ? {'Authorization': 'Bearer $token'} : <String, String>{};

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: ClipOval(
        child: Image.network(
          photoUrl,
          headers: headers,
          fit: BoxFit.cover,
          width: size,
          height: size,
          // While loading, show the initial letter
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _initial(firstName, size);
          },
          // On error (no photo uploaded yet), show the initial letter
          errorBuilder: (_, __, ___) => _initial(firstName, size),
        ),
      ),
    );
  }

  Widget _initial(String name, double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.white.withOpacity(0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC5B13).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon,
                      color: const Color(0xFFEC5B13), size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 16, endIndent: 16,
              color: Color(0xFFF8FAFC)),
      ],
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _HeaderStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;

  const _ActionData({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
  });
}
