import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

class WalletData {
  final double pendingBalance;
  final double availableBalance;
  final double reservedBalance;
  final double totalBalance;
  final String currency;
  final List<WalletTransaction> transactions;

  WalletData({
    this.pendingBalance = 0,
    this.availableBalance = 0,
    this.reservedBalance = 0,
    this.totalBalance = 0,
    this.currency = 'KES',
    this.transactions = const [],
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      pendingBalance: (json['pendingBalance'] ?? 0).toDouble(),
      availableBalance: (json['availableBalance'] ?? 0).toDouble(),
      reservedBalance: (json['reservedBalance'] ?? 0).toDouble(),
      totalBalance: (json['totalBalance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'KES',
      transactions: (json['transactions'] as List? ?? [])
          .map((t) => WalletTransaction.fromJson(t))
          .toList(),
    );
  }
}

class WalletTransaction {
  final String id;
  final double amount;
  final String type;
  final String referenceType;
  final String? description;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.referenceType,
    this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      referenceType: json['referenceType'] ?? '',
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class WalletState {
  final bool isLoading;
  final WalletData? wallet;
  final String? error;

  WalletState({this.isLoading = false, this.wallet, this.error});

  WalletState copyWith({bool? isLoading, WalletData? wallet, String? error, bool clearError = false}) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      wallet: wallet ?? this.wallet,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final ApiClient _apiClient;

  WalletNotifier(this._apiClient) : super(WalletState());

  Future<void> fetchWallet() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final walletResponse = await _apiClient.get(Endpoints.wallet);
      List<WalletTransaction> transactions = [];
      try {
        final txResponse = await _apiClient.get('${Endpoints.wallet}/transactions');
        if (txResponse.statusCode == 200 && txResponse.data['data'] != null) {
          transactions = (txResponse.data['data'] as List)
              .map((t) => WalletTransaction.fromJson(t))
              .toList();
        }
      } catch (_) {}

      if (walletResponse.statusCode == 200) {
        final data = walletResponse.data['data'] ?? walletResponse.data;
        final walletJson = Map<String, dynamic>.from(data);
        walletJson['transactions'] = transactions.map((t) => {
          'id': t.id,
          'amount': t.amount,
          'type': t.type,
          'referenceType': t.referenceType,
          'description': t.description,
          'createdAt': t.createdAt.toIso8601String(),
        }).toList();
        final wallet = WalletData.fromJson(walletJson);
        state = state.copyWith(isLoading: false, wallet: wallet);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load wallet');
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> refreshWallet() => fetchWallet();
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.watch(apiClientProvider));
});
