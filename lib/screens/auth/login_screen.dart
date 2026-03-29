import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/admin/admin_dashboard_screen.dart';
import 'package:flutter_application_1/screens/auth/register_screen.dart';
import 'package:flutter_application_1/screens/main_shell.dart';

enum LoginMode { user, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialMode = LoginMode.user});

  final LoginMode initialMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late LoginMode _mode;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final destination = _mode == LoginMode.admin
        ? const AdminDashboardScreen()
        : const MainShell(isPremium: true);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7FF), Color(0xFFE4ECFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _LoginBadge(),
                            Icon(
                              Icons.qr_code_scanner,
                              color: Color(0xFF0F65FF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in to sync your saved shops and continue rating.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        _ModeSelector(
                          mode: _mode,
                          onModeChanged: (mode) => setState(() => _mode = mode),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0x110F65FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF0F65FF),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Logging in makes your profile premium so badges, votes, and saved shops sync everywhere.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'your@email.com',
                                ),
                                validator: (value) =>
                                    value != null && value.contains('@')
                                    ? null
                                    : 'Enter valid email',
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                obscureText: true,
                                validator: (value) =>
                                    value != null && value.length >= 6
                                    ? null
                                    : 'Min 6 characters',
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submit,
                                  child: const Text('Sign In'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.lock_outline,
                                color: Color(0xFF0F65FF),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Two-factor ready. Admins get additional verification after sign in.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  ),
                              child: const Text('Sign up'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onModeChanged});

  final LoginMode mode;
  final ValueChanged<LoginMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: LoginMode.values
            .map(
              (option) => Expanded(
                child: GestureDetector(
                  onTap: () => onModeChanged(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: option == mode ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      option == LoginMode.user ? 'User' : 'Admin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: option == mode
                            ? const Color(0xFF0F65FF)
                            : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LoginBadge extends StatelessWidget {
  const _LoginBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x110F65FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'Secure login',
        style: TextStyle(color: Color(0xFF0F65FF), fontWeight: FontWeight.w600),
      ),
    );
  }
}
