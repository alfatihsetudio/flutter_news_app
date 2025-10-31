// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request permission and obtain current position.
  /// Returns Position or throws Exception with reason.
  Future<Position> getCurrentPosition({bool forceLocation = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    // can use high accuracy for better results; consider battery impact
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best, timeLimit: const Duration(seconds: 15));
    return pos;
  }
}
