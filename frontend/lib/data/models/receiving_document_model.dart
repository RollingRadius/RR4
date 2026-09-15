/// "rlplwmz4090 · RR-03625 · Bilty: BN1234" — each part shown only when
/// present, shared by every receiving-docs trip capsule/card.
String formatTripDisplayLabel(String tripNumber, String? rrTripNumber, String? biltyNumber) {
  final parts = [tripNumber];
  if (rrTripNumber != null && rrTripNumber.isNotEmpty) parts.add(rrTripNumber);
  if (biltyNumber != null && biltyNumber.isNotEmpty) parts.add('Bilty: $biltyNumber');
  return parts.join(' · ');
}

/// A trip linked to a ReceivingDocumentModel — carries the trip's id
/// (needed to call the unlink endpoint), its own display number, the
/// RR-web-assigned number (null until synced), and its Stage-4 bilty
/// number (null until that stage is submitted).
class LinkedTripRef {
  final String id;
  final String tripNumber;
  final String? rrTripNumber;
  final String? biltyNumber;

  const LinkedTripRef({
    required this.id,
    required this.tripNumber,
    this.rrTripNumber,
    this.biltyNumber,
  });

  factory LinkedTripRef.fromJson(Map<String, dynamic> json) => LinkedTripRef(
        id: json['id'] as String,
        tripNumber: json['trip_number'] as String,
        rrTripNumber: json['rr_trip_number'] as String?,
        biltyNumber: json['s4_bilty_number'] as String?,
      );

  String get displayLabel => formatTripDisplayLabel(tripNumber, rrTripNumber, biltyNumber);
}

/// One trip returned by the receiving-docs trip search — carries RR4's own
/// trip number, the RR-web-assigned number, and the Stage-4 bilty number
/// (each null until set) so the search can match any of the three.
class TripSearchResult {
  final String id;
  final String tripNumber;
  final String? rrTripNumber;
  final String? biltyNumber;
  final String origin;
  final String destination;

  const TripSearchResult({
    required this.id,
    required this.tripNumber,
    this.rrTripNumber,
    this.biltyNumber,
    required this.origin,
    required this.destination,
  });

  factory TripSearchResult.fromJson(Map<String, dynamic> json) => TripSearchResult(
        id: json['id'] as String,
        tripNumber: json['trip_number'] as String,
        rrTripNumber: json['rr_trip_number'] as String?,
        biltyNumber: json['s4_bilty_number'] as String?,
        origin: json['origin'] as String? ?? '',
        destination: json['destination'] as String? ?? '',
      );

  String get displayLabel => formatTripDisplayLabel(tripNumber, rrTripNumber, biltyNumber);
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
