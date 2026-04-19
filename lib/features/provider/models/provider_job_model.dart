class ProviderJob {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String category;
  final String description;
  final double distance;
  final double price;
  final String status;
  final String requestedAt;
  final String? address;
  final double pickupLat;
  final double pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final bool hasResponded;

  ProviderJob({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.category,
    required this.description,
    required this.distance,
    required this.price,
    required this.status,
    required this.requestedAt,
    this.address,
    required this.pickupLat,
    required this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.hasResponded = false,
  });

  factory ProviderJob.fromJson(Map<String, dynamic> json) {
    return ProviderJob(
      id: json['id'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      category: json['category'],
      description: json['description'],
      distance: json['distance'].toDouble(),
      price: json['price'].toDouble(),
      status: json['status'],
      requestedAt: json['requestedAt'],
      address: json['address'],
      pickupLat: json['pickupLat'].toDouble(),
      pickupLng: json['pickupLng'].toDouble(),
      dropoffLat: json['dropoffLat']?.toDouble(),
      dropoffLng: json['dropoffLng']?.toDouble(),
      hasResponded: json['hasResponded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'category': category,
      'description': description,
      'distance': distance,
      'price': price,
      'status': status,
      'requestedAt': requestedAt,
      'address': address,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'hasResponded': hasResponded,
    };
  }

  ProviderJob copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? category,
    String? description,
    double? distance,
    double? price,
    String? status,
    String? requestedAt,
    String? address,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    bool? hasResponded,
  }) {
    return ProviderJob(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      category: category ?? this.category,
      description: description ?? this.description,
      distance: distance ?? this.distance,
      price: price ?? this.price,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      address: address ?? this.address,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      hasResponded: hasResponded ?? this.hasResponded,
    );
  }
}