import 'package:flutter/material.dart';
import 'package:fleet_management/presentation/widgets/language_switch_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/l10n/app_localizations.dart';

/// Load Owner Worker Dashboard — Coming Soon
class LoadOwnerWorkerDashboard extends ConsumerWidget {
  const LoadOwnerWorkerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider).user;
    final name = user?.fullName.split(' ').first ?? l10n.loWorkerHomeFallbackName;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'RR LOGISTICS',
          style: TextStyle(
            color: Color(0xFFFF6B00),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          const LanguageSwitchButton(),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF546067)),
            onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(AppConstants.routeLogin);
              },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(AppConstants.routeLogin);
              },
              icon: const Icon(Icons.logout),
              label: Text(l10n.feDashLogout),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  color: Color(0xFFFF6B00),
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.loWorkerHomeWelcome(name),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.loWorkerHomeTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF6B00),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.pwRecoveryComingSoon,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF546067),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.loWorkerHomeBuilding,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF546067),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
