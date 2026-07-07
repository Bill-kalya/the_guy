class ProviderStatisticsModel {
  final String providerId;
  final double serviceQualityScore;
  final double professionalismScore;
  final double communicationScore;
  final double timelinessScore;
  final double workQualityScore;
  final double valueScore;
  final double reliabilityScore;
  final double courtesyScore;
  final int reviewCount;
  final DateTime updatedAt;

  ProviderStatisticsModel({
    required this.providerId,
    this.serviceQualityScore = 0.0,
    this.professionalismScore = 0.0,
    this.communicationScore = 0.0,
    this.timelinessScore = 0.0,
    this.workQualityScore = 0.0,
    this.valueScore = 0.0,
    this.reliabilityScore = 0.0,
    this.courtesyScore = 0.0,
    this.reviewCount = 0,
    required this.updatedAt,
  });

  factory ProviderStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ProviderStatisticsModel(
      providerId: json['providerId'],
      serviceQualityScore: (json['serviceQualityScore'] ?? 0.0).toDouble(),
      professionalismScore: (json['professionalismScore'] ?? 0.0).toDouble(),
      communicationScore: (json['communicationScore'] ?? 0.0).toDouble(),
      timelinessScore: (json['timelinessScore'] ?? 0.0).toDouble(),
      workQualityScore: (json['workQualityScore'] ?? 0.0).toDouble(),
      valueScore: (json['valueScore'] ?? 0.0).toDouble(),
      reliabilityScore: (json['reliabilityScore'] ?? 0.0).toDouble(),
      courtesyScore: (json['courtesyScore'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'serviceQualityScore': serviceQualityScore,
      'professionalismScore': professionalismScore,
      'communicationScore': communicationScore,
      'timelinessScore': timelinessScore,
      'workQualityScore': workQualityScore,
      'valueScore': valueScore,
      'reliabilityScore': reliabilityScore,
      'courtesyScore': courtesyScore,
      'reviewCount': reviewCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ProviderStatisticsModel copyWith({
    String? providerId,
    double? serviceQualityScore,
    double? professionalismScore,
    double? communicationScore,
    double? timelinessScore,
    double? workQualityScore,
    double? valueScore,
    double? reliabilityScore,
    double? courtesyScore,
    int? reviewCount,
    DateTime? updatedAt,
  }) {
    return ProviderStatisticsModel(
      providerId: providerId ?? this.providerId,
      serviceQualityScore: serviceQualityScore ?? this.serviceQualityScore,
      professionalismScore: professionalismScore ?? this.professionalismScore,
      communicationScore: communicationScore ?? this.communicationScore,
      timelinessScore: timelinessScore ?? this.timelinessScore,
      workQualityScore: workQualityScore ?? this.workQualityScore,
      valueScore: valueScore ?? this.valueScore,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      courtesyScore: courtesyScore ?? this.courtesyScore,
      reviewCount: reviewCount ?? this.reviewCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}