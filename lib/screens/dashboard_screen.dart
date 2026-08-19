// lib/screens/dashboard_screen.dart
import 'package:KhanepaniApp/screens/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/dashboard/app_bar.dart';
import '../widgets/dashboard/stat_card.dart';
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

  // ✅ Safe navigation methods using addPostFrameCallback
  void _navigateToPayment() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PaymentScreen(),
          ),
        );
      }
    });
  }

  void _navigateTo(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushNamed(context, route);
      }
    });
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
        consumptionHistory.data.isNotEmpty) {
      _loadConsumptionDataFromAPI(consumptionHistory.data!);
    }

    // Calculate values from customer details
    String dueBalance = 'Rs. 0';
    if (customerDetails != null && customerDetails.readingBill != null && customerDetails.readingBill! > 0) {
      dueBalance = 'Rs. ${customerDetails.readingBill.toStringAsFixed(0)}';
    }

    String lastPaid = 'Rs. 0';
    if (customerDetails != null && customerDetails.lastPayAmount! > 0) {
      lastPaid = 'Rs. ${customerDetails.lastPayAmount.toStringAsFixed(0)}';
    }

    String avgConsumption = '${customerDetails?.avgConsumption.toStringAsFixed(0) ?? '0'} units';
    String readingBill = 'Rs. ${customerDetails?.readingBill.toStringAsFixed(0) ?? '0'}';
    String advance = 'Rs. ${customerDetails?.advance.toStringAsFixed(0) ?? '0'}';

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
        showCustomerInfo: false,
        onNotificationTap: () => _navigateTo('/notices'),
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
              // ✅ Customer Information Card
              if (customerDetails != null)
                _buildCustomerInfoCard(context, customerDetails, colorScheme, textTheme),

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

              // ✅ Due Balance and Status Cards - with Conditional Color
              _buildBudgetAndStatusCards(context, customerDetails),

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
                              'Consumption History',
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
                onSelfReadingTap: () => _navigateTo('/self-reading'),
                nextReadingDate: customerDetails?.nextReadingDate,
              ),

              const SizedBox(height: 16),

              // Quick Actions
              _buildQuickActions(context),

              const SizedBox(height: 16),

              // News & Alerts
              _buildNewsAndAlerts(context, colorScheme, textTheme),
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
              _navigateTo('/dashboard');
              break;
            case 1:
              _navigateTo('/reading-history');
              break;
            case 2:
              _navigateTo('/self-reading');
              break;
            case 3:
              _navigateTo('/account-statement');
              break;
            case 4:
              _navigateTo('/about');
              break;
          }
        },
      ),
    );
  }

  // ✅ Customer Information Card
  Widget _buildCustomerInfoCard(
    BuildContext context,
    customerDetails,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
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
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOMER INFORMATION',
            style: textTheme.labelLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
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
                customerDetails.name,
                Icons.person,
                Colors.white,
              ),
              _buildCustomerInfoItem(
                context,
                'Customer ID:',
                customerDetails.cusID,
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
                customerDetails.phone,
                Icons.phone,
                Colors.white,
              ),
              _buildCustomerInfoItem(
                context,
                'Meter No:',
                customerDetails.meterNo,
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
                'Address :',
                customerDetails.palika + "," + customerDetails.wardNo.toString(),
                Icons.location_city,
                Colors.white,
              ),
              _buildCustomerInfoItem(
                context,
                'Area:',
                customerDetails.area,
                Icons.map,
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Budget and Status Cards Builder - with Conditional Color
  Widget _buildBudgetAndStatusCards(BuildContext context, customerDetails) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = customerDetails?.status?.toLowerCase() == 'active';
    final dueBalance = customerDetails?.readingBill ?? 0.0;
    
    // ✅ Determine if due balance is greater than 0
    final bool hasDueBalance = dueBalance > 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Card: Due Balance - with Conditional Background
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                // ✅ Conditional Gradient based on due balance
                gradient: hasDueBalance
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.errorContainer,
                          colorScheme.errorContainer.withOpacity(0.8),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: hasDueBalance
                        ? colorScheme.error.withOpacity(0.2)
                        : colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Label and Amount
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasDueBalance ? "Due Balance" : "No Due",
                          style: TextStyle(
                            color: hasDueBalance
                                ? colorScheme.onErrorContainer
                                : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${dueBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: hasDueBalance
                                ? colorScheme.onErrorContainer
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right side: Pay Button
                  // Expanded(
                  //   flex: 1,
                  //   child: ElevatedButton(
                  //     onPressed: _navigateToPayment,
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.white,
                  //       foregroundColor: hasDueBalance 
                  //           ? colorScheme.error 
                  //           : colorScheme.primary,
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: 12,
                  //         vertical: 6,
                  //       ),
                  //       minimumSize: Size.zero,
                  //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(20),
                  //       ),
                  //     ),
                  //     child: Text(
                  //       hasDueBalance ? "Pay" : "Paid ✓",
                  //       style: TextStyle(
                  //         fontWeight: FontWeight.w600,
                  //         fontSize: 10,
                  //         color: hasDueBalance 
                  //             ? colorScheme.error 
                  //             : colorScheme.primary,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Right Card: Status
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive
                      ? [Colors.green.shade700, Colors.green.shade500]
                      : [Colors.orange.shade700, Colors.orange.shade500],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Status indicator dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Status text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Status",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customerDetails?.status ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Quick Actions
  Widget _buildQuickActions(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: textTheme.displaySmall,
        ),
        const SizedBox(height: 12),
        
        // Row 1
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            QuickAction(
              icon: Icons.account_circle,
              label: 'Account',
              onTap: () => _navigateTo('/account-statement'),
            ),
            QuickAction(
              icon: Icons.history,
              label: 'History',
              onTap: () => _navigateTo('/reading-history'),
            ),
            QuickAction(
              icon: Icons.camera_alt,
              label: 'Self Read',
              onTap: () => _navigateTo('/self-reading'),
            ),
            QuickAction(
              icon: Icons.event_note,
              label: 'Schedule',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Schedule feature coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Row 2
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            QuickAction(
              icon: Icons.campaign,
              label: 'Complaint',
              onTap: () => _navigateTo('/complaint'),
            ),
            QuickAction(
              icon: Icons.newspaper,
              label: 'News',
              onTap: () => _navigateTo('/notices'),
            ),
            QuickAction(
              icon: Icons.payment,
              label: 'Utility Payment',
              onTap: _navigateToPayment,
            ),
            QuickAction(
              icon: Icons.receipt_long,
              label: 'Bills',
              onTap: () => _navigateTo('/account-statement'),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ News & Alerts
  Widget _buildNewsAndAlerts(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'News & Alerts',
              style: textTheme.displaySmall,
            ),
            TextButton(
              onPressed: () => _navigateTo('/notices'),
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
      ],
    );
  }

  // ✅ Customer Info Item Builder
  Widget _buildCustomerInfoItem(BuildContext context, String label, String value, IconData icon, Color textColor) {
    final textTheme = Theme.of(context).textTheme;

    return Flexible(
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: textColor.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: textColor.withOpacity(0.6),
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
        _navigateTo('/login');
      }
    }
  }

  // Load consumption data from API
  void _loadConsumptionDataFromAPI(List<ConsumptionData> data) {
    if (data.isEmpty) return;
    
    final List<double> newData = [];
    final List<String> newMonths = [];
    
    final sortedData = List<ConsumptionData>.from(data)
      ..sort((a, b) => a.month.compareTo(b.month));
    
    for (var item in sortedData) {
      newData.add(item.consumption.toDouble());
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
    try {
      final parts = monthStr.split('/');
      if (parts.length == 2) {
        final monthNum = int.parse(parts[1]);
        
        const nepaliMonths = [
          'बैशाख', 'जेठ', 'असार', 'साउन', 
          'भदौ', 'असोज', 'कात्तिक', 'मंसिर', 
          'पुष', 'माघ', 'फागुन', 'चैत'
        ];
        
        if (monthNum >= 1 && monthNum <= 12) {
          return nepaliMonths[monthNum - 1];
        }
      }
      return monthStr;
    } catch (e) {
      return monthStr;
    }
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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