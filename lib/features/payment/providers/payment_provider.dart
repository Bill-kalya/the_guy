import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

final paymentProvider = NotifierProvider<PaymentNotifier, PaymentState>(
  PaymentNotifier.new,
);

class PaymentNotifier extends Notifier<PaymentState> {
  late final ApiClient _apiClient;

  @override
  PaymentState build() {
    _apiClient = ref.watch(apiClientProvider);
    return PaymentState.initial();
  }

  Future<void> initiateMpesaPayment(String jobId) async {
    state = state.copyWith(isProcessing: true);

    try {
      final response = await _apiClient.post(
        Endpoints.initiateMpesa,
        data: {'jobId': jobId},
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          isProcessing: false,
          checkoutRequestId: response.data['checkoutRequestId'],
          status: 'pending_verification',
        );

        // Start polling for payment status
        _pollPaymentStatus(response.data['checkoutRequestId']);
      }
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to initiate payment',
      );
    }
  }

  Future<void> _pollPaymentStatus(String checkoutRequestId) async {
    // Poll every 3 seconds for up to 60 seconds
    int attempts = 0;
    const maxAttempts = 20;

    Future.delayed(const Duration(seconds: 3), () async {
      attempts++;

      try {
        final response = await _apiClient.get(
          '${Endpoints.checkPaymentStatus}/$checkoutRequestId',
        );

        if (response.statusCode == 200) {
          final status = response.data['status'];

          if (status == 'completed') {
            state = state.copyWith(
              status: 'completed',
              isProcessing: false,
              transactionId: response.data['transactionId'],
            );
          } else if (status == 'failed') {
            state = state.copyWith(
              status: 'failed',
              isProcessing: false,
              error: response.data['message'] ?? 'Payment failed',
            );
          } else if (attempts < maxAttempts) {
            // Still pending, poll again
            _pollPaymentStatus(checkoutRequestId);
          } else {
            // Timeout
            state = state.copyWith(
              status: 'failed',
              isProcessing: false,
              error: 'Payment verification timeout',
            );
          }
        }
      } catch (e) {
        if (attempts >= maxAttempts) {
          state = state.copyWith(
            status: 'failed',
            isProcessing: false,
            error: 'Payment verification failed',
          );
        } else {
          _pollPaymentStatus(checkoutRequestId);
        }
      }
    });
  }

  Future<void> checkPaymentStatus() async {
    if (state.checkoutRequestId == null) return;
    await _pollPaymentStatus(state.checkoutRequestId!);
  }

  void reset() {
    state = PaymentState.initial();
  }
}

class PaymentState {
  final bool isProcessing;
  final String? checkoutRequestId;
  final String? transactionId;
  final String status;
  final String? error;
  final double amount;

  PaymentState({
    this.isProcessing = false,
    this.checkoutRequestId,
    this.transactionId,
    this.status = 'pending',
    this.error,
    this.amount = 0.0,
  });

  factory PaymentState.initial() {
    return PaymentState();
  }

  PaymentState copyWith({
    bool? isProcessing,
    String? checkoutRequestId,
    String? transactionId,
    String? status,
    String? error,
    double? amount,
  }) {
    return PaymentState(
      isProcessing: isProcessing ?? this.isProcessing,
      checkoutRequestId: checkoutRequestId ?? this.checkoutRequestId,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      error: error ?? this.error,
      amount: amount ?? this.amount,
    );
  }

  bool get isPending => status == 'pending';
  bool get isPendingVerification => status == 'pending_verification';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}
