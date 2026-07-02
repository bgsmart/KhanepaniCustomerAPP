// lib/models/customer_statement.dart
class StatementItem {
  final int sn;
  final String date;
  final int billNo;
  final String receiptNo;
  final int units;
  final double? billAmt;
  final double? paid;
  final double? penalty;
  final double? discount;
  final double? advance;

  StatementItem({
    required this.sn,
    required this.date,
    required this.billNo,
    required this.receiptNo,
    required this.units,
    this.billAmt,
    this.paid,
    this.penalty,
    this.discount,
    this.advance,
  });

  factory StatementItem.fromJson(Map<String, dynamic> json) {
    return StatementItem(
      sn: json['sn'] ?? 0,
      date: json['date'] ?? '',
      billNo: json['billNo'] ?? 0,
      receiptNo: json['receiptNo']?.toString() ?? '0',
      units: json['units'] ?? 0,
      billAmt: (json['billAmt'] ?? 0).toDouble(),
      paid: (json['paid'] ?? 0).toDouble(),
      penalty: (json['penalty'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      advance: (json['advance'] ?? 0).toDouble(),
    );
  }

  bool get isPayment => billNo == 0 && receiptNo != '0';
  bool get isBill => billNo != 0 && receiptNo == '0';
}

class StatementSummary {
  final double? totalBillAmt;
  final double? totalPaid;
  final double? totalPenalty;
  final double? totalDiscount;
  final double? totalAdvance;
  final double? netAmount;

  StatementSummary({
    this.totalBillAmt,
    this.totalPaid,
    this.totalPenalty,
    this.totalDiscount,
    this.totalAdvance,
    this.netAmount,
  });

  factory StatementSummary.fromJson(Map<String, dynamic> json) {
    return StatementSummary(
      totalBillAmt: (json['totalBillAmt'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
      totalPenalty: (json['totalPenalty'] ?? 0).toDouble(),
      totalDiscount: (json['totalDiscount'] ?? 0).toDouble(),
      totalAdvance: (json['totalAdvance'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
    );
  }
}

class CustomerStatementResponse {
  final bool success;
  final List<StatementItem> data;
  final StatementSummary? summary;
  final int count;
  final int customerID;
  final String fromDate;
  final String toDate;

  CustomerStatementResponse({
    required this.success,
    required this.data,
    this.summary,
    required this.count,
    required this.customerID,
    required this.fromDate,
    required this.toDate,
  });

  factory CustomerStatementResponse.fromJson(Map<String, dynamic> json) {
    return CustomerStatementResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => StatementItem.fromJson(item))
          .toList() ?? [],
      summary: json['summary'] != null ? StatementSummary.fromJson(json['summary']) : null,
      count: json['count'] ?? 0,
      customerID: json['customerID'] ?? 0,
      fromDate: json['fromDate'] ?? '',
      toDate: json['toDate'] ?? '',
    );
  }
}