import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/utils/error_handler.dart';

final paymentProvider = NotifierProvider<PaymentNotifier, PaymentState>(
  PaymentNotifier.new,
);

class PaymentNotifier extends Notifier<PaymentState> {
  late final ApiClient _apiClient;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  bool _disposed = false;

  @override
  PaymentState build() {
    ref.onDispose(() {
      _disposed = true;
      _pollTimer?.cancel();
    });
    _apiClient = ref.watch(apiClientProvider);
    return PaymentState.initial();
  }

  Future<void> initiateMpesaPayment(String jobId) async {
    state = state.copyWith(isProcessing: true, error: null);

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

        _startPolling(response.data['checkoutRequestId']);
      }
    } catch (e) {
      ErrorHandler.logError('Payment initiation failed', e);
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to initiate payment. Please try again.',
      );
    }
  }

  void _startPolling(String checkoutRequestId) {
    _pollTimer?.cancel();
    _pollAttempts = 0;
    _pollNext(checkoutRequestId);
  }

  void _pollNext(String checkoutRequestId) {
    if (_disposed) return;
    const maxAttempts = 20;
    if (_pollAttempts >= maxAttempts) {
      state = state.copyWith(
        status: 'failed',
        isProcessing: false,
        error: 'Payment verification timed out. Please check your M-PESA.',
      );
      return;
    }

    _pollTimer = Timer(const Duration(seconds: 3), () async {
      if (_disposed) return;
      _pollAttempts++;

      try {
        final response = await _apiClient.get(
          '${Endpoints.checkPaymentStatus}/$checkoutRequestId',
        );

        if (response.statusCode == 200 && !_disposed) {
          final status = response.data['status'];

          if (status == 'completed') {
            state = state.copyWith(
              status: 'completed',
              isProcessing: false,
              transactionId: response.data['transactionId'],
            );
            return;
          }

          if (status == 'failed') {
            state = state.copyWith(
              status: 'failed',
              isProcessing: false,
              error: response.data['message'] ?? 'Payment failed.',
            );
            return;
          }

          _pollNext(checkoutRequestId);
        }
      } catch (e) {
        ErrorHandler.logError('Payment poll error', e);
        if (!_disposed) {
          _pollNext(checkoutRequestId);
        }
      }
    });
  }

  Future<void> checkPaymentStatus() async {
    if (state.checkoutRequestId == null) return;
    _pollAttempts = 0;
    _pollNext(state.checkoutRequestId!);
  }

  void reset() {
    _pollTimer?.cancel();
    _pollAttempts = 0;
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
