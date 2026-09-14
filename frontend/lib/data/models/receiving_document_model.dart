/// A trip linked to a ReceivingDocumentModel — carries both the trip's id
/// (needed to call the unlink endpoint) and its display number.
class LinkedTripRef {
  final String id;
  final String tripNumber;

  const LinkedTripRef({required this.id, required this.tripNumber});

  factory LinkedTripRef.fromJson(Map<String, dynamic> json) => LinkedTripRef(
        id: json['id'] as String,
        tripNumber: json['trip_number'] as String,
      );
}

/// One uploaded "receiving sheet" image, possibly linked to several trips.
/// See backend/app/models/receiving_document.py for the data model this
/// mirrors — trips are one-receiving-document-at-a-time (DB-enforced).
class ReceivingDocumentModel {
  final String id;
  final String fileUrl;
  final String? uploadedBy;
  final String? createdAt;
  final List<LinkedTripRef> trips;

  const ReceivingDocumentModel({
    required this.id,
    required this.fileUrl,
    this.uploadedBy,
    this.createdAt,
    this.trips = const [],
  });

  factory ReceivingDocumentModel.fromJson(Map<String, dynamic> json) => ReceivingDocumentModel(
        id: json['id'] as String,
        fileUrl: json['file_url'] as String,
        uploadedBy: json['uploaded_by'] as String?,
        createdAt: json['created_at'] as String?,
        trips: (json['trips'] as List<dynamic>?)
                ?.map((e) => LinkedTripRef.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
