import 'pricing_type.dart';

class PricingConfigModel {
  final String? serviceId;
  final PricingType pricingType;
  final double basePrice;
  final double? minPrice;
  final double? maxPrice;
  final int adjustmentPercent;
  final bool isActive;

  PricingConfigModel({
    this.serviceId,
    required this.pricingType,
    required this.basePrice,
    this.minPrice,
    this.maxPrice,
    this.adjustmentPercent = 10,
    this.isActive = true,
  });

  factory PricingConfigModel.fromJson(Map<String, dynamic> json) {
    return PricingConfigModel(
      serviceId: json['serviceId'],
      pricingType: PricingType.fromString(json['pricingType'] ?? 'CATALOG'),
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      minPrice: json['minPrice']?.toDouble(),
      maxPrice: json['maxPrice']?.toDouble(),
      adjustmentPercent: json['adjustmentPercent'] ?? 10,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    if (serviceId != null) 'serviceId': serviceId,
    'pricingType': pricingType.apiValue,
    'basePrice': basePrice,
    if (minPrice != null) 'minPrice': minPrice,
    if (maxPrice != null) 'maxPrice': maxPrice,
    'adjustmentPercent': adjustmentPercent,
  };
}
