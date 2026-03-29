import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/auth/login_screen.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialMode: LoginMode.admin);
  }
}
