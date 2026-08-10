import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../network/websocket_service.dart';
import '../network/api_client.dart';
import '../network/endpoints.dart';
import '../../shared/models/nearby_provider_model.dart';
import '../utils/location_utils.dart';
import '../utils/error_handler.dart' as error_handler;

final trackingEngineProvider = Provider<TrackingEngine>((ref) {
  return TrackingEngine(ref);
});

class TrackingEngine {
  final Ref _ref;
  late final WebSocketService _wsService;
  late final ApiClient _apiClient;

  StreamSubscription<Position>? _positionSub;
  int _sequenceNumber = 0;
  Position? _lastSentPosition;
  Position? _lastKnownPosition;
  Timer? _etaTimer;
  Timer? _deadReckoningTimer;
  String? _currentJobId;
  bool _isTracking = false;

  ProviderLocationUpdate? _lastReceivedUpdate;
  DateTime? _lastReceivedTime;
  ProviderLocationUpdate? _offlineCache;
  List<LatLng>? _routePolyline;
  double? _lastSentHeading;
  double? _lastSentSpeed;

  // Distance threshold: don't send if moved less than this
  static const double minDistanceMeters = 10.0;

  // Heading threshold: send update if heading changed more than this
  static const double minHeadingChangeDeg = 15.0;

  // Speed threshold: send update if speed changed more than this (m/s)
  static const double minSpeedChangeMs = 2.0; // ~7 km/h

  // Minimum interval between updates regardless of conditions
  static const Duration absoluteMinInterval = Duration(milliseconds: 500);

  // Route deviation: if provider strays >200m from polyline, recalculate
  static const double significantDeviationMeters = 200.0;

  static const Duration deadReckoningTimeout = Duration(seconds: 10);
  static const Duration etaRefreshInterval = Duration(seconds: 45);

  DateTime _lastSendTime = DateTime.now();

  void Function(List<LatLng> polyline)? onRouteUpdated;
  void Function(Duration eta)? onEtaUpdated;
  void Function(ProviderLocationUpdate update)? onLocationReceived;
  void Function(LatLng position, double? heading)? onDeadReckoningUpdate;
  void Function()? onProviderOffline;

  TrackingEngine(this._ref) {
    _wsService = _ref.read(webSocketServiceProvider);
    _apiClient = _ref.read(apiClientProvider);
    _wsService.onReconnected = _onWsReconnected;
  }

  bool get isTracking => _isTracking;
  List<LatLng>? get routePolyline => _routePolyline;

  Future<void> startProviderTracking(String jobId) async {
    _currentJobId = jobId;
    _isTracking = true;
    _sequenceNumber = 0;
    _lastSentPosition = null;
    _lastSentHeading = null;
    _lastSentSpeed = null;
    _offlineCache = null;
    _lastSendTime = DateTime.now();

    _startEtaTimer(jobId);
    await _startGpsStream();
  }

  void startCustomerTracking(String jobId, String providerId) {
    _currentJobId = jobId;
    _isTracking = true;
    _lastReceivedUpdate = null;
    _lastReceivedTime = null;

    _wsService.subscribeToProviderLocation(providerId);
    _wsService.requestTrackProvider(providerId);

    _startDeadReckoning();
    _startEtaTimer(jobId);

    _fetchRoutePolyline(jobId);
  }

  void stopTracking() {
    _isTracking = false;
    _positionSub?.cancel();
    _positionSub = null;
    _etaTimer?.cancel();
    _etaTimer = null;
    _deadReckoningTimer?.cancel();
    _deadReckoningTimer = null;
    _lastKnownPosition = null;
    _lastSentPosition = null;
    _lastSentHeading = null;
    _lastSentSpeed = null;
    _offlineCache = null;
    _routePolyline = null;
    _currentJobId = null;
  }

  void onLocationMessage(Map<String, dynamic> data) {
    if (!_isTracking) return;

    final seq = data['sequence'] as int?;
    if (seq != null && _lastReceivedUpdate != null) {
      final lastSeqStr = _lastReceivedUpdate!.toJson()['sequence'] as int? ?? 0;
      if (seq <= lastSeqStr) return;
    }

    final update = ProviderLocationUpdate.fromJson(data);
    _lastReceivedUpdate = update;
    _lastReceivedTime = DateTime.now();

    onLocationReceived?.call(update);
    _checkRouteDeviation(update);
  }

  /// Returns an adaptive minimum interval based on speed.
  Duration _adaptiveInterval(double? speedMs) {
    if (speedMs == null || speedMs <= 0) {
      return const Duration(seconds: 15);
    }
    final speedKmh = speedMs * 3.6;
    if (speedKmh > 40) {
      return const Duration(seconds: 2);
    } else if (speedKmh > 10) {
      return const Duration(seconds: 5);
    }
    return const Duration(seconds: 10);
  }

