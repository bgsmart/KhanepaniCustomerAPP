// lib/providers/notice_provider.dart
import 'package:flutter/material.dart';
import '../models/notice.dart';

class NoticeProvider extends ChangeNotifier {
  List<Notice> _notices = [];
  String _selectedCategory = 'all';
  bool _isLoading = false;

  List<Notice> get notices => _notices;
  List<Notice> get filteredNotices {
    if (_selectedCategory == 'all') {
      return _notices;
    }
    return _notices.where((n) => n.category == _selectedCategory).toList();
  }
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  NoticeProvider() {
    _loadMockNotices();
  }

  void _loadMockNotices() {
    _notices = [
      Notice(
        id: '1',
        title: 'Scheduled Pipe Maintenance',
        description: 'Essential repairs in Ward 7 might result in temporary low pressure between 10 PM and 4 AM tonight.',
        category: 'maintenance',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isNew: true,
        actionLabel: 'Details',
      ),
      Notice(
        id: '2',
        title: 'Bill Reminder: Oct 2023',
        description: 'Your water bill for October is due in 3 days. Total amount: 42.50. Tap to pay now.',
        category: 'billing',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        actionLabel: 'Pay Now',
      ),
      Notice(
        id: '3',
        title: 'Smart Meter Upgrade',
        description: 'Upgrade to a digital smart meter for real-time usage tracking. Early bird discount available.',
        category: 'offers',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        isNew: true,
        actionLabel: 'View Offer',
      ),
      Notice(
        id: '4',
        title: 'Conservation Tips',
        description: 'Join our \'Green Flow\' initiative and save up to 15% on your monthly bill.',
        category: 'offers',
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        imageUrl: 'https://example.com/conservation.jpg',
        actionLabel: 'Read Guide',
      ),
    ];
    notifyListeners();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void markAsRead(String noticeId) {
    final index = _notices.indexWhere((n) => n.id == noticeId);
    if (index != -1) {
      _notices[index] = Notice(
        id: _notices[index].id,
        title: _notices[index].title,
        description: _notices[index].description,
        category: _notices[index].category,
        timestamp: _notices[index].timestamp,
        isNew: false,
        imageUrl: _notices[index].imageUrl,
        actionLabel: _notices[index].actionLabel,
      );
      notifyListeners();
    }
  }
}