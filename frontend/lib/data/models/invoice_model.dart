class InvoiceLineItemModel {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double amount;
  final String? vehicleId;
  final DateTime createdAt;

  InvoiceLineItemModel({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.vehicleId,
    required this.createdAt,
  });

  factory InvoiceLineItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItemModel(
      id: json['id'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      vehicleId: json['vehicle_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'amount': amount,
      'vehicle_id': vehicleId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
  String get formattedUnitPrice => '₹${unitPrice.toStringAsFixed(2)}';
}

class InvoiceModel {
  final String id;
  final String organizationId;
  final String invoiceNumber;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerGstin;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final double amountPaid;
  final String status;
  final String? notes;
  final String? termsAndConditions;
  final DateTime? sentAt;
  final String? sentBy;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InvoiceLineItemModel> lineItems;

  InvoiceModel({
    required this.id,
    required this.organizationId,
    required this.invoiceNumber,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.customerAddress,
    this.customerGstin,
    required this.invoiceDate,
    required this.dueDate,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.amountPaid,
    required this.status,
    this.notes,
    this.termsAndConditions,
    this.sentAt,
    this.sentBy,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.lineItems = const [],
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      customerName: json['customer_name'] as String,
      customerEmail: json['customer_email'] as String?,
      customerPhone: json['customer_phone'] as String?,
      customerAddress: json['customer_address'] as String?,
      customerGstin: json['customer_gstin'] as String?,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      termsAndConditions: json['terms_and_conditions'] as String?,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      sentBy: json['sent_by'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((e) => InvoiceLineItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'invoice_number': invoiceNumber,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'customer_gstin': customerGstin,
      'invoice_date': invoiceDate.toIso8601String().split('T')[0],
      'due_date': dueDate.toIso8601String().split('T')[0],
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'status': status,
      'notes': notes,
      'terms_and_conditions': termsAndConditions,
      'sent_at': sentAt?.toIso8601String(),
      'sent_by': sentBy,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'line_items': lineItems.map((e) => e.toJson()).toList(),
    };
  }

  // Computed properties
  double get amountDue => totalAmount - amountPaid;

  bool get isOverdue {
    final now = DateTime.now();
    return (status.toLowerCase() == 'sent' ||
            status.toLowerCase() == 'partially_paid') &&
           dueDate.isBefore(now);
  }

  bool get isFullyPaid => amountPaid >= totalAmount;

  bool get canSend => status.toLowerCase() == 'draft';

  bool get canEdit => status.toLowerCase() == 'draft';

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  String get formattedTotal => '₹${totalAmount.toStringAsFixed(2)}';
  String get formattedAmountPaid => '₹${amountPaid.toStringAsFixed(2)}';
  String get formattedAmountDue => '₹${amountDue.toStringAsFixed(2)}';
  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(2)}';
  String get formattedTax => '₹${taxAmount.toStringAsFixed(2)}';

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'grey';
      case 'sent':
        return 'blue';
      case 'partially_paid':
        return 'orange';
      case 'paid':
        return 'green';
      case 'overdue':
        return 'red';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'draft':
        return '📝';
      case 'sent':
        return '📤';
      case 'partially_paid':
        return '💵';
      case 'paid':
        return '✅';
      case 'overdue':
        return '⚠️';
      case 'cancelled':
        return '❌';
      default:
        return '📄';
    }
  }

  InvoiceModel copyWith({
    String? id,
    String? organizationId,
    String? invoiceNumber,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerAddress,
    String? customerGstin,
    DateTime? invoiceDate,
    DateTime? dueDate,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    double? amountPaid,
    String? status,
    String? notes,
    String? termsAndConditions,
    DateTime? sentAt,
    String? sentBy,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceLineItemModel>? lineItems,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerGstin: customerGstin ?? this.customerGstin,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      sentAt: sentAt ?? this.sentAt,
      sentBy: sentBy ?? this.sentBy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lineItems: lineItems ?? this.lineItems,
    );
  }
}
