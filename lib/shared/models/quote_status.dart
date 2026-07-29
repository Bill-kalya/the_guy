enum QuoteStatus {
  pending('Awaiting customer response'),
  accepted('Customer accepted \u2014 price locked'),
  rejected('Customer declined'),
  countered('Customer made counter-offer'),
  expired('Quote expired');

  final String description;

  const QuoteStatus(this.description);

  static QuoteStatus fromString(String value) {
    return QuoteStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuoteStatus.pending,
    );
  }
}
