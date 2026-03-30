import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/auth_provider.dart';

/// Load Owner Worker Dashboard — Coming Soon
class LoadOwnerWorkerDashboard extends ConsumerWidget {
  const LoadOwnerWorkerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.fullName.split(' ').first ?? 'Worker';

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
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF546067)),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
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
                'Welcome, $name!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Load Owner Worker Dashboard',
                style: TextStyle(
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
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF546067),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your load owner worker workspace is being built. Check back soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
