import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../providers/job_provider.dart';
import '../models/job_state.dart';
import '../../../shared/widgets/service_quality_score.dart';
import '../../../shared/widgets/user_avatar.dart';

class MatchingScreen extends ConsumerStatefulWidget {
  final String jobId;

  const MatchingScreen({super.key, required this.jobId});

  @override
  ConsumerState<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends ConsumerState<MatchingScreen> {
  @override
  void initState() {
    super.initState();
    _listenForMatch();
  }

  void _listenForMatch() {
    Future.delayed(const Duration(seconds: 30), () {
      if (ref.read(jobProvider).status == JobStatus.matching) {
        _showNoProvidersFound();
      }
    });
  }

  void _showNoProvidersFound() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('No Providers Found'),
        content: const Text(
          'No available providers in your area. Please try again later.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(jobProvider);

    return Scaffold(
      body: Center(
        child: jobState.status == JobStatus.matched && jobState.provider != null
            ? _buildMatchedScreen(jobState.provider!)
            : _buildMatchingScreen(),
      ),
    );
  }

  Widget _buildMatchingScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/animations/searching.json',
          width: 200,
          height: 200,
        ),
        const SizedBox(height: 32),
        const Text(
          'Finding the best provider...',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'We are matching you with available providers nearby',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildMatchedScreen(Map<String, dynamic> provider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Provider Found!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  UserAvatar(
                    imageUrl: provider['avatar'],
                    name: provider['name'] ?? '',
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                   const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       ServiceQualityScore(
                         score: (provider['serviceQualityScore'] ?? provider['rating'] * 20).toDouble(),
                         size: 40,
                         showLabel: false,
                       ),
                       const SizedBox(width: 12),
                       Text(
                         '${provider['reviews']} reviews',
                       ),
                     ],
                   ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text('${provider['distance']} km away'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'KES ${provider['price']}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                '/active-job',
                arguments: widget.jobId,
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
