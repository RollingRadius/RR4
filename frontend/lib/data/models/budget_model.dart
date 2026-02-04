class BudgetModel {
  final String id;
  final String organizationId;
  final String name;
  final String category;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final double allocatedAmount;
  final double spentAmount;
  final double remainingAmount;
  final double alertThresholdPercent;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.category,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.allocatedAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.alertThresholdPercent,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      period: json['period'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      allocatedAmount: (json['allocated_amount'] as num).toDouble(),
      spentAmount: (json['spent_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      alertThresholdPercent: (json['alert_threshold_percent'] as num).toDouble(),
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'category': category,
      'period': period,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'allocated_amount': allocatedAmount,
      'spent_amount': spentAmount,
      'remaining_amount': remainingAmount,
      'alert_threshold_percent': alertThresholdPercent,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Computed properties
  double get percentageSpent {
    if (allocatedAmount == 0) return 0;
    return (spentAmount / allocatedAmount) * 100;
  }

  bool get isOverThreshold => percentageSpent >= alertThresholdPercent;

  bool get isExceeded => spentAmount > allocatedAmount;

  bool get isActive {
    final now = DateTime.now();
    return startDate.isBefore(now) && endDate.isAfter(now) ||
           startDate.isAtSameMomentAs(now) ||
           endDate.isAtSameMomentAs(now);
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }

  int get totalDays => endDate.difference(startDate).inDays;

  int get daysElapsed {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;
    if (now.isAfter(endDate)) return totalDays;
    return now.difference(startDate).inDays;
  }

  double get dailyBurnRate {
    if (daysElapsed <= 0) return 0;
    return spentAmount / daysElapsed;
  }

  double get projectedTotal {
    if (daysRemaining <= 0) return spentAmount;
    return spentAmount + (dailyBurnRate * daysRemaining);
  }

  double get projectedPercentage {
    if (allocatedAmount == 0) return 0;
    return (projectedTotal / allocatedAmount) * 100;
  }

  String get formattedAllocated => '₹${allocatedAmount.toStringAsFixed(2)}';
  String get formattedSpent => '₹${spentAmount.toStringAsFixed(2)}';
  String get formattedRemaining => '₹${remainingAmount.toStringAsFixed(2)}';
  String get formattedProjected => '₹${projectedTotal.toStringAsFixed(2)}';
  String get formattedDailyBurnRate => '₹${dailyBurnRate.toStringAsFixed(2)}';

  String get statusColor {
    if (isExceeded) return 'red';
    if (isOverThreshold) return 'orange';
    if (percentageSpent >= 50) return 'yellow';
    return 'green';
  }

  String get statusIcon {
    if (isExceeded) return '🔴';
    if (isOverThreshold) return '🟠';
    if (percentageSpent >= 50) return '🟡';
    return '🟢';
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

  String get periodLabel {
    switch (period.toLowerCase()) {
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      default:
        return period;
    }
  }

  BudgetModel copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? category,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    double? allocatedAmount,
    double? spentAmount,
    double? remainingAmount,
    double? alertThresholdPercent,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      category: category ?? this.category,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      alertThresholdPercent: alertThresholdPercent ?? this.alertThresholdPercent,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
