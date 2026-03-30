import 'package:flutter/material.dart';
import 'package:fleet_management/presentation/screens/logistic_partner/logistic_partner_dashboard.dart';

/// Logistic Partner Worker Dashboard
///
/// Workers have the same view as the Logistic Partner dashboard for now —
/// fleet status and trip stages. They cannot search/fulfill loads independently.
class LogisticPartnerWorkerDashboard extends StatelessWidget {
  const LogisticPartnerWorkerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const LogisticPartnerDashboard(hideLoads: true);
  }
}
