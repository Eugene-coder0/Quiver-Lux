import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin(
      [String? emailOverride, String? passwordOverride]) async {
    final email = (emailOverride ?? _emailController.text).trim();
    final password = (passwordOverride ?? _passwordController.text).trim();

    if (email.isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }
    if (!_isValidEmail(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      _showMessage('Please enter your password.');
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .login(email, password);
    if (!mounted || !success) {
      _showMessage(ref.read(authProvider).error ?? 'Unable to sign in.');
      return;
    }

    final role = ref.read(authProvider).user?.role ?? 'customer';
    final path = switch (role) {
      'vendor' => '/vendor',
      'admin' => '/admin',
      _ => '/',
    };
    if (mounted) context.go(path);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1ED),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'QUIVER LUX',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: QuiverLuxTheme.matteBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Luxury Multi-Vendor Marketplace',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed:
                        authState.isLoading ? null : () => _handleLogin(),
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Create account'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/admin'),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Admin Portal'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
