// lib/screens/account_statement_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:nepali_utils/nepali_utils.dart';
import 'package:provider/provider.dart';
import '../models/customer_statement.dart';
import '../models/company.dart';
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

class _AccountStatementScreenState extends State<AccountStatementScreen> with WidgetsBindingObserver {
  int _currentIndex = 3;
  String _selectedFilter = 'All';
  CustomerStatementResponse? _statementResponse;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;

  // Date range in BS (Nepali) format
  String _fromDateBS = '';
  String _toDateBS = '';

  // Company Details (English version for PDF)
  final Company _company = Company.defaultCompanyEnglish;

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

  // Controllers for date input with mask
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setDefaultDates();
    _fetchStatement();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    }
  }

  void _setDefaultDates() {
    final now = NepaliDateTime.now();
    _toDateBS = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
    
    final sixMonthsAgo = now.subtract(const Duration(days: 180));
    _fromDateBS = '${sixMonthsAgo.year}/${sixMonthsAgo.month.toString().padLeft(2, '0')}/${sixMonthsAgo.day.toString().padLeft(2, '0')}';
    
    _fromDateController.text = _fromDateBS;
    _toDateController.text = _toDateBS;
  }

  Future<void> _fetchStatement() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final customerId = authProvider.customerDetails?.cusID;
      
      int customerIdInt;
      if (customerId == null) {
        throw Exception('Customer ID not found');
      } else if (customerId is String) {
        customerIdInt = int.tryParse(customerId) ?? 0;
        if (customerIdInt == 0) {
          throw Exception('Invalid Customer ID format');
        }
      } else {
        throw Exception('Invalid Customer ID type');
      }

      final response = await ApiService.getCustomerStatement(
        customerID: customerIdInt,
        fromDate: _fromDateBS,
        toDate: _toDateBS,
      );

      if (!mounted) return;

      setState(() {
        _statementResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
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

  // Show snackbar with auto-dismiss
  void _showSnackBar(String message, {bool isSuccess = true, Duration duration = const Duration(seconds: 2)}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
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
        cusID: customerDetails?.cusID?.toString() ?? 'N/A',
        phone: customerDetails?.phone ?? 'N/A',
        meterNo: customerDetails?.meterNo ?? 'N/A',
        advance: customerDetails?.advance?.toString() ?? "0",
        showBackButton: true,
        showCustomerInfo: false,
        onBackPressed: () => Navigator.pop(context),
        onNotificationTap: () => Navigator.pushNamed(context, '/notices'),
        onLogoutTap: () => _handleLogout(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Compact Summary Card with Gradient Background
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Title, Date Filters, Apply Button, Download Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SUMMARY',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white.withAlpha(230),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: _isDownloading 
                            ? const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download, color: Colors.white, size: 20),
                        onPressed: _isDownloading ? null : _downloadPDF,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(38),
                          padding: const EdgeInsets.all(4),
                          minimumSize: const Size(35, 35),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Row 1: Total Bill and Total Payment
                  Row(
                    children: [
                      _buildSummaryItemCompact(
                        context,
                        'Total Bill',
                        'Rs. ${_totalBillAmount.toStringAsFixed(2)}',
                        Icons.receipt_long,
                        Colors.white,
                      ),
                      _buildSummaryItemCompact(
                        context,
                        'Total Payment',
                        'Rs. ${_totalPayment.toStringAsFixed(2)}',
                        Icons.payments,
                        Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Row 2: Total Penalty and Total Discount
                  Row(
                    children: [
                      _buildSummaryItemCompact(
                        context,
                        'Total Penalty',
                        'Rs. ${_totalPenalty.toStringAsFixed(2)}',
                        Icons.warning_amber,
                        Colors.white,
                      ),
                      _buildSummaryItemCompact(
                        context,
                        'Total Discount',
                        'Rs. ${_totalDiscount.abs().toStringAsFixed(2)}',
                        Icons.discount,
                        Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Row 3: Total Advance and Due Amount
                  Row(
                    children: [
                      _buildSummaryItemCompact(
                        context,
                        'Total Advance',
                        'Rs. ${_totalAdvance.toStringAsFixed(2)}',
                        Icons.account_balance,
                        Colors.white,
                      ),
                      _buildSummaryItemCompact(
                        context,
                        'Due Amount',
                        'Rs. ${_dueAmount.toStringAsFixed(2)}',
                        Icons.account_balance,
                        Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // From Date with Mask
                      SizedBox(
                        width: 120,
                        height: 30,
                        child: TextFormField(
                          controller: _fromDateController,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          decoration: InputDecoration(
                            hintText: 'YYYY/MM/DD',
                            hintStyle: TextStyle(
                              fontSize: 9,
                              color: Colors.white.withAlpha(128),
                            ),
                            filled: true,
                            fillColor: Colors.white.withAlpha(38),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.calendar_today, color: Colors.white, size: 12),
                              onPressed: () => _pickDate(context, true),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                              String formatted = '';
                              for (int i = 0; i < cleaned.length && i < 8; i++) {
                                if (i == 4 || i == 6) {
                                  formatted += '/';
                                }
                                formatted += cleaned[i];
                              }
                              _fromDateBS = cleaned;
                              
                              if (formatted != _fromDateController.text) {
                                _fromDateController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                    offset: formatted.length,
                                  ),
                                );
                              }
                            } else {
                              _fromDateBS = '';
                              _fromDateController.text = '';
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      // To Date with Mask
                      SizedBox(
                        width: 120,
                        height: 30,
                        child: TextFormField(
                          controller: _toDateController,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          decoration: InputDecoration(
                            hintText: 'YYYY/MM/DD',
                            hintStyle: TextStyle(
                              fontSize: 9,
                              color: Colors.white.withAlpha(128),
                            ),
                            filled: true,
                            fillColor: Colors.white.withAlpha(38),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.calendar_today, color: Colors.white, size: 12),
                              onPressed: () => _pickDate(context, false),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                              String formatted = '';
                              for (int i = 0; i < cleaned.length && i < 8; i++) {
                                if (i == 4 || i == 6) {
                                  formatted += '/';
                                }
                                formatted += cleaned[i];
                              }
                              _toDateBS = cleaned;
                              
                              if (formatted != _toDateController.text) {
                                _toDateController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                    offset: formatted.length,
                                  ),
                                );
                              }
                            } else {
                              _toDateBS = '';
                              _toDateController.text = '';
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Apply Button
                      Container(
                        height: 26,
                        width: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_fromDateBS.length == 8 && _toDateBS.length == 8) {
                              _fromDateBS = '${_fromDateBS.substring(0, 4)}/${_fromDateBS.substring(4, 6)}/${_fromDateBS.substring(6, 8)}';
                              _toDateBS = '${_toDateBS.substring(0, 4)}/${_toDateBS.substring(4, 6)}/${_toDateBS.substring(6, 8)}';
                            }
                            _fetchStatement();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: const Size(0, 26),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Bills', 'Payments', 'Due'].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          final filterColor = _filterColors[filter] ?? colorScheme.primary;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedFilter = filter),
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              selectedColor: filterColor.withAlpha(50),
                              checkmarkColor: filterColor,
                              labelStyle: textTheme.labelLarge?.copyWith(
                                color: isSelected ? filterColor : colorScheme.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 11,
                              ),
                              avatar: isSelected
                                  ? Icon(
                                      filter == 'Payments' ? Icons.payments : 
                                      filter == 'Bills' ? Icons.receipt_long : 
                                      filter == 'Due' ? Icons.warning : 
                                      Icons.filter_list,
                                      size: 14,
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

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
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            '# $monthName ${monthParts[0]}',
                                            style: textTheme.displaySmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.primary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: colorScheme.outlineVariant,
                                              margin: const EdgeInsets.only(left: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...items.map((item) => _buildNewStyleCard(context, item)),
                                    const SizedBox(height: 6),
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
              Navigator.pushReplacementNamed(context, '/reading-history');
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

  // Pick date from calendar
  Future<void> _pickDate(BuildContext context, bool isFromDate) async {
    final currentDate = isFromDate ? _fromDateBS : _toDateBS;
    final selectedDate = await showDialog<NepaliDateTime>(
      context: context,
      builder: (context) => NepaliDatePickerDialog(
        initialDate: _parseBSDate(currentDate),
        firstDate: NepaliDateTime(2075, 1, 1),
        lastDate: NepaliDateTime(2090, 12, 30),
        onDateSelected: (date) {
          final dateStr = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
          if (isFromDate) {
            _fromDateController.text = dateStr;
            _fromDateBS = dateStr;
          } else {
            _toDateController.text = dateStr;
            _toDateBS = dateStr;
          }
        },
      ),
    );
  }

  // Compact Summary Item Builder
  Widget _buildSummaryItemCompact(BuildContext context, String label, String value, IconData icon, Color textColor) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: textColor.withAlpha(38),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 12,
              color: textColor.withAlpha(230),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: textColor.withAlpha(180),
                    fontSize: 7,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: textTheme.displaySmall?.copyWith(
                    color: textColor,
                    fontSize: 10,
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

  Widget _buildChip(BuildContext context, String text, String type) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color getBgColor() {
      switch (type) {
        case 'billNo':
          return colorScheme.primaryContainer.withAlpha(38);
        case 'receipt':
          return colorScheme.secondaryContainer.withAlpha(50);
        case 'units':
          return colorScheme.tertiaryContainer.withAlpha(38);
        case 'discount':
          return colorScheme.primaryContainer.withAlpha(38);
        case 'penalty':
          return colorScheme.errorContainer.withAlpha(50);
        case 'advance':
          return colorScheme.secondaryContainer.withAlpha(38);
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: getBgColor(),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: getTextColor().withAlpha(50),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getIcon(),
            size: 10,
            color: getTextColor(),
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: textTheme.labelLarge?.copyWith(
              fontSize: 8,
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
    final displayBillAmt = (item.units == 0) ? 0.0 : (item.billAmt ?? 0.0);

    String getTitle() {
      if (isPayment) {
        return 'Bill Payment for ${_getMonthYearForTitle(item.date)}';
      } else {
        return 'Monthly Bill of ${_getMonthYearForTitle(item.date)}';
      }
    }

    String getSubtitle() {
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
        return colorScheme.secondaryContainer.withAlpha(50);
      } else if (isDue) {
        return colorScheme.errorContainer.withAlpha(75);
      } else {
        return colorScheme.primaryContainer.withAlpha(50);
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
          ? colorScheme.errorContainer.withAlpha(20)
          : colorScheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDue
              ? colorScheme.error.withAlpha(75)
              : colorScheme.outlineVariant.withAlpha(50),
          width: isDue ? 2 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: getIconBgColor(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          getIcon(),
                          color: getIconColor(),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTitle(),
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    getSubtitle(),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: isDue ? colorScheme.error : colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                if (isDue) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: colorScheme.error,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      'DUE',
                                      style: textTheme.labelLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                                if (isPayment) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      'PAID',
                                      style: textTheme.labelLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 7,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      getAmount(),
                      style: textTheme.displaySmall?.copyWith(
                        color: getAmountColor(),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isDue)
                      Text(
                        'Unpaid',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPayment
                        ? colorScheme.secondaryContainer.withAlpha(75)
                        : isDue
                            ? colorScheme.errorContainer.withAlpha(75)
                            : colorScheme.primaryContainer.withAlpha(75),
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
                      fontSize: 9,
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

  // PDF Download
  Future<void> _downloadPDF() async {
    if (_statementResponse == null || _statementResponse!.data.isEmpty) {
      if (!mounted) return;
      _showSnackBar('No data to download', isSuccess: false);
      return;
    }

    if (!mounted) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final pdf = pw.Document();
      final customerDetails = context.read<AuthProvider>().customerDetails;

      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            // Company Header - Using English Company
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    _company.name,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _company.address,
                    style: pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Phone: ${_company.phone}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Email: ${_company.email}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Website: ${_company.website}',
                    style: pw.TextStyle(fontSize: 10),
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
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text('Name: ${customerDetails?.name ?? 'N/A'}'),
                      ),
                      pw.Expanded(
                        child: pw.Text('Customer ID: ${customerDetails?.cusID ?? 'N/A'}'),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text('Phone: ${customerDetails?.phone ?? 'N/A'}'),
                      ),
                      pw.Expanded(
                        child: pw.Text('Ward: ${customerDetails?.wardNo ?? 'N/A'}'),
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
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'To: ${_formatBSDateForDisplay(_toDateBS)}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
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
                      child: pw.Text('SN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Units', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Bill Amt', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Paid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
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
                        child: pw.Text(index.toString(), style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(description, style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(item.units.toString(), style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Rs. ${displayBillAmt.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Rs. ${item.paid?.toStringAsFixed(2) ?? '0.00'}',
                          style: pw.TextStyle(fontSize: 8),
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
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 16),
            
            // Footer with company details
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                children: [
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _company.name,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    _company.address,
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                  pw.Text(
                    'Phone: ${_company.phone} | Email: ${_company.email}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on: ${_formatBSDateForDisplay(_toDateBS)}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                  ),
                ],
              ),
            ),
          ],
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
        ),
      );

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'account_statement_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
      });

      _showSnackBar('PDF downloaded: $fileName', isSuccess: true, duration: const Duration(seconds: 2));
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final result = await OpenFile.open(filePath);
      
      if (!mounted) return;
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
      
      if (result.type != ResultType.done) {
        _showSnackBar('PDF saved at: $filePath', isSuccess: true, duration: const Duration(seconds: 2));
      }
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isDownloading = false;
      });
      
      _showSnackBar('Error downloading statement: $e', isSuccess: false, duration: const Duration(seconds: 2));
    }
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