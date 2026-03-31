import 'dart:convert';

class TripModel {
  final String id;
  final String tripNumber;
  final String? biltyNumber;
  final String origin;
  final String? originSub;
  final String destination;
  final String? destinationSub;
  final String loadItem;
  final String? weight;
  final double? tripAmount;
  final String? invoiceNumber;
  final String status;
  final String organizationId;
  final String? lpOrgName;
  final String? loadOwnerOrgId;
  final String? loadOwnerOrgName;
  final String? vehicleId;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? driverId;
  final String? driverName;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? updatedAt;
  final int currentStage;

  // ── Stage 1 fields ───────────────────────────────────────────────────────────
  final String? s1DriverName;
  final String? s1DriverPhone;
  final String? s1DrivingLicense;
  final String? s1DrivingLicenseUrl;
  final String? s1Aadhaar;
  final String? s1AadhaarUrl;
  final String? s1Rc;
  final String? s1Insurance;
  final String? s1Pollution;
  final String? s1Fitness;
  final String? s1Pan;
  final String? s1TaxDeclaration;
  final String? s1CancelledCheque;

  // ── Stage 2 fields ───────────────────────────────────────────────────────────
  final bool? s2SpecsVerified;
  final bool? s2DocsVerified;
  final bool? s2DriverDocsValid;
  final bool? s2EntryPermission;
  final String? s2LoadingSlipUrl;

  // ── Stage 3 fields ───────────────────────────────────────────────────────────
  final String? s3EmptyTruckWeightKg;
  final String? s3EmptyTruckWeightUnit;
  final String? s3LoadedTruckWeightKg;
  final String? s3LoadedTruckWeightUnit;
  final String? s3BiltyUrl;
  final List<String>? s3MaterialDocUrls;

  // ── Stage 4 fields ───────────────────────────────────────────────────────────
  final bool? s4TruckMoved;
  final bool? s4SecurityVerified;
  final bool? s4BiltyChecked;
  final bool? s4WeightChecked;
  final bool? s4MaterialChecked;
  final String? s4CompletedAt;
  final String? s4NotifiedAt;

  // ── Stage authorship (who submitted each stage) ───────────────────────────────
  final String? s1SubmittedBy;
  final String? s2SubmittedBy;
  final String? s3SubmittedBy;
  final String? s4SubmittedBy;

  // ── Stage claims (who is currently working on each stage) ─────────────────────
  final String? s1ClaimedBy;
  final String? s2ClaimedBy;
  final String? s3ClaimedBy;
  final String? s4ClaimedBy;

  // ── Draft (cross-device in-progress form data) ────────────────────────────────
  final Map<String, dynamic>? draftData;

  const TripModel({
    required this.id,
    required this.tripNumber,
    this.biltyNumber,
    required this.origin,
    this.originSub,
    required this.destination,
    this.destinationSub,
    required this.loadItem,
    this.weight,
    this.tripAmount,
    this.invoiceNumber,
    required this.status,
    required this.organizationId,
    this.lpOrgName,
    this.loadOwnerOrgId,
    this.loadOwnerOrgName,
    this.vehicleId,
    this.vehiclePlate,
    this.vehicleModel,
    this.driverId,
    this.driverName,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.currentStage = 0,
    this.s1DriverName,
    this.s1DriverPhone,
    this.s1DrivingLicense,
    this.s1DrivingLicenseUrl,
    this.s1Aadhaar,
    this.s1AadhaarUrl,
    this.s1Rc,
    this.s1Insurance,
    this.s1Pollution,
    this.s1Fitness,
    this.s1Pan,
    this.s1TaxDeclaration,
    this.s1CancelledCheque,
    this.s2SpecsVerified,
    this.s2DocsVerified,
    this.s2DriverDocsValid,
    this.s2EntryPermission,
    this.s2LoadingSlipUrl,
    this.s3EmptyTruckWeightKg,
    this.s3EmptyTruckWeightUnit,
    this.s3LoadedTruckWeightKg,
    this.s3LoadedTruckWeightUnit,
    this.s3BiltyUrl,
    this.s3MaterialDocUrls,
    this.s4TruckMoved,
    this.s4SecurityVerified,
    this.s4BiltyChecked,
    this.s4WeightChecked,
    this.s4MaterialChecked,
    this.s4CompletedAt,
    this.s4NotifiedAt,
    this.s1SubmittedBy,
    this.s2SubmittedBy,
    this.s3SubmittedBy,
    this.s4SubmittedBy,
    this.s1ClaimedBy,
    this.s2ClaimedBy,
    this.s3ClaimedBy,
    this.s4ClaimedBy,
    this.draftData,
  });

