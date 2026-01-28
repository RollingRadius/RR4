/// Company Data Model
class CompanyModel {
  final String companyId;
  final String companyName;
  final String city;
  final String state;
  final String businessType;

  CompanyModel({
    required this.companyId,
    required this.companyName,
    required this.city,
    required this.state,
    required this.businessType,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      businessType: json['business_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'company_name': companyName,
      'city': city,
      'state': state,
      'business_type': businessType,
    };
  }

  String get location => '$city, $state';

  // Getter for backward compatibility
  String get id => companyId;
}
