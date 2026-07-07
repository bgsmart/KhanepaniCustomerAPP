import 'package:flutter/material.dart';

class ReadingHistoryResponse {
  final bool success;
  final List<ReadingHistory>? data;
  final int count;
  final int customerID;
  final String fromDate;
  final String endDate;

  ReadingHistoryResponse({
    required this.success,
    this.data,
    required this.count,
    required this.customerID,
    required this.fromDate,
    required this.endDate,
  });

  factory ReadingHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ReadingHistoryResponse(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? List<ReadingHistory>.from(
              json['data'].map((x) => ReadingHistory.fromJson(x)))
          : [],
      count: json['count'] ?? 0,
      customerID: json['customerID'] ?? 0,
      fromDate: json['fromDate'] ?? '',
      endDate: json['endDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.map((x) => x.toJson()).toList(),
      'count': count,
      'customerID': customerID,
      'fromDate': fromDate,
      'endDate': endDate,
    };
  }
}

class ReadingHistory {
  final String readingDate;
  final int billNo;
  final int previousReading;
  final int currentReading;
  final int units;
  final double billAmount;
  final int? rno;
  final String status;

  ReadingHistory({
    required this.readingDate,
    required this.billNo,
    required this.previousReading,
    required this.currentReading,
    required this.units,
    required this.billAmount,
    this.rno,
    required this.status,
  });

  factory ReadingHistory.fromJson(Map<String, dynamic> json) {
    // Handle units - could be int or double
    int unitsValue = 0;
    if (json['units'] != null) {
      if (json['units'] is int) {
        unitsValue = json['units'];
      } else if (json['units'] is double) {
        unitsValue = (json['units'] as double).toInt();
      } else if (json['units'] is String) {
        unitsValue = int.tryParse(json['units']) ?? 0;
      }
    }

    // Handle billAmount - could be int or double
    double billAmountValue = 0;
    if (json['billAmt'] != null) {
      if (json['billAmt'] is double) {
        billAmountValue = json['billAmt'];
      } else if (json['billAmt'] is int) {
        billAmountValue = (json['billAmt'] as int).toDouble();
      } else if (json['billAmt'] is String) {
        billAmountValue = double.tryParse(json['billAmt']) ?? 0;
      }
    }

    return ReadingHistory(
      readingDate: json['readingDate']?.toString() ?? '',
      billNo: json['billNo'] as int? ?? 0,
      previousReading: json['preNum'] as int? ?? 0,
      currentReading: json['currNum'] as int? ?? 0,
      units: unitsValue,
      billAmount: billAmountValue,
      rno: json['rno'] as int?,
      status: json['status']?.toString() ?? 'Due',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'readingDate': readingDate,
      'billNo': billNo,
      'preNum': previousReading,
      'currNum': currentReading,
      'units': units,
      'billAmt': billAmount,
      'rno': rno,
      'status': status,
    };
  }

  // Helper Properties
  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isDue => status.toLowerCase() != 'paid';
  
  String get formattedBillAmount => 'Rs. ${billAmount.toInt()}';
  String get formattedUnits => '$units Units';
  String get billNumber => billNo.toString();
  String get previousReadingText => previousReading.toString();
  String get currentReadingText => currentReading.toString();
  String get rnoText => rno?.toString() ?? 'N/A';
  
  // Get month name from BS date (English)
  String get monthName {
    try {
      final parts = readingDate.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[1]);
        const englishMonths = [
          'Baisakh', 'Jestha', 'Ashad', 'Shrawan', 
          'Bhadra', 'Ashwin', 'Kartik', 'Mangsir', 
          'Poush', 'Magh', 'Falgun', 'Chaitra'
        ];
        if (month >= 1 && month <= 12) {
          return englishMonths[month - 1];
        }
      }
      return readingDate;
    } catch (e) {
      return readingDate;
    }
  }

  // Get formatted date (English)
  String get formattedDate {
    try {
      final parts = readingDate.split('/');
      if (parts.length == 3) {
        final year = parts[0];
        final month = int.parse(parts[1]);
        final day = parts[2];
        const englishMonths = [
          'Baisakh', 'Jestha', 'Ashad', 'Shrawan', 
          'Bhadra', 'Ashwin', 'Kartik', 'Mangsir', 
          'Poush', 'Magh', 'Falgun', 'Chaitra'
        ];
        if (month >= 1 && month <= 12) {
          return '${englishMonths[month - 1]} $day, $year';
        }
      }
      return readingDate;
    } catch (e) {
      return readingDate;
    }
  }

  // Get status color
  Color get statusColor {
    return isPaid ? Colors.green : Colors.red;
  }

  // Get status icon
  IconData get statusIcon {
    return isPaid ? Icons.check_circle : Icons.warning;
  }

  // Get status background color with opacity
  Color get statusBgColor {
    return isPaid ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25);
  }

  // Get status border color
  Color get statusBorderColor {
    return isPaid ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50);
  }
}