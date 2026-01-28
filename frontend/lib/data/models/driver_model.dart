class DriverLicenseModel {
  final String licenseNumber;
  final String licenseType;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? issuingAuthority;
  final String? issuingState;

  DriverLicenseModel({
    required this.licenseNumber,
    required this.licenseType,
    required this.issueDate,
    required this.expiryDate,
    this.issuingAuthority,
    this.issuingState,
  });

  factory DriverLicenseModel.fromJson(Map<String, dynamic> json) {
    return DriverLicenseModel(
      licenseNumber: json['license_number'] as String,
      licenseType: json['license_type'] as String,
      issueDate: DateTime.parse(json['issue_date'] as String),
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      issuingAuthority: json['issuing_authority'] as String?,
      issuingState: json['issuing_state'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'license_number': licenseNumber,
      'license_type': licenseType,
      'issue_date': issueDate.toIso8601String().split('T')[0], // Date only
      'expiry_date': expiryDate.toIso8601String().split('T')[0], // Date only
      'issuing_authority': issuingAuthority,
      'issuing_state': issuingState,
    };
  }

  // Computed properties
  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isExpiringSoon {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
  }

  String get licenseTypeDisplay {
    switch (licenseType) {
      case 'LMV':
        return 'Light Motor Vehicle';
      case 'HMV':
        return 'Heavy Motor Vehicle';
      case 'MCWG':
        return 'Motorcycle with Gear';
      case 'HPMV':
        return 'Heavy Passenger Motor Vehicle';
      default:
        return licenseType;
    }
  }
}

class DriverModel {
  final String driverId;
  final String organizationId;
  final String employeeId;
  final DateTime joinDate;
  final String status;

  // Basic Information
  final String firstName;
  final String lastName;
  final String? email;
  final String phone;
  final DateTime? dateOfBirth;

  // Address Information
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String country;

  // Emergency Contact
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;

  // License Information
  final DriverLicenseModel? license;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverModel({
    required this.driverId,
    required this.organizationId,
    required this.employeeId,
    required this.joinDate,
    required this.status,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.phone,
    this.dateOfBirth,
    this.address,
    this.city,
    this.state,
    this.pincode,
    required this.country,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.license,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      driverId: json['driver_id'] as String,
      organizationId: json['organization_id'] as String,
      employeeId: json['employee_id'] as String,
      joinDate: DateTime.parse(json['join_date'] as String),
      status: json['status'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      country: json['country'] as String? ?? 'India',
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      emergencyContactRelationship: json['emergency_contact_relationship'] as String?,
      license: json['license'] != null
          ? DriverLicenseModel.fromJson(json['license'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'organization_id': organizationId,
      'employee_id': employeeId,
      'join_date': joinDate.toIso8601String().split('T')[0], // Date only
      'status': status,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relationship': emergencyContactRelationship,
      'license': license?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Computed properties
  String get fullName => '$firstName $lastName';

  bool get isActive => status.toLowerCase() == 'active';
  bool get isInactive => status.toLowerCase() == 'inactive';
  bool get isOnLeave => status.toLowerCase() == 'on_leave';
  bool get isTerminated => status.toLowerCase() == 'terminated';

  bool get hasExpiredLicense => license?.isExpired ?? false;
  bool get hasExpiringSoonLicense => license?.isExpiringSoon ?? false;

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'on_leave':
        return 'On Leave';
      case 'terminated':
        return 'Terminated';
      default:
        return status;
    }
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth!.year;
    if (today.month < dateOfBirth!.month ||
        (today.month == dateOfBirth!.month && today.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (pincode != null && pincode!.isNotEmpty) parts.add(pincode!);
    if (parts.isEmpty) return 'No address provided';
    return parts.join(', ');
  }

  // Create a copy with updated fields
  DriverModel copyWith({
    String? driverId,
    String? organizationId,
    String? employeeId,
    DateTime? joinDate,
    String? status,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? country,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    DriverLicenseModel? license,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverModel(
      driverId: driverId ?? this.driverId,
      organizationId: organizationId ?? this.organizationId,
      employeeId: employeeId ?? this.employeeId,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
      license: license ?? this.license,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
