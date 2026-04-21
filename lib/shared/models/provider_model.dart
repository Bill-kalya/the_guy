class ProviderModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatar;
  final String category;
  final double rating;
  final int reviewsCount;
  final bool isOnline;
  final double distance; // in kilometers
  final double priceEstimate;
  final String? bio;
  final List<String>? skills;
  final int jobsCompleted;
  final String? businessName;
  final String? idNumber;
  final bool isVerified;

  ProviderModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatar,
    required this.category,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.isOnline = false,
    this.distance = 0.0,
    this.priceEstimate = 0.0,
    this.bio,
    this.skills,
    this.jobsCompleted = 0,
    this.businessName,
    this.idNumber,
    this.isVerified = false,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      avatar: json['avatar'],
      category: json['category'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviewsCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      distance: (json['distance'] ?? 0.0).toDouble(),
      priceEstimate: (json['priceEstimate'] ?? 0.0).toDouble(),
      bio: json['bio'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      jobsCompleted: json['jobsCompleted'] ?? 0,
      businessName: json['businessName'],
      idNumber: json['idNumber'],
      isVerified: json['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'avatar': avatar,
      'category': category,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'isOnline': isOnline,
      'distance': distance,
      'priceEstimate': priceEstimate,
      'bio': bio,
      'skills': skills,
      'jobsCompleted': jobsCompleted,
      'businessName': businessName,
      'idNumber': idNumber,
      'isVerified': isVerified,
    };
  }

  ProviderModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatar,
    String? category,
    double? rating,
    int? reviewsCount,
    bool? isOnline,
    double? distance,
    double? priceEstimate,
    String? bio,
    List<String>? skills,
    int? jobsCompleted,
    String? businessName,
    String? idNumber,
    bool? isVerified,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      isOnline: isOnline ?? this.isOnline,
      distance: distance ?? this.distance,
      priceEstimate: priceEstimate ?? this.priceEstimate,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      businessName: businessName ?? this.businessName,
      idNumber: idNumber ?? this.idNumber,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
