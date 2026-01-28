import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/presentation/screens/auth/login_screen.dart';
import 'package:fleet_management/presentation/screens/auth/signup_screen.dart';
import 'package:fleet_management/presentation/screens/auth/email_verification_screen.dart';
import 'package:fleet_management/presentation/screens/auth/code_verification_screen.dart';
import 'package:fleet_management/presentation/screens/auth/security_questions_screen.dart';
import 'package:fleet_management/presentation/screens/auth/password_recovery_screen.dart';
import 'package:fleet_management/presentation/screens/auth/username_recovery_screen.dart';
import 'package:fleet_management/presentation/screens/auth/profile_completion_screen.dart';
import 'package:fleet_management/presentation/screens/company/company_selection_screen.dart';
import 'package:fleet_management/presentation/screens/company/company_search_screen.dart';
import 'package:fleet_management/presentation/screens/company/company_create_screen.dart';
import 'package:fleet_management/presentation/screens/home/dashboard_screen.dart';
import 'package:fleet_management/presentation/screens/home/main_screen.dart';
import 'package:fleet_management/presentation/screens/vehicles/vehicles_list_screen.dart';
import 'package:fleet_management/presentation/screens/vehicles/add_vehicle_screen.dart';
import 'package:fleet_management/presentation/screens/drivers/drivers_list_screen.dart';
import 'package:fleet_management/presentation/screens/drivers/add_driver_screen.dart';
import 'package:fleet_management/presentation/screens/organizations/organization_selector_screen.dart';
import 'package:fleet_management/presentation/screens/organizations/organization_management_screen.dart';
import 'package:fleet_management/presentation/screens/organizations/create_organization_screen.dart';
import 'package:fleet_management/presentation/screens/reports/reports_screen.dart';
import 'package:fleet_management/presentation/screens/reports/organization_summary_report_screen.dart';
import 'package:fleet_management/presentation/screens/reports/driver_list_report_screen.dart';
import 'package:fleet_management/presentation/screens/reports/license_expiry_report_screen.dart';
import 'package:fleet_management/presentation/screens/roles/custom_roles_screen.dart';
import 'package:fleet_management/presentation/screens/roles/create_custom_role_screen.dart';
import 'package:fleet_management/presentation/screens/profile/profile_screen.dart';
import 'package:fleet_management/presentation/screens/settings/settings_screen.dart';
import 'package:fleet_management/presentation/screens/help/help_screen.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

/// App Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConstants.routeLogin,
    debugLogDiagnostics: true,
    routes: [
      // Authentication Routes
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppConstants.routeSignup,
        name: 'signup',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MaterialPage(
            key: state.pageKey,
            child: EmailVerificationScreen(
              email: extra?['email'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: '/verify-code',
        name: 'verify-code',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MaterialPage(
            key: state.pageKey,
            child: CodeVerificationScreen(
              verificationCode: extra?['verification_code'] as String?,
              email: extra?['email'] as String?,
              expiresAt: extra?['expires_at'] as DateTime?,
            ),
          );
        },
      ),
      GoRoute(
        path: '/security-questions',
        name: 'security-questions',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MaterialPage(
            key: state.pageKey,
            child: SecurityQuestionsScreen(
              signupData: extra,
            ),
          );
        },
      ),
      GoRoute(
        path: '/password-recovery',
        name: 'password-recovery',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const PasswordRecoveryScreen(),
        ),
      ),
      GoRoute(
        path: '/username-recovery',
        name: 'username-recovery',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const UsernameRecoveryScreen(),
        ),
      ),
      GoRoute(
        path: '/profile-complete',
        name: 'profile-complete',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const ProfileCompletionScreen(),
        ),
      ),

      // Company Routes
      GoRoute(
        path: '/company/selection',
        name: 'company-selection',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MaterialPage(
            key: state.pageKey,
            child: CompanySelectionScreen(
              signupData: extra,
            ),
          );
        },
      ),
      GoRoute(
        path: '/company/search',
        name: 'company-search',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MaterialPage(
            key: state.pageKey,
            child: CompanySearchScreen(
              signupData: extra,
            ),
          );
        },
      ),
      GoRoute(
        path: '/company/create',
        name: 'company-create',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MaterialPage(
            key: state.pageKey,
            child: CompanyCreateScreen(
              signupData: extra,
            ),
          );
        },
      ),

      // Dashboard (with main scaffold)
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: AppConstants.routeDashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/vehicles',
            name: 'vehicles',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VehiclesListScreen(),
            ),
          ),
          GoRoute(
            path: '/vehicles/add',
            name: 'add-vehicle',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AddVehicleScreen(),
            ),
          ),
          GoRoute(
            path: '/drivers',
            name: 'drivers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DriversListScreen(),
            ),
          ),
          GoRoute(
            path: '/drivers/add',
            name: 'add-driver',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const AddDriverScreen(),
            ),
          ),
          GoRoute(
            path: '/organizations',
            name: 'organizations',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OrganizationSelectorScreen(),
            ),
          ),
          GoRoute(
            path: '/organizations/:id/manage',
            name: 'organization-management',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              final extra = state.extra as Map<String, dynamic>?;
              final name = extra?['name'] ?? 'Organization';
              return MaterialPage(
                key: state.pageKey,
                child: OrganizationManagementScreen(
                  organizationId: id,
                  organizationName: name,
                ),
              );
            },
          ),
          GoRoute(
            path: '/organizations/create',
            name: 'create-organization',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const CreateOrganizationScreen(),
            ),
          ),
          GoRoute(
            path: '/trips',
            name: 'trips',
            pageBuilder: (context, state) => NoTransitionPage(
              child: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route_outlined, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Trips', style: TextStyle(fontSize: 24, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Coming soon...', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportsScreen(),
            ),
          ),
          GoRoute(
            path: '/reports/organization-summary',
            name: 'report-organization-summary',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const OrganizationSummaryReportScreen(),
            ),
          ),
          GoRoute(
            path: '/reports/driver-list',
            name: 'report-driver-list',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const DriverListReportScreen(),
            ),
          ),
          GoRoute(
            path: '/reports/license-expiry',
            name: 'report-license-expiry',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const LicenseExpiryReportScreen(),
            ),
          ),
          GoRoute(
            path: '/roles/custom',
            name: 'custom-roles',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CustomRolesScreen(),
            ),
          ),
          GoRoute(
            path: '/roles/custom/create',
            name: 'create-custom-role',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const CreateCustomRoleScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/help',
            name: 'help',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: const HelpScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
