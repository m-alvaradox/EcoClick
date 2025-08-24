import 'dart:async';
import 'package:flutter/material.dart';
import 'ui/theme.dart';
import 'screens/quiz_list_page.dart';
import 'screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const EcoClickApp());
}

class EcoClickApp extends StatelessWidget {
  const EcoClickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoClick',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      home: const InitialScreen(),
    );
  }
}

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  Future<bool> _hasName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('username');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasName(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        return snapshot.data == true ? const QuizListPage() : const LoginPage();
      },
    );
  }
}
