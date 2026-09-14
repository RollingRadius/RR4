/// One uploaded "receiving sheet" image, possibly linked to several trips.
/// See backend/app/models/receiving_document.py for the data model this
/// mirrors — trips are one-receiving-document-at-a-time (DB-enforced).
class ReceivingDocumentModel {
  final String id;
  final String fileUrl;
  final String? uploadedBy;
  final String? createdAt;
  final List<String> tripNumbers;

  const ReceivingDocumentModel({
    required this.id,
    required this.fileUrl,
    this.uploadedBy,
    this.createdAt,
    this.tripNumbers = const [],
  });

  factory ReceivingDocumentModel.fromJson(Map<String, dynamic> json) => ReceivingDocumentModel(
        id: json['id'] as String,
        fileUrl: json['file_url'] as String,
        uploadedBy: json['uploaded_by'] as String?,
        createdAt: json['created_at'] as String?,
        tripNumbers: (json['trip_numbers'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      );
}
