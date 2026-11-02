import 'package:fleet_management/l10n/app_localizations.dart';

/// Display labels for vehicle and driver values stored in English (status, type,
/// fuel, license class, role). The stored value is what is sent to the API; only
/// what the user sees is translated. An unknown value is shown as it is.

String vehicleStatusLabel(AppLocalizations l10n, String value) {
  switch (value.toLowerCase()) {
    case 'active': return l10n.vehListStatusActive;
    case 'maintenance': return l10n.vehListStatusMaintenance;
    case 'inactive': return l10n.vehListStatusInactive;
    default: return value;
  }
}

String vehicleTypeLabel(AppLocalizations l10n, String value) {
  switch (value.toLowerCase()) {
    case 'car': return l10n.vehAddTypeCar;
    case 'truck': return l10n.vehAddTypeTruck;
    case 'van': return l10n.vehAddTypeVan;
    case 'bus': return l10n.vehAddTypeBus;
    case 'motorcycle': return l10n.vehAddTypeMotorcycle;
    case 'suv': return l10n.vehAddTypeSuv;
    case 'other': return l10n.vehAddTypeOther;
    default: return value;
  }
}

String fuelTypeLabel(AppLocalizations l10n, String value) {
  switch (value.toLowerCase()) {
    case 'diesel': return l10n.vehAddFuelDiesel;
    case 'petrol': return l10n.vehAddFuelPetrol;
    case 'electric': return l10n.vehAddFuelElectric;
    case 'hybrid': return l10n.vehAddFuelHybrid;
    case 'cng': return l10n.vehAddFuelCng;
    case 'lpg': return l10n.vehAddFuelLpg;
    default: return value;
  }
}

/// Driver list filter keys ('All', 'Active', 'On Leave', 'Available') and the
/// driver status values ('active', 'on_leave', 'terminated', other = available).
String driverStatusLabel(AppLocalizations l10n, String value) {
  switch (value.toLowerCase().replaceAll(' ', '_')) {
    case 'all': return l10n.drvMgmtStatusAll;
    case 'active': return l10n.drvMgmtStatusActive;
    case 'on_leave': return l10n.drvMgmtStatusOnLeave;
    case 'terminated': return l10n.drvMgmtStatusTerminated;
    case 'available': return l10n.drvMgmtStatusAvailable;
    default: return value;
  }
}

String licenseClassLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'LMV': return l10n.drvAddLicenseLmv;
    case 'HMV': return l10n.drvAddLicenseHmv;
    case 'MCWG': return l10n.drvAddLicenseMcwg;
    case 'HPMV': return l10n.drvAddLicenseHpmv;
    default: return value;
  }
}

String driverSystemRoleLabel(AppLocalizations l10n, String value) {
  switch (value) {
    case 'driver': return l10n.roleDriver;
    case 'logistics': return l10n.drvAddRoleLogistics;
    case 'support': return l10n.drvAddRoleSupport;
    default: return value;
  }
}
