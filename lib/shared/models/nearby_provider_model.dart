import 'dart:math';

class NearbyProviderModel {
  final String id;
  final String name;
  final String category;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final double distance; // meters
  final double? serviceQualityScore; // 0-100
  final String? badge; // Bronze / Silver / Gold / Platinum
  final double priceEstimate;
  final double? minPrice;
  final double? maxPrice;
  final double? callOutFee;
  final double? searchScore;
  final bool isOnline;
  final String verificationLevel;
  final double rating;
  final int jobsCompleted;
  final int etaMinutes;

  NearbyProviderModel({
    required this.id,
    required this.name,
    required this.category,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.serviceQualityScore,
    this.badge,
    required this.priceEstimate,
    this.minPrice,
    this.maxPrice,
    this.callOutFee,
    this.searchScore,
    required this.isOnline,
    required this.verificationLevel,
    required this.rating,
    required this.jobsCompleted,
    required this.etaMinutes,
  });

  factory NearbyProviderModel.fromJson(Map<String, dynamic> json) {
    return NearbyProviderModel(
      id: json['id'] ?? '',
      name: json['name'] ?? json['businessName'] ?? '',
      category: json['category'] ?? 'Unknown',
      imageUrl: json['profileImageUrl'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      serviceQualityScore: json['serviceQualityScore']?.toDouble(),
      badge: json['badge'],
      priceEstimate: (json['priceEstimate'] ?? 0.0).toDouble(),
      minPrice: json['minPrice']?.toDouble(),
      maxPrice: json['maxPrice']?.toDouble(),
      callOutFee: json['callOutFee']?.toDouble(),
      searchScore: json['searchScore']?.toDouble(),
      isOnline: json['isOnline'] ?? false,
      verificationLevel: json['verificationLevel'] ?? 'NONE',
      rating: (json['rating'] ?? 0.0).toDouble(),
      jobsCompleted: json['jobsCompleted'] ?? 0,
      etaMinutes: json['etaMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'profileImageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'serviceQualityScore': serviceQualityScore,
      'badge': badge,
      'priceEstimate': priceEstimate,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'callOutFee': callOutFee,
      'searchScore': searchScore,
      'isOnline': isOnline,
      'verificationLevel': verificationLevel,
      'rating': rating,
      'jobsCompleted': jobsCompleted,
      'etaMinutes': etaMinutes,
    };
  }

  /// "KES 300 - 2,500" when both bounds exist, "From KES X" for a minimum
  /// only, falling back to the legacy single price estimate.
  String get priceLabel {
    final range = priceRangeLabel(minPrice, maxPrice);
    return range.isNotEmpty ? range : 'From KES ${priceEstimate.round()}';
  }

  /// Distance from this provider to another coordinate (meters)
  double distanceTo(double lat, double lng) {
    const double earthRadius = 6371000;
    double lat1 = latitude * pi / 180;
    double lat2 = lat * pi / 180;
    double deltaLat = (lat - latitude) * pi / 180;
    double deltaLng = (lng - longitude) * pi / 180;

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
               cos(lat1) * cos(lat2) *
               sin(deltaLng / 2) * sin(deltaLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  NearbyProviderModel copyWith({
    String? id,
    String? name,
    String? category,
    String? imageUrl,
    double? latitude,
    double? longitude,
    double? distance,
    double? serviceQualityScore,
    String? badge,
    double? priceEstimate,
    double? minPrice,
    double? maxPrice,
    double? callOutFee,
    double? searchScore,
    bool? isOnline,
    String? verificationLevel,
    double? rating,
    int? jobsCompleted,
    int? etaMinutes,
  }) {
    return NearbyProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      serviceQualityScore: serviceQualityScore ?? this.serviceQualityScore,
      badge: badge ?? this.badge,
      priceEstimate: priceEstimate ?? this.priceEstimate,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      callOutFee: callOutFee ?? this.callOutFee,
      searchScore: searchScore ?? this.searchScore,
      isOnline: isOnline ?? this.isOnline,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      rating: rating ?? this.rating,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      etaMinutes: etaMinutes ?? this.etaMinutes,
    );
  }
}

/// "KES 300 - 2,500" when both bounds exist, "From KES 300" for a minimum
/// only, otherwise an empty string.
String priceRangeLabel(double? minPrice, double? maxPrice) {
  if (minPrice != null && minPrice > 0 && maxPrice != null && maxPrice > 0) {
    return 'KES ${minPrice.round()} - ${maxPrice.round()}';
  }
  if (minPrice != null && minPrice > 0) {
    return 'From KES ${minPrice.round()}';
  }
  if (maxPrice != null && maxPrice > 0) {
    return 'Up to KES ${maxPrice.round()}';
  }
  return '';
}

/// Live provider location update received via WebSocket
class ProviderLocationUpdate {
  final String providerId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? heading;
  final double? speed;

  ProviderLocationUpdate({
    required this.providerId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.heading,
    this.speed,
  });

  factory ProviderLocationUpdate.fromJson(Map<String, dynamic> json) {
    return ProviderLocationUpdate(
      providerId: json['providerId'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      heading: json['heading']?.toDouble(),
      speed: json['speed']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'heading': heading,
      'speed': speed,
    };
  }
}