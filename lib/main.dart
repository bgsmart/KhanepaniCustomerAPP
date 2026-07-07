// lib/main.dart
import 'package:KhanepaniApp/screens/complaint_screen.dart';
import 'package:KhanepaniApp/screens/forgot_password_screen.dart';
import 'package:KhanepaniApp/screens/reading_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/notices_screen.dart';
import 'screens/about_screen.dart';
import 'screens/self_reading_screen.dart';
import 'screens/consumption_history_screen.dart';
import 'screens/account_statement_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/notice_provider.dart';
import 'providers/reading_provider.dart';
import 'providers/complaint_provider.dart';  // ✅ Add this import
import 'theme/app_theme.dart';

void main() {
  runApp(const AquaFlowApp());
}

class AquaFlowApp extends StatelessWidget {
  const AquaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(create: (_) => ReadingProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()), // ✅ Add ComplaintProvider
      ],
      child: MaterialApp(
        title: 'HWSHBOARD',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/notices': (context) => const NoticesScreen(),
          '/about': (context) => const AboutScreen(),
          '/self-reading': (context) => const SelfReadingScreen(),
          '/consumption-history': (context) => const ConsumptionHistoryScreen(),
          '/account-statement': (context) => const AccountStatementScreen(),
          '/reading-history': (context) => const ReadingHistoryScreen(),
          '/complaint': (context) => const ComplaintScreen(),  // ✅ Fixed: changed to /complaint
          '/complain': (context) => const ComplaintScreen(),  // ✅ Also keep this for backward compatibility
        },
      ),
    );
  }
}