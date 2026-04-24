import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final Future<void> Function(String, String) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;

  // Input validation rules:
  // - Email must follow valid format
  // - Password must be at least 6 characters
  // - Empty fields are not allowed
  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Reset error
    setState(() {
      _errorMessage = null;
    });

    // Empty fields
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please enter both email and password";
      });
      return;
    }

    // Invalid email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = "Enter a valid email address";
      });
      return;
    }

    // Weak password
    if (password.length < 6) {
      setState(() {
        _errorMessage = "Password must be at least 6 characters";
      });
      return;
    }

    // Passed validation
    widget.onLogin(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Error message display
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _handleLogin,
              child: const Text('Login'),
            ),

            const SizedBox(height: 20),

            const Text(
              "Prototype: Credentials are not stored.\nFuture version will use secure authentication (e.g., Firebase).",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}