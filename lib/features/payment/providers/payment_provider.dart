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

  Future<void> initiateMpesaPayment(String jobId, {String phoneNumber = ''}) async {
    state = state.copyWith(isProcessing: true, error: null, selectedMethod: 'MPESA');

    try {
      final response = await _apiClient.post(
        Endpoints.initiateMpesa,
        data: {
          'jobId': jobId,
          'phoneNumber': phoneNumber,
          'method': 'MPESA',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        state = state.copyWith(
          isProcessing: false,
          paymentId: data['paymentId'],
          amount: (data['amount'] ?? 0).toDouble(),
          status: 'pending_verification',
        );

        _startPolling(data['paymentId']);
      }
    } catch (e) {
      ErrorHandler.logError('Payment initiation failed', e);
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to initiate payment. Please try again.',
      );
    }
  }

  Future<void> initiateCardPayment(String jobId) async {
    state = state.copyWith(isProcessing: true, error: null, selectedMethod: 'CARD');

    try {
      final response = await _apiClient.post(
        Endpoints.initiateMpesa, // Same endpoint, different method param
        data: {
          'jobId': jobId,
          'method': 'CARD',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        state = state.copyWith(
          isProcessing: false,
          paymentId: data['paymentId'],
          amount: (data['amount'] ?? 0).toDouble(),
          clientSecret: data['clientSecret'],
          status: 'awaiting_card_input',
        );
      }
    } catch (e) {
      ErrorHandler.logError('Card payment initiation failed', e);
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to initiate card payment. Please try again.',
      );
    }
  }

  void setSelectedMethod(String method) {
    state = state.copyWith(selectedMethod: method, error: null);
  }

  void setCardProcessing() {
    state = state.copyWith(status: 'card_processing');
  }

  void _startPolling(String paymentId) {
    _pollTimer?.cancel();
    _pollAttempts = 0;
    _pollNext(paymentId);
  }

  void _pollNext(String paymentId) {
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
          Endpoints.paymentStatus(paymentId),
        );

        if (response.statusCode == 200 && !_disposed) {
          final status = response.data['status'];

          if (status == 'HELD') {
            state = state.copyWith(
              status: 'completed',
              isProcessing: false,
              transactionId: response.data['transactionId'],
            );
            return;
          }

          if (status == 'FAILED') {
            state = state.copyWith(
              status: 'failed',
              isProcessing: false,
              error: response.data['message'] ?? 'Payment failed.',
            );
            return;
          }

          _pollNext(paymentId);
        }
      } catch (e) {
        ErrorHandler.logError('Payment poll error', e);
        if (!_disposed) {
          _pollNext(paymentId);
        }
      }
    });
  }

  Future<void> checkPaymentStatus() async {
    if (state.paymentId == null) return;
    _pollAttempts = 0;
    _pollNext(state.paymentId!);
  }

  void reset() {
    _pollTimer?.cancel();
    _pollAttempts = 0;
    state = PaymentState.initial();
  }
}

class PaymentState {
  final bool isProcessing;
  final String? paymentId;
  final String? transactionId;
  final String status;
  final String? error;
  final double amount;
  final String? clientSecret;
  final String? selectedMethod;

  PaymentState({
    this.isProcessing = false,
    this.paymentId,
    this.transactionId,
    this.status = 'pending',
    this.error,
    this.amount = 0.0,
    this.clientSecret,
    this.selectedMethod,
  });

  factory PaymentState.initial() {
    return PaymentState();
  }

  PaymentState copyWith({
    bool? isProcessing,
    String? paymentId,
    String? transactionId,
    String? status,
    String? error,
    double? amount,
    String? clientSecret,
    String? selectedMethod,
  }) {
    return PaymentState(
      isProcessing: isProcessing ?? this.isProcessing,
      paymentId: paymentId ?? this.paymentId,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      error: error ?? this.error,
      amount: amount ?? this.amount,
      clientSecret: clientSecret ?? this.clientSecret,
      selectedMethod: selectedMethod ?? this.selectedMethod,
    );
  }

  bool get isPending => status == 'pending';
  bool get isPendingVerification => status == 'pending_verification';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}
