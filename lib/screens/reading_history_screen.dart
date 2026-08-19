// lib/screens/reading_history_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/reading_history.dart';
import '../models/company.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/dashboard/app_bar.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> with WidgetsBindingObserver {
  int _currentIndex = 1;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isDownloading = false;
  String? _errorMessage;
  List<ReadingHistory> _readingHistory = [];

  // Company Details (English version for PDF)
  final Company _company = Company.defaultCompanyEnglish;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReadingHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  Future<void> _loadReadingHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final customerId = authProvider.customerDetails?.cusID;
      
      int customerIdInt;
      if (customerId == null) {
        throw Exception('Customer ID not found. Please login again.');
      } 
      else if (customerId is String) {
        customerIdInt = int.tryParse(customerId) ?? 0;
        if (customerIdInt == 0) {
          throw Exception('Invalid Customer ID format');
        }
      } else {
        throw Exception('Invalid Customer ID type');
      }

      final response = await ApiService.getReadingHistory(
        customerID: customerIdInt,
        fromDate: '',
        endDate: '',
      );

      if (response.success && response.data != null) {
        setState(() {
          _readingHistory = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load reading history';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshReadingHistory() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final customerId = authProvider.customerDetails?.cusID;
      
      int customerIdInt;
      if (customerId == null) {
        throw Exception('Customer ID not found. Please login again.');
      } 
       else if (customerId is String) {
        customerIdInt = int.tryParse(customerId) ?? 0;
        if (customerIdInt == 0) {
          throw Exception('Invalid Customer ID format');
        }
      } else {
        throw Exception('Invalid Customer ID type');
      }

      final response = await ApiService.getReadingHistory(
        customerID: customerIdInt,
        fromDate: '',
        endDate: '',
      );

      if (response.success && response.data != null) {
        setState(() {
          _readingHistory = response.data!;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load reading history';
          _isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isRefreshing = false;
      });
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

  // Generate PDF
  Future<void> _downloadPDF() async {
    if (_readingHistory.isEmpty) {
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
            // Company Header
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
            
            // Title
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Reading History Report',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            
            pw.SizedBox(height: 8),
            
            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('Total Readings'),
                          pw.Text(
                            _readingHistory.length.toString(),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('Total Units'),
                          pw.Text(
                            _readingHistory.fold(0, (sum, item) => sum + item.units).toString(),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('Total Bills'),
                          pw.Text(
                            'Rs. ${_readingHistory.fold(0, (sum, item) => sum + item.billAmount.toInt()).toString()}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('Paid / Due'),
                          pw.Text(
                            '${_readingHistory.where((item) => item.isPaid).length} / ${_readingHistory.where((item) => item.isDue).length}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 8),
            
            // Reading Table
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FixedColumnWidth(40),
                3: const pw.FixedColumnWidth(40),
                4: const pw.FixedColumnWidth(40),
                5: const pw.FixedColumnWidth(45),
                6: const pw.FixedColumnWidth(45),
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
                      child: pw.Text('Month', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Bill No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Prev', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Curr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Units', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                  ],
                ),
                // Data Rows
                ..._readingHistory.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;
                  final isEven = index % 2 == 0;
                  
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? PdfColors.grey100 : PdfColors.white,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(index.toString(), style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(item.monthName, style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(item.billNumber, style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(item.previousReadingText, style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(item.currentReadingText, style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(item.units.toString(), style: pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          item.isPaid ? 'Paid' : 'Due',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: item.isPaid ? PdfColors.green : PdfColors.red,
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
                    'Generated on: ${DateTime.now().toString().substring(0, 16)}',
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
      final fileName = 'reading_history_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
      });

      _showSnackBar('PDF downloaded: $fileName', isSuccess: true, duration: const Duration(seconds: 2));
      
      // Wait for snackbar to be visible before opening PDF
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Open the file
      final result = await OpenFile.open(filePath);
      
      if (!mounted) return;
      
      // Clear any existing snackbars when returning from PDF viewer
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
      
      _showSnackBar('Error downloading: ${e.toString()}', isSuccess: false, duration: const Duration(seconds: 2));
    }
  }

  // Download individual bill PDF
  Future<void> _downloadBillPDF(ReadingHistory reading) async {
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
            // Company Header
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
            
            // Bill Details Title
            pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Bill Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            
            pw.SizedBox(height: 8),
            
            // Bill Details
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Bill No:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(reading.billNumber),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Month:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(reading.monthName),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(reading.formattedDate),
                    ],
                  ),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Previous Reading:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(reading.previousReadingText),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Current Reading:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(reading.currentReadingText),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Units Consumed:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(reading.formattedUnits),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Bill Amount:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(reading.formattedBillAmount),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Status:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        reading.isPaid ? 'Paid' : 'Due',
                        style: pw.TextStyle(
                          color: reading.isPaid ? PdfColors.green : PdfColors.red,
                        ),
                      ),
                    ],
                  ),
                  if (reading.isPaid && reading.rno != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('RNO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(reading.rno.toString()),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            pw.SizedBox(height: 16),
            
            // Footer
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
                    'Generated on: ${DateTime.now().toString().substring(0, 16)}',
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
      final fileName = 'bill_${reading.billNo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;

      setState(() {
        _isDownloading = false;
      });

      _showSnackBar('Bill downloaded: $fileName', isSuccess: true, duration: const Duration(seconds: 2));
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      final result = await OpenFile.open(filePath);
      
      if (!mounted) return;
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
      
      if (result.type != ResultType.done) {
        _showSnackBar('Bill saved at: $filePath', isSuccess: true, duration: const Duration(seconds: 2));
      }
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isDownloading = false;
      });
      
      _showSnackBar('Error downloading: ${e.toString()}', isSuccess: false, duration: const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authProvider = context.watch<AuthProvider>();
    final customerDetails = authProvider.customerDetails;

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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ FIXED: Row with proper constraints - Removed Expanded from Text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ✅ FIXED: Use Flexible instead of Expanded for the Column
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reading History',
                          style: textTheme.displayLarge?.copyWith(
                            fontSize: 22,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View your meter reading and billing history.',
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Download All Button
                  if (!_isLoading && _readingHistory.isNotEmpty)
                    IconButton(
                      onPressed: _isDownloading ? null : _downloadPDF,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.download,
                              color: colorScheme.primary,
                            ),
                      tooltip: 'Download All',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primary.withAlpha(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Stats
              _buildSummaryStats(colorScheme, textTheme),

              const SizedBox(height: 16),

              // ✅ FIXED: Reading List with proper Expanded
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorWidget(colorScheme, textTheme)
                        : _readingHistory.isEmpty
                            ? _buildEmptyWidget(colorScheme, textTheme)
                            : RefreshIndicator(
                                onRefresh: _refreshReadingHistory,
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: _readingHistory.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final reading = _readingHistory[index];
                                    return _buildReadingCard(
                                      context,
                                      reading,
                                      colorScheme,
                                      textTheme,
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
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
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/self-reading');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/account-statement');
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

  Widget _buildSummaryStats(ColorScheme colorScheme, TextTheme textTheme) {
    if (_readingHistory.isEmpty) return const SizedBox.shrink();

    int totalUnits = 0;
    int totalBills = 0;
    int paidCount = 0;
    int dueCount = 0;

    for (var reading in _readingHistory) {
      totalUnits += reading.units;
      totalBills += reading.billAmount.toInt();
      if (reading.isPaid) {
        paidCount++;
      } else {
        dueCount++;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            'Total Units',
            '$totalUnits',
            Icons.water_drop,
            colorScheme.primary,
            colorScheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Total Bills',
            'Rs. $totalBills',
            Icons.receipt,
            colorScheme.secondary,
            colorScheme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Due Bills',
            '$dueCount',
            Icons.warning,
            dueCount > 0 ? colorScheme.error : colorScheme.secondary,
            colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(
    BuildContext context,
    ReadingHistory reading,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final statusColor = reading.statusColor;

    return Card(
      color: colorScheme.surfaceContainerLowest,
      elevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Month and Amount
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Month and Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reading.monthName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reading.formattedDate,
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right: Bill Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Bill Amount',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      reading.formattedBillAmount,
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: reading.statusBgColor,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: reading.statusBorderColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    reading.statusIcon,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    reading.isPaid ? 'Paid' : 'Due',
                    style: textTheme.labelLarge?.copyWith(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (reading.isPaid && reading.rno != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 16,
                      color: colorScheme.outlineVariant.withAlpha(50),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'RNO: ${reading.rno}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Stats Grid
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withAlpha(20),
              ),
            ),
            child: Row(
              children: [
                _buildStatItem(
                  context,
                  'Bill No',
                  reading.billNumber,
                  colorScheme,
                ),
                _buildStatItem(
                  context,
                  'Units',
                  reading.formattedUnits,
                  colorScheme,
                ),
                _buildStatItem(
                  context,
                  'Prev',
                  reading.previousReadingText,
                  colorScheme,
                ),
                _buildStatItem(
                  context,
                  'Curr',
                  reading.currentReadingText,
                  colorScheme,
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(50),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (reading.isDue)
                  // TextButton.icon(
                  //   onPressed: () {
                  //     Navigator.pushNamed(
                  //       context, 
                  //       '/payment',
                  //       arguments: {'billNo': reading.billNo},
                  //     );
                  //   },
                  //   icon: Icon(
                  //     Icons.payment,
                  //     size: 18,
                  //     color: colorScheme.primary,
                  //   ),
                  //   label: Text(
                  //     'Pay Now',
                  //     style: textTheme.labelLarge?.copyWith(
                  //       color: colorScheme.primary,
                  //       fontWeight: FontWeight.w600,
                  //     ),
                  //   ),
                  //   style: TextButton.styleFrom(
                  //     padding: const EdgeInsets.symmetric(horizontal: 12),
                  //     backgroundColor: colorScheme.primary.withAlpha(10),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(8),
                  //     ),
                  //   ),
                  // ),
                // Download Individual Bill Button
                TextButton.icon(
                  onPressed: _isDownloading ? null : () => _downloadBillPDF(reading),
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.download,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                  label: Text(
                    'Download',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Please try again',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReadingHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: colorScheme.onSurfaceVariant.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No Reading History Found',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your meter reading history will appear here.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshReadingHistory,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}