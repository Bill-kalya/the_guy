import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';

final adminFinanceProvider = NotifierProvider<AdminFinanceNotifier, AdminFinanceState>(
  AdminFinanceNotifier.new,
);

class AdminFinanceNotifier extends Notifier<AdminFinanceState> {
  late final ApiClient _api;

  @override
  AdminFinanceState build() {
    _api = ref.watch(apiClientProvider);
    return AdminFinanceState.initial();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        _loadSummary(),
        _loadRevenueTrend(),
        _loadPendingPayouts(),
        _loadLedger(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadSummary() async {
    try {
      final res = await _api.get(Endpoints.adminFinanceSummary);
      final data = _unwrap(res.data);
      if (data != null) state = state.copyWith(summary: data);
    } catch (_) {}
  }

  Future<void> _loadRevenueTrend() async {
    try {
      final res = await _api.get('${Endpoints.adminFinanceRevenueTrend}?days=30');
      final data = _unwrapList(res.data);
      if (data != null) state = state.copyWith(revenueTrend: data);
    } catch (_) {}
  }

  Future<void> _loadPendingPayouts() async {
    try {
      final res = await _api.get(Endpoints.adminFinancePendingPayouts);
      final data = _unwrapList(res.data);
      if (data != null) state = state.copyWith(pendingPayouts: data);
    } catch (_) {}
  }

  Future<void> _loadLedger() async {
    try {
      final res = await _api.get('${Endpoints.adminFinanceLedger}?size=20');
      final data = _unwrapPageList(res.data);
      if (data != null) state = state.copyWith(ledger: data);
    } catch (_) {}
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  List<dynamic>? _unwrapList(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      final d = data['data'];
      return d is List ? d : null;
    }
    return data is List ? data : null;
  }

  List<dynamic>? _unwrapPageList(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      final d = data['data'];
      if (d is Map<String, dynamic> && d.containsKey('content')) {
        return d['content'] as List<dynamic>?;
      }
      return d is List ? d : null;
    }
    if (data is Map<String, dynamic> && data.containsKey('content')) {
      return data['content'] as List<dynamic>?;
    }
    return data is List ? data : null;
  }
}

class AdminFinanceState {
  final Map<String, dynamic>? summary;
  final List<dynamic> revenueTrend;
  final List<dynamic> pendingPayouts;
  final List<dynamic> ledger;
  final bool isLoading;
  final String? error;

  AdminFinanceState({
    this.summary,
    this.revenueTrend = const [],
    this.pendingPayouts = const [],
    this.ledger = const [],
    this.isLoading = false,
    this.error,
  });

  factory AdminFinanceState.initial() => AdminFinanceState();

  AdminFinanceState copyWith({
    Map<String, dynamic>? summary,
    List<dynamic>? revenueTrend,
    List<dynamic>? pendingPayouts,
    List<dynamic>? ledger,
    bool? isLoading,
    String? error,
  }) {
    return AdminFinanceState(
      summary: summary ?? this.summary,
      revenueTrend: revenueTrend ?? this.revenueTrend,
      pendingPayouts: pendingPayouts ?? this.pendingPayouts,
      ledger: ledger ?? this.ledger,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
