class ExpenseAttachmentModel {
  final String id;
  final String fileName;
  final String filePath;
  final double fileSize;
  final String? fileType;
  final String? uploadedBy;
  final DateTime uploadedAt;

  ExpenseAttachmentModel({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    this.fileType,
    this.uploadedBy,
    required this.uploadedAt,
  });

  factory ExpenseAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ExpenseAttachmentModel(
      id: json['id'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileSize: (json['file_size'] as num).toDouble(),
      fileType: json['file_type'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'file_type': fileType,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }

  String get formattedSize {
    if (fileSize < 1024) return '${fileSize.toStringAsFixed(0)} B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ExpenseModel {
  final String id;
  final String organizationId;
  final String expenseNumber;
  final String category;
  final String description;
  final double amount;
  final double taxAmount;
  final double totalAmount;
  final DateTime expenseDate;
  final String? vehicleId;
  final String? driverId;
  final String? vendorId;
  final String status;
  final DateTime? submittedAt;
  final String? submittedBy;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;
  final DateTime? paidAt;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ExpenseAttachmentModel> attachments;

  ExpenseModel({
    required this.id,
    required this.organizationId,
    required this.expenseNumber,
    required this.category,
    required this.description,
    required this.amount,
    required this.taxAmount,
    required this.totalAmount,
    required this.expenseDate,
    this.vehicleId,
    this.driverId,
    this.vendorId,
    required this.status,
    this.submittedAt,
    this.submittedBy,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
    this.paidAt,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      expenseNumber: json['expense_number'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expense_date'] as String),
      vehicleId: json['vehicle_id'] as String?,
      driverId: json['driver_id'] as String?,
      vendorId: json['vendor_id'] as String?,
      status: json['status'] as String,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      submittedBy: json['submitted_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      approvedBy: json['approved_by'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => ExpenseAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'expense_number': expenseNumber,
      'category': category,
      'description': description,
      'amount': amount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'vehicle_id': vehicleId,
      'driver_id': driverId,
      'vendor_id': vendorId,
      'status': status,
      'submitted_at': submittedAt?.toIso8601String(),
      'submitted_by': submittedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'rejection_reason': rejectionReason,
      'paid_at': paidAt?.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
    };
  }

  // Computed properties
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isSubmitted => status.toLowerCase() == 'submitted';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isPaid => status.toLowerCase() == 'paid';

  bool get canEdit => isDraft || isRejected;
  bool get canSubmit => isDraft;
  bool get canApprove => isSubmitted;
  bool get canMarkPaid => isApproved;

  String get formattedAmount => '₹${totalAmount.toStringAsFixed(2)}';

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'grey';
      case 'submitted':
        return 'blue';
      case 'approved':
        return 'green';
      case 'rejected':
        return 'red';
      case 'paid':
        return 'teal';
      default:
        return 'grey';
    }
  }

  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'fuel':
        return '⛽';
      case 'maintenance':
        return '🔧';
      case 'toll':
        return '🛣️';
      case 'parking':
        return '🅿️';
      case 'insurance':
        return '🛡️';
      case 'salary':
        return '💰';
      default:
        return '📝';
    }
  }

  ExpenseModel copyWith({
    String? id,
    String? organizationId,
    String? expenseNumber,
    String? category,
    String? description,
    double? amount,
    double? taxAmount,
    double? totalAmount,
    DateTime? expenseDate,
    String? vehicleId,
    String? driverId,
    String? vendorId,
    String? status,
    DateTime? submittedAt,
    String? submittedBy,
    DateTime? approvedAt,
    String? approvedBy,
    String? rejectionReason,
    DateTime? paidAt,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ExpenseAttachmentModel>? attachments,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      expenseNumber: expenseNumber ?? this.expenseNumber,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      expenseDate: expenseDate ?? this.expenseDate,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      vendorId: vendorId ?? this.vendorId,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
    );
  }
}
