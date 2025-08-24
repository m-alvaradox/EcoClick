import 'package:flutter/material.dart';
import 'package:frontend/screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getUsername() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('username') ?? 'Eco-Héroe';
}

Future<void> logoutAndGoToLogin(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('username');

  if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
