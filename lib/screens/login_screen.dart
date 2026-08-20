// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../config/app_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isPasswordReset = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _customerIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ Load saved credentials from SharedPreferences
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getString('saved_customer_id');
      final password = prefs.getString('saved_password');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe && customerId != null && password != null) {
        setState(() {
          _rememberMe = true;
          _customerIdController.text = customerId;
          _passwordController.text = password;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  // ✅ Save credentials to SharedPreferences
  Future<void> _saveCredentials(String customerId, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_customer_id', customerId);
        await prefs.setString('saved_password', password);
        await prefs.setBool('remember_me', true);
        await prefs.setString('last_login', DateTime.now().toIso8601String());
      } else {
        await _clearSavedCredentials();
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  // ✅ Clear saved credentials
  Future<void> _clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_customer_id');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
      await prefs.remove('last_login');
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();

      setState(() => _isLoading = true);
      authProvider.clearError();

      try {
        final customerId = int.parse(_customerIdController.text.trim());
        final password = _passwordController.text.trim();

        final success = await authProvider.loginWithCustomerSimple(
          customerID: customerId,
          password: password,
        );

        if (mounted) {
          setState(() => _isLoading = false);

          if (success && authProvider.isAuthenticated) {
            await _saveCredentials(customerId.toString(), password);

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful! Welcome back.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      } on FormatException {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar(
              'Invalid Customer ID format. Please enter numbers only.');
        }
      } on Exception catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar(
              'Login failed: ${e.toString().replaceFirst('Exception: ', '')}');
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _handleForgotPassword() {
    if (_customerIdController.text.isNotEmpty) {
      try {
        final customerId = int.parse(_customerIdController.text.trim());
        Navigator.pushNamed(
          context,
          '/forgot-password',
          arguments: {'customerId': customerId},
        );
      } catch (_) {
        Navigator.pushNamed(context, '/forgot-password');
      }
    } else {
      Navigator.pushNamed(context, '/forgot-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authProvider = context.watch<AuthProvider>();

    // ✅ Responsive sizing based on screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width >= 360 && screenSize.width < 600;
    final isLargeScreen = screenSize.width >= 600 && screenSize.width < 1200;
    final isExtraLargeScreen = screenSize.width >= 1200;

    // ✅ Responsive padding and spacing
    final horizontalPadding = isSmallScreen
        ? 12.0
        : (isMediumScreen ? 20.0 : (isLargeScreen ? 24.0 : 32.0));
    final verticalPadding = isSmallScreen ? 16.0 : 20.0;
    final cardPadding = isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 24.0);
    final logoSize = isSmallScreen
        ? 60.0
        : (isMediumScreen ? 80.0 : (isLargeScreen ? 100.0 : 120.0));
    final fontSizeMultiplier = isSmallScreen
        ? 0.85
        : (isMediumScreen ? 1.0 : (isLargeScreen ? 1.1 : 1.2));
    final buttonHeight = isSmallScreen ? 48.0 : (isMediumScreen ? 52.0 : 56.0);
    final maxWidth =
        isExtraLargeScreen ? 400.0 : (isLargeScreen ? 500.0 : double.infinity);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Company Logo
                  _buildLogo(colorScheme, logoSize),
                  SizedBox(height: screenSize.height * 0.02),

                  // Company Name
                  _buildCompanyName(textTheme, colorScheme, fontSizeMultiplier),
                  SizedBox(height: screenSize.height * 0.005),

                  // Company Address
                  _buildCompanyAddress(
                      textTheme, colorScheme, fontSizeMultiplier),
                  SizedBox(height: screenSize.height * 0.03),

                  // Error Message Display
                  if (authProvider.errorMessage != null)
                    _buildErrorMessage(authProvider, textTheme, colorScheme),

                  // Login Card
                  _buildLoginCard(
                    colorScheme,
                    textTheme,
                    authProvider,
                    cardPadding,
                    fontSizeMultiplier,
                    buttonHeight,
                    isSmallScreen,
                  ),

                  SizedBox(height: screenSize.height * 0.02),

                  // Quick Info Cards - UPDATED with overflow fix
                  _buildInfoCards(colorScheme, textTheme, isSmallScreen),

                  SizedBox(height: screenSize.height * 0.02),

                  // Powered By
                  _buildPoweredBy(textTheme, colorScheme, fontSizeMultiplier),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Extracted widget builders with responsive parameters
  Widget _buildLogo(ColorScheme colorScheme, double size) {
    return Container(
      width: size * 1.2,
      height: size * 0.8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.15),
            blurRadius: 100,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/Logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primaryContainer,
                  ],
                ),
              ),
              child: Icon(
                Icons.water_drop,
                size: size * 0.5,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompanyName(
    TextTheme textTheme,
    ColorScheme colorScheme,
    double fontSizeMultiplier,
  ) {
    return Text(
      AppConfig.companyName,
      style: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontSize: 20 * fontSizeMultiplier,
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
        height: 1.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCompanyAddress(
    TextTheme textTheme,
    ColorScheme colorScheme,
    double fontSizeMultiplier,
  ) {
    return Text(
      AppConfig.companyAddress,
      style: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontSize: 14 * fontSizeMultiplier,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage(
    AuthProvider authProvider,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.error,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              authProvider.errorMessage!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => authProvider.clearError(),
            child: Icon(
              Icons.close,
              color: colorScheme.onErrorContainer,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(
    ColorScheme colorScheme,
    TextTheme textTheme,
    AuthProvider authProvider,
    double cardPadding,
    double fontSizeMultiplier,
    double buttonHeight,
    bool isSmallScreen,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer ID
              _buildCustomerIdField(
                textTheme,
                colorScheme,
                authProvider,
                fontSizeMultiplier,
                isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Password
              _buildPasswordField(
                textTheme,
                colorScheme,
                authProvider,
                fontSizeMultiplier,
                isSmallScreen,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),

              // Remember Me
              _buildRememberMeCheckbox(
                textTheme,
                colorScheme,
                authProvider,
                fontSizeMultiplier,
                isSmallScreen,
              ),
              const SizedBox(
                height: 10,
              ),
              InkWell(
                onTap: () {
                  launchUrlLink("https://sites.google.com/view/privacypolicyhetaudakhanepani/home");
                },
                child: const Text(
                  'I here by declare to accept the given policies.',
                  style: TextStyle(color: Colors.black),
                  textScaler: TextScaler.linear(1),
                ),
              ),
              // Login Button
              SizedBox(height: isSmallScreen ? 16 : 24),

              _buildLoginButton(
                colorScheme,
                authProvider,
                buttonHeight,
                fontSizeMultiplier,
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> launchUrlLink(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildCustomerIdField(
    TextTheme textTheme,
    ColorScheme colorScheme,
    AuthProvider authProvider,
    double fontSizeMultiplier,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer ID',
          style: textTheme.labelLarge?.copyWith(
            fontSize: 14 * fontSizeMultiplier,
          ),
        ),
        SizedBox(height: isSmallScreen ? 2 : 4),
        TextFormField(
          controller: _customerIdController,
          keyboardType: TextInputType.number,
          maxLength: 10,
          enabled: !authProvider.isLoading && !_isLoading,
          style: TextStyle(fontSize: 16 * fontSizeMultiplier),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.person_outline,
              size: isSmallScreen ? 20 : 24,
            ),
            hintText: 'Enter your Customer ID',
            hintStyle: TextStyle(fontSize: 14 * fontSizeMultiplier),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 10 : 12,
            ),
          ),
          onChanged: (value) {
            if (authProvider.errorMessage != null) {
              authProvider.clearError();
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your Customer ID';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid numeric Customer ID';
            }
            final number = int.parse(value);
            if (number < 1) {
              return 'Customer ID must be greater than 0';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    TextTheme textTheme,
    ColorScheme colorScheme,
    AuthProvider authProvider,
    double fontSizeMultiplier,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password',
              style: textTheme.labelLarge?.copyWith(
                fontSize: 14 * fontSizeMultiplier,
              ),
            ),
            TextButton(
              onPressed: authProvider.isLoading || _isLoading
                  ? null
                  : _handleForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 4 : 8,
                  vertical: isSmallScreen ? 4 : 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12 * fontSizeMultiplier,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 2 : 4),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !authProvider.isLoading && !_isLoading,
          style: TextStyle(fontSize: 16 * fontSizeMultiplier),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outline,
              size: isSmallScreen ? 20 : 24,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                size: isSmallScreen ? 20 : 24,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            hintText: 'Enter your password',
            hintStyle: TextStyle(fontSize: 14 * fontSizeMultiplier),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 10 : 12,
            ),
          ),
          onChanged: (value) {
            if (authProvider.errorMessage != null) {
              authProvider.clearError();
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 4) {
              return 'Password must be at least 4 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRememberMeCheckbox(
    TextTheme textTheme,
    ColorScheme colorScheme,
    AuthProvider authProvider,
    double fontSizeMultiplier,
    bool isSmallScreen,
  ) {
    return Row(
      children: [
        SizedBox(
          width: isSmallScreen ? 40 : 48,
          height: isSmallScreen ? 40 : 48,
          child: Checkbox(
            value: _rememberMe,
            onChanged: authProvider.isLoading || _isLoading
                ? null
                : (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                      if (!_rememberMe) {
                        _clearSavedCredentials();
                      }
                    });
                  },
            activeColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Text(
          'Remember this device',
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 14 * fontSizeMultiplier,
          ),
        ),
        const Spacer(),
        Text(
          '🔒 Secure',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontSize: 11 * fontSizeMultiplier,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(
    ColorScheme colorScheme,
    AuthProvider authProvider,
    double buttonHeight,
    double fontSizeMultiplier,
  ) {
    final isLoading = authProvider.isLoading || _isLoading;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: colorScheme.primary.withOpacity(0.3),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Login',
                style: TextStyle(
                  fontSize: 14 * fontSizeMultiplier,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // ✅ FIXED: Info Cards with proper overflow handling
  // ✅ FIXED: Info Cards in same row for all devices
  Widget _buildInfoCards(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isSmallScreen,
  ) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.verified,
                      color: const Color(0xFF006E28),
                      size: isSmallScreen ? 16 : 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SECURITY',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: isSmallScreen ? 8 : 10,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Flexible(
                          child: Text(
                            'SSL Encrypted',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 11 : 14,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.support_agent,
                      color: const Color(0xFF4C4ACA),
                      size: isSmallScreen ? 16 : 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ASSISTANCE',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: isSmallScreen ? 8 : 10,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Flexible(
                          child: Text(
                            '24/7 Support',
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 11 : 14,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPoweredBy(
    TextTheme textTheme,
    ColorScheme colorScheme,
    double fontSizeMultiplier,
  ) {
    return Center(
      child: Text(
        'Powered By : Devanasoft Pvt. Ltd.',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontSize: 12 * fontSizeMultiplier,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
