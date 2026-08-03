import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../../shared/models/nearby_provider_model.dart';

/// A provider rendered on the map, with its effective position (live location
/// wins over the static search position). [provider] is null when the marker
/// comes from a live location with no nearby-search model (e.g. active job).
class ProviderPoint {
  final String providerId;
  final NearbyProviderModel? provider;
  final LatLng position;
  final bool isLive;

  ProviderPoint({
    required this.providerId,
    this.provider,
    required this.position,
    this.isLive = false,
  });
}

/// A group of providers that share a map cell at the current zoom level.
class ProviderCluster {
  final LatLng center;
  final List<ProviderPoint> points;

  ProviderCluster({required this.center, required this.points});

  int get count => points.length;

  String? get dominantCategory {
    final withCategory = points.where((p) => p.provider != null).toList();
    if (withCategory.isEmpty) return null;
    final counts = <String, int>{};
    for (final p in withCategory) {
      counts[p.provider!.category] = (counts[p.provider!.category] ?? 0) + 1;
    }
    var best = withCategory.first.provider!.category;
    var bestCount = 0;
    counts.forEach((category, count) {
      if (count > bestCount) {
        best = category;
        bestCount = count;
      }
    });
    return best;
  }
}

/// Cluster providers into grid cells sized for the current zoom level.
///
/// The cell size shrinks as the user zooms in, so far-away providers merge
/// into a single count bubble while nearby providers split into individual
/// markers. This is a dependency-free grid clustering: no package required.
List<ProviderCluster> clusterProviders(List<ProviderPoint> points, double zoom) {
  if (points.isEmpty) return const [];
  if (points.length == 1) {
    return [ProviderCluster(center: points.first.position, points: points)];
  }

  final cellSizeDegrees = 48.0 / (256.0 * pow(2.0, zoom));

  final cells = <String, List<ProviderPoint>>{};
  for (final point in points) {
    final cellX = (point.position.latitude / cellSizeDegrees).floor();
    final cellY = (point.position.longitude / cellSizeDegrees).floor();
    final key = '$cellX,$cellY';
    cells.putIfAbsent(key, () => []).add(point);
  }

  final clusters = <ProviderCluster>[];
  for (final cell in cells.values) {
    final lat =
        cell.fold<double>(0, (sum, p) => sum + p.position.latitude) / cell.length;
    final lng =
        cell.fold<double>(0, (sum, p) => sum + p.position.longitude) / cell.length;
    clusters.add(ProviderCluster(center: LatLng(lat, lng), points: cell));
  }
  return clusters;
}
