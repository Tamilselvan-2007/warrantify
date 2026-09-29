import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_providers.dart';

class UserSignupScreen extends ConsumerStatefulWidget {
  const UserSignupScreen({super.key});

  @override
  ConsumerState<UserSignupScreen> createState() => _UserSignupScreenState();
}

class _UserSignupScreenState extends ConsumerState<UserSignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _submitSignup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Passwords don't match");
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: 'customer',
      );
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  } 
  

  Future<void> _verifyOtp() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.verifySignupOtp(
        email: _emailController.text.trim(),
        token: _otpController.text.trim(),
      );
      // Handle successful OTP verification (e.g., navigate to home screen)
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              enabled: !_otpSent,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              enabled: !_otpSent,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              obscureText: true,
              enabled: !_otpSent,
            ),
            const SizedBox(height: 16),
            if (_otpSent)
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : (_otpSent ? _verifyOtp : _submitSignup), // OTP verify wired next step
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_loading
                    ? 'Please wait...'
                    : (_otpSent ? 'Verify & Sign Up' : 'Sign Up')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}