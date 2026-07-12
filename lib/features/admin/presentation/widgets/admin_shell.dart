import 'package:flutter/material.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trust & Safety Operating System'),
      ),
      body: body,
    );
  }
}

