class SqsCalculator {
  /// Calculate Service Quality Score from review scores
  /// Returns a value between 0 and 100
  static double calculate({
    required int overallExperience,
    required int timeliness,
    required int professionalism,
    required int communication,
    required int courtesy,
    required int workQuality,
    required int attentionToDetail,
    required int cleanliness,
    required int reliability,
    required int valueForMoney,
    required int recommendation,
    int? problemResolution,
  }) {
    final List<int> scores = [
      overallExperience,
      timeliness,
      professionalism,
      communication,
      courtesy,
      workQuality,
      attentionToDetail,
      cleanliness,
      reliability,
      valueForMoney,
      recommendation,
    ];

    // Add problem resolution if provided
    if (problemResolution != null) {
      scores.add(problemResolution);
    }

    // Calculate average
    final average = scores.reduce((a, b) => a + b) / scores.length;

    return average;
  }

  /// Calculate provider's overall SQS from multiple reviews
  static double calculateProviderSqs(List<double> sqsScores) {
    if (sqsScores.isEmpty) return 0.0;

    final average = sqsScores.reduce((a, b) => a + b) / sqsScores.length;
    return average;
  }

  /// Calculate category-specific score from multiple reviews
  static double calculateCategoryScore(List<int> scores) {
    if (scores.isEmpty) return 0.0;

    final average = scores.reduce((a, b) => a + b) / scores.length;
    return average;
  }
}