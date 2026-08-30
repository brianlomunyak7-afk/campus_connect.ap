import 'dart:convert';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await AuthStorage.loadToken();
  runApp(CampusConnectApp(isLoggedIn: isLoggedIn));
}

class CampusConnectApp extends StatelessWidget {
  final bool isLoggedIn;
  const CampusConnectApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          secondary: const Color(0xFFF59E0B),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}