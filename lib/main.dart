import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

import 'package:bus_ticket_scanner/providers/auth_provider.dart';
import 'package:bus_ticket_scanner/providers/scanner_provider.dart';
import 'package:bus_ticket_scanner/providers/history_provider.dart';
import 'package:bus_ticket_scanner/screens/auth_screen.dart';
import 'package:bus_ticket_scanner/screens/home_screen.dart';
import 'package:bus_ticket_scanner/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  Logger.level = Level.debug;
  final logger = Logger();

  try {
    logger.i('Initializing application...');

    // Initialize packages
    const storage = FlutterSecureStorage();
    const baseUrl = 'https://n7gjzkm4-3001.euw.devtunnels.ms';

    // Initialize Dio client
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for logging
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              storage: storage,
              baseUrl: baseUrl,
              dio: dio, // Make sure your AuthProvider accepts this parameter
            ),
          ),
          ChangeNotifierProvider(create: (_) => ScannerProvider()),
          ChangeNotifierProvider(
            create: (_) => HistoryProvider()..loadScans(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    logger.i('Application started successfully');
  } catch (e, stackTrace) {
    logger.e('Application initialization failed',
        error: e, stackTrace: stackTrace);
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Ticket Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Remove isLoading check if not implemented in AuthProvider
          return authProvider.isAuthenticated
              ? HomeScreen()
              : const AuthScreen();
        },
      ),
      routes: {
        '/scanner': (context) => HomeScreen(),
        '/auth': (context) => const AuthScreen(),
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}
