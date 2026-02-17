/// Organization Branding Data Model
class BrandingColors {
  final String primaryColor;
  final String primaryDark;
  final String primaryLight;
  final String secondaryColor;
  final String accentColor;
  final String backgroundPrimary;
  final String backgroundSecondary;

  BrandingColors({
    required this.primaryColor,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
  });

  factory BrandingColors.fromJson(Map<String, dynamic> json) {
    return BrandingColors(
      primaryColor: json['primary_color'] as String? ?? '#1E40AF',
      primaryDark: json['primary_dark'] as String? ?? '#1E3A8A',
      primaryLight: json['primary_light'] as String? ?? '#3B82F6',
      secondaryColor: json['secondary_color'] as String? ?? '#06B6D4',
      accentColor: json['accent_color'] as String? ?? '#0EA5E9',
      backgroundPrimary: json['background_primary'] as String? ?? '#F8FAFC',
      backgroundSecondary: json['background_secondary'] as String? ?? '#FFFFFF',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_color': primaryColor,
      'primary_dark': primaryDark,
      'primary_light': primaryLight,
      'secondary_color': secondaryColor,
      'accent_color': accentColor,
      'background_primary': backgroundPrimary,
      'background_secondary': backgroundSecondary,
    };
  }

  /// Factory method for default colors
  factory BrandingColors.defaultColors() {
    return BrandingColors(
      primaryColor: '#1E40AF',
      primaryDark: '#1E3A8A',
      primaryLight: '#3B82F6',
      secondaryColor: '#06B6D4',
      accentColor: '#0EA5E9',
      backgroundPrimary: '#F8FAFC',
      backgroundSecondary: '#FFFFFF',
    );
  }

  BrandingColors copyWith({
    String? primaryColor,
    String? primaryDark,
    String? primaryLight,
    String? secondaryColor,
    String? accentColor,
    String? backgroundPrimary,
    String? backgroundSecondary,
  }) {
    return BrandingColors(
      primaryColor: primaryColor ?? this.primaryColor,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
    );
  }
}

class LogoInfo {
  final String? url;
  final String? filename;
  final int? sizeBytes;
  final DateTime? uploadedAt;

  LogoInfo({
    this.url,
    this.filename,
    this.sizeBytes,
    this.uploadedAt,
  });

  factory LogoInfo.fromJson(Map<String, dynamic> json) {
    return LogoInfo(
      url: json['url'] as String?,
      filename: json['filename'] as String?,
      sizeBytes: json['size_bytes'] as int?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'filename': filename,
      'size_bytes': sizeBytes,
      'uploaded_at': uploadedAt?.toIso8601String(),
    };
  }
}

class OrganizationBranding {
  final String id;
  final String organizationId;
  final LogoInfo? logo;
  final BrandingColors colors;
  final Map<String, dynamic> themeConfig;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrganizationBranding({
    required this.id,
    required this.organizationId,
    this.logo,
    required this.colors,
    this.themeConfig = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory OrganizationBranding.fromJson(Map<String, dynamic> json) {
    return OrganizationBranding(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      logo: json['logo'] != null ? LogoInfo.fromJson(json['logo']) : null,
      colors: BrandingColors.fromJson(json['colors'] as Map<String, dynamic>),
      themeConfig: json['theme_config'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'logo': logo?.toJson(),
      'colors': colors.toJson(),
      'theme_config': themeConfig,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Helper method to get full logo URL
  String? getLogoUrl(String baseUrl) {
    if (logo?.url == null) return null;
    // If URL already starts with http, return as is
    if (logo!.url!.startsWith('http')) return logo!.url;
    // Otherwise, prepend base URL
    return '$baseUrl${logo!.url}';
  }

  /// Factory method for default branding
  factory OrganizationBranding.defaultBranding(String organizationId) {
    return OrganizationBranding(
      id: '',
      organizationId: organizationId,
      colors: BrandingColors.defaultColors(),
    );
  }

  OrganizationBranding copyWith({
    String? id,
    String? organizationId,
    LogoInfo? logo,
    BrandingColors? colors,
    Map<String, dynamic>? themeConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizationBranding(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      logo: logo ?? this.logo,
      colors: colors ?? this.colors,
      themeConfig: themeConfig ?? this.themeConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
