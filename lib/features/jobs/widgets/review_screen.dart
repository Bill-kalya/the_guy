import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/sqs_calculator.dart';
import '../../../shared/widgets/service_quality_score.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/review_model.dart';
import '../../../core/network/api_client.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String providerId;
  final String providerName;

  const ReviewScreen({
    super.key,
    required this.jobId,
    required this.providerId,
    required this.providerName,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  // Score values (0-100)
  int overallExperience = 80;
  int timeliness = 80;
  int professionalism = 80;
  int communication = 80;
  int courtesy = 80;
  int workQuality = 80;
  int attentionToDetail = 80;
  int cleanliness = 80;
  int reliability = 80;
  int valueForMoney = 80;
  int? problemResolution;
  int recommendation = 80;

  // Comment
  final TextEditingController _commentController = TextEditingController();

  // Loading state
  bool _isSubmitting = false;

  // Calculate SQS
  double get _sqs {
    return SqsCalculator.calculate(
      overallExperience: overallExperience,
      timeliness: timeliness,
      professionalism: professionalism,
      communication: communication,
      courtesy: courtesy,
      workQuality: workQuality,
      attentionToDetail: attentionToDetail,
      cleanliness: cleanliness,
      reliability: reliability,
      valueForMoney: valueForMoney,
      recommendation: recommendation,
      problemResolution: problemResolution,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Experience'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider info
            Text(
              'How was your experience with ${widget.providerName}?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // SQS Preview
            Center(
              child: Column(
                children: [
                  ServiceQualityScore(
                    score: _sqs,
                    size: 120,
                    showLabel: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Service Quality Score',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Review questions
            const Text(
              'Please rate the following aspects:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            ReviewQuestion(
              title: 'How satisfied were you with your overall experience?',
              initialValue: overallExperience.toDouble(),
              onChanged: (v) => setState(() => overallExperience = v.round()),
            ),

            ReviewQuestion(
              title: 'Was the service completed within a reasonable time?',
              initialValue: timeliness.toDouble(),
              onChanged: (v) => setState(() => timeliness = v.round()),
            ),

            ReviewQuestion(
              title: 'How professional was the service provider?',
              initialValue: professionalism.toDouble(),
              onChanged: (v) => setState(() => professionalism = v.round()),
            ),

            ReviewQuestion(
              title: 'How would you rate the communication?',
              initialValue: communication.toDouble(),
              onChanged: (v) => setState(() => communication = v.round()),
            ),

            ReviewQuestion(
              title: 'How courteous was the provider?',
              initialValue: courtesy.toDouble(),
              onChanged: (v) => setState(() => courtesy = v.round()),
            ),

            ReviewQuestion(
              title: 'How would you rate the quality of work?',
              initialValue: workQuality.toDouble(),
              onChanged: (v) => setState(() => workQuality = v.round()),
            ),

            ReviewQuestion(
              title: 'How would you rate the attention to detail?',
              initialValue: attentionToDetail.toDouble(),
              onChanged: (v) => setState(() => attentionToDetail = v.round()),
            ),

            ReviewQuestion(
              title: 'How would you rate the cleanliness?',
              initialValue: cleanliness.toDouble(),
              onChanged: (v) => setState(() => cleanliness = v.round()),
            ),

            ReviewQuestion(
              title: 'How reliable was the provider?',
              initialValue: reliability.toDouble(),
              onChanged: (v) => setState(() => reliability = v.round()),
            ),

            ReviewQuestion(
              title: 'How would you rate the value for money?',
              initialValue: valueForMoney.toDouble(),
              onChanged: (v) => setState(() => valueForMoney = v.round()),
            ),

            ReviewQuestion(
              title: 'Would you recommend this provider to others?',
              initialValue: recommendation.toDouble(),
              onChanged: (v) => setState(() => recommendation = v.round()),
            ),

            // Optional: Problem resolution
            const SizedBox(height: 16),
            const Text(
              'Did you experience any problems?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        problemResolution = problemResolution == null ? 80 : null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: problemResolution == null
                          ? Colors.grey[200]
                          : Colors.green,
                      foregroundColor: problemResolution == null
                          ? Colors.black87
                          : Colors.white,
                    ),
                    child: const Text('No problems'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: problemResolution == null
                        ? null
                        : () {
                            setState(() {
                              problemResolution = 40;
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: problemResolution != null && problemResolution! < 60
                          ? Colors.red
                          : Colors.grey[200],
                      foregroundColor: problemResolution != null && problemResolution! < 60
                          ? Colors.white
                          : Colors.black87,
                    ),
                    child: const Text('Had problems'),
                  ),
                ),
              ],
            ),
            if (problemResolution != null && problemResolution! < 60) ...[
              const SizedBox(height: 16),
              ReviewQuestion(
                title: 'How well were the problems resolved?',
                initialValue: problemResolution!.toDouble(),
                onChanged: (v) => setState(() => problemResolution = v.round()),
              ),
            ],

            // Comment
            const SizedBox(height: 24),
            const Text(
              'Additional Comments (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Share more details about your experience...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);

    try {
      final userId = ref.read(authProvider).user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final request = CreateReviewRequest(
        jobId: widget.jobId,
        overallExperience: overallExperience,
        timeliness: timeliness,
        professionalism: professionalism,
        communication: communication,
        courtesy: courtesy,
        workQuality: workQuality,
        attentionToDetail: attentionToDetail,
        cleanliness: cleanliness,
        reliability: reliability,
        valueForMoney: valueForMoney,
        problemResolution: problemResolution,
        recommendation: recommendation,
        comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      );

      final api = ref.read(apiClientProvider);
      final response = await api.post('/reviews', data: request.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

class ReviewQuestion extends StatefulWidget {
  final String title;
  final ValueChanged<double> onChanged;
  final double initialValue;

  const ReviewQuestion({
    super.key,
    required this.title,
    required this.onChanged,
    this.initialValue = 80,
  });

  @override
  State<ReviewQuestion> createState() => _ReviewQuestionState();
}

class _ReviewQuestionState extends State<ReviewQuestion> {
  late double value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            min: 0,
            max: 100,
            divisions: 100,
            value: value,
            label: '${value.round()}%',
            onChanged: (v) {
              setState(() => value = v);
              widget.onChanged(v);
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getScoreColor(value.round()).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getScoreColor(value.round()),
                  width: 1,
                ),
              ),
              child: Text(
                '${value.round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(value.round()),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}