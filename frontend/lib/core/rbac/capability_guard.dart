/// RBAC capability guard widgets and helpers.
///
/// Usage:
///   // Widget-level guard
///   CapabilityGuard(
///     capability: 'vehicle.create',
///     requiredLevel: 'full',
///     child: AddVehicleButton(),
///   )
///
///   // Role-level guard (cheaper — no API call needed)
///   FleetOwnerGuard(child: VehicleManagementScreen())

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/capability_provider.dart';

// ─── Capability-level guard ───────────────────────────────────────────────────

/// Shows [child] only when the current user has [capability] at [requiredLevel].
/// Shows [fallback] (defaults to nothing) otherwise.
///
/// For fleet-owner-only capabilities (vehicle.*, driver.*, etc.) prefer
/// [FleetOwnerGuard] — it avoids the async capability fetch.
class CapabilityGuard extends ConsumerWidget {
  final String capability;
  final String requiredLevel;
  final Widget child;
  final Widget fallback;

  const CapabilityGuard({
    super.key,
    required this.capability,
    this.requiredLevel = 'view',
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capState = ref.watch(capabilityProvider);

    // While capabilities haven't loaded yet, hide the child.
    if (capState.myCapabilities == null) return fallback;

    final allowed = capState.myCapabilities!.containsKey(capability) &&
        _levelPasses(
          capState.myCapabilities![capability]['access_level'] as String,
          requiredLevel,
        );

    return allowed ? child : fallback;
  }

  static bool _levelPasses(String has, String needs) {
    const h = {'none': 0, 'view': 1, 'limited': 2, 'full': 3};
    return (h[has] ?? 0) >= (h[needs] ?? 0);
  }
}

// ─── Role-level guards ────────────────────────────────────────────────────────

/// Shows [child] only for users with role_key == 'fleet_owner'.
/// Cheaper than [CapabilityGuard] — reads from already-loaded auth state.
class FleetOwnerGuard extends ConsumerWidget {
  final Widget child;
  final Widget fallback;

  const FleetOwnerGuard({
    super.key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return (user?.isFleetOwner == true) ? child : fallback;
  }
}

/// Shows [child] only for users with role_key == 'load_owner'.
class LoadOwnerGuard extends ConsumerWidget {
  final Widget child;
  final Widget fallback;

  const LoadOwnerGuard({
    super.key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return (user?.isLoadOwner == true) ? child : fallback;
  }
}

// ─── Convenience: vehicle-specific guards ────────────────────────────────────

class CanViewVehicles extends ConsumerWidget {
  final Widget child;
  final Widget fallback;
  const CanViewVehicles(
      {super.key, required this.child, this.fallback = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FleetOwnerGuard(child: child, fallback: fallback).build(context, ref);
}

class CanCreateVehicles extends ConsumerWidget {
  final Widget child;
  final Widget fallback;
  const CanCreateVehicles(
      {super.key, required this.child, this.fallback = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FleetOwnerGuard(child: child, fallback: fallback).build(context, ref);
}

class CanEditVehicles extends ConsumerWidget {
  final Widget child;
  final Widget fallback;
  const CanEditVehicles(
      {super.key, required this.child, this.fallback = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FleetOwnerGuard(child: child, fallback: fallback).build(context, ref);
}

class CanDeleteVehicles extends ConsumerWidget {
  final Widget child;
  final Widget fallback;
  const CanDeleteVehicles(
      {super.key, required this.child, this.fallback = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FleetOwnerGuard(child: child, fallback: fallback).build(context, ref);
}

class CanAssignVehicles extends ConsumerWidget {
  final Widget child;
  final Widget fallback;
  const CanAssignVehicles(
      {super.key, required this.child, this.fallback = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FleetOwnerGuard(child: child, fallback: fallback).build(context, ref);
}

class CanManageVehicleDocs extends ConsumerWidget {
  final Widget child;
  final Widget fallback;
  const CanManageVehicleDocs(
      {super.key, required this.child, this.fallback = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FleetOwnerGuard(child: child, fallback: fallback).build(context, ref);
}

// ─── Utility: programmatic capability check ───────────────────────────────────

/// Returns whether [user] has [roleKey].
bool userHasRole(dynamic user, String roleKey) =>
    (user?.roleKey as String?) == roleKey;

/// Quick check — use in initState or redirect logic.
bool isFleetOwnerUser(dynamic user) =>
    user?.isFleetOwner == true;

bool isLoadOwnerUser(dynamic user) =>
    user?.isLoadOwner == true;
