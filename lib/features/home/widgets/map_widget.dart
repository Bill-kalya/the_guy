import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/nearby_provider_model.dart';

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

  const MapWidget({
    super.key,
    this.position,
    this.providers,
    this.selectedProviderId,
    this.liveLocations,
    this.polyline,
    this.onProviderTap,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  static const LatLng _nairobi = LatLng(-1.286389, 36.817223);

  // Animation controllers for smooth marker movement
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, LatLng> _previousPositions = {};
  final Map<String, Marker> _animatedMarkers = {};

  // Latest heading per provider so the direction arrow survives position animation
  final Map<String, double> _markerHeadings = {};

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

  /// Selected/assigned providers render a profile-photo marker with a green
  /// status ring and a direction arrow; browsing markers render a service
  /// category icon inside a category-colored circle.
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

    final circle = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.green,
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

  Widget _categoryMarkerChild(NearbyProviderModel? model) {
    final color = _categoryColor(model?.category);

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

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Add user location marker
    if (widget.position != null) {
      markers.add(_userMarker());
    }

    // Add provider markers from live locations (WebSocket updates)
    if (widget.liveLocations != null) {
      for (final entry in widget.liveLocations!.entries) {
        final providerId = entry.key;
        final update = entry.value;

        // If marker already animated, reuse it
        if (_animatedMarkers.containsKey(providerId)) {
          markers.add(_animatedMarkers[providerId]!);
          continue;
        }

        markers.add(
          _providerMarker(
            providerId: providerId,
            position: LatLng(update.latitude, update.longitude),
          ),
        );
      }
    }

    // Add provider markers from nearby providers list (REST API data)
    if (widget.providers != null) {
      for (final provider in widget.providers!) {
        // Skip if we already have a live location for this provider
        if (widget.liveLocations != null &&
            widget.liveLocations!.containsKey(provider.id)) {
          continue;
        }

        markers.add(
          _providerMarker(
            providerId: provider.id,
            position: LatLng(provider.latitude, provider.longitude),
          ),
        );
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

    final markers = _buildMarkers();

    return FlutterMap(
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
  }
}
