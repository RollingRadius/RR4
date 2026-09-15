/// One uploaded "receiving sheet" image, tagged with the date it's for.
/// See backend/app/models/receiving_document.py for the data model this
/// mirrors.
class ReceivingDocumentModel {
  final String id;
  final String fileUrl;
  final String docDate;
  final String? uploadedBy;
  final String? createdAt;

  const ReceivingDocumentModel({
    required this.id,
    required this.fileUrl,
    required this.docDate,
    this.uploadedBy,
    this.createdAt,
  });

  factory ReceivingDocumentModel.fromJson(Map<String, dynamic> json) => ReceivingDocumentModel(
        id: json['id'] as String,
        fileUrl: json['file_url'] as String,
        docDate: json['doc_date'] as String,
        uploadedBy: json['uploaded_by'] as String?,
        createdAt: json['created_at'] as String?,
      );
}
