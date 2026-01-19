import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_driver/config/theme.dart';
import 'package:app_driver/providers/auth_provider.dart';
import 'package:app_driver/providers/route_provider.dart';
import 'package:app_driver/providers/sales_provider.dart';
import 'package:app_driver/screens/login_screen.dart';
import 'package:app_driver/screens/dashboard_screen.dart';
import 'package:app_driver/widgets/session_timeout_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
      ],
      child: MaterialApp(
        title: 'App Repartidor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.status == AuthStatus.authenticated) {
          return const SessionTimeoutManager(
            child: DashboardScreen(),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
