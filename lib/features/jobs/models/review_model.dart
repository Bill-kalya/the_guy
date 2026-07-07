class ReviewModel {
  final String id;
  final String providerId;
  final String customerId;
  final String jobId;
  final int overallExperience;
  final int timeliness;
  final int professionalism;
  final int communication;
  final int courtesy;
  final int workQuality;
  final int attentionToDetail;
  final int cleanliness;
  final int reliability;
  final int valueForMoney;
  final int? problemResolution;
  final int recommendation;
  final double serviceQualityScore;
  final String? comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.providerId,
    required this.customerId,
    required this.jobId,
    required this.overallExperience,
    required this.timeliness,
    required this.professionalism,
    required this.communication,
    required this.courtesy,
    required this.workQuality,
    required this.attentionToDetail,
    required this.cleanliness,
    required this.reliability,
    required this.valueForMoney,
    this.problemResolution,
    required this.recommendation,
    required this.serviceQualityScore,
    this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      providerId: json['providerId'],
      customerId: json['customerId'],
      jobId: json['jobId'],
      overallExperience: json['overallExperience'],
      timeliness: json['timeliness'],
      professionalism: json['professionalism'],
      communication: json['communication'],
      courtesy: json['courtesy'],
      workQuality: json['workQuality'],
      attentionToDetail: json['attentionToDetail'],
      cleanliness: json['cleanliness'],
      reliability: json['reliability'],
      valueForMoney: json['valueForMoney'],
      problemResolution: json['problemResolution'],
      recommendation: json['recommendation'],
      serviceQualityScore: (json['serviceQualityScore'] ?? 0.0).toDouble(),
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'customerId': customerId,
      'jobId': jobId,
      'overallExperience': overallExperience,
      'timeliness': timeliness,
      'professionalism': professionalism,
      'communication': communication,
      'courtesy': courtesy,
      'workQuality': workQuality,
      'attentionToDetail': attentionToDetail,
      'cleanliness': cleanliness,
      'reliability': reliability,
      'valueForMoney': valueForMoney,
      'problemResolution': problemResolution,
      'recommendation': recommendation,
      'serviceQualityScore': serviceQualityScore,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CreateReviewRequest {
  final String jobId;
  final int overallExperience;
  final int timeliness;
  final int professionalism;
  final int communication;
  final int courtesy;
  final int workQuality;
  final int attentionToDetail;
  final int cleanliness;
  final int reliability;
  final int valueForMoney;
  final int? problemResolution;
  final int recommendation;
  final String? comment;

  CreateReviewRequest({
    required this.jobId,
    required this.overallExperience,
    required this.timeliness,
    required this.professionalism,
    required this.communication,
    required this.courtesy,
    required this.workQuality,
    required this.attentionToDetail,
    required this.cleanliness,
    required this.reliability,
    required this.valueForMoney,
    this.problemResolution,
    required this.recommendation,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'overallExperience': overallExperience,
      'timeliness': timeliness,
      'professionalism': professionalism,
      'communication': communication,
      'courtesy': courtesy,
      'workQuality': workQuality,
      'attentionToDetail': attentionToDetail,
      'cleanliness': cleanliness,
      'reliability': reliability,
      'valueForMoney': valueForMoney,
      'problemResolution': problemResolution,
      'recommendation': recommendation,
      'comment': comment,
    };
  }
}