class JobModel {
  final String id;
  final String customerId;
  final String category;
  final String description;
  final double price;
  final String status;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? dropoffAddress;
  final String? providerId;
  final String? providerName;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  JobModel({
    required this.id,
    required this.customerId,
    required this.category,
    required this.description,
    required this.price,
    required this.status,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.dropoffAddress,
    this.providerId,
    this.providerName,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'],
      customerId: json['customerId'],
      category: json['category'],
      description: json['description'],
      price: json['price'].toDouble(),
      status: json['status'],
      pickupLat: json['pickupLat'].toDouble(),
      pickupLng: json['pickupLng'].toDouble(),
      pickupAddress: json['pickupAddress'],
      dropoffLat: json['dropoffLat']?.toDouble(),
      dropoffLng: json['dropoffLng']?.toDouble(),
      dropoffAddress: json['dropoffAddress'],
      providerId: json['providerId'],
      providerName: json['providerName'],
      createdAt: DateTime.parse(json['createdAt']),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}
