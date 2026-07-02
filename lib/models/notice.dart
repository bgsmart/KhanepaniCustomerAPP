// lib/models/notice.dart
class Notice {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime timestamp;
  final bool isNew;
  final String? imageUrl;
  final String? actionLabel;

  Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
    this.isNew = false,
    this.imageUrl,
    this.actionLabel,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'general',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isNew: json['isNew'] ?? false,
      imageUrl: json['imageUrl'],
      actionLabel: json['actionLabel'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'isNew': isNew,
      'imageUrl': imageUrl,
      'actionLabel': actionLabel,
    };
  }
}