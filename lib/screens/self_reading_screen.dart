// lib/screens/self_reading_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reading_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/dashboard/app_bar.dart';
import '../widgets/nepali_date_picker_dialog.dart';
import '../config/app_config.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

class SelfReadingScreen extends StatefulWidget {
  const SelfReadingScreen({super.key});

  @override
  State<SelfReadingScreen> createState() => _SelfReadingScreenState();
}

class _SelfReadingScreenState extends State<SelfReadingScreen> with WidgetsBindingObserver {
  final List<TextEditingController> _digitControllers = [];
  String _selectedMonth = 'बैशाख';
  String _selectedYear = '';
  XFile? _image;
  NepaliDateTime? _selectedDate;
  bool _isImageLoading = false;
  String? _lastReadingNumber;

  // Nepali months
  final List<String> _nepaliMonths = [
    'बैशाख', 'जेठ', 'असार', 'साउन', 
    'भदौ', 'असोज', 'कात्तिक', 'मंसिर', 
    'पुष', 'माघ', 'फागुन', 'चैत'
  ];

  // Get current Nepali year and surrounding years
  late List<String> _nepaliYears;

  // Last reading date (mock data - replace with actual from API)
  NepaliDateTime _lastReadingDate = NepaliDateTime(2081, 2, 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _initializeYears();
    _selectedDate = NepaliDateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _digitControllers) {
      controller.dispose();
    }
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

  void _initializeControllers() {
    // Get last reading number from customer details
    final authProvider = context.read<AuthProvider>();
    final customerDetails = authProvider.customerDetails;
    _lastReadingNumber = customerDetails?.lastReadingNumber ?? '0';
    
    // Parse the last reading number and split into digits
    String lastReading = _lastReadingNumber ?? '00000';
    // Pad with leading zeros if needed
    while (lastReading.length < 5) {
      lastReading = '0' + lastReading;
    }
    
    // Initialize controllers with the last reading number digits
    _digitControllers.clear();
    for (int i = 0; i < 5; i++) {
      String digit = i < lastReading.length ? lastReading[i] : '0';
      _digitControllers.add(TextEditingController(text: digit));
    }
  }

  void _initializeYears() {
    final currentYear = NepaliDateTime.now().year;
    final currentYearStr = currentYear.toString();
    _selectedYear = currentYearStr;
    
    _nepaliYears = [
      (currentYear - 1).toString(),
      currentYearStr,
      (currentYear + 1).toString(),
    ];
  }

