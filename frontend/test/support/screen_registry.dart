import 'package:flutter/widgets.dart';
import 'package:fleet_management/presentation/screens/auth/login_screen.dart';
import 'package:fleet_management/presentation/screens/auth/code_verification_screen.dart';
import 'package:fleet_management/presentation/screens/auth/email_verification_screen.dart';
import 'package:fleet_management/presentation/screens/auth/password_recovery_screen.dart';
import 'package:fleet_management/presentation/screens/auth/profile_completion_screen.dart';
import 'package:fleet_management/presentation/screens/auth/security_questions_screen.dart';
import 'package:fleet_management/presentation/screens/auth/signup_screen.dart';
import 'package:fleet_management/presentation/screens/company/company_create_screen.dart';
import 'package:fleet_management/presentation/screens/company/company_search_screen.dart';
import 'package:fleet_management/presentation/screens/company/company_selection_screen.dart';
import 'package:fleet_management/presentation/screens/driver/driver_home_screen.dart';
import 'package:fleet_management/presentation/screens/driver/driver_vehicle_screen.dart';
import 'package:fleet_management/presentation/screens/drivers/add_driver_screen.dart';
import 'package:fleet_management/presentation/screens/drivers/assignment_confirmed_screen.dart';
import 'package:fleet_management/presentation/screens/drivers/driver_management_screen.dart';
import 'package:fleet_management/presentation/screens/drivers/driver_onboarding_screen.dart';
import 'package:fleet_management/presentation/screens/drivers/onboarding_success_screen.dart';
import 'package:fleet_management/presentation/screens/drivers/select_vehicle_screen.dart';
import 'package:fleet_management/presentation/screens/help/help_center_screen.dart';
import 'package:fleet_management/presentation/screens/load_owner/load_owner_dashboard_screen.dart';
import 'package:fleet_management/presentation/screens/load_owner/load_owner_worker_dashboard.dart';
import 'package:fleet_management/presentation/screens/load_owner/upload_load_requirement_screen.dart';
import 'package:fleet_management/presentation/screens/load_receiver/load_receiver_dashboard.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/logistic_partner_dashboard.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/logistic_partner_worker_dashboard.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/lp_rr_ops_dashboard.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/lp_workers_screen.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/rr_quick_add/add_market_vehicle_screen.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/rr_quick_add/add_rr_company_screen.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/rr_quick_add/add_rr_user_screen.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/rr_quick_add/add_rr_vehicle_screen.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/rr_quick_add/vehicle_hire_requests_screen.dart';
import 'package:fleet_management/presentation/screens/organizations/create_organization_screen.dart';
import 'package:fleet_management/presentation/screens/organizations/organization_selector_screen.dart';
import 'package:fleet_management/presentation/screens/profile/change_password_screen.dart';
import 'package:fleet_management/presentation/screens/profile/profile_screen.dart';
import 'package:fleet_management/presentation/screens/receiving_documents/receiving_documents_screen.dart';
import 'package:fleet_management/presentation/screens/settings/settings_screen.dart';
import 'package:fleet_management/presentation/screens/trips/create_trip_screen.dart';
import 'package:fleet_management/presentation/screens/vehicles/add_vehicle_screen.dart';
import 'package:fleet_management/presentation/screens/vehicles/vehicles_list_screen.dart';
import 'package:fleet_management/presentation/screens/worker_requests/worker_requests_screen.dart';

