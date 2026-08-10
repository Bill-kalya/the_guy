import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationUtils {
  // Calculate distance between two coordinates (in meters)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371000; // Earth's radius in meters

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = R * c;

    return distance;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  // Calculate ETA based on distance (assuming average speed)
  static Duration calculateETA(
    double distanceMeters, {
    double averageSpeedKmh = 30,
  }) {
    final distanceKm = distanceMeters / 1000;
    final hours = distanceKm / averageSpeedKmh;
    final minutes = (hours * 60).round();
    return Duration(minutes: minutes);
  }

  // Format ETA for display
  static String formatETA(Duration eta) {
    if (eta.inMinutes < 60) {
      return '${eta.inMinutes} min';
    } else {
      final hours = eta.inHours;
      final minutes = eta.inMinutes.remainder(60);
      if (minutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $minutes min';
      }
    }
  }

  // Check if location permission is granted
  static Future<bool> checkLocationPermission() async {
    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('LocationUtils: checkPermission failed: $e');
      return false;
    }

    if (permission == LocationPermission.denied) {
      try {
        permission = await Geolocator.requestPermission();
      } catch (e) {
        debugPrint('LocationUtils: requestPermission failed: $e');
        return false;
      }
      if (permission == LocationPermission.denied) {
        debugPrint('LocationUtils: permission denied by user');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('LocationUtils: permission denied forever');
      return false;
    }

    return true;
  }

  /// Get current location.
  ///
  /// Browsers (and laptops without GPS) can't reliably deliver GPS-level fixes,
  /// so on web we ask for a medium accuracy fix and give it much longer before
  /// giving up. Every failure is logged so the real cause (permission denied,
  /// timeout, service disabled, network) is visible in the console instead of
  /// being reported as "GPS off".
  static Future<Position?> getCurrentLocation() async {
    final hasPermission = await checkLocationPermission();
    if (!hasPermission) return null;

    final settings = LocationSettings(
      // High accuracy on native (GPS); medium on web where browsers fall back
      // to WiFi/IP positioning and often time out waiting for a GPS lock.
      accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      ).timeout(const Duration(seconds: 20));
      debugPrint('LocationUtils: fix acquired '
          '(${position.latitude}, ${position.longitude}) '
          'accuracy=${position.accuracy}m');
      return position;
    } on TimeoutException catch (e) {
      debugPrint('LocationUtils: location request timed out: $e');
    } on Exception catch (e) {
      debugPrint('LocationUtils: location request failed '
          '(${e.runtimeType}): $e');
    } catch (e) {
      debugPrint('LocationUtils: unexpected location error '
          '(${e.runtimeType}): $e');
    }
    return null;
  }

  /// Return the most recently cached fix (native only; browsers don't retain
  /// one across sessions). Used as a fallback when a fresh fix fails.
  static Future<Position?> getLastKnownPosition() async {
    if (kIsWeb) return null;
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        debugPrint('LocationUtils: using last known position '
            '(${position.latitude}, ${position.longitude})');
      }
      return position;
    } catch (e) {
      debugPrint('LocationUtils: getLastKnownPosition failed: $e');
      return null;
    }
  }

  // Continuous accurate position updates. The one-shot above can return a
  // coarse/network fix; listening on the stream lets the map converge on the
  // true location as GPS refines it and as the user moves.
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    );
  }

  // Get location address from coordinates
  static Future<String?> getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.administrativeArea,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        return address.isNotEmpty ? address : null;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Check if user is within a radius of a point
  static bool isWithinRadius(
    double userLat,
    double userLng,
    double targetLat,
    double targetLng,
    double radiusMeters,
  ) {
    final distance = calculateDistance(userLat, userLng, targetLat, targetLng);
    return distance <= radiusMeters;
  }

  // Get bounding box around a point
  static Map<String, double> getBoundingBox(
    double lat,
    double lng,
    double radiusKm,
  ) {
    const double earthRadiusKm = 6371;

    // Angular distance in radians
    final angularDistance = radiusKm / earthRadiusKm;

    // Latitude bounds
    final minLat = lat - (angularDistance * 180 / pi);
    final maxLat = lat + (angularDistance * 180 / pi);

    // Longitude bounds (adjusted for latitude)
    final deltaLon = asin(sin(angularDistance) / cos(_toRadians(lat)));
    final minLng = lng - (deltaLon * 180 / pi);
    final maxLng = lng + (deltaLon * 180 / pi);

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  // Generate random coordinates within a radius
  static Map<String, double> getRandomCoordinatesInRadius(
    double centerLat,
    double centerLng,
    double radiusMeters,
  ) {
    final random = Random();
    const double earthRadius = 6371000;

    // Convert radius to radians
    final radiusRad = radiusMeters / earthRadius;

    // Random angle and distance
    final u = random.nextDouble();
    final v = random.nextDouble();

    final w = radiusRad * sqrt(u);
    final t = 2 * pi * v;

    final x = w * cos(t);
    final y = w * sin(t);

    // Convert to latitude/longitude
    final newLat = centerLat + (y * 180 / pi);
    final newLng = centerLng + (x * 180 / pi / cos(centerLat * pi / 180));

    return {'lat': newLat, 'lng': newLng};
  }

  // Calculate midpoint between two coordinates
  static Map<String, double> getMidpoint(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final midLat = (lat1 + lat2) / 2;
    final midLng = (lng1 + lng2) / 2;

    return {'lat': midLat, 'lng': midLng};
  }

  // Check if coordinates are valid
  static bool isValidCoordinates(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  // Get bearing between two points
  static double getBearing(double lat1, double lon1, double lat2, double lon2) {
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);
    final dLon = _toRadians(lon2 - lon1);

    final y = sin(dLon) * cos(lat2Rad);
    final x =
        cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    double bearing = atan2(y, x);
    bearing = bearing * 180 / pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  // Get cardinal direction from bearing
  static String getDirectionFromBearing(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'N';
    if (bearing >= 22.5 && bearing < 67.5) return 'NE';
    if (bearing >= 67.5 && bearing < 112.5) return 'E';
    if (bearing >= 112.5 && bearing < 157.5) return 'SE';
    if (bearing >= 157.5 && bearing < 202.5) return 'S';
    if (bearing >= 202.5 && bearing < 247.5) return 'SW';
    if (bearing >= 247.5 && bearing < 292.5) return 'W';
    return 'NW';
  }
}
