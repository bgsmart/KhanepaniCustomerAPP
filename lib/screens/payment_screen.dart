// lib/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';
import '../models/payment_topic.dart';
import '../widgets/payment_topic_card.dart';
import '../widgets/payment_summary_bottom_sheet.dart';
import '../services/esewa_intent_service.dart';
import '../config/esewa_config.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isInitialized = false;
  bool _isProcessing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentTopics();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentTopics() async {
    final authProvider = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();
    
    if (authProvider.authToken != null) {
      final success = await paymentProvider.fetchTopics(authProvider.authToken!);
      if (success && mounted) {
        setState(() => _isInitialized = true);
      }
    }
  }

  void _showPaymentSummary() {
    final paymentProvider = context.read<PaymentProvider>();
    if (paymentProvider.selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one payment option'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentSummaryBottomSheet(
        selectedTopics: paymentProvider.selectedTopics,
        totalAmount: paymentProvider.totalAmount,
        onConfirm: _processPaymentWithEsewaIntent,
      ),
    );
  }

  // ✅ Process payment with eSewa Intent
  Future<void> _processPaymentWithEsewaIntent() async {
    if (_isProcessing) return;
    
    final authProvider = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    String customerId = '0';
    
    if (authProvider.customerDetails != null) {
      customerId = authProvider.customerDetails!.cusID ?? '0';
    }
    
    if (customerId == '0' || customerId.isEmpty) {
      if (authProvider.currentUser != null) {
        customerId = authProvider.currentUser!.customerId ?? '0';
      }
    }

    if (customerId == '0' || customerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Invalid Customer ID. Please login again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // ✅ Generate unique transaction UUID
      final transactionUuid = 'txn-${DateTime.now().millisecondsSinceEpoch}';
      final amount = paymentProvider.totalAmount.toStringAsFixed(0);
      
      // ✅ Prepare properties
      final properties = {
        'customer_id': customerId,
        'remarks': 'Water Bill Payment - ${paymentProvider.selectedCount} items',
      };

      print('📝 Processing eSewa Intent Payment:');
      print('👤 Customer ID: $customerId');
      print('💰 Total Amount: $amount');
      print('📋 Transaction UUID: $transactionUuid');

      // ✅ Step 1: Book Payment
      final bookingResult = await EsewaIntentService.bookPayment(
        amount: amount,
        transactionUuid: transactionUuid,
        callbackUrl: EsewaConfigConstants.callbackUrl,
        redirectUrl: EsewaConfigConstants.redirectUrl,
        properties: properties,
      );

      if (!bookingResult['success']) {
        throw Exception(bookingResult['message'] ?? 'Booking failed');
      }

      final bookingData = bookingResult['data'];
      final deeplink = bookingData['deeplink'];
      final bookingId = bookingData['booking_id'];
      final correlationId = bookingData['correlation_id'];

      print('✅ Booking Successful:');
      print('📝 Booking ID: $bookingId');
      print('🔗 Deeplink: $deeplink');

      // ✅ Store booking info for status check
      // You can store this in SharedPreferences or a global state
      // For now, we'll pass it to the launcher

      // ✅ Step 2: Launch eSewa app via deeplink
      final launched = await launchUrl(
        Uri.parse(deeplink),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // ✅ Fallback: Open in browser
        final webUrl = 'https://rc.esewa.com.np/pay/$bookingId';
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.platformDefault,
        );
      }

      // ✅ Step 3: Start polling for status (optional)
      // You can implement a polling mechanism to check payment status
      // For now, we'll rely on the callback URL

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Payment initiated! Please complete payment in eSewa app.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      print('❌ eSewa Intent Payment Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ✅ Check Payment Status Manually (Optional)
  Future<void> _checkPaymentStatus({
    required String bookingId,
    required String correlationId,
  }) async {
    try {
      final result = await EsewaIntentService.checkStatus(
        bookingId: bookingId,
        correlationId: correlationId,
      );

      if (result['success']) {
        final data = result['data'];
        final status = data['status'];
        
        print('📊 Payment Status: $status');
        
        if (status == 'SUCCESS') {
          // Handle success
        } else if (status == 'FAILED' || status == 'CANCELED') {
          // Handle failure
        }
      }
    } catch (e) {
      print('❌ Status check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final paymentProvider = context.watch<PaymentProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    final customerName = authProvider.customerDetails?.name ?? 
                        authProvider.currentUser?.name ?? 
                        'Customer';

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Payment Options',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 12,
                  color: colorScheme.onPrimary.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  customerName,
                  style: TextStyle(
                    color: colorScheme.onPrimary.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          if (paymentProvider.topics.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: paymentProvider.selectedCount == paymentProvider.topics.length
                  ? null
                  : paymentProvider.selectAll,
              tooltip: 'Select All',
            ),
            IconButton(
              icon: const Icon(Icons.deselect),
              onPressed: paymentProvider.selectedCount == 0
                  ? null
                  : paymentProvider.deselectAll,
              tooltip: 'Deselect All',
            ),
          ],
        ],
      ),
      body: _buildBody(colorScheme, textTheme, paymentProvider),
      bottomNavigationBar: _buildBottomBar(colorScheme, paymentProvider),
    );
  }

  Widget _buildBody(
    ColorScheme colorScheme,
    TextTheme textTheme,
    PaymentProvider paymentProvider,
  ) {
    if (paymentProvider.isLoading && !_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading payment options...',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (paymentProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                paymentProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPaymentTopics,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (paymentProvider.topics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No payment options available',
              style: textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPaymentTopics,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: paymentProvider.topics.length,
        itemBuilder: (context, index) {
          final topic = paymentProvider.topics[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PaymentTopicCard(
              topic: topic,
              onTap: () {
                if (!paymentProvider.isProcessing && !_isProcessing) {
                  paymentProvider.toggleSelection(topic.sn);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(
    ColorScheme colorScheme,
    PaymentProvider paymentProvider,
  ) {
    final isEnabled = paymentProvider.selectedCount > 0 && 
                      !paymentProvider.isLoading &&
                      !paymentProvider.isProcessing &&
                      !_isProcessing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Rs. ',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        paymentProvider.totalAmount.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${paymentProvider.selectedCount} item(s) selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isEnabled ? _showPaymentSummary : null,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.payment),
                  label: Text(
                    _isProcessing 
                        ? 'Processing...' 
                        : 'Pay with eSewa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnabled 
                        ? colorScheme.primary 
                        : colorScheme.onSurfaceVariant,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}