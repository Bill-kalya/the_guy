import 'quote_status.dart';

class QuoteModel {
  final String id;
  final String jobId;
  final String providerId;
  final String customerId;
  final double amount;
  final String? description;
  final int estimatedDurationMinutes;
  final QuoteStatus status;
  final double? counterAmount;
  final String? rejectionReason;
  final DateTime? respondedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  QuoteModel({
    required this.id,
    required this.jobId,
    required this.providerId,
    required this.customerId,
    required this.amount,
    this.description,
    required this.estimatedDurationMinutes,
    required this.status,
    this.counterAmount,
    this.rejectionReason,
    this.respondedAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      id: json['id'] ?? '',
      jobId: json['jobId'] ?? '',
      providerId: json['providerId'] ?? '',
      customerId: json['customerId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'],
      estimatedDurationMinutes: json['estimatedDurationMinutes'] ?? 60,
      status: QuoteStatus.fromString(json['status'] ?? 'PENDING'),
      counterAmount: json['counterAmount']?.toDouble(),
      rejectionReason: json['rejectionReason'],
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isRespondable =>
      status == QuoteStatus.pending || status == QuoteStatus.countered;

  bool get isFinalized =>
      status == QuoteStatus.accepted ||
      status == QuoteStatus.rejected ||
      status == QuoteStatus.expired;
}
