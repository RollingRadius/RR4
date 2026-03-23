/// Data model for a LoadRequirement (load posted by a load_owner company).
class LoadRequirementModel {
  final String id;
  final String companyId;
  final String? createdBy;
  final String entryMethod;
  final String? pickupLocation;
  final String? unloadLocation;
  final String? materialType;
  final String? entryDate;
  final int truckCount;
  final String? capacity;
  final String? axelType;
  final String? bodyType;
  final String? floorType;
  final String status;
  final String createdAt;

  const LoadRequirementModel({
    required this.id,
    required this.companyId,
    this.createdBy,
    required this.entryMethod,
    this.pickupLocation,
    this.unloadLocation,
    this.materialType,
    this.entryDate,
    required this.truckCount,
    this.capacity,
    this.axelType,
    this.bodyType,
    this.floorType,
    required this.status,
    required this.createdAt,
  });

  factory LoadRequirementModel.fromJson(Map<String, dynamic> j) =>
      LoadRequirementModel(
        id: j['id'] as String,
        companyId: j['company_id'] as String,
        createdBy: j['created_by'] as String?,
        entryMethod: j['entry_method'] as String? ?? 'manual',
        pickupLocation: j['pickup_location'] as String?,
        unloadLocation: j['unload_location'] as String?,
        materialType: j['material_type'] as String?,
        entryDate: j['entry_date'] as String?,
        truckCount: j['truck_count'] as int? ?? 1,
        capacity: j['capacity'] as String?,
        axelType: j['axel_type'] as String?,
        bodyType: j['body_type'] as String?,
        floorType: j['floor_type'] as String?,
        status: j['status'] as String? ?? 'pending',
        createdAt: j['created_at'] as String,
      );

  /// Short reference ID derived from the UUID tail.
  String get refId => 'REQ-${id.replaceAll('-', '').substring(0, 8).toUpperCase()}';

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  /// Display date — first 10 chars of ISO string (YYYY-MM-DD).
  String get displayDate => createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
}
