class ProviderProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String? bio;
  final String? profileImageUrl;
  final String? categoryId;
  final String verificationLevel;
  final double ratingAvg;
  final int totalReviews;
  final int jobsCompleted;
  final int jobsCancelled;
  final double responseRate;
  final double repeatClientsPercentage;
  final bool isOnline;
  final List<PortfolioImageModel> portfolioImages;
  final double? serviceQualityScore;
  final int? reviewCount;
  final Map<String, double>? scoreBreakdown;

  ProviderProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.bio,
    this.profileImageUrl,
    this.categoryId,
    this.verificationLevel = 'BASIC',
    this.ratingAvg = 0.0,
    this.totalReviews = 0,
    this.jobsCompleted = 0,
    this.jobsCancelled = 0,
    this.responseRate = 0.0,
    this.repeatClientsPercentage = 0.0,
    this.isOnline = false,
    this.portfolioImages = const [],
    this.serviceQualityScore,
    this.reviewCount,
    this.scoreBreakdown,
  });

  factory ProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return ProviderProfileModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      profileImageUrl: json['profileImageUrl'],
      categoryId: json['categoryId'],
      verificationLevel: json['verificationLevel'] ?? 'BASIC',
      ratingAvg: (json['ratingAvg'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      jobsCompleted: json['jobsCompleted'] ?? 0,
      jobsCancelled: json['jobsCancelled'] ?? 0,
      responseRate: (json['responseRate'] ?? 0.0).toDouble(),
      repeatClientsPercentage: (json['repeatClientsPercentage'] ?? 0.0).toDouble(),
      isOnline: json['isOnline'] ?? false,
      portfolioImages: json['portfolioImages'] != null
          ? (json['portfolioImages'] as List)
              .map((e) => PortfolioImageModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      serviceQualityScore: json['serviceQualityScore'] != null
          ? (json['serviceQualityScore'] as num).toDouble()
          : null,
      reviewCount: json['reviewCount'],
      scoreBreakdown: json['scoreBreakdown'] != null
          ? Map<String, double>.from(
              (json['scoreBreakdown'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())))
          : null,
    );
  }
}

class PortfolioImageModel {
  final String? id;
  final String imageUrl;
  final String? publicId;
  final int? sortOrder;

  PortfolioImageModel({
    this.id,
    required this.imageUrl,
    this.publicId,
    this.sortOrder,
  });

  factory PortfolioImageModel.fromJson(Map<String, dynamic> json) {
    return PortfolioImageModel(
      id: json['id'],
      imageUrl: json['imageUrl'] ?? '',
      publicId: json['publicId'],
      sortOrder: json['sortOrder'],
    );
  }
}
