import 'dart:async';
import 'dart:js_interop';

import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:web/web.dart' as web;

import 'geolocation_manager.dart';
import 'utils.dart';

/// Implementation of the [GeolocationManager] interface based on the
/// [html.Geolocation] class.
class HtmlGeolocationManager implements GeolocationManager {
  final web.Geolocation _geolocation;

  /// Creates a new instance of the [HtmlGeolocationManager] class.
  HtmlGeolocationManager() : _geolocation = web.window.navigator.geolocation;

  @override
  Future<Position> getCurrentPosition({
    bool? enableHighAccuracy,
    Duration? timeout,
    Duration? maximumAge,
  }) async {
    Completer<Position> completer = Completer();
    // Vendored patch: browsers (Chrome in particular) can invoke the
    // success AND error callbacks for the same request (or deliver a cached
    // position after a permission/error event). Guard every completion so a
    // late callback can't throw StateError('Future already completed') and
    // crash the whole web app.
    void completeWith(Position position) {
      if (!completer.isCompleted) completer.complete(position);
    }

    void completeWithError(Object error) {
      if (!completer.isCompleted) completer.completeError(error);
    }

    try {
      _geolocation.getCurrentPosition(
        (web.GeolocationPosition position) {
          completeWith(toPosition(position));
        }.toJS,
        (web.GeolocationPositionError error) {
          completeWithError(convertPositionError(error));
        }.toJS,
        web.PositionOptions(
          enableHighAccuracy: enableHighAccuracy ?? false,
          timeout:
              timeout?.inMicroseconds ?? const Duration(days: 1).inMilliseconds,
          maximumAge: maximumAge?.inMilliseconds ?? 0,
        ),
      );
    } catch (e) {
      completeWithError(const PositionUpdateException(
          "Something went wrong while getting current position"));
    }

    return completer.future;
  }

  @override
  Stream<Position> watchPosition({
    bool? enableHighAccuracy,
    Duration? timeout,
    Duration? maximumAge,
  }) {
    int? watchId;
    StreamController<Position> controller = StreamController<Position>(
        sync: true,
        onCancel: () {
          assert(watchId != null);
          _geolocation.clearWatch(watchId!);
        });

    controller.onListen = () {
      assert(watchId == null);
      watchId = _geolocation.watchPosition(
        (web.GeolocationPosition position) {
          if (!controller.isClosed) controller.add(toPosition(position));
        }.toJS,
        (web.GeolocationPositionError error) {
          if (!controller.isClosed) {
            controller.addError(convertPositionError(error));
          }
        }.toJS,
        web.PositionOptions(
          enableHighAccuracy: enableHighAccuracy ?? false,
          timeout:
              timeout?.inMicroseconds ?? const Duration(days: 1).inMilliseconds,
          maximumAge: maximumAge?.inMilliseconds ?? 0,
        ),
      );
    };

    return controller.stream;
  }
}
