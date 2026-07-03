// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        
        // Attempt login
        final success = await authProvider.loginWithCustomerSimple(
          customerID: customerId,
          password: password,
        );
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          if (success && authProvider.isAuthenticated) {
            // ✅ Save credentials if remember me is checked
            await _saveCredentials(customerId.toString(), password);
            
            // Show success message
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful! Welcome back.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            
            // Navigate to dashboard
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      } on FormatException {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Invalid Customer ID format. Please enter numbers only.');
        }
      } on Exception catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Login failed: ${e.toString().replaceFirst('Exception: ', '')}');
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

  // ✅ New method to handle forgot password
  void _handleForgotPassword() {
    if (_customerIdController.text.isNotEmpty) {
      try {
        final customerId = int.parse(_customerIdController.text.trim());
        // Pass customer ID to forgot password screen
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

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Company Logo
                _buildLogo(colorScheme),
                const SizedBox(height: 16),
                
                // Company Name
                _buildCompanyName(textTheme, colorScheme),
                const SizedBox(height: 4),
                
                // Company Address
                _buildCompanyAddress(textTheme, colorScheme),
                const SizedBox(height: 32),

                // Error Message Display
                if (authProvider.errorMessage != null)
                  _buildErrorMessage(authProvider, textTheme, colorScheme),

                // Login Card
                _buildLoginCard(
                  colorScheme, 
                  textTheme, 
                  authProvider,
                ),

                const SizedBox(height: 16),

                // Quick Info Cards
                _buildInfoCards(colorScheme, textTheme),

                const SizedBox(height: 16),

                // Powered By
                _buildPoweredBy(textTheme, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Extracted widget builders for better readability
  Widget _buildLogo(ColorScheme colorScheme) {
    return Container(
      width: 120,
      height: 80,
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
          width: 100,
          height: 100,
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
              child: const Icon(
                Icons.water_drop,
                size: 50,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompanyName(TextTheme textTheme, ColorScheme colorScheme) {
    return Text(
      AppConfig.companyName,
      style: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.primary,
        height: 1.2,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCompanyAddress(TextTheme textTheme, ColorScheme colorScheme) {
    return Text(
      AppConfig.companyAddress,
      style: TextStyle(
        fontFamily: 'NotoSansDevanagari',
        fontSize: 14,
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
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer ID
              _buildCustomerIdField(textTheme, colorScheme, authProvider),
              const SizedBox(height: 16),

              // Password
              _buildPasswordField(textTheme, colorScheme, authProvider),
              const SizedBox(height: 16),

              // Remember Me
              _buildRememberMeCheckbox(textTheme, colorScheme, authProvider),
              const SizedBox(height: 24),

              // Login Button
              _buildLoginButton(colorScheme, authProvider),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerIdField(
    TextTheme textTheme,
    ColorScheme colorScheme,
    AuthProvider authProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer ID',
          style: textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _customerIdController,
          keyboardType: TextInputType.number,
          maxLength: 10,
          enabled: !authProvider.isLoading && !_isLoading,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person_outline),
            hintText: 'Enter your Customer ID',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password',
              style: textTheme.labelLarge,
            ),
            TextButton(
              onPressed: authProvider.isLoading || _isLoading 
                  ? null 
                  : _handleForgotPassword,
              child: Text(
                'Forgot Password?',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !authProvider.isLoading && !_isLoading,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            hintText: 'Enter your password',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
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
  ) {
    return Row(
      children: [
        Checkbox(
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
        Text(
          'Remember this device',
          style: textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          '🔒 Secure',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(ColorScheme colorScheme, AuthProvider authProvider) {
    final isLoading = authProvider.isLoading || _isLoading;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
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
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCards(ColorScheme colorScheme, TextTheme textTheme) {
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
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Color(0xFF006E28),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SECURITY',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'SSL Encrypted',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Color(0xFF4C4ACA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSISTANCE',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '24/7 Support',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPoweredBy(TextTheme textTheme, ColorScheme colorScheme) {
    return Center(
      child: Text(
        'Powered By : Iconsft Technologies',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}