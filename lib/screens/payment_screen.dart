// lib/screens/payment_screen.dart
import 'package:KhanepaniApp/models/esewa_payment_status_model.dart';
import 'package:KhanepaniApp/screens/dashboard_screen.dart';
import 'package:KhanepaniApp/share_preference/share_preference.dart';
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
  final String paymentTopic;
  const PaymentScreen({super.key, required this.paymentTopic});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _awaitingPayment = false;
  bool _handlingReturn = false;
  final ScrollController _scrollController = ScrollController();
  final remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentTopics();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _awaitingPayment &&
        !_handlingReturn) {
      _onReturnedFromEsewa();
    }
  }

  Future<void> _onReturnedFromEsewa() async {
    _handlingReturn = true;
    try {
      final status = await _verifyPayment();
      if (!mounted) return;

      _awaitingPayment = false;
      await _showPaymentResultDialog(status);
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } finally {
      _handlingReturn = false;
    }
  }

  Future<EsewaPaymentStatusModel> _verifyPayment() async {
    final paymentModel = await SharePreference.getUtilityPayment();
    print("paymenet model : ${paymentModel?.toJson()}");
    try {
      final result = await EsewaIntentService.checkStatus(
        bookingId: paymentModel?.bookingId ?? '',
        correlationId: paymentModel?.correlationId ?? '',
      );
      print("payment status result : ${result.toJson()}");
      if (result.success == true) {
        final authProvider = context.read<AuthProvider>();
        final paymentProvider = context.read<PaymentProvider>();

        String customerId = '0';
        String customerName = '';

        if (authProvider.customerDetails != null) {
          customerId = authProvider.currentUser!.customerId ?? '0';
          customerName = authProvider.currentUser!.name;
          print('customer id : $customerId');
          print('customer name : $customerName');
        }
        final receiptVerification = await EsewaIntentService.verifyReceipt(
          customerCode: int.tryParse(customerId) ?? 0,
          customerName: customerName,
          topics: paymentProvider.selectedTopics,
          totalAmout: paymentProvider.totalAmount.toStringAsFixed(0),
        );
        if (receiptVerification.success == true) {
          SharePreference.setReceiptCode(receiptVerification.strValues);
          print(
              '✅ Receipt verification successful: ${receiptVerification.message}');
        } else {
          print(
              '❌ Receipt verification failed: ${receiptVerification.message}');
        }
      }
      return result;
    } catch (e) {
      throw Exception("Payment verification failed: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentTopics() async {
    final authProvider = context.read<AuthProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    if (authProvider.authToken != null) {
      final success =
          await paymentProvider.fetchTopics(authProvider.authToken!);
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
        remarksController: remarksController,
        onConfirm: () {
          Navigator.of(context).pop(); // Close the bottom sheet
          _processPaymentWithEsewaIntent();
        },
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
      print('customer id : $customerId');
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
      final selectedSns = paymentProvider.selectedTopics
          .map((topic) => topic.sn.toString())
          .join(',');

      print('📋 Selected SNs: $selectedSns');

      // ✅ Prepare properties
      final properties = {
        'customer_id': customerId,
        'remarks':
            'Water Bill Payment - ${paymentProvider.selectedCount} items',
      };

      print('📝 Processing eSewa Intent Payment:');
      print('👤 Customer ID: $customerId');
      print('💰 Total Amount: $amount');
      print('📋 Transaction UUID: $transactionUuid');
      print('remarks text : ${remarksController.text}');
      print('payment topic : ${widget.paymentTopic}');
      // ✅ Step 1: Book Payment
      final bookingResult = await AuthProvider.paymentMethod(
          amount,
          'khanepani-local-001',
          customerId,
          remarksController.text,
          selectedSns,
          widget.paymentTopic);

      if (bookingResult!.success == false) {
        throw Exception(bookingResult.message ?? 'Booking failed');
      }

      print('✅ Booking Successful:');
      print('📝 esewa deeplink: ${bookingResult.deeplink}');

      final launched = await launchUrl(
        Uri.parse(bookingResult.deeplink ?? ''),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        final webUrl = bookingResult.deeplink ?? '';
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.platformDefault,
        );
      }
      _awaitingPayment = true;

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Payment initiated! Please complete payment in eSewa app.'),
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ✅ Check Payment Status Manually (Optional)
  // Future<void> _checkPaymentStatus({
  //   required String bookingId,
  //   required String correlationId,
  // }) async {
  //   try {
  //     final result = await EsewaIntentService.checkStatus(
  //       bookingId: bookingId,
  //       correlationId: correlationId,
  //     );

  //     if (result['success']) {
  //       final data = result['data'];
  //       final status = data['status'];

  //       print('📊 Payment Status: $status');

  //       if (status == 'SUCCESS') {
  //         // Handle success
  //       } else if (status == 'FAILED' || status == 'CANCELED') {
  //         // Handle failure
  //       }
  //     }
  //   } catch (e) {
  //     print('❌ Status check error: $e');
  //   }
  // }

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
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          if (paymentProvider.topics.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed:
                  paymentProvider.selectedCount == paymentProvider.topics.length
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
                    _isProcessing ? 'Processing...' : 'Pay with eSewa',
                    style: const TextStyle(
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

  Future<void> _showPaymentResultDialog(EsewaPaymentStatusModel data) async {
    final recieptCode = await SharePreference.getReceiptCode();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.mark_as_unread, color: Colors.orange, size: 56),
            const SizedBox(height: 12),
            Text(data.status, textAlign: TextAlign.center),
          ],
        ),
        content: SizedBox(
          height:100,
          width: MediaQuery.sizeOf(context).width,
          child: Column(children: [
            Text("Receipt Code: $recieptCode", textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(data.message, textAlign: TextAlign.center),
          ]),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final cancelResult = await cancelPayment(data.bookingId);
                    if (cancelResult['success'] == true) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${cancelResult['message']}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DashboardScreen()),
                        (route) => false,
                      );
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '❌ Cancellation failed: ${cancelResult['message']}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 40,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('Cancel Booking',
                          style: TextStyle(color: Colors.black),
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.linear(0.9)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    (route) => false,
                  ),
                  child: Container(
                    height: 40,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('Go to Dashboard',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.linear(0.9)),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> cancelPayment(String bookingId) async {
    final paymentModel = await SharePreference.getUtilityPayment();
    print("Cancel model : ${paymentModel?.toJson()}");
    try {
      final result = await EsewaIntentService.cancelPayment(
        bookingId: paymentModel?.bookingId ?? '',
      );
      print(
          "Cancel payment result : ${result.map((key, value) => MapEntry(key, value.toString()))}");
      return result;
    } catch (e) {
      throw Exception("Payment cancellation failed: ${e.toString()}");
    }
  }
}
