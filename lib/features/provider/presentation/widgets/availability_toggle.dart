import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/availability_provider.dart';

class AvailabilityToggleWidget extends ConsumerWidget {
  const AvailabilityToggleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityState = ref.watch(availabilityProvider);
    final isOnline = availabilityState.isOnline;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            isOnline ? 'You are Online' : 'You are Offline',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOnline ? Colors.green : Colors.red,
            ),
          ),
          subtitle: Text(
            isOnline
                ? 'Customers can see you and request your services'
                : 'You are not visible to customers',
          ),
          value: isOnline,
          onChanged: availabilityState.isLoading
              ? null
              : (value) {
                  ref.read(availabilityProvider.notifier).toggleAvailability();
                },
          activeColor: Colors.green,
          inactiveThumbColor: Colors.red,
          inactiveTrackColor: Colors.red.shade100,
        ),
      ),
    );
  }
}
