import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../shared/widgets/service_quality_score.dart';

class NearbyProvidersList extends StatelessWidget {
  final Position? position;

  const NearbyProvidersList({super.key, this.position});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Nearby Providers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildProviderCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(int index) {
    // Mock SQS score (in real app, this comes from provider data)
    final sqsScore = 85.0 + (index * 2);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.handyman)),
        title: const Text('John Doe'),
        subtitle: Row(
          children: [
            // Service Quality Score
            ServiceQualityScore(
              score: sqsScore,
              size: 40,
              showLabel: false,
            ),
            const SizedBox(width: 12),
            // Distance
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${(index + 1) * 0.5} km away'),
          ],
        ),
        trailing: const Chip(
          label: Text('Plumbing'),
          backgroundColor: Colors.blue,
          labelStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
