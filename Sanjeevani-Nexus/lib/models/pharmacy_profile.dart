import 'dart:convert';

class PharmacyProfile {
  final String pharmacyName;
  final String ownerName;
  final String phone;
  final String? logoPath;

  const PharmacyProfile({
    required this.pharmacyName,
    required this.ownerName,
    required this.phone,
    this.logoPath,
  });

  PharmacyProfile copyWith({
    String? pharmacyName,
    String? ownerName,
    String? phone,
    String? logoPath,
  }) {
    return PharmacyProfile(
      pharmacyName: pharmacyName ?? this.pharmacyName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'pharmacyName': pharmacyName,
        'ownerName': ownerName,
        'phone': phone,
        'logoPath': logoPath,
      };

  factory PharmacyProfile.fromJson(Map<String, dynamic> json) {
    return PharmacyProfile(
      pharmacyName: json['pharmacyName'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      logoPath: json['logoPath'] as String?,
    );
  }

  /// Returns up to 2 uppercase initials from the pharmacy name.
  String get initials {
    final parts = pharmacyName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'P';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
