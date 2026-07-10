import 'dart:math';

class NearbyProviderModel {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double distance; // meters
  final double? serviceQualityScore; // 0-100
  final double priceEstimate;
  final bool isOnline;
  final String verificationLevel;
  final double rating;
  final int jobsCompleted;
  final int etaMinutes;

  NearbyProviderModel({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.serviceQualityScore,
    required this.priceEstimate,
    required this.isOnline,
    required this.verificationLevel,
    required this.rating,
    required this.jobsCompleted,
    required this.etaMinutes,
  });

  factory NearbyProviderModel.fromJson(Map<String, dynamic> json) {
    return NearbyProviderModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Unknown',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      serviceQualityScore: json['serviceQualityScore']?.toDouble(),
      priceEstimate: (json['priceEstimate'] ?? 0.0).toDouble(),
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
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'serviceQualityScore': serviceQualityScore,
      'priceEstimate': priceEstimate,
      'isOnline': isOnline,
      'verificationLevel': verificationLevel,
      'rating': rating,
      'jobsCompleted': jobsCompleted,
      'etaMinutes': etaMinutes,
    };
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
    double? latitude,
    double? longitude,
    double? distance,
    double? serviceQualityScore,
    double? priceEstimate,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      serviceQualityScore: serviceQualityScore ?? this.serviceQualityScore,
      priceEstimate: priceEstimate ?? this.priceEstimate,
      isOnline: isOnline ?? this.isOnline,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      rating: rating ?? this.rating,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      etaMinutes: etaMinutes ?? this.etaMinutes,
    );
  }
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