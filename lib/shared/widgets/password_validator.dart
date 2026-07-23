import 'package:flutter/material.dart';

class PasswordValidator extends StatelessWidget {
  final String password;
  const PasswordValidator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final checks = [
      _Check('At least 8 characters', password.length >= 8),
      _Check(
          'One uppercase letter (A-Z)', password.contains(RegExp(r'[A-Z]'))),
      _Check(
          'One lowercase letter (a-z)', password.contains(RegExp(r'[a-z]'))),
      _Check('One number (0-9)', password.contains(RegExp(r'[0-9]'))),
      _Check('One special character (!@#\$%)',
          password.contains(RegExp(r'[!@#\$%^&+=]'))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: checks
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    c.pass ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: c.pass ? Colors.green : Colors.red.shade400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.pass
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      decoration:
                          c.pass ? TextDecoration.lineThrough : null,
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

class _Check {
  final String label;
  final bool pass;
  _Check(this.label, this.pass);
}
