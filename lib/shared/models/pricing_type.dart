enum PricingType {
  catalog('Fixed-price catalog'),
  quoteRequired('Quote required'),
  platformCalculated('Platform-calculated');

  final String displayName;

  const PricingType(this.displayName);

  static PricingType fromString(String value) {
    return PricingType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PricingType.catalog,
    );
  }

  String get apiValue {
    switch (this) {
      case PricingType.catalog:
        return 'CATALOG';
      case PricingType.quoteRequired:
        return 'QUOTE_REQUIRED';
      case PricingType.platformCalculated:
        return 'PLATFORM_CALCULATED';
    }
  }
}