/// Screens under lib/presentation/screens that the Hindi overflow test builds.
/// Key: path relative to lib/presentation/screens. Value: how to build it with
/// only the fake login and GPS providers.
///
/// A screen file must be in exactly one of [coveredScreens] or [skippedScreens];
/// test/screen_guard_test.dart fails on any screen file that is in neither.
final Map<String, Widget Function()> coveredScreens = {
  'auth/login_screen.dart': () => const LoginScreen(),
  'auth/code_verification_screen.dart': () => const CodeVerificationScreen(),
  'auth/email_verification_screen.dart': () => const EmailVerificationScreen(),
  'auth/password_recovery_screen.dart': () => const PasswordRecoveryScreen(),
  'auth/profile_completion_screen.dart': () => const ProfileCompletionScreen(),
  'auth/security_questions_screen.dart': () => const SecurityQuestionsScreen(),
  'auth/signup_screen.dart': () => const SignupScreen(),
  'company/company_create_screen.dart': () => const CompanyCreateScreen(),
  'company/company_search_screen.dart': () => const CompanySearchScreen(),
  'company/company_selection_screen.dart': () => const CompanySelectionScreen(),
  'driver/driver_home_screen.dart': () => const DriverHomeScreen(),
  'driver/driver_vehicle_screen.dart': () => const DriverVehicleScreen(),
  'drivers/add_driver_screen.dart': () => const AddDriverScreen(),
  'drivers/assignment_confirmed_screen.dart': () =>
      const AssignmentConfirmedScreen(),
  'drivers/driver_management_screen.dart': () => const DriverManagementScreen(),
  'drivers/driver_onboarding_screen.dart': () => const DriverOnboardingScreen(),
  'drivers/onboarding_success_screen.dart': () =>
      const OnboardingSuccessScreen(),
  'drivers/select_vehicle_screen.dart': () => const SelectVehicleScreen(),
  'help/help_center_screen.dart': () => const HelpCenterScreen(),
  'load_owner/load_owner_dashboard_screen.dart': () =>
      const LoadOwnerDashboardScreen(),
  'load_owner/load_owner_worker_dashboard.dart': () =>
      const LoadOwnerWorkerDashboard(),
  'load_owner/upload_load_requirement_screen.dart': () =>
      const UploadLoadRequirementScreen(),
  'load_receiver/load_receiver_dashboard.dart': () =>
      const LoadReceiverDashboard(),
  'logistic_partner/logistic_partner_dashboard.dart': () =>
      const LogisticPartnerDashboard(),
  'logistic_partner/logistic_partner_worker_dashboard.dart': () =>
      const LogisticPartnerWorkerDashboard(),
  'logistic_partner/lp_rr_ops_dashboard.dart': () => const LpRrOpsDashboard(),
  'logistic_partner/lp_workers_screen.dart': () => const LpWorkersScreen(),
  'logistic_partner/rr_quick_add/add_market_vehicle_screen.dart': () =>
      const AddMarketVehicleScreen(),
  'logistic_partner/rr_quick_add/add_rr_company_screen.dart': () =>
      const AddRrCompanyScreen(),
  'logistic_partner/rr_quick_add/add_rr_user_screen.dart': () =>
      const AddRrUserScreen(),
  'logistic_partner/rr_quick_add/add_rr_vehicle_screen.dart': () =>
      const AddRrVehicleScreen(),
  'logistic_partner/rr_quick_add/vehicle_hire_requests_screen.dart': () =>
      const VehicleHireRequestsScreen(),
  'organizations/create_organization_screen.dart': () =>
      const CreateOrganizationScreen(),
  'organizations/organization_selector_screen.dart': () =>
      const OrganizationSelectorScreen(),
  'profile/change_password_screen.dart': () => const ChangePasswordScreen(),
  'profile/profile_screen.dart': () => const ProfileScreen(),
  'receiving_documents/receiving_documents_screen.dart': () =>
      const ReceivingDocumentsScreen(),
  'settings/settings_screen.dart': () => const SettingsScreen(),
  'trips/create_trip_screen.dart': () => const CreateTripScreen(),
  'vehicles/add_vehicle_screen.dart': () => const AddVehicleScreen(),
  'vehicles/vehicles_list_screen.dart': () => const VehiclesListScreen(),
  'worker_requests/worker_requests_screen.dart': () =>
      const WorkerRequestsScreen(),
};

