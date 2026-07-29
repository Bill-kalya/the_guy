import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../shared/models/quote_model.dart';
import 'dart:async';

class QuoteState {
  final List<QuoteModel> quotes;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;

  const QuoteState({
    this.quotes = const [],
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
  });

  QuoteState copyWith({
    List<QuoteModel>? quotes,
    bool? isLoading,
    String? error,
    bool? isSubmitting,
  }) {
    return QuoteState(
      quotes: quotes ?? this.quotes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class QuoteProvider extends StateNotifier<QuoteState> {
  final Ref _ref;

  QuoteProvider(this._ref) : super(const QuoteState());

  Future<void> fetchQuotesByJob(String jobId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.get(Endpoints.quotesByJob(jobId));
      final data = response.data['data'] as List<dynamic>? ?? [];
      state = state.copyWith(
        quotes: data.map((e) => QuoteModel.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchProviderQuotes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.get(Endpoints.providerQuotes);
      final data = response.data['data'] as List<dynamic>? ?? [];
      state = state.copyWith(
        quotes: data.map((e) => QuoteModel.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchCustomerQuotes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final response = await api.get(Endpoints.customerQuotes);
      final data = response.data['data'] as List<dynamic>? ?? [];
      state = state.copyWith(
        quotes: data.map((e) => QuoteModel.fromJson(e)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> acceptQuote(String quoteId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final api = _ref.read(apiClientProvider);
      await api.post(Endpoints.acceptQuote(quoteId));
      await fetchCustomerQuotes();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> rejectQuote(String quoteId, {String? reason}) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final api = _ref.read(apiClientProvider);
      await api.post(Endpoints.rejectQuote(quoteId), data: {'reason': reason});
      await fetchCustomerQuotes();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> submitCounterOffer(String quoteId, double amount) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final api = _ref.read(apiClientProvider);
      await api.post(Endpoints.counterQuote(quoteId), data: {'counterAmount': amount});
      await fetchCustomerQuotes();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> acceptCounterOffer(String quoteId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final api = _ref.read(apiClientProvider);
      await api.post(Endpoints.acceptCounterQuote(quoteId));
      await fetchProviderQuotes();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final quoteProvider = StateNotifierProvider<QuoteProvider, QuoteState>((ref) {
  return QuoteProvider(ref);
});
