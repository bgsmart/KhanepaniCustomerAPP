// lib/models/customer_details.dart
class CustomerDetails {
  final String cusID;
  final String name;
  final String palika;
  final String wardNo;
  final String phone;
  final String area;
  final String reader;
  final String tapSize;
  final String meterNo;
  final double readingBill;
  final double dueBalance;
  final double advance;
  final double avgConsumption;
  final double lastPayAmount;
  final String lastPayDate;
  final String status;
  final String nextReadingDate;
  final String lastReadingDate;

  CustomerDetails({
    required this.cusID,
    required this.name,
    required this.palika,
    required this.wardNo,
    required this.phone,
    required this.area,
    required this.reader,
    required this.tapSize,
    required this.meterNo,
    required this.readingBill,
    required this.dueBalance,
    required this.advance,
    required this.avgConsumption,
    required this.lastPayAmount,
    required this.lastPayDate,
    required this.status,
    required this.nextReadingDate,
    required this.lastReadingDate,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerDetails(
      cusID: json['cusID']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      palika: json['palika'] as String? ?? '',
      wardNo: json['wardNo'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      area: json['area'] as String? ?? '',
      reader: json['reader'] as String? ?? '',
      tapSize: json['tapSize'] as String? ?? '',
      meterNo: json['meterNo']?.toString() ?? '',
      readingBill: (json['readingBill'] as num?)?.toDouble() ?? 0.0,
      dueBalance: (json['dueBalance'] as num?)?.toDouble() ?? 0.0,
      advance: (json['advance'] as num?)?.toDouble() ?? 0.0,
      avgConsumption: (json['avgConsumption'] as num?)?.toDouble() ?? 0.0,
      lastPayAmount: (json['lastPayAmount'] as num?)?.toDouble() ?? 0.0,
      lastPayDate: json['lastPayDate'] as String? ?? '',
      status: json['status'] as String? ?? '',
      nextReadingDate: json['nextReadingDate'] as String? ?? '',
      lastReadingDate: json['lastReadingDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cusID': cusID,
      'name': name,
      'palika': palika,
      'wardNo': wardNo,
      'phone': phone,
      'area': area,
      'reader': reader,
      'tapSize': tapSize,
      'meterNo': meterNo,
      'readingBill': readingBill,
      'dueBalance': dueBalance,
      'advance': advance,
      'avgConsumption': avgConsumption,
      'lastPayAmount': lastPayAmount,
      'lastPayDate': lastPayDate,
      'status': status,
      'nextReadingDate': nextReadingDate,
      'lastReadingDate': lastReadingDate,
    };
  }
}