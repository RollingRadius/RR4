import 'package:fleet_management/data/models/user_model.dart';
import 'package:fleet_management/core/constants/app_constants.dart';

/// Single source of truth for "where does this user's own dashboard live" —
/// shared by the router's auth-aware redirect (splash / bounce-from-login)
/// and login_screen.dart's post-login navigation, so the two can never drift
/// out of sync with each other.
String dashboardRouteFor(UserModel user) {
  if (user.isLoadReceiver) return AppConstants.routeLoadReceiverHome;
  if (user.isLpRrOperations) return AppConstants.routeLpRrOperationsHome;
  if (user.isLogisticPartnerWorker) return AppConstants.routeLogisticPartnerWorkerHome;
  if (user.isLoadOwnerWorker) return AppConstants.routeLoadOwnerWorkerHome;
  if (user.isLoadOwner) return AppConstants.routeLoadOwnerHome;
  if (user.isTransporter) return AppConstants.routeTransporterHome;
  if (user.isDriver) return '/driver/home';
  return AppConstants.routeDashboard;
}
