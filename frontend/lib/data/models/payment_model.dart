class PaymentModel {
  final String id;
  final String organizationId;
  final String paymentNumber;
  final String paymentType;
  final String paymentMethod;
  final double amount;
  final DateTime paymentDate;
  final String? invoiceId;
  final String? expenseId;
  final String? referenceNumber;
  final String? bankName;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.organizationId,
    required this.paymentNumber,
    required this.paymentType,
    required this.paymentMethod,
    required this.amount,
    required this.paymentDate,
    this.invoiceId,
    this.expenseId,
    this.referenceNumber,
    this.bankName,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      paymentNumber: json['payment_number'] as String,
      paymentType: json['payment_type'] as String,
      paymentMethod: json['payment_method'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      invoiceId: json['invoice_id'] as String?,
      expenseId: json['expense_id'] as String?,
      referenceNumber: json['reference_number'] as String?,
      bankName: json['bank_name'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'payment_number': paymentNumber,
      'payment_type': paymentType,
      'payment_method': paymentMethod,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'invoice_id': invoiceId,
      'expense_id': expenseId,
      'reference_number': referenceNumber,
      'bank_name': bankName,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Computed properties
  bool get isReceived => paymentType.toLowerCase() == 'received';
  bool get isPaid => paymentType.toLowerCase() == 'paid';

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';

  String get methodIcon {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return '💵';
      case 'bank_transfer':
        return '🏦';
      case 'cheque':
        return '📝';
      case 'upi':
        return '📱';
      case 'card':
        return '💳';
      default:
        return '💰';
    }
  }

  String get methodLabel {
    switch (paymentMethod.toLowerCase()) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Card';
      case 'cash':
        return 'Cash';
      case 'cheque':
        return 'Cheque';
      default:
        return 'Other';
    }
  }

  String get typeColor => isReceived ? 'green' : 'red';

  String get typeIcon => isReceived ? '📥' : '📤';

  String get typeLabel => isReceived ? 'Received' : 'Paid';

  String get linkedEntityType {
    if (invoiceId != null) return 'Invoice';
    if (expenseId != null) return 'Expense';
    return 'None';
  }

  String? get linkedEntityId => invoiceId ?? expenseId;

  PaymentModel copyWith({
    String? id,
    String? organizationId,
    String? paymentNumber,
    String? paymentType,
    String? paymentMethod,
    double? amount,
    DateTime? paymentDate,
    String? invoiceId,
    String? expenseId,
    String? referenceNumber,
    String? bankName,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      paymentNumber: paymentNumber ?? this.paymentNumber,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      invoiceId: invoiceId ?? this.invoiceId,
      expenseId: expenseId ?? this.expenseId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      bankName: bankName ?? this.bankName,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
