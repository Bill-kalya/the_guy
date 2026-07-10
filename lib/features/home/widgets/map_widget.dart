import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/nearby_provider_model.dart';

class MapWidget extends StatefulWidget {
  final Position? position;
  final List<NearbyProviderModel>? providers;
  final String? selectedProviderId;

  /// Map of live location updates from WebSocket
  final Map<String, ProviderLocationUpdate>? liveLocations;

  const MapWidget({
    super.key,
    this.position,
    this.providers,
    this.selectedProviderId,
    this.liveLocations,
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
    final isSelected = providerId == widget.selectedProviderId;
    final baseColor = isSelected ? Colors.orange : Colors.blue;

    setState(() {
      _animatedMarkers[providerId] = Marker(
        point: position,
        width: isSelected ? 48 : 40,
        height: isSelected ? 48 : 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isSelected ? 44 : 36,
              height: isSelected ? 44 : 36,
              decoration: BoxDecoration(
                color: baseColor,
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
                Icons.handyman,
                color: Colors.white,
                size: isSelected ? 22 : 18,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
              ),
          ],
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
    final isSelected = providerId == widget.selectedProviderId;
    final baseColor = isSelected ? Colors.orange : Colors.blue;

    return Marker(
      point: position,
      width: isSelected ? 48 : 40,
      height: isSelected ? 48 : 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSelected ? 44 : 36,
            height: isSelected ? 44 : 36,
            decoration: BoxDecoration(
              color: baseColor,
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
              Icons.handyman,
              color: Colors.white,
              size: isSelected ? 22 : 18,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
            ),
        ],
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
        ),
        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers,
          ),
      ],
    );
  }
}

