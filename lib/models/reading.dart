// lib/models/reading.dart
class Reading {
  final String id;
  final String meterId;
  final int previousReading;
  final int currentReading;
  final int unitsConsumed;
  final DateTime readingDate;
  final DateTime? submittedDate;
  final String status; // pending, approved, rejected

  Reading({
    required this.id,
    required this.meterId,
    required this.previousReading,
    required this.currentReading,
    required this.unitsConsumed,
    required this.readingDate,
    this.submittedDate,
    this.status = 'pending',
  });

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      id: json['id'] ?? '',
      meterId: json['meterId'] ?? '',
      previousReading: json['previousReading'] ?? 0,
      currentReading: json['currentReading'] ?? 0,
      unitsConsumed: json['unitsConsumed'] ?? 0,
      readingDate: DateTime.parse(json['readingDate'] ?? DateTime.now().toIso8601String()),
      submittedDate: json['submittedDate'] != null 
          ? DateTime.parse(json['submittedDate']) 
          : null,
      status: json['status'] ?? 'pending',
    );
  }
}