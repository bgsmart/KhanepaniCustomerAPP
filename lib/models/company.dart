// lib/models/company.dart
class Company {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String logoPath;
  final String website;
  final String panNumber;
  final String registrationNumber;

  Company({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.logoPath = 'assets/images/Logo.png',
    this.website = '',
    this.panNumber = '',
    this.registrationNumber = '',
  });

  // Default company data
  static Company get defaultCompany {
    return Company(
      name: 'हेटौडा खानेपानी ब्यवस्थापन बोर्ड',
      address: 'हेटौडा २, मकवानपुर',
      phone: '9855070610',
      email: 'info@hwsmboard.com.np',
      website: 'www.hwsmboard.com.np',
      panNumber: '123456789',
      registrationNumber: '123/456',
    );
  }

  // English version of company
  static Company get defaultCompanyEnglish {
    return Company(
      name: 'Hetauda Water Supply Management Board',
      address: 'Hetauda-2, Makawanpur',
      phone: '9855070610',
      email: 'info@hwsmboard.com.np',
      website: 'www.hwsmboard.com.np',
      panNumber: '123456789',
      registrationNumber: '123/456',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'logoPath': logoPath,
      'website': website,
      'panNumber': panNumber,
      'registrationNumber': registrationNumber,
    };
  }

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'] ?? Company.defaultCompany.name,
      address: json['address'] ?? Company.defaultCompany.address,
      phone: json['phone'] ?? Company.defaultCompany.phone,
      email: json['email'] ?? Company.defaultCompany.email,
      logoPath: json['logoPath'] ?? Company.defaultCompany.logoPath,
      website: json['website'] ?? '',
      panNumber: json['panNumber'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
    );
  }

  Company copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? logoPath,
    String? website,
    String? panNumber,
    String? registrationNumber,
  }) {
    return Company(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoPath: logoPath ?? this.logoPath,
      website: website ?? this.website,
      panNumber: panNumber ?? this.panNumber,
      registrationNumber: registrationNumber ?? this.registrationNumber,
    );
  }
}