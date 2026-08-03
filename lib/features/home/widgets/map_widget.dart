import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/nearby_provider_model.dart';
import 'map_clustering.dart';

class MapWidget extends StatefulWidget {
  final Position? position;
  final List<NearbyProviderModel>? providers;
  final String? selectedProviderId;

  /// Map of live location updates from WebSocket
  final Map<String, ProviderLocationUpdate>? liveLocations;

  /// Optional route polyline to draw on the map
  final List<LatLng>? polyline;

  /// Called when a provider marker is tapped
  final ValueChanged<NearbyProviderModel>? onProviderTap;

  /// Called when the user taps the "near me" button (to refresh providers)
  final VoidCallback? onNearMe;

  /// Placement of the "near me" button overlay
  final Alignment nearMeAlignment;

  const MapWidget({
    super.key,
    this.position,
    this.providers,
    this.selectedProviderId,
    this.liveLocations,
    this.polyline,
    this.onProviderTap,
    this.onNearMe,
    this.nearMeAlignment = Alignment.bottomRight,
  });

  @override
  State<MapWidget> createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  static const LatLng _nairobi = LatLng(-1.286389, 36.817223);

  // Animation controllers for smooth marker movement
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, LatLng> _previousPositions = {};
  final Map<String, Marker> _animatedMarkers = {};

  // Latest heading per provider so the direction arrow survives position animation
  final Map<String, double> _markerHeadings = {};

  double _currentZoom = 12.0;
  StreamSubscription<MapEvent>? _mapEventSub;

  /// Centers the map on [point] at [zoom]. Used by callers (e.g. a browse
  /// sheet) to focus a tapped provider.
  void moveTo(LatLng point, double zoom) {
    _mapController.move(point, zoom);
    _currentZoom = zoom;
    setState(() {});
  }

  double get _zoom {
    try {
      return _mapController.camera.zoom;
    } catch (_) {
      return _currentZoom;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.position != null ? 15.0 : 12.0;
    _mapEventSub = _mapController.mapEventStream.listen(_onMapEvent);
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd || event is MapEventFlingAnimation) {
      try {
        final zoom = _mapController.camera.zoom;
        if ((zoom - _currentZoom).abs() > 0.05) {
          _currentZoom = zoom;
          if (mounted) setState(() {});
        }
      } catch (_) {
        // Camera not attached yet; ignore.
      }
    }
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate map to new position
    if (widget.position != null && oldWidget.position != widget.position) {
      _animateToLocation(widget.position!);
    }

    // Update provider markers when live locations change
    if (widget.liveLocations != oldWidget.liveLocations &&
        widget.liveLocations != null) {
      _updateLiveMarkers(widget.liveLocations!);
    }
  }

  void _animateToLocation(Position position) {
    _mapController.move(
      LatLng(position.latitude, position.longitude),
      15.0,
    );
  }

  void _updateLiveMarkers(Map<String, ProviderLocationUpdate> locations) {
    for (final entry in locations.entries) {
      final providerId = entry.key;
      final update = entry.value;
      final targetLatLng = LatLng(update.latitude, update.longitude);

      // If we have a previous position, animate the marker
      if (_previousPositions.containsKey(providerId)) {
        _animateMarker(
          providerId,
          _previousPositions[providerId]!,
          targetLatLng,
        );
      } else {
        // First update - just place the marker
        _addProviderMarker(providerId, targetLatLng, update.heading);
      }

      _previousPositions[providerId] = targetLatLng;
    }

    setState(() {});
  }

  void _animateMarker(String providerId, LatLng from, LatLng to) {
    // Dispose existing animation controller for this provider
    _animationControllers[providerId]?.dispose();

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animationControllers[providerId] = controller;

    controller.addListener(() {
      final t = controller.value;
      final lat = from.latitude + (to.latitude - from.latitude) * t;
      final lng = from.longitude + (to.longitude - from.longitude) * t;

      _addProviderMarker(providerId, LatLng(lat, lng), null);

      if (mounted) setState(() {});
    });

    controller.forward(from: 0.0);
  }

