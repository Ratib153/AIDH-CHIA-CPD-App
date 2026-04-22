import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Future<void> Function() onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: ElevatedButton(
          onPressed: onLogout,
          child: const Text("Logout"),
        ),
      ),
    );
  }
}