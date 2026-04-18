import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/main_shell.dart';
import 'package:flutter_application_1/services/app_session.dart';
import 'package:flutter_application_1/services/firebase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isSubmitting = true);
    final user = await FirebaseService.registerUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email already exists or request failed')),
      );
      return;
    }

    AppSession.setUser(user);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE5ECFF), Color(0xFFF7F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x110F65FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Create your profile',
                            style: TextStyle(
                              color: Color(0xFF0F65FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Join ShopRate',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Share honest ratings, unlock achievements, and help millions shop smarter.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        const _ProgressSteps(),
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
                                  'Already creating as a guest? Secure your progress with a premium profile by signing up.',
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
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                ),
                                validator: (value) =>
                                    value != null && value.isNotEmpty
                                    ? null
                                    : 'Enter your name',
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                validator: (value) =>
                                    value != null && value.contains('@')
                                    ? null
                                    : 'Enter valid email',
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                obscureText: true,
                                validator: (value) =>
                                    value != null && value.length >= 6
                                    ? null
                                    : 'Min 6 characters',
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                ),
                                obscureText: true,
                                validator: (value) =>
                                    value != null && value.isNotEmpty
                                    ? null
                                    : 'Confirm your password',
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  child: Text(
                                    _isSubmitting
                                        ? 'Creating account...'
                                        : 'Create Account',
                                  ),
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
                                Icons.emoji_events_outlined,
                                color: Color(0xFF0F65FF),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Complete your profile to unlock Top Reviewer badges faster.',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?'),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Sign in'),
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

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps();

  @override
  Widget build(BuildContext context) {
    const labels = ['Profile', 'Verify', 'Review'];
    return Row(
      children: labels
          .asMap()
          .entries
          .map(
            (entry) => Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: entry.key == 0
                        ? const Color(0xFF0F65FF)
                        : const Color(0xFFE0E5F2),
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        color: entry.key == 0 ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: entry.key == 0
                          ? const Color(0xFF0F65FF)
                          : Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
