// lib/screens/notices_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notice_provider.dart';
import '../widgets/notice_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/dashboard/app_bar.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final List<String> _categories = ['All', 'Maintenance', 'Billing', 'Offers'];
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authProvider = context.watch<AuthProvider>();
    final noticeProvider = context.watch<NoticeProvider>();
    final user = authProvider.currentUser;
    final customerDetails = authProvider.customerDetails;
    final notices = noticeProvider.filteredNotices;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: DashboardAppBar(
        name: user?.name ?? 'User',
        wardNo: customerDetails?.wardNo ?? 'N/A',
        area: customerDetails?.area ?? 'N/A',
        palika: customerDetails?.palika ?? 'N/A',
        cusID: user?.customerId?.toString() ?? 'N/A',
        phone: customerDetails?.phone ?? 'N/A',
        meterNo: customerDetails?.meterNo ?? 'N/A',
        advance: customerDetails?.advance.toString() ?? "0",
        showBackButton: true,  // Enable back button
        onBackPressed: () => Navigator.pop(context),  // Navigate back
        onNotificationTap: () {
          // Already on notices screen, can refresh or show message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are already on Notices screen'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        onLogoutTap: () => _handleLogout(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notices',
                style: textTheme.displayLarge?.copyWith(
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Stay updated with service alerts and billing.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final isSelected = noticeProvider.selectedCategory == category.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) {
                          noticeProvider.filterByCategory(category.toLowerCase());
                        },
                        backgroundColor: colorScheme.surfaceContainerLowest,
                        selectedColor: colorScheme.primary,
                        labelStyle: textTheme.labelLarge?.copyWith(
                          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                        ),
                        side: isSelected 
                            ? BorderSide(color: colorScheme.primary.withOpacity(0.1))
                            : const BorderSide(color: Colors.transparent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Notices List
              Expanded(
                child: notices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notices found',
                              style: textTheme.displaySmall,
                            ),
                            Text(
                              'Try selecting a different category',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: notices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notice = notices[index];
                          return NoticeCard(
                            notice: notice,
                            onTap: () => noticeProvider.markAsRead(notice.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/consumption-history');
              break;
            case 2:
              // Already on notices
              break;
            case 3:
              Navigator.pushNamed(context, '/account-statement');
              break;
            case 4:
              Navigator.pushNamed(context, '/about');
              break;
          }
        },
      ),
    );
  }

  // Handle logout
  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await authProvider.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}