  bool get isOngoing => status == 'ongoing';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get hasVehicle => vehicleId != null;

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] as String,
      tripNumber: json['trip_number'] as String,
      biltyNumber: json['bilty_number'] as String?,
      origin: json['origin'] as String,
      originSub: json['origin_sub'] as String?,
      destination: json['destination'] as String,
      destinationSub: json['destination_sub'] as String?,
      loadItem: json['load_item'] as String,
      weight: json['weight'] as String?,
      tripAmount: (json['trip_amount'] as num?)?.toDouble(),
      invoiceNumber: json['invoice_number'] as String?,
      status: json['status'] as String? ?? 'ongoing',
      organizationId: json['organization_id'] as String,
      lpOrgName: json['lp_org_name'] as String?,
      loadOwnerOrgId: json['load_owner_org_id'] as String?,
      loadOwnerOrgName: json['load_owner_org_name'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      driverId: json['driver_id'] as String?,
      driverName: json['driver_name'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      currentStage: json['current_stage'] as int? ?? 0,
      s1DriverName: json['s1_driver_name'] as String?,
      s1DriverPhone: json['s1_driver_phone'] as String?,
      s1DrivingLicense: json['s1_driving_license'] as String?,
      s1DrivingLicenseUrl: json['s1_driving_license_url'] as String?,
      s1Aadhaar: json['s1_aadhaar'] as String?,
      s1AadhaarUrl: json['s1_aadhaar_url'] as String?,
      s1Rc: json['s1_rc'] as String?,
      s1Insurance: json['s1_insurance'] as String?,
      s1Pollution: json['s1_pollution'] as String?,
      s1Fitness: json['s1_fitness'] as String?,
      s1Pan: json['s1_pan'] as String?,
      s1TaxDeclaration: json['s1_tax_declaration'] as String?,
      s1CancelledCheque: json['s1_cancelled_cheque'] as String?,
      s2SpecsVerified: json['s2_specs_verified'] as bool?,
      s2DocsVerified: json['s2_docs_verified'] as bool?,
      s2DriverDocsValid: json['s2_driver_docs_valid'] as bool?,
      s2EntryPermission: json['s2_entry_permission'] as bool?,
      s2LoadingSlipUrl: json['s2_loading_slip_url'] as String?,
      s3EmptyTruckWeightKg: json['s3_empty_truck_weight_kg'] as String?,
      s3EmptyTruckWeightUnit: json['s3_empty_truck_weight_unit'] as String?,
      s3LoadedTruckWeightKg: json['s3_loaded_truck_weight_kg'] as String?,
      s3LoadedTruckWeightUnit: json['s3_loaded_truck_weight_unit'] as String?,
      s3BiltyUrl: json['s3_bilty_url'] as String?,
      s3MaterialDocUrls: _parseUrlList(json['s3_material_doc_urls']),
      s4TruckMoved:       json['s4_truck_moved']       as bool?,
      s4SecurityVerified: json['s4_security_verified'] as bool?,
      s4BiltyChecked:     json['s4_bilty_checked']     as bool?,
      s4WeightChecked:    json['s4_weight_checked']     as bool?,
      s4MaterialChecked:  json['s4_material_checked']   as bool?,
      s4CompletedAt:      json['s4_completed_at']       as String?,
      s4NotifiedAt:       json['s4_notified_at']        as String?,
      s1SubmittedBy:      json['s1_submitted_by']       as String?,
      s2SubmittedBy:      json['s2_submitted_by']       as String?,
      s3SubmittedBy:      json['s3_submitted_by']       as String?,
      s4SubmittedBy:      json['s4_submitted_by']       as String?,
      s1ClaimedBy:        json['s1_claimed_by']         as String?,
      s2ClaimedBy:        json['s2_claimed_by']         as String?,
      s3ClaimedBy:        json['s3_claimed_by']         as String?,
      s4ClaimedBy:        json['s4_claimed_by']         as String?,
      draftData:          json['draft_data'] as Map<String, dynamic>?,
    );
  }

  static List<String>? _parseUrlList(dynamic value) {
    if (value == null) return null;
    if (value is List) return List<String>.from(value);
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return List<String>.from(decoded);
      } catch (_) {}
    }
    return null;
  }
}

class TripLocationModel {
  final String tripId;
  final String tripNumber;
  final String? vehicleId;
  final String? driverId;
  final bool hasLocation;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final double? heading;
  final String? timestamp;
  final String? message;

  const TripLocationModel({
    required this.tripId,
    required this.tripNumber,
    this.vehicleId,
    this.driverId,
    required this.hasLocation,
    this.latitude,
    this.longitude,
    this.speed,
    this.heading,
    this.timestamp,
    this.message,
  });

  factory TripLocationModel.fromJson(Map<String, dynamic> json) {
    return TripLocationModel(
      tripId: json['trip_id'] as String,
      tripNumber: json['trip_number'] as String,
      vehicleId: json['vehicle_id'] as String?,
      driverId: json['driver_id'] as String?,
      hasLocation: json['has_location'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as String?,
      message: json['message'] as String?,
    );
  }
}
