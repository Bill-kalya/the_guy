import 'package:flutter/material.dart';

class ServiceQualityScore extends StatelessWidget {
  final double score;
  final double size;
  final bool showLabel;

  const ServiceQualityScore({
    super.key,
    required this.score,
    this.size = 80,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure score is between 0 and 100
    final normalizedScore = score.clamp(0.0, 100.0);
    final percentage = normalizedScore / 100.0;

    // Determine color based on score
    Color scoreColor;
    if (normalizedScore >= 80) {
      scoreColor = Colors.green;
    } else if (normalizedScore >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
              ),
            ),
            // Progress circle
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: size / 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            // Score text
            Text(
              '${normalizedScore.round()}%',
              style: TextStyle(
                fontSize: size / 3.5,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          const Text(
            'SERVICE QUALITY SCORE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class ScoreBreakdownRow extends StatelessWidget {
  final String label;
  final double score;
  final bool showPercentage;

  const ScoreBreakdownRow({
    super.key,
    required this.label,
    required this.score,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedScore = score.clamp(0.0, 100.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Label
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          // Score bar
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: normalizedScore / 100.0,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  normalizedScore >= 80
                      ? Colors.green
                      : normalizedScore >= 60
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ),
          ),
          // Score value
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              showPercentage ? '${normalizedScore.round()}%' : normalizedScore.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class ScoreBreakdownList extends StatelessWidget {
  final Map<String, double> scores;

  const ScoreBreakdownList({
    super.key,
    required this.scores,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: scores.entries.map((entry) {
        return ScoreBreakdownRow(
          label: _formatLabel(entry.key),
          score: entry.value,
        );
      }).toList(),
    );
  }

  String _formatLabel(String key) {
    // Convert camelCase to Title Case with spaces
    return key
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}