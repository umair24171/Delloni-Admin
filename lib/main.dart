import 'dart:developer' as developer;
import 'dart:ui';

import 'package:delloniweb/controllers/admin_auth_provider.dart';
import 'package:delloniweb/controllers/admin_chat_provider.dart';
import 'package:delloniweb/controllers/admin_data_provider.dart';
import 'package:delloniweb/controllers/individual_chat_provider.dart';
import 'package:delloniweb/providers/admin_data_provider.dart';
import 'package:delloniweb/providers/analytics_provider.dart';
import 'package:delloniweb/providers/banner_provider.dart';
import 'package:delloniweb/providers/category_provider.dart';
import 'package:delloniweb/providers/chat_provider.dart';
import 'package:delloniweb/providers/product_provider.dart';
import 'package:delloniweb/providers/reports_provider.dart';
import 'package:delloniweb/providers/support_provider.dart';
import 'package:delloniweb/providers/user_provider.dart';
import 'package:delloniweb/resources/colors.dart';
import 'package:delloniweb/screens/admin_chat_dashboard.dart';
import 'package:delloniweb/screens/dashboard_layout.dart';
import 'package:delloniweb/screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(

      apiKey: "AIzaSyBE3vqWd_ReJyeHVcqtGe7uPDN9Gw6IyjY",
  authDomain: "delloni.firebaseapp.com",
  projectId: "delloni",
  storageBucket: "delloni.firebasestorage.app",
  messagingSenderId: "324991894056",
  appId: "1:324991894056:web:3ded49b4babd1aa261eb1d",
  measurementId: "G-L3GET4YLJB"
    ),
  );
  if (kIsWeb) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        print('ERROR: ${record.error}');
      }
      if (record.stackTrace != null) {
        print('STACK TRACE: ${record.stackTrace}');
      }
    });
  }

  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    developer.log(
      'Flutter Error: ${details.exception}',
      name: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
    print('🔴 FLUTTER ERROR: ${details.exception}');
    print('🔴 STACK TRACE: ${details.stack}');
  };

  // Handle platform dispatcher errors
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      'Platform Error: $error',
      name: 'PlatformError',
      error: error,
      stackTrace: stack,
    );
    print('🔴 PLATFORM ERROR: $error');
    print('🔴 STACK TRACE: $stack');
    return true;
  };
  
  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        // ChangeNotifierProvider(create: (_) => AdminDataProvider()),
         ChangeNotifierProvider(create: (_) => AdminChatProvider()),
          ChangeNotifierProvider(create: (_) => AdminIndividualChatProvider()),
          ChangeNotifierProvider(create: (_) => DashboardDataProvider()),
        
        // Individual providers (optional if you want direct access)
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),

      ],
      child: MaterialApp(
        title: 'Arabic Marketplace - Admin Panel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Roboto',
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.textDark,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: AppColors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        home: const AdminAuthWrapper(),
      ),
    );
  }
}

class AdminAuthWrapper extends StatelessWidget {
  const AdminAuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (authProvider.isAuthenticated) {
          return const AdminDashboard();
        }
        
        return const AdminLoginScreen();
      },
    );
  }
}