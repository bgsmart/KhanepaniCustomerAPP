// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/dashboard/app_bar.dart';
import '../widgets/dashboard/stat_card.dart';
import '../widgets/dashboard/budget_card.dart';
import '../widgets/dashboard/line_graph.dart';
import '../widgets/dashboard/quick_action.dart';
import '../widgets/dashboard/self_reading_card.dart';
import '../models/consumption_history.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  // Consumption data
  List<double> _consumptionData = [];
  List<String> _months = [];
  
  @override
  void initState() {
    super.initState();
    _loadConsumptionData();
  }

  void _loadConsumptionData() {
    // Default sample data if no API data available
    _consumptionData = [122, 108, 112, 120, 110, 95, 84, 96, 92, 107, 119, 145];
    _months = [
      'बैशाख', 'जेठ', 'असार', 'साउन', 
      'भदौ', 'असोज', 'कात्तिक', 'मंसिर', 
      'पुष', 'माघ', 'फागुन', 'चैत'
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final customerDetails = authProvider.customerDetails;
    final consumptionHistory = authProvider.consumptionHistory;

    // Update consumption data from API if available
    if (consumptionHistory != null && 
        consumptionHistory.data != null && 
        consumptionHistory.data!.isNotEmpty) {
      _loadConsumptionDataFromAPI(consumptionHistory.data!);
    }

    // Calculate values from customer details
    String dueBalance = 'Rs. 0';
    if (customerDetails != null && customerDetails.readingBill != null && customerDetails.readingBill! > 0) {
      dueBalance = 'Rs. ${customerDetails.readingBill!.toStringAsFixed(0)}';
    }

    String lastPaid = 'Rs. 0';
    if (customerDetails != null && customerDetails.lastPayAmount != null && customerDetails.lastPayAmount! > 0) {
      lastPaid = 'Rs. ${customerDetails.lastPayAmount!.toStringAsFixed(0)}';
    }

    String avgConsumption = '${customerDetails?.avgConsumption?.toStringAsFixed(0) ?? '0'} units';
    String readingBill = 'Rs. ${customerDetails?.readingBill?.toStringAsFixed(0) ?? '0'}';
    String advance = 'Rs. ${customerDetails?.advance?.toStringAsFixed(0) ?? '0'}';
    

    // Determine status
    String statusText = 'Active';
    Color statusColor = colorScheme.secondary;

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
        showCustomerInfo: false, // ✅ Hide customer info in AppBar
        onNotificationTap: () => Navigator.pushNamed(context, '/notices'),
        onLogoutTap: () => _handleLogout(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Customer Information Card (Like Summary)
              if (customerDetails != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        const Color.fromARGB(255, 2, 54, 166),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'CUSTOMER INFORMATION',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Row 1: Customer Name and ID
                      Row(
                        children: [
                          _buildCustomerInfoItem(
                            context,
                            'Name:',
                            customerDetails.name ?? 'N/A',
                            Icons.person,
                            Colors.white,
                          ),
                          _buildCustomerInfoItem(
                            context,
                            'Customer ID:',
                            customerDetails.cusID ?? 'N/A',
                            Icons.badge,
                            Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Row 2: Phone and Meter No
                      Row(
                        children: [
                          _buildCustomerInfoItem(
                            context,
                            'Phone:',
                            customerDetails.phone ?? 'N/A',
                            Icons.phone,
                            Colors.white,
                          ),
                          _buildCustomerInfoItem(
                            context,
                            'Meter No:',
                            customerDetails.meterNo ?? customerDetails.cusID ?? 'N/A',
                            Icons.speed,
                            Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Row 3: Ward and Area
                      Row(
                        children: [
                          _buildCustomerInfoItem(
                            context,
                            'Ward:',
                            customerDetails.wardNo?.toString() ?? 'N/A',
                            Icons.location_city,
                            Colors.white,
                          ),
                          _buildCustomerInfoItem(
                            context,
                            'Area:',
                            customerDetails.area ?? 'N/A',
                            Icons.map,
                            Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.bar_chart,
                      label: 'Avg / Month',
                      value: avgConsumption,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.account_balance_wallet,
                      label: 'Advance',
                      value: advance,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.history,
                      label: 'Last Paid',
                      value: lastPaid,
                      color: colorScheme.tertiary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Budget Cards Row - Due Balance (Left) and Status (Right)
              Row(
                children: [
                  // Due Balance Card (Left side - flex 2)
                  Expanded(
                    flex: 2,
                    child: BudgetCard(
                      title: 'Due Balance',
                      amount: dueBalance,
                      icon: Icons.payments,
                      backgroundColor: colorScheme.primary,
                      textColor: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Card (Right side - flex 1)
                  Expanded(
                    flex: 1,
                    child: BudgetCard(
                      title: 'Status',
                      amount: statusText,
                      icon: Icons.check_circle,
                      backgroundColor: statusColor,
                      textColor: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Consumption History - Line Graph
              Card(
                color: colorScheme.surfaceContainerLowest,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Consumption History (2081-2082)',
                              style: textTheme.displaySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Monthly',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(
                                Icons.expand_more,
                                size: 20,
                                color: Color(0xFF0058BC),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_consumptionData.isNotEmpty && _months.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: LineGraph(
                            data: _consumptionData,
                            months: _months,
                            color: colorScheme.primary,
                            fillColor: colorScheme.primary.withOpacity(0.1),
                            height: 200,
                          ),
                        )
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text('No consumption data available'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Self Reading Card
              SelfReadingCard(
                onSelfReadingTap: () => Navigator.pushNamed(context, '/self-reading'),
                nextReadingDate: customerDetails?.nextReadingDate,
              ),

              const SizedBox(height: 16),

              // Quick Actions
              Text(
                'Quick Actions',
                style: textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  QuickAction(
                    icon: Icons.account_circle,
                    label: 'Account',
                    onTap: () => Navigator.pushNamed(context, '/account-details'),
                  ),
                  QuickAction(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () => Navigator.pushNamed(context, '/consumption-history'),
                  ),
                  QuickAction(
                    icon: Icons.camera_alt,
                    label: 'Self Read',
                    onTap: () => Navigator.pushNamed(context, '/self-reading'),
                  ),
                  QuickAction(
                    icon: Icons.event_note,
                    label: 'Schedule',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  QuickAction(
                    icon: Icons.campaign,
                    label: 'Complaint',
                    onTap: () => Navigator.pushNamed(context, '/complaint'),
                  ),
                  QuickAction(
                    icon: Icons.newspaper,
                    label: 'News',
                    onTap: () => Navigator.pushNamed(context, '/notices'),
                  ),
                  QuickAction(
                    icon: Icons.support_agent,
                    label: 'Assistance',
                    onTap: () {},
                  ),
                  QuickAction(
                    icon: Icons.receipt_long,
                    label: 'Bills',
                    onTap: () => Navigator.pushNamed(context, '/account-statement'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // News & Alerts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'News & Alerts',
                    style: textTheme.displaySmall,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/notices'),
                    child: Text(
                      'View all',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 230,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildNewsCard(
                      context,
                      'Regular Pipe Maintenance in Ward 4',
                      'Expected water disruption on June 12th between 10 AM to 2 PM for technical upgrades.',
                      'Maintenance',
                    ),
                    const SizedBox(width: 12),
                    _buildNewsCard(
                      context,
                      'Early Payment Bonus Active',
                      'Pay your bill within 5 days of generation to get 5% cashback on your next reading.',
                      'Offer',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
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
              Navigator.pushNamed(context, '/self-reading');
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

  // ✅ Customer Info Item Builder
  Widget _buildCustomerInfoItem(BuildContext context, String label, String value, IconData icon, Color textColor) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: textColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: textTheme.displaySmall?.copyWith(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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

  // Load consumption data from API
  void _loadConsumptionDataFromAPI(List<ConsumptionData> data) {
    if (data.isEmpty) return;
    
    final List<double> newData = [];
    final List<String> newMonths = [];
    
    // Sort data by month to ensure correct order
    final sortedData = List<ConsumptionData>.from(data)
      ..sort((a, b) => a.month.compareTo(b.month));
    
    // Convert Nepali month format to readable format
    for (var item in sortedData) {
      newData.add(item.consumption.toDouble());
      
      // Convert "2081/04" to Nepali month name
      String monthLabel = _convertNepaliMonth(item.month);
      newMonths.add(monthLabel);
    }
    
    setState(() {
      _consumptionData = newData;
      _months = newMonths;
    });
  }

  // Convert Nepali month string to readable month name
  String _convertNepaliMonth(String monthStr) {
    // monthStr format: "2081/04" where 04 is the month number
    try {
      final parts = monthStr.split('/');
      if (parts.length == 2) {
        final monthNum = int.parse(parts[1]);
        
        // Nepali month names (BS calendar)
        const nepaliMonths = [
          'बैशाख',  // 1
          'जेठ',    // 2
          'असार',   // 3
          'साउन',   // 4
          'भदौ',    // 5
          'असोज',   // 6
          'कात्तिक', // 7
          'मंसिर',   // 8
          'पुष',     // 9
          'माघ',     // 10
          'फागुन',   // 11
          'चैत'      // 12
        ];
        
        if (monthNum >= 1 && monthNum <= 12) {
          return nepaliMonths[monthNum - 1];
        }
      }
      return monthStr; // fallback
    } catch (e) {
      return monthStr; // fallback
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, String title, String description, String tag) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 280,
      constraints: const BoxConstraints(
        minHeight: 180,
        maxHeight: 220,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image Container
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(
                Icons.image,
                size: 48,
                color: colorScheme.outline,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tag == 'Maintenance' 
                        ? colorScheme.tertiaryFixed 
                        : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: textTheme.labelLarge?.copyWith(
                      color: tag == 'Maintenance' 
                          ? colorScheme.onTertiaryFixedVariant 
                          : colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Title
                Text(
                  title,
                  style: textTheme.displaySmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Description
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}