  // Show image picker options (Camera or Gallery)
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImagePickerOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImagePickerOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // Remove image
  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isImageLoading = true;
    });

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _image = image;
          _isImageLoading = false;
        });
      } else {
        setState(() {
          _isImageLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isImageLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDialog<NepaliDateTime>(
      context: context,
      builder: (context) => NepaliDatePickerDialog(
        initialDate: _selectedDate ?? NepaliDateTime.now(),
        firstDate: _lastReadingDate.add(const Duration(days: 1)),
        lastDate: NepaliDateTime.now(),
        onDateSelected: (date) {
          setState(() {
            _selectedDate = date;
          });
        },
      ),
    );
  }

  Future<void> _submitReading() async {
    final readingProvider = context.read<ReadingProvider>();
    final readingValue = int.parse(_digitControllers.map((c) => c.text).join());
    final lastReading = int.parse(_lastReadingNumber ?? '0');
    
    // Check if reading is less than last reading
    if (readingValue < lastReading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reading cannot be less than the last reading: ${_formatReadingNumber(lastReading.toString())}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reading date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Convert NepaliDateTime to DateTime for submission
    final dateTime = DateTime(
      _selectedDate!.year - 56, // Approximate conversion
      _selectedDate!.month,
      _selectedDate!.day,
    );

    await readingProvider.submitReading(
      readingValue,
      dateTime,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reading submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  String _formatReadingNumber(String number) {
    // Format number with commas: e.g., 1420 -> 1,420
    if (number.isEmpty) return '0';
    final int num = int.tryParse(number) ?? 0;
    return NumberFormat('#,###', 'en_US').format(num);
  }


  String _formatNepaliDate(NepaliDateTime date) {
    final monthName = AppConfig.getNepaliMonth(date.month);
    return '${date.year} $monthName ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final readingProvider = context.watch<ReadingProvider>();
    final authProvider = context.watch<AuthProvider>();
    final customerDetails = authProvider.customerDetails;

    // Update last reading number from customer details
    if (customerDetails != null && _lastReadingNumber != customerDetails.lastReadingNumber) {
      _lastReadingNumber = customerDetails.lastReadingNumber;
      _initializeControllers();
    }

    bool isDateValid = _selectedDate != null && 
        _selectedDate!.isAfter(_lastReadingDate);

    // ✅ Get Customer ID and Meter No
    final customerId = customerDetails?.cusID ?? 'N/A';
    final meterNo = customerDetails?.meterNo ?? customerDetails?.cusID ?? 'N/A';
    final lastReading = _lastReadingNumber ?? '0';
    final formattedLastReading = _formatReadingNumber(lastReading);

    // Get current reading value for validation
    final currentReading = int.parse(_digitControllers.map((c) => c.text).join());
    final isReadingValid = currentReading >= int.parse(lastReading);

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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit this month\'s reading',
                  style: textTheme.displayLarge?.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ensure your bill is accurate by providing your current meter data.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Account Details Card
                Card(
                  color: colorScheme.surfaceContainerLowest,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha(76),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACCOUNT DETAILS',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          customerDetails?.name ?? 'Customer',
                          style: textTheme.displaySmall,
                        ),
                        Text(
                          customerDetails != null 
                              ? 'Ward ${customerDetails.wardNo} • Area: ${customerDetails.area}'
                              : 'Residential • Ward 0',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer ID',
                                  style: textTheme.labelLarge?.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  customerId,
                                  style: textTheme.displaySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    letterSpacing: 2,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Meter No',
                                  style: textTheme.labelLarge?.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  meterNo,
                                  style: textTheme.displaySmall?.copyWith(
                                    fontFamily: 'monospace',
                                    letterSpacing: 2,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Period Selector - Nepali Date Picker
                Card(
                  color: colorScheme.surfaceContainerLowest,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha(76),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'READING DATE (Nepali BS)',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Last Reading: ${_formatNepaliDate(_lastReadingDate)}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedDate != null && isDateValid
                                    ? colorScheme.primary
                                    : _selectedDate != null && !isDateValid
                                        ? colorScheme.error
                                        : colorScheme.outlineVariant,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: _selectedDate != null && isDateValid
                                      ? colorScheme.primary
                                      : _selectedDate != null && !isDateValid
                                          ? colorScheme.error
                                          : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedDate != null
                                        ? _formatNepaliDate(_selectedDate!)
                                        : 'Select Reading Date',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: _selectedDate != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedDate != null && !isDateValid)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Reading date must be after ${_formatNepaliDate(_lastReadingDate)}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Reading Input - No Decimal
                Card(
                  color: colorScheme.surfaceContainerLowest,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha(76),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CURRENT READING',
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isReadingValid 
                                    ? colorScheme.secondaryContainer.withAlpha(76)
                                    : colorScheme.errorContainer.withAlpha(76),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                'Last: $formattedLastReading m³',
                                style: textTheme.labelLarge?.copyWith(
                                  color: isReadingValid 
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < 5; i++)
                              Padding(
                                padding: EdgeInsets.only(right: i == 3 ? 8 : 4),
                                child: SizedBox(
                                  width: 45,
                                  height: 60,
                                  child: TextFormField(
                                    controller: _digitControllers[i],
                                    textAlign: TextAlign.center,
                                    style: textTheme.displayLarge?.copyWith(
                                      fontSize: 30,
                                      color: isReadingValid 
                                          ? colorScheme.onSurface
                                          : colorScheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLength: 1,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      counterText: '',
                                      filled: true,
                                      fillColor: colorScheme.surface,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isReadingValid 
                                              ? colorScheme.outlineVariant
                                              : colorScheme.error,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isReadingValid 
                                              ? colorScheme.outlineVariant
                                              : colorScheme.error,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isReadingValid 
                                              ? colorScheme.primary
                                              : colorScheme.error,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (value) {
                                      if (value.length == 1 && i < 4) {
                                        FocusScope.of(context).nextFocus();
                                      }
                                      // Update the state to refresh the validation
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Text(
                              'm³',
                              style: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isReadingValid 
                                  ? Icons.info_outline
                                  : Icons.warning,
                              size: 16,
                              color: isReadingValid 
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isReadingValid 
                                    ? 'Enter all black digits shown on your meter (without decimals).'
                                    : 'Current reading must be greater than or equal to last reading: $formattedLastReading m³',
                                style: textTheme.bodySmall?.copyWith(
                                  color: isReadingValid 
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Photo Upload with Camera and Gallery Options
                Card(
                  color: colorScheme.surfaceContainerLowest,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withAlpha(76),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ATTACH METER PHOTO',
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            if (_image != null)
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: colorScheme.error,
                                  size: 20,
                                ),
                                onPressed: _removeImage,
                                tooltip: 'Remove photo',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Photo Requirements',
                                    style: textTheme.displaySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildRequirement(
                                    context,
                                    'Include the full meter dial showing all digits clearly.',
                                  ),
                                  _buildRequirement(
                                    context,
                                    'Ensure there are no reflections or glares from flash.',
                                  ),
                                  _buildRequirement(
                                    context,
                                    'Meter serial number must be visible.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Image Preview / Upload Area - Fixed
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GestureDetector(
                                onTap: _showImagePickerOptions,
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    border: Border.all(
                                      color: _image != null 
                                          ? colorScheme.primary 
                                          : colorScheme.outlineVariant,
                                      style: BorderStyle.solid,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _isImageLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : _image != null
                                          ? Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.file(
                                                    File(_image!.path),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 4,
                                                  right: 4,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withAlpha(150),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.camera_alt,
                                                          size: 12,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Change',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 48,
                                                  color: colorScheme.primary,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Tap to upload',
                                                  style: textTheme.displaySmall?.copyWith(
                                                    color: colorScheme.primary,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  'Camera or Gallery',
                                                  style: textTheme.bodySmall?.copyWith(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (readingProvider.isLoading || !isReadingValid) ? null : _submitReading,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReadingValid ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      foregroundColor: isReadingValid ? colorScheme.onPrimary : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isReadingValid ? 4 : 0,
                      shadowColor: isReadingValid ? colorScheme.primary.withAlpha(76) : Colors.transparent,
                    ),
                    child: readingProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isReadingValid ? Icons.send : Icons.block,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isReadingValid ? 'Submit Reading' : 'Invalid Reading',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'By submitting, you confirm the data matches your physical meter reading.',
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/reading-history');
              break;
            case 2:
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

  Widget _buildRequirement(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 20,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}