/// Screens deliberately not built by the overflow test, with the reason.
/// A reason starting with "TODO" is a gap to close later; any other reason is a
/// final decision. Moving a screen to [coveredScreens] removes it from here.
const Map<String, String> skippedScreens = {
  'drivers/driver_details_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'drivers/drivers_list_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'expenses/attachment_viewer_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'expenses/expense_details_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'expenses/expense_form_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'expenses/expense_summary_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'expenses/expenses_list_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'fleet_owner/trip_stages_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'fleet_owner/vehicle_management_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'help/enhanced_help_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'help/help_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'home/dashboard_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'invoices/invoice_details_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'invoices/invoice_form_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'invoices/invoice_pdf_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'invoices/invoices_list_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'invoices/send_invoice_dialog.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'load_owner/shipment_details_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'logistic_partner/rr_sync_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'organization/employees_tab.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'organization/organization_dashboard.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'organization/organization_overview_tab.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'organization/pending_requests_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'profile/role_selection_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'vehicles/vehicle_details_screen.dart':
      'Dead code: nothing in the live app builds it (see md/HINDI_LOCALIZATION_PLAN.md, scope rule).',
  'settings/branding_settings_screen.dart':
      'Not used: a route exists but nothing navigates to it.',
  'vehicles/vehicle_analytics_screen.dart':
      'Not used: a route exists but nothing navigates to it.',
  'load_owner/my_trips_screen.dart':
      'Not used: a route exists but nothing navigates to it.',
  'fleet/fleet_hub_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'maintenance/digital_inspection_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'maintenance/maintenance_history_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'maintenance/schedule_maintenance_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'maintenance_supervisor/ms_inventory_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'maintenance_supervisor/ms_maintenance_history_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'maintenance_supervisor/ms_parts_request_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'maintenance_supervisor/ms_review_onboarding_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'maintenance_supervisor/ms_schedule_confirmed_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'maintenance_supervisor/ms_work_orders_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'reports/fuel_consumption_report_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'reports/reports_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'shared/truck_tracking_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'tracking/driver_history_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'tracking/driver_locate_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'tracking/geofence_alerts_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'tracking/geofence_management_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'tracking/live_tracking_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'tracking/route_optimizer_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'tracking/track_driver_search_screen.dart':
      'Not translated yet (Hindi Phase 6, paused). Add to the overflow list when translated.',
  'splash/splash_screen.dart':
      'Splash: drawing and timing code with no translated text (it has its own splash tests).',
  'splash/splash_animation/splash_animation.dart':
      'Splash: drawing and timing code with no translated text (it has its own splash tests).',
  'splash/splash_animation/splash_logo_geometry.dart':
      'Splash: drawing and timing code with no translated text (it has its own splash tests).',
  'splash/splash_animation/splash_painter.dart':
      'Splash: drawing and timing code with no translated text (it has its own splash tests).',
  'splash/splash_animation/splash_quality.dart':
      'Splash: drawing and timing code with no translated text (it has its own splash tests).',
  'splash/splash_animation/splash_sprites.dart':
      'Splash: drawing and timing code with no translated text (it has its own splash tests).',
  'splash/splash_animation/splash_timeline.dart':
      'Splash: drawing and timing code with no translated text (it has its own splash tests).',
  'splash/splash_animation/splash_trails.dart':
      'Splash: drawing and timing code with no translated text (it has its own splash tests).',
  'auth/username_recovery_screen.dart':
      'TODO needs setup: changes a provider while building; needs a provider fake.',
  'driver/driver_dashboard_screen.dart':
      'TODO needs setup: needs the GPS fake to implement checkPermission.',
  'drivers/driver_dashboard_screen.dart':
      'TODO needs setup: needs a driverId argument and API data.',
  'fleet_owner/rr_trip_stages_screen.dart':
      'TODO needs setup: needs a trip object and API data.',
  'home/main_screen.dart': 'TODO needs setup: needs a router and a child page.',
  'organizations/organization_management_screen.dart':
      'TODO needs setup: needs organization arguments and API data.',
  'roles/create_custom_role_screen.dart': 'TODO needs setup: needs a GoRouter.',
  'roles/custom_roles_screen.dart': 'TODO needs setup: needs a GoRouter.',
  'roles/edit_custom_role_screen.dart':
      'TODO needs setup: needs a role id and a GoRouter.',
  'transporter/transporter_dashboard.dart':
      'TODO needs setup: fails with the fake login user; needs a fuller user fake.',
  'trips/trip_detail_screen.dart':
      'TODO needs setup: needs a trip argument and API data.',
  'trips/trip_locate_screen.dart':
      'TODO needs setup: needs a trip argument and map/network data.',
};
