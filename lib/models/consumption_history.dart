// lib/models/consumption_history.dart
class ConsumptionHistoryResponse {
  final bool success;
  final List<ConsumptionData> data;
  final int count;
  final int customerID;

  ConsumptionHistoryResponse({
    required this.success,
    required this.data,
    required this.count,
    required this.customerID,
  });

  factory ConsumptionHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ConsumptionHistoryResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => ConsumptionData.fromJson(item))
          .toList() ?? [],
      count: json['count'] ?? 0,
      customerID: json['customerID'] ?? 0,
    );
  }
}

class ConsumptionData {
  final String month;
  final int consumption;

  ConsumptionData({
    required this.month,
    required this.consumption,
  });

  factory ConsumptionData.fromJson(Map<String, dynamic> json) {
    return ConsumptionData(
      month: json['month'] ?? '',
      consumption: json['consumption'] ?? 0,
    );
  }
}