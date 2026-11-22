import 'package:geolocator/geolocator.dart';

/// Why a position could not be read. The UI explains each differently —
/// "turn on GPS" and "you denied this forever" need different buttons.
enum LocationProblem { serviceDisabled, denied, deniedForever, failed }

class LocationException implements Exception {
  const LocationException(this.problem, this.message);

  final LocationProblem problem;
  final String message;

  @override
  String toString() => message;
}

/// A reading, with the moment it was taken.
///
/// The server stores `location_fetched_at` beside its own receive time, so a
/// punch filed from a tunnel and synced later is visibly late rather than
/// silently backdated. That only works if the app reports when it actually
/// read the GPS, which is why the timestamp travels with the coordinates.
class GeoFix {
  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.takenAt,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final DateTime takenAt;
  final double? accuracy;
}

class LocationService {
  const LocationService();

  /// Asks for a position, prompting for permission if that has not been
  /// settled yet. Throws [LocationException] rather than returning null, so
  /// a caller cannot quietly file a visit with no coordinates.
  Future<GeoFix> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        LocationProblem.serviceDisabled,
        'Location is switched off on this phone. Turn it on to continue.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationProblem.deniedForever,
        'Location permission is blocked. Allow it in Settings to continue.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        LocationProblem.denied,
        'Location permission is needed to record where this happened.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      return GeoFix(
        latitude: position.latitude,
        longitude: position.longitude,
        takenAt: position.timestamp,
        accuracy: position.accuracy,
      );
    } on Exception {
      // Timed out indoors, or the platform refused. Not fatal in itself —
      // the caller decides whether the action can go ahead without a fix.
      throw const LocationException(
        LocationProblem.failed,
        'Could not get a location fix. Move somewhere with a clearer sky.',
      );
    }
  }
}
