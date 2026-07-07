// lib/screens/complaint_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/complaint.dart';
import '../providers/auth_provider.dart';
import '../providers/complaint_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/dashboard/app_bar.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> with WidgetsBindingObserver {
  int _currentIndex = 4;
  
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  ComplaintType? _selectedComplaintType;
  double? _latitude;
  double? _longitude;
  List<XFile> _images = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  bool _showSuccess = false;
  String? _submittedId;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load complaints after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComplaints();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subjectController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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

  Future<void> _loadComplaints() async {
    final authProvider = context.read<AuthProvider>();
    final customerId = authProvider.customerDetails?.cusID?.toString();
    
    if (customerId != null && customerId.isNotEmpty) {
      final complaintProvider = context.read<ComplaintProvider>();
      await complaintProvider.loadComplaints(customerId);
    }
  }

  // Keep GPS functionality as optional
  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;
    
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled. Please enable GPS/Location in your device settings.');
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permission denied. Please grant permission to use this feature.');
          setState(() {
            _isGettingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog();
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      // Get position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _isGettingLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Location captured successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
        
        String errorMessage = 'Failed to get location. ';
        if (e.toString().contains('PERMISSION_DENIED')) {
          errorMessage += 'Please grant location permission.';
        } else if (e.toString().contains('LOCATION_DISABLED')) {
          errorMessage += 'Please enable GPS/Location services.';
        } else if (e.toString().contains('TIMEOUT')) {
          errorMessage += 'Request timed out. Please try again.';
        } else {
          errorMessage += 'Please try again.';
        }
        
        _showLocationError(errorMessage);
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission is permanently denied. Please enable it from app settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedImages = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedImages.isNotEmpty) {
        setState(() {
          _images = pickedImages;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedComplaintType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a complaint type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final complaintProvider = context.read<ComplaintProvider>();
      final customerId = authProvider.customerDetails?.cusID?.toString() ?? '';

      // Get location from controller
      final location = _locationController.text.trim().isNotEmpty 
          ? _locationController.text.trim() 
          : null;

      // Upload images first (you can implement this)
      List<String> imageUrls = [];
      // TODO: Upload images to server and get URLs

      final success = await complaintProvider.submitComplaint(
        customerId: customerId,
        complaintType: _selectedComplaintType!.id,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        location: location,
        latitude: _latitude,
        longitude: _longitude,
        imageUrls: imageUrls,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (success) {
          setState(() {
            _showSuccess = true;
          });
          _resetForm();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complaint submitted successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (complaintProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(complaintProvider.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    _subjectController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _selectedComplaintType = null;
    _latitude = null;
    _longitude = null;
    _images = [];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authProvider = context.watch<AuthProvider>();
    final complaintProvider = context.watch<ComplaintProvider>();
    final customerDetails = authProvider.customerDetails;

    if (_showSuccess) {
      return _buildSuccessScreen(colorScheme, textTheme);
    }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Submit Complaint',
                style: textTheme.displayLarge?.copyWith(
                  fontSize: 26,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Report any issues related to water supply, billing, or service.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Complaint Type
                    Text(
                      'COMPLAINT TYPE *',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ComplaintType.types.map((type) {
                            final isSelected = _selectedComplaintType?.id == type.id;
                            return FilterChip(
                              label: Text('${type.icon} ${type.name}'),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedComplaintType = isSelected ? null : type;
                                });
                              },
                              backgroundColor: colorScheme.surface,
                              selectedColor: colorScheme.primary.withAlpha(20),
                              checkmarkColor: colorScheme.primary,
                              labelStyle: textTheme.bodySmall?.copyWith(
                                color: isSelected 
                                    ? colorScheme.primary 
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: isSelected 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected 
                                    ? colorScheme.primary 
                                    : colorScheme.outlineVariant,
                                width: isSelected ? 2 : 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subject
                    Text(
                      'SUBJECT *',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        hintText: 'Brief subject of your complaint',
                        border: OutlineInputBorder(
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
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a subject';
                        }
                        if (value.length < 5) {
                          return 'Subject must be at least 5 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'DESCRIPTION *',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Describe your complaint in detail',
                        border: OutlineInputBorder(
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
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLowest,
                        prefixIcon: const Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location - Free Typing
                    Text(
                      'LOCATION (Optional)',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surfaceContainerLowest,
                      ),
                      child: Column(
                        children: [
                          // Manual location entry
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              hintText: 'Enter your location (e.g., Ward 4, Hetauda)',
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                _locationController.text.isNotEmpty 
                                    ? Icons.location_on 
                                    : Icons.location_off,
                                color: _locationController.text.isNotEmpty 
                                    ? Colors.green 
                                    : colorScheme.onSurfaceVariant,
                              ),
                              suffixIcon: _locationController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _locationController.clear();
                                          _latitude = null;
                                          _longitude = null;
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value.trim().isEmpty) {
                                  _latitude = null;
                                  _longitude = null;
                                }
                              });
                            },
                          ),
                          
                          // Optional: GPS button
                          const Divider(height: 24),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Or use current location',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                                icon: _isGettingLocation
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.gps_fixed, size: 18),
                                label: Text(_isGettingLocation ? 'Getting...' : 'Get GPS'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: const Size(80, 36),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image Upload
                    Text(
                      'ATTACH IMAGES (Optional)',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surfaceContainerLowest,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image grid
                          if (_images.isNotEmpty)
                            Container(
                              height: 120,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 120,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: colorScheme.outlineVariant,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            File(_images[index].path),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 12,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withAlpha(150),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          // Upload button
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImages,
                                  icon: const Icon(Icons.photo_library),
                                  label: Text(
                                    _images.isNotEmpty 
                                        ? '${_images.length} images selected' 
                                        : 'Select images',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              if (_images.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _images.clear();
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: colorScheme.error.withAlpha(20),
                                    foregroundColor: colorScheme.error,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can select multiple images. Max 5 images.',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || complaintProvider.isSubmitting) 
                            ? null 
                            : _submitComplaint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: colorScheme.primary.withAlpha(76),
                        ),
                        child: (_isSubmitting || complaintProvider.isSubmitting)
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
                                    'Submit Complaint',
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
                        'We will respond to your complaint within 24 hours.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
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
              Navigator.pushReplacementNamed(context, '/account-statement');
              break;
            case 4:
              break;
          }
        },
      ),
    );
  }

  Widget _buildSuccessScreen(ColorScheme colorScheme, TextTheme textTheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: DashboardAppBar(
        name: 'User',
        wardNo: 'N/A',
        area: 'N/A',
        palika: 'N/A',
        cusID: 'N/A',
        phone: 'N/A',
        meterNo: 'N/A',
        advance: '0',
        showBackButton: false,
        showCustomerInfo: false,
        onNotificationTap: () {},
        onLogoutTap: () {},
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Complaint Submitted!',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your complaint has been submitted successfully. We will review and respond within 24 hours.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showSuccess = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Another',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
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
}