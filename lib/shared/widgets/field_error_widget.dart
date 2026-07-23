import 'package:flutter/material.dart';

class FieldErrorWidget extends StatelessWidget {
  final String? error;
  const FieldErrorWidget({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    if (error == null || error!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: Colors.red.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              error!,
              style: TextStyle(fontSize: 12, color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
