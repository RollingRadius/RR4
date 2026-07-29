/// Remembers the last trip's entered field values so Create Trip can
/// pre-fill on next open, instead of starting blank — mirrors rr_kanpur's
/// `LastTripData` (`SharedPref.saveLastTripData`/`getLastTripData`). This is
/// a pure convenience cache, not a resumable draft of the same trip: it has
/// no trip id, and submitting from a pre-filled form always creates a new,
/// separate trip (same as rr_kanpur — confirmed it has no edit/resume path).
///
/// Vehicle and driver ARE cached too, matching rr_kanpur's own
/// `LastTripData` exactly (it caches `vehicleId`/`vehicleNumber`/
/// `driverId`/`driverName`) — the same "remember everything from last time"
/// convenience applies uniformly, not selectively.
class LastTripData {
  final String? consignorName;
  final String? consignorRrCompanyId;
  final String? consignorGstin;
  final String? consigneeName;
  final String? consigneeRrCompanyId;
  final String? consigneeGstin;
  final String? pickupCityName;
  final String? pickupCityId;
  final String? dropCityName;
  final String? dropCityId;
  final String? materialName;
  final String? materialRrId;
  final String? weight;
  final String? invoiceValue;
  final String? pickupLine1;
  final String? pickupLine2;
  final String? pickupPin;
  final String? unloadLine1;
  final String? unloadLine2;
  final String? unloadPin;
  final String? depotCode;
  final String? vehicleBodyType;
  final String? axleType;
  final int? numberOfWheels;
  final String? vpPhone;
  final String? vpCompanyId;
  final String? vpCompanyName;
  final String? vehicleId;
  final String? vehicleNumber;
  final String? driverId;
  final String? driverName;
  final String? expectedFreight;
  final String? bookingAmount;
  final String? opsWorkerLocalId;

  const LastTripData({
    this.consignorName,
    this.consignorRrCompanyId,
    this.consignorGstin,
    this.consigneeName,
    this.consigneeRrCompanyId,
    this.consigneeGstin,
    this.pickupCityName,
    this.pickupCityId,
    this.dropCityName,
    this.dropCityId,
    this.materialName,
    this.materialRrId,
    this.weight,
    this.invoiceValue,
    this.pickupLine1,
    this.pickupLine2,
    this.pickupPin,
    this.unloadLine1,
    this.unloadLine2,
    this.unloadPin,
    this.depotCode,
    this.vehicleBodyType,
    this.axleType,
    this.numberOfWheels,
    this.vpPhone,
    this.vpCompanyId,
    this.vpCompanyName,
    this.vehicleId,
    this.vehicleNumber,
    this.driverId,
    this.driverName,
    this.expectedFreight,
    this.bookingAmount,
    this.opsWorkerLocalId,
  });

  Map<String, dynamic> toJson() => {
        'consignorName': consignorName,
        'consignorRrCompanyId': consignorRrCompanyId,
        'consignorGstin': consignorGstin,
        'consigneeName': consigneeName,
        'consigneeRrCompanyId': consigneeRrCompanyId,
        'consigneeGstin': consigneeGstin,
        'pickupCityName': pickupCityName,
        'pickupCityId': pickupCityId,
        'dropCityName': dropCityName,
        'dropCityId': dropCityId,
        'materialName': materialName,
        'materialRrId': materialRrId,
        'weight': weight,
        'invoiceValue': invoiceValue,
        'pickupLine1': pickupLine1,
        'pickupLine2': pickupLine2,
        'pickupPin': pickupPin,
        'unloadLine1': unloadLine1,
        'unloadLine2': unloadLine2,
        'unloadPin': unloadPin,
        'depotCode': depotCode,
        'vehicleBodyType': vehicleBodyType,
        'axleType': axleType,
        'numberOfWheels': numberOfWheels,
        'vpPhone': vpPhone,
        'vpCompanyId': vpCompanyId,
        'vpCompanyName': vpCompanyName,
        'vehicleId': vehicleId,
        'vehicleNumber': vehicleNumber,
        'driverId': driverId,
        'driverName': driverName,
        'expectedFreight': expectedFreight,
        'bookingAmount': bookingAmount,
        'opsWorkerLocalId': opsWorkerLocalId,
      };

  factory LastTripData.fromJson(Map<String, dynamic> json) => LastTripData(
        consignorName: json['consignorName'] as String?,
        consignorRrCompanyId: json['consignorRrCompanyId'] as String?,
        consignorGstin: json['consignorGstin'] as String?,
        consigneeName: json['consigneeName'] as String?,
        consigneeRrCompanyId: json['consigneeRrCompanyId'] as String?,
        consigneeGstin: json['consigneeGstin'] as String?,
        pickupCityName: json['pickupCityName'] as String?,
        pickupCityId: json['pickupCityId'] as String?,
        dropCityName: json['dropCityName'] as String?,
        dropCityId: json['dropCityId'] as String?,
        materialName: json['materialName'] as String?,
        materialRrId: json['materialRrId'] as String?,
        weight: json['weight'] as String?,
        invoiceValue: json['invoiceValue'] as String?,
        pickupLine1: json['pickupLine1'] as String?,
        pickupLine2: json['pickupLine2'] as String?,
        pickupPin: json['pickupPin'] as String?,
        unloadLine1: json['unloadLine1'] as String?,
        unloadLine2: json['unloadLine2'] as String?,
        unloadPin: json['unloadPin'] as String?,
        depotCode: json['depotCode'] as String?,
        vehicleBodyType: json['vehicleBodyType'] as String?,
        axleType: json['axleType'] as String?,
        numberOfWheels: json['numberOfWheels'] as int?,
        vpPhone: json['vpPhone'] as String?,
        vpCompanyId: json['vpCompanyId'] as String?,
        vpCompanyName: json['vpCompanyName'] as String?,
        vehicleId: json['vehicleId'] as String?,
        vehicleNumber: json['vehicleNumber'] as String?,
        driverId: json['driverId'] as String?,
        driverName: json['driverName'] as String?,
        expectedFreight: json['expectedFreight'] as String?,
        bookingAmount: json['bookingAmount'] as String?,
        opsWorkerLocalId: json['opsWorkerLocalId'] as String?,
      );
}
