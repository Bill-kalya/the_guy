import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Periodically refreshes a Riverpod notifier while it has active listeners.
///
/// Call [startAutoRefresh] from the notifier's `build()`. The timer is
/// cancelled automatically when the notifier is disposed (i.e. when the last
/// screen watching it is removed), so at most the visible screen polls.
mixin AutoRefreshMixin<T> on Notifier<T> {
  Timer? _autoRefreshTimer;

  /// How often to re-fetch while the notifier is alive.
  Duration get autoRefreshInterval => const Duration(seconds: 30);

  /// Re-fetch the latest data. Implementations usually delegate to `loadAll()`.
  Future<void> autoRefresh() async {}

  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(autoRefreshInterval, (_) => autoRefresh());
    ref.onDispose(() => _autoRefreshTimer?.cancel());
  }
}
