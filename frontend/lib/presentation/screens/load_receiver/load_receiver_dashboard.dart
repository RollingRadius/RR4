import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

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

const _accent = Color(0xFF00796B);   // teal — distinct from LP orange and RR blue


class LoadReceiverDashboard extends ConsumerWidget {
  const LoadReceiverDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.fullName ?? 'Load Receiver',
                    style: _manrope(size: 14)),
                Text('Load Receiver',
                    style: _inter(size: 11, color: _accent)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Color(0xFF546067)),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppConstants.routeLogin);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 72, color: Colors.teal[100]),
              const SizedBox(height: 24),
              Text('Load Receiver Dashboard',
                  style: _manrope(size: 20, weight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text(
                'Your incoming deliveries will appear here.',
                style: _inter(size: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
