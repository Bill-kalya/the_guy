import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _cancelledDialogShown = false;

  @override
  void initState() {
    super.initState();
    ref.read(jobProvider.notifier).startMatching(widget.jobId);
    _listenForMatch();
  }

  void _listenForMatch() {
    Future.delayed(const Duration(seconds: 30), () {
      if (!mounted) return;
      if (ref.read(jobProvider).status == JobStatus.matching) {
        _showNoProvidersFound();
      }
    });
  }

  void _maybeShowCancelledDialog() {
    if (_cancelledDialogShown) return;
    _cancelledDialogShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showNoProvidersFound();
    });
  }

  void _showNoProvidersFound() {
    if (_cancelledDialogShown) return;
    _cancelledDialogShown = true;
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
              context.pop();
              context.pop(); // Go back to home
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

    if (jobState.status == JobStatus.cancelled) {
      _maybeShowCancelledDialog();
    }

    final showMatched = (jobState.status == JobStatus.matched ||
            jobState.status == JobStatus.accepted) &&
        jobState.provider != null;

    return Scaffold(
      body: Center(
        child: showMatched
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
    final name = provider['name'] ?? 'Provider';
    final rating = (provider['rating'] ?? 0).toDouble();
    final serviceQualityScore =
        (provider['serviceQualityScore'] ?? rating * 20).toDouble();
    final reviews = (provider['reviews'] ?? 0).toInt();
    final distance = (provider['distance'] ?? 0).toDouble();
    final price = (provider['price'] ?? 0).toDouble();

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
                    name: name,
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
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
                        score: serviceQualityScore,
                        size: 40,
                        showLabel: false,
                      ),
                      const SizedBox(width: 12),
                      Text('$reviews reviews'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text('${distance.toStringAsFixed(1)} km away'),
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
                      'KES ${price.toStringAsFixed(0)}',
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
              context.pushReplacement('/active-job/${widget.jobId}');
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
