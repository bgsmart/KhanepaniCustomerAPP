// lib/screens/account_statement_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nepali_utils/nepali_utils.dart';
import 'package:provider/provider.dart';
import '../models/customer_statement.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/dashboard/app_bar.dart';
import '../widgets/nepali_date_picker_dialog.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AccountStatementScreen extends StatefulWidget {
  const AccountStatementScreen({super.key});

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  int _currentIndex = 3;
  String _selectedFilter = 'All';
  CustomerStatementResponse? _statementResponse;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;

  // Date range in BS (Nepali) format
  String _fromDateBS = '';
  String _toDateBS = '';

  // Company Details
  final String companyName = 'हेटौडा खानेपानी ब्यवस्थापन बोर्ड';
  final String companyAddress = 'हेटौडा २, मकवानपुर';
  final String companyPhone = '9855072264';
  final String companyEmail = 'info@hwsboard.gov.np';

  // Filter colors
  final Map<String, Color> _filterColors = {
    'All': Colors.blue,
    'Bills': Colors.blue,
    'Payments': Colors.green,
    'Due': Colors.red,
  };

  // English month names
  final List<String> _englishMonths = [
    'Baisakh', 'Jestha', 'Ashad', 'Shrawan', 'Bhadra', 'Ashwin',
    'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'
  ];

  @override
  void initState() {
    super.initState();
    _setDefaultDates();
    _fetchStatement();
  }

  void _setDefaultDates() {
    final now = NepaliDateTime.now();
    _toDateBS = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
    
    final sixMonthsAgo = now.subtract(const Duration(days: 180));
    _fromDateBS = '${sixMonthsAgo.year}/${sixMonthsAgo.month.toString().padLeft(2, '0')}/${sixMonthsAgo.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchStatement() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final customerId = int.parse(authProvider.customerDetails?.cusID ?? '0');
      
      if (customerId == 0) {
        throw Exception('Customer ID not found');
      }

      final response = await ApiService.getCustomerStatement(
        customerID: customerId,
        fromDate: _fromDateBS,
        toDate: _toDateBS,
      );

      setState(() {
        _statementResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Bills filter shows ALL bills (both paid and due)
  List<StatementItem> get _filteredStatements {
    if (_statementResponse == null) return [];
  
    switch (_selectedFilter) {
      case 'All':
        return _statementResponse!.data;
      case 'Bills':
        return _statementResponse!.data.where((s) => s.billNo > 0).toList();
      case 'Payments':
        return _statementResponse!.data.where((s) => s.isPayment).toList();
      case 'Due':
        return _statementResponse!.data.where((s) => _isBillDue(s)).toList();
      default:
        return _statementResponse!.data;
    }
  }

  // Total Bill Amount = sum of BillAmt from all bills (billNo > 0)
  double get _totalBillAmount {
    if (_statementResponse == null) return 0.0;
    return _statementResponse!.data
        .where((item) => item.billNo > 0)
        .fold(0.0, (sum, item) => sum + (item.billAmt ?? 0));
  }

  // Total Payment = sum of Paid from all payments (receiptNo != '0')
  double get _totalPayment {
    if (_statementResponse == null) return 0.0;
    return _statementResponse!.data
        .where((item) => item.receiptNo != '0')
        .fold(0.0, (sum, item) => sum + (item.paid ?? 0));
  }

  // Total Penalty = sum of Penalty from all items (penalty > 0)
  double get _totalPenalty {
    if (_statementResponse == null) return 0.0;
    return _statementResponse!.data
        .where((item) => item.penalty != null && item.penalty! > 0)
        .fold(0.0, (sum, item) => sum + (item.penalty ?? 0));
  }

  // Total Discount = sum of Discount from all items (discount < 0)
  double get _totalDiscount {
    if (_statementResponse == null) return 0.0;
    return _statementResponse!.data
        .where((item) => item.discount != null && item.discount! < 0)
        .fold(0.0, (sum, item) => sum + (item.discount ?? 0));
  }

  // Total Advance = sum of Advance from all items (advance > 0)
  double get _totalAdvance {
    if (_statementResponse == null) return 0.0;
    return _statementResponse!.data
        .where((item) => item.advance != null && item.advance! > 0)
        .fold(0.0, (sum, item) => sum + (item.advance ?? 0));
  }

  // Due Amount = Total Bill - Total Payment + Total Penalty - Total Discount - Total Advance
  double get _dueAmount {
    return _totalBillAmount - _totalPayment + _totalPenalty - _totalDiscount.abs() - _totalAdvance;
  }

  // Check if bill is due (no receipt)
  bool _isBillDue(StatementItem item) {
    if (item.billNo <= 0) return false;
    return !_statementResponse!.data.any((receipt) =>
      receipt.receiptNo != '0' &&           
      receipt.billAmt == item.billAmt &&    
      receipt.date == item.date             
    );
  }

  // Group bills by month with English month names
  Map<String, List<StatementItem>> get _groupedByMonth {
    final Map<String, List<StatementItem>> grouped = {};
    
    for (final item in _filteredStatements) {
      final parts = item.date.split('/');
      if (parts.length == 3) {
        final year = parts[0];
        final month = int.parse(parts[1]);
        // Use English month name
        final monthName = _englishMonths[month - 1];
        final key = '$year $monthName';
        
        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(item);
      }
    }
    return grouped;
  }

  String _formatBSDateForDisplay(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final year = parts[0];
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final monthName = _englishMonths[month - 1];
        return '$year $monthName $day';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthYearForTitle(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final year = parts[0];
        final month = int.parse(parts[1]);
        final monthName = _englishMonths[month - 1];
        return '$year-$monthName';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authProvider = context.watch<AuthProvider>();
    final customerDetails = authProvider.customerDetails;
    final groupedData = _groupedByMonth;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: DashboardAppBar(
        name: customerDetails?.name ?? 'User',
        wardNo: customerDetails?.wardNo ?? 'N/A',
        area: customerDetails?.area ?? 'N/A',
        palika: customerDetails?.palika ?? 'N/A',
        cusID: customerDetails?.cusID ?? 'N/A',
        phone: customerDetails?.phone ?? 'N/A',
        meterNo: customerDetails?.meterNo ?? 'N/A',
        advance: customerDetails?.advance.toString()??"0",

        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        onNotificationTap: () => Navigator.pushNamed(context, '/notices'),
        onLogoutTap: () => _handleLogout(context),
        onSettingsTap: () => Navigator.pushNamed(context, '/settings'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Card with 2 items per row
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SUMMARY',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                            onPressed: () => _showDateFilterDialog(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: _isDownloading 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download, color: Colors.white),
                            onPressed: _isDownloading ? null : _downloadPDF,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Row 1: Total Bill and Total Payment
                  Row(
                    children: [
                      _buildSummaryItem(
                        context,
                        'Total Bill',
                        'Rs. ${_totalBillAmount.toStringAsFixed(2)}',
                        Icons.receipt_long,
                        Colors.white,
                      ),
                      _buildSummaryItem(
                        context,
                        'Total Payment',
                        'Rs. ${_totalPayment.toStringAsFixed(2)}',
                        Icons.payments,
                        Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Row 2: Total Penalty and Total Discount
                  Row(
                    children: [
                      _buildSummaryItem(
                        context,
                        'Total Penalty',
                        'Rs. ${_totalPenalty.toStringAsFixed(2)}',
                        Icons.warning_amber,
                        Colors.white,
                      ),
                      _buildSummaryItem(
                        context,
                        'Total Discount',
                        'Rs. ${_totalDiscount.abs().toStringAsFixed(2)}',
                        Icons.discount,
                        Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Row 3: Total Advance and Due Amount
                  Row(
                    children: [
                      _buildSummaryItem(
                        context,
                        'Total Advance',
                        'Rs. ${_totalAdvance.toStringAsFixed(2)}',
                        Icons.account_balance,
                        Colors.white,
                      ),
                      _buildSummaryItem(
                        context,
                        'Due Amount',
                        'Rs. ${_dueAmount.toStringAsFixed(2)}',
                        Icons.account_balance,
                        Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Range Display
                  InkWell(
                    onTap: () => _showDateFilterDialog(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'From: ${_formatBSDateForDisplay(_fromDateBS)}',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'To: ${_formatBSDateForDisplay(_toDateBS)}',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', 'Bills', 'Payments', 'Due'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  final filterColor = _filterColors[filter] ?? colorScheme.primary;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      selectedColor: filterColor.withValues(alpha: 0.2),
                      checkmarkColor: filterColor,
                      labelStyle: textTheme.labelLarge?.copyWith(
                        color: isSelected ? filterColor : colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      avatar: isSelected
                          ? Icon(
                              filter == 'Payments' ? Icons.payments : 
                              filter == 'Bills' ? Icons.receipt_long : 
                              filter == 'Due' ? Icons.warning : 
                              Icons.filter_list,
                              size: 16,
                              color: filterColor,
                            )
                          : null,
                      side: BorderSide(
                        color: isSelected ? filterColor : colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Grouped Transaction List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                              const SizedBox(height: 16),
                              Text('Error loading statement', style: textTheme.displaySmall),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchStatement,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : groupedData.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_toggle_off, size: 64, color: colorScheme.outline),
                                  const SizedBox(height: 16),
                                  Text('No records found', style: textTheme.displaySmall),
                                  Text(
                                    'Try adjusting your filter or date range',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: groupedData.keys.length,
                              itemBuilder: (context, index) {
                                final monthKey = groupedData.keys.elementAt(index);
                                final items = groupedData[monthKey]!;
                                final monthParts = monthKey.split(' ');
                                final monthName = monthParts.length > 1 ? monthParts[1] : monthKey;
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Month Header
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        children: [
                                          Text(
                                            '# $monthName ${monthParts[0]}',
                                            style: textTheme.displaySmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: colorScheme.outlineVariant,
                                              margin: const EdgeInsets.only(left: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...items.map((item) => _buildNewStyleCard(context, item)),
                                    const SizedBox(height: 8),
                                  ],
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/consumption-history');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/self-reading');
              break;
            case 3:
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/about');
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

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, Color textColor) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 14,
                color: textColor.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: textTheme.displaySmall?.copyWith(
                      color: textColor,
                      fontSize: 13,
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
      ),
    );
  }

  Widget _buildChip(BuildContext context, String text, String type) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color getBgColor() {
      switch (type) {
        case 'billNo':
          return colorScheme.primaryContainer.withValues(alpha: 0.15);
        case 'receipt':
          return colorScheme.secondaryContainer.withValues(alpha: 0.2);
        case 'units':
          return colorScheme.tertiaryContainer.withValues(alpha: 0.15);
        case 'discount':
          return colorScheme.primaryContainer.withValues(alpha: 0.15);
        case 'penalty':
          return colorScheme.errorContainer.withValues(alpha: 0.2);
        case 'advance':
          return colorScheme.secondaryContainer.withValues(alpha: 0.15);
        default:
          return colorScheme.surfaceContainerLow;
      }
    }

    Color getTextColor() {
      switch (type) {
        case 'billNo':
          return colorScheme.primary;
        case 'receipt':
          return colorScheme.secondary;
        case 'units':
          return colorScheme.tertiary;
        case 'discount':
          return colorScheme.primary;
        case 'penalty':
          return colorScheme.error;
        case 'advance':
          return colorScheme.secondary;
        default:
          return colorScheme.onSurfaceVariant;
      }
    }

    IconData getIcon() {
      switch (type) {
        case 'billNo':
          return Icons.receipt_outlined;
        case 'receipt':
          return Icons.payments_outlined;
        case 'units':
          return Icons.water_drop_outlined;
        case 'discount':
          return Icons.discount_outlined;
        case 'penalty':
          return Icons.warning_amber_outlined;
        case 'advance':
          return Icons.account_balance_outlined;
        default:
          return Icons.info_outline;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: getBgColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getTextColor().withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getIcon(),
            size: 12,
            color: getTextColor(),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: textTheme.labelLarge?.copyWith(
              fontSize: 9,
              color: getTextColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewStyleCard(BuildContext context, StatementItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isPayment = item.isPayment;
    final isDue = _isBillDue(item);

    // If units is 0, bill amount should be 0
    final displayBillAmt = (item.units == 0) ? 0.0 : (item.billAmt ?? 0.0);

    String getTitle() {
      if (isPayment) {
        return 'Bill Payment for ${_getMonthYearForTitle(item.date)}';
      } else {
        return 'Monthly Bill of ${_getMonthYearForTitle(item.date)}';
      }
    }

    String getSubtitle() {
      // Description: Date and Bill/Receipt No
      String description = _formatBSDateForDisplay(item.date);
      if (item.billNo > 0) {
        description += ' | Bill No: ${item.billNo}';
      }
      if (item.receiptNo != '0') {
        description += ' | Receipt No: ${item.receiptNo}';
      }
      return description;
    }

    IconData getIcon() {
      if (isPayment) {
        return Icons.payments;
      } else if (isDue) {
        return Icons.warning;
      } else {
        return Icons.receipt_long;
      }
    }

    Color getIconColor() {
      if (isPayment) {
        return colorScheme.secondary;
      } else if (isDue) {
        return colorScheme.error;
      } else {
        return colorScheme.primary;
      }
    }

    Color getIconBgColor() {
      if (isPayment) {
        return colorScheme.secondaryContainer.withValues(alpha: 0.2);
      } else if (isDue) {
        return colorScheme.errorContainer.withValues(alpha: 0.3);
      } else {
        return colorScheme.primaryContainer.withValues(alpha: 0.2);
      }
    }

    String getAmount() {
      if (isPayment) {
        return 'Rs. ${item.paid?.toStringAsFixed(2) ?? '0.00'}';
      } else {
        return 'Rs. ${displayBillAmt.toStringAsFixed(2)}';
      }
    }

    Color getAmountColor() {
      if (isPayment) {
        return colorScheme.secondary;
      } else if (isDue) {
        return colorScheme.error;
      } else {
        return colorScheme.primary;
      }
    }

    return Card(
      color: isDue
          ? colorScheme.errorContainer.withValues(alpha: 0.08)
          : colorScheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDue
              ? colorScheme.error.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: isDue ? 2 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon, Title, Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: getIconBgColor(),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          getIcon(),
                          color: getIconColor(),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTitle(),
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Description: Date and Bill/Receipt No
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    getSubtitle(),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: isDue ? colorScheme.error : colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (isDue) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.error,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'DUE',
                                      style: textTheme.labelLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                                if (isPayment) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'PAID',
                                      style: textTheme.labelLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      getAmount(),
                      style: textTheme.displaySmall?.copyWith(
                        color: getAmountColor(),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isDue)
                      Text(
                        'Unpaid',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 10),

            // Bottom: Details with chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (item.billNo > 0)
                        _buildChip(context, 'Bill No: ${item.billNo}', 'billNo'),
                      if (item.receiptNo != '0')
                        _buildChip(context, 'Receipt: ${item.receiptNo}', 'receipt'),
                      if (item.units > 0)
                        _buildChip(context, 'Units: ${item.units}', 'units'),
                      if (item.discount != null && item.discount! < 0)
                        _buildChip(context, 'Discount: Rs. ${item.discount!.abs().toStringAsFixed(2)}', 'discount'),
                      if (item.penalty != null && item.penalty! > 0)
                        _buildChip(context, 'Penalty: Rs. ${item.penalty?.toStringAsFixed(2) ?? '0.00'}', 'penalty'),
                      if (item.advance != null && item.advance! > 0)
                        _buildChip(context, 'Advance: Rs. ${item.advance?.toStringAsFixed(2) ?? '0.00'}', 'advance'),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPayment
                        ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
                        : isDue
                            ? colorScheme.errorContainer.withValues(alpha: 0.3)
                            : colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    isPayment ? 'Paid' : isDue ? 'Due' : 'Bill',
                    style: textTheme.labelLarge?.copyWith(
                      color: isPayment
                          ? colorScheme.onSecondaryContainer
                          : isDue
                              ? colorScheme.error
                              : colorScheme.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // PDF Download - Open directly without sharing
  Future<void> _downloadPDF() async {
    if (_statementResponse == null || _statementResponse!.data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to download'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      // Try to load Nepali font if available
      pw.Font? font;
      try {
        final fontData = await rootBundle.load('assets/fonts/mangal.ttf');
        font = pw.Font.ttf(fontData.buffer.asByteData());
      } catch (e) {
        // Font not available, use default
        font = null;
      }

      final pdf = pw.Document();
      final customerDetails = context.read<AuthProvider>().customerDetails;

      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            // Company Header
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      font: font,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    companyAddress,
                    style: pw.TextStyle(fontSize: 12, font: font),
                  ),
                  pw.Text(
                    'Phone: $companyPhone',
                    style: pw.TextStyle(fontSize: 10, font: font),
                  ),
                  pw.Text(
                    'Email: $companyEmail',
                    style: pw.TextStyle(fontSize: 10, font: font),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 8),
                ],
              ),
            ),
            
            // Customer Details
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Customer Details',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      font: font,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text('Name: ${customerDetails?.name ?? 'N/A'}', style: pw.TextStyle(font: font)),
                      ),
                      pw.Expanded(
                        child: pw.Text('CustomerID: ${customerDetails?.cusID ?? 'N/A'}', style: pw.TextStyle(font: font)),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text('Phone: ${customerDetails?.phone ?? 'N/A'}', style: pw.TextStyle(font: font)),
                      ),
                      pw.Expanded(
                        child: pw.Text('Ward: ${customerDetails?.wardNo ?? 'N/A'}', style: pw.TextStyle(font: font)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 8),
            
            // Date Range
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'From: ${_formatBSDateForDisplay(_fromDateBS)}',
                  style: pw.TextStyle(fontSize: 10, font: font),
                ),
                pw.Text(
                  'To: ${_formatBSDateForDisplay(_toDateBS)}',
                  style: pw.TextStyle(fontSize: 10, font: font),
                ),
              ],
            ),
            
            pw.SizedBox(height: 8),
            
            // Summary Section - 2 items per row
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  // Row 1: Total Bill and Total Payment
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('Total Bill', style: pw.TextStyle(font: font)),
                          pw.Text(
                            'Rs. ${_totalBillAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('Total Payment', style: pw.TextStyle(font: font)),
                          pw.Text(
                            'Rs. ${_totalPayment.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  // Row 2: Total Penalty and Total Discount
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('Total Penalty', style: pw.TextStyle(font: font)),
                          pw.Text(
                            'Rs. ${_totalPenalty.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('Total Discount', style: pw.TextStyle(font: font)),
                          pw.Text(
                            'Rs. ${_totalDiscount.abs().toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  // Row 3: Total Advance and Due Amount
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('Total Advance', style: pw.TextStyle(font: font)),
                          pw.Text(
                            'Rs. ${_totalAdvance.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('Due Amount', style: pw.TextStyle(font: font)),
                          pw.Text(
                            'Rs. ${_dueAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: _dueAmount > 0 ? PdfColors.red : PdfColors.green,
                              font: font,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 8),
            
            // Statement Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FixedColumnWidth(35),
                3: const pw.FixedColumnWidth(50),
                4: const pw.FixedColumnWidth(50),
                5: const pw.FixedColumnWidth(45),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('SN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Units', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Bill Amt', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Paid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, font: font)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, font: font)),
                    ),
                  ],
                ),
                // Data Rows
                ..._statementResponse!.data.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  final isEven = index % 2 == 0;
                  final isDueItem = _isBillDue(item);
                  final displayBillAmt = (item.units == 0) ? 0.0 : (item.billAmt ?? 0.0);
                  
                  // Build description: Date and Bill/Receipt No
                  String description = _formatBSDateForDisplay(item.date);
                  if (item.billNo > 0) {
                    description += '\nBill: ${item.billNo}';
                  }
                  if (item.receiptNo != '0') {
                    description += '\nReceipt: ${item.receiptNo}';
                  }
                  
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isDueItem 
                          ? PdfColors.red100
                          : isEven ? PdfColors.grey100 : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(index.toString(), style: pw.TextStyle(fontSize: 8, font: font)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(description, style: pw.TextStyle(fontSize: 8, font: font)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(item.units.toString(), style: pw.TextStyle(fontSize: 8, font: font)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Rs. ${displayBillAmt.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 8, font: font),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Rs. ${item.paid?.toStringAsFixed(2) ?? '0.00'}',
                          style: pw.TextStyle(fontSize: 8, font: font),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          item.isPayment ? 'Paid' : isDueItem ? 'Due' : 'Bill',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: item.isPayment 
                                ? PdfColors.green 
                                : isDueItem 
                                    ? PdfColors.red 
                                    : PdfColors.blue,
                            font: font,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 16),
            
            // Footer
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Generated on: ${_formatBSDateForDisplay(_toDateBS)}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, font: font),
              ),
            ),
          ],
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'statement_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _isDownloading = false;
      });

      // Open PDF directly instead of sharing
      final result = await OpenFile.open(filePath);
      
      if (result.type == ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded: $fileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              onPressed: () => OpenFile.open(filePath),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved at: $filePath'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading statement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDateFilterDialog() {
    String tempFromDate = _fromDateBS;
    String tempToDate = _toDateBS;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'Select Date Range (Nepali BS)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        const Text(
                          'From Date (Nepali BS)',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final selectedDate = await showDialog<NepaliDateTime>(
                              context: context,
                              builder: (context) => NepaliDatePickerDialog(
                                initialDate: _parseBSDate(tempFromDate),
                                firstDate: NepaliDateTime(2075, 1, 1),
                                lastDate: NepaliDateTime(2090, 12, 30),
                                onDateSelected: (date) {
                                  final dateStr = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
                                  setStateDialog(() {
                                    tempFromDate = dateStr;
                                  });
                                },
                              ),
                            );
                            // Use the selected date
                            if (selectedDate != null) {
                              // Date is already set in the callback above
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tempFromDate.isNotEmpty 
                                      ? _formatBSDateForDisplay(tempFromDate)
                                      : 'Select From Date',
                                  style: TextStyle(
                                    color: tempFromDate.isNotEmpty 
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'To Date (Nepali BS)',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final selectedDate = await showDialog<NepaliDateTime>(
                              context: context,
                              builder: (context) => NepaliDatePickerDialog(
                                initialDate: _parseBSDate(tempToDate),
                                firstDate: NepaliDateTime(2075, 1, 1),
                                lastDate: NepaliDateTime(2090, 12, 30),
                                onDateSelected: (date) {
                                  final dateStr = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
                                  setStateDialog(() {
                                    tempToDate = dateStr;
                                  });
                                },
                              ),
                            );
                            // Use the selected date
                            if (selectedDate != null) {
                              // Date is already set in the callback above
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tempToDate.isNotEmpty 
                                      ? _formatBSDateForDisplay(tempToDate)
                                      : 'Select To Date',
                                  style: TextStyle(
                                    color: tempToDate.isNotEmpty 
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  final now = NepaliDateTime.now();
                                  final sixMonthsAgo = now.subtract(const Duration(days: 180));
                                  final defaultFrom = '${sixMonthsAgo.year}/${sixMonthsAgo.month.toString().padLeft(2, '0')}/${sixMonthsAgo.day.toString().padLeft(2, '0')}';
                                  final defaultTo = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
                                  
                                  setStateDialog(() {
                                    tempFromDate = defaultFrom;
                                    tempToDate = defaultTo;
                                  });
                                },
                                child: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _fromDateBS = tempFromDate;
                                    _toDateBS = tempToDate;
                                  });
                                  Navigator.pop(context);
                                  _fetchStatement();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Apply'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  NepaliDateTime _parseBSDate(String dateStr) {
    final now = NepaliDateTime.now();
    try {
      if (dateStr.isEmpty) return now;
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        if (year >= 2070 && year <= 2100 && month >= 1 && month <= 12 && day >= 1 && day <= 32) {
          return NepaliDateTime(year, month, day);
        }
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return now;
  }
}