  void _addProviderMarker(
    String providerId,
    LatLng position,
    double? heading,
  ) {
    if (heading != null) {
      _markerHeadings[providerId] = heading;
    }

    final model = _providerModelFor(providerId);
    final selected = providerId == widget.selectedProviderId;

    setState(() {
      _animatedMarkers[providerId] = Marker(
        point: position,
        width: selected ? 52 : 40,
        height: selected ? 72 : 40,
        child: GestureDetector(
          onTap: () => _handleProviderTap(providerId),
          child: _markerChild(
            model: model,
            providerId: providerId,
            selected: selected,
            heading: _markerHeadings[providerId],
          ),
        ),
      );
    });
  }

  Marker _userMarker() {
    return Marker(
      point: LatLng(widget.position!.latitude, widget.position!.longitude),
      width: 40,
      height: 40,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Marker _providerMarker({
    required String providerId,
    required LatLng position,
  }) {
    final model = _providerModelFor(providerId);
    final selected = providerId == widget.selectedProviderId;

    return Marker(
      point: position,
      width: selected ? 52 : 40,
      height: selected ? 72 : 40,
      child: GestureDetector(
        onTap: () => _handleProviderTap(providerId),
        child: _markerChild(
          model: model,
          providerId: providerId,
          selected: selected,
          heading: _markerHeadings[providerId],
        ),
      ),
    );
  }

  /// Selected/assigned providers render a profile-photo marker with a
  /// status ring and a direction arrow; browsing markers render a service
  /// category icon inside an availability-colored circle.
  Widget _markerChild({
    required NearbyProviderModel? model,
    required String providerId,
    required bool selected,
    required double? heading,
  }) {
    if (selected) {
      return _selectedMarkerChild(model, heading);
    }
    return _categoryMarkerChild(model);
  }

  Widget _selectedMarkerChild(NearbyProviderModel? model, double? heading) {
    final imageUrl = model?.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final ringColor = model == null || !model.isOnline
        ? Colors.grey
        : Colors.green;

    final circle = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: ringColor,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasImage
          ? null
          : Icon(
              _categoryIcon(model?.category),
              color: _categoryColor(model?.category),
              size: 26,
            ),
    );

    if (heading == null) {
      return circle;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: heading * pi / 180,
          child: const Icon(
            Icons.navigation,
            color: Colors.green,
            size: 18,
          ),
        ),
        const SizedBox(height: 2),
        circle,
      ],
    );
  }

  /// Availability color: green when online, gray when offline.
  Color _availabilityColor(NearbyProviderModel? model) {
    if (model == null || !model.isOnline) return Colors.grey;
    return Colors.green;
  }

  Widget _categoryMarkerChild(NearbyProviderModel? model) {
    final color = _availabilityColor(model);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _categoryIcon(model?.category),
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Marker _buildClusterMarker(ProviderCluster cluster) {
    final category = cluster.dominantCategory;
    final color =
        category == null ? Colors.blue : _categoryColor(category);

    return Marker(
      point: cluster.center,
      width: 56,
      height: 56,
      child: GestureDetector(
        onTap: () => _zoomIntoCluster(cluster.center),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_categoryIcon(category), color: Colors.white, size: 14),
              Text(
                '${cluster.count}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _zoomIntoCluster(LatLng center) {
    final targetZoom = (_currentZoom + 2.0).clamp(3.0, 18.0);
    _mapController.move(center, targetZoom);
    _currentZoom = targetZoom;
    setState(() {});
  }

  Marker _buildSingleProviderMarker(ProviderPoint point) {
    // Reuse the animated marker so live providers keep gliding smoothly.
    if (point.isLive && _animatedMarkers.containsKey(point.providerId)) {
      return _animatedMarkers[point.providerId]!;
    }
    return _providerMarker(
      providerId: point.providerId,
      position: point.position,
    );
  }

  List<ProviderPoint> _buildProviderPoints() {
    final points = <ProviderPoint>[];
    final handled = <String>{};

    if (widget.liveLocations != null) {
      widget.liveLocations!.forEach((providerId, update) {
        points.add(ProviderPoint(
          providerId: providerId,
          provider: _providerModelFor(providerId),
          position: LatLng(update.latitude, update.longitude),
          isLive: true,
        ));
        handled.add(providerId);
      });
    }

    if (widget.providers != null) {
      for (final provider in widget.providers!) {
        if (handled.contains(provider.id)) continue;
        points.add(ProviderPoint(
          providerId: provider.id,
          provider: provider,
          position: LatLng(provider.latitude, provider.longitude),
        ));
      }
    }

    return points;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Add user location marker
    if (widget.position != null) {
      markers.add(_userMarker());
    }

    // Cluster nearby providers into count bubbles at overview zoom, or render
    // them individually as the user zooms in.
    final points = _buildProviderPoints();
    if (points.isEmpty) return markers;

    final clusters = clusterProviders(points, _zoom);
    for (final cluster in clusters) {
      if (cluster.count == 1) {
        markers.add(_buildSingleProviderMarker(cluster.points.first));
      } else {
        markers.add(_buildClusterMarker(cluster));
      }
    }

    return markers;
  }

  NearbyProviderModel? _providerModelFor(String providerId) {
    if (widget.providers == null) return null;
    for (final provider in widget.providers!) {
      if (provider.id == providerId) {
        return provider;
      }
    }
    return null;
  }

  void _handleProviderTap(String providerId) {
    final onTap = widget.onProviderTap;
    if (onTap == null) return;

    final provider = _providerModelFor(providerId);
    if (provider != null) {
      onTap(provider);
    }
  }

  Widget _nearMeButton() {
    return FloatingActionButton.small(
      heroTag: null,
      backgroundColor: Colors.white,
      foregroundColor: Colors.blue,
      onPressed: () {
        if (widget.position != null) {
          _mapController.move(
            LatLng(widget.position!.latitude, widget.position!.longitude),
            15.0,
          );
          _currentZoom = 15.0;
        }
        widget.onNearMe?.call();
        setState(() {});
      },
      tooltip: 'Go to my location',
      child: const Icon(Icons.my_location),
    );
  }

  IconData _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'carpenter':
        return Icons.handyman;
      case 'mason':
        return Icons.construction;
      case 'painting':
        return Icons.format_paint;
      case 'moving':
        return Icons.local_shipping;
      case 'gardening':
      case 'lawn & compound maintenance':
      case 'hedge & fence trimming':
      case 'tree services':
        return Icons.local_florist;
      case 'irrigation & borehole services':
        return Icons.water_drop;
      case 'appliance repair':
        return Icons.home_repair_service;
      case 'tutoring':
        return Icons.school;
      case 'pet care':
        return Icons.pets;
      case 'health':
        return Icons.medical_services;
      case 'cleaning':
      case 'mama fua':
      case 'commercial cleaning':
      case 'carpet & sofa cleaning':
      case 'pressure washing':
        return Icons.cleaning_services;
      default:
        return Icons.handyman;
    }
  }

  Color _categoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'plumbing':
        return Colors.blue;
      case 'electrical':
        return Colors.amber.shade700;
      case 'carpenter':
        return Colors.orange.shade800;
      case 'mason':
        return Colors.brown;
      case 'painting':
        return Colors.pink;
      case 'moving':
        return Colors.deepOrange;
      case 'gardening':
      case 'lawn & compound maintenance':
      case 'hedge & fence trimming':
      case 'tree services':
        return Colors.green;
      case 'irrigation & borehole services':
        return Colors.teal;
      case 'appliance repair':
        return Colors.blueGrey;
      case 'tutoring':
        return Colors.indigo;
      case 'pet care':
        return Colors.pink.shade300;
      case 'health':
        return Colors.red;
      case 'cleaning':
      case 'mama fua':
      case 'commercial cleaning':
      case 'carpet & sofa cleaning':
      case 'pressure washing':
        return Colors.lightBlue.shade600;
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    _mapEventSub?.cancel();
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPosition = widget.position;

    LatLng center = _nairobi;
    double zoom = 12.0;
    if (currentPosition != null) {
      center = LatLng(currentPosition.latitude, currentPosition.longitude);
      zoom = 15.0;
    }

    _currentZoom = _zoom;
    final markers = _buildMarkers();

    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.the_guy',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        if (widget.polyline != null && widget.polyline!.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.polyline!,
                color: Colors.blue.withValues(alpha: 0.5),
                strokeWidth: 4,
              ),
            ],
          ),
        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers,
          ),
      ],
    );

    if (widget.position == null) return map;

    final nearMe = _nearMeButton();
    final atTop = widget.nearMeAlignment.y < 0;

    return Stack(
      children: [
        map,
        Positioned(
          right: 12,
          top: atTop ? 76 : null,
          bottom: atTop ? null : 12,
          child: nearMe,
        ),
      ],
    );
  }
}