  Future<void> _startGpsStream() async {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_onPositionChanged);
  }

  bool _shouldSendUpdate(Position position) {
    final now = DateTime.now();
    if (now.difference(_lastSendTime) < absoluteMinInterval) return false;

    final adaptiveMin = _adaptiveInterval(position.speed);
    if (now.difference(_lastSendTime) < adaptiveMin) return false;

    // Distance check
    if (_lastSentPosition != null) {
      final distance = LocationUtils.calculateDistance(
        _lastSentPosition!.latitude,
        _lastSentPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      if (distance < minDistanceMeters) {
        // Not far enough — check heading/speed change
      final headingChanged = _lastSentHeading != null &&
            (position.heading - _lastSentHeading!).abs() % 360 > minHeadingChangeDeg;
            final speedChanged = _lastSentSpeed != null &&
            (position.speed - _lastSentSpeed!).abs() > minSpeedChangeMs;
        if (!headingChanged && !speedChanged) return false;
      }
    }

    return true;
  }

  void _onPositionChanged(Position position) {
    if (!_isTracking) return;
    _lastKnownPosition = position;
    if (!_shouldSendUpdate(position)) return;

    final update = ProviderLocationUpdate(
      providerId: '',
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      heading: position.heading,
      speed: position.speed,
    );

    _sendUpdate(update);
    _lastSendTime = DateTime.now();
    _lastSentHeading = position.heading;
    _lastSentSpeed = position.speed;
  }

  void _sendUpdate(ProviderLocationUpdate update) {
    _sequenceNumber++;
    _lastSentPosition = _lastKnownPosition;

    if (!_wsService.isConnected) {
      _offlineCache = ProviderLocationUpdate(
        providerId: update.providerId,
        latitude: update.latitude,
        longitude: update.longitude,
        timestamp: update.timestamp,
        heading: update.heading,
        speed: update.speed,
      );
      return;
    }

    _wsService.sendLocationUpdate(
      update,
      sequenceNumber: _sequenceNumber,
      jobId: _currentJobId,
    );
  }

  void _onWsReconnected() {
    if (_offlineCache == null || !_isTracking) return;

    _sequenceNumber++;
    _wsService.sendLocationUpdate(
      _offlineCache!,
      sequenceNumber: _sequenceNumber,
      jobId: _currentJobId,
    );
    _offlineCache = null;
  }

  void _startDeadReckoning() {
    _deadReckoningTimer?.cancel();
    _deadReckoningTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _performDeadReckoning(),
    );
  }

  void _performDeadReckoning() {
    if (!_isTracking || _lastReceivedUpdate == null) return;
    if (_lastReceivedTime == null) return;

    final elapsed = DateTime.now().difference(_lastReceivedTime!);
    if (elapsed < deadReckoningTimeout) return;

    final speed = _lastReceivedUpdate!.speed ?? 0.0;
    final heading = _lastReceivedUpdate!.heading ?? 0.0;
    if (speed <= 0) return;

    final elapsedSeconds = elapsed.inMilliseconds / 1000.0;
    final distance = speed * elapsedSeconds;
    final distanceDeg = distance / 111320.0;
    final headingRad = heading * pi / 180;

    final newLat = _lastReceivedUpdate!.latitude + distanceDeg * cos(headingRad);
    final newLng = _lastReceivedUpdate!.longitude +
        distanceDeg * sin(headingRad) / cos(_lastReceivedUpdate!.latitude * pi / 180);

    onDeadReckoningUpdate?.call(LatLng(newLat, newLng), heading);
  }

  /// Check if provider has deviated significantly from the planned route.
  void _checkRouteDeviation(ProviderLocationUpdate update) {
    if (_routePolyline == null || _routePolyline!.length < 2) return;

    final providerLatLng = LatLng(update.latitude, update.longitude);
    double minDist = double.infinity;

    for (final point in _routePolyline!) {
      final d = LocationUtils.calculateDistance(
        providerLatLng.latitude,
        providerLatLng.longitude,
        point.latitude,
        point.longitude,
      );
      if (d < minDist) {
        minDist = d;
        if (minDist < significantDeviationMeters) break;
      }
    }

    if (minDist > significantDeviationMeters && _currentJobId != null) {
      _fetchRoutePolyline(_currentJobId!);
    }
  }

  void _startEtaTimer(String jobId) {
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(
      etaRefreshInterval,
      (_) => _refreshEta(jobId),
    );
  }

  Future<void> _refreshEta(String jobId) async {
    if (!_isTracking) return;

    try {
      final response = await _apiClient.get(
        EndpointBuilder.trackingEta(jobId),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('eta')) {
          final etaMinutes = data['eta'] as int;
          _lastEta = Duration(minutes: etaMinutes);
          onEtaUpdated?.call(_lastEta);
          return;
        }
      }
    } catch (e) {
      error_handler.ErrorHandler.logError('ETA refresh failed', e);
    }

    _fallbackEta();
  }

  void _fallbackEta() {
    if (_lastKnownPosition == null || _routePolyline == null || _routePolyline!.isEmpty) return;

    final dest = _routePolyline!.last;
    final distance = LocationUtils.calculateDistance(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      dest.latitude,
      dest.longitude,
    );

    _lastEta = LocationUtils.calculateETA(distance);
    onEtaUpdated?.call(_lastEta);
  }

  Future<void> _fetchRoutePolyline(String jobId) async {
    try {
      final response = await _apiClient.get(
        EndpointBuilder.trackingPolyline(jobId),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('polyline')) {
          final points = (data['polyline'] as List)
              .map((p) => LatLng(
                    (p['lat'] as num).toDouble(),
                    (p['lng'] as num).toDouble(),
                  ))
              .toList();
          _routePolyline = points;
          onRouteUpdated?.call(points);
        }
      }
    } catch (e) {
      error_handler.ErrorHandler.logError('Route polyline fetch failed', e);
    }
  }

  Duration _lastEta = Duration.zero;
  Duration get currentEta => _lastEta;
}
