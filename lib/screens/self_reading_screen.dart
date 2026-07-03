// lib/screens/self_reading_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reading_provider.dart';
import '../widgets/bottom_nav_bar.dart';
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

class _SelfReadingScreenState extends State<SelfReadingScreen> {
  final List<TextEditingController> _digitControllers = [];
  String _selectedMonth = 'बैशाख';
  String _selectedYear = '';
  XFile? _image;
  NepaliDateTime? _selectedDate;

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
    _initializeControllers();
    _initializeYears();
    _selectedDate = NepaliDateTime.now();
  }

  void _initializeControllers() {
    for (int i = 0; i < 5; i++) {
      _digitControllers.add(TextEditingController(text: i == 2 ? '1' : i == 3 ? '4' : i == 4 ? '5' : '0'));
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

  @override
  void dispose() {
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _image = image);
    }
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDialog<NepaliDateTime>(
      context: context,
      builder: (context) => NepaliDatePickerDialog(
        initialDate: _selectedDate ?? NepaliDateTime.now(),
        firstDate: _lastReadingDate.add(Duration(days: 1)),
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

    bool isDateValid = _selectedDate != null && 
        _selectedDate!.isAfter(_lastReadingDate);

    // ✅ Get Customer ID and Meter No
    final customerId = customerDetails?.cusID ?? 'N/A';
    final meterNo = customerDetails?.meterNo ?? customerDetails?.cusID ?? 'N/A';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.9),
                          Colors.white.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        customerDetails?.name.isNotEmpty == true 
                            ? customerDetails!.name[0].toUpperCase() 
                            : 'U',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          customerDetails?.name ?? 'Customer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (customerDetails != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.badge,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ID: $customerId',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.phone,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customerDetails.phone,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                          // ✅ Meter No - Separate from Customer ID
                          Row(
                            children: [
                              const Icon(
                                Icons.speed,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Meter No: $meterNo',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Notification Button
                  IconButton(
                    icon: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/notices'),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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

                // Period Selector - Nepali Date Picker (Same as Account Statement)
                Card(
                  color: colorScheme.surfaceContainerLowest,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                                color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                'Last: 1,420 m³',
                                style: textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
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
                                  width: 52,
                                  height: 68,
                                  child: TextFormField(
                                    controller: _digitControllers[i],
                                    textAlign: TextAlign.center,
                                    style: textTheme.displayLarge?.copyWith(
                                      fontSize: 30,
                                      color: colorScheme.onSurface,
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
                                          color: colorScheme.outlineVariant,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.outlineVariant,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (value) {
                                      if (value.length == 1 && i < 4) {
                                        FocusScope.of(context).nextFocus();
                                      }
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
                              Icons.info_outline,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Enter all black digits shown on your meter (without decimals).',
                                style: textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Photo Upload
                Card(
                  color: colorScheme.surfaceContainerLowest,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ATTACH METER PHOTO',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
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
                            InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                    style: BorderStyle.solid,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _image != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _image!.path,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt,
                                            size: 40,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Capture Photo',
                                            style: textTheme.displaySmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'or tap to upload',
                                            style: textTheme.bodySmall,
                                          ),
                                        ],
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
                    onPressed: readingProvider.isLoading ? null : _submitReading,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: colorScheme.primary.withValues(alpha: 0.3),
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send),
                              SizedBox(width: 8),
                              Text(
                                'Submit Reading',
                                style: TextStyle(
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
              Navigator.pushReplacementNamed(context, '/consumption-history');
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