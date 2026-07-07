// lib/models/complaint.dart
import 'package:flutter/material.dart';

class Complaint {
  final String? id;
  final String customerId;
  final String complaintType;
  final String subject;
  final String description;
  final String? location;
  final double? latitude;
  final double? longitude;
  final List<String>? imageUrls;
  final String? status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Complaint({
    this.id,
    required this.customerId,
    required this.complaintType,
    required this.subject,
    required this.description,
    this.location,
    this.latitude,
    this.longitude,
    this.imageUrls,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id']?.toString(),
      customerId: json['customerId']?.toString() ?? '',
      complaintType: json['complaintType'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      location: json['location'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      imageUrls: json['imageUrls'] != null 
          ? List<String>.from(json['imageUrls']) 
          : null,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'complaintType': complaintType,
      'subject': subject,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper properties
  String get formattedDate => 
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  
  String get formattedTime => 
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  
  String get formattedDateTime => '$formattedDate at $formattedTime';
  
  Color get statusColor {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in-progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String get statusLabel {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in-progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return status ?? 'Unknown';
    }
  }
}

class ComplaintType {
  final String id;
  final String name;
  final String icon;

  ComplaintType({
    required this.id,
    required this.name,
    required this.icon,
  });

  static List<ComplaintType> get types => [
    ComplaintType(
      id: 'water_leakage',
      name: 'Water Leakage',
      icon: '💧',
    ),
    ComplaintType(
      id: 'no_water_supply',
      name: 'No Water Supply',
      icon: '🚱',
    ),
    ComplaintType(
      id: 'low_pressure',
      name: 'Low Water Pressure',
      icon: '💦',
    ),
    ComplaintType(
      id: 'water_quality',
      name: 'Water Quality Issue',
      icon: '🧪',
    ),
    ComplaintType(
      id: 'meter_issue',
      name: 'Meter Issue',
      icon: '📊',
    ),
    ComplaintType(
      id: 'billing_issue',
      name: 'Billing Issue',
      icon: '💰',
    ),
    ComplaintType(
      id: 'pipe_burst',
      name: 'Pipe Burst',
      icon: '🔧',
    ),
    ComplaintType(
      id: 'other',
      name: 'Other',
      icon: '📝',
    ),
  ];
}