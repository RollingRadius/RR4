/// A trip linked to a ReceivingDocumentModel — carries the trip's id
/// (needed to call the unlink endpoint), its own display number, and the
/// RR-web-assigned number (null until synced).
class LinkedTripRef {
  final String id;
  final String tripNumber;
  final String? rrTripNumber;

  const LinkedTripRef({required this.id, required this.tripNumber, this.rrTripNumber});

  factory LinkedTripRef.fromJson(Map<String, dynamic> json) => LinkedTripRef(
        id: json['id'] as String,
        tripNumber: json['trip_number'] as String,
        rrTripNumber: json['rr_trip_number'] as String?,
      );

  /// "rlplwmz4090 · RR-03625" when synced, else just the RR4 number.
  String get displayLabel => rrTripNumber != null && rrTripNumber!.isNotEmpty
      ? '$tripNumber · $rrTripNumber'
      : tripNumber;
}

/// One trip returned by the receiving-docs trip search — carries both
/// RR4's own trip number and the RR-web-assigned number (null until synced)
/// so the search can match either.
class TripSearchResult {
  final String id;
  final String tripNumber;
  final String? rrTripNumber;
  final String origin;
  final String destination;

  const TripSearchResult({
    required this.id,
    required this.tripNumber,
    this.rrTripNumber,
    required this.origin,
    required this.destination,
  });

  factory TripSearchResult.fromJson(Map<String, dynamic> json) => TripSearchResult(
        id: json['id'] as String,
        tripNumber: json['trip_number'] as String,
        rrTripNumber: json['rr_trip_number'] as String?,
        origin: json['origin'] as String? ?? '',
        destination: json['destination'] as String? ?? '',
      );

  /// "rlplwmz4090 · RR-03625" when synced, else just the RR4 number.
  String get displayLabel => rrTripNumber != null && rrTripNumber!.isNotEmpty
      ? '$tripNumber · $rrTripNumber'
      : tripNumber;
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
